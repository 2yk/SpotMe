"""Single-arm DB overhead extension: seated tall against an upright back rest, one dumbbell in the near hand;
the elbow points up beside the head and the forearm lowers behind the head, then extends. The free hand
rests on the thigh."""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rig import L, P, joint, trunk, slab, line, write

PELVIS = [80, 138, 0]
TORSO = -93
UPPER, UPPER_OUT = -80, -8      # upper arm straight up beside the head
FORE_START, FORE_END = 140, -84
HAND_Z_START, HAND_Z_END = 3, 11  # lowers behind the head, toward the middle


def pose(fore, hz):
    p = trunk(PELVIS, TORSO, head_ang=-88)
    for s, z in (("L", 13), ("R", -13)):
        p["ankle" + s] = [114, 175, z]
        p["toe" + s] = [127, 175, z]
        p["knee" + s] = joint(p["hip" + s], p["ankle" + s], L["thigh"], L["shin"], [1, -1, 0])
    p["elbowL"] = P(p["shoulderL"], UPPER, L["upper"], UPPER_OUT)
    el = p["elbowL"]
    dz = hz - el[2]
    flat = (L["fore"] ** 2 - dz ** 2) ** 0.5
    p["handL"] = P([el[0], el[1], hz], fore, flat)
    thigh = [p["hipR"][i] * 0.3 + p["kneeR"][i] * 0.7 for i in range(3)]
    p["handR"] = [thigh[0], thigh[1] - 6, thigh[2] - 2]           # free hand on the thigh
    p["elbowR"] = joint(p["shoulderR"], p["handR"], L["upper"], L["fore"], [-0.3, 0, -1])
    return p


start, end = pose(FORE_START, HAND_Z_START), pose(FORE_END, HAND_Z_END)
for k in ("elbowR", "handR"):
    end[k] = start[k]
props = [slab([[60, 147], [104, 147]], -14, 14, 7),
         slab([[70, 140], [70, 92]], -13, 13, 7)]
for x in (64, 100):
    for z in (-10, 10):
        props.append(line([[x, 150, z], [x, 181, z]], 5))
props.append(line([[70, 144, 0], [64, 150, 0]], 4))
# One dumbbell in one hand (the dumbbells load puts one in each): a handle front to back with a wheel disc at each
# end, as suitcase-carry builds it.
load = [{"type": "machine", "grips": ["handL"], "axis": [1, 0, 0], "length": 18},
        {"type": "held", "kind": "wheel", "at": "handL", "offset": [9, 0, 0], "axis": [1, 0, 0]},
        {"type": "held", "kind": "wheel", "at": "handL", "offset": [-9, 0, 0], "axis": [1, 0, 0]}]
write("single-arm-db-overhead-extension", start, end, props, load, tempo=2.8)
