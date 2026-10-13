"""DB curl: standing, side view, a dumbbell in each hand palms up (handles across the body), elbows at the sides;
curl from hanging to the shoulders."""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rig import L, P, along, joint, trunk, mirror, slab, line, write

PELVIS = [100, 103, 0]


def pose(fore):
    p = trunk(PELVIS, -90)
    p["kneeL"] = P(p["hipL"], 88, L["thigh"])
    p["ankleL"] = P(p["kneeL"], 92, L["shin"])
    p["toeL"] = P(p["ankleL"], 0, L["foot"])
    p["elbowL"] = P(p["shoulderL"], 86, L["upper"], 6)
    p["handL"] = P(p["elbowL"], fore, L["fore"], 6)
    return mirror(p)


start = pose(88)      # hanging at the sides
end = pose(-66)       # dumbbell at the shoulder
write("db-curl", start, end, [], {"type": "dumbbells", "axis": [0, 0, 1]}, tempo=2.6, yaw=30)
