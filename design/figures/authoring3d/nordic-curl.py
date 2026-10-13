"""Nordic curl: kneeling on a mat, heels hooked under a fixed pad behind; knees, hips and shoulders in one straight
line that leans forward from upright, lowered under control about the knees. Hands come forward, ready to catch."""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rig import L, P, along, joint, trunk, mirror, slab, line, write

KNEE = [76, 175, 7]
ANKLE = [KNEE[0] - 36, 175, 7]


def pose(ang, arm):
    """ang: knee -> hip -> shoulder line (-90 upright). arm: upper-arm angle off that line."""
    pelvis = P([KNEE[0], KNEE[1], 0], ang, L["thigh"])
    p = trunk(pelvis, ang, head_ang=ang + 8)
    p["kneeL"], p["ankleL"] = list(KNEE), list(ANKLE)
    p["toeL"] = P(ANKLE, 168, L["foot"])
    p["toeL"][2] = ANKLE[2]
    p["elbowL"] = P(p["shoulderL"], ang + arm, L["upper"], 10)
    p["handL"] = P(p["elbowL"], ang + arm - 80, L["fore"], 6)
    p = mirror(p)
    return p


start = pose(-88, 150)             # upright, hands in front of the chest
end = pose(-36, 105)               # leaning far forward, arms reaching down toward the floor
for k in ("kneeL", "ankleL", "toeL", "kneeR", "ankleR", "toeR"):
    end[k] = list(start[k])
props = [slab([[30, 180], [96, 180]], -16, 16, 4),                        # mat
         line([[ANKLE[0] + 1, 164, -17], [ANKLE[0] + 1, 164, 17]], 12),   # heel roller over the ankles
         line([[ANKLE[0] - 12, 181, -17], [ANKLE[0] - 1, 164, -17]], 6),  # its frame either side
         line([[ANKLE[0] - 12, 181, 17], [ANKLE[0] - 1, 164, 17]], 6),
         line([[ANKLE[0] - 12, 181, -17], [ANKLE[0] - 12, 181, 17]], 6)]
write("nordic-curl", start, end, props, {"type": "none"}, tempo=3.2)
