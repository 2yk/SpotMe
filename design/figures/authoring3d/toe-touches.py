"""Toe touches: on the back, legs straight up, arms reaching up; the shoulders curl off the floor until the
hands reach the toes."""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rig import L, P, along, joint, trunk, write

PELVIS = [118, 176, 0]
LEG = -98                             # legs straight up, a touch toward the head
TORSO_START, TORSO_END = 180, 218     # pelvis -> neck: flat, then curled up
ARM_START = -72                       # arms reaching up toward the feet


def dist(a, b):
    return sum((a[i] - b[i]) ** 2 for i in range(3)) ** 0.5


def pose(torso, reach):
    p = trunk(PELVIS, torso, head_ang=torso + (17 if torso == 180 else 12))
    for s, k in (("L", 1), ("R", -1)):
        p["knee" + s] = P(p["hip" + s], LEG, L["thigh"])
        p["ankle" + s] = P(p["knee" + s], LEG, L["shin"])
        p["toe" + s] = P(p["ankle" + s], -150, L["foot"])
        sh = p["shoulder" + s]
        if reach:
            target = [p["toe" + s][0] - 2, p["toe" + s][1] + 6, k * 6]
            d = min(dist(sh, target), L["upper"] + L["fore"] - 2)
            hand = along(sh, [target[i] - sh[i] for i in range(3)], d)
            p["elbow" + s] = joint(sh, hand, L["upper"], L["fore"], [-0.3, 0.6, k])
            p["hand" + s] = hand
        else:
            p["elbow" + s] = P(sh, ARM_START, L["upper"], -k * 6)
            p["hand" + s] = P(p["elbow" + s], ARM_START, L["fore"], -k * 6)
    return p


start, end = pose(TORSO_START, False), pose(TORSO_END, True)
for k in ("pelvis", "hipL", "hipR", "kneeL", "ankleL", "toeL", "kneeR", "ankleR", "toeR"):
    end[k] = list(start[k])
write("toe-touches", start, end, (), {"type": "none"}, tempo=2.4)
