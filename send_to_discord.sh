#!/usr/bin/env bash
set -euo pipefail

# Ensure the webhook URL is provided
: "${WEBHOOK_URL:?Need to set WEBHOOK_URL}"

# 1) Extract the final cell’s last non-empty line
MESSAGE="$(python3 - << 'PYCODE'
import json, sys
nb = json.load(open('output.ipynb'))
cells = nb.get('cells', [])
if not cells:
    sys.exit(1)
for out in reversed(cells[-1].get('outputs', [])):
    if out.get('output_type') == 'stream':
        text = ''.join(out.get('text', []))
        lines = [l for l in text.splitlines() if l.strip()]
        if lines:
            print(lines[-1])
            sys.exit(0)
# nothing found
sys.exit(1)
PYCODE
)"

# 2) JSON-escape it
ESCAPED=$(printf '%s' "$MESSAGE" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read())[1:-1])')

# 3) Send to Discord
curl -X POST \
     -H "Content-Type: application/json" \
     -d "{\"content\":\"$ESCAPED\"}" \
     "$WEBHOOK_URL"
