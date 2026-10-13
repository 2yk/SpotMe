"""Spider curl: chest down on a 45 degree incline bench, toes on the floor behind, arms hanging straight down
over the top of the pad; curl the dumbbells up while the upper arms stay still."""
import os, sys, math
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rig import L, P, joint, trunk, mirror, slab, line, write

PELVIS = [70, 112, 0]
INCLINE = 45                    # torso (and pad) angle from the floor, rising to the right
PAD = 10                        # pad surface below the body's centre line
ARM_Z = 18                      # arms hang just outside the pad's top corners
UPPER = 84                      # upper arm: straight down, a touch forward of the pad top
FORE_END = -62                  # curled: forearm up and forward, dumbbell in front of the face


def pose(curled):
    p = trunk(PELVIS, -INCLINE, head_ang=-INCLINE - 10)
    p["ankleL"] = [42, 175, 11]
    p["toeL"] = [54.5, 179, 11]
    p["kneeL"] = joint(p["hipL"], p["ankleL"], L["thigh"], L["shin"], [1, 0.3, 0])
    sh = p["shoulderL"]
    dz = ARM_Z - sh[2]
    out = math.degrees(math.asin(dz / L["upper"]))
    p["elbowL"] = P(sh, UPPER, L["upper"], out)
    p["handL"] = P(p["elbowL"], FORE_END if curled else UPPER + 2, L["fore"])
    return mirror(p)


def stagger(p, dx):
    p["ankleR"][0] += dx
    p["toeR"][0] += dx
    p["kneeR"] = joint(p["hipR"], p["ankleR"], L["thigh"], L["shin"], [1, 0.3, 0])
    return p


start, end = stagger(pose(False), 4), stagger(pose(True), 4)
for k in ("ankleL", "toeL", "kneeL", "ankleR", "toeR", "kneeR"):
    end[k] = start[k]
a = math.radians(INCLINE)
n = [math.sin(a) * PAD, math.cos(a) * PAD]
pad0 = [PELVIS[0] + n[0] + 2 * math.cos(a), PELVIS[1] + n[1] - 2 * math.sin(a)]
pad1 = [PELVIS[0] + n[0] + 36 * math.cos(a), PELVIS[1] + n[1] - 36 * math.sin(a)]
postx = (pad0[0] + pad1[0]) / 2
posty = (pad0[1] + pad1[1]) / 2 + 4
props = [slab([pad0, pad1], -12, 12, 8),                             # chest pad
         line([[postx, posty, 0], [postx, 181, 0]], 5),              # post
         slab([[postx - 22, 181], [postx + 22, 181]], -14, 14, 4)]   # base
write("spider-curl", start, end, props, {"type": "dumbbells", "axis": [0, 0, 1]}, tempo=2.6, yaw=35)
