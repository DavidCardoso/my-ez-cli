#!/usr/bin/env bats

setup() {
  BASEDIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
  SCRIPT="${BASEDIR}/.github/scripts/security/group-cves.sh"
  FIXTURES="${BASEDIR}/tests/security-scripts/fixtures"
}

@test "group-cves.sh script exists and is executable" {
  [ -x "$SCRIPT" ]
}

@test "group-cves.sh groups two binary packages sharing a CVE and source package" {
  run bash "$SCRIPT" "${FIXTURES}/trivy-high-full.json"
  [ "$status" -eq 0 ]
  # CVE-2025-68973 has gnupg + gpg both sourced from gnupg2 with a fix — should appear once
  count=$(echo "$output" | grep -c "CVE-2025-68973" || true)
  [ "$count" -eq 1 ]
}

@test "group-cves.sh merges binary package names into one row" {
  run bash "$SCRIPT" "${FIXTURES}/trivy-high-full.json"
  [ "$status" -eq 0 ]
  # Both gnupg and gpg should appear in the same row
  echo "$output" | grep "CVE-2025-68973" | grep -q "gnupg"
  echo "$output" | grep "CVE-2025-68973" | grep -q "gpg"
}

@test "group-cves.sh outputs pipe-delimited table rows starting with |" {
  run bash "$SCRIPT" "${FIXTURES}/trivy-high-full.json"
  [ "$status" -eq 0 ]
  [[ "${lines[0]}" =~ ^\| ]]
}

@test "group-cves.sh handles empty results gracefully" {
  run bash "$SCRIPT" "${FIXTURES}/trivy-empty.json"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "group-cves.sh reads from file argument" {
  run bash "$SCRIPT" "${FIXTURES}/trivy-tier3.json"
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "CVE-2023-12345"
}

@test "group-cves.sh reads from stdin with - argument" {
  run bash -c "bash '${SCRIPT}' - < '${FIXTURES}/trivy-tier3.json'"
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "CVE-2023-12345"
}

@test "group-cves.sh includes severity column" {
  run bash "$SCRIPT" "${FIXTURES}/trivy-high-full.json"
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "HIGH\|CRITICAL\|MEDIUM\|LOW"
}
