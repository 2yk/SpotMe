"""Smith machine shoulder press: seated on an upright bench between the Smith machine's rails, back on the pad;
the bar runs straight up and down on the rails just in front of the face, from chin height to arms straight.
The rails and the straight-up path in front of the face tell it apart from the seated barbell press."""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rig import L, P, joint, trunk, mirror, slab, line, write

PELVIS = [80, 138, 0]
GRIP = 25                       # hands a bit wider than the shoulders
BAR_X = 96                      # the bar's fixed line, just in front of the face
BOTTOM_Y, TOP_Y = 82, 41        # chin height, arms nearly straight
RAIL_Z, RAIL_TOP = 36, 16


def pose(top):
    p = trunk(PELVIS, -90, head_ang=-92)
    p["ankleL"] = [114, 175, 13]
    p["toeL"] = [127, 175, 13]
    p["kneeL"] = joint(p["hipL"], p["ankleL"], L["thigh"], L["shin"], [1, -1, 0])
    hand = [BAR_X, TOP_Y if top else BOTTOM_Y, GRIP]
    p["elbowL"] = joint(p["shoulderL"], hand, L["upper"], L["fore"], [0.4, 1, 0.6])
    p["handL"] = hand
    return mirror(p)


start, end = pose(False), pose(True)
props = [slab([[60, 147], [104, 147]], -14, 14, 7),          # seat
         slab([[70, 140], [70, 80]], -13, 13, 7)]            # upright back rest
for x in (64, 100):                                          # four legs
    for z in (-10, 10):
        props.append(line([[x, 150, z], [x, 181, z]], 5))
props.append(line([[70, 144, 0], [64, 150, 0]], 4))         # back rest strut
for z in (-RAIL_Z, RAIL_Z):                                  # the two rails, on the bar's line
    props.append(line([[BAR_X, 181, z], [BAR_X, RAIL_TOP, z]], 4))
    props.append(slab([[BAR_X - 14, 181], [BAR_X + 14, 181]], z - 3, z + 3, 4))   # rail feet
props.append(line([[BAR_X, RAIL_TOP, -RAIL_Z], [BAR_X, RAIL_TOP, RAIL_Z]], 5))   # crossbar on top
load = {"type": "bar", "length": 96, "plate": 14}
write("smith-machine-shoulder-press", start, end, props, load, tempo=2.6, yaw=40)
