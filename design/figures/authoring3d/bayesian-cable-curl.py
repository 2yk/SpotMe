"""Bayesian cable curl: facing away from a low pulley, small staggered stance; the near arm stays behind the
torso and curls the handle forward and up to the shoulder. The far arm hangs."""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rig import L, P, along, joint, trunk, mirror, slab, line, write

PELVIS = [104, 105, 0]
UPPER = 128           # near upper arm: back and down, behind the torso
ANCHOR = [44, 168, 17]


def pose(fore):
    p = trunk(PELVIS, -79, head_ang=-84)
    p["ankleL"], p["toeL"] = [118, 176, 9], [131, 177, 9]          # front foot
    p["ankleR"], p["toeR"] = [88, 176, -9], [101, 177, -9]         # back foot
    for s in "LR":
        p["knee" + s] = joint(p["hip" + s], p["ankle" + s], L["thigh"], L["shin"], [1, 0, 0])
    p["elbowL"] = P(p["shoulderL"], UPPER, L["upper"], 3)
    p["handL"] = P(p["elbowL"], fore, L["fore"])
    p["elbowR"] = P(p["shoulderR"], 92, L["upper"], -4)
    p["handR"] = P(p["elbowR"], 86, L["fore"])
    return p


start = pose(UPPER - 12)       # arm long behind the body
end = pose(UPPER - 158)        # hand up by the shoulder, elbow still behind
props = [line([[36, 181, ANCHOR[2]], [36, 20, ANCHOR[2]]], 6),
         line([[36, ANCHOR[1], ANCHOR[2]], ANCHOR], 8),
         slab([[24, 181], [50, 181]], ANCHOR[2] - 12, ANCHOR[2] + 12, 4)]
write("bayesian-cable-curl", start, end, props,
      {"type": "cable", "handle": "grip", "at": "handL", "anchor": ANCHOR}, tempo=2.6)
