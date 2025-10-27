from pathlib import Path
import sys
p = Path('coverage') / 'lcov.info'
if not p.exists():
    print('lcov.info not found at', p)
    sys.exit(1)
lf_total = 0
lh_total = 0
with p.open('r', encoding='utf-8', errors='ignore') as f:
    for line in f:
        line = line.strip()
        if line.startswith('LF:'):
            try:
                lf_total += int(line.split(':',1)[1])
            except Exception:
                pass
        elif line.startswith('LH:'):
            try:
                lh_total += int(line.split(':',1)[1])
            except Exception:
                pass
print(f'LF={lf_total} LH={lh_total}')
if lf_total:
    pct = lh_total / lf_total * 100
    print(f'Pct={pct:.2f}%')
else:
    print('No lines found')

