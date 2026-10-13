"""Iso-lateral row (plate-loaded, Hammer Strength type): seated, chest on an angled pad; each handle sits on its own
lever hung from a pivot in front and above, with a plate on a horn just past the handle. The arms work on their
own: shown alternating, one rows while the other reaches, so it reads apart from the stack machine row."""
import os, sys, math
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rig import L, P, along, joint, trunk, mirror, slab, line, write

PELVIS = [62, 140, 0]
TORSO = -78                             # leaning onto the angled chest pad
HAND_Z = 21
REACH = [116, 116]                      # arm long, handle low and ahead
PULL = [84, 106]                        # elbow back past the torso, handle by the ribs
_m = [(REACH[0] + PULL[0]) / 2, (REACH[1] + PULL[1]) / 2]
_d = [REACH[0] - PULL[0], REACH[1] - PULL[1]]
_n = [-_d[1], _d[0]]
if _n[1] > 0:
    _n = [-_n[0], -_n[1]]
_k = 74 / math.hypot(*_n)
PIVOT = [_m[0] + _n[0] * _k, _m[1] + _n[1] * _k, 26]   # on the bisector: each lever keeps its length
PLATE = [9, 13, 9]                       # plate horn: past the handle, outside it


def arm(p, side, hand):
    s = 1 if side == "L" else -1
    p["hand" + side] = [hand[0], hand[1], s * HAND_Z]
    p["elbow" + side] = joint(p["shoulder" + side], p["hand" + side], L["upper"], L["fore"], [-1, 0.5, s * 0.3])


def pose(left, right, s=None):
    p = trunk(PELVIS, TORSO, head_ang=-84)
    if s:
        for k in ("kneeL", "ankleL", "toeL"):
            p[k] = s[k]
    else:
        p["ankleL"] = [100, 175, 11]
        p["toeL"] = P(p["ankleL"], 5, L["foot"])
        p["kneeL"] = joint(p["hipL"], p["ankleL"], L["thigh"], L["shin"], [1, -1, 0])
    mirror(p)
    arm(p, "L", left)
    arm(p, "R", right)
    return p


start = pose(REACH, PULL)
end = pose(PULL, REACH, start)
for k in ("kneeR", "ankleR", "toeR"):
    end[k] = start[k]
neck = start["neck"]
a = math.radians(TORSO)
pad = [[neck[0] + 9 - 6, neck[1] + 8], [neck[0] + 9 + 30 * math.cos(a + math.pi) * -0.25, neck[1] + 40]]
props = [slab([[42, 148], [84, 148]], -14, 14, 7),                      # seat
         line([[64, 151, 0], [64, 181, 0]], 5),                         # seat post
         slab([[neck[0] + 12, 88], [neck[0] + 20, 124]], -9, 9, 9),     # angled chest pad
         line([[neck[0] + 20, 122, 0], [150, 122, 0]], 5),              # pad arm
         line([[150, 181, 0], [150, PIVOT[1], 0], [PIVOT[0], PIVOT[1], 0]], 6),   # front post and top arm
         line([[PIVOT[0], PIVOT[1], -PIVOT[2]], [PIVOT[0], PIVOT[1], PIVOT[2]]], 5),
         slab([[42, 181], [158, 181]], -24, 24, 4)]
load = [{"type": "machine", "grips": ["handL", "handR"],
         "pivots": [PIVOT, [PIVOT[0], PIVOT[1], -PIVOT[2]]], "axis": [0.25, 1, 0], "length": 14},
        {"type": "held", "kind": "plate", "at": "handL", "offset": PLATE, "axis": [0, 0, 1]},
        {"type": "held", "kind": "plate", "at": "handR", "offset": [PLATE[0], PLATE[1], -PLATE[2]], "axis": [0, 0, 1]}]
write("iso-lateral-row", start, end, props, load, tempo=3.0, yaw=35)
