"""Tibialis raise: standing with the back and hips leaning on a wall, legs straight, heels about a foot out from the
wall; the toes lift high off the floor (heels stay down), then lower slowly. Arms hang relaxed at the sides."""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rig import L, P, joint, trunk, mirror, slab, line, write

WALL_X = 64
ANKLE = [99, 174, 9]
LEG = -104                   # ankle -> hip: leaning back to the wall


def pose(foot_ang):
    hip = P(ANKLE, LEG, L["shin"] + L["thigh"] - 0.3)
    pel = [hip[0], hip[1], 0]
    p = trunk(pel, -92, head_ang=-88)
    p["ankleL"] = list(ANKLE)
    p["kneeL"] = joint(p["hipL"], ANKLE, L["thigh"], L["shin"], [1, 0, 0])
    p["toeL"] = P(ANKLE, foot_ang, L["foot"])
    p["toeL"][2] = ANKLE[2] + 1
    p["elbowL"] = P(p["shoulderL"], 93, L["upper"], 10)
    p["handL"] = P(p["elbowL"], 85, L["fore"], 6)
    return mirror(p)


start, end = pose(19), pose(-42)          # foot flat (toe on the floor), then toes pulled up high
props = [slab([[WALL_X, 181], [WALL_X, 22]], -26, 26, 7)]
write("tibialis-raise", start, end, props, {"type": "none"}, tempo=2.6)
