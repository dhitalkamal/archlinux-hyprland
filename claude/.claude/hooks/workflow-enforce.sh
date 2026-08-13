#!/bin/bash
# UserPromptSubmit hook. Enforces the PROCEED gate from CLAUDE.md's
# "Prompt workflow" section, but only in interactive mode - headless,
# routine, and ci sessions have no human to type PROCEED.
set -euo pipefail

session_id="${CLAUDE_SESSION_ID:-$$}"
env_file="${HOME}/.claude/session-env/${session_id}.env"

mode="interactive"
if [ -f "$env_file" ]; then
    # shellcheck disable=SC1090
    . "$env_file"
    mode="${CLAUDE_EXEC_MODE:-interactive}"
fi

if [ "$mode" != "interactive" ]; then
    cat >/dev/null 2>&1 || true
    exit 0
fi

input=$(cat)
prompt=$(echo "$input" | /usr/bin/python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
except (json.JSONDecodeError, ValueError):
    print('')
    sys.exit(0)
print(data.get('prompt', ''))
" || echo "")

last_word=$(echo "$prompt" | awk 'NF{last=$NF} END{print last}' | sed -E 's/[.,:;!]+$//')
if [ "$last_word" = "PROCEED" ]; then
    exit 0
fi

/usr/bin/python3 -c "
import json
msg = (
    'WORKFLOW - follow this for every prompt without exception:\n\n'
    '1. ANALYZE (silently): read relevant files, understand scope and context first.\n'
    '2. RESPOND IN ONE MESSAGE with all three:\n'
    '   a. Findings: what you discovered about the codebase/context\n'
    '   b. Questions: every clarifying question - mark unknowns as [UNKNOWN]\n'
    '   c. Draft plan: the complete proposed flow with [UNKNOWN] markers\n'
    '3. GATE: do not write code, run commands, or modify any files until the user replies\n'
    '   with PROCEED as the final word of their message.\n'
    '   \"yes\", \"ok\", \"sure\", \"go ahead\", \"looks good\" are NOT approval.\n'
    '   PROCEED mid-sentence is not approval either - it must be the final word.\n'
    '   If the user answers questions but does not end with PROCEED, revise and wait.'
)
print(json.dumps({'additionalContext': msg}))
"
