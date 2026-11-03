#!/usr/bin/env bash
mkdir -p /usr/share/beedy
cp /etc/os-release /usr/share/beedy/os-release
printf 'BeedyOS \\r (\\l)\n\n' > /etc/issue

mkdir -p /etc/pacman.d/hooks
cat > /etc/pacman.d/hooks/beedy-os-release.hook <<'EOF'
[Trigger]
Operation = Install
Operation = Upgrade
Type = Package
Target = filesystem

[Action]
When = PostTransaction
Exec = /usr/bin/sh -c 'rm -f /etc/os-release && cp /usr/share/beedy/os-release /etc/os-release'
EOF

for f in /boot/loader/entries/*.conf; do
  [ -e "$f" ] && sed -i -E 's/^title[[:space:]]+Arch Linux/title   BeedyOS/' "$f"
done
if [ -f /etc/default/grub ]; then
  sed -i 's/^GRUB_DISTRIBUTOR=.*/GRUB_DISTRIBUTOR="BeedyOS"/' /etc/default/grub
  grub-mkconfig -o /boot/grub/grub.cfg
fi

# ironbar
systemctl --global enable ironbar.service
