"""Leg extension: seated, shins from hanging (knees 90 deg) to straight out; pad on the front of the ankles."""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rig import L, P, joint, trunk, mirror, slab, line, write

PELVIS = [80, 130, 0]
SHIN_START, SHIN_END = 90, -4      # shin angle: hanging, then straight out (a touch above level)
PIVOT = [118, 130, -22]            # lever pivot: beside the knee, on the machine's far side


def pose(shin):
    p = trunk(PELVIS, -96)
    p["kneeL"] = P(p["hipL"], 0, L["thigh"])
    p["ankleL"] = P(p["kneeL"], shin, L["shin"])
    p["toeL"] = P(p["ankleL"], shin - 75, L["foot"])
    hand = [PELVIS[0] + 6, PELVIS[1] - 2, 24]           # holding the seat handle beside the hip
    p["elbowL"] = joint(p["shoulderL"], hand, L["upper"], L["fore"], [-1, 0, 0.5])
    p["handL"] = hand
    return mirror(p)


start, end = pose(SHIN_START), pose(SHIN_END)
props = [slab([[58, 139], [112, 139]], -16, 16, 7),                   # seat
         slab([[71, 131], [66, 80]], -14, 14, 7),                     # back rest
         line([[86, 142, 0], [86, 181, 0]], 5),                       # post
         slab([[58, 181], [122, 181]], -18, 18, 4),                   # base
         line([[104, 181, -22], [PIVOT[0], PIVOT[1] + 3, -22]], 5)]  # lever tower
load = {"type": "pad", "at": ["ankleL", "ankleR"], "offset": [4, -4, 0], "pivot": PIVOT, "length": 28}
write("leg-extension", start, end, props, load, tempo=2.6)
