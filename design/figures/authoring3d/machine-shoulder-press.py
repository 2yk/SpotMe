"""Machine shoulder press: seated with the back on a tall pad, machine handles from shoulder height to overhead."""
import os, sys, math
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rig import L, P, along, joint, trunk, mirror, slab, line, write

PELVIS = [78, 138, 0]
TORSO = -96                             # back pad reclined a little, head clear of the arms
GRIP_START = [100, 68, 31]
PX, PY, PZ = 55, 88, 34                 # lever pivot on the uprights behind the pad, a little above the shoulders
END_X, END_Z = 78, 22                   # the grip arcs up about the pivot to overhead, a little in front of the head


def arc_end():
    """End grip on the lever's circle: same distance from the pivot as the start grip."""
    r2 = sum((a - b) ** 2 for a, b in zip(GRIP_START, (PX, PY, PZ)))
    return [END_X, PY - math.sqrt(r2 - (END_X - PX) ** 2 - (END_Z - PZ) ** 2), END_Z]


GRIP_END = arc_end()


def pose(hand):
    p = trunk(PELVIS, TORSO)
    p["ankleL"] = [112, 175, 11]
    p["toeL"] = [125, 175, 11]
    p["kneeL"] = joint(p["hipL"], p["ankleL"], L["thigh"], L["shin"], [1, -1, 0])
    p["handL"] = list(hand)
    p["elbowL"] = joint(p["shoulderL"], p["handL"], L["upper"], L["fore"], [0.2, 1, 1])
    return mirror(p)


start, end = pose(GRIP_START), pose(GRIP_END)
PIVOT = [PX, PY, PZ]
t, n = P([0, 0, 0], TORSO, 1), P([0, 0, 0], TORSO - 90, 1)
PAD0 = [PELVIS[0] + n[0] * 9, PELVIS[1] + n[1] * 9]
PAD1 = [PAD0[0] + t[0] * 72, PAD0[1] + t[1] * 72]
props = [slab([[58, 147], [104, 147]], -16, 16, 7),          # seat
         slab([PAD0, PAD1], -14, 14, 7),                     # tall back pad, parallel to the torso
         line([[82, 150, 0], [82, 181, 0]], 5),              # seat post
         line([[69, 132, 0], [62, 132, 0], [62, 181, 0]], 5),  # back pad post
         slab([[48, 181], [112, 181]], -30, 30, 4)]          # base
for z in (-PZ, PZ):                                          # frame: an upright each side behind the pad, pivot on top
    props.append(line([[PX, 181, z], [PX, PY, z]], 5))
load = {"type": "machine", "grips": ["handL", "handR"],
        "pivots": [PIVOT, [PIVOT[0], PY, -PZ]], "axis": [1, 0, 0], "length": 14}
write("machine-shoulder-press", start, end, props, load, tempo=2.4)
