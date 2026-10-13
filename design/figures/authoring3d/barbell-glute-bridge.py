"""Barbell glute bridge: on the back on the floor, knees bent, feet flat, a loaded bar across the hips held
by both hands; hips from the floor up until knees, hips and shoulders are in one line."""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rig import L, P, joint, trunk, write

NECK = [62, 176, 0]
TORSO_START, TORSO_END = 0, -23       # angle neck -> pelvis: on the floor, then the hips up in line
ANKLE = [156, 175]
FOOT_W = 11
BAR_UP = 9                            # bar sits on top of the hips
HAND_Z = 22                           # hands on the bar outside the hips


def pose(ang):
    pelvis = P(NECK, ang, L["torso"])
    p = trunk(pelvis, ang + 180, head_ang=197)
    p["neck"] = list(NECK)
    for s, k in (("L", 1), ("R", -1)):
        p["ankle" + s] = [ANKLE[0], ANKLE[1], k * FOOT_W]
        p["toe" + s] = [ANKLE[0] + 12.4, 179, k * FOOT_W]
        p["knee" + s] = joint(p["hip" + s], p["ankle" + s], L["thigh"], L["shin"], [0.2, -1, 0])
        hand = [pelvis[0] - 3, pelvis[1] - BAR_UP - 1, k * HAND_Z]
        p["elbow" + s] = joint(p["shoulder" + s], hand, L["upper"], L["fore"], [0, -1, 0.5 * k])
        p["hand" + s] = hand
    return p


start, end = pose(TORSO_START), pose(TORSO_END)
for k in ("neck", "head", "shoulderL", "shoulderR", "ankleL", "toeL", "ankleR", "toeR"):
    end[k] = list(start[k])
load = {"type": "bar", "at": "pelvis", "offset": [0, -BAR_UP, 0], "length": 92, "plate": 14}
write("barbell-glute-bridge", start, end, (), load, tempo=2.8)
