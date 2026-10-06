"""Hammer curl: standing, side view, dumbbells thumbs-up; elbows at the sides, curl from hanging to the shoulders."""
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
    p["handL"] = P(p["elbowL"], fore, L["fore"])
    return mirror(p)


start = pose(86)      # hanging
end = pose(-68)       # dumbbell in front of the shoulder
write("hammer-curl", start, end, [], {"type": "dumbbells", "axis": [1, 0, 0]}, tempo=2.6)
