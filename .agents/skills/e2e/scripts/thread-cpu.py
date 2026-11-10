"""Per-thread CPU (% of one core) of the example app from a time-profile XML
(argent native-profiler-stop `exportedFiles.cpu`), and the main thread's
inclusive time under each frame name given.

Usage: python3 -I thread-cpu.py <cpu.xml> <seconds> [frame substring ...]
"""
import sys
import xml.etree.ElementTree as ET
from collections import Counter

path, seconds, wanted = sys.argv[1], float(sys.argv[2]), sys.argv[3:]
root = ET.parse(path).getroot()
ids = {}


def register(el):
    if 'id' in el.attrib:
        ids[el.attrib['id']] = el
    for child in el:
        register(child)


def resolve(el):
    return ids[el.attrib['ref']] if el is not None and 'ref' in el.attrib else el


def pct(ns):
    return f'{ns / 1e9 / seconds * 100:5.1f}%'


threads = Counter()
frames = Counter()
for row in root.iter('row'):
    register(row)
    thread = resolve(row.find('thread'))
    weight = resolve(row.find('weight'))
    if thread is None or weight is None:
        continue
    name = thread.attrib.get('fmt', '?')
    if 'LuggMapsExample' not in name:
        continue
    ns = int(weight.text)
    threads[name.split(' (0x')[0]] += ns
    if wanted and name.startswith('Main Thread'):
        backtrace = resolve(row.find('tagged-backtrace')) or resolve(row.find('backtrace'))
        if backtrace is None:
            continue
        names = {resolve(f).attrib.get('name', '') for f in backtrace.iter('frame')}
        for w in wanted:
            if any(w in n for n in names):
                frames[w] += ns

for name, ns in threads.most_common(8):
    print(f'{pct(ns)}  {name}')
if wanted:
    print('main thread, inclusive:')
    for w in wanted:
        print(f'{pct(frames[w])}  {w}')
