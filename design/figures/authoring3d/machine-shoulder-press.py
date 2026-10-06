"""Machine shoulder press: seated with the back on a tall pad, machine handles from shoulder height to overhead."""
import os, sys, math
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rig import L, P, along, joint, trunk, mirror, slab, line, write

PELVIS = [78, 138, 0]
TORSO = -96                             # back pad reclined a little, head clear of the arms
GRIP_START = [96, 68, 31]
GRIP_END = [96, 44, 22]
PX, PZ = 126, 34                        # lever pivot in front; y solved so both grips are equidistant


def pose(hand):
    p = trunk(PELVIS, TORSO)
    p["ankleL"] = [112, 175, 11]
    p["toeL"] = [125, 175, 11]
    p["kneeL"] = joint(p["hipL"], p["ankleL"], L["thigh"], L["shin"], [1, -1, 0])
    p["handL"] = list(hand)
    p["elbowL"] = joint(p["shoulderL"], p["handL"], L["upper"], L["fore"], [0.2, 1, 1])
    return mirror(p)


def solve_py():
    """y where the pivot (at PX, PZ) is as far from the start grip as from the end grip."""
    d = lambda g, y: (PX - g[0]) ** 2 + (y - g[1]) ** 2 + (PZ - g[2]) ** 2
    c0, c1 = d(GRIP_START, 0) - d(GRIP_END, 0), d(GRIP_START, 1) - d(GRIP_END, 1)
    return -c0 / (c1 - c0)


start, end = pose(GRIP_START), pose(GRIP_END)
PY = solve_py()
PIVOT = [PX, PY, PZ]
t, n = P([0, 0, 0], TORSO, 1), P([0, 0, 0], TORSO - 90, 1)
PAD0 = [PELVIS[0] + n[0] * 9, PELVIS[1] + n[1] * 9]
PAD1 = [PAD0[0] + t[0] * 72, PAD0[1] + t[1] * 72]
props = [slab([[58, 147], [104, 147]], -16, 16, 7),          # seat
         slab([PAD0, PAD1], -14, 14, 7),                     # tall back pad, parallel to the torso
         line([[82, 150, 0], [82, 181, 0]], 5),              # seat post
         line([[69, 132, 0], [62, 132, 0], [62, 181, 0]], 5),  # back pad post
         slab([[56, 181], [168, 181]], -30, 30, 4)]          # base
for z in (-PZ, PZ):                                          # frame: a post each side up to the pivot
    props.append(line([[160, 181, z], [160, PY, z], [PIVOT[0], PY, z]], 5))
load = {"type": "machine", "grips": ["handL", "handR"],
        "pivots": [PIVOT, [PIVOT[0], PY, -PZ]], "axis": [1, 0, 0], "length": 14}
write("machine-shoulder-press", start, end, props, load, tempo=2.4)
