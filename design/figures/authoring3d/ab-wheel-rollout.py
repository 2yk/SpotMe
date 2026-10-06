"""Ab wheel rollout: kneeling, both hands on a wheel on the floor. From hips over the knees with the wheel in
front of the knees, roll out until the body is long and low, arms ahead; knees stay on the floor."""
import math, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rig import L, P, along, joint, trunk, mirror, slab, line, write

GROUND = 177.5
KNEE = [46, GROUND, 9]
WHEEL_Y = 182 - 9                    # axle height: wheel radius 9 on the floor
HAND_Z = 7


def pose(thigh, torso, head):
    pelvis = P([KNEE[0], KNEE[1], 0], thigh, L["thigh"])
    p = trunk(pelvis, torso, head_ang=head)
    for s, k in (("L", 1), ("R", -1)):
        p["knee" + s] = [KNEE[0], KNEE[1], 9 * k]
        p["ankle" + s] = P(p["knee" + s], 186, L["shin"])
        p["toe" + s] = P(p["ankle" + s], 120, L["foot"])
    sh = p["shoulderL"]
    dy = WHEEL_Y - sh[1]
    reach = L["upper"] + L["fore"] - 1.5
    dx = math.sqrt(max(0, reach ** 2 - dy ** 2 - (sh[2] - HAND_Z) ** 2))
    for s, k in (("L", 1), ("R", -1)):
        hand = [sh[0] + dx, WHEEL_Y, HAND_Z * k]
        p["hand" + s] = hand
        p["elbow" + s] = joint(p["shoulder" + s], hand, L["upper"], L["fore"], [0, -1, 0.3 * k])
    return p


start, end = pose(-86, -24, -6), pose(-34, -13, -24)
for k in ("kneeL", "kneeR", "ankleL", "ankleR", "toeL", "toeR"):
    end[k] = start[k]
load = {"type": "held", "kind": "wheel", "at": "hands"}
write("ab-wheel-rollout", start, end, [], load, tempo=3.2)
