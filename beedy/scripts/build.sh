#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

[[ $EUID -eq 0 ]] || { echo "Запусти через sudo"; exit 1; }
for c in mkarchiso jq; do command -v "$c" >/dev/null || { echo "Нужен $c"; exit 1; }; done

list() {
  local f
  for f in "$@"; do
    sed -e 's/#.*//' -e 's/[[:space:]]*$//' -e '/^$/d' "$f"
    echo
  done | sed '/^$/d'
}

list packages/*/packages.x86_64 | sort -u > profile/packages.x86_64

installed=$(list $(ls packages/*/packages.x86_64 | grep -v '^packages/live/') | sort -u)

mkdir -p profile/airootfs/etc/beedy
jq --argjson p "$(printf '%s\n' "$installed" | jq -R . | jq -s .)" \
   '.packages = $p' archinstall/base.json \
   > profile/airootfs/etc/beedy/archinstall.json

rm -rf work
mkarchiso -v -w work -o out profile
( cd out && sha256sum ./*.iso > SHA256SUMS )