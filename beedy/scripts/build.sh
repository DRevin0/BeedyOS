#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

[[ $EUID -eq 0 ]] || { echo "Need sudo"; exit 1; }
for c in mkarchiso jq base64; do command -v "$c" >/dev/null || { echo "Need $c"; exit 1; }; done

command -v tar >/dev/null || { echo "Need tar"; exit 1; }

list() {
  local f
  for f in "$@"; do
    sed -e 's/#.*//' -e 's/[[:space:]]*$//' -e '/^$/d' "$f"
    echo
  done | sed '/^$/d'
}

list packages/*/packages.x86_64 | sort -u > profile/packages.x86_64
installed=$(list $(ls packages/*/packages.x86_64 | grep -v '^packages/live/') | sort -u)

cfg_src="configs"

post=$(mktemp)
{
  echo 'rm -f /etc/os-release'
  echo "cat > /etc/os-release <<'EOF_OSREL'"
  cat profile/airootfs/etc/os-release
  echo
  echo 'EOF_OSREL'
  cat archinstall/postinstall.sh
} > "$post"

if [ -d "$cfg_src" ]; then
  configs_b64=$(tar -C "$cfg_src" -c . | base64 -w0)
  {
    echo 'mkdir -p /etc/skel/.config'
    echo "echo '$configs_b64' | base64 -d | tar -C /etc/skel/.config -x"
    echo 'while IFS=: read -r u x uid gid gecos home shell; do'
    echo '  if [ -d "$home" ] && { [ "$uid" -eq 0 ] || [ "$uid" -ge 1000 ]; }; then'
    echo '    mkdir -p "$home/.config"'
    echo '    cp -a /etc/skel/.config/. "$home/.config/"'
    echo '    chown -R "$u" "$home/.config"'
    echo '  fi'
    echo 'done < <(cat /etc/passwd)'
  } >> "$post"
fi

cmd="echo $(base64 -w0 "$post") | base64 -d | bash"
rm -f "$post"

mkdir -p profile/airootfs/etc/beedy
jq --argjson p "$(printf '%s\n' "$installed" | jq -R . | jq -s .)" \
   --arg c "$cmd" \
   '.packages = $p | .custom_commands = [$c]' archinstall/base.json \
   > profile/airootfs/etc/beedy/archinstall.json
   
#cfg for live-iso
#if [ -d "$cfg_src" ]; then
#  rm -rf profile/airootfs/root/.config
#  mkdir -p profile/airootfs/root/.config
#  cp -a "$cfg_src"/. profile/airootfs/root/.config/
#fi

rm -rf work
mkarchiso -v -w work -o out profile
( cd out && sha256sum ./*.iso > SHA256SUMS )