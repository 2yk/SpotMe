"""Single-arm cable row: seated upright on a bench facing a pulley at chest height; the near arm reaches forward
with a single handle, then pulls the elbow back to the hip. The other hand rests on its thigh."""
import os, sys, math
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rig import L, P, along, joint, trunk, mirror, slab, line, write

PELVIS = [66, 140, 0]
REACH = [124, 100, 11]                 # hand stretched toward the pulley
PULL = [72, 113, 14]                   # hand at the side of the waist, elbow back past the hip
_t = (166 - PULL[0]) / (REACH[0] - PULL[0])
ANCHOR = [PULL[i] + (REACH[i] - PULL[i]) * _t for i in range(3)]   # on the line the hand travels


def pose(hand, lean, s=None):
    p = trunk(PELVIS, lean, head_ang=-90)
    if s:
        for k in ("kneeL", "ankleL", "toeL", "kneeR", "ankleR", "toeR", "hipL", "hipR"):
            p[k] = s[k]
    else:
        for side, z in (("L", 11), ("R", -11)):
            p["ankle" + side] = [104, 175, z]
            p["toe" + side] = P(p["ankle" + side], 5, L["foot"])
            p["knee" + side] = joint(p["hip" + side], p["ankle" + side], L["thigh"], L["shin"], [1, -1, 0])
    p["handL"] = list(hand)
    p["elbowL"] = joint(p["shoulderL"], p["handL"], L["upper"], L["fore"], [-1, 0.6, 0.2])
    thigh = [(p["hipR"][i] * 0.35 + p["kneeR"][i] * 0.65) for i in range(3)]
    p["handR"] = [thigh[0], thigh[1] - 6, thigh[2] - 1]
    p["elbowR"] = joint(p["shoulderR"], p["handR"], L["upper"], L["fore"], [-0.5, 0, -1])
    return p


start = pose(REACH, -80)             # leaning a touch forward into the reach
end = pose(PULL, -91, start)
props = [slab([[44, 148], [94, 148]], -12, 12, 7),                 # bench top
         line([[50, 151, 0], [50, 181, 0]], 5), line([[88, 151, 0], [88, 181, 0]], 5),
         line([[176, 181, 0], [176, 20, 0]], 6),                     # cable column
         line([[176, ANCHOR[1], 0], [ANCHOR[0], ANCHOR[1], ANCHOR[2]]], 5),   # pulley arm
         line([[ANCHOR[0], ANCHOR[1] - 3, ANCHOR[2]], [ANCHOR[0], ANCHOR[1] + 3, ANCHOR[2]]], 8),
         slab([[164, 181], [188, 181]], -14, 14, 4)]
write("single-arm-cable-row", start, end, props,
      {"type": "cable", "handle": "grip", "at": "handL", "anchor": ANCHOR}, tempo=2.6)
