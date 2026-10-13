"""Band lateral raise: front view, standing on the middle of a band, feet hip-width, a slight forward lean. Each
hand holds one end; arms from hanging at the sides to straight out at shoulder height. A band per hand, from
under the same-side foot (dashed volt)."""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rig import L, P, along, joint, trunk, mirror, slab, line, write

PELVIS = [100, 103, 0]
LEFT = [-1, 0, 0]
LEAN = 8                          # degrees the torso tips toward the viewer


def pose(upper, fore, out_u, out_f):
    p = trunk(PELVIS, -90, out=LEAN, left=LEFT)
    for s, dx in (("L", -1), ("R", 1)):
        p["knee" + s] = P(p["hip" + s], 90 - 3 * dx, L["thigh"])
        p["ankle" + s] = P(p["knee" + s], 90 + 1 * dx, L["shin"])
        p["toe" + s] = along(p["ankle" + s], [-0.25 * -dx, 0, 1], L["foot"])
    p["elbowL"] = P(p["shoulderL"], upper, L["upper"], out_u)
    p["handL"] = P(p["elbowL"], fore, L["fore"], out_f)
    p["elbowR"] = P(p["shoulderR"], 180 - upper, L["upper"], out_u)
    p["handR"] = P(p["elbowR"], 180 - fore, L["fore"], out_f)
    return p


start = pose(98, 94, 10, 16)        # hanging beside the thighs, a little in front
end = pose(180, 171, 12, 18)        # upper arm level with the shoulder, hand just below the elbow
for k in list(start):
    if k not in ("elbowL", "handL", "elbowR", "handR"):
        end[k] = start[k]
aL, aR = start["ankleL"], start["ankleR"]
load = [{"type": "band", "handle": "grip", "at": "handL", "anchor": [aL[0] + 1, 179, aL[2] + 5]},
        {"type": "band", "handle": "grip", "at": "handR", "anchor": [aR[0] - 1, 179, aR[2] + 5]}]
write("band-lateral-raise", start, end, [], load, tempo=2.6, view="front")
