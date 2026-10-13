"""DB preacher curl: seated at a preacher bench, one arm (the left) along the sloping pad with the armpit on its
top edge, one dumbbell from arm nearly straight to curled up; the right hand holds the top of the pad. One
dumbbell is built from a short handle (a machine grip without a lever) and two small discs."""
import os, sys, math
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rig import L, P, along, joint, trunk, mirror, slab, line, write

PELVIS = [66, 140, 0]
TORSO = -76                             # leaning forward over the pad
UPPER = 48                              # upper arm along the pad
FORE_START, FORE_END = 58, -70          # nearly straight along the pad; curled up
ARM_Z = 7                               # the working arm comes in toward the middle of the pad
YAW = 30                                # turned a little so one arm and one dumbbell read


def pose(fore, s=None):
    p = trunk(PELVIS, TORSO, head_ang=-84)
    if s:
        for k in ("kneeL", "ankleL", "toeL", "kneeR", "ankleR", "toeR", "hipL", "hipR", "elbowR", "handR"):
            p[k] = s[k]
    else:
        for side, z in (("L", 13), ("R", -13)):
            p["ankle" + side] = [100, 175, z]
            p["toe" + side] = P(p["ankle" + side], 5, L["foot"])
            p["knee" + side] = joint(p["hip" + side], p["ankle" + side], L["thigh"], L["shin"], [1, -1, 0])
    sh = p["shoulderL"]
    u = [math.cos(math.radians(UPPER)), math.sin(math.radians(UPPER))]
    dz = ARM_Z - sh[2]
    p["elbowL"] = along(sh, [u[0] * math.sqrt(L["upper"] ** 2 - dz ** 2), u[1] * math.sqrt(L["upper"] ** 2 - dz ** 2), dz], L["upper"])
    p["handL"] = P(p["elbowL"], fore, L["fore"])
    return p


start = pose(FORE_START)
sh = start["shoulderL"]
off = lambda q, k: [q[0] + math.cos(math.radians(UPPER + 90)) * k, q[1] + math.sin(math.radians(UPPER + 90)) * k]
top, low = off(along(sh, [1, 1, 0], 12), 10), off(along(sh, [1, 1, 0], 44), 10)
base = [top[0] + 6, top[1] + 19]
# the free hand grips the pad's top edge on the right side
start["handR"] = [top[0] + 2, top[1] - 4, -14]
start["elbowR"] = joint(start["shoulderR"], start["handR"], L["upper"], L["fore"], [-0.3, 1, -1])
end = pose(FORE_END, start)
props = [slab([base, top, low, base], -18, 18, 8),                    # sloping arm pad, a wedge from the side
         line([[base[0], base[1], 0], [base[0], 181, 0]], 5),         # pad post, between the knees
         slab([[46, 148], [84, 148]], -14, 14, 7),                     # seat
         line([[62, 151, 0], [62, 181, 0]], 5),                        # seat post
         slab([[40, 181], [110, 181]], -20, 20, 4)]                    # base
load = [{"type": "machine", "grips": ["handL"], "axis": [0, 0, 1], "length": 16},
        {"type": "held", "kind": "wheel", "at": "handL", "offset": [0, 0, 8], "axis": [0, 0, 1]},
        {"type": "held", "kind": "wheel", "at": "handL", "offset": [0, 0, -8], "axis": [0, 0, 1]}]
write("db-preacher-curl", start, end, props, load, tempo=2.8, yaw=YAW)
