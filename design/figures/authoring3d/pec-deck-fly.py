"""Pec deck fly: seated upright, back on the pad, feet on the floor; arms out to the sides at chest height, elbows
soft, hands on the upright handles. The handles sweep forward and together in front of the chest, then open back
to a stretch a little behind the shoulders. Levers hang from pivots above the shoulders. The movement is in depth,
so it opens turned (the mirror of reverse-pec-deck: back pad behind instead of a chest pad in front)."""
import os, sys, math
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rig import L, P, along, joint, trunk, mirror, slab, line, write

PELVIS = [80, 140, 0]
ARM = 50                                # shoulder to hand, elbows soft
HAND_DROP = 0.18                        # hands a little below the shoulders (chest height)
PIVOT_Y = 30


def pose(sweep, s=None):
    """sweep: arm angle in the horizontal plane, 0 = straight ahead, 100 = out to the side, a little behind."""
    p = trunk(PELVIS, -90, head_ang=-90)
    if s:
        for k in ("kneeL", "ankleL", "toeL"):
            p[k] = s[k]
    else:
        p["ankleL"] = [114, 175, 13]
        p["toeL"] = P(p["ankleL"], 5, L["foot"])
        p["kneeL"] = joint(p["hipL"], p["ankleL"], L["thigh"], L["shin"], [1, -1, 0])
    a = math.radians(sweep)
    sh = p["shoulderL"]
    p["handL"] = along(sh, [math.cos(a), HAND_DROP, math.sin(a)], ARM)
    p["elbowL"] = joint(sh, p["handL"], L["upper"], L["fore"], [-0.3, 0.6, 1] if sweep < 50 else [-1, 0.6, 0])
    return mirror(p)


start = pose(102)                       # open: arms out to the sides, a little behind
end = pose(-14, start)                  # together in front of the chest
neck = start["neck"]
PIV = [neck[0] - 2, PIVOT_Y, 16]        # a pivot above each shoulder; the levers hang from them
props = [slab([[58, 148], [102, 148]], -15, 15, 7),                     # seat
         line([[82, 151, 0], [82, 181, 0]], 5),                        # seat post
         slab([[neck[0] - 11, 146], [neck[0] - 11, 76]], -13, 13, 9),  # back pad
         line([[neck[0] - 11, 110, 0], [40, 110, 0]], 5),              # pad bracket
         line([[40, 181, 0], [40, 22, 0], [PIV[0], 22, 0]], 6),         # rear post and top arm
         line([[PIV[0], 22, -PIV[2]], [PIV[0], 22, PIV[2]]], 6),       # cross bar to the two pivots
         line([[PIV[0], 22, PIV[2]], PIV], 5), line([[PIV[0], 22, -PIV[2]], [PIV[0], PIV[1], -PIV[2]]], 5),
         slab([[34, 181], [120, 181]], -24, 24, 4)]                    # base
load = {"type": "machine", "grips": ["handL", "handR"], "pivots": [PIV, [PIV[0], PIV[1], -PIV[2]]],
        "axis": [0, 1, 0], "length": 14}
write("pec-deck-fly", start, end, props, load, tempo=2.8, yaw=50)
