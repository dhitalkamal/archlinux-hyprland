#!/usr/bin/env bash
# Shared helpers sourced by every scripts/NN-*.sh step. Not meant to be run directly.

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKUP_DIR="${BACKUP_DIR:-$HOME/.config-backup-$(date +%Y%m%d-%H%M%S)}"

c_red=$'\033[31m'; c_green=$'\033[32m'; c_yellow=$'\033[33m'; c_blue=$'\033[34m'; c_reset=$'\033[0m'

log()  { printf '%s[+]%s %s\n' "$c_blue"  "$c_reset" "$*"; }
ok()   { printf '%s[ok]%s %s\n' "$c_green" "$c_reset" "$*"; }
warn() { printf '%s[!]%s %s\n' "$c_yellow" "$c_reset" "$*"; }
err()  { printf '%s[x]%s %s\n' "$c_red" "$c_reset" "$*" >&2; }

confirm() {
  # confirm "question" — returns 0 (yes) / 1 (no). Auto-yes if ASSUME_YES=1.
  local prompt="$1"
  if [[ "${ASSUME_YES:-0}" == "1" ]]; then
    return 0
  fi
  local reply
  read -r -p "$prompt [y/N] " reply
  [[ "$reply" =~ ^[Yy]$ ]]
}

# link_path <source-in-repo> <target-path>
# If target exists and is not already a symlink to source, back it up first.
link_path() {
  local src="$1" dst="$2"
  mkdir -p "$(dirname "$dst")"
  if [[ -L "$dst" && "$(readlink -f "$dst")" == "$(readlink -f "$src")" ]]; then
    ok "already linked: $dst"
    return 0
  fi
  if [[ -e "$dst" || -L "$dst" ]]; then
    mkdir -p "$BACKUP_DIR/$(dirname "${dst#"$HOME"/}")"
    mv "$dst" "$BACKUP_DIR/${dst#"$HOME"/}"
    warn "backed up existing $dst -> $BACKUP_DIR/${dst#"$HOME"/}"
  fi
  ln -s "$src" "$dst"
  ok "linked $dst -> $src"
}

require_arch() {
  if ! command -v pacman >/dev/null 2>&1; then
    err "pacman not found — this repo only supports Arch Linux (and derivatives)."
    exit 1
  fi
}

require_not_root() {
  if [[ "$EUID" -eq 0 ]]; then
    err "Don't run install.sh as root. It calls sudo itself where needed."
    exit 1
  fi
}
