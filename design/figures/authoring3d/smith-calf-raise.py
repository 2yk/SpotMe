"""Smith machine calf raise: side view, bar on the upper back between the machine's two rails, hands on the bar,
balls of the feet on a step under it; straight knees, heels from below the step to high on the toes. The bar rides
straight up the rails."""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rig import L, P, joint, trunk, mirror, slab, line, write

TOE = [114, 173, 7]
STEP_Y, STEP_X = 178, (108, 134)
BAR_OFF = [-5, -3, 0]
RAIL_Z, TOP = 38, 22


def pose(foot_ang):
    ankle = P([TOE[0], TOE[1], 0], foot_ang + 180, L["foot"])
    knee = P(ankle, -89, L["shin"])
    pelvis = P(knee, -91, L["thigh"])
    p = trunk(pelvis, -90)
    p["hipL"] = [pelvis[0], pelvis[1], 9]
    p["kneeL"], p["ankleL"], p["toeL"] = [knee[0], knee[1], 8], [ankle[0], ankle[1], 7], list(TOE)
    bar = [p["neck"][i] + BAR_OFF[i] for i in range(3)]
    p["handL"] = [bar[0], bar[1], 25]
    p["elbowL"] = joint(p["shoulderL"], p["handL"], L["upper"], L["fore"], [-0.7, 1, 0.3])
    return mirror(p)


start, end = pose(-22), pose(22)
bx = start["neck"][0] + BAR_OFF[0]
props = [line([[bx, 181, z], [bx, TOP, z]], 5) for z in (RAIL_Z, -RAIL_Z)]
props.append(line([[bx, TOP, RAIL_Z], [bx, TOP, -RAIL_Z]], 5))
props.append(slab([[bx - 16, 181], [STEP_X[1] + 4, 181]], -RAIL_Z - 4, RAIL_Z + 4, 4))
props.append(slab([[STEP_X[0], STEP_Y], [STEP_X[1], STEP_Y]], -20, 20, 7))
load = {"type": "bar", "at": "neck", "offset": BAR_OFF, "length": 100, "plate": 14}
write("smith-calf-raise", start, end, props, load, tempo=2.6, yaw=35)   # turned: rails and plate clear of the body
