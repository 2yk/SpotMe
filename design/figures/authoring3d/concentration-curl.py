"""Concentration curl: seated on the end of a flat bench, feet wide, leaning forward; the left elbow braced on the
inside of the left thigh near the knee, one dumbbell curled from hanging to the shoulder. The right hand rests on
the right knee. One dumbbell is built from a short handle (a machine grip without a lever) and two small discs."""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rig import L, P, along, joint, trunk, mirror, slab, line, write

PELVIS = [64, 140, 0]
TORSO = -42                     # leaning well forward
YAW = 75                        # turned toward the front so the arm shows braced between the legs


def pose(fore):
    p = trunk(PELVIS, TORSO, head_ang=-60)
    for s, z in (("L", 26), ("R", -26)):
        p["ankle" + s] = [104, 175, z]
        p["toe" + s] = along(p["ankle" + s], [1, 0, 0.35 * (1 if z > 0 else -1)], L["foot"])
        p["knee" + s] = joint(p["hip" + s], p["ankle" + s], L["thigh"], L["shin"], [1, -1, 0])
    k, h = p["kneeL"], p["hipL"]
    target = [k[0] + (h[0] - k[0]) * 0.18, k[1] + (h[1] - k[1]) * 0.18 - 4, k[2] - 9]   # inside of the thigh
    p["elbowL"] = along(p["shoulderL"], [target[i] - p["shoulderL"][i] for i in range(3)], L["upper"])
    p["handL"] = P(p["elbowL"], fore, L["fore"], -6)
    hr = [p["kneeR"][0] - 2, p["kneeR"][1] - 6, p["kneeR"][2] + 2]                        # hand on the knee
    p["elbowR"] = joint(p["shoulderR"], hr, L["upper"], L["fore"], [0, 0, -1])
    p["handR"] = hr
    return p


start = pose(96)        # arm hanging straight down
end = pose(-112)        # dumbbell up to the front of the shoulder
for k in start:
    if k not in ("handL",):
        end[k] = start[k]
props = [slab([[22, 149], [76, 149]], -13, 13, 7),                  # flat bench under the seat
         line([[30, 152, 0], [30, 181, 0]], 5),
         line([[70, 152, 0], [70, 181, 0]], 5)]
load = [{"type": "machine", "grips": ["handL"], "axis": [0, 0, 1], "length": 16},
        {"type": "held", "kind": "wheel", "at": "handL", "offset": [0, 0, 8], "axis": [0, 0, 1]},
        {"type": "held", "kind": "wheel", "at": "handL", "offset": [0, 0, -8], "axis": [0, 0, 1]}]
write("concentration-curl", start, end, props, load, tempo=2.8, yaw=YAW)
