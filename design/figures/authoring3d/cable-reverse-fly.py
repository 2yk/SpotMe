"""Cable reverse fly: standing between two pulleys set at shoulder height, cables crossed (the left hand holds the
right cable); arms from crossed in front of the chest sweep back out wide into a T, elbows soft. Front view."""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rig import L, P, along, joint, trunk, mirror, slab, line, write

PELVIS = [100, 101, 0]
HAND_START = [11, 4, 44]        # from the neck: L hand crossed past the middle, in front of the chest
HAND_END = [-63, 4, 4]          # from the neck: out wide in a T, a touch in front of the body
ANCHOR = [180, 0, 30]           # pulley on the viewer's right (y set from the neck), a little in front
CROSS_DZ = 5                    # the R arm crosses under the L one


def pose(h, bend, dz):
    p = trunk(PELVIS, -90, left=[-1, 0, 0])
    p["ankleL"] = [p["hipL"][0] - 2, 175, -2]
    p["toeL"] = along(p["ankleL"], [0, 0.3, 1], L["foot"])
    p["kneeL"] = joint(p["hipL"], p["ankleL"], L["thigh"], L["shin"], [0, 0, 1])
    n = p["neck"]
    p["handL"] = [n[0] + h[0], n[1] + h[1], n[2] + h[2]]
    p["elbowL"] = joint(p["shoulderL"], p["handL"], L["upper"], L["fore"], bend)
    for k in [k for k in p if k.endswith("L")]:
        x, y, z = p[k]
        p[k[:-1] + "R"] = [2 * PELVIS[0] - x, y, z]
    for k in ("handR", "elbowR"):
        p[k][2] -= dz if k == "handR" else dz / 2
    p["elbowR"] = joint(p["shoulderR"], p["handR"], L["upper"], L["fore"], [bend[0] * -1, bend[1], bend[2]])
    return p


start = pose(HAND_START, [-1, 0.5, 0], CROSS_DZ)
end = pose(HAND_END, [0, 0.5, -1], 0)
for k in ("ankleL", "toeL", "kneeL", "ankleR", "toeR", "kneeR"):
    end[k] = start[k]
AY = start["neck"][1] - 12                  # pulleys a little above the shoulders: the cables angle down to the hands
anc_r, anc_l = [ANCHOR[0], AY, ANCHOR[2]], [200 - ANCHOR[0], AY, ANCHOR[2]]
props = []
for px in (anc_l[0], anc_r[0]):
    props.append(slab([[px - 6, 181], [px + 6, 181]], ANCHOR[2] - 7, ANCHOR[2] + 7, 4))
    props.append(line([[px, 181, ANCHOR[2]], [px, 20, ANCHOR[2]]], 6))
    props.append(line([[px, AY, ANCHOR[2]], [px + (4 if px < 100 else -4), AY, ANCHOR[2]]], 8))   # pulley
load = [{"type": "cable", "handle": "grip", "at": "handL", "anchor": anc_r},
        {"type": "cable", "handle": "grip", "at": "handR", "anchor": anc_l}]
write("cable-reverse-fly", start, end, props, load, tempo=2.6, view="front", yaw=-25)
