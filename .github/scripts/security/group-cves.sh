#!/usr/bin/env bash
# Pure transform: reads Trivy JSON from stdin (or file), writes a grouped Markdown table to stdout.
# Groups binary packages that share the same CVE + source package into a single row.
#
# Usage:
#   group-cves.sh < trivy.json
#   group-cves.sh trivy.json
#
# Output columns: CVE | Source Package | Binary Packages | Installed Version | Fixed Version

set -euo pipefail

INPUT="${1:--}"

jq -r '
  # Flatten all Results[].Vulnerabilities[] into a stream of objects
  [
    .Results[]?
    | .Vulnerabilities[]?
    | {
        cve:        .VulnerabilityID,
        src:        (.SrcName // .PkgName),
        pkg:        .PkgName,
        installed:  .InstalledVersion,
        fixed:      (.FixedVersion // "n/a"),
        severity:   .Severity
      }
  ]
  # Group by CVE + source package
  | group_by(.cve + "|" + .src)
  | .[]
  | {
      cve:       .[0].cve,
      src:       .[0].src,
      pkgs:      ([ .[].pkg ] | unique | sort | join(", ")),
      installed: .[0].installed,
      fixed:     ([ .[].fixed ] | unique | join(", ")),
      severity:  .[0].severity
    }
  | "| \(.cve) | \(.src) | \(.pkgs) | \(.installed) | \(.fixed) | \(.severity) |"
' "$INPUT"
