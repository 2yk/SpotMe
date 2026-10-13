"""Barbell upright row: standing, side view, overhand grip about shoulder width. The bar rises close to the body
from the thighs to the upper chest, elbows leading up and out to shoulder height, above the hands. The bar is
longer than the usual 80 so its plates sit outside the raised elbows instead of covering them."""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rig import L, P, along, joint, trunk, mirror, slab, line, write

PELVIS = [96, 103, 0]


def base():
    p = trunk(PELVIS, -90)
    p["kneeL"] = P(p["hipL"], 88, L["thigh"])
    p["ankleL"] = P(p["kneeL"], 92, L["shin"])
    p["toeL"] = P(p["ankleL"], 0, L["foot"])
    return p


# end: elbow out to the side at shoulder height, forearm angled down and in to the bar at the upper chest
end = base()
end["elbowL"] = along(end["shoulderL"], [0.22, -0.04, 1], L["upper"])
end["handL"] = along(end["elbowL"], [108 - end["elbowL"][0], 66 - end["elbowL"][1], 17 - end["elbowL"][2]], L["fore"])
HZ = end["handL"][2]               # grip a little wider than the shoulders, the same in both poses
mirror(end)

# start: arms hanging, bar in front of the thighs
start = base()
start["handL"] = [104, 104, HZ]
start["elbowL"] = joint(start["shoulderL"], start["handL"], L["upper"], L["fore"], [0, 0, 1])
mirror(start)
write("barbell-upright-row", start, end, [], {"type": "bar", "length": 104}, tempo=2.6, yaw=62)
