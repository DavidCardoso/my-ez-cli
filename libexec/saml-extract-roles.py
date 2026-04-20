#!/usr/bin/env python3
"""Extract AWS IAM role/provider pairs from a SAML assertion file.

The input file contains a raw base64+HTML-entity-encoded SAML assertion as
returned by Okta's SAML POST binding response.  Output is one
"role_arn,provider_arn" pair per line, suitable for shell consumption.

Usage:
    saml-extract-roles.py <assertion-file>
"""

import sys
import re
import base64
import xml.etree.ElementTree as ET

ROLE_ATTR = "https://aws.amazon.com/SAML/Attributes/Role"
SAML2_NS = "urn:oasis:names:tc:SAML:2.0:assertion"


def decode_assertion(path: str) -> bytes:
    """Read the assertion file and return decoded XML bytes.

    Okta HTML-entity-encodes the base64 string (e.g. &#43; → +, &#x2b; → +).
    Both decimal and hex numeric character references must be decoded before
    the base64 decode step.

    Args:
        path: Path to the file containing the raw encoded assertion.

    Returns:
        Raw XML bytes of the decoded SAML assertion.

    Raises:
        OSError: If the file cannot be read.
        Exception: If base64 decoding fails.
    """
    with open(path, "rb") as fh:
        data = fh.read()

    text = data.decode("ascii", errors="replace")
    # Decode hex numeric character references: &#x2b; → +
    text = re.sub(r"&#x([0-9a-fA-F]+);", lambda m: chr(int(m.group(1), 16)), text)
    # Decode decimal numeric character references: &#43; → +
    text = re.sub(r"&#(\d+);", lambda m: chr(int(m.group(1))), text)
    # Strip whitespace — base64 must be a contiguous string
    text = re.sub(r"\s", "", text)

    return base64.b64decode(text)


def extract_via_xml(xml_bytes: bytes) -> list[str]:
    """Extract role pairs using the stdlib XML parser.

    Preferred path: works when the SAML document is well-formed XML that
    ElementTree can parse (i.e. no binary-contaminated sections in scope).

    Args:
        xml_bytes: Raw XML bytes of the decoded SAML assertion.

    Returns:
        List of "role_arn,provider_arn" strings.  Empty if none found.

    Raises:
        xml.etree.ElementTree.ParseError: If the bytes are not parseable XML.
    """
    root = ET.fromstring(xml_bytes)
    tag = f"{{{SAML2_NS}}}Attribute"
    avtag = f"{{{SAML2_NS}}}AttributeValue"
    roles: list[str] = []

    for attr in root.iter(tag):
        if attr.get("Name") == ROLE_ATTR:
            for av in attr.iter(avtag):
                text = (av.text or "").strip()
                parts = [p.strip() for p in text.split(",")]
                role = next((p for p in parts if ":role/" in p), None)
                prov = next((p for p in parts if ":saml-provider/" in p), None)
                if role and prov:
                    roles.append(f"{role},{prov}")

    return roles


def extract_via_bytes(xml_bytes: bytes) -> list[str]:
    """Extract role pairs using a binary-safe byte-search strategy.

    SAML XML digital signatures embed raw DER-encoded binary data inside
    <ds:SignatureValue> and <ds:X509Certificate> elements.  Those binary bytes
    can include 0x3C ('<') and 0x3E ('>'), which corrupt full-document regex or
    string searches.

    Strategy: anchor the search to AFTER the last </ds:Signature> close tag
    using rfind(), then locate the AttributeStatement block only within the
    clean text that follows.  Strip non-printable bytes from that substring
    before applying regex extraction.

    Args:
        xml_bytes: Raw XML bytes of the decoded SAML assertion.

    Returns:
        List of "role_arn,provider_arn" strings.  Empty if none found.
    """
    sig_close = b"</ds:Signature>"
    last_sig = xml_bytes.rfind(sig_close)
    search_from = (last_sig + len(sig_close)) if last_sig >= 0 else 0

    open_pos = xml_bytes.find(b"AttributeStatement", search_from)
    if open_pos < 0:
        return []

    tag_start = xml_bytes.rfind(b"<", 0, open_pos)
    close_pos = xml_bytes.find(b"/AttributeStatement>", open_pos)
    if close_pos >= 0:
        blob = xml_bytes[tag_start : close_pos + len(b"/AttributeStatement>")]
    else:
        blob = xml_bytes[tag_start:]

    # Keep only printable ASCII + tab/LF/CR to strip any residual binary bytes
    clean = bytes(b for b in blob if b in (0x09, 0x0A, 0x0D) or 0x20 <= b <= 0x7E)
    text = clean.decode("ascii", errors="ignore")

    role_re = re.compile(
        r'<(?:\w+:)?Attribute\b[^>]*\bName="' + re.escape(ROLE_ATTR) + r'"[^>]*>'
        r"(.*?)</(?:\w+:)?Attribute>",
        re.DOTALL,
    )
    val_re = re.compile(
        r"<(?:\w+:)?AttributeValue[^>]*>(.*?)</(?:\w+:)?AttributeValue>",
        re.DOTALL,
    )

    roles: list[str] = []
    for attr_match in role_re.finditer(text):
        for val_match in val_re.finditer(attr_match.group(1)):
            parts = [p.strip() for p in val_match.group(1).strip().split(",")]
            role = next((p for p in parts if ":role/" in p), None)
            prov = next((p for p in parts if ":saml-provider/" in p), None)
            if role and prov:
                roles.append(f"{role},{prov}")

    return roles


def main() -> None:
    """Entry point: decode assertion, extract roles, print to stdout."""
    if len(sys.argv) < 2:
        print("Usage: saml-extract-roles.py <assertion-file>", file=sys.stderr)
        sys.exit(1)

    try:
        xml_bytes = decode_assertion(sys.argv[1])
    except Exception as exc:
        print(f"Error: Failed to decode SAML assertion: {exc}", file=sys.stderr)
        sys.exit(1)

    # Try the clean XML parser first; fall back to byte-search if it fails or
    # returns nothing (e.g. when binary signature bytes prevent full parse).
    roles: list[str] = []
    try:
        roles = extract_via_xml(xml_bytes)
    except Exception:
        pass

    if not roles:
        roles = extract_via_bytes(xml_bytes)

    if not roles:
        if b"EncryptedAssertion" in xml_bytes:
            print(
                "Error: SAML assertion is encrypted — roles cannot be extracted.",
                file=sys.stderr,
            )
        else:
            print("Error: No AWS roles found in SAML assertion.", file=sys.stderr)
        sys.exit(1)

    for pair in roles:
        print(pair)


if __name__ == "__main__":
    main()
