"""Seated DB shoulder press: seated on a bench with an upright back rest. Dumbbells from ear level (elbows out
to the sides, under the hands) to overhead, arms nearly straight, a little closer together at the top."""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rig import L, P, joint, trunk, mirror, slab, line, write

PELVIS = [80, 138, 0]
ELBOW_START = [6, 4, 25.9]      # start: elbow from the shoulder, out to the side, a touch below and forward
HAND_TOP = [10, -49, 6]          # end: hand from the shoulder, overhead, nearly straight, closer in


def pose(top):
    p = trunk(PELVIS, -90)
    p["ankleL"] = [114, 175, 14]
    p["toeL"] = [127, 175, 14]
    p["kneeL"] = joint(p["hipL"], p["ankleL"], L["thigh"], L["shin"], [1, -1, 0])
    sh = p["shoulderL"]
    if top:
        hand = [sh[i] + HAND_TOP[i] for i in range(3)]
        p["elbowL"] = joint(sh, hand, L["upper"], L["fore"], [0, 0, 1])
    else:
        el = [sh[i] + ELBOW_START[i] for i in range(3)]
        p["elbowL"] = joint(sh, el, L["upper"], 0.001, [0, 0, 1])   # true-length upper arm toward el
        hand = P(p["elbowL"], -90, L["fore"])                         # forearm straight up, hand over elbow
    p["handL"] = hand
    return mirror(p)


start, end = pose(False), pose(True)
props = [slab([[60, 147], [104, 147]], -14, 14, 7),          # seat
         slab([[70, 140], [70, 80]], -13, 13, 7)]            # upright back rest
for x in (64, 100):                                          # four legs
    for z in (-10, 10):
        props.append(line([[x, 150, z], [x, 181, z]], 5))
props.append(line([[70, 144, 0], [64, 150, 0]], 4))         # back rest strut
load = {"type": "dumbbells", "axis": [0, 0, 1]}
write("seated-db-shoulder-press", start, end, props, load, tempo=2.6, yaw=50)
