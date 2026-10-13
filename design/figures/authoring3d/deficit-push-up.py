"""Deficit push-up: hands on hex dumbbells lying on the floor (handles along the body), wrists straight; body one
straight line pivoting on the toes. The chest lowers past the hands for a deep stretch, then presses up."""
import math, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rig import L, P, along, joint, trunk, mirror, slab, line, write

GROUND = 177.5
HAND_Y = 173                         # grip on a dumbbell handle: heads 13 tall resting on the floor
TOE = [40, GROUND]
FOOT = 55
HAND_Z = 21                          # handles a little wider than the shoulders
BODY = L["torso"] + L["thigh"] + L["shin"]
ANKLE = [TOE[0] - L["foot"] * math.cos(math.radians(FOOT)), GROUND - L["foot"] * math.sin(math.radians(FOOT))]


def neck_at(neck_y):
    return [ANKLE[0] + math.sqrt(BODY ** 2 - (ANKLE[1] - neck_y) ** 2), neck_y, 0]


HAND_X = neck_at(HAND_Y - 51)[0] - 4         # hands under the lower chest


def pose(neck_y):
    neck = neck_at(neck_y)
    tilt = math.degrees(math.atan2(ANKLE[1] - neck[1], neck[0] - ANKLE[0]))
    pelvis = P(neck, 180 - tilt, L["torso"])
    p = trunk(pelvis, -tilt, head_ang=-tilt + 8)
    for s, k in (("L", 1), ("R", -1)):
        p["knee" + s] = P(p["hip" + s], 180 - tilt, L["thigh"])
        p["ankle" + s] = P(p["knee" + s], 180 - tilt, L["shin"])
        p["toe" + s] = P(p["ankle" + s], FOOT, L["foot"])
        hand = [HAND_X, HAND_Y, HAND_Z * k]
        p["hand" + s] = hand
        p["elbow" + s] = joint(p["shoulder" + s], hand, L["upper"], L["fore"], [-0.7, -0.35, 1.4 * k])
    return p


start, end = pose(HAND_Y - 51), pose(HAND_Y - 9)
for k in ("ankleL", "toeL", "ankleR", "toeR", "handL", "handR"):
    end[k] = start[k]
write("deficit-push-up", start, end, [], {"type": "dumbbells", "axis": [1, 0, 0]}, tempo=2.8)
