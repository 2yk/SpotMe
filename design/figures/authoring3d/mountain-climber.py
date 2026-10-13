"""Mountain climber: high plank on straight arms, hips level. The knees drive to the chest one at a time: the
near knee comes in while the far leg is back, then they switch (one rep shows both legs)."""
import math, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rig import L, P, along, joint, trunk, mirror, slab, line, write

GROUND = 177.5
HAND_X = 152
FOOT = 55
BODY = L["torso"] + L["thigh"] + L["shin"]
sh_y = GROUND - L["upper"] - L["fore"] + 1
NECK = [HAND_X, sh_y, 0]
ANKLE_Y = GROUND - L["foot"] * math.sin(math.radians(FOOT))
TILT = math.degrees(math.asin((ANKLE_Y - sh_y) / BODY))
PELVIS = P(NECK, 180 - TILT, L["torso"])
PELVIS[1] -= 3                        # hips a touch high, level through the rep


def leg_back(p, s):
    hip = p["hip" + s]
    end = P(hip, 180 - TILT, L["thigh"] + L["shin"])
    ankle = [end[0], ANKLE_Y, hip[2] * 0.8]
    p["ankle" + s] = ankle
    p["knee" + s] = joint(hip, ankle, L["thigh"], L["shin"], [0, -1, 0])
    p["toe" + s] = P(ankle, FOOT, L["foot"])


def leg_in(p, s):
    hip = p["hip" + s]
    p["knee" + s] = P(hip, 15, L["thigh"])                    # knee forward under the chest
    p["ankle" + s] = P(p["knee" + s], 165, L["shin"])         # shin back, foot just off the floor
    p["toe" + s] = P(p["ankle" + s], 70, L["foot"])


def pose(near_in):
    p = trunk(PELVIS, math.degrees(math.atan2(NECK[1] - PELVIS[1], NECK[0] - PELVIS[0])), head_ang=-TILT + 10)
    p["neck"], p["shoulderL"], p["shoulderR"] = NECK, [NECK[0], NECK[1], 15], [NECK[0], NECK[1], -15]
    for s, k in (("L", 1), ("R", -1)):
        sh = p["shoulder" + s]
        p["hand" + s] = [sh[0], GROUND, sh[2] * 1.1]
        p["elbow" + s] = joint(sh, p["hand" + s], L["upper"], L["fore"], [-1, 0, 0])
    (leg_in if near_in else leg_back)(p, "L")
    (leg_back if near_in else leg_in)(p, "R")
    return p


start, end = pose(True), pose(False)
write("mountain-climber", start, end, [], None, tempo=2.4, yaw=-20)
