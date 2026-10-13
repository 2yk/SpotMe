"""High cable curl: front view, standing between two high pulleys, arms out to the sides at shoulder height
holding a D-handle each; curl the handles in to the ears while the upper arms stay level (double biceps pose)."""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rig import L, P, along, joint, trunk, mirror, slab, line, write

PELVIS = [100, 103, 0]
LEFT = [-1, 0, 0]
COLX = 14                       # columns this far in from the box edges
ANCHOR_Y = 44                   # pulleys a little above shoulder height


def pose(fore, fore_out):
    p = trunk(PELVIS, -90, left=LEFT)
    for s, dx in (("L", -1), ("R", 1)):
        p["knee" + s] = P(p["hip" + s], 90 - 4 * dx, L["thigh"])
        p["ankle" + s] = P(p["knee" + s], 90 + 1 * dx, L["shin"])
        p["toe" + s] = along(p["ankle" + s], [0.2 * dx, 0, 1], L["foot"])
    p["elbowL"] = P(p["shoulderL"], 182, L["upper"], 6)          # upper arm level, out to the side
    p["handL"] = P(p["elbowL"], 180 - fore, L["fore"], fore_out)
    p["elbowR"] = P(p["shoulderR"], -2, L["upper"], 6)
    p["handR"] = P(p["elbowR"], fore, L["fore"], fore_out)
    return p


start = pose(-6, 4)       # arms long toward the pulleys
end = pose(-140, 18)      # hands curled in beside the ears, a little forward
anchors = [[COLX + 3, ANCHOR_Y, 0], [200 - COLX - 3, ANCHOR_Y, 0]]
props = []
for (ax, ay, az), cx in zip(anchors, (COLX, 200 - COLX)):
    props.append(line([[cx, 181, 0], [cx, 26, 0]], 6))                       # column
    props.append(line([[cx, ay, 0], [ax, ay, az]], 8))                       # pulley
    props.append(slab([[cx - 6, 181], [cx + 6, 181]], -12, 12, 4))          # foot
load = [{"type": "cable", "handle": "grip", "at": "handL", "anchor": anchors[0]},
        {"type": "cable", "handle": "grip", "at": "handR", "anchor": anchors[1]}]
write("high-cable-curl", start, end, props, load, tempo=2.6, view="front")
