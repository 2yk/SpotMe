"""Reverse crunch: on the back, arms flat at the sides, hips and knees bent at 90 (thighs vertical, shins
level); the hips curl off the floor and the knees come toward the chest, then lower slowly."""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rig import L, P, joint, trunk, write

NECK = [66, 176, 0]
ARM_OUT = 13


def pose(curl, thigh):
    """curl: neck -> pelvis angle (0 flat; negative lifts the pelvis). thigh: hip -> knee angle."""
    pelvis = P(NECK, curl, L["torso"])
    p = trunk(pelvis, curl + 180, head_ang=197)
    p["neck"] = list(NECK)
    for s, k in (("L", 1), ("R", -1)):
        p["elbow" + s] = P(p["shoulder" + s], 2, L["upper"], k * ARM_OUT)
        p["hand" + s] = P(p["elbow" + s], 2, L["fore"], k * 4)
        p["knee" + s] = P(p["hip" + s], thigh, L["thigh"], -k * 4)
        p["ankle" + s] = P(p["knee" + s], thigh + 90, L["shin"])
        p["toe" + s] = P(p["ankle" + s], thigh + 40, L["foot"])
    return p


start, end = pose(0, -90), pose(-20, -142)
for k in ("neck", "head", "shoulderL", "shoulderR", "elbowL", "handL", "elbowR", "handR"):
    end[k] = list(start[k])
write("reverse-crunch", start, end, (), {"type": "none"}, tempo=2.8, yaw=20)
