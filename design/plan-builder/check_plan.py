#!/usr/bin/env python3
"""The planner's independent check of what build_plan.py produces. It shares no code with the builder.

  python3 check_plan.py                 every personas/<name>.json against plans/<name>.json
  python3 check_plan.py yeshu           one of them
Errors mean a rule in RULES.md is broken. Warnings are for the planner to read as a coach.
"""
import glob, json, os, sys

HERE = os.path.dirname(os.path.abspath(__file__))
DB = json.load(open(os.path.join(HERE, '..', 'exercise-db', 'exercises.json')))
EX = {e['id']: e for e in DB['exercises']}
WEEK = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday']
WEEKDAY = {'sunday': 1, 'monday': 2, 'tuesday': 3, 'wednesday': 4, 'thursday': 5, 'friday': 6, 'saturday': 7}
CAP = {'new': 4, 'some': 5, 'experienced': 6}
LEVELS = {'new': ['beginner'], 'some': ['beginner', 'intermediate'], 'experienced': ['beginner', 'intermediate', 'advanced']}
REGION = {'chest': 'chest', 'back': 'back', 'shoulders': 'shoulders', 'biceps': 'arms', 'triceps': 'arms', 'forearms': 'arms',
          'quads': 'quads', 'hamstrings': 'glutesHamstrings', 'glutes': 'glutesHamstrings', 'calves': 'calves', 'hips': 'glutesHamstrings', 'core': 'core',
          'neck': 'other', 'full-body': 'core'}

def minutes(item):
    rest = item.get('restSec', 0) / 60
    if item['kind'] == 'timed':
        return item['sets'] * (item['secMax'] * (2 if item.get('perSide') else 1) / 60 + rest)
    return item['sets'] * ((1.2 if item.get('perSide') else 0.7) + rest)

def check(name):
    a = json.load(open(os.path.join(HERE, 'personas', name + '.json')))
    p = json.load(open(os.path.join(HERE, 'plans', name + '.json')))
    err, warn = [], []
    have = set(a['equipment']) | {'bodyweight', 'wall'}
    notes = ' '.join(p.get('summary', {}).get('notes', []))
    if [d['key'] for d in p['days']] != WEEK: err.append('days are not Monday to Sunday, all seven')
    training = [d for d in p['days'] if any(i['kind'] != 'checklist' for i in d['items'])]
    want = min(len(a['days']), CAP[a['experience']])
    if len(training) != want: err.append(f'{len(training)} training days, expected {want}')
    for d in training:
        if d['key'] not in a['days']: err.append(f'{d["key"]} is a training day but was not picked')
    for d in p['days']:
        if d.get('weekday') != WEEKDAY[d['key']]: err.append(f'{d["key"]}: weekday {d.get("weekday")}')
    weekly, used = {}, {}
    for d in training:
        items = d['items']
        if items[0]['kind'] != 'checklist' or 'Warmup' not in items[0]['name']: err.append(f'{d["key"]}: does not start with the warmup')
        if items[-1]['kind'] != 'checklist' or 'Cooldown' not in items[-1]['name']: err.append(f'{d["key"]}: does not end with the cooldown')
        lifts = [i for i in items if i['kind'] != 'checklist']
        if len(lifts) < 3: warn.append(f'{d["key"]}: only {len(lifts)} exercises')
        seen = set()
        total = 10.0
        for i in lifts:
            e = EX.get(i['exerciseId'])
            where = f'{d["key"]} · {i.get("name")}'
            if not e: err.append(f'{where}: not in the database'); continue
            if i['exerciseId'] in seen: err.append(f'{where}: twice in one day')
            seen.add(i['exerciseId'])
            used.setdefault(i['exerciseId'], []).append(d['key'])
            missing = set(e['equipment']) - have
            if missing: err.append(f'{where}: needs {sorted(missing)}')
            for area, how in a.get('injuries', {}).items():
                r = e['injury'][area]
                if how == 'avoid' and r > 1: err.append(f'{where}: {area} is {r}, marked avoid')
                if how == 'care' and r > 2: err.append(f'{where}: {area} is {r}, marked take care')
                if how == 'care' and r == 2: warn.append(f'{where}: {area} is 2 (take care)')
            if e['level'] not in LEVELS[a['experience']]: warn.append(f'{where}: level {e["level"]} for a {a["experience"]} lifter')
            if i['name'] != e['name']: err.append(f'{where}: name differs from the database')
            if i['kind'] != e['logAs']: err.append(f'{where}: kind {i["kind"]}, database logs it as {e["logAs"]}')
            if bool(i.get('perSide')) != e['perSide']: err.append(f'{where}: perSide differs from the database')
            if 'incrementKg' in e and i.get('increment') != e['incrementKg']: err.append(f'{where}: increment {i.get("increment")} vs {e["incrementKg"]}')
            if not (2 <= i.get('sets', 0) <= 5): err.append(f'{where}: {i.get("sets")} sets')
            if a['goal'] == 'fit' and i.get('sets', 0) > 4: err.append(f'{where}: {i["sets"]} sets on a fit plan')
            if i['kind'] == 'timed':
                if not (i.get('secMin') and i.get('secMax')): err.append(f'{where}: timed without seconds')
            else:
                if not (i.get('repMin') and i.get('repMax')): err.append(f'{where}: no rep range')
                elif i['repMin'] < 6 and (a['experience'] == 'new' or (a.get('age') or 0) >= 50): err.append(f'{where}: {i["repMin"]}–{i["repMax"]} reps for a new or 50+ lifter')
            if i.get('restSec', 0) % 15: err.append(f'{where}: rest {i.get("restSec")} is not a multiple of 15')
            if i['kind'] == 'weighted' and i.get('sessionsAtTopToProgress') != 1: err.append(f'{where}: sessionsAtTopToProgress')
            total += minutes(i)
            weekly[REGION[e['bodyPart']]] = weekly.get(REGION[e['bodyPart']], 0) + i['sets']
        stated = int(''.join(ch for ch in d['time'] if ch.isdigit()) or 0)
        if abs(stated - total) > 3: err.append(f'{d["key"]}: says {d["time"]}, works out at {total:.0f} min')
        if total > a['minutes'] + 5 and 'over' not in notes: err.append(f'{d["key"]}: {total:.0f} min for a {a["minutes"]}-minute session, and no note says so')
        if total < a['minutes'] - 15: warn.append(f'{d["key"]}: {total:.0f} min of a {a["minutes"]}-minute session')
    for g in ('chest', 'back', 'quads', 'glutesHamstrings'):
        if weekly.get(g, 0) < 4: warn.append(f'weekly sets for {g}: {weekly.get(g, 0)}')
    for g, n in weekly.items():
        if n > 26: warn.append(f'weekly sets for {g}: {n}')
    for g in ('shoulders', 'arms', 'core'):
        if weekly.get(g, 0) == 0: warn.append(f'nothing for {g} all week')
    for ex, days in used.items():
        if len(days) >= 3: warn.append(f'{EX[ex]["name"]} on {len(days)} days')
    stated = p.get('summary', {}).get('weeklySets', {})
    if {k: v for k, v in stated.items() if v} != {k: v for k, v in weekly.items() if k != 'other' and v}: err.append(f'weeklySets in the summary {stated} do not match the plan {weekly}')
    print(f'== {name}: {len(training)} days · weekly sets {dict(sorted(weekly.items()))}')
    for w in warn: print('  warn  ' + w)
    for x in err: print('  ERROR ' + x)
    return len(err)

if __name__ == '__main__':
    names = sys.argv[1:] or sorted(os.path.basename(f)[:-5] for f in glob.glob(os.path.join(HERE, 'personas', '*.json')))
    bad = sum(check(n) for n in names if os.path.exists(os.path.join(HERE, 'plans', n + '.json')))
    print(f'{len(names)} plans checked, {bad} errors')
    sys.exit(1 if bad else 0)
