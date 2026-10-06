#!/usr/bin/env python3
"""Builds the figure bundle the app ships: bundle/figures.json.

  python3 bundle.py          writes the bundle and says which plan exercises have no figure yet
  python3 bundle.py --strict the same, but fails when one is missing

Shape:
  {"version": 1,
   "exercises": {"<plan exerciseId>": {"figure": "<figure id>", "cue": "<one or two short sentences>"}},
   "figures":   {"<figure id>": <the pose file from poses3d/, see FIGURES.md "The 3D format, complete">}}
Several plan exercises can share one figure (max-rep-set and volume-sets are both pull-ups).
Cues are the watch's short ones from cues.json (72 characters at most), keyed by figure id.
"""
import json, os, sys

HERE = os.path.dirname(os.path.abspath(__file__))

def main(strict):
    db = json.load(open(os.path.join(HERE, '..', 'exercise-db', 'exercises.json')))
    db = db['exercises'] if isinstance(db, dict) else db
    cues = json.load(open(os.path.join(HERE, 'cues.json')))
    figures, exercises, missing = {}, {}, []
    for e in db:
        if not e.get('planIds'):
            continue
        path = os.path.join(HERE, 'poses3d', e['id'] + '.json')
        if e['id'] not in cues:
            sys.exit(f"no cue for {e['id']}")
        if len(cues[e['id']]) > 72:
            sys.exit(f"cue too long for {e['id']}: {len(cues[e['id']])}")
        if not os.path.exists(path):
            missing.append(e['id'])
            continue
        figures[e['id']] = json.load(open(path))
        for pid in e['planIds']:
            exercises[pid] = {'figure': e['id'], 'cue': cues[e['id']]}
    out = os.path.join(HERE, 'bundle')
    os.makedirs(out, exist_ok=True)
    with open(os.path.join(out, 'figures.json'), 'w') as f:
        json.dump({'version': 1, 'exercises': exercises, 'figures': figures}, f, ensure_ascii=False,
                  separators=(',', ':'), sort_keys=True)
    size = os.path.getsize(os.path.join(out, 'figures.json'))
    print(f'{len(figures)} figures for {len(exercises)} plan exercises, {size // 1024} KB')
    if missing:
        print(f'{len(missing)} without a figure: ' + ', '.join(missing))
        if strict:
            sys.exit(1)

if __name__ == '__main__':
    main('--strict' in sys.argv)
