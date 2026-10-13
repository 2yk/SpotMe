"""Incline machine press: seated, back on a pad reclined about 25 degrees, feet on the floor; the handles start
at the upper chest and press up and forward (up and in) to arms nearly straight, slow on the way back. Grips
only, no levers: on an incline any lever pivot behind the head draws its lever straight across the face from the
side, so the machine is told by its reclined pad, frame and upright handles."""
import os, sys, math
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rig import L, P, joint, trunk, mirror, slab, line, write

PELVIS = [84, 138, 0]
TORSO = -115                          # reclined: pelvis -> neck up and back
GRIP_Z_START, GRIP_Z_END = 23, 17     # hands come a little in as they press
FRAME_X, FRAME_Z, FRAME_TOP = 34, 30, 40


def pose(hand_from_shoulder, gz):
    p = trunk(PELVIS, TORSO, head_ang=-102)
    p["ankleL"] = [124, 175, 11]
    p["toeL"] = [137, 175, 11]
    p["kneeL"] = joint(p["hipL"], p["ankleL"], L["thigh"], L["shin"], [1, -1, 0])
    sh = p["shoulderL"]
    hand = [sh[0] + hand_from_shoulder[0], sh[1] + hand_from_shoulder[1], gz]
    p["elbowL"] = joint(sh, hand, L["upper"], L["fore"], [-0.6, 0.8, 0.8])
    p["handL"] = hand
    return mirror(p)


start = pose([16, 6], GRIP_Z_START)                # handles at the upper chest, elbows down and back
end = pose([37, -27], GRIP_Z_END)                  # pressed up and forward, arms nearly straight
nk, pel = start["neck"], start["pelvis"]
t = [(nk[0] - pel[0]) / 50, (nk[1] - pel[1]) / 50]  # along the back
n = [t[1], -t[0]] if t[1] < 0 else [-t[1], t[0]]
if n[0] > 0:
    n = [-n[0], -n[1]]                              # behind the back
pb = [pel[0] + n[0] * 9 + t[0] * 4, pel[1] + n[1] * 9 + t[1] * 4]
pt = [pb[0] + t[0] * 62, pb[1] + t[1] * 62]
props = [slab([[62, 147], [108, 147]], -16, 16, 7),          # seat
         slab([pb, pt], -14, 14, 9),                          # reclined back pad
         line([[86, 150, 0], [86, 181, 0]], 5),               # seat post
         line([[(pb[0] + pt[0]) / 2, (pb[1] + pt[1]) / 2, 0], [FRAME_X, (pb[1] + pt[1]) / 2, 0]], 4),  # pad bracket
         slab([[FRAME_X - 8, 181], [128, 181]], -30, 30, 4)]  # base
for z in (-FRAME_Z, FRAME_Z):                                 # an upright each side behind the pad
    props.append(line([[FRAME_X, 181, z], [FRAME_X, FRAME_TOP, z]], 5))
props.append(line([[FRAME_X, FRAME_TOP, -FRAME_Z], [FRAME_X, FRAME_TOP, FRAME_Z]], 5))  # cross bar on top
load = {"type": "machine", "grips": ["handL", "handR"], "axis": [0, 1, 0], "length": 14}
write("incline-machine-press", start, end, props, load, tempo=2.8)
