"""Cable curl: standing facing a low pulley, straight bar, elbows pinned; curl from the thighs to the chest."""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rig import L, P, along, joint, trunk, mirror, slab, line, write

PELVIS = [92, 103, 0]
ANCHOR = [156, 170, 0]


def pose(fore):
    p = trunk(PELVIS, -92)
    p["kneeL"] = P(p["hipL"], 87, L["thigh"])
    p["ankleL"] = P(p["kneeL"], 93, L["shin"])
    p["toeL"] = P(p["ankleL"], 0, L["foot"])
    p["elbowL"] = P(p["shoulderL"], 84, L["upper"], -4)
    p["handL"] = P(p["elbowL"], fore, L["fore"])
    return mirror(p)


start = pose(68)      # bar on the thighs
end = pose(-62)       # bar at the chest
props = [line([[164, 181, 0], [164, 20, 0]], 6),                 # column
         line([[164, 170, 0], [ANCHOR[0], ANCHOR[1], 0]], 8),    # pulley
         slab([[150, 181], [176, 181]], -12, 12, 4)]             # base
write("cable-curl", start, end, props, {"type": "cable", "handle": "bar", "anchor": ANCHOR}, tempo=2.6)
