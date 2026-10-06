"""DB lateral raise: standing, front view; arms from hanging at the sides to straight out at shoulder height, elbows soft."""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rig import L, P, along, joint, trunk, mirror, slab, line, write

PELVIS = [100, 103, 0]
LEFT = [-1, 0, 0]


def legs(p):
    for s, dx in (("L", -1), ("R", 1)):
        p["knee" + s] = P(p["hip" + s], 90 - 2 * dx, L["thigh"])
        p["ankle" + s] = P(p["knee" + s], 90 + 2 * dx, L["shin"])
        p["toe" + s] = along(p["ankle" + s], [-0.25 * -dx, 0, 1], L["foot"])


def pose(upper, fore, out_u, out_f):
    """upper/fore: angles for the L arm (180 = out to the viewer's left); R is mirrored."""
    p = trunk(PELVIS, -90, left=LEFT)
    legs(p)
    p["elbowL"] = P(p["shoulderL"], upper, L["upper"], out_u)
    p["handL"] = P(p["elbowL"], fore, L["fore"], out_f)
    p["elbowR"] = P(p["shoulderR"], 180 - upper, L["upper"], out_u)
    p["handR"] = P(p["elbowR"], 180 - fore, L["fore"], out_f)
    return p


start = pose(100, 95, 8, 14)        # hanging beside the thighs, dumbbells a little in front
end = pose(180, 171, 10, 16)        # upper arm level with the shoulder, hand just below the elbow
write("db-lateral-raise", start, end, [], {"type": "dumbbells", "axis": [0, 0, 1]}, tempo=2.6, view="front")
