"""Stability ball leg curl: on the back, shoulders and arms on the floor, heels on a big ball, hips up so the body
is one straight line; the knees bend and the heels pull the ball in toward the glutes while the hips rise higher.
The ball is a short, very thick pad under the heels: its round caps draw a volt disc from every side."""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rig import L, P, along, joint, trunk, write

NECK = [36, 175, 0]
BALL_R = 23
HEEL_Y = 182 - 2 * BALL_R - 5          # heels on top of the ball, the ball on the floor
FOOT_W = 6
ARM_OUT = 13


def pose(ang, ankle_x):
    pelvis = P(NECK, ang, L["torso"])
    p = trunk(pelvis, ang + 180, head_ang=197)
    p["neck"] = list(NECK)
    for s, k in (("L", 1), ("R", -1)):
        p["ankle" + s] = [ankle_x, HEEL_Y, k * FOOT_W]
        p["knee" + s] = joint(p["hip" + s], p["ankle" + s], L["thigh"], L["shin"], [0, -1, 0])
        p["elbow" + s] = P(p["shoulder" + s], 2, L["upper"], k * ARM_OUT)
        p["hand" + s] = P(p["elbow" + s], 2, L["fore"], k * 4)
    return p


def feet(p, toe_ang):
    for s in "LR":
        p["toe" + s] = P(p["ankle" + s], toe_ang, L["foot"])
        p["toe" + s][2] = p["ankle" + s][2]


# start: body straight from the shoulders to the heels; end: knees bent, hips higher
s_ang = -20.5
sp = P(NECK, s_ang, L["torso"])
start_ankle_x = P(sp, s_ang, L["thigh"] + L["shin"] - 1)[0]
start = pose(s_ang, start_ankle_x)
end = pose(-31, start_ankle_x - 46)
feet(start, -70)                        # toes up, heels digging into the ball
feet(end, -20)                          # soles turning onto the ball as it rolls in
for k in ("neck", "head", "shoulderL", "shoulderR", "elbowL", "handL", "elbowR", "handR"):
    end[k] = list(start[k])
load = {"type": "pad", "at": "ankleL", "offset": [3, BALL_R + 5, -FOOT_W], "length": 2, "w": 2 * BALL_R}
write("stability-ball-leg-curl", start, end, [], load, tempo=2.8)
