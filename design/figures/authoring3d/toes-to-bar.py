"""Toes-to-bar: side view, hanging from a bar. Arms stay straight and press the bar down: the shoulders swing
back under it, the torso leans back and the straight legs fold up until the toes touch the bar."""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rig import L, P, along, joint, trunk, mirror, line, write

BAR = [96, 12]
HAND_Z = 15
FRAME_X, FRAME_Z = 26, 34
ARM = L["upper"] + L["fore"] - 1


def pose(arm_ang, torso_ang, head_ang, thigh_ang, shin_ang, toe_ang, knee_out=-1):
    """arm_ang: hand -> shoulder (90 straight down; more swings the shoulders back); torso_ang: neck -> pelvis."""
    hand = [BAR[0], BAR[1], HAND_Z]
    sh = P(hand, arm_ang, ARM)
    neck = [sh[0], sh[1], 0]
    pelvis = P(neck, torso_ang, L["torso"])
    p = trunk(pelvis, torso_ang + 180, head_ang=head_ang)
    p["elbowL"] = joint(p["shoulderL"], hand, L["upper"], L["fore"], [-1, 0, 0.3])
    p["handL"] = hand
    p["kneeL"] = [a + b for a, b in zip(P(p["hipL"], thigh_ang, L["thigh"]), [0, 0, knee_out])]
    p["ankleL"] = P(p["kneeL"], shin_ang, L["shin"])
    p["toeL"] = P(p["ankleL"], toe_ang, L["foot"])
    return mirror(p)


start = pose(68, 94, -62, 80, 100, 40)                  # hang, as hanging-leg-raise
end = pose(122, 44, -118, -95, -95, -60)                # pike: torso back, legs straight up, toes at the bar
for k in ("handL", "handR"):
    end[k] = list(start[k])
RAIL_END = BAR[0] + 13
props = [line([[BAR[0], BAR[1], -FRAME_Z - 6], [BAR[0], BAR[1], FRAME_Z + 6]], 6)]
for z in (-FRAME_Z, FRAME_Z):
    props.append(line([[RAIL_END, BAR[1], z], [FRAME_X, BAR[1], z], [FRAME_X, 196, z]], 5))
write("toes-to-bar", start, end, props, None, tempo=3.2, floor=197)
