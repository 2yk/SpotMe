"""Stability ball back extension: hips on a ball, legs straight back, toes on the floor braced against a wall,
hands by the ears; round down over the ball, then lift to one straight line. The ball is a grey prop: a
zero-length line as wide as the ball (round caps draw a filled circle that faces the viewer from every side)."""
import os, sys, math
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rig import L, P, along, joint, trunk, mirror, slab, line, write

BALL = [104, 152, 0]
BALL_R = 27
PELVIS = [96, BALL[1] - BALL_R - 7, 0]       # hips resting on top of the ball
LEG = 147                                    # legs back and down to the wall
TORSO_START, TORSO_END = 34, -30             # chest draped over the ball, then in line with the legs
WALL_X = 24


def pose(t):
    p = trunk(PELVIS, t, head_ang=t + (14 if t > 0 else 4))
    for s, z in (("L", 1), ("R", -1)):
        p["knee" + s] = P(p["hip" + s], LEG, L["thigh"], -z * 4)
        p["ankle" + s] = P(p["knee" + s], LEG, L["shin"], -z * 4)
        p["toe" + s] = along(p["ankle" + s], [-0.45, 1, 0], L["foot"])
        # hands lightly by the ears, elbows out to the sides
        tr = math.radians(t)
        back = [math.cos(tr - math.pi / 2), math.sin(tr - math.pi / 2)]   # the back side (body face down)
        hd = p["head"]
        hand = [hd[0] + back[0] * 2 - math.cos(tr) * 3, hd[1] + back[1] * 2 - math.sin(tr) * 3, z * 11]
        p["hand" + s] = hand
        p["elbow" + s] = joint(p["shoulder" + s], hand, L["upper"], L["fore"], [back[0] * 0.3, back[1] * 0.3, z])
    return p


start, end = pose(TORSO_START), pose(TORSO_END)
for k in ("pelvis", "hipL", "hipR", "kneeL", "kneeR", "ankleL", "ankleR", "toeL", "toeR"):
    end[k] = start[k]
props = [line([[BALL[0], BALL[1], 0], [BALL[0], BALL[1] + 0.01, 0]], 2 * BALL_R),     # the ball
         slab([[WALL_X, 181], [WALL_X, 110]], -12, 12, 6)]                          # wall
write("stability-ball-back-extension", start, end, props, None, tempo=3.0)
