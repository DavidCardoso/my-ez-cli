#!/bin/bash
set -euo pipefail

# Run firewall if enabled (MEC_FIREWALL_ENABLED is set by bin/claude when
# ai.claude.firewall.enabled = true in user config)
if [ "${MEC_FIREWALL_ENABLED:-false}" = "true" ]; then
    sudo /usr/local/bin/init-firewall.sh
fi

exec claude "$@"
