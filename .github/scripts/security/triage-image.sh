#!/usr/bin/env bash
# For a given image, derives Tier 2 (HIGH/CRITICAL unfixable) and Tier 3 (MEDIUM/LOW fixable)
# finding sets from the Trivy JSON artifacts produced by security-scan.yml.
#
# Outputs Markdown body files consumed by upsert-issue.sh:
#   /tmp/tier2-<tool>.md
#   /tmp/tier3-<tool>.md
#
# Tier 2 = HIGH/CRITICAL full minus HIGH/CRITICAL fixable (i.e., unfixable)
# Tier 3 = MEDIUM/LOW fixable (direct from trivy-tier3-<tool>.json)
#
# Usage:
#   triage-image.sh --tool <tool> --input <dir>
#
# Expected files in <dir>:
#   trivy-high-full-<tool>.json
#   trivy-tier3-<tool>.json

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOL=""
INPUT_DIR=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --tool)    TOOL="$2";      shift 2 ;;
    --input)   INPUT_DIR="$2"; shift 2 ;;
    *)         echo "Unknown argument: $1" >&2; exit 1 ;;
  esac
done

[[ -z "$TOOL" ]]      && { echo "ERROR: --tool is required" >&2; exit 1; }
[[ -z "$INPUT_DIR" ]] && { echo "ERROR: --input is required" >&2; exit 1; }

FULL_JSON="${INPUT_DIR}/trivy-high-full-${TOOL}.json"
TIER3_JSON="${INPUT_DIR}/trivy-tier3-${TOOL}.json"
TIER2_OUT="/tmp/tier2-${TOOL}.md"
TIER3_OUT="/tmp/tier3-${TOOL}.md"

[[ -f "$FULL_JSON" ]]  || { echo "ERROR: missing ${FULL_JSON}" >&2; exit 1; }
[[ -f "$TIER3_JSON" ]] || { echo "ERROR: missing ${TIER3_JSON}" >&2; exit 1; }

# Derive Tier 2: entries in the full HIGH/CRITICAL scan whose FixedVersion is empty/null
# (ignore-unfixed: false captured them; ignore-unfixed: true would have dropped them)
TIER2_ROWS=$(jq -r '
  [
    .Results[]?
    | .Vulnerabilities[]?
    | select(.FixedVersion == null or .FixedVersion == "")
    | {
        cve:       .VulnerabilityID,
        src:       (.SrcName // .PkgName),
        pkg:       .PkgName,
        installed: .InstalledVersion,
        severity:  .Severity
      }
  ]
  | group_by(.cve + "|" + .src)
  | .[]
  | {
      cve:      .[0].cve,
      src:      .[0].src,
      pkgs:     ([ .[].pkg ] | unique | sort | join(", ")),
      installed: .[0].installed,
      severity: .[0].severity
    }
  | "| \(.cve) | \(.src) | \(.pkgs) | \(.installed) | no fix available | \(.severity) |"
' "$FULL_JSON")

# Derive Tier 3 rows using shared group-cves helper
TIER3_ROWS=$("${SCRIPT_DIR}/group-cves.sh" "$TIER3_JSON")

write_issue_body() {
  local tier="$1" rows="$2" out="$3"
  if [[ -z "$rows" ]]; then
    : > "$out"
    return
  fi

  if [[ "$tier" == "2" ]]; then
    local title="HIGH/CRITICAL CVEs awaiting upstream fix"
  else
    local title="MEDIUM/LOW fixable CVEs"
  fi

  {
    echo "<!-- security-bot: tool=${TOOL} tier=${tier} -->"
    echo ""
    echo "## ${title} — ${TOOL}"
    echo ""
    echo "| CVE | Source Package | Binary Packages | Installed Version | Fixed Version | Severity |"
    echo "|-----|---------------|-----------------|-------------------|---------------|----------|"
    echo "$rows"
    echo ""
    echo "_Updated by the [security-triage workflow](../../actions/workflows/security-triage.yml) · ${TOOL} · tier ${tier}_"
  } > "$out"
}

write_issue_body "2" "$TIER2_ROWS" "$TIER2_OUT"
write_issue_body "3" "$TIER3_ROWS" "$TIER3_OUT"

tier2_count=$(echo "$TIER2_ROWS" | grep -c "^|" || true)
tier3_count=$(echo "$TIER3_ROWS" | grep -c "^|" || true)
echo "triage-image [${TOOL}]: tier2=${tier2_count} rows, tier3=${tier3_count} rows"
