"""Suitcase carry: walking tall mid-stride, one heavy dumbbell in the left hand at the side, the right arm free.
A timed hold: only the pelvis moves 2 units."""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rig import L, P, along, joint, trunk, mirror, slab, line, write

PELVIS = [100, 105, 0]
LEFT = [-1, 0, 0]
YAW = 300                 # turned a little toward the loaded side so the stride and the dumbbell show


def pose(dy):
    p = trunk(PELVIS, -90, left=LEFT)
    p["ankleL"], p["ankleR"] = [p["hipL"][0], 177, 15], [p["hipR"][0], 177, -15]   # left foot ahead
    p["toeL"] = along(p["ankleL"], [-0.15, 0, 1], L["foot"])
    p["toeR"] = along(p["ankleR"], [0.15, 0, 1], L["foot"])
    for s in "LR":
        p["knee" + s] = joint(p["hip" + s], p["ankle" + s], L["thigh"], L["shin"], [0, 0, 1])
    p["elbowL"] = P(p["shoulderL"], 97, L["upper"], 0)          # loaded arm straight down, a little out
    p["handL"] = P(p["elbowL"], 95, L["fore"], 0)
    p["elbowR"] = P(p["shoulderR"], 84, L["upper"], 12)         # free arm swings forward, opposite the left leg
    p["handR"] = P(p["elbowR"], 86, L["fore"], 20)
    p["pelvis"] = [PELVIS[0], PELVIS[1] + dy, PELVIS[2]]
    return p


start, end = pose(0), pose(2)
for k in end:
    if k != "pelvis":
        end[k] = start[k]
# One dumbbell, front to back in the left hand: a handle along z plus a plate at each end (the dumbbells load
# would put one in each hand).
load = [{"type": "machine", "grips": ["handL"], "axis": [0, 0, 1], "length": 18},
        {"type": "held", "kind": "plate", "at": "handL", "offset": [0, 0, 8], "axis": [0, 0, 1]},
        {"type": "held", "kind": "plate", "at": "handL", "offset": [0, 0, -8], "axis": [0, 0, 1]}]
write("suitcase-carry", start, end, [], load, tempo=4, view="front", hold=True, yaw=YAW)
