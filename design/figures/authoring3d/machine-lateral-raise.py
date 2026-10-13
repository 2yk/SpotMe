"""Machine lateral raise: front view, seated, chest against a small pad in front, elbows bent about 90 degrees with
the forearms forward. A pad on the outside of each upper arm near the elbow, on a lever from a pivot just in
front of the shoulder; the elbows push the pads out and up to shoulder height.
Arm pads: `machine` grips at the elbows (axis front to back, seen end-on) (no levers: a lever from the shoulder pivot lies on the upper arm and greys it out)."""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rig import L, P, along, joint, trunk, mirror, slab, line, write

PELVIS = [100, 136, 0]
LEFT = [-1, 0, 0]
PZ = 4                            # pivots this far in front of the shoulders


def legs(p):
    for s, dx in (("L", -1), ("R", 1)):
        hip = p["hip" + s]
        p["ankle" + s] = [hip[0] + dx * 6, 175, hip[2] + 36]
        p["toe" + s] = along(p["ankle" + s], [dx * 0.2, 0, 1], L["foot"])
        p["knee" + s] = joint(hip, p["ankle" + s], L["thigh"], L["shin"], [0, -1, 1])


def pose(upper):
    p = trunk(PELVIS, -90, left=LEFT)
    legs(p)
    p["elbowL"] = P(p["shoulderL"], upper, L["upper"])
    p["elbowR"] = P(p["shoulderR"], 180 - upper, L["upper"])
    for s in "LR":                                    # forearms forward and a little up, hands on the handles
        e = p["elbow" + s]
        p["hand" + s] = along(e, [0, -0.25, 1], L["fore"])
    return p


start = pose(104)                 # upper arms down by the sides, a little out
end = pose(178)                   # upper arms level with the shoulders
for k in list(start):
    if k not in ("elbowL", "handL", "elbowR", "handR"):
        end[k] = start[k]
sL, sR = start["shoulderL"], start["shoulderR"]
PIV = [[sL[0], sL[1], PZ], [sR[0], sR[1], PZ]]
BZ = -24                          # frame behind the back
props = [slab([[86, 145], [114, 145]], -16, 14, 7),                 # seat
         line([[100, 148, -2], [100, 181, -2]], 5),                  # seat post
         slab([[93, 98], [107, 98], [107, 124], [93, 124]], 12, 14, 4),  # chest pad, small, in front of the sternum
         line([[100, 124, 13], [100, 142, 13]], 5),                  # chest pad support down to the seat
         line([[100, 181, BZ], [100, sL[1], BZ]], 6),                # rear post
         line([PIV[0], [sL[0], sL[1], BZ], [sR[0], sR[1], BZ], PIV[1]], 5),   # pivot arms over the shoulders
         slab([[80, 181], [120, 181]], BZ - 8, 18, 4)]               # base
load = {"type": "machine", "grips": ["elbowL", "elbowR"], "axis": [0, 0, 1], "length": 16}
write("machine-lateral-raise", start, end, props, load, tempo=2.6, view="front", yaw=-15)
