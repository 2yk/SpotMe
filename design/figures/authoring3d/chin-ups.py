"""Chin-ups: front view, underhand at shoulder width (narrower than pull-ups), full hang to chest at the bar;
elbows travel forward of the body, not out to the sides."""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rig import L, along, joint, trunk, write, line

BAR_Y = 26
HANDS = {"L": [78, BAR_Y, 0], "R": [122, BAR_Y, 0]}     # shoulder width
LEFT = (-1, 0, 0)


def pose(pelvis, lean, bend):
    p = trunk(pelvis, -90, out=lean, left=LEFT)
    for s, sx in (("L", -1), ("R", 1)):
        hand = HANDS[s]
        p["elbow" + s] = joint(p["shoulder" + s], hand, L["upper"], L["fore"], [sx * 0.25, bend, 1])
        p["hand" + s] = list(hand)
        knee = along(p["hip" + s], [sx * 0.03, 1, 0], L["thigh"])
        ankle = along(knee, [-sx * 0.05, 0.62, -0.78], L["shin"])
        p["knee" + s], p["ankle" + s] = knee, ankle
        p["toe" + s] = along(ankle, [0, 0.88, -0.46], L["foot"])
    return p


start = pose([100, 126, 0], 0, 0)
end = pose([100, 79, -3], -12, 0.6)      # chest up to the bar, head back past it
props = [line([[38, BAR_Y, 0], [162, BAR_Y, 0]], 7)]
write("chin-ups", start, end, props, None, tempo=3.0, view="front", floor=200, yaw=18)
