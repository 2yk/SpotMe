"""Hollow body hold: on the back, low back flat, shoulders lifted a little, arms overhead and legs straight,
both low off the floor: a shallow banana. Timed hold."""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rig import L, P, trunk, write

PELVIS = [114, 175, 0]
TORSO = 202                           # pelvis -> neck: shoulders a little off the floor
ARM = 192                             # arms overhead, hands just off the floor
LEG = -18                             # legs straight, feet low off the floor


def pose(lift):
    p = trunk([PELVIS[0], PELVIS[1] - lift, 0], TORSO, head_ang=TORSO + 14)
    for s, k in (("L", 1), ("R", -1)):
        p["elbow" + s] = P(p["shoulder" + s], ARM, L["upper"], k * -4)
        p["hand" + s] = P(p["elbow" + s], ARM, L["fore"], k * -3)
        p["knee" + s] = P(p["hip" + s], LEG, L["thigh"], k * -3)
        p["ankle" + s] = P(p["knee" + s], LEG, L["shin"], 0)
        p["toe" + s] = P(p["ankle" + s], LEG + 10, L["foot"])
    return p


start = pose(0)
end = {k: list(v) for k, v in start.items()}
end["pelvis"] = [PELVIS[0], PELVIS[1] - 2, 0]
write("hollow-body-hold", start, end, (), {"type": "none"}, tempo=4, hold=True)
