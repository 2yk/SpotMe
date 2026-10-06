"""Band-assisted pull-ups: front view, a long band looped over the bar and under the feet, legs straight."""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rig import L, along, joint, trunk, write, line

BAR_Y = 26
HANDS = {"L": [60, BAR_Y, 0], "R": [140, BAR_Y, 0]}
LEFT = (-1, 0, 0)
LEG = [0, 0.906, 0.423]        # straight legs, a little in front (standing in the band, inside the box)


def pose(pelvis, lean):
    p = trunk(pelvis, -90, out=lean, left=LEFT)
    for s, sx in (("L", -1), ("R", 1)):
        hand = HANDS[s]
        p["elbow" + s] = joint(p["shoulder" + s], hand, L["upper"], L["fore"], [sx, 0, 0.35])
        p["hand" + s] = list(hand)
        p["knee" + s] = along(p["hip" + s], [sx * 0.04] + LEG[1:], L["thigh"])
        p["ankle" + s] = along(p["knee" + s], [sx * 0.04] + LEG[1:], L["shin"])
        p["toe" + s] = along(p["ankle" + s], [0, 0.25, 1], L["foot"])
    return p


start = pose([100, 121.6, 0], 0)
end = pose([100, 82, -4], -9.2)
props = [line([[38, BAR_Y, 0], [162, BAR_Y, 0]], 7)]
load = [{"type": "band", "anchor": [round(start["ankle" + s][0], 1), BAR_Y, 0], "handle": "grip", "at": "ankle" + s}
        for s in ("L", "R")]
write("band-assisted-pull-ups", start, end, props, load, tempo=3.0, view="front", floor=193)
