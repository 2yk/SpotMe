"""Single-leg RDL: standing on the far leg, one dumbbell in the near hand (the opposite hand). Hinge at the hip:
the torso tips forward to nearly level while the near leg swings straight back in line with it, the standing knee
soft; then stand back up, near foot down beside the other. One dumbbell is built from a short machine grip with a
plate at each end (as suitcase-carry does)."""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rig import L, P, along, joint, trunk, mirror, slab, line, write

ANKLE_R = [100, 177, -7]


def pose(shin, thigh, torso, leg, arm):
    knee = P([ANKLE_R[0], ANKLE_R[1], 0], shin, L["shin"])
    pelvis = P(knee, thigh, L["thigh"])
    p = trunk(pelvis, torso, head_ang=torso - 4)
    p["ankleR"] = list(ANKLE_R)
    p["kneeR"] = [knee[0], knee[1], -8]
    p["kneeR"] = joint(p["hipR"], p["ankleR"], L["thigh"], L["shin"], [1, 0, 0])
    p["toeR"] = P(ANKLE_R, 0, L["foot"])
    # free leg (near): straight along `leg`, toes pointing down
    p["kneeL"] = P(p["hipL"], leg, L["thigh"])
    p["kneeL"][2] = 8
    p["ankleL"] = P(p["kneeL"], leg, L["shin"])
    p["ankleL"][2] = 7
    p["toeL"] = P(p["ankleL"], leg - 90 if leg > 120 else 0, L["foot"])
    p["toeL"][2] = 7
    p["elbowL"] = P(p["shoulderL"], arm, L["upper"], -4)
    p["handL"] = P(p["elbowL"], arm, L["fore"], -2)
    p["elbowR"] = P(p["shoulderR"], arm - 4, L["upper"], 6)
    p["handR"] = P(p["elbowR"], arm - 8, L["fore"], 4)
    return p


start = pose(-90, -90, -88, 92, 86)       # standing tall, near foot just touching down beside
end = pose(-84, -104, -10, 170, 96)       # T: torso near level, near leg straight back in line
for k in ("ankleR", "toeR"):
    end[k] = list(start[k])
load = [{"type": "machine", "grips": ["handL"], "axis": [1, 0, 0], "length": 18},
        {"type": "held", "kind": "plate", "at": "handL", "offset": [8, 0, 0], "axis": [1, 0, 0]},
        {"type": "held", "kind": "plate", "at": "handL", "offset": [-8, 0, 0], "axis": [1, 0, 0]}]
write("single-leg-rdl", start, end, [], load, tempo=3.2, yaw=20)
