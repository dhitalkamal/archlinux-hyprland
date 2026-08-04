#!/usr/bin/env bash
# Symlinks this repo's config/ and local/bin/ into place. Anything that already
# exists at the destination gets moved into $BACKUP_DIR first, never deleted.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

log "Existing configs (if any) will be backed up to: $BACKUP_DIR"

# Whole-directory links: these app config dirs are entirely owned by this repo.
for app in hypr waybar wofi kitty swaync quickshell gtk-3.0 gtk-4.0; do
  link_path "$REPO_ROOT/config/$app" "$HOME/.config/$app"
done

# Per-file links: ~/.local/bin may already contain the user's own unrelated scripts.
mkdir -p "$HOME/.local/bin"
for f in "$REPO_ROOT"/local/bin/*; do
  link_path "$f" "$HOME/.local/bin/$(basename "$f")"
done

ok "Configs and scripts linked."
log "Note: /etc/keyd and SDDM's /etc/sddm.conf.d are handled by 03-keyd.sh and 04-sddm.sh (need root)."
