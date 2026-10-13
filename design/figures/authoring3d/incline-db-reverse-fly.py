"""Incline DB reverse fly: chest down on a 35 degree incline bench, toes on the floor, arms hanging straight down;
raise the dumbbells out wide to shoulder height, elbows soft, arms square to the torso. The sweep is in depth, so
it opens turned."""
import os, sys, math
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rig import L, P, along, joint, trunk, mirror, slab, line, write

PELVIS = [72, 103, 0]
INCLINE = 35                    # torso (and pad) angle from the floor, rising to the right
PAD = 10                        # pad surface below the body's centre line
HAND_Z = 19                     # start: arms hang just outside the pad
HAND_END = [-3, 6, 50]          # end: hand from the shoulder, out wide at shoulder height
KNEE_BEND = [1, 0.3, 0]


def pose(raised):
    p = trunk(PELVIS, -INCLINE, head_ang=-INCLINE + 5)
    p["ankleL"] = [60, 175, 11]
    p["toeL"] = [72.5, 179, 11]
    p["kneeL"] = joint(p["hipL"], p["ankleL"], L["thigh"], L["shin"], KNEE_BEND)
    sh = p["shoulderL"]
    if raised:
        hand = [sh[0] + HAND_END[0], sh[1] + HAND_END[1], sh[2] + HAND_END[2]]
        p["elbowL"] = joint(sh, hand, L["upper"], L["fore"], [0, 1, 0])
    else:
        dz = HAND_Z - sh[2]
        hand = [sh[0] - 1, sh[1] + math.sqrt(51 ** 2 - dz ** 2 - 1), HAND_Z]
        p["elbowL"] = joint(sh, hand, L["upper"], L["fore"], [0, 0, 1])
    p["handL"] = hand
    return mirror(p)


def stagger(p, dx):
    """Far foot set back dx along the floor so the two legs read apart from the side."""
    p["ankleR"][0] += dx
    p["toeR"][0] += dx
    p["kneeR"] = joint(p["hipR"], p["ankleR"], L["thigh"], L["shin"], KNEE_BEND)
    return p


start, end = stagger(pose(False), 4), stagger(pose(True), 4)
for k in ("ankleL", "toeL", "kneeL", "ankleR", "toeR", "kneeR"):
    end[k] = start[k]
a = math.radians(INCLINE)
n = [math.sin(a) * PAD, math.cos(a) * PAD]                          # from the torso line down to the pad
pad0 = [PELVIS[0] + n[0] + 6 * math.cos(a), PELVIS[1] + n[1] - 6 * math.sin(a)]
pad1 = [PELVIS[0] + n[0] + 44 * math.cos(a), PELVIS[1] + n[1] - 44 * math.sin(a)]
postx = (pad0[0] + pad1[0]) / 2
posty = (pad0[1] + pad1[1]) / 2 + 4
props = [slab([pad0, pad1], -12, 12, 8),                             # chest pad
         line([[postx, posty, 0], [postx, 181, 0]], 5),              # post
         slab([[postx - 22, 181], [postx + 22, 181]], -14, 14, 4)]   # base
load = {"type": "dumbbells", "axis": [1, 0, 0]}
write("incline-db-reverse-fly", start, end, props, load, tempo=2.6, yaw=-50)
