#!/usr/bin/env bash
# Installs every native + AUR package this desktop needs.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

read_list() {
  grep -vE '^\s*(#|$)' "$1"
}

log "Syncing pacman databases..."
sudo pacman -Sy

log "Installing native packages (packages/pacman.txt)..."
mapfile -t PACMAN_PKGS < <(read_list "$REPO_ROOT/packages/pacman.txt")
sudo pacman -S --needed --noconfirm "${PACMAN_PKGS[@]}"

if ! command -v yay >/dev/null 2>&1; then
  log "yay not found — bootstrapping it from AUR..."
  sudo pacman -S --needed --noconfirm git base-devel
  tmpdir="$(mktemp -d)"
  git clone --depth=1 https://aur.archlinux.org/yay.git "$tmpdir/yay"
  (cd "$tmpdir/yay" && makepkg -si --noconfirm)
  rm -rf "$tmpdir"
  ok "yay installed"
else
  ok "yay already installed"
fi

log "Installing AUR packages (packages/aur.txt)..."
mapfile -t AUR_PKGS < <(read_list "$REPO_ROOT/packages/aur.txt")
yay -S --needed --noconfirm "${AUR_PKGS[@]}"

ok "All packages installed."
