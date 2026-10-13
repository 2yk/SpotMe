"""Cable pullover: lying along a flat bench, head toward a low pulley, rope in both hands; straight arms sweep
from overhead behind the head, over the face, down to the hips."""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rig import L, P, along, joint, trunk, mirror, slab, line, write

PELVIS = [132, 137, 0]
BENCH_TOP = 146
ARM_START, ARM_END = 194, -36   # overhead behind the head (stretched by the cable), then hands over the hips
ELBOW = 6
IN = -9
ANCHOR = [18, 168, 0]           # low pulley behind the head


def legs(p):
    p["ankleL"] = [164, 175, 15]
    p["toeL"] = [176.4, 179, 15]
    p["kneeL"] = joint(p["hipL"], p["ankleL"], L["thigh"], L["shin"], [1, -1, 0])


def pose(arm):
    p = trunk(PELVIS, 180, head_ang=180)
    legs(p)
    p["elbowL"] = P(p["shoulderL"], arm, L["upper"], IN)
    p["handL"] = P(p["elbowL"], arm - ELBOW, L["fore"], IN * 0.9)
    return mirror(p)


def stagger(p, dx):
    p["ankleR"][0] += dx
    p["toeR"][0] += dx
    p["kneeR"] = joint(p["hipR"], p["ankleR"], L["thigh"], L["shin"], [1, -1, 0])
    return p


start, end = stagger(pose(ARM_START), -6), stagger(pose(ARM_END), -6)
for k in ("ankleL", "toeL", "kneeL", "ankleR", "toeR", "kneeR"):
    end[k] = start[k]
props = [slab([[56, BENCH_TOP], [140, BENCH_TOP]], -12, 12, 7)]
for x in (64, 132):
    for z in (-9, 9):
        props.append(line([[x, 149, z], [x, 181, z]], 5))
props += [line([[10, 181, 0], [10, 40, 0]], 6),                       # cable column
          line([[10, ANCHOR[1], 0], ANCHOR], 5),
          line([[ANCHOR[0], ANCHOR[1] - 3, 0], [ANCHOR[0], ANCHOR[1] + 3, 0]], 8),
          slab([[4, 181], [24, 181]], -14, 14, 4)]
write("cable-pullover", start, end, props, {"type": "cable", "handle": "rope", "anchor": ANCHOR}, tempo=3.0, yaw=-25)
