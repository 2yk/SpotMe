"""Triceps extension machine: seated, chest up against an angled arm pad, upper arms resting on it reaching forward
and down, elbows at the machine's pivot; the forearms extend from bent up toward the shoulders to straight in line
with the upper arms. Each handle rides on a lever from a pivot beside the elbow."""
import os, sys, math
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rig import L, P, along, joint, trunk, mirror, slab, line, write

PELVIS = [74, 138, 0]
TORSO = -86                     # upright, a touch forward toward the pad
UPPER = 38                      # upper arm angle: forward and down onto the pad
ELBOW_Z = 14
FORE_START, FORE_END = -98, 44   # forearm: folded up toward the shoulder -> straight, in line with the upper arm


def pose(fore):
    p = trunk(PELVIS, TORSO, head_ang=-84)
    p["ankleL"] = [110, 175, 11]
    p["toeL"] = [123, 175, 11]
    p["kneeL"] = joint(p["hipL"], p["ankleL"], L["thigh"], L["shin"], [1, -1, 0])
    sh = p["shoulderL"]
    dz = ELBOW_Z - sh[2]
    flat = math.sqrt(L["upper"] ** 2 - dz ** 2)
    a = math.radians(UPPER)
    p["elbowL"] = [sh[0] + flat * math.cos(a), sh[1] + flat * math.sin(a), ELBOW_Z]
    p["handL"] = P(p["elbowL"], fore, L["fore"])
    return mirror(p)


start, end = pose(FORE_START), pose(FORE_END)
el = start["elbowL"]
PZ = ELBOW_Z + 8
a = math.radians(UPPER)
u, nrm = [math.cos(a), math.sin(a)], [math.sin(a), -math.cos(a)]        # along the upper arm; below it (down-left)
nrm = [-nrm[0], -nrm[1]]
sh = start["shoulderL"]
pad0 = [sh[0] + u[0] * 6 + nrm[0] * 8, sh[1] + u[1] * 6 + nrm[1] * 8]
pad1 = [el[0] + u[0] * 2 + nrm[0] * 8, el[1] + u[1] * 2 + nrm[1] * 8]
props = [slab([[54, 147], [96, 147]], -15, 15, 7),                     # seat
         line([[76, 150, 0], [76, 181, 0]], 5),                        # seat post
         slab([pad0, pad1], -20, 20, 8),                               # arm pad under the upper arms
         line([[pad1[0] + 2, pad1[1] + 2, 0], [138, 132, 0], [138, 181, 0]], 5),   # pad support
         slab([[54, 181], [150, 181]], -26, 26, 4)]                    # base
load = {"type": "machine", "grips": ["handL", "handR"], "pivots": [[el[0], el[1], PZ], [el[0], el[1], -PZ]],
        "axis": [0, 0, 1], "length": 10}
write("triceps-extension-machine", start, end, props, load, tempo=2.6, yaw=-20)
