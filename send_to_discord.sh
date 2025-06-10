#!/usr/bin/env bash
set -euo pipefail

# -----------------------------------------------------------------------------
# Usage:
#   ./send_to_discord.sh --dry-run    # prints & validates JSON only
#   ./send_to_discord.sh              # actually POSTs to Discord
# -----------------------------------------------------------------------------

DRY_RUN=0
if [[ "${1:-}" == "--dry-run" ]]; then
  DRY_RUN=1
  echo "🔎 DRY RUN: no HTTP request will be sent"
fi

: "${WEBHOOK_URL:?You must export WEBHOOK_URL}"

# Build the JSON payload in one shot
PAYLOAD="$(python3 - << 'PYCODE'
import json, sys

# Load notebook
nb = json.load(open('output.ipynb'))
cells = nb.get('cells', [])
if not cells:
    sys.exit("No cells found")

# Look at the last cell
cell = cells[-1]

# Gather all text from stream, execute_result, and display_data
texts = []
for out in cell.get('outputs', []):
    t = ''
    if out.get('output_type') == 'stream':
        t = ''.join(out.get('text', []))
    elif out.get('output_type') in ('execute_result','display_data'):
        data = out.get('data', {})
        txt = data.get('text/plain') or data.get('text/html') or ''
        if isinstance(txt, list):
            txt = ''.join(txt)
        t = txt
    if t:
        texts.append(t)

# Flatten lines, strip blanks
lines = []
for block in texts:
    for line in block.splitlines():
        if line.strip():
            lines.append(line)

if not lines:
    sys.exit("No text lines found in last cell outputs")

# Take the very last non-empty line
last = lines[-1]
# Emit a valid JSON object
print(json.dumps({"content": last}))
PYCODE
)"

# Show and validate
echo "→ PAYLOAD: $PAYLOAD"
if ! printf '%s' "$PAYLOAD" | python3 -c 'import sys,json; json.load(sys.stdin)'; then
  echo "❌ Generated JSON is invalid" >&2
  exit 1
else
  echo "✅ JSON is valid"
fi

# Dry-run bail-out
if (( DRY_RUN )); then
  echo "🚫 Dry-run complete; exiting before curl"
  exit 0
fi

# Send to Discord
echo "📤 Sending to Discord…"
curl -X POST \
     -H "Content-Type: application/json" \
     -d "$PAYLOAD" \
     "$WEBHOOK_URL"
echo
