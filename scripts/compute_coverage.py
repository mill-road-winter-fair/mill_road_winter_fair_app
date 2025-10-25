import re
from pathlib import Path

lcov_path = Path('coverage') / 'lcov.info'
if not lcov_path.exists():
    print('lcov.info not found at', lcov_path)
    raise SystemExit(1)

lf_total = 0
lh_total = 0

with lcov_path.open('r', encoding='utf-8') as f:
    for line in f:
        line=line.strip()
        if line.startswith('LF:'):
            try:
                lf_total += int(line.split(':',1)[1])
            except:
                pass
        elif line.startswith('LH:'):
            try:
                lh_total += int(line.split(':',1)[1])
            except:
                pass

if lf_total == 0:
    print('No lines found in lcov')
else:
    percent = (lh_total / lf_total) * 100
    print(f'Covered lines: {lh_total} / {lf_total} => {percent:.2f}%')

