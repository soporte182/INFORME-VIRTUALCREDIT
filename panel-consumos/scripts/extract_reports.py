from pathlib import Path
from pypdf import PdfReader
import json, re

root = Path(__file__).resolve().parents[2]
months = ['marzo','abril','mayo','junio','julio','agosto']
data=[]
for i,p in enumerate(sorted(root.glob('*.pdf'))):
    text=PdfReader(p).pages[2].extract_text()
    rows=[]
    for line in text.splitlines():
        m=re.fullmatch(r'(.+?)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)',line.strip())
        if m and m[1]!='Total':
            name=m[1]; identity,debtor,codebtor,total,campaigns,messages=map(int,m.groups()[1:])
            assert debtor+codebtor==total
            rows.append(dict(entity=name,debtor=debtor,codebtor=codebtor))
    expected=[981,923,1030,1002,1189,1210][i]
    assert sum(r['debtor']+r['codebtor'] for r in rows)==expected
    data.append(dict(month=f'2026-{i+3:02}',source=p.name,rows=rows))
assert sum(r['debtor']+r['codebtor'] for m in data for r in m['rows'])==6335
out=root/'panel-consumos/lib/initial-data.json'
out.write_text(json.dumps(data,ensure_ascii=False,indent=2),encoding='utf-8')
print('Verified 6 months: 6335 consumed; 8665 remaining.')
