#!/usr/bin/env bash
# archlinux-hyprland — bootstrap a fresh Arch install into this exact Hyprland desktop.
#
# Usage:
#   ./install.sh                 # interactive, asks before each opinionated step
#   ./install.sh --yes           # non-interactive (still asks before the network switch)
#   ./install.sh --skip-packages # skip pacman/AUR installs (e.g. re-linking configs only)
#
# Safe to re-run: every step is idempotent and backs up anything it would overwrite.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"
source scripts/lib.sh

ASSUME_YES=0
SKIP_PACKAGES=0

for arg in "$@"; do
  case "$arg" in
    -y|--yes) ASSUME_YES=1 ;;
    --skip-packages) SKIP_PACKAGES=1 ;;
    -h|--help)
      sed -n '2,10p' "$0"
      exit 0
      ;;
    *)
      err "Unknown option: $arg (see --help)"
      exit 1
      ;;
  esac
done
export ASSUME_YES

require_arch
require_not_root

cat <<'BANNER'
==========================================================
 archlinux-hyprland — full desktop bootstrap
==========================================================
This will, in order:
  1. Install all required pacman + AUR packages
  2. Symlink Hyprland/Waybar/wofi/kitty/swaync/quickshell/
     GTK configs and ~/.local/bin scripts from this repo
  3. Install the keyd macOS-style keyboard remap  [asks first]
  4. Enable SDDM with the astronaut theme         [asks first]
  5. Optionally switch to iwd + systemd-networkd  [always asks]

Anything already at a target path gets backed up, never deleted.
==========================================================
BANNER

if [[ "$ASSUME_YES" != "1" ]]; then
  confirm "Continue?" || { warn "Aborted."; exit 0; }
fi

if [[ "$SKIP_PACKAGES" == "1" ]]; then
  warn "Skipping package installation (--skip-packages)."
else
  bash scripts/01-packages.sh
fi

bash scripts/02-link-configs.sh
bash scripts/03-keyd.sh
bash scripts/04-sddm.sh
bash scripts/05-network.sh

ok "Done."
log "Reboot (or at least re-login) to pick up SDDM/keyd/network changes and start Hyprland fresh."
