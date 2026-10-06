"""Reference implementation of the RepCoach progression engine.

The Swift ProgressionEngine must produce exactly these results; the vectors printed
at the bottom are copied into ProgressionEngineTests.swift.
"""
import math

def round_near(x, inc):  # matches Swift (x / inc).rounded() * inc  (half away from zero)
    return round(math.floor(x / inc + 0.5) * inc, 2)

def round_down(x, inc):
    return round(math.floor(x / inc + 1e-9) * inc, 2)

def e1rm(w, r):
    """Epley estimated one-rep max."""
    return round(w * (1 + r / 30), 2)

def working_sets(p, sess):
    return sess[: p["sets"]]

def working_weight(p, sess):
    """The weight a session was trained at: the first set's, or a heavier one reached within the session
    with at least the bottom of the range (a raise after a set that was too light, or a change by hand).
    A heavier attempt that fell short of the range doesn't count."""
    sets = working_sets(p, sess)
    return max([sets[0][0]] + [w for (w, r) in sets if r >= p["repMin"]])

def dropped_below(sets, w):
    """The weight went back under `w` after reaching it."""
    reached = False
    for (sw, _) in sets:
        if sw >= w:
            reached = True
        elif reached:
            return True
    return False

def at_top(p, sess):
    """Every planned set at the top of the range or above, never going back under the working weight."""
    sets = working_sets(p, sess)
    w = working_weight(p, sess)
    return len(sets) >= p["sets"] and all(r >= p["repMax"] for (_, r) in sets) and not dropped_below(sets, w)

def missed(p, sess):
    """Too few sets, a set at or under the working weight below the range, or a drop under it."""
    sets = working_sets(p, sess)
    w = working_weight(p, sess)
    return (len(sets) < p["sets"]
            or any(r < p["repMin"] and sw <= w for (sw, r) in sets)
            or dropped_below(sets, w))

def first_target(p, history, deload=False):
    """history: list of sessions newest first; each session = list of (weight, reps). Deload sessions excluded by caller."""
    if not history:
        return (None, "firstTime", sets_for(p, deload))
    work = working_weight(p, history[0])
    top = 0
    for sess in history:
        if working_weight(p, sess) == work and at_top(p, sess):
            top += 1
        else:
            break
    if top >= p.get("need", 1):
        w, why = work + p["inc"], "increase"
    elif (len(history) >= 2 and working_weight(p, history[1]) == work
          and missed(p, history[0]) and missed(p, history[1])):
        w = round_down(work * 0.9, p["inc"])
        if w > work - p["inc"]:
            w = work - p["inc"]
        w, why = max(w, 0.0), "decrease"
    else:
        w, why = work, "repeat"
    if deload:
        w, why = round_near(w * 0.85, p["inc"]), "deload"
    return (round(w, 2), why, sets_for(p, deload))

def sets_for(p, deload):
    return math.ceil(p["sets"] / 2) if deload else p["sets"]

def next_set(p, w, r, set_index, total):
    if r < p["repMin"]:
        d = p["repMin"] - r
        pct = min(0.20, 0.05 * d)
        nw = round_down(w * (1 - pct), p["inc"])
        if nw > w - p["inc"]:
            nw = w - p["inc"]
        return (max(round(nw, 2), 0.0), "dropWeight")
    if r >= p["repMax"] + 2 and set_index < total:
        # The weight this set's effort would lift for the top of the range, rounded down:
        # at least one increment heavier, at most two.
        top = round_down(e1rm(w, r) / (1 + p["repMax"] / 30), p["inc"])
        nw = min(max(top, w + p["inc"]), w + 2 * p["inc"])
        return (round(nw, 2), "raiseWeight")
    return (w, "keep")

def volume_reps(amrap, pct=0.6):
    return max(1, math.floor(amrap * pct + 0.5))

def reached_top(sets, top, planned):
    """reps and timed kinds: every planned set reached the top of the range (seconds for timed).
    No weight change follows; the app says "Top of range. Add weight or make it harder next time." """
    done = sets[:planned]
    return len(done) >= planned and all(s >= top for s in done)

# Ramp-up sets (new, approved 6 Oct 2026): one or two lighter, short sets before the first working set.
# They are never counted: not in history, progression, charts or set counts. Nothing above changes.

# (factor of the working weight, reps) per role
RAMP_UP_TABLE = {
    "first": [(0.50, 8), (0.75, 4)],   # the first main lift of the day
    "main":  [(0.70, 5)],              # every other main lift
    "small": [(0.70, 5)],              # smaller lifts, only with the setting "Every weighted lift"
}

REST_AFTER_RAMP_UP_SEC = 60

def role(day_items, index):
    """day_items: the day's items in today's order, each a dict(kind, restSec). Main lift = weighted with
    rest of 120 s or more. The first main lift in the day's order is 'first'. Fixed by the plan's order,
    not by the order the exercises are done in."""
    it = day_items[index]
    if it["kind"] != "weighted":
        return None
    if it.get("restSec", 0) < 120:
        return "small"
    earlier = [i for i in day_items[:index] if i["kind"] == "weighted" and i.get("restSec", 0) >= 120]
    return "main" if earlier else "first"

def ramp_ups(working, inc, rep_max, role, setting="main", bodyweight_base=False):
    """working: today's working weight for set 1 (the first target; the deload weight in a deload week).
    None when there is no history yet. Returns [(weight_kg, reps)], lightest first.
    setting: 'off', 'main' (default) or 'all'.
    bodyweight_base: the logged weight is added to bodyweight (weighted pull-ups). Weight 0 = bodyweight only."""
    if role is None or setting == "off" or working is None:
        return []
    if role == "small" and setting != "all":
        return []
    out = []
    if bodyweight_base:
        if working <= 0:
            return []
        out.append((0.0, min(5, rep_max)))
        if role == "first":
            w = round_down(working * 0.5, inc)
            if 0 < w < working:
                out.append((w, min(3, rep_max)))
        return out
    for factor, reps in RAMP_UP_TABLE[role]:
        w = round_down(working * factor, inc)
        if w <= 0 or w >= working:
            continue
        if out and w <= out[-1][0]:
            continue
        out.append((w, min(reps, rep_max)))
    return out

P = dict(sets=3, repMin=8, repMax=12, inc=2.5)
PU = dict(sets=5, repMin=3, repMax=5, inc=2.5, need=2)
LP = dict(sets=4, repMin=8, repMax=12, inc=10.0)
LAT = dict(sets=3, repMin=15, repMax=20, inc=1.0)

cases = [
 ("first: no history", first_target(P, [])),
 ("first: all sets at top -> increase", first_target(P, [[(20, 12), (20, 12), (20, 12)]])),
 ("first: in range -> repeat", first_target(P, [[(20, 12), (20, 11), (20, 10)]])),
 ("first: pull-up needs 2 sessions, only 1", first_target(PU, [[(15, 5)] * 5, [(15, 5), (15, 4), (15, 4), (15, 4), (15, 3)]])),
 ("first: pull-up 2 sessions at top", first_target(PU, [[(15, 5)] * 5, [(15, 5)] * 5])),
 ("first: two misses -> decrease", first_target(P, [[(20, 7), (20, 6), (17.5, 8)], [(20, 8), (20, 7), (20, 7)]])),
 ("first: one miss -> repeat", first_target(P, [[(20, 7), (20, 6), (20, 6)], [(20, 10), (20, 9), (20, 8)]])),
 ("first: leg press two misses", first_target(LP, [[(100, 7)] * 4, [(100, 6)] * 4])),
 ("first: deload after repeat", first_target(P, [[(20, 10)] * 3], deload=True)),
 ("first: deload sets for 4-set lift", first_target(LP, [[(100, 10)] * 4], deload=True)),
 ("first: raised mid-session -> keeps the raise", first_target(P, [[(20, 15), (22.5, 12), (22.5, 11)]])),
 ("first: raised and at the top -> increase", first_target(P, [[(20, 15), (22.5, 12), (22.5, 12)]])),
 ("first: failed heavier attempt -> repeat", first_target(P, [[(20, 12), (20, 12), (22.5, 4)]])),
 ("first: dropped after the first set -> repeat", first_target(P, [[(20, 12), (17.5, 12), (17.5, 12)]])),
 ("first: raise fell short -> first weight", first_target(P, [[(20, 15), (22.5, 7), (22.5, 7)]])),
 ("next: 6 reps (min 8)", next_set(P, 20, 6, 1, 3)),
 ("next: 7 reps (min 8)", next_set(P, 20, 7, 1, 3)),
 ("next: 3 reps (min 8)", next_set(P, 20, 3, 1, 3)),
 ("next: 10 reps in range", next_set(P, 20, 10, 1, 3)),
 ("next: 13 reps (max+1) keeps", next_set(P, 20, 13, 1, 3)),
 ("next: 14 reps (max+2) raises", next_set(P, 20, 14, 1, 3)),
 ("next: 15 reps, not last set", next_set(P, 20, 15, 1, 3)),
 ("next: 15 reps, last set", next_set(P, 20, 15, 3, 3)),
 ("next: 25 reps -> two increments", next_set(P, 20, 25, 1, 3)),
 ("next: 40 reps -> capped at two", next_set(P, 20, 40, 1, 3)),
 ("next: leg press 16 reps", next_set(LP, 100, 16, 1, 4)),
 ("next: leg press 5 reps (min 8)", next_set(LP, 100, 5, 2, 4)),
 ("next: DB lateral 12 reps (min 15)", next_set(LAT, 8, 12, 1, 3)),
 ("next: DB lateral 22 reps", next_set(LAT, 8, 22, 1, 3)),
 ("next: pull-up 7 reps", next_set(PU, 15, 7, 1, 5)),
 ("next: bodyweight pull-up 8 reps", next_set(PU, 0, 8, 1, 5)),
 ("volume: amrap 12", volume_reps(12)),
 ("volume: amrap 9", volume_reps(9)),
 ("volume: amrap 13", volume_reps(13)),
 ("volume: amrap 1", volume_reps(1)),
 ("e1rm: 20kg x 10", e1rm(20, 10)),
 ("top: every set at the top", reached_top([12, 12, 12], 12, 3)),
 ("top: one set short", reached_top([12, 11, 12], 12, 3)),
 ("top: too few sets", reached_top([12, 12], 12, 3)),
 ("top: timed, past the max", reached_top([46, 45, 50], 45, 3)),
 ("top: extra sets ignored", reached_top([15, 15, 15, 9], 15, 3)),
]
for name, res in cases:
    print(f"{name:45s} -> {res}")

# name, working, inc, rep_max, role, setting, bodyweight_base
ramp_up_cases = [
    ("Incline DB Press 22.5, first", 22.5, 2.5, 10, "first", "main", False),
    ("20 kg x 12 case, first", 20.0, 2.5, 12, "first", "main", False),
    ("Machine Chest Press 45, main", 45.0, 5.0, 10, "main", "main", False),
    ("Seated DB Shoulder Press 17.5, main", 17.5, 2.5, 10, "main", "main", False),
    ("Leg Press 120, first", 120.0, 10.0, 12, "first", "main", False),
    ("Leg Press 40, first", 40.0, 10.0, 12, "first", "main", False),
    ("Leg Press 20, first (second equals first: left out)", 20.0, 10.0, 12, "first", "main", False),
    ("Leg Press 10, first (rounds to zero: none)", 10.0, 10.0, 12, "first", "main", False),
    ("Hip Thrust 60 inc 5, main", 60.0, 5.0, 12, "main", "main", False),
    ("DB 5 kg, first", 5.0, 2.5, 10, "first", "main", False),
    ("DB 2.5 kg, main (rounds to zero)", 2.5, 2.5, 10, "main", "main", False),
    ("Cable Lateral Raise 7.5, small, setting main", 7.5, 2.5, 15, "small", "main", False),
    ("Cable Lateral Raise 7.5, small, setting all", 7.5, 2.5, 15, "small", "all", False),
    ("DB Lateral Raise 6 inc 1, small, setting all", 6.0, 1.0, 20, "small", "all", False),
    ("Incline DB Press 22.5, first, setting off", 22.5, 2.5, 10, "first", "off", False),
    ("First time (no working weight)", None, 2.5, 10, "first", "main", False),
    ("Deload week: Incline DB Press at 20 (0.85 x 22.5 rounded), first", 20.0, 2.5, 10, "first", "main", False),
    ("Weighted Pull-ups +15, first", 15.0, 2.5, 5, "first", "main", True),
    ("Weighted Pull-ups +2.5, first (half rounds to zero)", 2.5, 2.5, 5, "first", "main", True),
    ("Weighted Pull-ups +15, main", 15.0, 2.5, 5, "main", "main", True),
    ("Weighted Pull-ups bodyweight only, first", 0.0, 2.5, 5, "first", "main", True),
    ("Heavy low-rep lift 100 inc 2.5 range 3-5, first (reps capped at the top of the range)",
     100.0, 2.5, 5, "first", "main", False),
]
print()
for name, working, inc, rep_max, r, setting, bw in ramp_up_cases:
    print(f"ramp-up: {name} -> {ramp_ups(working, inc, rep_max, r, setting, bw)}")
wed = [dict(kind="checklist"), dict(kind="weighted", restSec=150), dict(kind="weighted", restSec=150),
       dict(kind="weighted", restSec=150), dict(kind="weighted", restSec=75), dict(kind="reps", restSec=45)]
print("ramp-up: Wednesday roles ->", [role(wed, i) for i in range(len(wed))])
