"""Lean-away lateral raise: front view. Feet together beside an upright on the viewer's right; the right hand holds
the upright at chest height with a straight arm and the whole body leans away from it to the viewer's left. One
dumbbell in the left hand, raised from in front of the hip (across the body) out to shoulder height.
One dumbbell in one hand has no load of its own: built as in suitcase-carry, a machine grip (the handle, front
to back) with a wheel disc (smaller than a plate) at each end."""
import os, sys, math
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rig import L, P, along, joint, trunk, mirror, slab, line, write

LEAN = 14                         # degrees the body leans to the viewer's left
FEET_X = 118
POST = [150, 0]                   # upright x, z


def pose(upper, fore, out_u, out_f):
    up = -90 - LEAN
    # legs straight from the feet, the body one line leaning left
    ank = {"L": [FEET_X - 6, 175, 0], "R": [FEET_X + 6, 175, 0]}
    hipmid = P([FEET_X, 175, 0], up, L["thigh"] + L["shin"])
    p = trunk(hipmid, up, head_ang=up + 6, left=[-math.cos(math.radians(LEAN)), -math.sin(math.radians(LEAN)), 0])
    for s, dx in (("L", -1), ("R", 1)):
        a = ank[s]
        p["ankle" + s] = a
        p["toe" + s] = along(a, [dx * 0.2, 0, 1], L["foot"])
        p["knee" + s] = joint(p["hip" + s], a, L["thigh"], L["shin"], [0, 0, 1])
    # right hand on the upright, arm straight
    p["handR"] = [POST[0] - 3, 82, POST[1]]
    p["elbowR"] = joint(p["shoulderR"], p["handR"], L["upper"], L["fore"], [0, 1, 0])
    # working arm (viewer's left)
    p["elbowL"] = P(p["shoulderL"], upper, L["upper"], out_u)
    p["handL"] = P(p["elbowL"], fore, L["fore"], out_f)
    return p


start = pose(78, 72, 18, 26)        # dumbbell in front of the hip, a little across the body
end = pose(180 - LEAN + 4, 166 - LEAN, 6, 12)   # out to the side at shoulder height, elbow soft
for k in list(start):
    if k not in ("elbowL", "handL"):
        end[k] = start[k]
props = [line([[POST[0], 181, POST[1]], [POST[0], 12, POST[1]]], 7),
         slab([[POST[0] - 12, 181], [POST[0] + 12, 181]], -12, 12, 4)]
load = [{"type": "machine", "grips": ["handL"], "axis": [0, 0, 1], "length": 18},
        {"type": "held", "kind": "wheel", "at": "handL", "offset": [0, 0, 7], "axis": [0, 0, 1]},
        {"type": "held", "kind": "wheel", "at": "handL", "offset": [0, 0, -7], "axis": [0, 0, 1]}]
write("lean-away-lateral-raise", start, end, props, load, tempo=2.6, view="front", yaw=-30)
