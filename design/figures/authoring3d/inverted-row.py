"""Inverted row: hanging under a Smith or rack bar, body straight from the heels on the floor, arms straight up to
the bar; pull the chest to the bar, the body pivoting at the heels."""
import os, sys, math
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rig import L, P, along, joint, trunk, mirror, slab, line, write

ANKLE = [34, 172, 0]              # heels on the floor (toes up)
BODY_START, BODY_END = -17, -33   # body line angle from the floor, rising toward the head (right)
HAND_Z = 21                       # a bit wider than the shoulders


def body_point(ang, dist_):
    a = math.radians(ang)
    return [ANKLE[0] + math.cos(a) * dist_, ANKLE[1] + math.sin(a) * dist_]


def bar_from(ang):
    """Bar centre: straight arms from the shoulders, perpendicular to the body."""
    n = body_point(ang, 74 + 50)
    a = math.radians(ang - 90)
    reach = math.sqrt(50.5 ** 2 - (HAND_Z - 15) ** 2)
    return [n[0] + math.cos(a) * reach, n[1] + math.sin(a) * reach]


BAR = bar_from(BODY_START)


def pose(ang):
    pelvis = body_point(ang, 74) + [0]
    p = trunk(pelvis, ang, head_ang=ang - 12)
    for s, z in (("L", 9), ("R", -9)):
        k = body_point(ang, 36)
        p["ankle" + s] = [ANKLE[0], ANKLE[1], z * 0.8]
        p["knee" + s] = [k[0], k[1], z * 0.9]
        p["toe" + s] = P(p["ankle" + s], -95, L["foot"])
        sz = 1 if s == "L" else -1
        p["hand" + s] = [BAR[0], BAR[1], sz * HAND_Z]
        p["elbow" + s] = joint(p["shoulder" + s], p["hand" + s], L["upper"], L["fore"], [-0.2, 1, sz * 0.6])
    return p


start, end = pose(BODY_START), pose(BODY_END)
for k in ("ankleL", "ankleR", "toeL", "toeR"):
    end[k] = start[k]
props = [line([[BAR[0], BAR[1], -38], [BAR[0], BAR[1], 38]], 6)]          # the bar, across
UP = 186                                                                      # rack uprights past the head
for z in (-38, 38):
    props.append(line([[UP, 181, z], [UP, 40, z]], 5))
    props.append(line([[BAR[0] - 4, BAR[1] + 4, z], [UP, BAR[1] + 4, z]], 4))   # safety arm under the bar end
props.append(slab([[UP - 8, 181], [UP + 4, 181]], -40, 40, 4))
write("inverted-row", start, end, props, None, tempo=2.6, yaw=-20)
