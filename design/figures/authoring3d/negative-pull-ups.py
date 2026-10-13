"""Negative pull-ups: front view. Starts at the top, chin over the bar, feet still on a tall box behind (stepped
up), then lowers slowly to a full hang, legs down in front of the box. The box tells it from a pull-up."""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rig import L, along, joint, trunk, write, line, slab

BAR_Y = 26
HANDS = {"L": [60, BAR_Y, 0], "R": [140, BAR_Y, 0]}
LEFT = (-1, 0, 0)
BOX_Y = 133                    # box top, behind the body


def pose(pelvis, lean, shin, foot):
    p = trunk(pelvis, -90, out=lean, left=LEFT)
    for s, sx in (("L", -1), ("R", 1)):
        hand = HANDS[s]
        p["elbow" + s] = joint(p["shoulder" + s], hand, L["upper"], L["fore"], [sx, 0, 0.35])
        p["hand" + s] = list(hand)
        knee = along(p["hip" + s], [sx * 0.03, 1, 0.12], L["thigh"])
        ankle = along(knee, [-sx * 0.04] + shin, L["shin"])
        p["knee" + s], p["ankle" + s] = knee, ankle
        p["toe" + s] = along(ankle, foot, L["foot"])
    return p


start = pose([100, 82, -4], -9.2, [0.15, -0.99], [0, 0.3, -0.95])        # top: shins back, feet on the box
end = pose([100, 121.6, 0], 0, [0.9, -0.44], [0, 0.6, 0.8])               # full hang, legs off the box
props = [line([[38, BAR_Y, 0], [162, BAR_Y, 0]], 7),
         slab([[76, 206], [76, BOX_Y], [124, BOX_Y], [124, 206]], -52, -20, 5)]
for z in (-20, -52):                                      # front and back faces: a fat line fills each
    props.append(line([[89, BOX_Y + 13, z], [89, 206 - 13, z], [111, 206 - 13, z], [111, BOX_Y + 13, z]], 26))
write("negative-pull-ups", start, end, props, None, tempo=3.2, view="front", floor=206, yaw=30)
