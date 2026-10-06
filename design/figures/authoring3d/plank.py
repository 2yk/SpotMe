"""Forearm plank: forearms and toes on the floor, body one straight line, a plate lying on the upper back. Hold."""
import math, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rig import L, P, along, joint, trunk, mirror, slab, line, write

GROUND = 177.5                      # y of a limb point resting on the floor
FOOT = 70                           # ankle -> toe angle: toes tucked under, heel up
ELBOW_X = 150                       # elbows under the shoulders


def pose(lift=0):
    neck = [ELBOW_X, GROUND - L["upper"], 0]
    ankle_y = GROUND - L["foot"] * math.sin(math.radians(FOOT))
    tilt = math.degrees(math.asin((ankle_y - neck[1]) / (L["torso"] + L["thigh"] + L["shin"])))
    pelvis = P(neck, 180 - tilt, L["torso"])
    pelvis[1] -= lift
    p = trunk(pelvis, -tilt, head_ang=-tilt - 4)
    p["neck"], p["shoulderL"], p["shoulderR"] = neck, [neck[0], neck[1], 15], [neck[0], neck[1], -15]
    p["head"] = P(neck, -tilt - 4, L["head"])
    p["elbowL"] = [ELBOW_X, GROUND, 14]
    p["handL"] = P(p["elbowL"], 0, L["fore"], out=-16)
    knee = P([pelvis[0], pelvis[1] + lift, 9], 180 - tilt, L["thigh"])
    p["kneeL"] = knee
    p["ankleL"] = P(knee, 180 - tilt, L["shin"])
    p["toeL"] = P(p["ankleL"], FOOT, L["foot"])
    return mirror(p)


start, end = pose(0), pose(2)
for k in start:
    if k not in ("pelvis", "hipL", "hipR"):
        end[k] = start[k]
s = start
dx, dy = s["pelvis"][0] - s["neck"][0], s["pelvis"][1] - s["neck"][1]
n = math.hypot(dx, dy)
up = [dy / n, -dx / n, 0]           # normal to the spine, pointing up off the back
if up[1] > 0:
    up = [-u for u in up]
spine = [dx / n * 15, dy / n * 15]
off = [spine[0] + up[0] * 9, spine[1] + up[1] * 9, 0]
load = {"type": "held", "kind": "plate", "at": "neck", "offset": off, "axis": up}
write("plank", start, end, [], load, tempo=4, hold=True)
