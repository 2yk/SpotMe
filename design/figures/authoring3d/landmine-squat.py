"""Landmine squat: side view, facing the landmine; both hands cup the bar's end at the chest, the bar runs down
to its pivot on the floor ahead, a plate on the sleeve just past the hands. Lean slightly into it, squat deep.
The bar is a machine lever from the pivot (grey shaft) with a volt grip along it at the hands (the sleeve end)
plus a held plate on the sleeve. Opens turned a little so the plate shows as a disc."""
import math, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rig import L, P, along, joint, trunk, mirror, slab, line, write

ANKLE = [92, 176, 12]
PIVOT = [182, 179, 0]


def pose(px, py, torso, head):
    p = trunk([px, py, 0], torso, head_ang=head)
    p["ankleL"] = list(ANKLE)
    p["toeL"] = along(ANKLE, [1, 0.25, 0.3], L["foot"])
    p["kneeL"] = joint(p["hipL"], p["ankleL"], L["thigh"], L["shin"], [1, -0.2, 0.45])
    t = math.radians(torso)
    fwd, up = [-math.sin(t), math.cos(t), 0], [math.cos(t), math.sin(t), 0]
    c = [p["neck"][i] + fwd[i] * 14 - up[i] * 6 for i in range(3)]       # bar end at the upper chest
    p["handL"] = [c[0], c[1], 3]
    p["elbowL"] = joint(p["shoulderL"], p["handL"], L["upper"], L["fore"], [0.1, 1, 0.6])
    return mirror(p)


start = pose(88, 104, -84, -88)        # standing, leaning a little into the bar
end = pose(62, 150, -60, -74)          # deep squat
for k in ("ankleL", "ankleR", "toeL", "toeR"):
    end[k] = start[k]


def bar_dir(p):
    h = [(p["handL"][i] + p["handR"][i]) / 2 for i in range(3)]
    d = [PIVOT[i] - h[i] for i in range(3)]
    n = math.sqrt(sum(x * x for x in d))
    return [x / n for x in d]


a, b = bar_dir(start), bar_dir(end)
mid = [(a[i] + b[i]) / 2 for i in range(3)]
props = [line([[PIVOT[0] - 6, 181, 0], [PIVOT[0] + 4, 181, 0]], 7)]
load = [{"type": "machine", "grips": ["handL"], "pivots": [PIVOT], "axis": mid, "length": 18},
        {"type": "held", "kind": "plate", "at": "hands", "offset": [x * 13 for x in mid], "axis": mid}]
write("landmine-squat", start, end, props, load, tempo=2.8, yaw=30)
