"""Half-kneeling Pallof press: side-on to a pulley at chest height, the knee nearer the cable down under the hip,
the other foot flat in front; both hands on one handle press straight out from the sternum and back."""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rig import L, P, along, joint, trunk, mirror, slab, line, write

PELVIS = [100, 139, 0]                 # hip over the down knee
HAND_Y = 110
Z_START, Z_END = 14, 46
ANCHOR = [180, HAND_Y, 12]


def pose(z, bend):
    p = trunk(PELVIS, -90, left=[-1, 0, 0])
    # L (viewer's left, away from the cable): front leg, foot flat ahead, shin vertical
    p["kneeL"] = [p["hipL"][0] - 2, 141, 38]
    p["ankleL"] = [p["hipL"][0] - 2, 176, 40]
    p["toeL"] = along(p["ankleL"], [0, 0.25, 1], L["foot"])
    # R (cable side): knee down under the hip, shin back along the floor
    p["kneeR"] = [p["hipR"][0] + 2, 176, -4]
    p["ankleR"] = [p["hipR"][0] + 2, 177, -40]
    p["toeR"] = along(p["ankleR"], [0, 0.35, -1], L["foot"])
    for s, k in (("L", 1), ("R", -1)):
        p["hand" + s] = [PELVIS[0] - k * 2, HAND_Y, z]
        p["elbow" + s] = joint(p["shoulder" + s], p["hand" + s], L["upper"], L["fore"], [-k, 1, 0])
    return p


start, end = pose(Z_START, None), pose(Z_END, None)
props = [line([[187, 181, ANCHOR[2]], [187, 30, ANCHOR[2]]], 6),
         line([[187, HAND_Y - 8, ANCHOR[2]], [ANCHOR[0], HAND_Y - 8, ANCHOR[2]], ANCHOR], 8),
         slab([[178, 181], [192, 181]], 0, 24, 4)]
write("half-kneeling-pallof-press", start, end, props,
      {"type": "cable", "handle": "grip", "at": "handL", "anchor": ANCHOR}, tempo=2.6, view="front", yaw=52)
