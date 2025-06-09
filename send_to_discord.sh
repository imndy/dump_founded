#!/bin/bash

OUTPUT=$(python3 -c "
import nbformat
nb = nbformat.read(open('output.ipynb'), as_version=4)
cells = [c for c in nb.cells if c.cell_type == 'code' and 'outputs' in c]
if cells and cells[-1]['outputs']:
    out = cells[-1]['outputs'][0]
    if out['output_type'] == 'stream':
        print(out.get('text', '[No stream text]'))
    else:
        print('[Unsupported output format: ' + out['output_type'] + ']')
else:
    print('[No output found]')
")

ESCAPED_OUTPUT=$(echo "$OUTPUT" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g')

curl -X POST "$WEBHOOK_URL" \
  -H "Content-Type: application/json" \
  -d "{\"content\": \"📋 **Active Orders Report**\\n\`\`\`\n$ESCAPED_OUTPUT\n\`\`\`\"}"
