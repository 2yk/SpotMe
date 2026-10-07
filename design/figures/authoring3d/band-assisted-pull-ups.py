"""Band-assisted pull-ups: front view, a long band looped over the bar and under the feet, legs straight."""
import os, sys, math
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rig import L, along, joint, trunk, write, line

BAR_Y = 26
HANDS = {"L": [60, BAR_Y, 0], "R": [140, BAR_Y, 0]}
LEFT = (-1, 0, 0)
KNEE_Z = 17                    # knees a little forward, ankles back under the pelvis: the hang is vertical


def pose(pelvis, lean):
    p = trunk(pelvis, -90, out=lean, left=LEFT)
    for s, sx in (("L", -1), ("R", 1)):
        hand = HANDS[s]
        p["elbow" + s] = joint(p["shoulder" + s], hand, L["upper"], L["fore"], [sx, 0, 0.35])
        p["hand" + s] = list(hand)
        hip = p["hip" + s]
        knee = [hip[0] + sx * 1.5, 0, hip[2] + KNEE_Z]
        knee[1] = hip[1] + math.sqrt(L["thigh"] ** 2 - 1.5 ** 2 - KNEE_Z ** 2)
        ankle = [knee[0] + sx * 1.5, 0, pelvis[2]]
        ankle[1] = knee[1] + math.sqrt(L["shin"] ** 2 - 1.5 ** 2 - (knee[2] - ankle[2]) ** 2)
        p["knee" + s], p["ankle" + s] = knee, ankle
        p["toe" + s] = along(ankle, [0, 0.25, 1], L["foot"])
    return p


start = pose([100, 121.6, 0], 0)
end = pose([100, 82, -2], -5)
props = [line([[38, BAR_Y, 0], [162, BAR_Y, 0]], 7)]
load = [{"type": "band", "anchor": [round(start["ankle" + s][0], 1), BAR_Y, 0], "handle": "grip", "at": "ankle" + s}
        for s in ("L", "R")]
write("band-assisted-pull-ups", start, end, props, load, tempo=3.0, view="front", floor=193)
