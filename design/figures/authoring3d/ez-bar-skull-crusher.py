"""EZ-bar skull crusher: lying on a flat bench, feet on the floor, upper arms tilted about 15 degrees past
vertical toward the head. Start: elbows bent, bar behind and above the head. End: arms straight."""
import os, sys, math
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rig import L, P, joint, trunk, mirror, slab, line, write

PELVIS = [118, 137, 0]
BENCH_TOP = 146
UPPER_ANG = -105                # upper arm: 15 degrees past vertical toward the head
FORE_START = 150                # start forearm: back past the head, a little down
HAND_Z, ELBOW_Z = 10, 13        # narrow EZ grip, elbows a touch wider
KNEE_BEND = [1, -1, 0]


def pose(bent):
    p = trunk(PELVIS, 180, head_ang=180)
    p["ankleL"] = [150, 175, 16]
    p["toeL"] = [162.4, 179, 16]
    p["kneeL"] = joint(p["hipL"], p["ankleL"], L["thigh"], L["shin"], [1, -1, 0])
    sh = p["shoulderL"]
    dz = ELBOW_Z - sh[2]
    flat = math.sqrt(L["upper"] ** 2 - dz ** 2)
    el = P([sh[0], sh[1], ELBOW_Z], UPPER_ANG, flat)
    if bent:
        hz = HAND_Z - ELBOW_Z
        hand = P([el[0], el[1], HAND_Z], FORE_START, math.sqrt(L["fore"] ** 2 - hz ** 2))
    else:
        hz = HAND_Z - ELBOW_Z
        hand = P([el[0], el[1], HAND_Z], UPPER_ANG, math.sqrt(L["fore"] ** 2 - hz ** 2))
    p["elbowL"], p["handL"] = el, hand
    return mirror(p)


def stagger(p, dx):
    """Far foot set back dx along the floor so the two legs read apart from the side."""
    p["ankleR"][0] += dx
    p["toeR"][0] += dx
    p["kneeR"] = joint(p["hipR"], p["ankleR"], L["thigh"], L["shin"], KNEE_BEND)
    return p


start, end = stagger(pose(True), -6), stagger(pose(False), -6)
props = [slab([[30, BENCH_TOP], [126, BENCH_TOP]], -12, 12, 7)]
for x in (40, 118):                                          # four legs
    for z in (-9, 9):
        props.append(line([[x, 149, z], [x, 181, z]], 5))
load = {"type": "bar", "length": 56, "plate": 8}
write("ez-bar-skull-crusher", start, end, props, load, tempo=2.6)
