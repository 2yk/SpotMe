"""Wide-grip seated cable row: seated on the low-row bench, feet on the foot plate, knees soft; a long bar held
overhand and wide, pulled from arms reaching forward to the lower chest with the elbows flared about 45 degrees."""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rig import L, P, along, joint, trunk, mirror, slab, line, write

PELVIS = [60, 140, 0]                  # on the bench top (149)
HAND_Z = 27                            # wide grip: hands well outside the shoulders (15)
REACH = [117, 119]                     # start: arms long toward the pulley, shoulders a touch forward
PULL = [82, 113]                       # end: bar at the lower chest
ANCHOR_X = 172
_t = (ANCHOR_X - PULL[0]) / (REACH[0] - PULL[0])
ANCHOR = [ANCHOR_X, PULL[1] + (REACH[1] - PULL[1]) * _t, 0]   # on the line the bar travels


def pose(hand, lean, s=None):
    p = trunk(PELVIS, lean, head_ang=-86)
    if s:
        for k in ("kneeL", "ankleL", "toeL"):
            p[k] = s[k]
    else:
        p["ankleL"] = [124, 152, 11]
        p["toeL"] = P(p["ankleL"], -68, L["foot"])
        p["kneeL"] = joint(p["hipL"], p["ankleL"], L["thigh"], L["shin"], [0.2, -1, 0])
    p["handL"] = [hand[0], hand[1], HAND_Z]
    p["elbowL"] = joint(p["shoulderL"], p["handL"], L["upper"], L["fore"], [-0.6, 0.15, 1])   # elbows out ~45
    return mirror(p)


start = pose(REACH, -74)
end = pose(PULL, -90, start)
ft = start["ankleL"]
props = [slab([[30, 149], [98, 149]], -12, 12, 7),                                   # bench
         line([[38, 152, 0], [38, 181, 0]], 5), line([[90, 152, 0], [90, 181, 0]], 5),
         slab([[ft[0] + 8, 158], [ft[0] + 13, 134]], -16, 16, 5),                     # foot plate
         line([[ft[0] + 11, 146, 0], [ANCHOR_X + 6, 146, 0]], 5),                    # foot plate brace
         line([[ANCHOR_X + 6, 181, 0], [ANCHOR_X + 6, 40, 0]], 6),       # column
         line([[ANCHOR_X + 6, ANCHOR[1], 0], ANCHOR], 5),                            # pulley
         line([[ANCHOR[0], ANCHOR[1] - 3, 0], [ANCHOR[0], ANCHOR[1] + 3, 0]], 8),
         slab([[24, 181], [186, 181]], -14, 14, 4)]
write("wide-grip-seated-cable-row", start, end, props,
      {"type": "cable", "handle": "bar", "anchor": ANCHOR}, tempo=2.6, yaw=-30)
