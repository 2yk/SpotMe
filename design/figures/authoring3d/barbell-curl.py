"""Barbell curl: standing tall, side view, straight barbell with plates at shoulder width, elbows pinned at the
sides; curl from the bar on the thighs to the chest."""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rig import L, P, along, joint, trunk, mirror, slab, line, write

PELVIS = [96, 103, 0]


def pose(fore):
    p = trunk(PELVIS, -91)
    p["kneeL"] = P(p["hipL"], 87, L["thigh"])
    p["ankleL"] = P(p["kneeL"], 93, L["shin"])
    p["toeL"] = P(p["ankleL"], 0, L["foot"])
    p["elbowL"] = P(p["shoulderL"], 85, L["upper"], 2)        # shoulder-width grip
    p["handL"] = P(p["elbowL"], fore, L["fore"])
    return mirror(p)


start = pose(70)      # bar on the thighs
end = pose(-62)       # bar at the chest
write("barbell-curl", start, end, [], {"type": "bar", "length": 80, "plate": 14}, tempo=2.6, yaw=30)
