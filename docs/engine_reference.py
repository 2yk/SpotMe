"""Reference implementation of the RepCoach progression engine.

The Swift ProgressionEngine must produce exactly these results; the vectors printed
at the bottom are copied into ProgressionEngineTests.swift.
"""
import math

def round_near(x, inc):  # matches Swift (x / inc).rounded() * inc  (half away from zero)
    return round(math.floor(x / inc + 0.5) * inc, 2)

def round_down(x, inc):
    return round(math.floor(x / inc + 1e-9) * inc, 2)

def at_top(p, sess, w):
    sets = sess[: p["sets"]]
    return len(sets) >= p["sets"] and all(s[0] >= w and s[1] >= p["repMax"] for s in sets)

def missed(p, sess):
    sets = sess[: p["sets"]]
    first = sets[0][0]
    return len(sets) < p["sets"] or any(s[1] < p["repMin"] for s in sets) or any(s[0] < first for s in sets)

def first_target(p, history, deload=False):
    """history: list of sessions newest first; each session = list of (weight, reps). Deload sessions excluded by caller."""
    if not history:
        return (None, "firstTime", sets_for(p, deload))
    work = history[0][0][0]
    top = 0
    for sess in history:
        if sess[0][0] == work and at_top(p, sess, work):
            top += 1
        else:
            break
    if top >= p.get("need", 1):
        w, why = work + p["inc"], "increase"
    elif len(history) >= 2 and history[1][0][0] == work and missed(p, history[0]) and missed(p, history[1]):
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
    if r >= p["repMax"] + 3 and set_index < total:
        return (round(w + p["inc"], 2), "raiseWeight")
    return (w, "keep")

def volume_reps(amrap, pct=0.6):
    return max(1, math.floor(amrap * pct + 0.5))

def e1rm(w, r):
    return round(w * (1 + r / 30), 2)

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
 ("next: 6 reps (min 8)", next_set(P, 20, 6, 1, 3)),
 ("next: 7 reps (min 8)", next_set(P, 20, 7, 1, 3)),
 ("next: 3 reps (min 8)", next_set(P, 20, 3, 1, 3)),
 ("next: 10 reps in range", next_set(P, 20, 10, 1, 3)),
 ("next: 15 reps, not last set", next_set(P, 20, 15, 1, 3)),
 ("next: 15 reps, last set", next_set(P, 20, 15, 3, 3)),
 ("next: 14 reps (max+2) keeps", next_set(P, 20, 14, 1, 3)),
 ("next: DB lateral 12 reps (min 15)", next_set(LAT, 8, 12, 1, 3)),
 ("next: leg press 5 reps (min 8)", next_set(LP, 100, 5, 2, 4)),
 ("volume: amrap 12", volume_reps(12)),
 ("volume: amrap 9", volume_reps(9)),
 ("volume: amrap 13", volume_reps(13)),
 ("volume: amrap 1", volume_reps(1)),
 ("e1rm: 20kg x 10", e1rm(20, 10)),
]
for name, res in cases:
    print(f"{name:45s} -> {res}")
