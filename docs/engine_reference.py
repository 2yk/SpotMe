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
