#!/usr/bin/env python3
"""Ramp-up sets: the reference for a NEW engine function (approved by Yeshu, 6 Oct 2026).

Nothing here changes existing engine behaviour. To build it, follow the repo rule: copy `ramp_ups` and the
vectors below into docs/engine_reference.py, run it, pin the Swift tests to its output, then write
ProgressionEngine.rampUps. Rounding uses the engine's own round_down.

  python3 rampup_reference.py      prints the vectors
"""
import math

def round_down(x, inc):
    return math.floor(x / inc + 1e-9) * inc

# (factor of the working weight, reps) per role
TABLE = {
    'first': [(0.50, 8), (0.75, 4)],   # the first main lift of the day
    'main':  [(0.70, 5)],              # every other main lift
    'small': [(0.70, 5)],              # smaller lifts, only with the setting "Every weighted lift"
}

def role(day_items, index):
    """day_items: the day's items in today's order, each a dict(kind, restSec). Main lift = weighted with
    rest of 120 s or more. The first main lift in the day's order is 'first'. Fixed by the plan's order,
    not by the order the exercises are done in."""
    it = day_items[index]
    if it['kind'] != 'weighted':
        return None
    if it.get('restSec', 0) < 120:
        return 'small'
    earlier = [i for i in day_items[:index] if i['kind'] == 'weighted' and i.get('restSec', 0) >= 120]
    return 'main' if earlier else 'first'

def ramp_ups(working, inc, rep_max, role, setting='main', bodyweight_base=False):
    """working: today's working weight for set 1 (the engine's first target; the deload weight in a deload
    week). None when there is no history yet. Returns [(weight_kg, reps)], lightest first.
    setting: 'off', 'main' (default) or 'all'.
    bodyweight_base: the logged weight is added to bodyweight (weighted pull-ups). Weight 0 = bodyweight only."""
    if role is None or setting == 'off' or working is None:
        return []
    if role == 'small' and setting != 'all':
        return []
    out = []
    if bodyweight_base:
        if working <= 0:
            return []
        out.append((0.0, min(5, rep_max)))
        if role == 'first':
            w = round_down(working * 0.5, inc)
            if 0 < w < working:
                out.append((w, min(3, rep_max)))
        return out
    for factor, reps in TABLE[role]:
        w = round_down(working * factor, inc)
        if w <= 0 or w >= working:
            continue
        if out and w <= out[-1][0]:
            continue
        out.append((w, min(reps, rep_max)))
    return out

REST_AFTER_RAMP_UP_SEC = 60

VECTORS = [
    # name, working, inc, rep_max, role, setting, bodyweight_base
    ('Incline DB Press 22.5, first', 22.5, 2.5, 10, 'first', 'main', False),
    ('20 kg x 12 case, first', 20.0, 2.5, 12, 'first', 'main', False),
    ('Machine Chest Press 45, main', 45.0, 5.0, 10, 'main', 'main', False),
    ('Seated DB Shoulder Press 17.5, main', 17.5, 2.5, 10, 'main', 'main', False),
    ('Leg Press 120, first', 120.0, 10.0, 12, 'first', 'main', False),
    ('Leg Press 40, first', 40.0, 10.0, 12, 'first', 'main', False),
    ('Leg Press 20, first (second equals first: left out)', 20.0, 10.0, 12, 'first', 'main', False),
    ('Leg Press 10, first (rounds to zero: none)', 10.0, 10.0, 12, 'first', 'main', False),
    ('Hip Thrust 60 inc 5, main', 60.0, 5.0, 12, 'main', 'main', False),
    ('DB 5 kg, first', 5.0, 2.5, 10, 'first', 'main', False),
    ('DB 2.5 kg, main (rounds to zero)', 2.5, 2.5, 10, 'main', 'main', False),
    ('Cable Lateral Raise 7.5, small, setting main', 7.5, 2.5, 15, 'small', 'main', False),
    ('Cable Lateral Raise 7.5, small, setting all', 7.5, 2.5, 15, 'small', 'all', False),
    ('DB Lateral Raise 6 inc 1, small, setting all', 6.0, 1.0, 20, 'small', 'all', False),
    ('Incline DB Press 22.5, first, setting off', 22.5, 2.5, 10, 'first', 'off', False),
    ('First time (no working weight)', None, 2.5, 10, 'first', 'main', False),
    ('Deload week: Incline DB Press at 20 (0.85 x 22.5 rounded), first', 20.0, 2.5, 10, 'first', 'main', False),
    ('Weighted Pull-ups +15, first', 15.0, 2.5, 5, 'first', 'main', True),
    ('Weighted Pull-ups +2.5, first (half rounds to zero)', 2.5, 2.5, 5, 'first', 'main', True),
    ('Weighted Pull-ups +15, main', 15.0, 2.5, 5, 'main', 'main', True),
    ('Weighted Pull-ups bodyweight only, first', 0.0, 2.5, 5, 'first', 'main', True),
    ('Heavy low-rep lift 100 inc 2.5 range 3-5, first (reps capped at the top of the range)', 100.0, 2.5, 5, 'first', 'main', False),
]

def fmt(sets):
    return ', '.join(f'{w:g} x {r}' for w, r in sets) or 'none'

if __name__ == '__main__':
    for name, working, inc, rep_max, r, setting, bw in VECTORS:
        print(f'{name}: {fmt(ramp_ups(working, inc, rep_max, r, setting, bw))}')
    wed = [dict(kind='checklist'), dict(kind='weighted', restSec=150), dict(kind='weighted', restSec=150),
           dict(kind='weighted', restSec=150), dict(kind='weighted', restSec=75), dict(kind='reps', restSec=45)]
    print('Wednesday roles:', [role(wed, i) for i in range(len(wed))])
