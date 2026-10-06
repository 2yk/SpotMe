"""Dead bug: on the back, arms up, hips and knees at 90 (shins level); the left arm lowers overhead while the
right leg straightens out low above the floor, the other arm and leg stay up."""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rig import L, P, trunk, write

PELVIS = [112, 176, 0]
ARM_UP, ARM_OVER = -90, 197          # arm angle: straight up, then overhead just above the floor
LEG_LOW = -14                         # straight leg, low above the floor
FOOT_UP = -50                         # toe angle in tabletop


def arm(p, s, ang):
    p["elbow" + s] = P(p["shoulder" + s], ang, L["upper"])
    p["hand" + s] = P(p["elbow" + s], ang, L["fore"])


def leg(p, s, z, straight):
    hip = p["hip" + s]
    if straight:
        p["knee" + s] = P(hip, LEG_LOW, L["thigh"])
        p["ankle" + s] = P(p["knee" + s], LEG_LOW, L["shin"])
        p["toe" + s] = P(p["ankle" + s], -80, L["foot"])
    else:
        p["knee" + s] = P(hip, -90, L["thigh"])
        p["ankle" + s] = P(p["knee" + s], 0, L["shin"])
        p["toe" + s] = P(p["ankle" + s], FOOT_UP, L["foot"])


def pose(reach):
    p = trunk(PELVIS, 180, head_ang=197)
    arm(p, "L", ARM_OVER if reach else ARM_UP)
    arm(p, "R", ARM_UP)
    leg(p, "L", 9, False)
    leg(p, "R", -9, reach)
    return p


start, end = pose(False), pose(True)
write("dead-bug", start, end, (), {"type": "none"}, tempo=3.2, yaw=35)
