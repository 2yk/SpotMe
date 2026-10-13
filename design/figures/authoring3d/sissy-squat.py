"""Sissy squat: side view, up on the toes, the near hand holding an upright post beside the body, the far hand
on the chest. The knees travel far forward and down while the body leans back in one straight line from
knee to shoulder (hips stay straight), then back up. The hand slides on the post."""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rig import L, P, along, joint, trunk, mirror, slab, line, write

TOE = [112, 179.5, 9]
POST = [116, 30]          # x and top of the post, at z 27
POST_Z = 27


def pose(shin, lean, hand_y):
    ankle = P([TOE[0], TOE[1], 0], 225, L["foot"])               # heel high, on the toes
    knee = P(ankle, shin, L["shin"])
    hip = P(knee, lean, L["thigh"])
    p = trunk([hip[0], hip[1], 0], lean, head_ang=lean + (30 if lean < -100 else 0))
    p["hipL"] = [hip[0], hip[1], 9]
    p["ankleL"], p["kneeL"], p["toeL"] = [ankle[0], ankle[1], 9], [knee[0], knee[1], 9], list(TOE)
    p = mirror(p)
    p["handL"] = [POST[0] - 3, hand_y, POST_Z - 3]
    p["elbowL"] = joint(p["shoulderL"], p["handL"], L["upper"], L["fore"], [-0.2, 1, 0.6])
    t = p["neck"]
    p["handR"] = [t[0] + 7, t[1] + 9, -2]                           # far hand on the chest
    p["elbowR"] = joint(p["shoulderR"], p["handR"], L["upper"], L["fore"], [0, 1, -0.3])
    return p


start = pose(-90, -90, 88)          # tall on the toes
end = pose(-30, -128, 104)          # knees far forward and low, body leaning back in a line
for k in ("ankleL", "ankleR", "toeL", "toeR"):
    end[k] = start[k]
props = [line([[POST[0], POST[1], POST_Z], [POST[0], 181, POST_Z]], 6),
         slab([[POST[0] - 10, 181], [POST[0] + 10, 181]], POST_Z - 8, POST_Z + 8, 4)]
write("sissy-squat", start, end, props, None, tempo=3.0)
