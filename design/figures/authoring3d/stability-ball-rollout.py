"""Stability ball rollout: kneeling, forearms on top of a stability ball in front, hands together. From hips
bent with the ball close, roll the ball forward until the body is long from knees to shoulders and the arms
reach ahead; knees stay on the floor.
The renderer has no stability ball: it is a `pad` with almost no length and a width of the ball's diameter,
which draws a filled volt circle (round from every side) that rolls with the forearms."""
import math, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rig import L, P, along, joint, trunk, write

GROUND = 177.5
BALL_R = 23
FOREARM_Y = 182 - 2 * BALL_R - 5     # forearm line resting on top of the ball
KNEE = [46, GROUND, 9]
ELBOW_Z, HAND_Z = 9, 3


def pose(thigh, torso, head):
    pelvis = P([KNEE[0], KNEE[1], 0], thigh, L["thigh"])
    p = trunk(pelvis, torso, head_ang=head)
    for s, k in (("L", 1), ("R", -1)):
        p["knee" + s] = [KNEE[0], KNEE[1], 9 * k]
        p["ankle" + s] = P(p["knee" + s], 186, L["shin"])
        p["toe" + s] = P(p["ankle" + s], 120, L["foot"])
        sh = p["shoulder" + s]
        dy, dz = FOREARM_Y - sh[1], ELBOW_Z * k - sh[2]
        elbow = [sh[0] + math.sqrt(L["upper"] ** 2 - dy ** 2 - dz ** 2), FOREARM_Y, ELBOW_Z * k]
        dz2 = HAND_Z * k - elbow[2]
        p["elbow" + s] = elbow
        p["hand" + s] = [elbow[0] + math.sqrt(L["fore"] ** 2 - dz2 ** 2), FOREARM_Y, HAND_Z * k]
    return p


start, end = pose(-80, -40, -30), pose(-40, -21, -42)
for k in ("kneeL", "kneeR", "ankleL", "ankleR", "toeL", "toeR"):
    end[k] = start[k]
load = {"type": "pad", "at": ["elbowL", "elbowR", "handL", "handR"], "offset": [0, BALL_R + 5, 0],
        "length": 0.5, "w": 2 * BALL_R}
write("stability-ball-rollout", start, end, [], load, tempo=3.2)
