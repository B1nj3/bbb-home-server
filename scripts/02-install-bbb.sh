#!/usr/bin/env bash
# Install BigBlueButton 3.0 on Ubuntu 22.04 with Let's Encrypt TLS and UFW firewall.
# Requires: DNS A record pointing DOMAIN at this server's public IP; ports 80, 443/tcp and 16384-32768/udp forwarded.
set -euo pipefail
DOMAIN="${1:?Usage: sudo $0 class.example.com admin@example.com}"
EMAIL="${2:?Usage: sudo $0 class.example.com admin@example.com}"

grep -q 'VERSION_ID="22.04"' /etc/os-release || { echo "BigBlueButton 3.0 needs Ubuntu 22.04."; exit 1; }
wget -q https://raw.githubusercontent.com/bigbluebutton/bbb-install/v3.0.x-release/bbb-install.sh -O bbb-install.sh
bash bbb-install.sh -w -v jammy-300 -s "$DOMAIN" -e "$EMAIL"
bbb-conf --check
