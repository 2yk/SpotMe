"""Pistol squat: side view, standing on the near (L) leg with the far leg held straight out in front, arms
reaching forward for balance; sit all the way down on one leg, heel flat, the free leg level just off the
floor and under the working knee, then stand."""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rig import L, P, along, joint, trunk, mirror, slab, line, write

ANKLE = [96, 176, 9]


def pose(shin, thigh, torso, free, arm):
    knee = P(ANKLE, shin, L["shin"])
    hip = P(knee, thigh, L["thigh"])
    p = trunk([hip[0], hip[1], 0], torso, head_ang=-72 if torso > -80 else torso)
    p["hipL"] = [hip[0], hip[1], 9]
    p["ankleL"], p["kneeL"] = list(ANKLE), [knee[0], knee[1], 9]
    p["toeL"] = [ANKLE[0] + 13, 179, 9]
    p["kneeR"] = P(p["hipR"], free, L["thigh"], -4)          # free leg straight out in front
    p["ankleR"] = P(p["kneeR"], free, L["shin"], -4)
    p["toeR"] = P(p["ankleR"], free - 85, L["foot"])         # toes up
    for s, z in (("L", 1), ("R", -1)):
        p["elbow" + s] = P(p["shoulder" + s], arm, L["upper"], z * -6)
        p["hand" + s] = P(p["elbow" + s], arm, L["fore"], z * -4)
    return p


start = pose(-92, -88, -88, 48, 8)       # standing on one leg, free leg a little forward, arms forward
end = pose(-52, 194, -46, 2, 14)         # bottom: hips by the heel, free leg level
for k in ("ankleL", "toeL"):
    end[k] = start[k]
write("pistol-squat", start, end, [], None, tempo=3.2)
