"""Seated dip machine: sitting tall with the back on the pad, a handle at each side; press the handles down from
lower-chest height (elbows bent, pointing back) to arms straight beside the hips. Each handle rides on a lever
from a pivot in front, beside the knees."""
import os, sys, math
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rig import L, P, along, joint, trunk, mirror, slab, line, write

PELVIS = [78, 138, 0]
TORSO = -93
GRIP_Z = 23                              # handles just outside the body
GRIP_START = [79, 99, GRIP_Z]
PX, PY = 150, 116                        # lever pivot (both sides at z = +-(GRIP_Z + 4))
END_X = 80                               # the grip arcs down about the pivot to beside the hips


def arc_end():
    r2 = (GRIP_START[0] - PX) ** 2 + (GRIP_START[1] - PY) ** 2
    return [END_X, PY + math.sqrt(r2 - (END_X - PX) ** 2), GRIP_Z]


def pose(hand, bend):
    p = trunk(PELVIS, TORSO)
    p["ankleL"] = [112, 175, 11]
    p["toeL"] = [125, 175, 11]
    p["kneeL"] = joint(p["hipL"], p["ankleL"], L["thigh"], L["shin"], [1, -1, 0])
    p["handL"] = list(hand)
    p["elbowL"] = joint(p["shoulderL"], p["handL"], L["upper"], L["fore"], bend)
    return mirror(p)


start, end = pose(GRIP_START, [-1, 0.2, 0.3]), pose(arc_end(), [-1, 0, 0.2])
t, n = P([0, 0, 0], TORSO, 1), P([0, 0, 0], TORSO - 90, 1)
PAD0 = [PELVIS[0] + n[0] * 9, PELVIS[1] + n[1] * 9]
PAD1 = [PAD0[0] + t[0] * 62, PAD0[1] + t[1] * 62]
PZ = GRIP_Z + 4
props = [slab([[58, 147], [104, 147]], -16, 16, 7),            # seat
         slab([PAD0, PAD1], -13, 13, 7),                       # back pad
         line([[82, 150, 0], [82, 181, 0]], 5),                # seat post
         line([[69, 132, 0], [62, 132, 0], [62, 181, 0]], 5),  # back pad post
         slab([[50, 181], [160, 181]], -32, 32, 4)]            # base
for z in (-PZ, PZ):                                            # an upright each side in front, pivot on top
    props.append(line([[PX, 181, z], [PX, PY, z]], 5))
load = {"type": "machine", "grips": ["handL", "handR"], "pivots": [[PX, PY, PZ], [PX, PY, -PZ]],
        "axis": [1, 0, 0], "length": 14}
write("seated-dip-machine", start, end, props, load, tempo=2.6)
