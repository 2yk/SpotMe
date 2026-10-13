"""Wall sit: side view, back flat on a wall, thighs level, shins vertical, hands resting on the thighs. A hold:
only the pelvis moves 2 units."""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rig import L, P, along, joint, trunk, mirror, slab, line, write

WALL_X = 58
PELVIS = [WALL_X + 11, 140, 0]


def pose(dy):
    p = trunk(PELVIS, -90, head_ang=-88)
    p["kneeL"] = P(p["hipL"], 0, L["thigh"])
    p["ankleL"] = P(p["kneeL"], 90, L["shin"])
    p["toeL"] = P(p["ankleL"], 0, L["foot"])
    p["handL"] = [p["pelvis"][0] + 24, p["pelvis"][1] - 6, 14]
    p["elbowL"] = joint(p["shoulderL"], p["handL"], L["upper"], L["fore"], [-0.4, 0, 1])
    p = mirror(p)
    p["pelvis"] = [PELVIS[0], PELVIS[1] - dy, 0]
    return p


start, end = pose(0), pose(2)
for k in end:
    if k != "pelvis":
        end[k] = start[k]
props = [slab([[WALL_X, 22], [WALL_X, 181]], -34, 34, 6)]
write("wall-sit", start, end, props, None, tempo=4, hold=True)
