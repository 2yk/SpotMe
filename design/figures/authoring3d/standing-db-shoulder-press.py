"""Standing DB shoulder press: standing tall, feet hip-width, no bench. Dumbbells from ear level (elbows out to the
sides, under the hands) to overhead, arms nearly straight, a little closer together at the top."""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rig import L, P, along, joint, trunk, mirror, slab, line, write

PELVIS = [100, 103, 0]
ELBOW_START = [6, 4, 25.9]      # start: elbow from the shoulder, out to the side, a touch below and forward
HAND_TOP = [10, -49, 6]          # end: hand from the shoulder, overhead, nearly straight, closer in


def pose(top):
    p = trunk(PELVIS, -90)
    p["hipL"] = [PELVIS[0], PELVIS[1], 9]
    p["kneeL"] = P(p["hipL"], 88, L["thigh"], 3)
    p["ankleL"] = P(p["kneeL"], 92, L["shin"], 3)
    p["ankleL"][1] = 175
    p["toeL"] = P(p["ankleL"], 0, L["foot"])
    sh = p["shoulderL"]
    if top:
        hand = [sh[i] + HAND_TOP[i] for i in range(3)]
        p["elbowL"] = joint(sh, hand, L["upper"], L["fore"], [0, 0, 1])
    else:
        el = [sh[i] + ELBOW_START[i] for i in range(3)]
        p["elbowL"] = joint(sh, el, L["upper"], 0.001, [0, 0, 1])
        hand = P(p["elbowL"], -90, L["fore"])
    p["handL"] = hand
    return mirror(p)


start, end = pose(False), pose(True)
write("standing-db-shoulder-press", start, end, [], {"type": "dumbbells", "axis": [0, 0, 1]}, tempo=2.6, yaw=40)
