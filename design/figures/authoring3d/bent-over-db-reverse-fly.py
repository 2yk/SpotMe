"""Bent-over DB reverse fly: standing, hinged at the hips to near flat, knees soft, back neutral, arms hanging under
the shoulders; raise the dumbbells out wide to shoulder height, elbows soft, pinkies leading. No bench. The sweep
is in depth, so it opens turned."""
import os, sys, math
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rig import L, P, along, joint, trunk, mirror, slab, line, write

PELVIS = [78, 107, 0]
TORSO = -17                     # near flat, chest a little higher than the hips
HAND_END = [-3, 7, 50]          # end: hand from the shoulder, out wide at shoulder height
KNEE_BEND = [1, -0.2, 0]


def pose(raised):
    p = trunk(PELVIS, TORSO, head_ang=TORSO + 8)
    p["ankleL"] = [94, 175, 10]
    p["toeL"] = P(p["ankleL"], 0, L["foot"])
    p["kneeL"] = joint(p["hipL"], p["ankleL"], L["thigh"], L["shin"], KNEE_BEND)
    sh = p["shoulderL"]
    if raised:
        hand = [sh[0] + HAND_END[0], sh[1] + HAND_END[1], sh[2] + HAND_END[2]]
        p["elbowL"] = joint(sh, hand, L["upper"], L["fore"], [0, 1, 0])
    else:
        hand = [sh[0] - 1, sh[1] + math.sqrt(51 ** 2 - 4 ** 2 - 1), sh[2] + 4]
        p["elbowL"] = joint(sh, hand, L["upper"], L["fore"], [0, 0, 1])
    p["handL"] = hand
    return mirror(p)


start, end = pose(False), pose(True)
write("bent-over-db-reverse-fly", start, end, [], {"type": "dumbbells", "axis": [1, 0, 0]}, tempo=2.6, yaw=-50)
