"""Plate front raise: standing, side view, a plate held in both hands at 3 and 9 o'clock, arms straight (elbows
soft); raised from in front of the thighs to eye level, plate upright, facing forward. Opens turned so the plate
reads as a disc."""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rig import L, P, along, joint, trunk, mirror, slab, line, write

PELVIS = [92, 103, 0]
HZ = 10                            # hands this far either side of the middle: the plate's rim


def pose(arm):
    p = trunk(PELVIS, -90)
    p["kneeL"] = P(p["hipL"], 88, L["thigh"])
    p["ankleL"] = P(p["kneeL"], 92, L["shin"])
    p["toeL"] = P(p["ankleL"], 0, L["foot"])
    sh = p["shoulderL"]
    hand = along(sh, [__import__("math").cos(__import__("math").radians(arm)),
                      __import__("math").sin(__import__("math").radians(arm)), 0], 50)
    hand[2] = HZ
    p["handL"] = hand
    p["elbowL"] = joint(sh, hand, L["upper"], L["fore"], [0, 1, 0.3])
    return mirror(p)


start = pose(78)                   # plate in front of the thighs
end = pose(-14)                    # plate at eye level, arms a little above horizontal
for k in list(start):
    if k not in ("elbowL", "handL", "elbowR", "handR"):
        end[k] = start[k]
load = {"type": "held", "kind": "plate", "at": "hands", "axis": [1, 0, 0]}
write("plate-front-raise", start, end, [], load, tempo=2.8, yaw=40)
