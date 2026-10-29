#!/bin/bash
set -euo pipefail
exec >> /var/log/offsite-web-backup.log 2>&1
echo "[$(date -Is)] Backup started"

# Keep application data and configuration; avoid copying logs and nested backups.
backup_root=/home
cd -- "$backup_root"
archive="web_$(date +"%Y%m%d%H%M%S").tar.gz"
[[ ! -e "$archive" ]] || { echo "Backup already exists: $archive" >&2; exit 1; }
temporary=$(mktemp .web-backup.XXXXXXXX)
trap 'status=$?; rm -f -- "$temporary"; echo "[$(date -Is)] Backup finished with status $status"' EXIT
tar_status=0
tar --exclude='web/log' --exclude='web/backups' -czf "$temporary" web || tar_status=$?
if (( tar_status == 1 )); then
    echo "WARNING: Files changed during backup; archive may not be a consistent snapshot." >&2
elif (( tar_status != 0 )); then
    echo "ERROR: tar failed with status $tar_status" >&2
    exit "$tar_status"
fi
gzip -t "$temporary"
chmod 600 "$temporary"
mv -- "$temporary" "$archive"

# Set the destination credentials and address before using this template.
backup_password=123456
backup_host=0.0.0.0

# Transfer the tar archive to another VPS
sshpass -p "$backup_password" scp -o StrictHostKeyChecking=no -P 22 "$archive" "root@$backup_host:/home/"

# Verify the destination before removing older local backups.
expected=$(sha256sum -- "$archive" | cut -d' ' -f1)
remote_hash=$(sshpass -p "$backup_password" ssh -o StrictHostKeyChecking=no -o ConnectTimeout=20 -p 22 "root@$backup_host" "sha256sum /home/$archive" | cut -d' ' -f1)
[[ "$expected" == "$remote_hash" ]] || { echo "ERROR: destination checksum mismatch" >&2; exit 1; }
echo "Verified destination checksum for $archive"

# Retain three completed web backups only after a successful transfer.
mapfile -t archives < <(find . -maxdepth 1 -type f -name 'web_*.tar.gz' -printf '%f\n' | LC_ALL=C sort -r)
retained=0
for previous in "${archives[@]}"; do
    [[ "$previous" =~ ^web_[0-9]{14}\.tar\.gz$ ]] || continue
    [[ -f "$previous" && ! -L "$previous" ]] || continue
    retained=$((retained + 1))
    if (( retained > 3 )); then rm -- "$previous"; fi
done
