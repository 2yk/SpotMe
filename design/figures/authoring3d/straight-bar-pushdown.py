"""Straight-bar pushdown: standing at a high pulley, overhand on a short straight bar, elbows pinned at the
sides; forearms from about chest height to straight down, the bar at the thighs."""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rig import L, P, trunk, mirror, slab, line, write

ELBOW = 75          # upper arm angle (down, a little forward)
FORE_START = -38    # forearm at the top: bar at chest height
FORE_END = 88       # straight down, bar at the thighs
ANCHOR = [146, 18, 0]


def pose(fore):
    p = trunk([92, 101, 0], -73, head_ang=-79)
    p["kneeL"] = P(p["hipL"], 80, L["thigh"])
    p["ankleL"] = P(p["kneeL"], 98, L["shin"])
    p["toeL"] = P(p["ankleL"], 8, L["foot"])
    p["elbowL"] = P(p["shoulderL"], ELBOW, L["upper"], -4)
    p["handL"] = P(p["elbowL"], fore, L["fore"], -6)      # shoulder-width grip on the bar
    return mirror(p)


start, end = pose(FORE_START), pose(FORE_END)
props = [line([[166, 181, 0], [166, 12, 0], [146, 12, 0]], 6),
         line([[146, 12, 0], [146, 18, 0]], 8), slab([[156, 181], [176, 181]], -12, 12, 4)]
write("straight-bar-pushdown", start, end, props, {"type": "cable", "handle": "bar", "anchor": ANCHOR}, tempo=2.4, yaw=25)
