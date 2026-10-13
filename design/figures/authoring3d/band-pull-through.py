"""Band pull-through: standing, back to a band anchored low behind; the band runs between the legs to both
hands. From a hip hinge with the hands back between the thighs, drive the hips forward to stand tall with
straight arms, hands in front of the hips."""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rig import L, P, along, joint, trunk, mirror, write

ANKLE = [100, 177]
FOOT_Z = 13                          # feet a little wider than the hips
ANCHOR = [16, 171, 0]                # band anchored low behind
HAND_Z = 3                           # both hands together on the band


def pose(pelvis, torso, hand_dir):
    p = trunk(pelvis, torso)
    p["ankleL"] = [ANKLE[0], ANKLE[1], FOOT_Z]
    p["toeL"] = [ANKLE[0] + 12.4, 179, FOOT_Z + 1]
    p["kneeL"] = joint(p["hipL"], p["ankleL"], L["thigh"], L["shin"], [1, 0, 0.2])
    sh = p["shoulderL"]
    hand = P([sh[0], sh[1], HAND_Z], hand_dir, L["upper"] + L["fore"] - 1)
    p["elbowL"] = joint(sh, hand, L["upper"], L["fore"], [-1, 0, 0.3])
    p["handL"] = hand
    return mirror(p)


start = pose([82, 111, 0], -27, 122)     # hinged: hips back, chest forward, hands back between the thighs
end = pose([102, 103.6, 0], -90, 82)     # tall: hips through, arms straight, hands in front of the hips
for k in ("ankleL", "toeL", "ankleR", "toeR"):
    end[k] = list(start[k])
# opening view turned a little so the band shows between the legs
load = {"type": "band", "anchor": ANCHOR, "handle": "rope"}
write("band-pull-through", start, end, [], load, tempo=2.6, yaw=335)
