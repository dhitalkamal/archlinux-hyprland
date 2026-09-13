#!/usr/bin/env bash
# Symlinks this repo's claude/.claude/* config into ~/.claude/. Leaves runtime
# state Claude Code itself owns (credentials, sessions, cache, projects,
# plugins, history.jsonl, memory) untouched - only the pieces this repo
# tracks get linked.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

CLAUDE_SRC="$REPO_ROOT/claude/.claude"
CLAUDE_DST="$HOME/.claude"

# Whole-directory links: these subdirs are entirely owned by this repo.
for dir in hooks agents commands evals headless routines; do
  link_path "$CLAUDE_SRC/$dir" "$CLAUDE_DST/$dir"
done

# Per-file links.
link_path "$CLAUDE_SRC/CLAUDE.md" "$CLAUDE_DST/CLAUDE.md"
link_path "$CLAUDE_SRC/settings.json" "$CLAUDE_DST/settings.json"
link_path "$CLAUDE_SRC/statusline.sh" "$CLAUDE_DST/statusline.sh"

# orchestration/ mixes repo-tracked spec (orchestrator.md) with machine-local
# runtime state (state.json) - link only the spec file, not the whole dir.
mkdir -p "$CLAUDE_DST/orchestration"
link_path "$CLAUDE_SRC/orchestration/orchestrator.md" "$CLAUDE_DST/orchestration/orchestrator.md"
if [[ ! -f "$CLAUDE_DST/orchestration/state.json" ]]; then
  cat >"$CLAUDE_DST/orchestration/state.json" <<'JSON'
{
  "repos": [],
  "active_orchestrations": [],
  "completed_orchestrations": []
}
JSON
  ok "seeded empty ~/.claude/orchestration/state.json - add repos to enable the routines"
fi

# pending/ is a local-only staging area for agent-drafted hooks/skills/agents
# awaiting human review - never repo-tracked.
mkdir -p "$CLAUDE_DST/pending/hooks" "$CLAUDE_DST/pending/skills" "$CLAUDE_DST/pending/agents"
mkdir -p "$CLAUDE_DST/logs/headless"

chmod +x "$CLAUDE_DST"/hooks/*.sh "$CLAUDE_DST/statusline.sh"

ok "Claude Code config linked."
