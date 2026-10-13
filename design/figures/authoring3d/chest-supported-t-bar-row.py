"""Chest-supported T-bar row: chest down on an incline pad, feet on the foot plate, arms hanging to the wide
handles at the front end of a plate-loaded lever that pivots at the floor behind the feet; row the lever up to
the lower chest. The lever and the plate on its nose tell it apart from the chest-supported DB row."""
import os, sys, math
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rig import L, P, along, joint, trunk, mirror, slab, line, write

PELVIS = [74, 108, 0]
INCLINE = 38                    # torso and pad angle from the floor
PAD = 10
HAND_Z = 20                     # wide handles across the lever's nose
LEVER_PIVOT = [20, 172, 0]
KNEE_BEND = [1, 0.2, 0]


def pose(lift):
    p = trunk(PELVIS, -INCLINE, head_ang=-INCLINE + 8)
    p["ankleL"] = [58, 163, 11]                 # standing on the raised foot plate
    p["toeL"] = P(p["ankleL"], 8, L["foot"])
    p["kneeL"] = joint(p["hipL"], p["ankleL"], L["thigh"], L["shin"], KNEE_BEND)
    sh = p["shoulderL"]
    if lift:
        R = math.dist(LEVER_PIVOT[:2], HANG[:2])
        y = HANG[1] - lift
        x = LEVER_PIVOT[0] + math.sqrt(R * R - (y - LEVER_PIVOT[1]) ** 2)
        hand = [x, y, HAND_Z]
        p["elbowL"] = joint(sh, hand, L["upper"], L["fore"], [-0.7, -1, 0.35])
    else:
        hand = list(HANG)
        p["elbowL"] = joint(sh, hand, L["upper"], L["fore"], [-1, 0, 0.2])
    p["handL"] = hand
    return mirror(p)


_sh = trunk(PELVIS, -INCLINE)["shoulderL"]
HANG = [_sh[0] + 2, _sh[1] + math.sqrt(51 ** 2 - (HAND_Z - 15) ** 2 - 4), HAND_Z]   # arms straight down
start, end = pose(0), pose(28)
for k in ("ankleL", "toeL", "kneeL", "ankleR", "toeR", "kneeR"):
    end[k] = start[k]
a = math.radians(INCLINE)
n = [math.sin(a) * PAD, math.cos(a) * PAD]
pad0 = [PELVIS[0] + n[0] + 8 * math.cos(a), PELVIS[1] + n[1] - 8 * math.sin(a)]
pad1 = [PELVIS[0] + n[0] + 46 * math.cos(a), PELVIS[1] + n[1] - 46 * math.sin(a)]
mid = [(pad0[0] + pad1[0]) / 2, (pad0[1] + pad1[1]) / 2 + 4]
props = [slab([pad0, pad1], -11, 11, 8),                                    # chest pad
         line([[mid[0], mid[1], 0], [mid[0] + 18, 181, 0]], 5),            # pad post, angled forward clear of the lever
         slab([[46, 169], [74, 169]], -18, 18, 5),                         # foot plate
         line([[60, 172, 0], [60, 181, 0]], 4),
         line([[LEVER_PIVOT[0], 181, 0], LEVER_PIVOT], 6),                  # pivot post
         slab([[12, 181], [150, 181]], -20, 20, 4)]                        # base
load = [{"type": "pad", "at": ["handL", "handR"], "length": 2 * HAND_Z + 8, "w": 5, "pivot": LEVER_PIVOT},
        {"type": "held", "kind": "plate", "at": "hands", "offset": [9, 3, 0], "axis": [1, -0.3, 0]}]
write("chest-supported-t-bar-row", start, end, props, load, tempo=2.8, yaw=-25)
