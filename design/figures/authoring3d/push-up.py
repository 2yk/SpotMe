"""Push-up: hands on the floor under the shoulders, a little wider; body one straight line from heels to head,
pivoting on the toes. From arms straight down to the chest a fist from the floor, elbows about 45 degrees out."""
import math, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rig import L, P, along, joint, trunk, mirror, slab, line, write

GROUND = 177.5                       # y of a limb point resting on the floor
TOE = [44, GROUND]                   # toes stay put; the body pivots on them
FOOT = 55                            # ankle -> toe, toes tucked
HAND_Z = 19                          # hands a little wider than the shoulders
BODY = L["torso"] + L["thigh"] + L["shin"]
ANKLE = [TOE[0] - L["foot"] * math.cos(math.radians(FOOT)), GROUND - L["foot"] * math.sin(math.radians(FOOT))]


def neck_at(neck_y):
    """Neck on the straight body line from the ankle, at this height."""
    return [ANKLE[0] + math.sqrt(BODY ** 2 - (ANKLE[1] - neck_y) ** 2), neck_y, 0]


TOP = neck_at(GROUND - 51)
HAND_X = TOP[0] - 1


def pose(neck_y):
    neck = neck_at(neck_y)
    tilt = math.degrees(math.atan2(ANKLE[1] - neck[1], neck[0] - ANKLE[0]))
    pelvis = P(neck, 180 - tilt, L["torso"])
    p = trunk(pelvis, -tilt, head_ang=-tilt + 8)
    for s, k in (("L", 1), ("R", -1)):
        hip = p["hip" + s]
        p["knee" + s] = P(hip, 180 - tilt, L["thigh"])
        p["ankle" + s] = P(p["knee" + s], 180 - tilt, L["shin"])
        p["toe" + s] = P(p["ankle" + s], FOOT, L["foot"])
        hand = [HAND_X, GROUND, HAND_Z * k]
        p["hand" + s] = hand
        p["elbow" + s] = joint(p["shoulder" + s], hand, L["upper"], L["fore"], [-1, -0.6, 1.1 * k])
    return p


start, end = pose(GROUND - 51), pose(GROUND - 17)
write("push-up", start, end, [], None, tempo=2.6)
