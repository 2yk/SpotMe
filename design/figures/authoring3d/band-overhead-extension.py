"""Band overhead extension: standing in a split stance, the band under the back foot and running up behind the
body to both hands behind the head; elbows up by the ears, forearms from folded to straight overhead."""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rig import L, P, along, joint, trunk, mirror, slab, line, write

PELVIS = [100, 108, 0]
TORSO = -86
UPPER = -82          # upper arms nearly vertical, elbows up beside the head
FORE_START, FORE_END = 112, -84   # forearms dropped behind the head, then straight up
BACK_ANKLE = [68, 175, -12]
ANCHOR = [60, 181, -12]  # band under the back heel, so it runs up clear of the back leg
ELBOW_OUT, HAND_Z = 8, 5   # elbows out beside the head, hands close on the band
YAW = 320                # from behind the back shoulder: the band runs clear of the back, the arms frame the head


def pose(fore):
    p = trunk(PELVIS, TORSO, head_ang=-88)
    p["elbowL"] = P(p["shoulderL"], UPPER, L["upper"], ELBOW_OUT)   # elbows wide enough to frame the head
    el = p["elbowL"]
    dz = HAND_Z - el[2]
    p["handL"] = P([el[0], el[1], HAND_Z], fore, (L["fore"] ** 2 - dz ** 2) ** 0.5)
    p = mirror(p)
    for s, ank, toe_ang in (("L", [126, 175, 10], 8), ("R", BACK_ANKLE, 18)):
        p["ankle" + s] = list(ank)
        p["toe" + s] = P(ank, toe_ang, L["foot"])
        p["knee" + s] = joint(p["hip" + s], ank, L["thigh"], L["shin"], [1, 0, 0])
    return p


start, end = pose(FORE_START), pose(FORE_END)
write("band-overhead-extension", start, end, [], {"type": "band", "handle": "rope", "anchor": ANCHOR}, tempo=2.6, yaw=YAW)
