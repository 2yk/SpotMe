"""Bodyweight calf raise: side view, balls of both feet on a step, heels from below the step to high on the toes;
the near hand rests on an upright in front (a wall or rack post) for balance, the other arm hangs."""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rig import L, P, joint, trunk, mirror, slab, line, write

TOE = [114, 173, 7]
STEP_Y, STEP_X = 178, (108, 134)
WALL_X = 140
HAND = [WALL_X - 4, 80, 16]          # palm on the wall at chest height


def pose(foot_ang):
    """foot_ang: ankle -> toe (negative: heel below the step, positive: up on the toes)."""
    ankle = P([TOE[0], TOE[1], 0], foot_ang + 180, L["foot"])
    knee = P(ankle, -88, L["shin"])
    pelvis = P(knee, -92, L["thigh"])
    p = trunk(pelvis, -88)
    p["hipL"] = [pelvis[0], pelvis[1], 9]
    p["kneeL"], p["ankleL"], p["toeL"] = [knee[0], knee[1], 8], [ankle[0], ankle[1], 7], list(TOE)
    p["elbowL"] = P(p["shoulderL"], 88, L["upper"], 4)
    p["handL"] = P(p["elbowL"], 84, L["fore"], 2)
    mirror(p)
    p["handL"] = list(HAND)
    p["elbowL"] = joint(p["shoulderL"], HAND, L["upper"], L["fore"], [0, 1, 0.6])
    return p


start, end = pose(-22), pose(22)
props = [slab([[STEP_X[0], STEP_Y], [STEP_X[1], STEP_Y]], -20, 20, 7),          # step
         line([[WALL_X, 181, 16], [WALL_X, 44, 16]], 6)]   # an upright to hold (a wall or rack post)
write("bodyweight-calf-raise", start, end, props, {"type": "none"}, tempo=2.4)
