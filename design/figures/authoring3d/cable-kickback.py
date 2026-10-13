"""Cable kickback: facing a low pulley, hinged forward with soft knees, the far hand on the column; the near
upper arm held level beside the body, the forearm from hanging toward the pulley to straight back."""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rig import L, P, joint, trunk, slab, line, write

PELVIS = [82, 104, 0]
TORSO = -24                     # hinged forward
UPPER, UPPER_OUT = 186, 6       # upper arm level beside the body
FORE_START, FORE_END = 78, 186
COL = 166
ANCHOR = [COL - 12, 168, 16]    # low pulley in line with the near hand
BRACE = [COL - 4, 98, -8]       # far hand on the column


def pose(fore):
    p = trunk(PELVIS, TORSO, head_ang=-14)
    for s, ank, z in (("L", [104, 175, 11], 11), ("R", [74, 175, -11], -11)):
        p["ankle" + s] = list(ank)
        p["toe" + s] = P(ank, 0, L["foot"])
        p["knee" + s] = joint(p["hip" + s], ank, L["thigh"], L["shin"], [1, 0, 0])
    p["elbowL"] = P(p["shoulderL"], UPPER, L["upper"], UPPER_OUT)
    p["handL"] = P(p["elbowL"], fore, L["fore"])
    p["handR"] = list(BRACE)
    p["elbowR"] = joint(p["shoulderR"], BRACE, L["upper"], L["fore"], [0, 1, -0.5])
    return p


start, end = pose(FORE_START), pose(FORE_END)
props = [line([[COL + 6, 181, 0], [COL + 6, 20, 0]], 6),                    # column
         line([[COL + 6, ANCHOR[1], 0], [ANCHOR[0], ANCHOR[1], ANCHOR[2]]], 5),   # low pulley arm
         line([[ANCHOR[0], ANCHOR[1] - 3, ANCHOR[2]], [ANCHOR[0], ANCHOR[1] + 3, ANCHOR[2]]], 8),
         line([[COL - 4, 60, -8], [COL - 4, 150, -8]], 5),                     # upright the far hand holds
         slab([[COL - 6, 181], [COL + 18, 181]], -14, 14, 4)]
write("cable-kickback", start, end, props, {"type": "cable", "handle": "grip", "at": "handL", "anchor": ANCHOR},
      tempo=2.6)
