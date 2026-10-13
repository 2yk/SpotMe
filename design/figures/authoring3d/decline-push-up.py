"""Decline push-up: toes up on a flat bench, hands on the floor under the shoulders; body one straight line,
pivoting on the toes. From arms straight down until the head nearly reaches the floor (upper-chest bias)."""
import math, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rig import L, P, along, joint, trunk, mirror, slab, line, write

GROUND = 177.5                       # y of a hand resting on the floor
BENCH_TOP = 142                      # bench top surface (line centre; stroke 7)
TOE = [38, BENCH_TOP - 8]            # toes resting on the bench top
FOOT = 40                            # ankle -> toe, toes tucked on the bench
HAND_Z = 19
BODY = L["torso"] + L["thigh"] + L["shin"]
ANKLE = [TOE[0] - L["foot"] * math.cos(math.radians(FOOT)), TOE[1] - L["foot"] * math.sin(math.radians(FOOT))]


def neck_at(neck_y):
    return [ANKLE[0] + math.sqrt(BODY ** 2 - (ANKLE[1] - neck_y) ** 2), neck_y, 0]


HAND_X = neck_at(GROUND - 51)[0] + 1


def pose(neck_y):
    neck = neck_at(neck_y)
    tilt = math.degrees(math.atan2(ANKLE[1] - neck[1], neck[0] - ANKLE[0]))
    pelvis = P(neck, 180 - tilt, L["torso"])
    p = trunk(pelvis, -tilt, head_ang=-tilt + 14)
    for s, k in (("L", 1), ("R", -1)):
        p["knee" + s] = P(p["hip" + s], 180 - tilt, L["thigh"])
        p["ankle" + s] = P(p["knee" + s], 180 - tilt, L["shin"])
        p["toe" + s] = P(p["ankle" + s], FOOT, L["foot"])
        hand = [HAND_X, GROUND, HAND_Z * k]
        p["hand" + s] = hand
        p["elbow" + s] = joint(p["shoulder" + s], hand, L["upper"], L["fore"], [-1, -0.6, 1.1 * k])
    return p


start, end = pose(GROUND - 51), pose(GROUND - 20)
for k in ("ankleL", "toeL", "ankleR", "toeR", "handL", "handR"):
    end[k] = start[k]
props = [slab([[8, BENCH_TOP], [60, BENCH_TOP]], -12, 12, 7)]           # flat bench, feet end
for x in (14, 54):
    for z in (-9, 9):
        props.append(line([[x, BENCH_TOP + 3, z], [x, 181, z]], 5))
write("decline-push-up", start, end, props, None, tempo=2.6)
