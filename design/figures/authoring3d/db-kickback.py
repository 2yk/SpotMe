"""DB kickback: far knee and far hand on a flat bench, near foot on the floor beside it, back flat; the near
upper arm held level beside the body, the forearm from hanging straight down to straight back."""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rig import L, P, along, joint, trunk, slab, line, write

BENCH_TOP = 146
KNEE_R = [82, 141, -9]          # far knee on the bench
TORSO = -18                     # back nearly flat, rising a little to the head
UPPER, UPPER_OUT = 197, 6       # upper arm about level, elbow a little high, beside the body
FORE_START, FORE_END = 92, 195


def pose(fore):
    hipR = P(KNEE_R, -94, L["thigh"])
    pelvis = [hipR[0], hipR[1], 0]
    p = trunk(pelvis, TORSO, head_ang=-10)
    p["kneeR"] = list(KNEE_R)
    p["ankleR"] = [KNEE_R[0] - 35.5, BENCH_TOP - 7, -9]     # shin along the bench
    p["toeR"] = P(p["ankleR"], 168, L["foot"])
    p["ankleL"] = [p["hipL"][0] + 8, 175, 15]                # near foot on the floor beside the bench
    p["toeL"] = P(p["ankleL"], 0, L["foot"])
    p["kneeL"] = joint(p["hipL"], p["ankleL"], L["thigh"], L["shin"], [1, 0, 0])
    p["handR"] = [p["shoulderR"][0] + 5, BENCH_TOP - 6, -14]  # far hand flat on the bench
    p["elbowR"] = joint(p["shoulderR"], p["handR"], L["upper"], L["fore"], [-1, 0, 0])
    p["elbowL"] = P(p["shoulderL"], UPPER, L["upper"], UPPER_OUT)
    p["handL"] = P(p["elbowL"], fore, L["fore"])
    return p


start, end = pose(FORE_START), pose(FORE_END)
props = [slab([[22, BENCH_TOP], [150, BENCH_TOP]], -24, 0, 7)]   # bench under the far side of the body
for x in (32, 140):
    for z in (-21, -3):
        props.append(line([[x, BENCH_TOP + 3, z], [x, 181, z]], 5))
# One dumbbell in the near hand (the dumbbells load puts one in each): a handle with a disc at each end, as
# suitcase-carry builds it. Handle tilted so it reads across the forearm at both ends of the rep.
AX = [0.6, -0.8, 0]
load = [{"type": "machine", "grips": ["handL"], "axis": AX, "length": 18},
        {"type": "held", "kind": "wheel", "at": "handL", "offset": [9 * AX[0], 9 * AX[1], 0], "axis": AX},
        {"type": "held", "kind": "wheel", "at": "handL", "offset": [-9 * AX[0], -9 * AX[1], 0], "axis": AX}]
write("db-kickback", start, end, props, load, tempo=2.6)
