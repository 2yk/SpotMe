"""Hanging knee-to-elbow twist: front view hang, both knees tuck up and across toward the left elbow."""
import os, sys, math
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rig import L, along, joint, trunk, write, line

BAR_Y = 26
HANDS = {"L": [60, BAR_Y, 0], "R": [140, BAR_Y, 0]}
LEFT = (-1, 0, 0)


def add(a, b, k=1):
    return [a[i] + b[i] * k for i in range(3)]


def arms(p, bend):
    for s, sx in (("L", -1), ("R", 1)):
        p["elbow" + s] = joint(p["shoulder" + s], HANDS[s], L["upper"], L["fore"], [sx, 0, bend])
        p["hand" + s] = list(HANDS[s])


def hang():
    p = trunk([100, 121.6, 0], -90, left=LEFT)
    arms(p, 0.35)
    for s, sx in (("L", -1), ("R", 1)):
        p["knee" + s] = along(p["hip" + s], [sx * 0.03, 1, 0.05], L["thigh"])
        p["ankle" + s] = along(p["knee" + s], [0, 0.7, -0.71], L["shin"])
        p["toe" + s] = along(p["ankle" + s], [0, 0.88, -0.46], L["foot"])
    return p


def tuck(twist):
    s0 = hang()
    p = {k: list(s0[k]) for k in ("neck", "head", "shoulderL", "shoulderR")}
    p["pelvis"] = along(p["neck"], [-0.16, 0.92, 0.36], L["torso"])        # pelvis curls up, forward, to the left
    t = math.radians(twist)
    left = [-math.cos(t), 0, -math.sin(t)]                               # hips turned toward the left
    front = [-math.sin(t), 0, math.cos(t)]
    p["hipL"], p["hipR"] = add(p["pelvis"], left, 9), add(p["pelvis"], left, -9)
    arms(p, 0.35)
    for s in ("L", "R"):
        thigh = add(add([0, -0.38, 0], front, 0.88), left, 0.3)          # knees up to the chest, across
        p["knee" + s] = along(p["hip" + s], thigh, L["thigh"])
        shin = add(add([0, 0.95, 0], front, -0.3), left, 0.05)             # shins fold back under
        p["ankle" + s] = along(p["knee" + s], shin, L["shin"])
        p["toe" + s] = along(p["ankle" + s], add([0, 0.6, 0], front, -0.8), L["foot"])
    return p


start, end = hang(), tuck(40)
props = [line([[38, BAR_Y, 0], [162, BAR_Y, 0]], 7)]
write("hanging-knee-to-elbow-twist", start, end, props, None, tempo=3.0, view="front", floor=193, yaw=35)
