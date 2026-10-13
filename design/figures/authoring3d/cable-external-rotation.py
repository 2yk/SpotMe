"""Cable external rotation: standing side-on to a pulley at elbow height (on the viewer's right), front view. The
arm far from the pulley (L, on the viewer's left) works: upper arm pinned to the ribs, elbow at 90 degrees, forearm level;
the hand turns from across the belly out to the side, the elbow stays put. The other hand rests on the hip.
The rotation is in the floor plane; seen from the front the hand travels from the belly out past the hip."""
import os, sys, math
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rig import L, P, along, joint, trunk, mirror, slab, line, write

PELVIS = [100, 103, 0]
LEFT = [-1, 0, 0]
COL = [176, 6]                    # column x, z
START_DEG, END_DEG = 40, 150      # forearm direction in the floor plane: 0 = toward the pulley (+x), 90 = forward


def pose(deg):
    p = trunk(PELVIS, -90, left=LEFT)
    for s, dx in (("L", -1), ("R", 1)):
        p["knee" + s] = P(p["hip" + s], 90 + 2 * dx, L["thigh"])
        p["ankle" + s] = P(p["knee" + s], 90 - 2 * dx, L["shin"])
        p["toe" + s] = along(p["ankle" + s], [0.25 * dx, 0, 1], L["foot"])
    sh = p["shoulderL"]
    p["elbowL"] = [sh[0] + 4, sh[1] + 26.5, 3]                 # pinned to the side, a towel's width off the ribs
    a = math.radians(deg)
    p["handL"] = along(p["elbowL"], [math.cos(a), 0, math.sin(a)], L["fore"])
    shr = p["shoulderR"]                                        # free hand on the hip
    p["handR"] = [p["hipR"][0] + 5, p["hipR"][1] - 6, 4]
    p["elbowR"] = joint(shr, p["handR"], L["upper"], L["fore"], [1, 0, -0.4])
    return p


start, end = pose(START_DEG), pose(END_DEG)
for k in start:
    if k != "handL":
        end[k] = start[k]
ANCHOR = [COL[0] - 5, start["elbowL"][1], COL[1]]
props = [line([[COL[0], 181, COL[1]], [COL[0], 22, COL[1]]], 6),
         line([[COL[0], ANCHOR[1], COL[1]], ANCHOR], 8),
         slab([[COL[0] - 10, 181], [COL[0] + 10, 181]], COL[1] - 10, COL[1] + 10, 4)]
write("cable-external-rotation", start, end, props,
      {"type": "cable", "handle": "grip", "at": "handL", "anchor": ANCHOR}, tempo=2.6, view="front", yaw=10)
