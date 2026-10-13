"""Biceps curl machine: seated, upper arms on a sloping pad, elbows lined up with the machine's pivot; each hand
on a handle at the end of a lever that turns about the elbow. Curl from arms nearly straight to curled up."""
import os, sys, math
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rig import L, P, along, joint, trunk, mirror, slab, line, write

PELVIS = [62, 140, 0]
TORSO = -80
UPPER = 38                              # upper arm along the pad (flatter than a preacher bench)
FORE_START, FORE_END = 40, -80          # nearly straight along the pad; curled up
ARM_Z = 13                              # shoulder-width handles
LEVER_Z = 25                            # levers run outside the arms, pivoting level with the elbows


def pose(fore, s=None):
    p = trunk(PELVIS, TORSO, head_ang=-86)
    if s:
        for k in ("kneeL", "ankleL", "toeL", "kneeR", "ankleR", "toeR", "hipL", "hipR"):
            p[k] = s[k]
    else:
        for side, z in (("L", 13), ("R", -13)):
            p["ankle" + side] = [96, 175, z]
            p["toe" + side] = P(p["ankle" + side], 5, L["foot"])
            p["knee" + side] = joint(p["hip" + side], p["ankle" + side], L["thigh"], L["shin"], [1, -1, 0])
    sh = p["shoulderL"]
    u = [math.cos(math.radians(UPPER)), math.sin(math.radians(UPPER))]
    dz = ARM_Z - sh[2]
    r = math.sqrt(L["upper"] ** 2 - dz ** 2)
    p["elbowL"] = [sh[0] + u[0] * r, sh[1] + u[1] * r, ARM_Z]
    p["handL"] = P(p["elbowL"], fore, L["fore"])
    m = mirror({k: p[k] for k in ("elbowL", "handL")})
    p["elbowR"], p["handR"] = m["elbowR"], m["handR"]
    return p


start = pose(FORE_START)
end = pose(FORE_END, start)
el = start["elbowL"]
pivots = [[el[0], el[1], LEVER_Z], [el[0], el[1], -LEVER_Z]]
sh = start["shoulderL"]
off = lambda q, k: [q[0] + math.cos(math.radians(UPPER + 90)) * k, q[1] + math.sin(math.radians(UPPER + 90)) * k]
top, low = off(along(sh, [1, 1, 0], 8), 9), off(along(sh, [math.cos(math.radians(UPPER)), math.sin(math.radians(UPPER)), 0], 30), 9)
props = [slab([top, low], -20, 20, 8),                                 # arm pad
         slab([[40, 148], [80, 148]], -14, 14, 7),                     # seat
         line([[58, 151, 0], [58, 181, 0]], 5),                        # seat post
         slab([[36, 181], [142, 181]], -34, 26, 4)]                    # base
for z in (-LEVER_Z, LEVER_Z):                                          # frame: an upright each side up to the pivot
    props.append(line([[el[0] + 6, 181, z], [el[0] + 6, el[1] + 6, z], [el[0], el[1], z]], 5))
props.append(line([[low[0], low[1] + 4, 0], [low[0] + 4, 181, 0]], 5))   # pad post
props.append(slab([[134, 181], [134, 96]], -34, -18, 10))               # weight stack, front right of the pad
load = {"type": "machine", "grips": ["handL", "handR"], "pivots": pivots, "axis": [0, 0, 1], "length": 12}  # handles across, at lever ends
write("machine-biceps-curl", start, end, props, load, tempo=2.8, yaw=30)
