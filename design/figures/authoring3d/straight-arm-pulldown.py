"""Straight-arm pulldown: slight hip hinge facing a high pulley, straight arms sweep a bar from forehead height to the thighs."""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rig import L, P, along, joint, trunk, mirror, slab, line, write

PELVIS = [78, 102, 0]
TORSO = -74
ARM_START, ARM_END = -20, 87
ANCHOR = [158, 19, 0]


def pose(arm):
    p = trunk(PELVIS, TORSO, head_ang=-80)
    p["ankleL"] = [84, 175, 9]
    p["toeL"] = P(p["ankleL"], 10, L["foot"])
    p["kneeL"] = joint(p["hipL"], p["ankleL"], L["thigh"], L["shin"], [1, 0, 0])
    p["elbowL"] = P(p["shoulderL"], arm, L["upper"], -4)
    p["handL"] = P(p["elbowL"], arm - 10, L["fore"], -4)
    return mirror(p)


start, end = pose(ARM_START), pose(ARM_END)
props = [line([[178, 181, 0], [178, 13, 0], [158, 13, 0]], 6), line([[158, 13, 0], ANCHOR], 8),
         slab([[168, 181], [188, 181]], -12, 12, 4)]
write("straight-arm-pulldown", start, end, props, {"type": "cable", "handle": "bar", "anchor": ANCHOR}, tempo=2.6)
