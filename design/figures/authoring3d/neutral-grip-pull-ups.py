"""Neutral-grip pull-ups: front view, palms facing on two parallel handles that stick forward from the bar
frame; full hang to chin over the handles, elbows down to the ribs (in front of the body)."""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rig import L, along, joint, trunk, write, line

BAR_Y = 26
HZ = 6                                                    # hands on the front half of the handles
HANDS = {"L": [80, BAR_Y, HZ], "R": [120, BAR_Y, HZ]}
LEFT = (-1, 0, 0)


def pose(pelvis, lean, bend):
    p = trunk(pelvis, -90, out=lean, left=LEFT)
    for s, sx in (("L", -1), ("R", 1)):
        hand = HANDS[s]
        p["elbow" + s] = joint(p["shoulder" + s], hand, L["upper"], L["fore"], [sx * 0.35, bend, 1])
        p["hand" + s] = list(hand)
        knee = along(p["hip" + s], [sx * 0.03, 1, 0], L["thigh"])
        ankle = along(knee, [-sx * 0.05, 0.62, -0.78], L["shin"])
        p["knee" + s], p["ankle" + s] = knee, ankle
        p["toe" + s] = along(ankle, [0, 0.88, -0.46], L["foot"])
    return p


start = pose([100, 126, 0], 0, 0)
end = pose([100, 81, -2], -10, 0.6)
FZ, FY = -28, 10                                          # the frame bar sits above and behind the handles
props = [line([[38, FY, FZ], [162, FY, FZ]], 7)]
for x in (HANDS["L"][0], HANDS["R"][0]):                  # parallel handles hang from it and run forward
    props.append(line([[x, FY, FZ], [x, BAR_Y, FZ], [x, BAR_Y, 20]], 6))
write("neutral-grip-pull-ups", start, end, props, None, tempo=3.0, view="front", floor=200, yaw=35)
