"""Reverse curl: standing tall, side view, EZ bar held overhand (palms down) on the outer angles, elbows pinned;
curl from the thighs to just below the chin. Wrists stay straight, so the knuckles lead."""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rig import L, P, along, joint, trunk, mirror, slab, line, write

PELVIS = [96, 103, 0]


def pose(fore):
    p = trunk(PELVIS, -91)
    p["kneeL"] = P(p["hipL"], 87, L["thigh"])
    p["ankleL"] = P(p["kneeL"], 93, L["shin"])
    p["toeL"] = P(p["ankleL"], 0, L["foot"])
    p["elbowL"] = P(p["shoulderL"], 86, L["upper"], -4)
    p["handL"] = P(p["elbowL"], fore, L["fore"])
    return mirror(p)


start = pose(72)      # bar on the thighs
end = pose(-50)       # bar at the upper chest; a palms-down curl stops a little lower than a regular curl
write("reverse-curl", start, end, [], {"type": "bar", "length": 56, "plate": 8}, tempo=2.8, yaw=30)
