"""Incline DB curl: sitting back on a 45 degree incline bench, arms hanging straight down behind the torso line;
curl the dumbbells to the shoulders while the upper arms stay vertical."""
import os, sys, math
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rig import L, P, joint, trunk, mirror, slab, line, write

PELVIS = [96, 138, 0]
INCLINE = 45                    # back rest angle from the floor
ARM_Z = 19                      # arms hang just outside the back rest
FORE_END = -62                  # end forearm angle: up and a little forward, dumbbell at the shoulder
PAD = 9                         # back rest surface below the body's centre line


def pose(curled):
    p = trunk(PELVIS, -180 + INCLINE, head_ang=-180 + INCLINE + 10)
    p["ankleL"] = [134, 175, 13]
    p["toeL"] = [147, 175, 13]
    p["kneeL"] = joint(p["hipL"], p["ankleL"], L["thigh"], L["shin"], [1, -1, 0])
    sh = p["shoulderL"]
    dz = ARM_Z - sh[2]
    el = [sh[0], sh[1] + math.sqrt(L["upper"] ** 2 - dz ** 2), ARM_Z]     # upper arm vertical
    hand = P(el, FORE_END, L["fore"]) if curled else P(el, 90, L["fore"])
    p["elbowL"], p["handL"] = el, hand
    return mirror(p)


start, end = pose(False), pose(True)
a = math.radians(INCLINE)
n = [-math.sin(a) * PAD, math.cos(a) * PAD]                          # from the torso line to the back rest
back0 = [PELVIS[0] + n[0] - 4 * math.cos(a), PELVIS[1] + n[1] + 4 * math.sin(a)]
back1 = [PELVIS[0] + n[0] - 56 * math.cos(a), PELVIS[1] + n[1] - 56 * math.sin(a)]
props = [slab([back1, back0], -12, 12, 7),                            # incline back rest
         slab([[80, 147], [118, 147]], -13, 13, 7)]                   # seat
for z in (-10, 10):                                                   # front legs
    props.append(line([[114, 150, z], [114, 181, z]], 5))
props.append(line([[86, 150, 0], [86, 181, 0]], 5))                  # rear post
props.append(line([[back1[0] + 3, back1[1] + 4, 0], [70, 181, 0]], 5))  # back rest strut to the floor
props.append(line([[70, 181, 0], [84, 181, 0]], 4))
load = {"type": "dumbbells", "axis": [0, 0, 1]}
write("incline-db-curl", start, end, props, load, tempo=2.6)
