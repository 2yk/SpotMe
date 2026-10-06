"""Bird dog: on all fours (hands under shoulders, knees under hips, back flat). The near arm reaches straight
forward and the far (opposite) leg straight back, both level with the torso."""
import math, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rig import L, P, along, joint, trunk, mirror, slab, line, write

GROUND = 177.5
KNEE_X = 62


def pose(reach):
    pelvis = [KNEE_X, GROUND - L["thigh"], 0]
    sh_y = GROUND - L["upper"] - L["fore"]
    dx = math.sqrt(L["torso"] ** 2 - (pelvis[1] - sh_y) ** 2)
    ang = -math.degrees(math.atan2(pelvis[1] - sh_y, dx))
    p = trunk(pelvis, ang, head_ang=ang + 8)
    for s, z in (("L", 1), ("R", -1)):
        sh, hip = p["shoulder" + s], p["hip" + s]
        p["elbow" + s] = [sh[0], sh[1] + L["upper"], sh[2]]
        p["hand" + s] = [sh[0], GROUND, sh[2]]
        p["knee" + s] = [hip[0], GROUND, hip[2]]
        p["ankle" + s] = P(p["knee" + s], 180, L["shin"])
        p["toe" + s] = P(p["ankle" + s], 180, L["foot"])
        p["ankle" + s][1] -= 1
    if reach:
        lev = ang * 0.45                                 # level: halfway between the back line and horizontal
        p["elbowL"] = P(p["shoulderL"], lev, L["upper"])
        p["handL"] = P(p["elbowL"], lev, L["fore"])
        p["kneeR"] = P(p["hipR"], 181, L["thigh"])
        p["ankleR"] = P(p["kneeR"], 181, L["shin"])
        p["toeR"] = P(p["ankleR"], 100, L["foot"])
    return p


start, end = pose(False), pose(True)
write("bird-dog", start, end, [], None, tempo=3)
