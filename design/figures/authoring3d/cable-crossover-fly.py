"""Cable crossover fly: standing between two pulleys set at shoulder height, split stance, leaning a little
forward. Elbows soft; the hands sweep from wide and a little behind the body forward and together in front of the
chest (a hug). Front view; the near-the-pulley version of low-to-high-cable-fly, with the pulleys high, not low."""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rig import L, P, along, joint, trunk, mirror, slab, line, write

PELVIS = [100, 101, 0]
LEAN = 12                             # torso tipped toward the viewer (forward)
ANCHOR = [14, 54, -52]                # pulley on the viewer's left, a little above shoulder height, well behind
HAND_START = [-46, 6, -6]             # from the shoulder: out to the side, a little behind
HAND_END = [11, 12, 41]                # from the shoulder: in front of the chest, hands nearly touching


def pose(h, bend, s=None):
    p = trunk(PELVIS, -90, out=LEAN, left=[-1, 0, 0])
    if s:
        for k in ("kneeL", "ankleL", "toeL", "kneeR", "ankleR", "toeR"):
            p[k] = s[k]
    else:
        # split stance: viewer's-left foot forward (toward the viewer), right foot back on its toes
        p["ankleL"] = [p["hipL"][0] - 3, 175, 20]
        p["toeL"] = along(p["ankleL"], [0, 0.3, 1], L["foot"])
        p["kneeL"] = joint(p["hipL"], p["ankleL"], L["thigh"], L["shin"], [0, -0.2, 1])
        p["ankleR"] = [p["hipR"][0] + 3, 170, -26]
        p["toeR"] = along(p["ankleR"], [0, 0.6, 0.8], L["foot"])
        p["kneeR"] = joint(p["hipR"], p["ankleR"], L["thigh"], L["shin"], [0, 0.3, 1])
    for side, k in (("L", 1), ("R", -1)):
        sh = p["shoulder" + side]
        hand = [sh[0] + k * h[0], sh[1] + h[1], sh[2] + h[2]]
        p["hand" + side] = hand
        p["elbow" + side] = joint(sh, hand, L["upper"], L["fore"], [-k * bend[0], bend[1], bend[2]])
    return p


start = pose(HAND_START, [0, 1, -0.2])
end = pose(HAND_END, [1, 0.8, 0], start)
props = []
for s in (1, -1):
    px = 100 + s * (ANCHOR[0] - 100)
    props.append(slab([[px - 6, 181], [px + 6, 181]], ANCHOR[2] - 7, ANCHOR[2] + 7, 4))
    props.append(line([[px, 181, ANCHOR[2]], [px, 22, ANCHOR[2]]], 9))
load = [{"type": "cable", "handle": "grip", "at": "handL", "anchor": ANCHOR},
        {"type": "cable", "handle": "grip", "at": "handR", "anchor": [200 - ANCHOR[0], ANCHOR[1], ANCHOR[2]]}]
write("cable-crossover-fly", start, end, props, load, tempo=2.8, view="front", yaw=0)
