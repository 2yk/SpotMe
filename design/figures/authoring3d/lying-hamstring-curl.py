"""Lying hamstring curl: side view, face down on the bench, a pad behind the ankles curls the shins about 110 degrees."""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rig import L, P, joint, trunk, mirror, slab, line, write

PELVIS = [95, 121, 0]
BENCH_Y, BENCH_X = 130, (42, 128)
GRIP = [44, 160]
CURL = 110


def pose(bend):
    p = trunk(PELVIS, 180, head_ang=186)
    hand = [GRIP[0], GRIP[1], 20]
    p["elbowL"] = joint(p["shoulderL"], hand, L["upper"], L["fore"], [0.2, 0, 1])
    p["handL"] = hand
    p["kneeL"] = P(p["hipL"], 0, L["thigh"])
    p["kneeL"][2] = 7
    shin = -8 - bend
    p["ankleL"] = P(p["kneeL"], shin, L["shin"])
    p["toeL"] = P(p["ankleL"], 68 - bend, L["foot"])
    return mirror(p)


start, end = pose(0), pose(CURL)
pivot = [start["kneeL"][0], start["kneeL"][1], 22]
props = [slab([[BENCH_X[0], BENCH_Y], [BENCH_X[1], BENCH_Y]], -12, 12, 7)]
for x in (BENCH_X[0] + 4, BENCH_X[1] - 6):
    for z in (-9, 9):
        props.append(line([[x, BENCH_Y + 3, z], [x, 181, z]], 5))
props.append(line([[GRIP[0], GRIP[1], -24], [GRIP[0], GRIP[1], 24]], 5))       # grips under the head end
props.append(line([[pivot[0], pivot[1] + 4, pivot[2]], [pivot[0], 181, pivot[2]], [BENCH_X[1] - 6, 181, 12]], 5))
load = {"type": "pad", "at": ["ankleL", "ankleR"], "offset": [-4, -3, 0], "pivot": pivot, "length": 24}
write("lying-hamstring-curl", start, end, props, load, tempo=2.6)
