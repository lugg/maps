"""Average CPU (% of one core) of the example app and backboardd on a physical
iPhone, from an Instruments Activity Monitor trace, plus the thermal state.

Usage: python3 -I device-cpu.py <DEVICE_UDID> <label> [seconds]
Appends the line to /tmp/maps-e2e/results.tsv.
"""
import os
import re
import subprocess
import sys
import xml.etree.ElementTree as ET

udid, label = sys.argv[1], sys.argv[2]
seconds = sys.argv[3] if len(sys.argv) > 3 else '30'
work = '/tmp/maps-e2e'
trace = f'{work}/device.trace'
os.makedirs(work, exist_ok=True)


def run(*args):
    return subprocess.run(args, capture_output=True, text=True)


# xctrace often reports the device as still booting; a devicectl call first
# wakes the connection
for _ in range(3):
    run('xcrun', 'devicectl', 'device', 'info', 'details', '--device', udid)
    run('rm', '-rf', trace)
    record = run('xcrun', 'xctrace', 'record', '--template', 'Activity Monitor',
                 '--device', udid, '--all-processes', '--time-limit', f'{seconds}s',
                 '--output', trace)
    if record.returncode == 0:
        break
else:
    sys.exit(f'xctrace record failed: {record.stdout[-300:]}{record.stderr[-300:]}')


def export(schema):
    xpath = f'/trace-toc/run[@number="1"]/data/table[@schema="{schema}"]'
    return run('xcrun', 'xctrace', 'export', '--input', trace, '--xpath', xpath).stdout


states = re.findall(r'fmt="(Nominal|Fair|Serious|Critical)"', export('device-thermal-state-intervals'))
thermal = states[-1] if states else '?'

# Rows reference earlier values by id, so resolve refs while walking
ids = {}


def value(el):
    if 'ref' in el.attrib:
        return ids[el.attrib['ref']]
    v = el.attrib.get('fmt') if el.tag == 'process' else el.text
    if 'id' in el.attrib:
        ids[el.attrib['id']] = v
    for child in el:
        value(child)
    return v


samples = {}
root = ET.fromstring(export('activity-monitor-process-live'))
cols = [m.text for m in root.iter('mnemonic')]
for row in root.iter('row'):
    cells = dict(zip(cols, (value(c) for c in row)))
    name, start, total = cells.get('process'), cells.get('start'), cells.get('cpu-total')
    if name and start and total:
        samples.setdefault(name, []).append((int(start), int(total)))

parts = []
for name, points in samples.items():
    if not name.startswith(('LuggMapsExample', 'backboardd')):
        continue
    points.sort()
    (t0, c0), (t1, c1) = points[0], points[-1]
    if t1 > t0:
        parts.append(f'{name.split(" (")[0]} {(c1 - c0) / (t1 - t0) * 100:.1f}% ({(t1 - t0) / 1e9:.0f}s)')

line = f'{label} [{thermal}]\t' + '\t'.join(sorted(parts, reverse=True))
print(line)
with open(f'{work}/results.tsv', 'a') as f:
    f.write(line + '\n')
