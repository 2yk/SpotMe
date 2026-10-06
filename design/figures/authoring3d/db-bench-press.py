"""DB bench press: lying on a flat bench, feet on the floor; dumbbells from beside the chest (elbows out about
45 degrees, a little below the bench top) to arms straight above the chest. Dumbbells lie across the body."""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rig import L, P, joint, trunk, mirror, slab, line, write

PELVIS = [114, 137, 0]          # body centre line 9 above the bench top (146)
BENCH_TOP = 146
ELBOW_SPLAY = 45                # start: upper arm 45 degrees from the torso, toward the hips
ELBOW_DROP = 13                 # start: elbow this far below the shoulder (bench top is 9 below)
HAND_TOP = [2, -51, -3]         # end: hand from the shoulder, arm nearly straight above the chest


def legs(p):
    p["ankleL"] = [146, 175, 16]
    p["toeL"] = [158.4, 179, 16]
    p["kneeL"] = joint(p["hipL"], p["ankleL"], L["thigh"], L["shin"], [1, -1, 0])
KNEE_BEND = [1, -1, 0]


def pose(top):
    p = trunk(PELVIS, 180, head_ang=180)
    legs(p)
    sh = p["shoulderL"]
    if top:
        hand = [sh[i] + HAND_TOP[i] for i in range(3)]
        p["elbowL"] = joint(sh, hand, L["upper"], L["fore"], [0, 0, 1])
    else:
        import math
        h = math.sqrt(L["upper"] ** 2 - ELBOW_DROP ** 2)
        a = math.radians(ELBOW_SPLAY)
        p["elbowL"] = [sh[0] + h * math.sin(a), sh[1] + ELBOW_DROP, sh[2] + h * math.cos(a)]
        hand = P(p["elbowL"], -90, L["fore"], -12)      # forearm up, tipped a little in
    p["handL"] = hand
    return mirror(p)


def stagger(p, dx):
    """Far foot set back dx along the floor so the two legs read apart from the side."""
    p["ankleR"][0] += dx
    p["toeR"][0] += dx
    p["kneeR"] = joint(p["hipR"], p["ankleR"], L["thigh"], L["shin"], KNEE_BEND)
    return p


start, end = stagger(pose(False), -6), stagger(pose(True), -6)
for k in ("ankleL", "toeL", "kneeL", "ankleR", "toeR", "kneeR"):
    end[k] = start[k]
props = [slab([[36, BENCH_TOP], [122, BENCH_TOP]], -12, 12, 7)]
for x in (44, 114):                                          # four legs
    for z in (-9, 9):
        props.append(line([[x, 149, z], [x, 181, z]], 5))
load = {"type": "dumbbells", "axis": [0, 0, 1]}
write("db-bench-press", start, end, props, load, tempo=2.6, yaw=-30)
