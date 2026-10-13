"""DB Romanian deadlift: standing, a dumbbell in each hand (overhand, handles across the body) in front of the
thighs; soft knees, hips push back and the flat back tips forward until the dumbbells pass the knees, then stand
tall. Arms hang straight throughout. Turned a little so both dumbbells show."""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rig import L, P, along, joint, trunk, mirror, slab, line, write

ANKLE = [100, 177, 9]


def pose(shin, thigh, torso, arm):
    knee = P([ANKLE[0], ANKLE[1], 0], shin, L["shin"])
    pelvis = P(knee, thigh, L["thigh"])
    p = trunk(pelvis, torso, head_ang=torso - (0 if torso > -60 else 0))
    p["ankleL"] = list(ANKLE)
    p["kneeL"] = [knee[0], knee[1], 9]
    p["toeL"] = P(ANKLE, 0, L["foot"])
    p["elbowL"] = P(p["shoulderL"], arm, L["upper"], -6)
    p["handL"] = P(p["elbowL"], arm, L["fore"], -4)
    return mirror(p)


start = pose(-90, -91, -88, 84)          # standing tall, dumbbells at the front of the thighs
end = pose(-82, -117, -24, 102)          # hinged: hips back, soft knees, dumbbells just below the knees
for k in ("ankleL", "toeL", "ankleR", "toeR"):
    end[k] = list(start[k])
write("db-romanian-deadlift", start, end, [], {"type": "dumbbells", "axis": [0, 0, 1]}, tempo=3.0, yaw=25)
