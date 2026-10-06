"""Standing calf raise: side view, shoulders under the machine's pads, balls of the feet on a low step, heels from below the step to high on the toes."""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rig import L, P, joint, trunk, mirror, slab, line, write

TOE = [114, 173, 7]
STEP_Y, STEP_X = 178, (108, 134)
PAD_UP = 4
PIVOT = [40, 49 - PAD_UP, 0]      # behind, level with the pads halfway up the rep


def pose(foot_ang):
    """foot_ang: ankle -> toe (negative: heel below the step, positive: up on the toes)."""
    ankle = P([TOE[0], TOE[1], 0], foot_ang + 180, L["foot"])
    knee = P(ankle, -88, L["shin"])
    pelvis = P(knee, -92, L["thigh"])
    p = trunk(pelvis, -90)
    p["pelvis"] = pelvis
    p["hipL"] = [pelvis[0], pelvis[1], 9]
    p["kneeL"], p["ankleL"], p["toeL"] = [knee[0], knee[1], 8], [ankle[0], ankle[1], 7], list(TOE)
    hand = [p["neck"][0] + 5, p["neck"][1] - PAD_UP - 2, 23]
    p["elbowL"] = joint(p["shoulderL"], hand, L["upper"], L["fore"], [0.6, 1, 0.5])
    p["handL"] = hand
    return mirror(p)


start, end = pose(-22), pose(22)
props = [slab([[STEP_X[0], STEP_Y], [STEP_X[1], STEP_Y]], -20, 20, 7),
         slab([[PIVOT[0] - 8, 181], [STEP_X[0] - 2, 181]], -20, 20, 4),
         line([[PIVOT[0], PIVOT[1] - 14, 0], [PIVOT[0], 181, 0]], 6)]
load = {"type": "pad", "at": ["shoulderL", "shoulderR"], "offset": [-2, -PAD_UP, 0], "pivot": PIVOT, "length": 40}
write("standing-calf-raise", start, end, props, load, tempo=2.4)
