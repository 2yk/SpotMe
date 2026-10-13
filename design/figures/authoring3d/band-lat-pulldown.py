"""Band lat pulldown: tall kneeling on the floor under a band anchored high in front. Arms reach up and
forward along the band, then the elbows pull down to the ribs, hands by the shoulders, chest up."""
import os, sys, math
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rig import L, P, along, joint, trunk, mirror, line, slab, write

PELVIS = [78, 140, 0]
REACH = -58                            # arm angle at the start: up and forward toward the anchor


def legs(p):
    p["kneeL"] = P(p["hipL"], 92, L["thigh"])           # knee on the floor under the hip
    p["kneeL"][2] = 9
    p["ankleL"] = P(p["kneeL"], 178, L["shin"])         # shin flat on the floor behind
    p["toeL"] = P(p["ankleL"], 150, L["foot"])


def top():
    p = trunk(PELVIS, -88, head_ang=-84)
    legs(p)
    p["handL"] = P(p["shoulderL"], REACH, 51)
    p["elbowL"] = joint(p["shoulderL"], p["handL"], L["upper"], L["fore"], [0, 0, 1])
    return mirror(p, 0)


def bottom(s):
    p = trunk(PELVIS, -93, head_ang=-90)
    for k in ("kneeL", "ankleL", "toeL", "hipL"):
        p[k] = s[k]
    p["handL"] = [p["neck"][0] + 10, p["neck"][1] + 2, 17]
    p["elbowL"] = joint(p["shoulderL"], p["handL"], L["upper"], L["fore"], [-0.7, 1, 0.3])
    return mirror(p, 0)


start = top()
end = bottom(start)
sh = start["shoulderL"]
ANCHOR = P([sh[0], sh[1], 0], REACH, 96)                  # on the line the hands reach along
POST_X = ANCHOR[0] + 6
props = [line([[POST_X, 181, 0], [POST_X, ANCHOR[1] - 14, 0]], 7),                 # rack post
         line([[POST_X, ANCHOR[1], 0], ANCHOR], 4),                                 # anchor strap
         slab([[POST_X - 10, 181], [POST_X + 10, 181]], -14, 14, 4)]
load = [{"type": "band", "anchor": ANCHOR, "handle": "grip", "at": h} for h in ("handL", "handR")]
write("band-lat-pulldown", start, end, props, load, tempo=2.8, yaw=25)
