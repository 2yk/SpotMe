#!/usr/bin/env python3
"""SpotMe exercise database: check a part, or check everything and write exercises.json.

  python3 validate.py parts/legs.json     check one part (links to other parts are not followed)
  python3 validate.py --check             check all parts together (links across parts, plan coverage)
  python3 validate.py --merge             the same, then write exercises.json
Exit code 1 when there are errors. Warnings are for the reviewer to read.
"""
import glob, json, os, re, sys

HERE = os.path.dirname(os.path.abspath(__file__))
PLAN = os.path.join(HERE, '..', '..', 'Packages', 'RepCoachCore', 'Sources', 'RepCoachCore', 'Resources', 'plan.json')

def vocab(name):
    """Read a vocabulary straight from SCHEMA.md so the rules and the check never drift."""
    text = open(os.path.join(HERE, 'SCHEMA.md')).read()
    m = re.search(r'\*\*' + re.escape(name) + r':\*\*(.*?)\n\n', text, re.S)
    return [w.strip() for w in m.group(1).replace('\n', ' ').split(',') if w.strip()]

BODY, MUSCLES, PATTERNS, EQUIP = vocab('bodyPart'), vocab('muscles'), vocab('pattern'), vocab('equipment')
ATTACH, LOADTYPES, LEVELS, LOGAS = vocab('attachment'), vocab('loadType'), vocab('level'), vocab('logAs')
AREAS = ['neck', 'shoulder', 'elbow', 'wrist', 'lowerBack', 'hip', 'knee', 'ankle']
KEYS = ['id', 'name', 'aliases', 'planIds', 'bodyPart', 'primaryMuscles', 'secondaryMuscles', 'pattern', 'equipment',
        'attachment', 'logAs', 'perSide', 'loadable', 'loadType', 'incrementKg', 'level', 'cue', 'injury',
        'injuryNotes', 'alternatives']
REQUIRED = [k for k in KEYS if k not in ('attachment', 'loadable', 'incrementKg')]

def plan_table():
    """Database id -> (planIds, part) from the table in SCHEMA.md."""
    text = open(os.path.join(HERE, 'SCHEMA.md')).read()
    rows = re.findall(r'^\| ([a-z0-9-]+) \| ([a-z0-9, -]+) \| ([a-z-]+) \|$', text, re.M)
    return {r[0]: ([p.strip() for p in r[1].split(',')], r[2]) for r in rows}

def plan_items():
    out = {}
    for d in json.load(open(PLAN))['days']:
        for it in d['items']:
            if it['kind'] != 'checklist':
                out[it['exerciseId']] = it
    return out

def check_entry(e, where, err):
    eid = e.get('id', '?')
    def bad(msg): err(f'{where} · {eid}: {msg}')
    for k in REQUIRED:
        if k not in e: bad(f'missing "{k}"')
    for k in e:
        if k not in KEYS: bad(f'unknown key "{k}"')
    if any(k not in e for k in REQUIRED): return
    if not re.fullmatch(r'[a-z0-9]+(-[a-z0-9]+)*', e['id']): bad('id is not kebab-case')
    if not (1 <= len(e['name']) <= 34): bad(f'name is {len(e["name"])} characters (max 34)')
    if not isinstance(e['aliases'], list) or len(e['aliases']) > 4: bad('aliases: 0–4 strings')
    if e['bodyPart'] not in BODY: bad(f'bodyPart "{e["bodyPart"]}" not in vocabulary')
    if e['pattern'] not in PATTERNS: bad(f'pattern "{e["pattern"]}" not in vocabulary')
    pm, sm = e['primaryMuscles'], e['secondaryMuscles']
    if not (1 <= len(pm) <= 3): bad('primaryMuscles: 1–3')
    if len(sm) > 4: bad('secondaryMuscles: 0–4')
    for m in pm + sm:
        if m not in MUSCLES: bad(f'muscle "{m}" not in vocabulary')
    if len(set(pm + sm)) != len(pm + sm): bad('a muscle is listed twice')
    eq = e['equipment']
    if not eq: bad('equipment is empty')
    for q in eq:
        if q not in EQUIP: bad(f'equipment "{q}" not in vocabulary')
    if 'bodyweight' in eq and len(eq) > 1: bad('bodyweight mixed with other equipment')
    if len(set(eq)) != len(eq): bad('equipment listed twice')
    if 'attachment' in e:
        if e['attachment'] not in ATTACH: bad(f'attachment "{e["attachment"]}" not in vocabulary')
        if not ({'cable-machine', 'cable-crossover', 'lat-pulldown-machine', 'seated-row-machine'} & set(eq)): bad('attachment without a cable')
    if e['logAs'] not in LOGAS: bad(f'logAs "{e["logAs"]}"')
    if not isinstance(e['perSide'], bool): bad('perSide must be true or false')
    if e['loadType'] not in LOADTYPES: bad(f'loadType "{e["loadType"]}" not in vocabulary')
    if e['level'] not in LEVELS: bad(f'level "{e["level"]}"')
    if e['logAs'] == 'weighted':
        if 'loadable' in e: bad('loadable is only for reps and timed')
        if e['loadType'] == 'bodyweight': bad('weighted but loadType is bodyweight')
        if not isinstance(e.get('incrementKg'), (int, float)) or e.get('incrementKg', 0) <= 0: bad('weighted needs incrementKg')
    else:
        if not isinstance(e.get('loadable'), bool): bad('reps/timed needs loadable true or false')
        elif e['loadable']:
            if not isinstance(e.get('incrementKg'), (int, float)) or e.get('incrementKg', 0) <= 0: bad('loadable needs incrementKg')
            if e['loadType'] == 'bodyweight': bad('loadable but loadType is bodyweight')
        else:
            if 'incrementKg' in e: bad('incrementKg on an exercise that takes no weight')
            if e['loadType'] != 'bodyweight': bad('not loadable, so loadType must be bodyweight')
    if not (10 <= len(e['cue']) <= 110): bad(f'cue is {len(e["cue"])} characters (10–110)')
    inj = e['injury']
    if sorted(inj) != sorted(AREAS): bad('injury must have exactly the eight areas')
    else:
        for a in AREAS:
            if inj[a] not in (0, 1, 2, 3): bad(f'injury.{a} must be 0–3')
        notes = e['injuryNotes']
        for a, t in notes.items():
            if a not in AREAS: bad(f'injuryNotes key "{a}"')
            elif inj[a] == 0: bad(f'injuryNotes.{a} but the rating is 0')
            if not (5 <= len(t) <= 70): bad(f'injuryNotes.{a} is {len(t)} characters (5–70)')
        for a in AREAS:
            if inj[a] >= 2 and a not in notes: bad(f'{a} is rated {inj[a]} with no injuryNotes reason')
    alts = e['alternatives']
    if not (3 <= len(alts) <= 8): bad(f'{len(alts)} alternatives (3–8)')
    seen = set()
    for a in alts:
        if sorted(a) != ['id', 'why']: bad('an alternative needs exactly "id" and "why"'); continue
        if a['id'] == e['id']: bad('lists itself as an alternative')
        if a['id'] in seen: bad(f'alternative {a["id"]} twice')
        seen.add(a['id'])
        if not (5 <= len(a['why']) <= 48): bad(f'why for {a["id"]} is {len(a["why"])} characters (5–48)')
        if a['why'].endswith('.'): bad(f'why for {a["id"]} ends with a full stop')

def check_set(entries, where_of, err, warn, complete):
    """Cross-entry checks. complete=False: links leaving the set are allowed if they are plan-table ids."""
    table = plan_table()
    by = {}
    names = {}
    for e in entries:
        if 'id' not in e: continue
        if e['id'] in by: err(f'{where_of(e)} · {e["id"]}: id used twice')
        by[e['id']] = e
        n = e.get('name', '').lower()
        if n in names: err(f'{where_of(e)} · {e["id"]}: name "{e.get("name")}" also used by {names[n]}')
        names[n] = e['id']
    for e in entries:
        if any(k not in e for k in REQUIRED): continue
        eid = e['id']
        want = table.get(eid)
        if want and sorted(e['planIds']) != sorted(want[0]): err(f'{where_of(e)} · {eid}: planIds should be {want[0]}')
        if not want and e['planIds']: err(f'{where_of(e)} · {eid}: planIds given but the id is not in the plan table')
        for a in e['alternatives']:
            if 'id' not in a: continue
            t = by.get(a['id'])
            if t is None:
                if complete or a['id'] not in table: err(f'{where_of(e)} · {eid}: alternative "{a["id"]}" does not exist')
                continue
            if 'alternatives' in t and eid not in [x.get('id') for x in t['alternatives']]:
                err(f'{where_of(e)} · {eid}: lists {a["id"]}, but {a["id"]} does not list it back')
            if t.get('bodyPart') != e['bodyPart'] and t.get('pattern') != e['pattern'] and not (set(t.get('primaryMuscles', [])) & set(e['primaryMuscles'])):
                warn(f'{eid} → {a["id"]}: different body part, pattern and main muscles')
        alts = [by[a['id']] for a in e['alternatives'] if a.get('id') in by]
        if alts and all(set(t.get('equipment', [])) == set(e['equipment']) for t in alts):
            warn(f'{eid}: every alternative needs the same equipment')
        for area in AREAS:
            r = e['injury'].get(area, 0) if isinstance(e['injury'], dict) else 0
            if r >= 2 and alts and not any(isinstance(t.get('injury'), dict) and t['injury'].get(area, 9) < r for t in alts):
                warn(f'{eid}: {area} is {r} and no alternative is easier on it')
    if complete:
        items = plan_items()
        covered = {}
        for e in entries:
            for p in e.get('planIds', []):
                if p in covered: err(f'plan id {p} is in both {covered[p]} and {e["id"]}')
                covered[p] = e['id']
                it = items.get(p)
                if not it: err(f'{e["id"]}: planId {p} is not in plan.json'); continue
                kind = {'amrap': 'reps', 'percentOfMax': 'reps'}.get(it['kind'], it['kind'])
                if e.get('logAs') != kind: err(f'{e["id"]}: logAs {e.get("logAs")} but the plan logs {p} as {kind}')
                if bool(it.get('perSide')) != e.get('perSide'): err(f'{e["id"]}: perSide differs from the plan ({p})')
                if kind != 'weighted' and bool(it.get('loadable')) != e.get('loadable'): err(f'{e["id"]}: loadable differs from the plan ({p})')
                if it.get('increment') and it['increment'] != e.get('incrementKg'): err(f'{e["id"]}: incrementKg {e.get("incrementKg")} but the plan has {it["increment"]} ({p})')
        for p in items:
            if p not in covered: err(f'plan exercise {p} is not in the database')
        for did in table:
            if did not in by: err(f'plan-table id {did} is missing')

def load(path, err):
    try:
        data = json.load(open(path))
    except Exception as x:
        err(f'{os.path.basename(path)}: not valid JSON ({x})'); return []
    if not isinstance(data, list): err(f'{os.path.basename(path)}: must be a JSON array'); return []
    return data

def main():
    errors, warnings = [], []
    write = '--merge' in sys.argv
    merge = write or '--check' in sys.argv
    paths = sorted(glob.glob(os.path.join(HERE, 'parts', '*.json'))) if merge else [a for a in sys.argv[1:] if not a.startswith('-')]
    if not paths: print(__doc__); return 2
    entries, origin = [], {}
    for p in paths:
        part = os.path.basename(p).replace('.json', '')
        for e in load(p, errors.append):
            check_entry(e, part, errors.append)
            origin[id(e)] = part
            entries.append(e)
    check_set(entries, lambda e: origin[id(e)], errors.append, warnings.append, complete=merge)
    if not merge:
        table = plan_table()
        part = os.path.basename(paths[0]).replace('.json', '') if len(paths) == 1 else None
        have = {e.get('id') for e in entries}
        for did, (_, owner) in table.items():
            if part and owner == part and did not in have: errors.append(f'{part}: plan exercise {did} is yours and is missing')
            if part and owner != part and did in have: errors.append(f'{part}: {did} belongs to part {owner}')
    for w in warnings: print('warn  ' + w)
    for x in errors: print('ERROR ' + x)
    print(f'{len(entries)} exercises · {len(errors)} errors · {len(warnings)} warnings')
    if write and not errors:
        out = []
        for e in sorted(entries, key=lambda e: (BODY.index(e['bodyPart']), e['name'].lower())):
            o = {k: e[k] for k in KEYS if k in e}
            o['avoidIf'] = [a for a in AREAS if e['injury'][a] == 3]
            o['careIf'] = [a for a in AREAS if e['injury'][a] == 2]
            out.append(o)
        doc = {'version': 1, 'injuryAreas': AREAS, 'injuryScale': {'0': 'none', '1': 'low', '2': 'take care', '3': 'avoid'},
               'vocabulary': {'bodyPart': BODY, 'muscles': MUSCLES, 'pattern': PATTERNS, 'equipment': EQUIP,
                              'attachment': ATTACH, 'loadType': LOADTYPES, 'level': LEVELS, 'logAs': LOGAS},
               'exercises': out}
        with open(os.path.join(HERE, 'exercises.json'), 'w') as f:
            json.dump(doc, f, ensure_ascii=False, indent=1)
            f.write('\n')
        print(f'wrote exercises.json ({len(out)} exercises)')
    return 1 if errors else 0

if __name__ == '__main__':
    sys.exit(main())
