"""Arnold press: seated on a bench with an upright back rest. Start: dumbbells in front of the chin, palms facing
you, elbows forward and close together under the hands. The elbows open out to the sides as the dumbbells press
overhead (palms turned forward at the top). The elbows sweeping out is what tells it from a plain seated press."""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rig import L, P, joint, trunk, mirror, slab, line, write

PELVIS = [80, 138, 0]
HAND_START = [21, -3, -8]        # start: hand from the shoulder, in front of the chin, close to the midline
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
        hand = [sh[i] + HAND_START[i] for i in range(3)]
        p["elbowL"] = joint(sh, hand, L["upper"], L["fore"], [0.4, 1, 0])   # elbow forward and down, in front
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
write("arnold-press", start, end, props, load, tempo=3.0, yaw=35)
