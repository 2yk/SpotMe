"""Russian twist: sitting leaning back about 45, knees bent, feet just off the floor, a plate held in both
hands in front of the chest; the shoulders and arms turn the plate from one side to the other, the hips stay."""
import math, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rig import L, P, along, joint, trunk, write

PELVIS = [92, 172, 0]
LEAN = -132                           # pelvis -> neck: leaning back about 45
TWIST = 55                            # shoulder turn each way (degrees about the torso axis)
PLATE_OUT, PLATE_DOWN = 33, 16        # plate centre: in front of the chest, down the torso from the neck


def pose(side):
    p = trunk(PELVIS, LEAN, head_ang=LEAN + 25)
    neck = p["neck"]
    a = math.radians(LEAN)
    up = [math.cos(a), math.sin(a), 0]
    front = [math.cos(a + math.pi / 2), math.sin(a + math.pi / 2), 0]   # chest normal (up and forward)
    t = math.radians(TWIST * side)
    f = [front[i] * math.cos(t) + [0, 0, 1][i] * math.sin(t) for i in range(3)]
    l = [[0, 0, 1][i] * math.cos(t) - front[i] * math.sin(t) for i in range(3)]
    for s, k in (("L", 1), ("R", -1)):
        p["shoulder" + s] = [neck[i] + l[i] * 15 * k for i in range(3)]
    plate = [neck[i] - up[i] * PLATE_DOWN + f[i] * PLATE_OUT for i in range(3)]
    for s, k in (("L", 1), ("R", -1)):
        hand = [plate[i] + l[i] * 10 * k for i in range(3)]
        p["hand" + s] = hand
        bend = [-up[i] * 0.6 + l[i] * k for i in range(3)]
        p["elbow" + s] = joint(p["shoulder" + s], hand, L["upper"], L["fore"], bend)
    for s, k in (("L", 1), ("R", -1)):
        p["knee" + s] = P(p["hip" + s], -42, L["thigh"])                 # knees about 100, hip width
        p["ankle" + s] = P(p["knee" + s], 38, L["shin"])
        p["toe" + s] = P(p["ankle" + s], 8, L["foot"])
    return p


start, end = pose(1), pose(-1)
for k in ("pelvis", "head", "neck", "hipL", "hipR", "kneeL", "ankleL", "toeL", "kneeR", "ankleR", "toeR"):
    end[k] = list(start[k])
write("russian-twist", start, end, (), {"type": "held", "kind": "plate", "axis": [0, 0, 1]}, tempo=2.4, yaw=35)
