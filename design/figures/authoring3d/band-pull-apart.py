"""Band pull-apart: standing, front view; arms straight out in front at shoulder height holding a light band,
then pulled apart into a T until the band touches the chest. The band is two dashed `band` pieces from a shared
middle point to each hand (the band load needs a fixed anchor); seen from the front it is one straight band."""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rig import L, P, along, joint, trunk, mirror, slab, line, write

PELVIS = [100, 103, 0]
LEFT = [-1, 0, 0]
HAND_START = [-13, 4, 48]       # from the neck: in front, a little inside shoulder width
HAND_END = [-63, 6, 9]          # from the neck: out wide in a T, band across the chest
MID_Z = 42                      # the band's middle (fixed): between its start and end depth


def pose(h, bend):
    p = trunk(PELVIS, -90, left=LEFT)
    for s, dx in (("L", -1), ("R", 1)):
        p["knee" + s] = P(p["hip" + s], 90 - 2 * dx, L["thigh"])
        p["ankle" + s] = P(p["knee" + s], 90 + 2 * dx, L["shin"])
        p["toe" + s] = along(p["ankle" + s], [-0.25 * -dx, 0, 1], L["foot"])
    n = p["neck"]
    p["handL"] = [n[0] + h[0], n[1] + h[1], h[2]]
    p["elbowL"] = joint(p["shoulderL"], p["handL"], L["upper"], L["fore"], bend)
    p["handR"] = [2 * PELVIS[0] - p["handL"][0], p["handL"][1], p["handL"][2]]
    e = p["elbowL"]
    p["elbowR"] = [2 * PELVIS[0] - e[0], e[1], e[2]]
    return p


start = pose(HAND_START, [-1, 0.3, 0])
end = pose(HAND_END, [0, 0.4, -1])
hy = start["handL"][1]
MID = [PELVIS[0], hy, MID_Z]
load = [{"type": "band", "handle": "grip", "at": "handL", "anchor": MID},
        {"type": "band", "handle": "grip", "at": "handR", "anchor": MID}]
write("band-pull-apart", start, end, [], load, tempo=2.6, view="front", yaw=-40)
