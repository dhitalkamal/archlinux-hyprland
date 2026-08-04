#!/usr/bin/env bash
# Switches the network stack to iwd + systemd-networkd (no NetworkManager).
#
# ⚠️ This is the one step that defaults to OFF even with --yes, because it can
# genuinely cut your network connection mid-setup on hardware/configs this
# wasn't tested against (VPNs, enterprise wifi, ethernet-only boxes, etc).
# If you skip it, everything else in this repo still works fine on top of
# NetworkManager — you'll just manage wifi via NetworkManager's own tools
# instead of iwgtk, and waybar's network click-action expects iwgtk/iwd.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

warn "Network stack switch: iwd + systemd-networkd, replacing NetworkManager."
warn "This can drop your connection if you're on wifi right now. Have a wired"
warn "fallback or physical access ready before saying yes."
if [[ "${ASSUME_YES:-0}" == "1" ]]; then
  warn "Skipping automatically under --yes — this step always requires an explicit answer."
fi
read -r -p "Switch to iwd + systemd-networkd now? [y/N] " reply
if [[ ! "$reply" =~ ^[Yy]$ ]]; then
  warn "Skipped network switch. Staying on your current network manager."
  exit 0
fi

sudo mkdir -p /etc/systemd/network
sudo cp "$REPO_ROOT"/config/systemd-network/*.network /etc/systemd/network/

sudo systemctl disable --now NetworkManager.service 2>/dev/null || true
sudo systemctl enable --now systemd-networkd.service
sudo systemctl enable --now iwd.service
sudo systemctl enable --now systemd-resolved.service 2>/dev/null || true
sudo ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
ok "Switched to iwd + systemd-networkd. Manage wifi with: iwctl, or the iwgtk GUI (waybar network click)."
