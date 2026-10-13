"""Side-lying DB external rotation: lying on the right side on a flat bench, front of the body toward the viewer,
head to the right resting on the straight bottom arm, knees bent and stacked. The top arm's elbow sits on the
side of the waist at 90 degrees: the forearm turns from down across the belly to up toward the ceiling, the
elbow stays put. One dumbbell: a short grip with a small disc at each end (no one-dumbbell load exists)."""
import os, sys, math
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rig import L, P, along, joint, trunk, mirror, slab, line, write

PELVIS = [82, 128, 0]
NECK_Y = 126
BENCH_Y = 150                     # bench top line (w 7)
UP = [0, -1, 0]                   # the body's left points at the ceiling
START_DIR = [0, 0.74, 0.67]       # forearm: down toward the bench, in front of the belly
END_DIR = [0, -0.9, 0.44]         # forearm: up toward the ceiling


def pose(fore):
    ang = math.degrees(math.atan2(NECK_Y - PELVIS[1], L["torso"]))
    p = trunk(PELVIS, ang, left=UP)
    n, shr = p["neck"], p["shoulderR"]
    p["elbowR"] = [shr[0] + 27, shr[1] + 1, 0]                   # bottom arm straight along the bench, under the head
    p["handR"] = [p["elbowR"][0] + 25, p["elbowR"][1], 0]
    for s, ank in (("R", [26, BENCH_Y - 10, 6]), ("L", [28, BENCH_Y - 19, 8])):
        p["ankle" + s] = ank
        p["knee" + s] = joint(p["hip" + s], ank, L["thigh"], L["shin"], [0, 0, 1])
        p["toe" + s] = along(ank, [-0.55, 0, 0.84], L["foot"])
    sh = p["shoulderL"]
    p["elbowL"] = along(sh, [-1, 0.24, 0.12], L["upper"])         # on the side of the waist, towel under it
    p["handL"] = along(p["elbowL"], fore, L["fore"])
    return p


start, end = pose(START_DIR), pose(END_DIR)
for k in start:
    if k != "handL":
        end[k] = start[k]
props = [slab([[22, BENCH_Y], [176, BENCH_Y]], -14, 14, 7),       # bench top
         line([[44, BENCH_Y + 3, 0], [44, 181, 0]], 5),
         line([[156, BENCH_Y + 3, 0], [156, 181, 0]], 5),
         slab([[34, 181], [54, 181]], -12, 12, 4), slab([[146, 181], [166, 181]], -12, 12, 4)]
load = [{"type": "machine", "grips": ["handL"], "axis": [1, 0, 0], "length": 16},
        {"type": "held", "kind": "wheel", "at": "handL", "offset": [8, 0, 0], "axis": [1, 0, 0]},
        {"type": "held", "kind": "wheel", "at": "handL", "offset": [-8, 0, 0], "axis": [1, 0, 0]}]
write("side-lying-db-external-rotation", start, end, props, load, tempo=3, yaw=-25)
