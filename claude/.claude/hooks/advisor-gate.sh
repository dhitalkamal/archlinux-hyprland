#!/bin/bash
set -euo pipefail

# PreToolUse gate on Write|Edit|NotebookEdit. replacement for design-advisor-gate.sh.
#
# maps each gateable feature-kickoff step to (file pattern -> required local mcp
# advisor call) and BLOCKS the write until that advisor actually appears in the
# session transcript. this is the enforcing version of the old gate, which only
# reminded and never checked whether the advisor was really consulted.
#
# local advisors only - the remote foundry-* fleet (schema-designer, migration,
# etc.) lives on the homelab over tailscale and is dead whenever that host is off,
# so gating on it would trap the user. schema-design and db-migration steps are
# therefore left as unenforced prose in the skill, on purpose.
#
# behavior per matched rule:
# - required mcp tool prefix already in the transcript -> silent pass (exit 0)
# - not yet called -> permissionDecision "ask" naming the exact tool
# safety valve: gives up after 2 asks per session (mirrors feature-workflow-gate
# and worktree-policy-gate) so a model that will not call the tool is not trapped.
#
# priority when a path matches more than one rule: most specific first
# (endpoint > event-contract > frontend-accessibility > api-docs > generic new
# file placement), since the more specific advisor is the more useful one.
#
# promotion (human review gate): move this to ~/.claude/hooks/advisor-gate.sh,
# chmod +x, then in settings.json replace the design-advisor-gate.sh command in
# the PreToolUse "Write|Edit|NotebookEdit" block with this script's path. remove
# design-advisor-gate.sh once this is confirmed working.

INPUT=$(cat)

# transcript + session are needed for the "was the advisor actually called" check
# and the safety-valve counter. bail quietly if the harness did not supply them.
TRANSCRIPT=$(echo "$INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('transcript_path',''))" 2>/dev/null || echo "")
SESSION_ID=$(echo "$INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('session_id',''))" 2>/dev/null || echo "")

[ -z "$SESSION_ID" ] && exit 0
[ -z "$TRANSCRIPT" ] && exit 0
[ ! -f "$TRANSCRIPT" ] && exit 0

COUNTER_FILE="/tmp/.advisor-gate-count-${SESSION_ID}"
COUNT=0
[ -f "$COUNTER_FILE" ] && COUNT=$(cat "$COUNTER_FILE" 2>/dev/null || echo 0)

# safety valve: after 2 asks in this session, stop gating so nothing gets trapped
if [ "$COUNT" -ge 2 ]; then
	rm -f "$COUNTER_FILE"
	exit 0
fi

# all rule matching + the transcript check happen in python for clean pattern and
# json handling. it prints "ask <tool> <reason>" on a block, or nothing on a pass.
RESULT=$(TRANSCRIPT_PATH="$TRANSCRIPT" python3 -c "
import sys, json, os, fnmatch

try:
    data = json.load(sys.stdin)
except (json.JSONDecodeError, ValueError):
    sys.exit(0)

tool = data.get('tool_name', '')
ti = data.get('tool_input', {}) or {}
file_path = ti.get('file_path') or ti.get('notebook_path') or ''
if not file_path:
    sys.exit(0)

basename = os.path.basename(file_path)
parts = set(p for p in file_path.split('/') if p)

# ordered rules, most specific first. each: (matched, required mcp tool prefix,
# human tool name for the reason string). schema and migration are intentionally
# absent - their only advisor is remote.
def match_endpoint():
    return (
        basename in ('views.py', 'urls.py')
        or bool(parts & {'routes', 'controllers', 'endpoints'})
        or ('api' in parts and basename.endswith('.ts'))
    )

def match_event():
    return (
        bool(parts & {'events', 'kafka', 'topics'})
        or fnmatch.fnmatch(basename, '*producer*')
        or fnmatch.fnmatch(basename, '*consumer*')
        or basename.endswith(('.avsc', '.proto'))
    )

def match_frontend():
    return basename.endswith(('.tsx', '.jsx', '.vue', '.svelte', '.html'))

def match_apidocs():
    b = basename.lower()
    return b.startswith('openapi') or b.startswith('asyncapi')

def match_newfile():
    # generic placement check only for brand-new files (Write to a missing path)
    return tool == 'Write' and not os.path.exists(file_path)

rules = [
    (match_endpoint(), 'mcp__endpoint-advisor__propose_api_design',
     'endpoint/route change - consult endpoint-advisor (propose_api_design)'),
    (match_event(), 'mcp__kafka-mcp__describe_topic',
     'event/topic change - consult kafka-mcp (describe_topic) for the contract'),
    (match_frontend(), 'mcp__structure-advisor__check_frontend_accessibility',
     'frontend markup - consult structure-advisor (check_frontend_accessibility)'),
    (match_apidocs(), 'mcp__endpoint-advisor__generate_openapi_doc',
     'api spec doc - consult endpoint-advisor (generate_openapi_doc)'),
    (match_newfile(), 'mcp__structure-advisor__audit_placement',
     'new file - consult structure-advisor (audit_placement) for correct placement'),
]

hit = next((r for r in rules if r[0]), None)
if hit is None:
    sys.exit(0)

_, tool_prefix, reason = hit

# was this advisor already called this session? scan the transcript for a tool_use
# whose name starts with the required prefix. same approach feature-workflow-gate
# uses for AskUserQuestion.
called = False
try:
    with open(os.environ['TRANSCRIPT_PATH']) as f:
        for line in f:
            line = line.strip()
            if not line or tool_prefix not in line:
                continue
            try:
                entry = json.loads(line)
            except json.JSONDecodeError:
                continue
            content = entry.get('message', {}).get('content', [])
            if not isinstance(content, list):
                continue
            for block in content:
                if (isinstance(block, dict) and block.get('type') == 'tool_use'
                        and str(block.get('name', '')).startswith(tool_prefix)):
                    called = True
                    break
            if called:
                break
except Exception:
    # if the transcript cannot be read, do not block - fail open
    sys.exit(0)

if called:
    sys.exit(0)

# emit a compact ask marker for the shell wrapper to turn into the hook decision
print('ASK\t' + tool_prefix + '\t' + reason + ' (' + file_path + ')')
" <<<"$INPUT" || echo "")

# no marker -> nothing to gate (advisor already used, or no rule matched)
[ -z "$RESULT" ] && exit 0

REASON=$(printf '%s' "$RESULT" | cut -f3-)

# count this ask against the safety valve, then emit the PreToolUse decision
echo $((COUNT + 1)) > "$COUNTER_FILE"

REASON="$REASON" python3 -c "
import json, os
print(json.dumps({'hookSpecificOutput': {
    'hookEventName': 'PreToolUse',
    'permissionDecision': 'ask',
    'permissionDecisionReason': os.environ['REASON'] +
        ' - call the tool first, or approve to proceed without it if this change does not need it.',
}}))
"
exit 0
