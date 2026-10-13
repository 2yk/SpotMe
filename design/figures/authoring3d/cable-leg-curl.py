"""Standing cable leg curl: facing a low pulley, both hands on the frame, standing on the far leg. A strap on the
near ankle; the thigh stays still under the hip and the heel curls up toward the glute against the cable."""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rig import L, P, along, joint, trunk, mirror, slab, line, write

PELVIS = [104, 105, 0]
LEAN = -78                       # torso leaning a little toward the frame
POST_X = 150
GRIP_Y = 86
ANCHOR = [POST_X - 4, 172, 8]    # low pulley on the column


def pose(shin):
    p = trunk(PELVIS, LEAN)
    # standing leg (far): straight down, foot flat
    p["ankleR"] = [PELVIS[0] + 2, 177, -8]
    p["toeR"] = P(p["ankleR"], 0, L["foot"])
    p["kneeR"] = joint(p["hipR"], p["ankleR"], L["thigh"], L["shin"], [1, 0, 0])
    # working leg (near): thigh still, a touch forward; the shin curls back
    p["kneeL"] = P(p["hipL"], 86, L["thigh"])
    p["kneeL"][2] = 8
    p["ankleL"] = P(p["kneeL"], shin, L["shin"])
    p["toeL"] = P(p["ankleL"], shin - 100, L["foot"])
    for s, z in (("L", 12), ("R", -12)):
        h = [POST_X - 5, GRIP_Y, z]
        p["hand" + s] = h
        p["elbow" + s] = joint(p["shoulder" + s], h, L["upper"], L["fore"], [0, 1, z / 12 * 0.4])
    return p


start, end = pose(88), pose(-158)      # shin hanging (foot just off the floor), then heel up behind
for k in ("kneeR", "ankleR", "toeR", "elbowL", "handL", "elbowR", "handR", "kneeL"):
    end[k] = list(start[k])
props = [line([[POST_X + 6, 181, 0], [POST_X + 6, 22, 0]], 6),                      # cable column
         line([[POST_X - 5, GRIP_Y, -18], [POST_X - 5, GRIP_Y, 18], [POST_X + 6, GRIP_Y, 18]], 5),  # handle frame
         line([[POST_X - 5, GRIP_Y, -18], [POST_X + 6, GRIP_Y, -18]], 5),
         line([[POST_X + 6, ANCHOR[1], 0], [ANCHOR[0], ANCHOR[1], ANCHOR[2]]], 5),   # pulley
         line([[ANCHOR[0], ANCHOR[1] - 3, ANCHOR[2]], [ANCHOR[0], ANCHOR[1] + 3, ANCHOR[2]]], 8),
         slab([[POST_X - 6, 181], [POST_X + 20, 181]], -16, 16, 4)]
load = {"type": "cable", "handle": "grip", "at": "ankleL", "anchor": ANCHOR}
write("cable-leg-curl", start, end, props, load, tempo=2.6)
