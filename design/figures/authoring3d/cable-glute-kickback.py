"""Cable glute kickback: standing, facing a cable column, leaning in with both hands on the frame. An ankle strap
on the near (left) ankle runs to the low pulley in front. The left leg goes from under the hip, knee soft, back
and up until the thigh is in line with the leaning torso; the right leg stands."""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rig import L, P, along, joint, trunk, line, slab, write

PELVIS = [102, 106, 0]
TORSO = -59                          # leaning in toward the column
POST_X = 164
PULLEY = [POST_X - 5, 170, 0]


def pose(thigh, shin):
    p = trunk(PELVIS, TORSO)
    # standing leg (far)
    p["ankleR"] = [108, 177, -8]
    p["toeR"] = [120.4, 179, -8]
    p["kneeR"] = joint(p["hipR"], p["ankleR"], L["thigh"], L["shin"], [1, 0, 0])
    # working leg (near) with the strap
    p["kneeL"] = P(p["hipL"], thigh, L["thigh"])
    p["ankleL"] = P(p["kneeL"], shin, L["shin"])
    p["toeL"] = P(p["ankleL"], shin - 85, L["foot"])
    for s, k in (("L", 1), ("R", -1)):
        hand = [POST_X - 4, 86, 5 * k]
        p["elbow" + s] = joint(p["shoulder" + s], hand, L["upper"], L["fore"], [0, 1, 0.6 * k])
        p["hand" + s] = hand
    return p


start = pose(98, 104)                # under the hip, knee soft, foot just off the floor
end = pose(147, 139)                 # back and up, thigh a little past the line of the leaning torso
for k in start:
    if not k.endswith("L") or k in ("shoulderL", "hipL", "elbowL", "handL"):
        end[k] = start[k]
props = [line([[POST_X, 26, 0], [POST_X, 181, 0]], 7),
         slab([[POST_X - 14, 181], [POST_X + 14, 181]], -18, 18, 4),
         line([[POST_X, PULLEY[1], 0], [PULLEY[0], PULLEY[1], 0]], 5)]
load = {"type": "cable", "anchor": PULLEY, "handle": "grip", "at": "ankleL"}
write("cable-glute-kickback", start, end, props, load, tempo=2.6)
