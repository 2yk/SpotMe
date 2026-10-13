"""DB step-up: side view, a knee-high box ahead, dumbbells hanging at the sides. Start with the near (L) foot
flat on the box and the far foot on the floor behind; drive up until standing tall on the box, the trailing
(far) leg coming up bent beside the box's edge, foot hovering. The box is a bench seen end-on (a slab)."""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rig import L, P, along, joint, trunk, mirror, slab, line, write

BOX_X, BOX_TOP = (117, 158), 143        # box front edge (left) to back, top surface line
UP = [131, BOX_TOP - 5.5, 9]           # near ankle on the box
REAR = [80, 176, -9]                   # far ankle on the floor at the start


def arms(p):
    for s, z in (("L", 1), ("R", -1)):
        p["elbow" + s] = P(p["shoulder" + s], 91, L["upper"], z * 4)
        p["hand" + s] = P(p["elbow" + s], 89, L["fore"], z * 2)
    return p


def pose(px, py, torso, top):
    p = trunk([px, py, 0], torso)
    p["ankleL"], p["toeL"] = list(UP), [UP[0] + 13, UP[1] + 2, 9]
    p["kneeL"] = joint(p["hipL"], p["ankleL"], L["thigh"], L["shin"], [1, -0.4, 0])
    if not top:
        p["ankleR"], p["toeR"] = list(REAR), [REAR[0] + 12.5, 179.5, -9]
        p["kneeR"] = joint(p["hipR"], p["ankleR"], L["thigh"], L["shin"], [1, 0, 0])
    else:                                  # trailing leg bent, foot just behind and above the box's edge
        p["kneeR"] = P(p["hipR"], 93, L["thigh"])
        p["ankleR"] = P(p["kneeR"], 122, L["shin"])
        p["toeR"] = P(p["ankleR"], 12, L["foot"])
    return arms(p)


start = pose(97, 116, -82, False)
end = pose(UP[0] - 3, UP[1] - 72, -89, True)
props = [slab([[BOX_X[0], 181], [BOX_X[0], BOX_TOP], [BOX_X[1], BOX_TOP], [BOX_X[1], 181]], -22, 22, 6)]
write("step-up", start, end, props, {"type": "dumbbells", "axis": [1, 0, 0]}, tempo=3.0)
