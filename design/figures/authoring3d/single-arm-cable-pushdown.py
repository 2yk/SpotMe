"""Single-arm cable pushdown: standing at a high pulley with one D-handle in the near hand, elbow pinned at the
side; the forearm from chest height to straight down. The far hand braces on the column."""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rig import L, P, joint, trunk, slab, line, write

ELBOW = 76
FORE_START, FORE_END = -50, 88
COL = 150                            # column x (closer than the two-hand pushdown: the far hand reaches it)
ANCHOR = [134, 16, 11]               # pulley above the working hand's line
BRACE = [COL - 4, 66, -6]            # far hand on the column at chest height


def pose(fore):
    p = trunk([92, 101, 0], -75, head_ang=-80)
    for s, z in (("L", 9), ("R", -9)):
        p["knee" + s] = P(p["hip" + s], 80, L["thigh"])
        p["ankle" + s] = P(p["knee" + s], 98, L["shin"])
        p["toe" + s] = P(p["ankle" + s], 8, L["foot"])
    p["elbowL"] = P(p["shoulderL"], ELBOW, L["upper"], -3)
    p["handL"] = P(p["elbowL"], fore, L["fore"], -2)
    p["handR"] = list(BRACE)
    p["elbowR"] = joint(p["shoulderR"], BRACE, L["upper"], L["fore"], [0, 1, -0.6])
    return p


start, end = pose(FORE_START), pose(FORE_END)
for k in ("elbowR", "handR"):
    end[k] = start[k]
props = [line([[COL + 10, 181, 0], [COL + 10, 10, 0], [ANCHOR[0], 10, ANCHOR[2]]], 6),
         line([[ANCHOR[0], 10, ANCHOR[2]], ANCHOR], 8),
         line([[COL, 175, 0], [COL, 40, 0]], 5),                     # stack guide the far hand holds
         slab([[COL - 2, 181], [COL + 22, 181]], -12, 12, 4)]
write("single-arm-cable-pushdown", start, end, props,
      {"type": "cable", "handle": "grip", "at": "handL", "anchor": ANCHOR}, tempo=2.4, yaw=330)
