"""Band curl: standing on the middle of a band, feet hip width, a band end in each hand palms up, elbows pinned;
curl from hanging to the shoulders. Each side is a band from under the foot to a handle in the hand."""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rig import L, P, along, joint, trunk, mirror, slab, line, write

PELVIS = [100, 103, 0]
YAW = 30            # turned a little toward the front so both bands show beside the legs


def pose(fore):
    p = trunk(PELVIS, -90)
    p["kneeL"] = P(p["hipL"], 88, L["thigh"])
    p["ankleL"] = P(p["kneeL"], 92, L["shin"])
    p["toeL"] = P(p["ankleL"], 0, L["foot"])
    p["elbowL"] = P(p["shoulderL"], 86, L["upper"], 8)
    p["handL"] = P(p["elbowL"], fore, L["fore"], 6)
    return mirror(p)


start = pose(84)      # hands hanging, band nearly slack
end = pose(-66)       # hands at the shoulders, band stretched
load = []
for s in "LR":
    a = start["ankle" + s]
    load.append({"type": "band", "handle": "grip", "at": "hand" + s, "anchor": [a[0] + 7, 180, a[2]]})
write("band-curl", start, end, [], load, tempo=2.8, yaw=YAW)
