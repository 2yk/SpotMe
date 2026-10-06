"""45 deg leg press: lying back on the angled pad, feet on the plate up and to the right; knees from bent toward
the chest to legs nearly straight while the plate slides away along its rail."""
import os, sys, math
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rig import L, P, along, joint, trunk, mirror, slab, line, write

PELVIS = [80, 152, 0]
TORSO = -142                            # back reclined along the pad
RAIL = -45                              # the sled runs up and to the right
FOOT_LINE = -38                         # hip to ankle direction
D_START, D_END = 42, 70
FZ = 12


def pose(dist, s=None):
    p = trunk(PELVIS, TORSO, head_ang=-125)
    if s:
        for k in ("elbowL", "handL", "elbowR", "handR"):
            p[k] = s[k]
    else:
        p["handL"] = [PELVIS[0] - 4, PELVIS[1] - 6, 22]
        p["elbowL"] = joint(p["shoulderL"], p["handL"], L["upper"], L["fore"], [0.3, 1, 0.6])
    a = P(PELVIS, FOOT_LINE, dist)
    p["ankleL"] = [a[0], a[1], FZ]
    p["toeL"] = P(p["ankleL"], RAIL - 90, L["foot"])       # foot flat on the plate, toes up
    p["kneeL"] = joint(p["hipL"], p["ankleL"], L["thigh"], L["shin"], [-0.6, -1, 0])
    return mirror(p)


start = pose(D_START)
end = pose(D_END, start)
# platform: centred on the soles, a little behind them along the rail
ru = [math.cos(math.radians(RAIL)), math.sin(math.radians(RAIL))]
fu = [math.cos(math.radians(RAIL - 90)), math.sin(math.radians(RAIL - 90))]
OFF = [fu[0] * 6 + ru[0] * 5, fu[1] * 6 + ru[1] * 5, 0]
load = {"type": "platform", "at": ["ankleL", "ankleR"], "offset": OFF, "angle": RAIL + 90, "length": 36, "width": 38}
# back pad parallel to the torso, 9 below it; seat under the pelvis
tu = [math.cos(math.radians(TORSO)), math.sin(math.radians(TORSO))]
nu = [-tu[1], tu[0]] if -tu[1] < 0 else [tu[1], -tu[0]]
pad0 = [PELVIS[0] + nu[0] * 9 - tu[0] * 2, PELVIS[1] + nu[1] * 9 - tu[1] * 2]
pad1 = [pad0[0] + tu[0] * 56, pad0[1] + tu[1] * 56]
# rail: under the plate's path, behind the soles
c0 = [start["ankleL"][0] + ru[0] * 8 + fu[0] * 10, start["ankleL"][1] + ru[1] * 8 + fu[1] * 10]
r0 = [c0[0] - ru[0] * 34, c0[1] - ru[1] * 34]
r1 = [c0[0] + ru[0] * 52, c0[1] + ru[1] * 52]
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
write("leg-press", start, end, props, load, tempo=2.8)
