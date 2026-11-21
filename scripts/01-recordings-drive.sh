#!/usr/bin/env bash
# Format a dedicated drive for BigBlueButton recordings and mount it at /var/bigbluebutton.
# WARNING: erases DEVICE. Run BEFORE installing BigBlueButton. Check the device with: lsblk -o NAME,SIZE,MODEL,MOUNTPOINT
set -euo pipefail
DEVICE="${1:?Usage: sudo $0 /dev/nvme0n1}"
PART="${DEVICE}p1"; [[ "$DEVICE" =~ nvme ]] || PART="${DEVICE}1"

read -rp "This will ERASE ${DEVICE}. Type YES to continue: " ok
[[ "$ok" == "YES" ]] || { echo "Aborted."; exit 1; }

wipefs -a "$DEVICE"
parted "$DEVICE" --script mklabel gpt mkpart recordings ext4 0% 100%
mkfs.ext4 -F -L recordings "$PART"
mkdir -p /var/bigbluebutton
sed -i '/LABEL=recordings/d' /etc/fstab
echo 'LABEL=recordings /var/bigbluebutton ext4 defaults,nofail 0 2' >> /etc/fstab
mount -a
df -h /var/bigbluebutton
