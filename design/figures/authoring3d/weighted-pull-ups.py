"""Weighted pull-ups: front view, full hang to chin over the bar, a plate hanging from a belt below the hips."""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rig import L, along, joint, trunk, write, line

BAR_Y = 26
HANDS = {"L": [60, BAR_Y, 0], "R": [140, BAR_Y, 0]}
LEFT = (-1, 0, 0)


def pose(pelvis, lean):
    """lean: torso tilt toward +z in degrees (negative leans the chest back to clear the bar)."""
    p = trunk(pelvis, -90, out=lean, left=LEFT)
    for s, sx in (("L", -1), ("R", 1)):
        hand = HANDS[s]
        p["elbow" + s] = joint(p["shoulder" + s], hand, L["upper"], L["fore"], [sx, 0, 0.35])
        p["hand" + s] = list(hand)
        knee = along(p["hip" + s], [sx * 0.03, 1, 0], L["thigh"])       # thighs hang, knees a little bent
        ankle = along(knee, [-sx * 0.05, 0.62, -0.78], L["shin"])        # feet back
        p["knee" + s], p["ankle" + s] = knee, ankle
        p["toe" + s] = along(ankle, [0, 0.88, -0.46], L["foot"])
    return p


start = pose([100, 121.6, 0], 0)
end = pose([100, 82, -4], -9.2)
props = [line([[38, BAR_Y, 0], [162, BAR_Y, 0]], 7)]
load = {"type": "held", "kind": "plate", "at": "pelvis", "offset": [0, 29, 7], "axis": [0.6, 0, 1]}
write("weighted-pull-ups", start, end, props, load, tempo=3.0, view="front", floor=193)
