"""Overhead cable extension: facing away from a low pulley, staggered stance, slight lean; elbows by the ears, forearms from folded behind the head to straight."""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rig import L, P, along, joint, trunk, mirror, slab, line, write

PELVIS = [100, 105, 0]
TORSO = -72
UPPER = -58          # upper arm: up and forward, elbows beside the ears
FORE_START, FORE_END = 128, -62
ANCHOR = [22, 172, 0]


def pose(fore):
    p = trunk(PELVIS, TORSO, head_ang=-76)
    p["elbowL"] = P(p["shoulderL"], UPPER, L["upper"], -7)
    p["handL"] = P(p["elbowL"], fore, L["fore"], -10)
    p = mirror(p)
    for s, ank, toe_ang, bend in (("L", [120, 175, 9], 8, [1, 0, 0]), ("R", [74, 173, -9], 18, [1, 0, 0])):
        p["ankle" + s] = ank
        p["toe" + s] = P(ank, toe_ang, L["foot"])
        p["knee" + s] = joint(p["hip" + s], ank, L["thigh"], L["shin"], bend)
    return p


start, end = pose(FORE_START), pose(FORE_END)
props = [line([[13, 181, 0], [13, 166, 0], [ANCHOR[0], 166, 0]], 6), line([[ANCHOR[0], 166, 0], ANCHOR], 8),
         slab([[12, 181], [30, 181]], -12, 12, 4)]
write("overhead-cable-extension", start, end, props, {"type": "cable", "handle": "rope", "anchor": ANCHOR}, tempo=2.6)
