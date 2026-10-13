"""DB pullover: lying along a flat bench, feet on the floor, one dumbbell held in both hands; arms (elbows soft)
lower in an arc from straight up over the chest to behind the head, then back. The dumbbell is drawn as a short
bar with two small plates across the hands."""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rig import L, P, along, joint, trunk, mirror, slab, line, write

PELVIS = [126, 137, 0]          # head to the left, centre line 9 above the bench top
BENCH_TOP = 146
ARM_START, ARM_END = 188, -86   # upper-arm angle: behind the head (a touch below the bench line), then straight up
ELBOW = 14                      # soft elbows: the forearm turns this far back toward the face
IN = -11                        # arms angle in so the hands meet on the dumbbell


def legs(p):
    p["ankleL"] = [158, 175, 15]
    p["toeL"] = [170.4, 179, 15]
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
props = [slab([[50, BENCH_TOP], [134, BENCH_TOP]], -12, 12, 7)]
for x in (58, 126):
    for z in (-9, 9):
        props.append(line([[x, 149, z], [x, 181, z]], 5))
load = {"type": "bar", "at": "hands", "length": 30, "plate": 8}
write("db-pullover", start, end, props, load, tempo=3.0, yaw=-30)
