"""EZ-bar overhead extension (French press): seated tall against an upright back rest, a narrow grip on an EZ
bar; elbows up, forward and in, the bar from behind the head to overhead."""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rig import L, P, joint, trunk, mirror, slab, line, write

PELVIS = [80, 138, 0]
TORSO = -93
UPPER, UPPER_OUT = -74, -10     # upper arms up and forward, elbows in
FORE_START, FORE_END = 146, -80
HAND_Z = 8                      # narrow grip on the EZ bar


def pose(fore):
    p = trunk(PELVIS, TORSO, head_ang=-88)
    p["ankleL"] = [114, 175, 13]
    p["toeL"] = [127, 175, 13]
    p["kneeL"] = joint(p["hipL"], p["ankleL"], L["thigh"], L["shin"], [1, -1, 0])
    p["elbowL"] = P(p["shoulderL"], UPPER, L["upper"], UPPER_OUT)
    el = p["elbowL"]
    dz = HAND_Z - el[2]
    flat = (L["fore"] ** 2 - dz ** 2) ** 0.5
    p["handL"] = P([el[0], el[1], HAND_Z], fore, flat)
    return mirror(p)


start, end = pose(FORE_START), pose(FORE_END)
props = [slab([[60, 147], [104, 147]], -14, 14, 7),          # seat
         slab([[70, 140], [70, 92]], -13, 13, 7)]            # upright back rest, top below the shoulders
for x in (64, 100):
    for z in (-10, 10):
        props.append(line([[x, 150, z], [x, 181, z]], 5))
props.append(line([[70, 144, 0], [64, 150, 0]], 4))
load = {"type": "bar", "length": 56, "plate": 8}
write("ez-bar-overhead-extension", start, end, props, load, tempo=2.8, yaw=40)
