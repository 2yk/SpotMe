"""Bird dog plank: high plank on straight arms; the near arm lifts forward and the far (opposite) leg lifts
back off the floor to about level with the body."""
import math, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rig import L, P, along, joint, trunk, mirror, slab, line, write

GROUND = 177.5
HAND_X = 160
FOOT = 55                            # ankle -> toe, toes tucked


def pose(reach):
    sh_y = GROUND - L["upper"] - L["fore"]
    neck = [HAND_X, sh_y, 0]
    ankle_y = GROUND - L["foot"] * math.sin(math.radians(FOOT))
    tilt = math.degrees(math.asin((ankle_y - sh_y) / (L["torso"] + L["thigh"] + L["shin"])))
    pelvis = P(neck, 180 - tilt, L["torso"])
    p = trunk(pelvis, -tilt, head_ang=-tilt + 6)
    for s in "LR":
        sh, hip = p["shoulder" + s], p["hip" + s]
        p["hand" + s] = [sh[0], GROUND, sh[2] * 0.9]
        p["elbow" + s] = along(sh, [0, 1, -sh[2] * 0.1 / 27], L["upper"])
        p["knee" + s] = P(hip, 180 - tilt, L["thigh"])
        p["ankle" + s] = P(p["knee" + s], 180 - tilt, L["shin"])
        p["toe" + s] = P(p["ankle" + s], FOOT, L["foot"])
    if reach:
        p["elbowL"] = P(p["shoulderL"], -4, L["upper"])
        p["handL"] = P(p["elbowL"], -4, L["fore"])
        p["kneeR"] = P(p["hipR"], 181, L["thigh"])
        p["ankleR"] = P(p["kneeR"], 181, L["shin"])
        p["toeR"] = P(p["ankleR"], 95, L["foot"])
    return p


start, end = pose(False), pose(True)
write("bird-dog-plank", start, end, [], None, tempo=3)
