"""Assisted pull-up machine (Gravitron): side view, kneeling on a pad that pushes up. Hands on two high handles,
knees bent, shins back on the pad; full hang to chin over the handles. The knee pad (volt, on its lever from the
machine) rises with the body: it is the assist. Opens turned a little so both handles show."""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rig import L, P, joint, trunk, mirror, line, slab, write

HANDS_Y, HX, HZ = 24, 104, 24
COL_X = 166
RISE = 40


def pose(pelvis, torso, head, bend):
    p = trunk(pelvis, torso, head_ang=head)
    hand = [HX, HANDS_Y, HZ]
    p["elbowL"] = joint(p["shoulderL"], hand, L["upper"], L["fore"], bend)
    p["handL"] = hand
    p["kneeL"] = P(p["hipL"], 84, L["thigh"])           # thighs down, a touch forward
    p["kneeL"][2] = 10
    p["ankleL"] = P(p["kneeL"], 172, L["shin"])         # shins back along the pad
    p["toeL"] = P(p["ankleL"], 125, L["foot"])
    return mirror(p)


start = pose([101, 124, 0], -90, -86, [0, 0, 1])                     # full hang
end = pose([108.5, 124 - RISE, 0], -100, -96, [-0.3, 1, 0.12])       # chin over the handles
mid_y = (start["kneeL"][1] + end["kneeL"][1]) / 2 + 7
PIVOT = [COL_X - 4, mid_y, 0]
pad = {"type": "pad", "at": ["kneeL", "kneeR"], "offset": [-9, 7, 0], "length": 36, "w": 10, "pivot": PIVOT}
props = [line([[COL_X, 181, 0], [COL_X, 12, 0], [122, 12, 0]], 6),            # column and top arm
         line([[122, 12, -HZ - 6], [122, 12, HZ + 6]], 6)]                     # cross bar
for z in (-HZ, HZ):
    props.append(line([[122, 12, z], [122, HANDS_Y, z], [94, HANDS_Y, z]], 5))  # handles
props.append(slab([[60, 181], [COL_X + 12, 181]], -26, 26, 4))                # base
write("assisted-pull-up-machine", start, end, props, pad, tempo=3.0, yaw=28)
