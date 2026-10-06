"""Hanging leg raise: side view, hanging from a bar, straight legs from hanging to just above level, pelvis curling up."""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rig import L, P, joint, trunk, mirror, line, write

BAR = [96, 12]                 # bar seen end-on, hands on it a little behind the head (as the flat figure)
NECK = [114.6, 58.5, 0]
HAND_Z = 18
FRAME_X, FRAME_Z = 26, 32      # a rack behind: the bar runs across, arms back to two posts


def pose(torso_ang, thigh_ang, shin_ang, toe_ang):
    """torso_ang: neck -> pelvis (90 straight down; more swings the pelvis forward)."""
    pelvis = P(NECK, torso_ang, L["torso"])
    p = trunk(pelvis, torso_ang + 180, head_ang=-62)
    hand = [BAR[0], BAR[1], HAND_Z]
    p["elbowL"] = joint(p["shoulderL"], hand, L["upper"], L["fore"], [-1, 0, 0.3])
    p["handL"] = hand
    p["kneeL"] = [a + b for a, b in zip(P(p["hipL"], thigh_ang, L["thigh"]), [0, 0, -1])]
    p["ankleL"] = P(p["kneeL"], shin_ang, L["shin"])
    p["toeL"] = P(p["ankleL"], toe_ang, L["foot"])
    return mirror(p)


start = pose(94, 79, 104, 38)
end = pose(106, -6, -6, -32)
for k in ("neck", "head", "shoulderL", "shoulderR", "handL", "handR"):
    end[k] = list(start[k])
props = [line([[BAR[0], BAR[1], -FRAME_Z], [BAR[0], BAR[1], FRAME_Z]], 6)]
for z in (-FRAME_Z, FRAME_Z):
    props.append(line([[BAR[0], BAR[1], z], [FRAME_X, BAR[1], z], [FRAME_X, 196, z]], 5))
write("hanging-leg-raise", start, end, props, None, tempo=3.0, floor=197)
