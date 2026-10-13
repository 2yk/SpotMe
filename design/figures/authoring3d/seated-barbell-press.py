"""Seated barbell press: seated on an upright bench, back on the pad, feet on the floor; a barbell from the front
of the collarbone (elbows forward, under the bar) pressed to arms straight over the head. The head tips back a
little at the bottom so the bar clears the face, and comes through at the top."""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rig import L, P, joint, trunk, mirror, slab, line, write

PELVIS = [80, 138, 0]
GRIP = 25                       # hands a bit wider than the shoulders
BOTTOM = [14, 1]                # bottom: bar from the neck, just in front of the collarbone
TOP = [4, -49]                  # top: hand from the shoulder, over the head, arms nearly straight
HEAD_BACK = -110                # bottom: head tipped back so the bar clears the chin


def pose(top):
    p = trunk(PELVIS, -90, head_ang=-90 if top else HEAD_BACK)
    p["ankleL"] = [114, 175, 13]
    p["toeL"] = [127, 175, 13]
    p["kneeL"] = joint(p["hipL"], p["ankleL"], L["thigh"], L["shin"], [1, -1, 0])
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
props = [slab([[60, 147], [104, 147]], -14, 14, 7),          # seat
         slab([[70, 140], [70, 80]], -13, 13, 7)]            # upright back rest
for x in (64, 100):                                          # four legs
    for z in (-10, 10):
        props.append(line([[x, 150, z], [x, 181, z]], 5))
props.append(line([[70, 144, 0], [64, 150, 0]], 4))         # back rest strut
load = {"type": "bar", "length": 92, "plate": 14}
write("seated-barbell-press", start, end, props, load, tempo=2.6, yaw=40)
