"""Single-leg DB calf raise: side view, the ball of the near foot on a step, the far foot hooked behind the near
ankle; one dumbbell hangs in the near hand, the far hand on an upright in front (a wall or rack post) for balance. Heel from below the step
to high on the toes. The dumbbell is a short machine grip with a plate at each end (as suitcase-carry does)."""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rig import L, P, joint, trunk, mirror, slab, line, write

TOE = [114, 173, 4]
STEP_Y, STEP_X = 178, (108, 134)
WALL_X = 140
HAND_R = [WALL_X - 4, 80, -14]        # far hand on the wall


def pose(foot_ang):
    ankle = P([TOE[0], TOE[1], 0], foot_ang + 180, L["foot"])
    knee = P(ankle, -88, L["shin"])
    pelvis = P(knee, -92, L["thigh"])
    p = trunk(pelvis, -88)
    p["kneeL"], p["ankleL"], p["toeL"] = [knee[0], knee[1], 6], [ankle[0], ankle[1], 4], list(TOE)
    # far leg: knee bent, foot tucked behind the working ankle
    p["ankleR"] = [ankle[0] - 9, ankle[1] - 12, -1]
    p["kneeR"] = joint(p["hipR"], p["ankleR"], L["thigh"], L["shin"], [1, 0, 0])
    p["toeR"] = P(p["ankleR"], 30, L["foot"])
    p["toeR"][2] = 1
    p["elbowL"] = P(p["shoulderL"], 90, L["upper"], 6)               # dumbbell arm hangs at the side
    p["handL"] = P(p["elbowL"], 90, L["fore"], 2)
    p["handR"] = list(HAND_R)
    p["elbowR"] = joint(p["shoulderR"], HAND_R, L["upper"], L["fore"], [0, 1, -0.6])
    return p


start, end = pose(-22), pose(22)
props = [slab([[STEP_X[0], STEP_Y], [STEP_X[1], STEP_Y]], -20, 20, 7),
         line([[WALL_X, 181, -14], [WALL_X, 44, -14]], 6)]   # an upright to hold (a wall or rack post)
load = [{"type": "machine", "grips": ["handL"], "axis": [1, 0, 0], "length": 18},
        {"type": "held", "kind": "plate", "at": "handL", "offset": [8, 0, 0], "axis": [1, 0, 0]},
        {"type": "held", "kind": "plate", "at": "handL", "offset": [-8, 0, 0], "axis": [1, 0, 0]}]
write("single-leg-db-calf-raise", start, end, props, load, tempo=2.6)
