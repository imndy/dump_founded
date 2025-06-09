#!/bin/bash

OUTPUT=$(python3 -c "
import nbformat
import pandas as pd
import json
from bs4 import BeautifulSoup

nb = nbformat.read(open('output.ipynb'), as_version=4)
cells = [c for c in nb.cells if c.cell_type == 'code' and 'outputs' in c]

def extract_df_from_html(html):
    try:
        soup = BeautifulSoup(html, 'html.parser')
        table = soup.find('table')
        if table:
            df = pd.read_html(str(table))[0]
            return df.to_markdown(index=False)
    except Exception as e:
        return f'[Failed to parse HTML table: {e}]'
    return None

if not cells or not cells[-1]['outputs']:
    print('[No output found]')
else:
    out = cells[-1]['outputs'][0]
    if out['output_type'] == 'execute_result':
        data = out.get('data', {})
        if 'text/plain' in data:
            print(data['text/plain'])
        elif 'text/html' in data:
            print(extract_df_from_html(data['text/html']))
        else:
            print('[No printable data]')
    elif out['output_type'] == 'display_data':
        data = out.get('data', {})
        if 'text/html' in data:
            print(extract_df_from_html(data['text/html']))
        elif 'text/plain' in data:
            print(data['text/plain'])
        else:
            print('[No printable display data]')
    elif out['output_type'] == 'stream':
        print(out.get('text', '[No stream text]'))
    else:
        print('[Unsupported output format]')
")

# Escape backslashes and quotes for JSON
ESCAPED_OUTPUT=$(echo "$OUTPUT" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g')

curl -X POST "$WEBHOOK_URL" \
  -H "Content-Type: application/json" \
  -d "{\"content\": \"📋 **Active Orders Report**\\n\`\`\`\n$ESCAPED_OUTPUT\n\`\`\`\"}"
