"""Reverse pec deck: seated facing the machine, chest on the pad, arms straight out in front at shoulder height;
they sweep out and back to the sides, a little behind. The movement is in depth, so it opens turned (yaw)."""
import os, sys, math
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rig import L, P, along, joint, trunk, mirror, slab, line, write

PELVIS = [74, 140, 0]
TORSO = -86                             # upright, a touch forward onto the pad
ARM = 51                                # shoulder to hand, elbows soft
PIVOT_Y = 34


def pose(sweep, s=None):
    """sweep: arm angle in the horizontal plane, 0 = straight ahead, 100 = out to the side and a little behind."""
    p = trunk(PELVIS, TORSO, head_ang=-88)
    if s:
        for k in ("kneeL", "ankleL", "toeL", "hipL"):
            p[k] = s[k]
    else:
        p["ankleL"] = [108, 175, 12]
        p["toeL"] = P(p["ankleL"], 5, L["foot"])
        p["kneeL"] = joint(p["hipL"], p["ankleL"], L["thigh"], L["shin"], [1, -1, 0])
    a = math.radians(sweep)
    sh = p["shoulderL"]
    p["handL"] = along(sh, [math.cos(a), 0.06, math.sin(a)], ARM)
    p["elbowL"] = joint(sh, p["handL"], L["upper"], L["fore"], [0, 0.5, -1] if sweep < 50 else [0.6, 0.5, 0])
    return mirror(p)


start = pose(-12)                       # hands in front, a little inside shoulder width
end = pose(100, start)
neck = start["neck"]
PIVOT = [neck[0] + 8, PIVOT_Y, 0]       # one pivot above the shoulders; both levers hang from it
props = [slab([[54, 148], [96, 148]], -15, 15, 7),                     # seat
         line([[76, 151, 0], [76, 181, 0]], 5),                        # seat post
         slab([[neck[0] + 13, 97], [neck[0] + 15, 126]], -9, 9, 8),   # chest pad
         line([[neck[0] + 15, 112, 0], [150, 112, 0]], 5),             # pad arm
         line([[150, 181, 0], [150, 24, 0], [PIVOT[0], 24, 0], PIVOT], 6),  # front post and top arm
         slab([[54, 181], [160, 181]], -24, 24, 4)]                    # base
load = {"type": "machine", "grips": ["handL", "handR"], "pivots": [PIVOT, PIVOT], "axis": [0, 1, 0], "length": 14}
write("reverse-pec-deck", start, end, props, load, tempo=2.6, yaw=22)
