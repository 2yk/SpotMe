"""Machine chest press: seated upright, back on the pad, hands press forward from beside the chest to nearly straight."""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rig import L, P, joint, trunk, mirror, slab, line, write

PELVIS = [78, 138, 0]
GRIP_Y, GRIP_Z = 94, 23
GRIP_X_START, GRIP_X_END = 93, 125
PIVOT = [109, 40, 30]                 # lever pivot overhead, equidistant from both grip positions


def pose(gx):
    p = trunk(PELVIS, -90)
    p["ankleL"] = [112, 175, 11]
    p["toeL"] = [125, 175, 11]
    p["kneeL"] = joint(p["hipL"], p["ankleL"], L["thigh"], L["shin"], [1, -1, 0])
    hand = [gx, GRIP_Y, GRIP_Z]
    p["elbowL"] = joint(p["shoulderL"], hand, L["upper"], L["fore"], [-1, 0.4, 1])
    p["handL"] = hand
    return mirror(p)


start, end = pose(GRIP_X_START), pose(GRIP_X_END)
props = [slab([[58, 147], [104, 147]], -16, 16, 7),          # seat
         slab([[69, 138], [69, 84]], -14, 14, 7),            # back pad
         line([[82, 150, 0], [82, 181, 0]], 5),              # seat post
         slab([[56, 181], [156, 181]], -30, 30, 4)]          # base
for z in (-PIVOT[2], PIVOT[2]):                              # frame: a post each side and an arm to the pivot
    props.append(line([[150, 181, z], [150, PIVOT[1], z], [PIVOT[0], PIVOT[1], z]], 5))
load = {"type": "machine", "grips": ["handL", "handR"],
        "pivots": [PIVOT, [PIVOT[0], PIVOT[1], -PIVOT[2]]], "axis": [0, 1, 0], "length": 14}
write("machine-chest-press", start, end, props, load, tempo=2.4)
