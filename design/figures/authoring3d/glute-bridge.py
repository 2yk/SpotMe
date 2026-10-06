"""Glute bridge: on the back, knees bent, feet flat, arms on the floor at the sides; hips from the floor up
until knees, hips and shoulders are in one line."""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rig import L, P, joint, trunk, write

NECK = [62, 176, 0]
TORSO_START, TORSO_END = 0, -23       # angle neck -> pelvis: on the floor, then the hips up in line
ANKLE = [156, 175]
FOOT_W = 11                           # feet a little wider than the hips
ARM_OUT = 13                          # arms angled out from the body on the floor


def pose(ang):
    pelvis = P(NECK, ang, L["torso"])
    p = trunk(pelvis, ang + 180, head_ang=197)
    p["neck"] = list(NECK)
    for s, k in (("L", 1), ("R", -1)):
        p["ankle" + s] = [ANKLE[0], ANKLE[1], k * FOOT_W]
        p["toe" + s] = [ANKLE[0] + 12.4, 179, k * FOOT_W]
        p["knee" + s] = joint(p["hip" + s], p["ankle" + s], L["thigh"], L["shin"], [0.2, -1, 0])
        p["elbow" + s] = P(p["shoulder" + s], 2, L["upper"], k * ARM_OUT)
        p["hand" + s] = P(p["elbow" + s], 2, L["fore"], k * 4)
    return p


start, end = pose(TORSO_START), pose(TORSO_END)
for k in ("neck", "head", "shoulderL", "shoulderR", "elbowL", "handL", "elbowR", "handR",
          "ankleL", "toeL", "ankleR", "toeR"):
    end[k] = list(start[k])
write("glute-bridge", start, end, (), {"type": "none"}, tempo=2.8)
