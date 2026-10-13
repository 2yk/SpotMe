"""Lying leg raise: flat on the back, hands under the hips, legs straight; the legs lower until the heels hover
just above the floor and rise back to vertical. Start is the lowered position."""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rig import L, P, joint, trunk, write

PELVIS = [112, 176, 0]
LEG_LOW, LEG_UP = -9, -88


def pose(leg):
    p = trunk(PELVIS, 180, head_ang=197)
    for s, k in (("L", 1), ("R", -1)):
        hand = [PELVIS[0] - 6, 180, k * 6]                    # palms flat under the glutes
        p["hand" + s] = hand
        p["elbow" + s] = joint(p["shoulder" + s], hand, L["upper"], L["fore"], [0, -0.4, k])
        p["knee" + s] = P(p["hip" + s], leg, L["thigh"], -k * 3)
        p["ankle" + s] = P(p["knee" + s], leg, L["shin"], -k * 3)
        p["toe" + s] = P(p["ankle" + s], leg - 68, L["foot"])
    return p


start, end = pose(LEG_LOW), pose(LEG_UP)
write("lying-leg-raise", start, end, (), {"type": "none"}, tempo=3.0, yaw=20)
