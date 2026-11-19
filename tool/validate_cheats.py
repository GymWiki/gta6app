#!/usr/bin/env python3
"""Validate assets/cheats.json. Use --strict to require the full 61 / 10-11-21-3-16 layout."""
import json, sys
d = json.load(open(sys.argv[1] if len(sys.argv) > 1 and not sys.argv[1].startswith('--') else 'assets/cheats.json'))
cs = d['cheats']; ids = [c['id'] for c in cs]
assert len(ids) == len(set(ids)), 'duplicate ids'
dirs = {'UP', 'DOWN', 'LEFT', 'RIGHT'}
for c in cs:
    assert c['dpad_sequence'] is None or set(c['dpad_sequence']) <= dirs, c['id']
counts = {}
for c in cs: counts[c['category']] = counts.get(c['category'], 0) + 1
print(len(cs), 'cheats', counts)
if '--strict' in sys.argv:
    want = {'Player': 10, 'Combat': 11, 'Vehicles': 21, 'Environment': 3, 'Filters': 16}
    assert counts == want, f'expected {want}'
