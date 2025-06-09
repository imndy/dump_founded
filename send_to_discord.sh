#!/bin/bash

OUTPUT=$(python3 -c "
import nbformat
import json
import pandas as pd
from bs4 import BeautifulSoup

nb = nbformat.read(open('output.ipynb'), as_version=4)
cells = [c for c in nb.cells if c.cell_type == 'code' and 'outputs' in c]

if not cells or not cells[-1]['outputs']:
    print('[No output found]')
else:
    out = cells[-1]['outputs'][0]
    if out['output_type'] == 'display_data' and 'text/html' in out['data']:
        html = out['data']['text/html']
        soup = BeautifulSoup(html, 'html.parser')
        table = soup.find('table')
        if table:
            df = pd.read_html(str(table))[0]
            print(df.to_markdown(index=False))
        else:
            print('[No HTML table found]')
    elif 'text/plain' in out.get('data', {}):
        print(out['data']['text/plain'])
    else:
        print('[Unsupported output format]')
")

# escape for Discord
ESCAPED_OUTPUT=$(echo "$OUTPUT" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g')

curl -X POST "$WEBHOOK_URL" \
  -H "Content-Type: application/json" \
  -d "{\"content\": \"📋 **Active Orders Report**\\n\`\`\`\n$ESCAPED_OUTPUT\n\`\`\`\"}"
