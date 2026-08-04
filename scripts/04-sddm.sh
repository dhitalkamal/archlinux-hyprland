#!/usr/bin/env bash
# Enables SDDM as the login manager and selects sddm-astronaut-theme.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

if ! confirm "Enable SDDM as the display/login manager, using sddm-astronaut-theme?"; then
  warn "Skipped SDDM setup. Install/enable your own display manager instead."
  exit 0
fi

sudo mkdir -p /etc/sddm.conf.d
printf '[Theme]\nCurrent=sddm-astronaut-theme\n' | sudo tee /etc/sddm.conf.d/theme.conf >/dev/null
sudo systemctl enable sddm.service
ok "SDDM enabled with sddm-astronaut-theme (takes effect on next boot/reboot)."
log "To preview other built-in styles first: sddm-greeter-qt6 --test-mode --theme /usr/share/sddm/themes/sddm-astronaut-theme"
log "To change style: edit ConfigFile= in /usr/share/sddm/themes/sddm-astronaut-theme/metadata.desktop (see Themes/*.conf in that dir)."
