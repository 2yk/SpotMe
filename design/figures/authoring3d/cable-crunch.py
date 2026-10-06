"""Cable crunch: kneeling facing a high pulley, rope by the ears; the torso tips forward from fixed hips so the elbows travel toward the knees."""
import math
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rig import L, P, along, joint, trunk, mirror, slab, line, write

PELVIS = [84, 140, 0]
TORSO_START, TORSO_END = -84, -29
ANCHOR = [160, 19, 0]


def pose(a):
    p = trunk(PELVIS, a, head_ang=a + 12)
    p["kneeL"] = P(p["hipL"], 84, L["thigh"])
    p["ankleL"] = P(p["kneeL"], 180, L["shin"])
    p["toeL"] = P(p["ankleL"], 172, L["foot"])
    u = [math.cos(math.radians(a)), math.sin(math.radians(a)), 0]
    f = [math.cos(math.radians(a + 90)), math.sin(math.radians(a + 90)), 0]
    n = p["neck"]
    p["handL"] = [n[0] + 11 * u[0] + 7 * f[0], n[1] + 11 * u[1] + 7 * f[1], 12]
    p["elbowL"] = joint(p["shoulderL"], p["handL"], L["upper"], L["fore"], [f[i] - 0.5 * u[i] for i in range(3)])
    return mirror(p)


start, end = pose(TORSO_START), pose(TORSO_END)
for k in ("hipL", "hipR", "kneeL", "kneeR", "ankleL", "ankleR", "toeL", "toeR"):
    end[k] = start[k]
props = [line([[180, 181, 0], [180, 13, 0], [ANCHOR[0], 13, 0]], 6), line([[ANCHOR[0], 13, 0], ANCHOR], 8),
         slab([[170, 181], [190, 181]], -12, 12, 4)]
write("cable-crunch", start, end, props, {"type": "cable", "handle": "rope", "anchor": ANCHOR}, tempo=2.6)
