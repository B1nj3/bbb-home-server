#!/usr/bin/env bash
# 05-remove-greenlight.sh
#
# Takes the public Greenlight v3 portal off a BigBlueButton server and restores
# the default "Welcome to BigBlueButton" page, so the server is API-only.
#
# Lesson built in: disabling greenlight-v3.nginx alone left nginx with no
# handler for "/" (default-fe.nginx had been disabled when Greenlight was
# installed), which caused a 500 error. This script re-enables the default
# front end in the same run, and tests nginx before reloading.
#
# Usage:
#   sudo bash 05-remove-greenlight.sh          # disable the portal, keep Greenlight's containers and data
#   sudo bash 05-remove-greenlight.sh --stop   # also stop Greenlight's containers (data kept)
#
# Safe to run more than once. Review before running.

set -euo pipefail

NGINX_DIR="/usr/share/bigbluebutton/nginx"

if [[ $EUID -ne 0 ]]; then
  echo "Run with sudo." >&2
  exit 1
fi

# 1. Disable Greenlight's nginx snippet.
if [[ -e "$NGINX_DIR/greenlight-v3.nginx" ]]; then
  mv "$NGINX_DIR/greenlight-v3.nginx" "$NGINX_DIR/greenlight-v3.nginx.disabled"
  echo "Disabled greenlight-v3.nginx"
fi

# 2. Re-enable the default front end, otherwise "/" has no handler (500 error).
if [[ -e "$NGINX_DIR/default-fe.nginx.disabled" ]]; then
  mv "$NGINX_DIR/default-fe.nginx.disabled" "$NGINX_DIR/default-fe.nginx"
  echo "Re-enabled default-fe.nginx"
fi

# 3. Test before reloading, so a bad config cannot take the site down.
nginx -t
systemctl reload nginx
echo "nginx reloaded"

# 4. Optional: stop Greenlight's containers too (they still hold the BBB secret).
if [[ "${1:-}" == "--stop" ]]; then
  for d in /root/greenlight-v3 /home/*/greenlight-v3; do
    if [[ -f "$d/docker-compose.yml" ]]; then
      (cd "$d" && docker compose down)
      echo "Stopped Greenlight containers in $d (data kept)"
    fi
  done
fi

echo
echo "Check: open https://<your-host>/ in a private window. You should see 'Welcome to BigBlueButton'."
echo "When re-running bbb-install.sh later, never add the -g flag."
