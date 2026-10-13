"""Scapular pull-ups: front view, dead hang on a wide bar with the arms straight the whole time. Start: shoulders
shrugged up to the ears; end: shoulders pulled down and back, which lifts the body a few units, chest up."""
import os, sys, math
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rig import L, along, joint, trunk, write, line

BAR_Y = 26
HANDS = {"L": [60, BAR_Y, 0], "R": [140, BAR_Y, 0]}
ARM = L["upper"] + L["fore"] - 1.5                 # arms straight (a hair of bend so the elbow has a direction)


def pose(sh_up, lean):
    """sh_up: shoulder elevation in degrees above the neck line (shrug +, depressed -); lean: chest tilt (z)."""
    a, o = math.radians(sh_up), math.radians(lean)
    off = [15 * math.cos(a), -15 * math.sin(a)]
    # neck height so that each shoulder sits ARM from its hand (straight arms)
    sx_ = 100 - off[0]
    dy = math.sqrt(ARM ** 2 - (sx_ - HANDS["L"][0]) ** 2)
    neck_y = BAR_Y + dy - off[1]
    neck = [100, neck_y, 0]
    pelvis = [100, neck_y + 50 * math.cos(o), -50 * math.sin(o)]
    p = trunk(pelvis, -90, out=lean, left=(-1, 0, 0))
    shift = [neck[i] - p["neck"][i] for i in range(3)]
    for k in list(p):
        p[k] = [p[k][i] + shift[i] for i in range(3)]
    n = p["neck"]
    p["shoulderL"] = [n[0] - off[0], n[1] + off[1], n[2]]
    p["shoulderR"] = [n[0] + off[0], n[1] + off[1], n[2]]
    p["head"] = along(n, [0, -1, 0.12 if lean else 0], L["head"])
    for s, sx in (("L", -1), ("R", 1)):
        p["elbow" + s] = joint(p["shoulder" + s], HANDS[s], L["upper"], L["fore"], [sx, 0, 0.3])
        p["hand" + s] = list(HANDS[s])
        knee = along(p["hip" + s], [sx * 0.03, 1, 0.03], L["thigh"])
        ankle = along(knee, [-sx * 0.05, 0.62, -0.78], L["shin"])
        p["knee" + s], p["ankle" + s] = knee, ankle
        p["toe" + s] = along(ankle, [0, 0.88, -0.46], L["foot"])
    return p


start = pose(34, 0)            # passive hang: shoulders up by the ears
end = pose(-12, 6)             # shoulders down and back, chest up a little
for k in ("elbowL", "elbowR"):  # the shoulders barely travel, so the elbows stay put
    end[k] = list(start[k])
write("scapular-pull-ups", start, end, [line([[38, BAR_Y, 0], [162, BAR_Y, 0]], 7)], None,
      tempo=3.0, view="front", floor=200)
