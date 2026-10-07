"""Machine chest press: seated upright, back on the pad, hands press forward from beside the chest to nearly straight."""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rig import L, P, joint, trunk, mirror, slab, line, write

PELVIS = [78, 138, 0]
GRIP_Y, GRIP_Z = 94, 23
GRIP_X_START, GRIP_X_END = 93, 125
PIVOT = [56, 80, 30]                  # lever pivot on top of the uprights, behind and a little above the shoulders (clear of the head)


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
         slab([[69, 138], [69, 82]], -14, 14, 9),            # back pad
         line([[82, 150, 0], [82, 181, 0]], 5),              # seat post
         line([[69, 120, 0], [56, 120, 0]], 4),              # back pad bracket to the frame
         slab([[50, 181], [120, 181]], -30, 30, 4)]          # base
for z in (-PIVOT[2], PIVOT[2]):                              # frame: an upright each side behind the pad, pivot on top
    props.append(line([[PIVOT[0], 181, z], [PIVOT[0], PIVOT[1], z]], 5))
load = {"type": "machine", "grips": ["handL", "handR"],
        "pivots": [PIVOT, [PIVOT[0], PIVOT[1], -PIVOT[2]]], "axis": [0, 1, 0], "length": 14}
write("machine-chest-press", start, end, props, load, tempo=2.4)
