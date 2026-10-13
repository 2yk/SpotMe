"""Smith machine squat: side view, bar on the upper back inside the machine's two upright rails, feet a little
ahead of the bar; the bar travels straight down and up (the neck keeps its x), from standing to parallel."""
import math, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rig import L, P, along, joint, trunk, mirror, slab, line, write

NECK_X = 92                     # the bar's path: the neck (and bar) stay on this vertical line
BAR_OFF = [-7, -1, 0]           # bar on the traps, just behind and above the neck
ANKLE = [NECK_X + 14, 176, 12]  # feet a little ahead of the bar
RAIL_Z, TOP = 38, 22


def pose(neck_y, torso):
    t = math.radians(torso)
    pelvis = [NECK_X - math.cos(t) * L["torso"], neck_y - math.sin(t) * L["torso"], 0]
    p = trunk(pelvis, torso, head_ang=torso + (8 if torso > -85 else 0))
    p["neck"][0] = NECK_X
    p["ankleL"] = list(ANKLE)
    p["toeL"] = along(ANKLE, [1, 0.25, 0.25], L["foot"])
    p["kneeL"] = joint(p["hipL"], p["ankleL"], L["thigh"], L["shin"], [1, -0.2, 0.3])
    bar = [p["neck"][i] + BAR_OFF[i] for i in range(3)]
    p["handL"] = [bar[0], bar[1], 25]
    p["elbowL"] = joint(p["shoulderL"], p["handL"], L["upper"], L["fore"], [-0.7, 1, 0.3])
    return mirror(p)


start = pose(53, -90)        # standing
end = pose(98, -66)          # thighs at parallel, back tall
for k in ("ankleL", "ankleR", "toeL", "toeR"):
    end[k] = start[k]
bx = NECK_X + BAR_OFF[0]
props = [line([[bx, 181, z], [bx, TOP, z]], 5) for z in (RAIL_Z, -RAIL_Z)]
props.append(line([[bx, TOP, RAIL_Z], [bx, TOP, -RAIL_Z]], 5))
props.append(slab([[bx - 16, 181], [bx + 16, 181]], -RAIL_Z - 4, RAIL_Z + 4, 4))
load = {"type": "bar", "at": "neck", "offset": BAR_OFF, "length": 100, "plate": 14}
write("smith-machine-squat", start, end, props, load, tempo=2.8, yaw=35)
