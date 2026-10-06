"""Cable lateral raise: front view, side-on to a low pulley on the right; the far (left) arm holds the handle with
the cable behind the body and raises out to shoulder height, elbow leading. The right hand holds the column."""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rig import L, P, along, joint, trunk, mirror, slab, line, write

PELVIS = [96, 103, 0]
LEFT = [-1, 0, 0]
COL = [160, -10]                  # column x, z (a little behind the body)
ANCHOR = [154, 170, COL[1]]


def pose(upper, fore, out_u, out_f):
    p = trunk(PELVIS, -90, left=LEFT)
    for s, dx in (("L", -1), ("R", 1)):
        p["knee" + s] = P(p["hip" + s], 90 - 2 * dx, L["thigh"])
        p["ankle" + s] = P(p["knee" + s], 90 + 2 * dx, L["shin"])
        p["toe" + s] = along(p["ankle" + s], [0.25 * dx, 0, 1], L["foot"])
    p["elbowL"] = P(p["shoulderL"], upper, L["upper"], out_u)
    p["handL"] = P(p["elbowL"], fore, L["fore"], out_f)
    p["handR"] = [COL[0] - 5, 80, COL[1] + 2]
    p["elbowR"] = joint(p["shoulderR"], p["handR"], L["upper"], L["fore"], [0, 1, -0.3])
    return p


start = pose(98, 93, -12, -12)      # hand by the left hip, cable behind the legs
end = pose(180, 168, -8, -6)        # upper arm level with the shoulder, hand a little below the elbow
props = [line([[COL[0], 181, COL[1]], [COL[0], 20, COL[1]]], 6),
         line([[COL[0], ANCHOR[1], COL[1]], ANCHOR], 8),
         slab([[COL[0] - 12, 181], [COL[0] + 12, 181]], COL[1] - 12, COL[1] + 12, 4)]
write("cable-lateral-raise", start, end, props,
      {"type": "cable", "handle": "grip", "at": "handL", "anchor": ANCHOR}, tempo=2.6, view="front")
