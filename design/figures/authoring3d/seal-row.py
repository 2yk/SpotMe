"""Seal row: lying face down on a high flat bench, legs straight along it, head just past the end; the barbell
hangs from straight arms below the bench, then is rowed up to the underside of the bench, elbows high past
the back. The raised prone bench tells it apart from a standing or chest-supported row."""
import os, sys, math
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rig import L, P, joint, trunk, mirror, slab, line, write

BENCH_TOP = 110
PELVIS = [88, BENCH_TOP - 9, 0]   # body centre line 9 above the bench top
GRIP = 23                         # hands a bit wider than the shoulders
HAND_TOP = [-18, 16]               # top: hand from the shoulder, bar just under the bench
KNEE_BEND = [0, -1, 0]


def pose(top):
    p = trunk(PELVIS, 0, head_ang=14)
    p["kneeL"] = P(p["hipL"], 180, L["thigh"])
    p["ankleL"] = P(p["kneeL"], 180, L["shin"])
    p["toeL"] = P(p["ankleL"], 100, L["foot"])               # toes point down past the end of the bench
    sh = p["shoulderL"]
    if top:
        hand = [sh[0] + HAND_TOP[0], sh[1] + HAND_TOP[1], GRIP]
        p["elbowL"] = joint(sh, hand, L["upper"], L["fore"], [-0.2, -1, 0.15])
    else:
        dz = GRIP - sh[2]
        hand = [sh[0] + 1, sh[1] + math.sqrt(51.5 ** 2 - dz * dz - 1), GRIP]
        p["elbowL"] = joint(sh, hand, L["upper"], L["fore"], [-1, 0, 0])
    p["handL"] = hand
    return mirror(p)


start, end = pose(False), pose(True)
for k in ("kneeL", "ankleL", "toeL", "kneeR", "ankleR", "toeR"):
    end[k] = start[k]
props = [slab([[30, BENCH_TOP], [144, BENCH_TOP]], -12, 12, 7)]   # high flat bench, chest to knees
for x in (40, 98):                                               # four tall legs
    for z in (-9, 9):
        props.append(line([[x, BENCH_TOP + 3, z], [x, 181, z]], 5))
load = {"type": "bar", "length": 92, "plate": 14}
write("seal-row", start, end, props, load, tempo=2.6, yaw=-30)
