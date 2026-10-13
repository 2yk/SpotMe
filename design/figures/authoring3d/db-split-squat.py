"""DB split squat: side view, long fixed split stance on the floor (front foot flat, rear foot on its toes),
dumbbells hanging at the sides; drop straight down until the rear knee nearly touches the floor, torso upright.
Both feet stay put (unlike a lunge); no bench (unlike the Bulgarian split squat). Front leg near (L)."""
import math, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rig import L, P, along, joint, trunk, mirror, slab, line, write

FRONT = [136, 176, 10]          # front ankle (L, near)
REAR_TOE = [50, 179.5, -10]     # rear foot on its toes (R, far)


def pose(px, py, foot_ang, torso=-88):
    p = trunk([px, py, 0], torso)
    p["ankleL"], p["toeL"] = list(FRONT), [FRONT[0] + 13, 179, 10]
    p["kneeL"] = joint(p["hipL"], p["ankleL"], L["thigh"], L["shin"], [1, -0.3, 0])
    p["toeR"] = list(REAR_TOE)
    p["ankleR"] = P(REAR_TOE, 180 + foot_ang, L["foot"])          # heel up behind the toe
    p["kneeR"] = joint(p["hipR"], p["ankleR"], L["thigh"], L["shin"], [0.4, 1, 0])
    for s, z in (("L", 1), ("R", -1)):
        p["elbow" + s] = P(p["shoulder" + s], 92, L["upper"], z * 4)
        p["hand" + s] = P(p["elbow" + s], 90, L["fore"], z * 2)
    return p


start = pose(98, 118, 66)       # top: both legs long
end = pose(98, 141, 60)         # bottom: front thigh level, rear knee just off the floor
for k in ("ankleL", "toeL", "toeR"):
    end[k] = start[k]
write("db-split-squat", start, end, [], {"type": "dumbbells", "axis": [1, 0, 0]}, tempo=2.8)
