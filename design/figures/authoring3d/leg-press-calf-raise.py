"""Leg press calf raise: 45 deg leg press, legs almost straight with soft knees that stay still; the balls of the
feet on the bottom edge of the plate, heels below it. Only the ankles move: toes from pulled back (full stretch)
to pointed, pushing the plate a short way along its rail."""
import os, sys, math
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rig import L, P, along, joint, trunk, mirror, slab, line, write

PELVIS = [80, 152, 0]
TORSO = -142
RAIL = -45
FOOT_LINE = -40
DIST = 70                               # hip to ankle: legs nearly straight
FZ = 12
FOOT_START, FOOT_END = RAIL - 90 - 28, RAIL - 90 + 42    # ankle -> ball of foot: stretched, then pointed


def pose(foot, s=None):
    p = trunk(PELVIS, TORSO, head_ang=-125)
    if s:
        for k in ("elbowL", "handL", "kneeL", "ankleL"):
            p[k] = s[k]
    else:
        p["handL"] = [PELVIS[0] - 4, PELVIS[1] - 6, 22]
        p["elbowL"] = joint(p["shoulderL"], p["handL"], L["upper"], L["fore"], [0.3, 1, 0.6])
        a = P(PELVIS, FOOT_LINE, DIST)
        p["ankleL"] = [a[0], a[1], FZ]
        p["kneeL"] = joint(p["hipL"], p["ankleL"], L["thigh"], L["shin"], [-0.6, -1, 0])
    p["toeL"] = P(p["ankleL"], foot, L["foot"])
    return mirror(p)


start = pose(FOOT_START)
end = pose(FOOT_END, start)
ru = [math.cos(math.radians(RAIL)), math.sin(math.radians(RAIL))]
fu = [math.cos(math.radians(RAIL - 90)), math.sin(math.radians(RAIL - 90))]
# The plate's face runs through the balls of the feet; its bottom edge sits just under them, so the heels hang
# below it. The platform follows the toes.
PLEN = 34
OFF = [fu[0] * (PLEN / 2 - 3) + ru[0] * 4, fu[1] * (PLEN / 2 - 3) + ru[1] * 4, 0]
load = {"type": "platform", "at": ["toeL", "toeR"], "offset": OFF, "angle": RAIL + 90, "length": PLEN, "width": 38}
tu = [math.cos(math.radians(TORSO)), math.sin(math.radians(TORSO))]
nu = [-tu[1], tu[0]] if -tu[1] < 0 else [tu[1], -tu[0]]
pad0 = [PELVIS[0] + nu[0] * 9 - tu[0] * 2, PELVIS[1] + nu[1] * 9 - tu[1] * 2]
pad1 = [pad0[0] + tu[0] * 56, pad0[1] + tu[1] * 56]
c0 = [start["toeL"][0] + ru[0] * 8 + fu[0] * 14, start["toeL"][1] + ru[1] * 8 + fu[1] * 14]
r0 = [c0[0] - ru[0] * 58, c0[1] - ru[1] * 58]
r1 = [c0[0] + ru[0] * 22, c0[1] + ru[1] * 22]
props = [slab([pad1, pad0, [pad0[0] + 20, pad0[1]]], -15, 15, 7),     # back pad and seat
         line([[pad0[0] + 6, pad0[1] + 2, 0], [pad0[0] + 6, 181, 0]], 5),
         line([[r0[0], r0[1], -22], [r1[0], r1[1], -22]], 4),          # rails either side
         line([[r0[0], r0[1], 22], [r1[0], r1[1], 22]], 4),
         line([[r1[0], r1[1], 0], [r1[0], 181, 0]], 5),                # rail post
         line([[r0[0], r0[1], -22], [r0[0], r0[1], 22]], 4),
         line([[r1[0], r1[1], -22], [r1[0], r1[1], 22]], 4),
         line([[PELVIS[0] - 6, PELVIS[1] - 6, 22], [PELVIS[0] - 2, PELVIS[1] - 6, 22]], 7),   # side handles
         line([[PELVIS[0] - 6, PELVIS[1] - 6, -22], [PELVIS[0] - 2, PELVIS[1] - 6, -22]], 7),
         slab([[pad1[0], 181], [r1[0] + 8, 181]], -24, 24, 4)]         # base
write("leg-press-calf-raise", start, end, props, load, tempo=2.4)
