#!/usr/bin/env bash
set -euo pipefail

# ---------------------------------------------------
# Usage:
#   ./send_to_discord.sh --dry-run    # just show & validate payload
#   ./send_to_discord.sh              # actually POST
# ---------------------------------------------------

DRY_RUN=0
if [[ "${1:-}" == "--dry-run" ]]; then
  DRY_RUN=1
  echo "🔎 DRY RUN: not curling Discord"
fi

# 1) require the webhook
: "${WEBHOOK_URL:?You must export WEBHOOK_URL}"

# 2) extract the final notebook line
MESSAGE="$(python3 - << 'PYCODE'
import json,sys
nb = json.load(open('output.ipynb'))
cells = nb.get('cells', [])
if not cells:
    sys.exit(1)
# look only at the last cell
for out in reversed(cells[-1].get('outputs', [])):
    if out.get('output_type') == 'stream':
        text = ''.join(out.get('text', []))
        lines = [l for l in text.splitlines() if l.strip()]
        if lines:
            print(lines[-1])
            sys.exit(0)
sys.exit(1)
PYCODE
)"

# 3) escape it for JSON
ESCAPED=$(printf '%s' "$MESSAGE" | python3 - << 'PYCODE'
import json,sys
data = sys.stdin.read()
# json.dumps wraps in quotes; strip them back off
s = json.dumps(data)
print(s[1:-1])
PYCODE
)

# 4) build payload
PAYLOAD=$(printf '{"content":"%s"}' "$ESCAPED")

# 5) show debug info
echo "→ MESSAGE: $MESSAGE"
echo "→ JSON:    $PAYLOAD"

# 6) validate JSON
if ! printf '%s' "$PAYLOAD" | python3 -c "import sys,json; json.load(sys.stdin)"; then
  echo "❌ JSON is invalid" >&2
  exit 1
else
  echo "✅ JSON is valid"
fi

# 7) send if not dry-run
if (( DRY_RUN )); then
  echo "🚫 Dry-run; exiting before curl"
  exit 0
fi

echo "📤 Posting to Discord…"
curl -X POST \
     -H "Content-Type: application/json" \
     -d "$PAYLOAD" \
     "$WEBHOOK_URL"
echo
