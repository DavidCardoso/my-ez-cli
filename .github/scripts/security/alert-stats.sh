#!/usr/bin/env bash
# Local-dev helper: prints a snapshot of open code-scanning alerts grouped by rule_id
# and by analysis_key. Useful for verifying alert count changes before/after workflow runs.
#
# Usage:
#   alert-stats.sh                  # print summary to stdout
#   alert-stats.sh > before.txt     # snapshot before changes
#
# Requires: gh (authenticated), jq

set -euo pipefail

REPO="${GITHUB_REPOSITORY:-}"
[[ -z "$REPO" ]] && REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner)

echo "=== Open code-scanning alerts for ${REPO} ==="
echo ""

echo "--- By analysis_key ---"
gh api "repos/${REPO}/code-scanning/alerts" \
  --paginate \
  --jq '.[].most_recent_instance.analysis_key' \
  | sort | uniq -c | sort -rn

echo ""
echo "--- By rule_id (top 30) ---"
gh api "repos/${REPO}/code-scanning/alerts" \
  --paginate \
  --jq '.[].rule.id' \
  | sort | uniq -c | sort -rn | head -30

echo ""
echo "--- Total open alerts ---"
gh api "repos/${REPO}/code-scanning/alerts" \
  --paginate \
  --jq '.[].number' \
  | wc -l | tr -d ' '
