"""L-sit: side view, supported on two parallel bars, arms straight, legs held straight out in front, level. A hold."""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rig import L, P, along, trunk, mirror, line, write

RAIL_Y, RAIL_Z = 110, 22
HAND = [72, RAIL_Y - 4, RAIL_Z]
RAIL_HALF = 14                         # short rails: legs hover beyond their ends


def pose(lift):
    shoulder_y = HAND[1] - (52 ** 2 - 7 ** 2 - 9 ** 2) ** 0.5        # arms straight down to the rail
    neck = [HAND[0] + 9, shoulder_y, 0]
    pelvis = P(neck, 100, L["torso"])
    p = trunk(pelvis, -80, head_ang=-86)
    p["neck"] = neck
    p["handL"] = list(HAND)
    p["elbowL"] = along(p["shoulderL"], [HAND[i] - p["shoulderL"][i] for i in range(3)], L["upper"])
    p["kneeL"] = P(p["hipL"], -3, L["thigh"])                           # legs a touch above level
    p["kneeL"][2] = 5
    p["ankleL"] = P(p["kneeL"], -3, L["shin"])
    p["ankleL"][2] = 4
    p["toeL"] = P(p["ankleL"], -18, L["foot"])
    mirror(p)
    p["pelvis"][1] -= lift                                              # breathing: the pelvis only
    return p


start, end = pose(0), pose(2)
props = []
for z in (-RAIL_Z, RAIL_Z):
    props.append(line([[HAND[0] - RAIL_HALF, RAIL_Y, z], [HAND[0] + RAIL_HALF, RAIL_Y, z]], 6))
    props.append(line([[HAND[0], RAIL_Y, z], [HAND[0], 181, z]], 5))
    props.append(line([[HAND[0] - 10, 181, z], [HAND[0] + 10, 181, z]], 5))     # foot of the post
write("l-sit", start, end, props, None, tempo=4, hold=True, yaw=30)
