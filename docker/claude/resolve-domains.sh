#!/bin/bash
# ============================================================================
# Build-time DNS resolution script for Claude Code firewall
# ============================================================================
# Runs during 'docker build'. Reads domain lists from /etc/mec-firewall/,
# fetches GitHub CIDR ranges via the /meta API, DNS-resolves other domains,
# and writes all IPs/CIDRs to /etc/mec-firewall/resolved-cidrs.txt.
#
# The resolved file is loaded by init-firewall.sh at container start.
# IPs go stale until a rebuild — run 'mec claude firewall rebuild' to refresh.
# ============================================================================
set -euo pipefail
IFS=$'\n\t'

FIREWALL_DIR="/etc/mec-firewall"
RESOLVED_FILE="${FIREWALL_DIR}/resolved-cidrs.txt"
GITHUB_META_FILE="${FIREWALL_DIR}/github_meta_endpoints.txt"
DNS_DOMAINS_FILE="${FIREWALL_DIR}/dns_resolve_domains.txt"

echo "Starting build-time domain resolution..."
echo "# Resolved IPs/CIDRs — generated at Docker build time" > "$RESOLVED_FILE"
echo "# Do not edit manually. Rebuild image to refresh: mec claude firewall rebuild" >> "$RESOLVED_FILE"
echo "" >> "$RESOLVED_FILE"

# ---------------------------------------------------------------------------
# GitHub meta API — fetch CIDR ranges
# ---------------------------------------------------------------------------
if [ -f "$GITHUB_META_FILE" ] && [ -s "$GITHUB_META_FILE" ]; then
    echo "# GitHub IP ranges (fetched via /meta API)" >> "$RESOLVED_FILE"

    while IFS= read -r endpoint; do
        [ -z "$endpoint" ] && continue
        [[ "$endpoint" =~ ^# ]] && continue

        echo "Fetching GitHub meta from https://api.github.com/meta ..."
        gh_ranges=$(curl -sf --connect-timeout 30 https://api.github.com/meta || true)
        if [ -z "$gh_ranges" ]; then
            echo "WARNING: Failed to fetch GitHub IP ranges (no network during build?) — skipping GitHub CIDRs" >&2
            break
        fi

        if ! echo "$gh_ranges" | jq -e '.web and .api and .git' >/dev/null; then
            echo "WARNING: GitHub API response missing required fields — skipping GitHub CIDRs" >&2
            break
        fi

        echo "Processing GitHub CIDRs..."
        while read -r cidr; do
            if [[ ! "$cidr" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}/[0-9]{1,2}$ ]]; then
                echo "ERROR: Invalid CIDR from GitHub meta: $cidr" >&2
                exit 1
            fi
            echo "$cidr" >> "$RESOLVED_FILE"
        done < <(echo "$gh_ranges" | jq -r '(.web + .api + .git)[]' | aggregate -q)
        break  # Only process the first endpoint entry (api.github.com)
    done < "$GITHUB_META_FILE"
else
    echo "No github_meta_endpoints.txt found or file is empty — skipping GitHub CIDRs"
fi

echo "" >> "$RESOLVED_FILE"

# ---------------------------------------------------------------------------
# DNS resolution for individual domains
# ---------------------------------------------------------------------------
if [ -f "$DNS_DOMAINS_FILE" ] && [ -s "$DNS_DOMAINS_FILE" ]; then
    echo "# DNS-resolved IPs" >> "$RESOLVED_FILE"

    while IFS= read -r domain; do
        [ -z "$domain" ] && continue
        [[ "$domain" =~ ^# ]] && continue

        echo "Resolving $domain..."
        ips=$(dig +noall +answer A "$domain" | awk '$4 == "A" {print $5}')
        if [ -z "$ips" ]; then
            echo "WARNING: Failed to resolve $domain (no network during build?) — skipping" >&2
            continue
        fi

        while read -r ip; do
            if [[ ! "$ip" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
                echo "WARNING: Invalid IP from DNS for $domain: $ip — skipping" >&2
                continue
            fi
            echo "$ip  # $domain" >> "$RESOLVED_FILE"
        done < <(echo "$ips")
    done < "$DNS_DOMAINS_FILE"
else
    echo "No dns_resolve_domains.txt found or file is empty — skipping DNS resolution"
fi

echo ""
echo "Domain resolution complete. Resolved file:"
cat "$RESOLVED_FILE"
