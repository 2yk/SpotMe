"""Barbell overhead press (standing): standing tall, feet hip-width, no bench; a barbell from the front of the
collarbone (elbows forward, under the bar) pressed straight up to arms locked over the head. The head tips back a
little at the bottom so the bar clears the chin, and comes through under the bar at the top."""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rig import L, P, joint, trunk, mirror, write

PELVIS = [100, 103, 0]
GRIP = 25                       # hands a bit wider than the shoulders
BOTTOM = [14, 1]                # bottom: bar from the neck, just in front of the collarbone
TOP = [3, -50]                  # top: hand from the shoulder, over the head, arms straight
HEAD_BACK = -110                # bottom: head tipped back so the bar clears the chin


def pose(top):
    p = trunk(PELVIS, -90, head_ang=-86 if top else HEAD_BACK)
    p["hipL"] = [PELVIS[0], PELVIS[1], 9]
    p["kneeL"] = P(p["hipL"], 88, L["thigh"], 3)
    p["ankleL"] = P(p["kneeL"], 92, L["shin"], 3)
    p["ankleL"][1] = 175
    p["toeL"] = P(p["ankleL"], 0, L["foot"])
    sh, nk = p["shoulderL"], p["neck"]
    if top:
        hand = [sh[0] + TOP[0], sh[1] + TOP[1], GRIP]
        p["elbowL"] = joint(sh, hand, L["upper"], L["fore"], [0.3, 0, 1])
    else:
        hand = [nk[0] + BOTTOM[0], nk[1] + BOTTOM[1], GRIP]
        p["elbowL"] = joint(sh, hand, L["upper"], L["fore"], [0.5, 1, 0.3])
    p["handL"] = hand
    return mirror(p)


start, end = pose(False), pose(True)
load = {"type": "bar", "length": 92, "plate": 14}
write("standing-barbell-press", start, end, [], load, tempo=2.6, yaw=40)
