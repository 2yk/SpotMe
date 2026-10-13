"""Decline crunch: on a decline bench, head end low, knees bent over the high end with the feet hooked under
the rollers, fingertips at the temples; the upper body curls up off the bench until the low back starts to
lift, then lowers slowly."""
import math, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rig import L, P, along, joint, trunk, slab, line, write
import importlib.util
_spec = importlib.util.spec_from_file_location("crunch", os.path.join(os.path.dirname(os.path.abspath(__file__)),
                                                                      "crunch.py"))
cr = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(cr)

DECLINE = 22                           # bench angle, head end down
PELVIS = [120, 124, 0]
TORSO_START, TORSO_END = 180 - DECLINE, 180 + 20
THIGH, SHIN, FOOT = -34, 78, -12       # thighs up the bench, knees over its top, feet hooked forward
OFF = 9                                # bench surface below the body's centre line


def pose(torso):
    p = trunk(PELVIS, torso, head_ang=torso + (14 if torso < 180 else 22))
    cr.temples(p, torso)
    for s, k in (("L", 1), ("R", -1)):
        p["knee" + s] = P(p["hip" + s], THIGH, L["thigh"])
        p["ankle" + s] = P(p["knee" + s], SHIN, L["shin"])
        p["toe" + s] = P(p["ankle" + s], FOOT, L["foot"])
    return p


def norm_down(ang):                    # unit normal of a body segment at angle `ang`, pointing to the floor side
    a = math.radians(ang + 90)
    n = [math.cos(a), math.sin(a)]
    return n if n[1] > 0 else [-n[0], -n[1]]


start, end = pose(TORSO_START), pose(TORSO_END)
for k in ("pelvis", "hipL", "hipR", "kneeL", "ankleL", "toeL", "kneeR", "ankleR", "toeR"):
    end[k] = list(start[k])

pv, kn, an = start["pelvis"], start["kneeL"], start["ankleL"]
head_end = P(pv, TORSO_START, 70)
nt, nh = norm_down(TORSO_START), norm_down(THIGH)
a = [head_end[0] + nt[0] * OFF, head_end[1] + nt[1] * OFF]
b = [pv[0] + (nt[0] + nh[0]) / 2 * OFF, pv[1] + (nt[1] + nh[1]) / 2 * OFF]
c = [kn[0] + nh[0] * OFF - 4, kn[1] + nh[1] * OFF]
roller = [an[0] + 6, an[1] - 6]
props = [slab([a, b, c], -12, 12, 8),                                          # bench and thigh pad
         line([[a[0] + 8, a[1] + 4, 0], [a[0] + 8, 181, 0]], 5),                # low leg
         line([[a[0] - 6, 181, 0], [a[0] + 22, 181, 0]], 5),
         line([[c[0] - 4, c[1] + 4, 0], [c[0] + 6, 181, 0]], 5),                # high leg
         line([[c[0] - 10, 181, 0], [c[0] + 22, 181, 0]], 5),
         line([[c[0] + 2, c[1] + 10, 0], [roller[0], roller[1] + 2, 0]], 4),    # roller arm
         line([[roller[0], roller[1], -14], [roller[0], roller[1], 14]], 9)]    # rollers over the feet
write("decline-crunch", start, end, props, {"type": "none"}, tempo=2.8, yaw=340)
