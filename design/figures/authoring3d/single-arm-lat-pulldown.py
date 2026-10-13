"""Single-arm lat pulldown: seated, thighs under the knee pad; the near arm reaches straight up to a D-handle for a
full stretch, then pulls the elbow down to the hip, hand by the shoulder. The other hand rests on the knee pad.
Opens turned a little so the one working arm and its cable read."""
import os, sys, math
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rig import L, P, along, joint, trunk, slab, line, write

PELVIS = [80, 140, 0]
HZ = 13                                # the handle over the near shoulder


def base(torso, head):
    p = trunk(PELVIS, torso, head_ang=head)
    for s, z in (("L", 11), ("R", -11)):
        p["ankle" + s] = [118, 175, z]
        p["toe" + s] = P(p["ankle" + s], 5, L["foot"])
        p["knee" + s] = joint(p["hip" + s], p["ankle" + s], L["thigh"], L["shin"], [1, -1, 0])
    p["handR"] = [112, 121, -12]                                   # resting on the knee pad
    p["elbowR"] = joint(p["shoulderR"], p["handR"], L["upper"], L["fore"], [-0.3, 1, -0.6])
    return p


def top():
    p = base(-93, -88)
    sh = p["shoulderL"]
    dx, dz = 6, HZ - sh[2]
    p["handL"] = [sh[0] + dx, sh[1] - math.sqrt(51.5 ** 2 - dx ** 2 - dz ** 2), HZ]
    p["elbowL"] = joint(p["shoulderL"], p["handL"], L["upper"], L["fore"], [0, 0, 1])
    return p


def bottom(s):
    p = base(-97, -94)
    p["handL"] = [p["neck"][0] + 7, p["neck"][1] + 6, 19]
    p["elbowL"] = joint(p["shoulderL"], p["handL"], L["upper"], L["fore"], [-0.7, 1, 0.35])
    for k in ("kneeL", "ankleL", "toeL", "hipL", "kneeR", "ankleR", "toeR", "hipR", "handR"):
        p[k] = s[k]
    return p


start = top()
end = bottom(start)
a, b = end["handL"], start["handL"]
d = [b[i] - a[i] for i in range(3)]
ANCHOR = along(a, d, (a[1] - 12) / -d[1] * math.sqrt(sum(x * x for x in d)))
props = [line([[168, 181, 0], [168, 6, 0], [ANCHOR[0], 6, 0], [ANCHOR[0], 6, ANCHOR[2]]], 6),
         line([[ANCHOR[0], 6, ANCHOR[2]], ANCHOR], 8),                       # pulley
         slab([[60, 149], [100, 149]], -15, 15, 7),                          # seat
         line([[82, 151, 0], [82, 181, 0]], 5),
         slab([[106, 127], [126, 127]], -16, 16, 7),                         # knee pad
         line([[126, 127, 0], [168, 127, 0]], 4),
         slab([[60, 181], [178, 181]], -22, 22, 4)]
write("single-arm-lat-pulldown", start, end, props,
      {"type": "cable", "handle": "grip", "at": "handL", "anchor": ANCHOR}, tempo=3.0, yaw=30)
