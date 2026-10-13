"""Cable woodchop (high to low): standing square to the camera, feet wide, a high pulley out to one side. Both
hands on one handle start up toward the pulley with the chest turned to it; the arms stay long and pull the
handle across and down to the far hip while the chest and hips turn with it."""
import math, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rig import L, P, along, joint, trunk, mirror, slab, line, write

PELVIS = [100, 106, 0]
ANCHOR = [178, 22, -4]
FEET = 17                              # ankles either side of the middle
HIGH = 40                              # start: handle this far from the neck toward the pulley
LOW = [-0.6, 0.72, 0.35], 44           # end: from the neck down, across and forward: by the far hip
TURN_START, TURN_END = 60, -60         # chest turn (toward +x is positive)


def rot(v, t):                          # turn a vector about the vertical axis; +t brings +z toward +x
    c, s = math.cos(math.radians(t)), math.sin(math.radians(t))
    return [v[0] * c + v[2] * s, v[1], -v[0] * s + v[2] * c]


def pose(turn, mid):
    p = trunk(PELVIS, -90, left=[-1, 0, 0])
    neck = p["neck"]
    lf = rot([-1, 0, 0], turn)
    p["shoulderL"] = along(neck, lf, 15)
    p["shoulderR"] = along(neck, lf, -15)
    hl = rot([-1, 0, 0], turn * 0.4)           # hips turn less than the chest
    p["hipL"] = along(p["pelvis"], hl, 9)
    p["hipR"] = along(p["pelvis"], hl, -9)
    if mid is None:                             # high: on the line from the neck to the pulley
        mid = along(neck, [ANCHOR[i] - neck[i] for i in range(3)], HIGH)
    else:
        mid = along(neck, mid[0], mid[1])
    # handle across the cable line: hands 4 apart
    d = [ANCHOR[i] - mid[i] for i in range(3)]
    side = [-d[1], d[0], 0]
    m = math.hypot(side[0], side[1])
    side = [side[0] / m, side[1] / m, 0]
    for s, k in (("L", 1), ("R", -1)):
        hand = [mid[i] + side[i] * 2.5 * k for i in range(3)]
        p["hand" + s] = hand
        p["elbow" + s] = joint(p["shoulder" + s], hand, L["upper"], L["fore"], [0, 1, 0.6])
    for s, k in (("L", -1), ("R", 1)):
        p["ankle" + s] = [PELVIS[0] + k * FEET, 175, 0]
        p["toe" + s] = along(p["ankle" + s], [k * 0.3, 0.3, 1], L["foot"])
        p["knee" + s] = joint(p["hip" + s], p["ankle" + s], L["thigh"], L["shin"], [0, 0, 1])
    return p


start, end = pose(TURN_START, None), pose(TURN_END, LOW)
for k in ("pelvis", "neck", "head", "ankleL", "toeL", "ankleR", "toeR"):
    end[k] = list(start[k])
props = [line([[186, 181, ANCHOR[2]], [186, 14, ANCHOR[2]], [ANCHOR[0], 14, ANCHOR[2]]], 6),
         line([[ANCHOR[0], 14, ANCHOR[2]], ANCHOR], 8), slab([[176, 181], [192, 181]], -16, 8, 4)]
write("cable-woodchop", start, end, props, {"type": "cable", "handle": "grip", "at": "handL", "anchor": ANCHOR},
      tempo=2.8, view="front", yaw=20)
