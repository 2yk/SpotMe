"""Copenhagen plank: side plank on the right forearm, the top (left) ankle on a flat bench, the bottom leg
hanging free under the bench top. Body straight and level, front toward the viewer. Hold."""
import math, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rig import L, P, along, joint, trunk, mirror, slab, line, write

GROUND = 177.5
SHOULDER_R = [150, GROUND - L["upper"], 0]
LEFT = [0, -1, 0]                   # body level: its left points straight up
DROP = 15                           # bottom leg hangs this many degrees below the body line


def pose(lift):
    neck = [SHOULDER_R[0], SHOULDER_R[1] - 15, 0]
    pelvis = [neck[0] - L["torso"], neck[1] - lift, 0]
    p = trunk(pelvis, 0, left=LEFT)
    p["neck"], p["shoulderL"], p["shoulderR"] = neck, [neck[0], neck[1] - 15, 0], SHOULDER_R
    p["head"] = P(neck, 0, L["head"])
    p["elbowR"] = [SHOULDER_R[0], GROUND, 0]
    p["handR"] = along(p["elbowR"], [0.55, 0, 1], L["fore"])
    hip_l = [pelvis[0], neck[1] - 9, 0]             # leg roots stay put
    hip_r = [pelvis[0], neck[1] + 9, 0]
    p["kneeL"] = P(hip_l, 180, L["thigh"])
    p["ankleL"] = P(p["kneeL"], 180, L["shin"])
    p["toeL"] = along(p["ankleL"], [0.2, 0.1, 1], L["foot"])
    p["kneeR"] = P(hip_r, 180 - DROP, L["thigh"])
    p["ankleR"] = P(p["kneeR"], 180 - DROP - 6, L["shin"])
    p["toeR"] = along(p["ankleR"], [0.2, 0.2, 1], L["foot"])
    p["handL"] = [pelvis[0] + 4, hip_l[1] - 2, 8]      # top hand resting on the hip
    p["elbowL"] = joint(p["shoulderL"], p["handL"], L["upper"], L["fore"], [0, -0.2, 1])
    return p


start, end = pose(0), pose(2)
for k in start:
    if k not in ("pelvis", "hipL", "hipR"):
        end[k] = start[k]
ax = start["ankleL"][0]
top = start["ankleL"][1] + 4.5 + 3.5
props = [slab([[ax - 14, top], [ax + 14, top]], -26, 26, 7)]
for x in (ax - 12, ax + 12):
    for z in (-23, 23):
        props.append(line([[x, top + 3, z], [x, 181, z]], 5))
write("copenhagen-plank", start, end, props, None, tempo=4, hold=True)
