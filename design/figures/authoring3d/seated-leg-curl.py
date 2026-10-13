"""Seated leg curl: sitting upright, leaning a touch forward, thighs level on the seat and locked under the grey thigh
pad; a volt pad behind the lower calves curls the shins from nearly straight out in front to well under the seat
(about 100 degrees), then back. Hands hold the side handles."""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rig import L, P, joint, trunk, mirror, slab, line, write

PELVIS = [72, 128, 0]
SHIN_START, SHIN_END = 14, 116     # shin angle: nearly straight out, then curled back under the knee
PIVOT = [110, 128, -24]            # lever pivot beside the knee, on the machine's far side


def pose(shin):
    p = trunk(PELVIS, -86, head_ang=-84)
    p["kneeL"] = P(p["hipL"], 0, L["thigh"])
    p["ankleL"] = P(p["kneeL"], shin, L["shin"])
    p["toeL"] = P(p["ankleL"], shin - 78, L["foot"])
    hand = [PELVIS[0] + 8, PELVIS[1] - 1, 24]           # side handle beside the hip
    p["elbowL"] = joint(p["shoulderL"], hand, L["upper"], L["fore"], [-1, 0, 0.5])
    p["handL"] = hand
    return mirror(p)


start, end = pose(SHIN_START), pose(SHIN_END)
props = [slab([[50, 137], [104, 137]], -16, 16, 7),                   # seat
         slab([[60, 131], [52, 80]], -14, 14, 7),                     # back rest
         slab([[94, 118], [112, 118]], -16, 16, 7),                   # thigh pad on top of the thighs
         line([[112, 118, -22], [122, 112, -22], [122, 181, -22]], 5),  # thigh pad arm and tower
         line([[76, 140, 0], [76, 181, 0]], 5),                       # post
         slab([[46, 181], [128, 181]], -20, 20, 4)]                   # base
load = {"type": "pad", "at": ["ankleL", "ankleR"], "offset": [-10, 5, 0], "pivot": PIVOT, "length": 28}
write("seated-leg-curl", start, end, props, load, tempo=2.8)
