#!/usr/bin/env bash
# Upserts a GitHub tracking issue for a given tool + tier.
#
# Finds an existing open issue tagged with the magic marker
#   <!-- security-bot: tool=<tool> tier=<N> -->
# and creates or updates its body. Closes the issue if the body file is empty.
#
# Requires: gh (authenticated), jq
#
# Usage:
#   upsert-issue.sh --tool <tool> --tier <2|3> --body <file>
#
# Environment:
#   GH_TOKEN — passed through to gh automatically
#   GITHUB_REPOSITORY — set automatically by GitHub Actions (owner/repo)

set -euo pipefail

TOOL=""
TIER=""
BODY_FILE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --tool)  TOOL="$2";      shift 2 ;;
    --tier)  TIER="$2";      shift 2 ;;
    --body)  BODY_FILE="$2"; shift 2 ;;
    *)       echo "Unknown argument: $1" >&2; exit 1 ;;
  esac
done

[[ -z "$TOOL" ]]      && { echo "ERROR: --tool is required" >&2; exit 1; }
[[ -z "$TIER" ]]      && { echo "ERROR: --tier is required" >&2; exit 1; }
[[ -z "$BODY_FILE" ]] && { echo "ERROR: --body is required" >&2; exit 1; }
[[ -f "$BODY_FILE" ]] || { echo "ERROR: body file not found: ${BODY_FILE}" >&2; exit 1; }

MARKER="<!-- security-bot: tool=${TOOL} tier=${TIER} -->"
REPO="${GITHUB_REPOSITORY:-}"
[[ -z "$REPO" ]] && REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner)

if [[ "$TIER" == "2" ]]; then
  ISSUE_TITLE="[security-watch] ${TOOL}: HIGH/CRITICAL CVEs awaiting upstream fix"
  LABELS="security,automated,priority:watch"
else
  ISSUE_TITLE="[security-triage] ${TOOL}: MEDIUM/LOW fixable CVEs"
  LABELS="security,automated,priority:normal"
fi

# Find existing open issue with the magic marker
EXISTING_ISSUE=$(gh api "repos/${REPO}/issues" \
  --jq ".[] | select(.state == \"open\" and (.body // \"\" | contains(\"${MARKER}\"))) | .number" \
  2>/dev/null | head -1 || true)

BODY_EMPTY=false
if [[ ! -s "$BODY_FILE" ]]; then
  BODY_EMPTY=true
fi

if [[ "$BODY_EMPTY" == "true" ]]; then
  if [[ -n "$EXISTING_ISSUE" ]]; then
    echo "upsert-issue [${TOOL} tier ${TIER}]: no findings, closing issue #${EXISTING_ISSUE}"
    gh issue close "$EXISTING_ISSUE" \
      --repo "$REPO" \
      --comment "All Tier ${TIER} findings resolved — closing automatically." 2>/dev/null || true
  else
    echo "upsert-issue [${TOOL} tier ${TIER}]: no findings, no existing issue — nothing to do"
  fi
  exit 0
fi

if [[ -n "$EXISTING_ISSUE" ]]; then
  echo "upsert-issue [${TOOL} tier ${TIER}]: updating issue #${EXISTING_ISSUE}"
  gh issue edit "$EXISTING_ISSUE" \
    --repo "$REPO" \
    --title "$ISSUE_TITLE" \
    --body-file "$BODY_FILE" 2>/dev/null || true
else
  echo "upsert-issue [${TOOL} tier ${TIER}]: creating new issue"
  gh issue create \
    --repo "$REPO" \
    --title "$ISSUE_TITLE" \
    --body-file "$BODY_FILE" \
    --label "$LABELS" 2>/dev/null || true
fi
