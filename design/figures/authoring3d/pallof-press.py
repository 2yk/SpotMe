"""Pallof press: standing side-on to a chest-height pulley, both hands on one handle press straight out from the sternum and back."""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rig import L, P, along, joint, trunk, mirror, slab, line, write

PELVIS = [100, 101, 0]
HAND_Y = 72
Z_START, Z_END = 14, 46
ANCHOR = [176, 72, 12]


def pose(z, bend):
    p = trunk(PELVIS, -90, left=[-1, 0, 0])
    p["ankleL"] = [88, 175, -2]
    p["toeL"] = along(p["ankleL"], [0, 0.3, 1], L["foot"])
    p["kneeL"] = joint(p["hipL"], p["ankleL"], L["thigh"], L["shin"], [0, 0, 1])
    p["handL"] = [98, HAND_Y, z]
    p["elbowL"] = joint(p["shoulderL"], p["handL"], L["upper"], L["fore"], bend)
    for k in [k for k in p if k.endswith("L")]:
        x, y, zz = p[k]
        p[k[:-1] + "R"] = [2 * PELVIS[0] - x, y, zz]
    return p


start, end = pose(Z_START, [-1, 1, 0]), pose(Z_END, [-1, 1, 0])
props = [line([[184, 181, ANCHOR[2]], [184, 64, ANCHOR[2]], [ANCHOR[0], 64, ANCHOR[2]]], 6),
         line([[ANCHOR[0], 64, ANCHOR[2]], ANCHOR], 8), slab([[172, 181], [190, 181]], 0, 24, 4)]
write("pallof-press", start, end, props, {"type": "cable", "handle": "grip", "at": "handL", "anchor": ANCHOR},
      tempo=2.6, view="front", yaw=52)
