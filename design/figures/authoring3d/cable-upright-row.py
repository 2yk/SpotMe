"""Cable upright row: standing facing a low pulley, side view, a rope held with the hands apart. The rope rises
close to the body from the thighs to chest height, elbows leading up and out to about shoulder height."""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rig import L, P, along, joint, trunk, mirror, slab, line, write

PELVIS = [88, 103, 0]
HZ = 7                             # rope ends: hands a little apart
ANCHOR = [146, 172, 0]             # low pulley in front of the feet


def pose(hand_xy, bend):
    p = trunk(PELVIS, -90)
    p["kneeL"] = P(p["hipL"], 88, L["thigh"])
    p["ankleL"] = P(p["kneeL"], 92, L["shin"])
    p["toeL"] = P(p["ankleL"], 0, L["foot"])
    p["handL"] = [hand_xy[0], hand_xy[1], HZ]
    p["elbowL"] = joint(p["shoulderL"], p["handL"], L["upper"], L["fore"], bend)
    return mirror(p)


start = pose([95, 103], [0, 0, 1])           # arms hanging, rope in front of the thighs
end = pose([101, 74], [-0.2, -1, 1.4])      # rope at chest height, elbows out at about shoulder height
for k in list(start):
    if k not in ("elbowL", "handL", "elbowR", "handR"):
        end[k] = start[k]
props = [line([[162, 181, 0], [162, 30, 0]], 6),                       # column
         line([[162, ANCHOR[1], 0], ANCHOR], 8),                       # low pulley arm
         slab([[152, 181], [172, 181]], -12, 12, 4)]
write("cable-upright-row", start, end, props, {"type": "cable", "handle": "rope", "anchor": ANCHOR},
      tempo=2.6, yaw=55)
