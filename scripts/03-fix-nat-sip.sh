#!/usr/bin/env bash
# Behind a home router: point bbb-webrtc-sfu at FreeSWITCH's LAN address so WebRTC audio connects.
set -euo pipefail
LAN_IP="${1:-$(ip -4 route get 1.1.1.1 | awk '{for(i=1;i<=NF;i++) if($i=="src") print $(i+1)}')}"
FILE=/etc/bigbluebutton/bbb-webrtc-sfu/production.yml

cp "$FILE" "$FILE.bak.$(date +%Y%m%d%H%M%S)"
yq e -i ".freeswitch.sip_ip = \"${LAN_IP}\"" "$FILE"
echo "freeswitch.sip_ip is now: $(yq e '.freeswitch.sip_ip' "$FILE")"
chown bigbluebutton:bigbluebutton "$FILE"
bbb-conf --restart
bbb-conf --check
