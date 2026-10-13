"""One-arm DB row: far knee and far hand on a flat bench, near foot on the floor, back flat; the near arm hangs
with one dumbbell, then pulls it to the hip, elbow up past the back. One dumbbell is built from a single handle
and two plates (no load of its own, as in suitcase-carry)."""
import os, sys, math
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rig import L, P, along, joint, trunk, mirror, slab, line, write

PELVIS = [64, 104, 0]
TORSO = -9                     # back flat, shoulders a little higher than the hips
BENCH_TOP = 149
BENCH_Z = [-22, 0]             # the bench sits under the far (supported) side
HAND_Z = 19


def pose(pulled):
    p = trunk(PELVIS, TORSO, head_ang=-2)
    # far side on the bench: knee under the hip, shin back along the bench; hand on the bench under the shoulder
    p["kneeR"] = [p["hipR"][0] + 2, BENCH_TOP - 6, -9]
    p["kneeR"] = along(p["hipR"], [p["kneeR"][i] - p["hipR"][i] for i in range(3)], L["thigh"])
    p["ankleR"] = P(p["kneeR"], 178, L["shin"])
    p["toeR"] = P(p["ankleR"], 150, L["foot"])
    p["handR"] = [p["shoulderR"][0] + 9, BENCH_TOP - 6, -12]
    p["elbowR"] = joint(p["shoulderR"], p["handR"], L["upper"], L["fore"], [-1, 0, -0.3])
    # near foot on the floor, a little back and out
    p["ankleL"] = [60, 175, 20]
    p["toeL"] = P(p["ankleL"], 3, L["foot"])
    p["kneeL"] = joint(p["hipL"], p["ankleL"], L["thigh"], L["shin"], [1, 0, 0])
    sh = p["shoulderL"]
    if pulled:
        hand = [PELVIS[0] + 22, PELVIS[1] + 10, HAND_Z]
        p["elbowL"] = joint(sh, hand, L["upper"], L["fore"], [-0.3, -1, 0.15])
    else:
        dz = HAND_Z - sh[2]
        hand = [sh[0] + 2, sh[1] + math.sqrt(50.5 ** 2 - dz ** 2 - 4), HAND_Z]
        p["elbowL"] = joint(sh, hand, L["upper"], L["fore"], [-1, 0, 0])
    p["handL"] = hand
    return p


start, end = pose(False), pose(True)
for k in ("kneeL", "ankleL", "toeL", "kneeR", "ankleR", "toeR", "elbowR", "handR"):
    end[k] = start[k]
props = [slab([[22, BENCH_TOP], [142, BENCH_TOP]], BENCH_Z[0], BENCH_Z[1], 7)]
for x in (30, 134):
    for z in (BENCH_Z[0] + 3, BENCH_Z[1] - 3):
        props.append(line([[x, BENCH_TOP + 3, z], [x, 181, z]], 5))
# one dumbbell, front to back in the near hand: handle along x and a plate at each end
load = [{"type": "machine", "grips": ["handL"], "axis": [1, 0, 0], "length": 18},
        {"type": "held", "kind": "plate", "at": "handL", "offset": [8, 0, 0], "axis": [1, 0, 0]},
        {"type": "held", "kind": "plate", "at": "handL", "offset": [-8, 0, 0], "axis": [1, 0, 0]}]
write("one-arm-db-row", start, end, props, load, tempo=2.6, yaw=-20)
