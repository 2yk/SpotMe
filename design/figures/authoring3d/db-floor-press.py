"""DB floor press: lying on a mat on the floor, knees bent and feet flat; dumbbells from the bottom (upper arms
resting on the floor about 45 degrees from the body, forearms vertical) to arms straight above the chest.
Lying on the floor with the knees up tells it apart from the DB bench press."""
import os, sys, math
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rig import L, P, joint, trunk, mirror, slab, line, write

PELVIS = [112, 174, 0]          # body centre line 8 above the floor
FLOOR = 182
ELBOW_SPLAY = 45                # bottom: upper arm 45 degrees from the torso, toward the hips
ELBOW_DROP = 3                  # bottom: elbow this far below the shoulder (resting on the floor)
HAND_TOP = [2, -50, -3]         # top: hand from the shoulder, arm nearly straight above the chest
ANKLE = [146, 175, 13]
KNEE_BEND = [0.2, -1, 0]


def pose(top):
    p = trunk(PELVIS, 180, head_ang=194)
    p["ankleL"] = list(ANKLE)
    p["toeL"] = [ANKLE[0] + 12.4, 179, ANKLE[2]]
    p["kneeL"] = joint(p["hipL"], p["ankleL"], L["thigh"], L["shin"], KNEE_BEND)
    sh = p["shoulderL"]
    if top:
        hand = [sh[i] + HAND_TOP[i] for i in range(3)]
        p["elbowL"] = joint(sh, hand, L["upper"], L["fore"], [0, 0, 1])
    else:
        h = math.sqrt(L["upper"] ** 2 - ELBOW_DROP ** 2)
        a = math.radians(ELBOW_SPLAY)
        p["elbowL"] = [sh[0] + h * math.sin(a), sh[1] + ELBOW_DROP, sh[2] + h * math.cos(a)]
        hand = P(p["elbowL"], -90, L["fore"], -10)       # forearm up, tipped a little in
    p["handL"] = hand
    return mirror(p)


def stagger(p, dx):
    """Far foot set back dx along the floor so the two legs read apart from the side."""
    p["ankleR"][0] += dx
    p["toeR"][0] += dx
    p["kneeR"] = joint(p["hipR"], p["ankleR"], L["thigh"], L["shin"], KNEE_BEND)
    return p


start, end = stagger(pose(False), -5), stagger(pose(True), -5)
for k in ("ankleL", "toeL", "kneeL", "ankleR", "toeR", "kneeR"):
    end[k] = start[k]
props = [slab([[30, 180.5], [166, 180.5]], -22, 22, 3)]        # mat on the floor
load = {"type": "dumbbells", "axis": [0, 0, 1]}
write("db-floor-press", start, end, props, load, tempo=2.6, yaw=-30)
