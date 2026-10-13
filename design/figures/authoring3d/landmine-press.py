"""Landmine press: standing in a staggered stance (far leg forward), leaning a little into the bar. The bar's end
pivots in a floor sleeve in front; the near hand holds the loaded end at the shoulder and presses it up and
forward to a straight arm. The free hand rests on the hip.
No bar-from-a-pivot load exists: the bar is a `machine` lever from the floor pivot (grey) with a volt sleeve at
the hand, plus a `held` plate on the sleeve just past the hand."""
import os, sys, math
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rig import L, P, along, joint, trunk, mirror, slab, line, write

PELVIS = [84, 105, 0]
TORSO = -80                                # leaning forward into the bar
PIVOT = [184, 178, 2]                     # floor sleeve, in front, near the middle of the body


def pose(hand_rel):
    p = trunk(PELVIS, TORSO, head_ang=-84)
    # near (L) leg back, far (R) leg forward
    p["ankleL"] = [64, 175, 9]
    p["toeL"] = P(p["ankleL"], 15, L["foot"])
    p["kneeL"] = joint(p["hipL"], p["ankleL"], L["thigh"], L["shin"], [1, 0, 0])
    p["ankleR"] = [112, 175, -9]
    p["toeR"] = P(p["ankleR"], 0, L["foot"])
    p["kneeR"] = joint(p["hipR"], p["ankleR"], L["thigh"], L["shin"], [1, 0, 0])
    sh = p["shoulderL"]
    p["handL"] = [sh[i] + hand_rel[i] for i in range(3)]
    p["elbowL"] = joint(sh, p["handL"], L["upper"], L["fore"], [0, 1, 0.5])
    # free hand on the far hip
    p["handR"] = [p["hipR"][0] + 4, p["hipR"][1] - 6, p["hipR"][2] - 5]
    p["elbowR"] = joint(p["shoulderR"], p["handR"], L["upper"], L["fore"], [-1, 0, -0.6])
    return p


start = pose([14, 2, -6])                  # bar end at the front of the shoulder, elbow down and tucked
end = pose([33, -35, -11])                 # pressed up and forward, arm nearly straight, a little in
for k in ("pelvis", "neck", "head", "shoulderL", "shoulderR", "hipL", "hipR", "kneeL", "ankleL", "toeL",
          "kneeR", "ankleR", "toeR", "elbowR", "handR"):
    end[k] = start[k]


def bar_dir():
    """Mean direction from the hand to the pivot over the rep (the plate's fixed offset sits on it)."""
    ds = []
    for p in (start, end):
        h = p["handL"]
        d = [PIVOT[i] - h[i] for i in range(3)]
        m = math.sqrt(sum(a * a for a in d))
        ds.append([a / m for a in d])
    v = [(ds[0][i] + ds[1][i]) / 2 for i in range(3)]
    m = math.sqrt(sum(a * a for a in v))
    return [a / m for a in v]


u = bar_dir()
props = [slab([[PIVOT[0] - 9, 181], [PIVOT[0] + 9, 181]], -9, 9, 4),     # landmine base plate
         line([[PIVOT[0], 181, PIVOT[2]], PIVOT], 7)]                      # sleeve post
load = [{"type": "machine", "grips": ["handL"], "pivots": [PIVOT], "axis": u, "length": 12},
        {"type": "held", "kind": "plate", "at": "handL", "offset": [u[i] * 14 for i in range(3)], "axis": u}]
write("landmine-press", start, end, props, load, tempo=2.6, yaw=40)
