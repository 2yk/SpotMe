"""Side plank with reach: on the right forearm, feet stacked, front of the body toward the viewer. The top
(left) arm goes from pointing at the ceiling to threading under the torso and through to the back."""
import math, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rig import L, P, along, joint, trunk, mirror, slab, line, write

GROUND = 177.5
SHOULDER_R = [146, GROUND - L["upper"], 0]   # bottom shoulder straight above the bottom elbow
ROLL = 35                                    # end: chest turned toward the floor (degrees)
REACH = [104, 148, -10]                      # end: the top hand, under the waist toward the hips
ANKLE_Y = 174                                # bottom ankle, foot on its side on the floor


def add(a, b, k=1):
    return [a[i] + b[i] * k for i in range(3)]


def pose(reach):
    long_ = L["torso"] + L["thigh"] + L["shin"]
    tilt = math.degrees(math.asin((ANKLE_Y - SHOULDER_R[1] - 15 * 0) / long_))
    a = math.radians(-tilt)
    head_dir = [math.cos(a), math.sin(a), 0]        # pelvis -> neck
    left = [math.sin(a), -math.cos(a), 0]           # up off the floor (the body's left)
    neck = add(SHOULDER_R, left, 15)
    pelvis = add(neck, head_dir, -L["torso"])
    p = trunk(pelvis, -tilt, left=left)
    p["head"] = P(neck, -tilt, L["head"])
    p["elbowR"] = [SHOULDER_R[0], GROUND, 0]
    p["handR"] = along(p["elbowR"], [0.55, 0, 1], L["fore"])
    for s in "LR":
        p["knee" + s] = add(p["hip" + s], head_dir, -L["thigh"])
        p["ankle" + s] = add(p["knee" + s], head_dir, -L["shin"])
        p["toe" + s] = along(p["ankle" + s], [0.25, 0.15, 1], L["foot"])
    sh = p["shoulderL"]
    if not reach:
        p["elbowL"] = P(sh, -92, L["upper"])
        p["handL"] = P(p["elbowL"], -92, L["fore"])
    else:
        # chest turned toward the floor: the top shoulder rolls toward the viewer (the bottom one stays over its elbow)
        t = math.radians(ROLL)
        roll = [left[i] * math.cos(t) + [0, 0, 1][i] * math.sin(t) for i in range(3)]
        p["shoulderL"] = add(neck, roll, 15)
        sh = p["shoulderL"]
        p["head"] = along(neck, [head_dir[0], head_dir[1] + 0.25, 0.3], L["head"])   # looking down after the hand
        hand = list(REACH)                          # under the waist toward the hips, behind the torso
        p["handL"] = hand
        p["elbowL"] = joint(sh, hand, L["upper"], L["fore"], [0.3, -1, 0.6])
    return p


start, end = pose(False), pose(True)
for k in start:
    if k in ("shoulderL", "head"):
        continue
    if not k.endswith("L") or k in ("hipL", "kneeL", "ankleL", "toeL"):
        end[k] = start[k]
write("side-plank-with-reach", start, end, [], None, tempo=3)
