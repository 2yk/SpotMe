"""Reverse-grip pushdown: standing at a high pulley, palms up on a short straight bar held narrow, elbows tight
to the ribs; a shorter path than the overhand pushdown, from forearms about level to straight down."""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rig import L, P, trunk, mirror, slab, line, write

ELBOW = 78          # upper arm: down, elbows tucked a touch further back than the overhand version
FORE_START = -12    # forearms about level (palms up, the wrist stops the bar lower)
FORE_END = 88       # straight down, full lockout
ANCHOR = [146, 18, 0]


def pose(fore):
    p = trunk([92, 101, 0], -75, head_ang=-80)
    p["kneeL"] = P(p["hipL"], 80, L["thigh"])
    p["ankleL"] = P(p["kneeL"], 98, L["shin"])
    p["toeL"] = P(p["ankleL"], 8, L["foot"])
    p["elbowL"] = P(p["shoulderL"], ELBOW, L["upper"], -6)
    p["handL"] = P(p["elbowL"], fore, L["fore"], -10)     # narrow underhand grip
    return mirror(p)


start, end = pose(FORE_START), pose(FORE_END)
props = [line([[166, 181, 0], [166, 12, 0], [146, 12, 0]], 6),
         line([[146, 12, 0], [146, 18, 0]], 8), slab([[156, 181], [176, 181]], -12, 12, 4)]
write("reverse-grip-pushdown", start, end, props, {"type": "cable", "handle": "bar", "anchor": ANCHOR}, tempo=2.6, yaw=25)
