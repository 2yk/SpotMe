"""Seated calf raise: sitting upright, knees bent about 90 degrees, the machine's volt pad across the lower thighs,
balls of the feet on the edge of a footrest; heels from dropped below the edge (full stretch) to high on the toes,
lifting the knees and the pad. Hands hold the pad's handles."""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rig import L, P, joint, trunk, mirror, slab, line, write

PELVIS = [82, 128, 0]
TOE = [132, 166, 10]
STEP_Y, STEP_X = 171, (126, 154)
PIVOT = [168, 132, -26]          # pad lever pivots at the front, beside the footrest


def pose(foot_ang, s=None):
    """foot_ang: ankle -> toe (negative: heel below the edge, positive: up on the toes)."""
    p = trunk(PELVIS, -90, head_ang=-88)
    a = P(TOE, foot_ang + 180, L["foot"])
    p["ankleL"], p["toeL"] = [a[0], a[1], TOE[2]], list(TOE)
    p["kneeL"] = joint(p["hipL"], p["ankleL"], L["thigh"], L["shin"], [0.4, -1, 0])
    hand = [p["kneeL"][0] - 6, p["kneeL"][1] - 15, 22]          # on the pad's handle
    p["elbowL"] = joint(p["shoulderL"], hand, L["upper"], L["fore"], [-0.6, 1, 0.4])
    p["handL"] = hand
    return mirror(p)


start, end = pose(-28), pose(27)
props = [slab([[58, 137], [102, 137]], -16, 16, 7),                    # seat
         line([[78, 140, 0], [78, 181, 0]], 5),                         # seat post
         slab([[STEP_X[0], STEP_Y], [STEP_X[1], STEP_Y]], -20, 20, 7),  # footrest
         line([[140, 174, 0], [140, 181, 0]], 6),
         line([[PIVOT[0], PIVOT[1], PIVOT[2]], [PIVOT[0], 181, PIVOT[2]]], 5),   # front tower
         slab([[54, 181], [176, 181]], -22, 22, 4)]                     # base
load = {"type": "pad", "at": ["kneeL", "kneeR"], "offset": [-8, -8, 0], "pivot": PIVOT, "length": 40}
write("seated-calf-raise", start, end, props, load, tempo=2.6, yaw=-25)
