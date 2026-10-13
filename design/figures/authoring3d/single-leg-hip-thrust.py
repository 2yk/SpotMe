"""Single-leg hip thrust: upper back across a bench, the far (right) foot flat on the floor, the near (left) leg
held up with the knee bent (thigh up, shin level). Hands rest on the hips. Hips from low to level with the
planted knee and the shoulders; the raised leg rides along with the pelvis."""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rig import L, P, joint, trunk, slab, write

NECK = [44, 139, 0]
TORSO_START, TORSO_END = 33, 0      # angle neck -> pelvis: hips low, then level
LEG = {TORSO_START: (-74, 12), TORSO_END: (-90, 0)}   # raised thigh and shin angles: knee held up, shin level
BENCH_Z = 22


def pose(ang):
    pelvis = P(NECK, ang, L["torso"])
    p = trunk(pelvis, ang + 180, head_ang=196)
    p["ankleR"] = [134, 175, -6]
    p["toeR"] = [146.4, 179, -6]
    p["kneeR"] = joint(p["hipR"], p["ankleR"], L["thigh"], L["shin"], [0.3, -1, 0])
    thigh, shin = LEG[ang]
    p["kneeL"] = P(p["hipL"], thigh, L["thigh"])
    p["ankleL"] = P(p["kneeL"], shin, L["shin"])
    p["toeL"] = P(p["ankleL"], shin - 80, L["foot"])
    for s, k in (("L", 1), ("R", -1)):          # hands on the front of the hips, elbows out
        hand = [pelvis[0] - 6, pelvis[1] - 9, k * 14]
        p["elbow" + s] = joint(p["shoulder" + s], hand, L["upper"], L["fore"], [0, -1, 0.8 * k])
        p["hand" + s] = hand
    return p


start, end = pose(TORSO_START), pose(TORSO_END)
for k in ("neck", "head", "shoulderL", "shoulderR", "ankleR", "toeR"):
    end[k] = list(start[k])
props = [slab([[20, 146], [56, 146]], -BENCH_Z, BENCH_Z, 7), slab([[56, 149], [56, 181]], -BENCH_Z, BENCH_Z, 5),
         slab([[20, 149], [20, 181]], -BENCH_Z, BENCH_Z, 5)]
write("single-leg-hip-thrust", start, end, props, None, tempo=2.8)
