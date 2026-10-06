"""Preacher curl: seated, upper arms on a pad sloping 45 deg down away from the body; an EZ bar from arms nearly
straight along the pad to curled up toward the shoulders."""
import os, sys, math
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rig import L, P, along, joint, trunk, mirror, slab, line, write

PELVIS = [66, 140, 0]
TORSO = -78                             # leaning forward over the pad
UPPER = 45                              # upper arm along the pad
FORE_START, FORE_END = 55, -72          # nearly straight along the pad; curled up
HAND_Z = 10                             # EZ bar grip


def pose(fore, s=None):
    p = trunk(PELVIS, TORSO, head_ang=-84)
    if s:
        for k in ("kneeL", "ankleL", "toeL", "kneeR", "ankleR", "toeR", "hipL", "hipR"):
            p[k] = s[k]
    else:
        for side, z in (("L", 13), ("R", -13)):
            p["ankle" + side] = [100, 175, z]
            p["toe" + side] = P(p["ankle" + side], 5, L["foot"])
            p["knee" + side] = joint(p["hip" + side], p["ankle" + side], L["thigh"], L["shin"], [1, -1, 0])
    sh = p["shoulderL"]
    p["elbowL"] = along(sh, [math.cos(math.radians(UPPER)), math.sin(math.radians(UPPER)), -0.06], L["upper"])
    e = p["elbowL"]
    p["handL"] = along(e, [math.cos(math.radians(fore)), math.sin(math.radians(fore)), (HAND_Z - e[2]) / 25.0],
                       L["fore"])
    m = mirror({k: v for k, v in p.items() if k.endswith("L") and k[:-1] in ("elbow", "hand")})
    p["elbowR"], p["handR"] = m["elbowR"], m["handR"]
    return p


start = pose(FORE_START)
end = pose(FORE_END, start)
sh, el = start["shoulderL"], start["elbowL"]
off = lambda q, k: [q[0] + math.cos(math.radians(UPPER + 90)) * k, q[1] + math.sin(math.radians(UPPER + 90)) * k]
top, low = off(along(sh, [1, 1, 0], 12), 10), off(along(sh, [1, 1, 0], 44), 10)
base = [top[0] + 6, top[1] + 19]                                      # the wedge's lower corner
props = [slab([base, top, low, base], -18, 18, 8),                    # sloping arm pad, a wedge from the side
         line([[base[0], base[1], 0], [base[0], 181, 0]], 5),         # pad post, between the knees
         slab([[46, 148], [84, 148]], -14, 14, 7),                     # seat
         line([[62, 151, 0], [62, 181, 0]], 5),                        # seat post
         slab([[40, 181], [110, 181]], -20, 20, 4)]                    # base
write("preacher-curl", start, end, props, {"type": "bar", "length": 56, "plate": 8}, tempo=2.6)
