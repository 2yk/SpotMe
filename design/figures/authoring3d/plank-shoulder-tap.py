"""Plank shoulder tap: high plank on straight arms, feet wide. The near hand lifts and taps the far shoulder while
the hips stay still, then goes back to the floor. The tap crosses the body, so it opens turned a little toward the head."""
import math, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rig import L, P, along, joint, trunk, mirror, slab, line, write

GROUND = 177.5
HAND_X = 150
FOOT = 55
FEET_Z = 19                           # feet wide for balance
BODY = L["torso"] + L["thigh"] + L["shin"]


def pose(tap):
    sh_y = GROUND - L["upper"] - L["fore"] + 1
    neck = [HAND_X, sh_y, 0]
    ankle_y = GROUND - L["foot"] * math.sin(math.radians(FOOT))
    tilt = math.degrees(math.asin((ankle_y - sh_y) / BODY))
    pelvis = P(neck, 180 - tilt, L["torso"])
    p = trunk(pelvis, -tilt, head_ang=-tilt + 10)
    for s, k in (("L", 1), ("R", -1)):
        hip = p["hip" + s]
        foot_end = P(hip, 180 - tilt, L["thigh"] + L["shin"])
        ankle = [foot_end[0], foot_end[1], FEET_Z * k]
        p["ankle" + s] = ankle
        p["knee" + s] = joint(hip, ankle, L["thigh"], L["shin"], [0, -1, 0])
        p["toe" + s] = P(ankle, FOOT, L["foot"])
        sh = p["shoulder" + s]
        p["hand" + s] = [sh[0], GROUND, sh[2] * 1.1]
        p["elbow" + s] = joint(sh, p["hand" + s], L["upper"], L["fore"], [-1, 0, 0])
    if tap:
        sr = p["shoulderR"]
        p["handL"] = [sr[0] + 3, sr[1] - 7, sr[2] + 6]          # fingers on top of the far shoulder
        p["elbowL"] = joint(p["shoulderL"], p["handL"], L["upper"], L["fore"], [0.2, 1, 0.8])
    return p


start, end = pose(False), pose(True)
write("plank-shoulder-tap", start, end, [], None, tempo=2.4, yaw=20)
