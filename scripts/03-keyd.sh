#!/usr/bin/env bash
# Installs the macOS-style SUPER/ALT keyboard remap via keyd.
#
# ⚠️ OPINIONATED: this remaps Super+letter (a/c/v/x/z/s/f/g/l/n/o/p/r/t/w/b/i/u/
# minus/equal/0/comma) to Ctrl+letter system-wide, so apps behave like macOS
# (⌘C/⌘V/⌘Z/⌘S/...). Space/Return/Tab/`/Escape/Q/E/H/digits/arrows/Print/F-keys
# are deliberately left alone — Hyprland itself binds Super on those for window
# management. See config/keyd/default.conf to review before installing.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

if ! confirm "Install the macOS-style keyd remap (Super+letter -> Ctrl+letter)?"; then
  warn "Skipped keyd remap."
  exit 0
fi

sudo mkdir -p /etc/keyd
sudo cp "$REPO_ROOT/config/keyd/default.conf" /etc/keyd/default.conf
sudo systemctl enable --now keyd.service
ok "keyd remap installed and enabled."
warn "If a key layout ever misbehaves: sudo systemctl stop keyd"
