"""Close-grip lat pulldown: seated, thighs under the knee pad, slight lean back; a close handle from arms straight
overhead down to the upper chest, elbows to the ribs. Cable from a pulley above."""
import os, sys, math
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rig import L, P, along, joint, trunk, mirror, slab, line, write

PELVIS = [80, 140, 0]
TORSO_START, TORSO_END = -96, -106     # a slight lean back, a little more at the bottom
HZ = 5                                 # hands 5 either side of the middle: a close grip


def legs(p):
    p["ankleL"] = [118, 175, 11]
    p["toeL"] = P(p["ankleL"], 5, L["foot"])
    p["kneeL"] = joint(p["hipL"], p["ankleL"], L["thigh"], L["shin"], [1, -1, 0])


def top():
    p = trunk(PELVIS, TORSO_START, head_ang=-92)
    legs(p)
    p["handL"] = along(p["shoulderL"], [0.3, -1, (HZ - 15) / 52.0], 51)
    p["elbowL"] = joint(p["shoulderL"], p["handL"], L["upper"], L["fore"], [0, 0, 1])
    return mirror(p)


def bottom(s):
    p = trunk(PELVIS, TORSO_END, head_ang=-96)
    p["handL"] = [p["neck"][0] + 13, p["neck"][1] + 6, HZ]
    p["elbowL"] = joint(p["shoulderL"], p["handL"], L["upper"], L["fore"], [-0.6, 1, 0.5])
    for k in ("kneeL", "ankleL", "toeL", "hipL"):
        p[k] = s[k]
    return mirror(p)


start = top()
end = bottom(start)
mid = lambda p: [(p["handL"][i] + p["handR"][i]) / 2 for i in range(3)]
a, b = mid(end), mid(start)
d = [b[i] - a[i] for i in range(3)]
ANCHOR = along(a, d, (a[1] - 14) / -d[1] * math.sqrt(sum(x * x for x in d)))
ANCHOR[2] = 0
props = [line([[168, 181, 0], [168, 8, 0], [ANCHOR[0], 8, 0]], 6),        # column and top arm
         line([[ANCHOR[0], 8, 0], [ANCHOR[0], ANCHOR[1], 0]], 8),          # pulley
         slab([[60, 149], [100, 149]], -15, 15, 7),                        # seat
         line([[82, 151, 0], [82, 181, 0]], 5),                            # seat post
         slab([[106, 127], [126, 127]], -16, 16, 7),                       # knee pad
         line([[126, 127, 0], [168, 127, 0]], 4),                          # knee pad arm
         slab([[60, 181], [178, 181]], -22, 22, 4)]                        # base
write("close-grip-lat-pulldown", start, end, props, {"type": "cable", "handle": "bar", "anchor": ANCHOR}, tempo=3.0)
