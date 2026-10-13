"""Goblet squat: side view, one dumbbell held upright at the chest with both hands; from standing to a deep
squat, chest tall, knees forward and out. The dumbbell is a short upright handle with a plate at each end
(the dumbbells load puts one in each hand)."""
import math, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rig import L, P, along, joint, trunk, mirror, slab, line, write

ANKLE = [104, 176, 12]


def pose(px, py, torso, head):
    pelvis = [px, py, 0]
    p = trunk(pelvis, torso, head_ang=head)
    p["ankleL"] = list(ANKLE)
    p["toeL"] = along(ANKLE, [1, 0.25, 0.3], L["foot"])
    p["kneeL"] = joint(p["hipL"], p["ankleL"], L["thigh"], L["shin"], [1, -0.2, 0.45])
    # hands together in front of the chest, under the dumbbell's top end
    t = math.radians(torso)
    fwd = [-math.sin(t), math.cos(t), 0]            # torso direction turned 90° forward
    up = [math.cos(t), math.sin(t), 0]
    c = [p["neck"][i] + fwd[i] * 15 - up[i] * 12 for i in range(3)]
    p["handL"] = [c[0], c[1], 3]
    p["elbowL"] = joint(p["shoulderL"], p["handL"], L["upper"], L["fore"], [0.2, 1, 0.5])
    return mirror(p)


start = pose(102, 103, -90, -90)          # standing tall
end = pose(74, 150, -62, -78)             # deep squat, chest up
for k in ("ankleL", "ankleR", "toeL", "toeR"):
    end[k] = start[k]
load = [{"type": "machine", "grips": ["handL"], "axis": [0, 1, 0], "length": 18},
        {"type": "held", "kind": "plate", "at": ["handL", "handR"], "offset": [0, -9, 0], "axis": [0, 1, 0]},
        {"type": "held", "kind": "plate", "at": ["handL", "handR"], "offset": [0, 9, 0], "axis": [0, 1, 0]}]
write("goblet-squat", start, end, [], load, tempo=2.8)
