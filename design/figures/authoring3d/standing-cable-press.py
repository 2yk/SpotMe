"""Standing cable chest press: standing a step in front of two pulleys at chest height, facing away from them,
split stance, leaning a little forward. A D-handle in each hand presses from beside the chest (elbows back)
forward and together to arms nearly straight, then returns. Side view, turned a little so both cables show."""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rig import L, P, along, joint, trunk, mirror, slab, line, write

PELVIS = [86, 103, 0]
TORSO = -82                           # tipped a little forward
COL_X, COL_Z = 30, 40                 # the two columns behind the body, either side
ANCHOR_Y = 76                         # pulleys at chest height
HAND_Y = 76


def pose(hx, hz, bend, s=None):
    p = trunk(PELVIS, TORSO, head_ang=-86)
    if s:
        for k in ("kneeL", "ankleL", "toeL", "kneeR", "ankleR", "toeR"):
            p[k] = s[k]
    else:
        p["ankleL"] = [108, 175, 9]                     # near foot forward
        p["toeL"] = P(p["ankleL"], 3, L["foot"])
        p["kneeL"] = joint(p["hipL"], p["ankleL"], L["thigh"], L["shin"], [1, -0.3, 0])
        p["ankleR"] = [60, 168, -9]                     # far foot back, heel up
        p["toeR"] = P(p["ankleR"], 40, L["foot"])
        p["kneeR"] = joint(p["hipR"], p["ankleR"], L["thigh"], L["shin"], [1, 0, 0])
    for s_, k in (("L", 1), ("R", -1)):
        hand = [hx, HAND_Y, hz * k]
        p["hand" + s_] = hand
        p["elbow" + s_] = joint(p["shoulder" + s_], hand, L["upper"], L["fore"], [bend[0], bend[1], bend[2] * k])
    return p


neck_x = trunk(PELVIS, TORSO)["neck"][0]
start = pose(neck_x + 10, 24, [-1, 0.3, 0.6])          # handles beside the chest, elbows back
end = pose(neck_x + 47, 7, [0, 0.6, 1], start)         # pressed forward and together
anchors = [[COL_X + 4, ANCHOR_Y, COL_Z], [COL_X + 4, ANCHOR_Y, -COL_Z]]
props = []
for z in (COL_Z, -COL_Z):
    props.append(line([[COL_X, 181, z], [COL_X, 20, z]], 9))
    props.append(slab([[COL_X - 7, 181], [COL_X + 7, 181]], z - 7, z + 7, 4))
props.append(line([[COL_X, 20, COL_Z], [COL_X, 20, -COL_Z]], 6))  # top bar joining the columns
load = [{"type": "cable", "handle": "grip", "at": "handL", "anchor": anchors[0]},
        {"type": "cable", "handle": "grip", "at": "handR", "anchor": anchors[1]}]
write("standing-cable-press", start, end, props, load, tempo=2.6, yaw=-25)
