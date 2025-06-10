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
