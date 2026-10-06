"""Rope pushdown: standing at a high pulley, elbows pinned at the sides, forearms from ~80 deg bent to straight down."""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rig import L, P, trunk, mirror, slab, line, write

ELBOW = 75          # upper arm angle (down, a little forward)
FORE_START = -52    # forearm angle at the top (hands up near the chest)
FORE_END = 90       # straight down
ANCHOR = [146, 18, 0]


def pose(fore, fore_out):
    p = trunk([92, 101, 0], -73, head_ang=-79)
    p["kneeL"] = P(p["hipL"], 80, L["thigh"])
    p["ankleL"] = P(p["kneeL"], 98, L["shin"])
    p["toeL"] = P(p["ankleL"], 8, L["foot"])
    p["elbowL"] = P(p["shoulderL"], ELBOW, L["upper"], -4)
    p["handL"] = P(p["elbowL"], fore, L["fore"], fore_out)
    return mirror(p)


start = pose(FORE_START, -15)     # hands close together on the rope
end = pose(FORE_END, -4)          # rope spread at the bottom
props = [line([[166, 181, 0], [166, 12, 0], [146, 12, 0]], 6),
         line([[146, 12, 0], [146, 18, 0]], 8), slab([[156, 181], [176, 181]], -12, 12, 4)]
write("rope-pushdown", start, end, props, {"type": "cable", "handle": "rope", "anchor": ANCHOR}, tempo=2.4)
