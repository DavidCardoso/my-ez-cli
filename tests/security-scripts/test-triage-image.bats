#!/usr/bin/env bats

setup() {
  BASEDIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
  SCRIPT="${BASEDIR}/.github/scripts/security/triage-image.sh"
  FIXTURES="${BASEDIR}/tests/security-scripts/fixtures"
  TOOL="test-image"
}

teardown() {
  rm -f "/tmp/tier2-${TOOL}.md" "/tmp/tier3-${TOOL}.md"
}

@test "triage-image.sh script exists and is executable" {
  [ -x "$SCRIPT" ]
}

@test "triage-image.sh fails without --tool" {
  run bash "$SCRIPT" --input /tmp
  [ "$status" -ne 0 ]
}

@test "triage-image.sh fails without --input" {
  run bash "$SCRIPT" --tool some-tool
  [ "$status" -ne 0 ]
}

@test "triage-image.sh produces tier2 output file" {
  cp "${FIXTURES}/trivy-high-full.json" "/tmp/trivy-high-full-${TOOL}.json"
  cp "${FIXTURES}/trivy-tier3.json" "/tmp/trivy-tier3-${TOOL}.json"
  run bash "$SCRIPT" --tool "$TOOL" --input /tmp
  [ "$status" -eq 0 ]
  [ -f "/tmp/tier2-${TOOL}.md" ]
  rm -f "/tmp/trivy-high-full-${TOOL}.json" "/tmp/trivy-tier3-${TOOL}.json"
}

@test "triage-image.sh produces tier3 output file" {
  cp "${FIXTURES}/trivy-high-full.json" "/tmp/trivy-high-full-${TOOL}.json"
  cp "${FIXTURES}/trivy-tier3.json" "/tmp/trivy-tier3-${TOOL}.json"
  run bash "$SCRIPT" --tool "$TOOL" --input /tmp
  [ "$status" -eq 0 ]
  [ -f "/tmp/tier3-${TOOL}.md" ]
  rm -f "/tmp/trivy-high-full-${TOOL}.json" "/tmp/trivy-tier3-${TOOL}.json"
}

@test "triage-image.sh tier2 body contains magic marker" {
  cp "${FIXTURES}/trivy-high-full.json" "/tmp/trivy-high-full-${TOOL}.json"
  cp "${FIXTURES}/trivy-tier3.json" "/tmp/trivy-tier3-${TOOL}.json"
  bash "$SCRIPT" --tool "$TOOL" --input /tmp
  grep -q "<!-- security-bot: tool=${TOOL} tier=2 -->" "/tmp/tier2-${TOOL}.md"
  rm -f "/tmp/trivy-high-full-${TOOL}.json" "/tmp/trivy-tier3-${TOOL}.json"
}

@test "triage-image.sh tier3 body contains magic marker" {
  cp "${FIXTURES}/trivy-high-full.json" "/tmp/trivy-high-full-${TOOL}.json"
  cp "${FIXTURES}/trivy-tier3.json" "/tmp/trivy-tier3-${TOOL}.json"
  bash "$SCRIPT" --tool "$TOOL" --input /tmp
  grep -q "<!-- security-bot: tool=${TOOL} tier=3 -->" "/tmp/tier3-${TOOL}.md"
  rm -f "/tmp/trivy-high-full-${TOOL}.json" "/tmp/trivy-tier3-${TOOL}.json"
}

@test "triage-image.sh tier2 body is empty when no unfixable HIGH/CRITICAL" {
  # trivy-tier3.json has only MEDIUM/LOW — no HIGH/CRITICAL at all
  cp "${FIXTURES}/trivy-tier3.json" "/tmp/trivy-high-full-${TOOL}.json"
  cp "${FIXTURES}/trivy-tier3.json" "/tmp/trivy-tier3-${TOOL}.json"
  bash "$SCRIPT" --tool "$TOOL" --input /tmp
  [ ! -s "/tmp/tier2-${TOOL}.md" ]
  rm -f "/tmp/trivy-high-full-${TOOL}.json" "/tmp/trivy-tier3-${TOOL}.json"
}

@test "triage-image.sh outputs empty files when input is empty" {
  cp "${FIXTURES}/trivy-empty.json" "/tmp/trivy-high-full-${TOOL}.json"
  cp "${FIXTURES}/trivy-empty.json" "/tmp/trivy-tier3-${TOOL}.json"
  bash "$SCRIPT" --tool "$TOOL" --input /tmp
  [ ! -s "/tmp/tier2-${TOOL}.md" ]
  [ ! -s "/tmp/tier3-${TOOL}.md" ]
  rm -f "/tmp/trivy-high-full-${TOOL}.json" "/tmp/trivy-tier3-${TOOL}.json"
}
