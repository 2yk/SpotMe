#!/usr/bin/env python3
"""SpotMe plan builder, reference implementation of RULES.md.

python3 build_plan.py personas/yeshu.json   prints the plan JSON
python3 build_plan.py --all                 builds personas/*.json into plans/ and prints outlines
import: build(answers, exercises) -> plan

Deterministic: no randomness, no hidden state. Spots where RULES.md is unclear are marked "# RULES?".
"""
import json
import os
import sys
from itertools import combinations

HERE = os.path.dirname(os.path.abspath(__file__))
DB_PATH = os.path.join(HERE, "..", "exercise-db", "exercises.json")

WEEK = ["monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday"]
WEEKDAY_NUMBER = {"sunday": 1, "monday": 2, "tuesday": 3, "wednesday": 4, "thursday": 5, "friday": 6, "saturday": 7}
LEVELS = ["beginner", "intermediate", "advanced"]
INJURY_AREAS = ["neck", "shoulder", "elbow", "wrist", "lowerBack", "hip", "knee", "ankle"]
INJURY_NAMES = {"neck": "Neck", "shoulder": "Shoulder", "elbow": "Elbow", "wrist": "Wrist",
                "lowerBack": "Lower back", "hip": "Hip", "knee": "Knee", "ankle": "Ankle"}
NUMBER_WORDS = {2: "two", 3: "three", 4: "four", 5: "five", 6: "six"}

# ---------------------------------------------------------------- Step 1 · days and split

MAX_DAYS = {"new": 4, "some": 5, "experienced": 6}

SPLITS = {
    2: ("Full body", ["Full A", "Full B"]),
    3: ("Full body", ["Full A", "Full B", "Full C"]),
    4: ("Upper / Lower", ["Upper A", "Lower A", "Upper B", "Lower B"]),
    5: ("Push / Pull / Legs + Upper / Lower", ["Push", "Pull", "Legs", "Upper B", "Lower B"]),
    6: ("Push / Pull / Legs, twice", ["Push", "Pull", "Legs", "Push B", "Pull B", "Legs B"]),
}

# ---------------------------------------------------------------- Step 2 · slots

# slot kind: (patterns, bodyParts, class, counts toward)
SLOTS = {
    "squat":      (["squat"], ["quads"], "big", "legs"),
    "single-leg": (["single-leg"], ["quads"], "big", "legs"),
    "hinge":      (["hinge", "hip-extension"], ["hamstrings", "glutes"], "big", "legs"),
    "glute":      (["hip-extension"], ["glutes"], "small", "glutes"),
    "leg-curl":   (["knee-flexion"], ["hamstrings"], "small", "legs"),
    "leg-ext":    (["knee-extension"], ["quads"], "small", "legs"),
    "calves":     (["calf-raise"], ["calves"], "small", "legs"),
    "adductor":   (["hip-adduction"], ["hips"], "small", "legs"),
    "press":      (["horizontal-push"], ["chest"], "big", "chest"),
    "incline":    (["incline-push"], ["chest"], "big", "chest"),
    "fly":        (["chest-fly"], ["chest"], "small", "chest"),
    "overhead":   (["vertical-push"], ["shoulders"], "big", "shoulders"),
    "lateral":    (["lateral-raise"], ["shoulders"], "small", "shoulders"),
    "rear":       (["rear-delt-pull"], ["shoulders"], "small", "shoulders"),
    "row":        (["horizontal-pull"], ["back"], "big", "back"),
    "pull":       (["vertical-pull"], ["back"], "big", "back"),
    "curl":       (["curl"], ["biceps"], "small", "arms"),
    "triceps":    (["triceps-extension"], ["triceps"], "small", "arms"),
    "core-brace": (["core-anti-extension"], ["core"], "core", "core"),
    "core-twist": (["core-anti-rotation", "core-lateral"], ["core"], "core", "core"),
    "core-flex":  (["core-flexion"], ["core"], "core", "core"),
}
LOWER_BIG = {"squat", "single-leg", "hinge"}

def focus_areas_of(kind):
    """Focus areas a slot counts toward: glute counts toward both glutes and legs."""
    if kind == "glute":
        return {"glutes", "legs"}
    return {SLOTS[kind][3]}

# weeklySets: counted by the picked exercise's bodyPart
WEEKLY_GROUP = {"chest": "chest", "back": "back", "shoulders": "shoulders", "biceps": "arms", "triceps": "arms",
                "forearms": "arms", "quads": "quads", "glutes": "glutesHamstrings", "hamstrings": "glutesHamstrings",
                "hips": "glutesHamstrings", "calves": "calves", "core": "core", "full-body": "core"}


def summary_group_of(kind):
    """Weekly summary group: glute slots count as legs."""
    return "legs" if kind == "glute" else SLOTS[kind][3]

TEMPLATES = {
    "Full A":  [("squat", 1), ("press", 1), ("row", 1), ("leg-curl", 2), ("lateral", 3), ("core-brace", 2)],
    "Full B":  [("hinge", 1), ("overhead", 1), ("pull", 1), ("single-leg", 2), ("curl", 3), ("triceps", 3), ("core-twist", 3)],
    "Full C":  [("squat", 1), ("incline", 1), ("row", 1), ("hinge", 2), ("rear", 3), ("core-flex", 2)],
    "Upper A": [("press", 1), ("row", 1), ("overhead", 1), ("pull", 1), ("lateral", 2), ("triceps", 3), ("curl", 3)],
    "Upper B": [("incline", 1), ("pull", 1), ("row", 1), ("fly", 2), ("rear", 2), ("curl", 3), ("triceps", 3)],
    "Lower A": [("squat", 1), ("hinge", 1), ("single-leg", 2), ("leg-curl", 2), ("calves", 3), ("core-brace", 2)],
    "Lower B": [("hinge", 1), ("squat", 1), ("leg-ext", 2), ("leg-curl", 2), ("calves", 3), ("core-twist", 2)],
    "Push":    [("press", 1), ("incline", 1), ("overhead", 1), ("lateral", 2), ("triceps", 2), ("triceps", 3), ("fly", 3)],
    "Pull":    [("pull", 1), ("row", 1), ("row", 2), ("rear", 2), ("curl", 2), ("curl", 3), ("core-flex", 3)],
    "Legs":    [("squat", 1), ("hinge", 1), ("single-leg", 2), ("leg-curl", 2), ("calves", 2), ("leg-ext", 3), ("core-brace", 3)],
    "Push B":  [("overhead", 1), ("incline", 1), ("press", 2), ("lateral", 2), ("triceps", 2), ("fly", 3)],
    "Pull B":  [("row", 1), ("pull", 1), ("pull", 2), ("rear", 2), ("curl", 2), ("curl", 3)],
    "Legs B":  [("hinge", 1), ("squat", 1), ("leg-ext", 2), ("leg-curl", 2), ("calves", 2), ("core-twist", 3)],
}

def region_of(day_type):
    """Full days are both; Upper, Push, Pull (and B days) are upper; Lower and Legs days are lower."""
    if day_type.startswith("Full"):
        return "both"
    if day_type.startswith(("Lower", "Legs")):
        return "lower"
    return "upper"

AREA_REGION = {"chest": "upper", "back": "upper", "shoulders": "upper", "arms": "upper",
               "glutes": "lower", "legs": "lower", "core": "any"}

FOCUS_TITLES = {
    "Full A": "Full Body A · Squat, Press & Row", "Full B": "Full Body B · Hinge, Overhead & Pull",
    "Full C": "Full Body C · Squat, Incline & Row", "Upper A": "Upper A · Press & Row",
    "Upper B": "Upper B · Incline & Pull", "Lower A": "Lower A · Squat Focus", "Lower B": "Lower B · Hinge Focus",
    "Push": "Push · Chest, Shoulders & Triceps", "Pull": "Pull · Back & Biceps",
    "Legs": "Legs · Quads, Hamstrings & Calves", "Push B": "Push B · Shoulders & Chest",
    "Pull B": "Pull B · Rows & Biceps", "Legs B": "Legs B · Hinge & Quads",
}

# plain names for missing-slot notes (Step 4)
SLOT_WORDS = {
    "squat": "squat", "single-leg": "single-leg", "hinge": "hip-hinge", "glute": "glute", "leg-curl": "hamstring curl",
    "leg-ext": "leg extension", "calves": "calf", "adductor": "inner-thigh", "press": "chest press",
    "incline": "incline press", "fly": "chest fly", "overhead": "overhead press", "lateral": "side raise",
    "rear": "rear-shoulder", "row": "row", "pull": "pull-down", "curl": "biceps", "triceps": "triceps",
    "core-brace": "core", "core-twist": "core", "core-flex": "core",
}


def new_slot(kind, priority):
    return {"kind": kind, "priority": priority, "focus": False, "exercise": None}


def insert_before_first_core(slots, slot):
    """Step 2: 'just before the first core slot (or at the end)'."""
    for i, s in enumerate(slots):
        if SLOTS[s["kind"]][2] == "core":
            slots.insert(i, slot)
            return
    slots.append(slot)


def day_slots(day_type, answers, first_lower_day_type):
    slots = [new_slot(k, p) for k, p in TEMPLATES[day_type]]
    region = region_of(day_type)
    kinds = lambda: {s["kind"] for s in slots}

    # Step 2.1 Focus, area by area in the order answered
    for area in answers.get("focus", []):
        # every slot that counts toward the area moves up one priority (3 -> 2, 2 -> 1) and is a focus slot
        for s in slots:
            if area in focus_areas_of(s["kind"]):
                s["priority"] = max(1, s["priority"] - 1)
                s["focus"] = True
        # add a missing slot only on days that already have a slot counting toward the area (core: every day)
        # glutes: on every day that has a slot counting toward legs
        need = "legs" if area == "glutes" else area
        trains = area == "core" or any(need in focus_areas_of(s["kind"]) for s in slots)
        if not trains:
            continue
        to_add = []
        if area == "arms":
            # curl on days with a pull or row, triceps on days with a press, incline or overhead
            if "curl" not in kinds() and kinds() & {"pull", "row"}:
                to_add.append("curl")
            if "triceps" not in kinds() and kinds() & {"press", "incline", "overhead"}:
                to_add.append("triceps")
        elif area == "core":
            if not any(SLOTS[k][2] == "core" for k in kinds()):
                to_add.append("core-flex")
        else:
            # the slot is added only if the day has no slot of this kind yet
            add = {"chest": "fly", "back": "row", "shoulders": "lateral", "glutes": "glute", "legs": "leg-ext"}[area]
            if add not in kinds():
                to_add.append(add)
        for kind in to_add:
            # added at priority 2, a focus slot
            slot = new_slot(kind, 2)
            slot["focus"] = True
            insert_before_first_core(slots, slot)

    # Step 2.2 Cardio 2: calves on Lower/Legs days without one, adductor on the first Lower/Legs day
    # lower days: Lower A, Lower B, Legs, Legs B
    if answers.get("cardio", 0) == 2 and region == "lower":
        # both go just before the first core slot, or at the end
        if "calves" not in kinds():
            insert_before_first_core(slots, new_slot("calves", 2))
        if day_type == first_lower_day_type:
            insert_before_first_core(slots, new_slot("adductor", 3))
    return slots

# ---------------------------------------------------------------- Step 3 · sets, reps, rest

REPS_REST = {  # goal -> slot row -> (repMin, repMax, rest)
    "muscle":   {"first": (6, 10, 150), "big": (8, 12, 120), "small": (10, 15, 75), "core": (8, 12, 45)},
    "strength": {"first": (4, 6, 180),  "big": (6, 8, 150),  "small": (8, 12, 75),  "core": (8, 12, 45)},
    "lean":     {"first": (6, 10, 120), "big": (8, 12, 90),  "small": (12, 15, 60), "core": (10, 15, 45)},
    "fit":      {"first": (8, 12, 90),  "big": (8, 12, 90),  "small": (12, 15, 60), "core": (10, 15, 45)},
}

BASE_SETS = {  # experience -> (first big of the day, other big, small, core)
    "new": (3, 2, 2, 2), "some": (3, 3, 3, 3), "experienced": (4, 3, 3, 3),
}


def no_heavy(answers):
    """New lifters and anyone aged 50 or more never get 4-6."""
    age = answers.get("age")
    return answers["experience"] == "new" or (age is not None and age >= 50)


def slot_sets(slot, is_first_big, answers):
    cls = SLOTS[slot["kind"]][2]
    first, other_big, small, core = BASE_SETS[answers["experience"]]
    if cls == "big":
        sets = first if is_first_big else other_big
    elif cls == "small":
        sets = small
    else:
        sets = core
    goal = answers["goal"]
    if goal == "strength":
        if is_first_big:
            sets += 1
        if cls == "small":
            sets -= 1
    if goal == "fit":
        sets = min(sets, 3)
    # Focus: +1 on the area's small slots, and on the first big slot when it is a focus slot.
    # for a core focus the +1 goes to its core slots
    if slot["focus"] and (cls in ("small", "core") or is_first_big):
        sets += 1
    if answers.get("cardio", 0) == 2 and slot["kind"] in LOWER_BIG:
        sets -= 1
    top = 5 if (answers["goal"] == "strength" and is_first_big) else 4
    return max(2, min(top, sets))


def slot_dose(slot, is_first_big, ex, answers):
    """Reps or seconds, and rest, for a slot filled by exercise ex."""
    cls = SLOTS[slot["kind"]][2]
    if ex["logAs"] == "timed":
        if answers["experience"] == "new":
            lo, hi = (15, 20) if ex["perSide"] else (20, 30)
        else:
            lo, hi = (20, 30) if ex["perSide"] else (30, 45)
        return {"secMin": lo, "secMax": hi, "restSec": short_rest(45, answers)}
    row = "first" if is_first_big else cls
    lo, hi, rest = REPS_REST[answers["goal"]][row]
    if is_first_big and answers["goal"] == "strength" and no_heavy(answers):
        lo, hi, rest = 6, 8, 150
    return {"repMin": lo, "repMax": hi, "restSec": short_rest(rest, answers)}


def short_rest(rest, answers):
    """Sessions of 30 minutes: every rest is 30 seconds shorter, never under 45."""
    return max(45, rest - 30) if answers["minutes"] == 30 else rest

# ---------------------------------------------------------------- Step 4 · picking

def level_allowed(experience, harder):
    top = {"new": 0, "some": 1, "experienced": 2}[experience] + (1 if harder else 0)
    return LEVELS[:min(top, 2) + 1]


def candidates(kind, answers, equipment, day_ids, harder, injuries=True):
    patterns, parts, _, _ = SLOTS[kind]
    out = []
    for ex in answers["_exercises"]:
        if ex["pattern"] not in patterns or ex["bodyPart"] not in parts:       # 4.1
            continue
        if not set(ex["equipment"]) <= equipment:                               # 4.2
            continue
        if ex["level"] not in level_allowed(answers["experience"], harder):     # 4.3
            continue
        ok = True
        for area, mark in (answers.get("injuries", {}).items() if injuries else []):   # 4.4
            limit = 1 if mark == "avoid" else 2
            if ex["injury"][area] > limit:
                ok = False
        if not ok or ex["id"] in day_ids:                                       # 4.5
            continue
        out.append(ex)
    return out


def score(ex, slot, is_first_big, answers, used_earlier, today, harder):
    cls = SLOTS[slot["kind"]][2]
    s = (15 if is_first_big else 10) * ex["tier"]
    for area, mark in answers.get("injuries", {}).items():
        if mark == "care" and ex["injury"][area] == 2:
            s += 6
    if ex["id"] in used_earlier:
        s += 15
    if ex["logAs"] != "weighted":
        s += {"big": 10, "small": 5}.get(cls, 0)
    if slot["kind"] == "hinge" and ex["pattern"] == "hip-extension":
        s += 4
    for other in today:
        o = other["exercise"]
        if o["bodyPart"] == ex["bodyPart"] and o["equipment"][0] == ex["equipment"][0]:
            s += 5
            break
    if harder and ex["level"] not in level_allowed(answers["experience"], False):
        s += 4
    if answers["experience"] == "new" and "barbell" in ex["equipment"]:
        s += 3
    age = answers.get("age")
    if age is not None and age >= 50 and ex["injury"]["lowerBack"] + ex["injury"]["knee"] + ex["injury"]["shoulder"] >= 5:
        s += 3
    if answers["goal"] == "strength" and cls == "big" and ex.get("loadType") == "barbell-total":
        s -= 3
    return s


def pick(slot, is_first_big, second_of_kind, answers, equipment, used_earlier, today):
    """Returns (exercise, None) or (None, missing-note or "" for a silent leave-out)."""
    day_ids = {s["exercise"]["id"] for s in today}
    harder = False
    cands = candidates(slot["kind"], answers, equipment, day_ids, False)
    if not cands and answers["experience"] != "experienced":
        harder = True   # 4.3: if no candidate, allow one level harder
        cands = candidates(slot["kind"], answers, equipment, day_ids, True)
    if not cands:
        return None, missing_note(slot["kind"], answers, equipment, day_ids)
    # 4.6: a priority-3 slot, or the second slot of a kind in a day, never takes a tier-3 exercise
    if slot["priority"] == 3 or second_of_kind:
        cands = [ex for ex in cands if ex["tier"] < 3]
        if not cands:
            return None, ""
    injury_sum = lambda ex: sum(ex["injury"][a] for a in INJURY_AREAS)
    best = min(cands, key=lambda ex: (score(ex, slot, is_first_big, answers, used_earlier, today, harder),
                                      injury_sum(ex), ex["id"]))
    return best, None


def missing_note(kind, answers, equipment, day_ids):
    """Step 4: name the real cause. Injuries when candidates exist with injuries ignored, else equipment."""
    free = candidates(kind, answers, equipment, day_ids, False, injuries=False)
    if not free and answers["experience"] != "experienced":
        free = candidates(kind, answers, equipment, day_ids, True, injuries=False)
    if not free:
        return f"No {SLOT_WORDS[kind]} exercise fits your equipment."
    areas = []
    for area in INJURY_AREAS:   # the injured areas that ruled candidates out
        mark = answers.get("injuries", {}).get(area)
        if mark and any(ex["injury"][area] > (1 if mark == "avoid" else 2) for ex in free):
            areas.append(INJURY_NAMES[area].lower())
    return f"Nothing for {SLOT_WORDS[kind]} suits your {join_words(areas)}, so it is left out."


# ---------------------------------------------------------------- Step 5 · session length

def exercise_minutes(slot):
    ex, d = slot["exercise"], slot["dose"]
    rest = d["restSec"] / 60
    if ex["logAs"] == "timed":
        sec = d["secMax"] * (2 if ex["perSide"] else 1)
        return slot["sets"] * (sec / 60 + rest)
    if ex["perSide"]:
        return slot["sets"] * (1.2 + rest)
    return slot["sets"] * (0.7 + rest)


def day_minutes(slots):
    return 6 + sum(exercise_minutes(s) for s in slots) + 4


def fit_day(slots, answers):
    """Returns (trimmed?, runs long?). Changes slots in place."""
    limit = answers["minutes"] + 5
    trimmed = False
    while day_minutes(slots) > limit:
        p3 = [i for i, s in enumerate(slots) if s["priority"] == 3]
        reducible = [i for i, s in enumerate(slots) if s["sets"] > 2 and s["priority"] != 1]
        p2 = [i for i, s in enumerate(slots) if s["priority"] == 2]
        p1 = [i for i, s in enumerate(slots) if s["priority"] == 1 and s["sets"] > 2 and not s["focus"]]
        fs = [i for i, s in enumerate(slots) if s["focus"] and s["sets"] > 2]
        if p3:
            del slots[p3[-1]]                 # 5.1 remove the last priority-3 slot
        elif reducible:
            slots[reducible[-1]]["sets"] -= 1  # 5.2 one set off the last non-priority-1 slot with > 2 sets
        elif p2:
            del slots[p2[-1]]                 # 5.3 remove the last priority-2 slot
        elif p1:
            slots[p1[-1]]["sets"] -= 1        # 5.4 one set off the last non-focus priority-1 slot with > 2 sets
        elif fs:
            slots[fs[-1]]["sets"] -= 1        # 5.5 one set off the last focus slot with > 2 sets
        else:
            return trimmed, True               # nothing possible: the day runs long
        trimmed = True
    # Top up: more than 12 minutes short -> one set at a time to big slots only, priority 1 first to last,
    # then 2, then 3, in rounds, while it fits; no slot above 4 (3 for new lifters and for fit); skip what won't fit
    if day_minutes(slots) < answers["minutes"] - 5:
        cap = 3 if (answers["goal"] == "fit" or answers["experience"] == "new") else 4
        order = sorted((s for s in slots if SLOTS[s["kind"]][2] == "big"
                        and not (answers.get("cardio", 0) == 2 and s["kind"] in LOWER_BIG)), key=lambda s: s["priority"])
        added = True
        while added:
            added = False
            for s in order:
                if s["sets"] >= cap:
                    continue
                s["sets"] += 1
                if day_minutes(slots) > limit:
                    s["sets"] -= 1
                else:
                    added = True
    return trimmed, False

# ---------------------------------------------------------------- Step 6 · warmup and cooldown

def warmup_steps(region, equipment):
    if region == "upper":
        band = "Band pull-aparts · 1 × 15" if "resistance-band" in equipment else "Wall slides · 1 × 10"
        return ["Light cardio 2–3 min", "Arm circles · 10 each way", band, "Scapular push-ups · 1 × 10",
                "Light set of your first lift · 1 × 10 at ~50%"]
    if region == "lower":
        return ["Light cardio 3 min", "Bodyweight squats · 1 × 10", "Hip hinges · 1 × 10", "Glute bridges · 1 × 10",
                "Light set of your first lift · 1 × 10 at ~50%"]
    return ["Light cardio 3 min", "Bodyweight squats · 1 × 10", "Scapular push-ups · 1 × 10", "Glute bridges · 1 × 10",
            "Light set of your first lift · 1 × 10 at ~50%"]

COOLDOWN = {
    "upper": "Doorway pec stretch · overhead triceps stretch · lat stretch, 30s each.",
    "lower": "Couch stretch · hamstring stretch · calf stretch, 30s each side.",
    "both": "Doorway pec stretch · couch stretch · hamstring stretch, 30s each.",
}

# ---------------------------------------------------------------- Step 7 · output

def exercise_item(slot):
    ex, d, sets = slot["exercise"], slot["dose"], slot["sets"]
    side = "/side" if ex["perSide"] else ""
    group = "Core" if SLOTS[slot["kind"]][2] == "core" else ex["bodyPart"][:1].upper() + ex["bodyPart"][1:]
    item = {"name": ex["name"], "exerciseId": ex["id"], "group": group, "note": ex["cue"]}
    if ex["logAs"] == "timed":
        item["display"] = f"{sets} × {d['secMin']}–{d['secMax']}s{side}"
    else:
        item["display"] = f"{sets} × {d['repMin']}–{d['repMax']}{side}"
    item["sets"] = sets
    item["kind"] = ex["logAs"]
    if ex["logAs"] == "timed":
        item["secMin"], item["secMax"] = d["secMin"], d["secMax"]
    else:
        item["repMin"], item["repMax"] = d["repMin"], d["repMax"]
    item["perSide"] = ex["perSide"]
    if ex["logAs"] in ("reps", "timed"):
        item["loadable"] = bool(ex.get("loadable", False))
    if "incrementKg" in ex:
        item["increment"] = ex["incrementKg"]
    item["restSec"] = d["restSec"]
    if ex["logAs"] == "weighted":
        item["sessionsAtTopToProgress"] = 1
    return item


def round5(minutes):
    # rounded to the nearest 5; halves (x2.5, x7.5) round up
    return int(minutes / 5 + 0.5) * 5


def choose_days(days, keep):
    """Step 1: keep `keep` days so the smallest gap (round the week) is largest; tie -> earliest start."""
    # "starts earliest in the week": compare the kept weekdays Monday-first, first
    # difference decides (Mon-Fri beats Tue-Sat). The week starts on Monday, as the plan's days do.
    idx = sorted(WEEK.index(d) for d in days)
    if len(idx) <= keep:
        return [WEEK[i] for i in idx]
    best = None
    for combo in combinations(idx, keep):   # combinations come out in lexicographic order
        gaps = [(combo[(i + 1) % keep] - combo[i]) % 7 or 7 for i in range(keep)]
        if best is None or min(gaps) > best[0]:
            best = (min(gaps), combo)
    return [WEEK[i] for i in best[1]]


def join_words(words):
    return words[0] if len(words) == 1 else ", ".join(words[:-1]) + " and " + words[-1]


def build(answers, exercises):
    answers = dict(answers)
    answers["_exercises"] = sorted(exercises, key=lambda e: e["id"])
    equipment = set(answers.get("equipment", [])) | {"bodyweight", "wall"}
    notes, missing_notes, long_days = [], [], []
    trimmed_any = False

    # Step 1
    keep = min(len(answers["days"]), MAX_DAYS[answers["experience"]])
    kept = choose_days(answers["days"], keep)
    dropped = [d for d in WEEK if d in answers["days"] and d not in kept]
    split, types = SPLITS[len(kept)]
    day_type_of = dict(zip(kept, types))
    first_lower = next((t for t in types if region_of(t) == "lower"), None)

    used_earlier = set()
    out_days = {}
    weekly = {k: 0 for k in ["chest", "back", "shoulders", "arms", "quads", "glutesHamstrings", "calves", "core"]}
    for key in kept:
        day_type = day_type_of[key]
        slots = day_slots(day_type, answers, first_lower)                       # Step 2
        # First big = the first big slot of the day that gets an exercise.
        first_big = None
        today = []
        seen_kinds = set()
        for slot in slots:                                                     # Step 4 (with Step 3)
            is_first_big = first_big is None and SLOTS[slot["kind"]][2] == "big"
            second_of_kind = slot["kind"] in seen_kinds
            seen_kinds.add(slot["kind"])
            ex, note = pick(slot, is_first_big, second_of_kind, answers, equipment, used_earlier, today)
            if ex is None:
                if note and note not in missing_notes:
                    missing_notes.append(note)
                continue
            slot["exercise"] = ex
            if is_first_big:
                first_big = slot
            slot["sets"] = slot_sets(slot, is_first_big, answers)
            slot["dose"] = slot_dose(slot, is_first_big, ex, answers)
            today.append(slot)
        trimmed, runs_long = fit_day(today, answers)                           # Step 5
        trimmed_any |= trimmed
        if runs_long:
            long_days.append(key)
        used_earlier |= {s["exercise"]["id"] for s in today}
        for s in today:
            weekly[WEEKLY_GROUP[s["exercise"]["bodyPart"]]] += s["sets"]
        region = region_of(day_type)
        items = [{"name": "Warmup · 6 min", "exerciseId": f"{key}-warmup", "group": "Warmup", "kind": "checklist",
                  "steps": warmup_steps(region, equipment), "display": "6 min"}]   # Step 6
        items += [exercise_item(s) for s in today]
        items.append({"name": "Cooldown stretches", "exerciseId": f"{key}-cooldown", "group": "Cooldown",
                      "kind": "checklist", "note": COOLDOWN[region], "display": "4 min"})
        out_days[key] = {"key": key, "weekday": WEEKDAY_NUMBER[key], "title": key.capitalize(),
                         "focus": FOCUS_TITLES[day_type], "time": f"~{round5(day_minutes(today))} min", "items": items}

    days = []
    for key in WEEK:
        if key in out_days:
            days.append(out_days[key])
        else:
            days.append({"key": key, "weekday": WEEKDAY_NUMBER[key], "title": key.capitalize(), "focus": "Rest",
                         "time": "Nothing planned", "items": [{
                             "name": "Rest day", "exerciseId": f"rest-{key}", "group": "Recovery", "kind": "checklist",
                             "display": "—", "note": "No lifting today. Walk, sleep and eat well."}]})

    # Step 7 notes, in order
    n = len(kept)
    per_week = {2: "twice", 3: "three times", 4: "twice", 5: "about twice", 6: "twice"}[n]
    notes.append(f"{split}, {NUMBER_WORDS[n]} days: every muscle is trained {per_week} a week.")
    if dropped:
        names = [d.capitalize() for d in dropped]
        free = f"{join_words(names)} {'is' if len(names) == 1 else 'are'} left free."
        if answers["experience"] == "new":
            notes.append(f"Four days to start with. More would not build faster yet, and you recover better. {free}")
        else:
            notes.append(f"{NUMBER_WORDS[n].capitalize()} days is the most this plan uses; {free}")
    goal = answers["goal"]
    if goal == "muscle":
        notes.append("Most sets are 6 to 15 reps, close to failure: the range that builds muscle.")
    elif goal == "strength":
        reps = "6 to 8" if no_heavy(answers) else "4 to 6"
        notes.append(f"The first lift of each day is heavy, {reps} reps with long rests.")
    elif goal == "lean":
        notes.append("Same lifting as for muscle, with shorter rests. The fat loss comes from eating, "
                     "the lifting keeps your muscle.")
    else:
        notes.append("Moderate reps and short rests: a little of everything, nothing extreme.")
    focus = answers.get("focus", [])
    if focus:
        verb = "it is" if len(focus) == 1 else "they are"
        notes.append(f"Extra sets for {join_words(focus)}, and {verb} the last thing to be cut when time is short.")
    for area in INJURY_AREAS:
        mark = answers.get("injuries", {}).get(area)
        if mark == "care":
            notes.append(f"{INJURY_NAMES[area]}: nothing risky for it is in the plan, and gentler options were picked first.")
        elif mark == "avoid":
            notes.append(f"{INJURY_NAMES[area]}: nothing that loads it is in the plan.")
    if answers.get("cardio", 0) == 2:
        notes.append("Lighter leg work, with extra calf and inner-thigh work, to leave room for your running.")
    age = answers.get("age")
    if age is not None and age >= 50:
        notes.append("No very heavy low-rep sets, and joint-friendly exercises first.")
    if trimmed_any:
        notes.append(f"Trimmed to fit {answers['minutes']} minutes: the most important lifts stayed.")
    for key in long_days:
        notes.append(f"{key.capitalize()} runs a little over {answers['minutes']} minutes.")
    notes.extend(missing_notes)   # one sentence per slot kind left out, worded as in Step 4
    notes.append("Weights go up by themselves: reach the top of the rep range on every set and next time adds "
                 "one step. Every 6th week is a lighter deload week.")

    return {"planVersion": 1, "deloadEveryNthWeek": 6, "days": days,
            "summary": {"split": split, "daysPerWeek": n, "minutes": answers["minutes"],
                        "weeklySets": weekly, "notes": notes}}

# ---------------------------------------------------------------- command line

def load_exercises():
    with open(DB_PATH) as f:
        return json.load(f)["exercises"]


def outline(name, plan):
    lines = [f"=== {name}: {plan['summary']['split']}, {plan['summary']['daysPerWeek']} days, {plan['summary']['minutes']} min"]
    for d in plan["days"]:
        if d["focus"] == "Rest":
            continue
        lines.append(f"{d['title']} · {d['focus']} · {d['time']}")
        for it in d["items"]:
            if it["kind"] == "checklist":
                lines.append(f"    [{it['name']}]")
            else:
                lines.append(f"    {it['name']:<34} {it['display']:<16} rest {it['restSec']}s")
    lines.append("weeklySets: " + ", ".join(f"{k} {v}" for k, v in plan["summary"]["weeklySets"].items()))
    for note in plan["summary"]["notes"]:
        lines.append("  - " + note)
    return "\n".join(lines)


def main(argv):
    exercises = load_exercises()
    if argv and argv[0] == "--all":
        pdir, odir = os.path.join(HERE, "personas"), os.path.join(HERE, "plans")
        os.makedirs(odir, exist_ok=True)
        for fn in sorted(os.listdir(pdir)):
            if not fn.endswith(".json"):
                continue
            with open(os.path.join(pdir, fn)) as f:
                plan = build(json.load(f), exercises)
            with open(os.path.join(odir, fn), "w") as f:
                json.dump(plan, f, indent=2, ensure_ascii=False)
                f.write("\n")
            print(outline(fn[:-5], plan) + "\n")
        return 0
    if len(argv) != 1:
        print(__doc__)
        return 2
    with open(argv[0]) as f:
        print(json.dumps(build(json.load(f), exercises), indent=2, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
