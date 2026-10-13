"""Band Pallof press: standing side-on to a band looped round a rack upright at chest height; both hands on the
band's end press straight out from the sternum and back. As pallof-press, with a dashed band and a post."""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rig import L, P, along, joint, trunk, mirror, slab, line, write

PELVIS = [100, 101, 0]
HAND_Y = 72
Z_START, Z_END = 14, 46
POST = [182, 12]                       # rack upright: x, z
ANCHOR = [POST[0] - 3, HAND_Y, POST[1]]


def pose(z, bend):
    p = trunk(PELVIS, -90, left=[-1, 0, 0])
    p["ankleL"] = [88, 175, -2]
    p["toeL"] = along(p["ankleL"], [0, 0.3, 1], L["foot"])
    p["kneeL"] = joint(p["hipL"], p["ankleL"], L["thigh"], L["shin"], [0, 0, 1])
    p["handL"] = [98, HAND_Y, z]
    p["elbowL"] = joint(p["shoulderL"], p["handL"], L["upper"], L["fore"], bend)
    for k in [k for k in p if k.endswith("L")]:
        x, y, zz = p[k]
        p[k[:-1] + "R"] = [2 * PELVIS[0] - x, y, zz]
    return p


start, end = pose(Z_START, [-1, 1, 0]), pose(Z_END, [-1, 1, 0])
props = [line([[POST[0], 181, POST[1]], [POST[0], 30, POST[1]]], 7),          # the upright
         line([[POST[0] - 8, 181, POST[1]], [POST[0] + 8, 181, POST[1]]], 5)]  # its foot
write("band-pallof-press", start, end, props, {"type": "band", "handle": "grip", "at": "handL", "anchor": ANCHOR},
      tempo=2.6, view="front", yaw=52)
