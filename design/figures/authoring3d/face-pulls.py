"""Face pulls: standing facing a pulley at face height, rope pulled from straight arms to elbows high and wide, hands by the ears."""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rig import L, P, along, joint, trunk, mirror, slab, line, write

PELVIS = [74, 101, 0]
ANCHOR = [160, 40, 0]


def pose(hand, bend):
    p = trunk(PELVIS, -92)
    p["ankleL"] = [76, 175, 9]
    p["toeL"] = P(p["ankleL"], 10, L["foot"])
    p["kneeL"] = joint(p["hipL"], p["ankleL"], L["thigh"], L["shin"], [1, 0, 0])
    n = p["neck"]
    p["handL"] = [n[0] + hand[0], n[1] + hand[1], hand[2]]
    p["elbowL"] = joint(p["shoulderL"], p["handL"], L["upper"], L["fore"], bend)
    return mirror(p)


start = pose([49, -9, 7], [0, 1, 0.3])
end = pose([9, -17, 21], [-0.3, 0.2, 1])
props = [line([[176, 181, 0], [176, 34, 0], [ANCHOR[0], 34, 0]], 6), line([[ANCHOR[0], 34, 0], ANCHOR], 8),
         slab([[166, 181], [186, 181]], -12, 12, 4)]
write("face-pulls", start, end, props, {"type": "cable", "handle": "rope", "anchor": ANCHOR}, tempo=2.6, yaw=-40)
