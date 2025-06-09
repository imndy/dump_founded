#!/bin/bash

OUTPUT=$(python3 -c "
import nbformat
nb = nbformat.read(open('output.ipynb'), as_version=4)
cells = [c for c in nb.cells if c.cell_type == 'code' and 'outputs' in c]
if cells and cells[-1]['outputs']:
    out = cells[-1]['outputs'][0]
    print(out.get('text', out.get('data', {}).get('text/plain', '[No text output]')))
else:
    print('[No output found]')
")

curl -X POST "$WEBHOOK_URL" \
  -H "Content-Type: application/json" \
  -d "{\"content\": \"📋 **Active Orders Report**\\n\`\`\`\n$OUTPUT\n\`\`\`\"}"
