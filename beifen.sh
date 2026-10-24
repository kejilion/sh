#!/bin/bash
set -euo pipefail

# Keep application data and configuration; avoid copying logs and nested backups.
backup_root=/home
cd -- "$backup_root"
archive="web_$(date +"%Y%m%d%H%M%S").tar.gz"
[[ ! -e "$archive" ]] || { echo "Backup already exists: $archive" >&2; exit 1; }
temporary=$(mktemp .web-backup.XXXXXXXX)
trap 'rm -f -- "$temporary"' EXIT
tar --exclude='web/log' --exclude='web/backups' -czf "$temporary" web
gzip -t "$temporary"
chmod 600 "$temporary"
mv -- "$temporary" "$archive"

# Transfer the tar archive to another VPS
sshpass -p 123456 scp -o StrictHostKeyChecking=no -P 22 "$archive" root@0.0.0.0:/home/

# Retain three completed web backups only after a successful transfer.
mapfile -t archives < <(find . -maxdepth 1 -type f -name 'web_*.tar.gz' -printf '%f\n' | LC_ALL=C sort -r)
retained=0
for previous in "${archives[@]}"; do
    [[ "$previous" =~ ^web_[0-9]{14}\.tar\.gz$ ]] || continue
    [[ -f "$previous" && ! -L "$previous" ]] || continue
    retained=$((retained + 1))
    if (( retained > 3 )); then rm -- "$previous"; fi
done
