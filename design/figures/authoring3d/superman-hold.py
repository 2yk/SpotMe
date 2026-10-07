"""Superman hold: face down, arms out ahead in a narrow Y, legs straight; lift arms, chest and legs off the
floor (start flat, end lifted)."""
import math, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rig import L, P, along, joint, trunk, mirror, slab, line, write

FLOOR_Y = 177.5
PELVIS = [96, 176, 0]                # pelvis rests on the floor
ARM_OUT = 26                         # arms open this many degrees out to the side (keeps the reach in the box)
LEG_OUT = 7


def pose(lift):
    chest = -19 * lift                 # torso angle: 0 flat, negative = chest up
    leg = 179.5 + 14.5 * lift          # legs back and up
    arm = 1.5 - 23.5 * lift           # arms on the floor, then up past the head
    p = trunk(PELVIS, chest, head_ang=chest - 16)
    for s, k in (("L", 1), ("R", -1)):
        p["elbow" + s] = P(p["shoulder" + s], arm, L["upper"], out=k * ARM_OUT)
        p["hand" + s] = P(p["elbow" + s], arm, L["fore"], out=k * ARM_OUT)
        p["knee" + s] = P(p["hip" + s], leg, L["thigh"], out=k * LEG_OUT)
        p["ankle" + s] = P(p["knee" + s], leg, L["shin"], out=k * LEG_OUT)
        p["toe" + s] = P(p["ankle" + s], 165 + 10 * lift, L["foot"])
    return p


start, end = pose(0), pose(1)
for k in ("pelvis", "hipL", "hipR"):
    end[k] = start[k]
write("superman-hold", start, end, [], None, tempo=3)
