#!/usr/bin/env bash
# Set a new random BigBlueButton shared secret (hex, easy to type). Read it with: sudo bbb-conf --secret
# Never commit, photograph or message the secret. Update the website's .env afterwards.
set -euo pipefail
bbb-conf --setsecret "$(openssl rand -hex 16)"
bbb-conf --restart
echo "Secret rotated. View it on this machine only: sudo bbb-conf --secret"
