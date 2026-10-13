"""Smith machine bench press: lying on a flat bench between the Smith machine's two rails, feet on the floor;
the bar runs straight up and down on the rails, from the mid/lower chest to arms straight. The upright rails
(with a crossbar on top) and the dead-vertical bar path tell it apart from the free barbell bench press."""
import os, sys, math
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rig import L, P, joint, trunk, mirror, slab, line, write

PELVIS = [114, 137, 0]          # body centre line 9 above the bench top (146)
BENCH_TOP = 146
GRIP = 27                       # hands a bit wider than the shoulders
BAR_DX = 12                     # the bar's fixed line: this far toward the hips from the shoulders (mid chest)
BOTTOM_Y = 124                  # bar touching the chest
TOP_UP = 47                     # top: hand this far above the shoulder, elbows nearly straight
RAIL_Z, RAIL_TOP = 36, 48
KNEE_BEND = [1, -1, 0]


def pose(top):
    p = trunk(PELVIS, 180, head_ang=180)
    p["ankleL"] = [146, 175, 16]
    p["toeL"] = [158.4, 179, 16]
    p["kneeL"] = joint(p["hipL"], p["ankleL"], L["thigh"], L["shin"], KNEE_BEND)
    sh = p["shoulderL"]
    x = sh[0] + BAR_DX
    hand = [x, sh[1] - TOP_UP, GRIP] if top else [x, BOTTOM_Y, GRIP]
    p["elbowL"] = joint(sh, hand, L["upper"], L["fore"], [0.3, 1, 0.8])
    p["handL"] = hand
    return mirror(p)


def stagger(p, dx):
    p["ankleR"][0] += dx
    p["toeR"][0] += dx
    p["kneeR"] = joint(p["hipR"], p["ankleR"], L["thigh"], L["shin"], KNEE_BEND)
    return p


start, end = stagger(pose(False), -6), stagger(pose(True), -6)
for k in ("ankleL", "toeL", "kneeL", "ankleR", "toeR", "kneeR"):
    end[k] = start[k]
RX = start["handL"][0]
props = [slab([[36, BENCH_TOP], [122, BENCH_TOP]], -12, 12, 7)]
for x in (44, 114):                                          # four bench legs
    for z in (-9, 9):
        props.append(line([[x, 149, z], [x, 181, z]], 5))
for z in (-RAIL_Z, RAIL_Z):                                  # the two rails, on the bar's line
    props.append(line([[RX, 181, z], [RX, RAIL_TOP, z]], 4))
    props.append(slab([[RX - 14, 181], [RX + 14, 181]], z - 3, z + 3, 4))   # rail feet
props.append(line([[RX, RAIL_TOP, -RAIL_Z], [RX, RAIL_TOP, RAIL_Z]], 5))   # crossbar on top
load = {"type": "bar", "length": 96, "plate": 14}
write("smith-bench-press", start, end, props, load, tempo=2.6, yaw=-30)
