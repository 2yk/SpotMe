"""Machine row: seated, chest against an upright pad, neutral handles at chest height on levers hung from a pivot
in front and above; arms reach forward, then the elbows drive back past the torso."""
import os, sys, math
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rig import L, P, along, joint, trunk, mirror, slab, line, write

PELVIS = [64, 140, 0]
TORSO = -86                             # upright, a touch forward onto the pad
HAND_Z = 19
REACH = [113, 108]                      # start: arms long, handles ahead of the chest
PULL = [80, 102]                        # end: handles beside the ribs, elbows behind the back
# Pivot on the bisector of the two grip positions, so the lever keeps its length (the grip swings on an arc).
_m = [(REACH[0] + PULL[0]) / 2, (REACH[1] + PULL[1]) / 2]
_d = [REACH[0] - PULL[0], REACH[1] - PULL[1]]
_n = [_d[1], -_d[0]]
_k = 66 / math.hypot(*_n)
PIVOT = [_m[0] + _n[0] * _k, _m[1] + _n[1] * _k, 24]
if PIVOT[1] > _m[1]:
    PIVOT = [_m[0] - _n[0] * _k, _m[1] - _n[1] * _k, 24]


def pose(hand, s=None):
    p = trunk(PELVIS, TORSO, head_ang=-88)
    if s:
        for k in ("kneeL", "ankleL", "toeL"):
            p[k] = s[k]
    else:
        p["ankleL"] = [102, 175, 11]
        p["toeL"] = P(p["ankleL"], 5, L["foot"])
        p["kneeL"] = joint(p["hipL"], p["ankleL"], L["thigh"], L["shin"], [1, -1, 0])
    p["handL"] = [hand[0], hand[1], HAND_Z]
    p["elbowL"] = joint(p["shoulderL"], p["handL"], L["upper"], L["fore"], [-1, 0.5, 0.25])
    return mirror(p)


start = pose(REACH)
end = pose(PULL, start)
neck = start["neck"]
px = neck[0] + 13
props = [slab([[44, 148], [86, 148]], -14, 14, 7),                      # seat
         line([[66, 151, 0], [66, 181, 0]], 5),                         # seat post
         slab([[px, 92], [px + 2, 126]], -9, 9, 9),                     # chest pad
         line([[px + 3, 124, 0], [142, 124, 0]], 5),                    # pad arm
         line([[142, 181, 0], [142, PIVOT[1], 0], [PIVOT[0], PIVOT[1], 0]], 6),   # front post and top arm
         line([[PIVOT[0], PIVOT[1], -PIVOT[2]], [PIVOT[0], PIVOT[1], PIVOT[2]]], 5),  # pivot shaft
         slab([[44, 181], [150, 181]], -22, 22, 4)]                     # base
load = {"type": "machine", "grips": ["handL", "handR"],
        "pivots": [PIVOT, [PIVOT[0], PIVOT[1], -PIVOT[2]]], "axis": [0, 1, 0], "length": 14}
write("machine-row", start, end, props, load, tempo=2.6)
