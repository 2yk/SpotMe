"""Hip thrust: upper back on a bench, feet flat, hips from near the floor to level with knees and shoulders."""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rig import L, P, joint, trunk, mirror, slab, write

NECK = [44, 139, 0]
TORSO_START, TORSO_END = 33, 0      # angle neck -> pelvis: hips low, then level
BAR_UP = 8                          # bar sits this far above the pelvis point (on top of the hips)


def pose(ang):
    pelvis = P(NECK, ang, L["torso"])
    p = trunk(pelvis, ang + 180, head_ang=196)
    p["ankleL"] = [134, 175, 12]
    p["toeL"] = [146.4, 179, 12]
    p["kneeL"] = joint(p["hipL"], p["ankleL"], L["thigh"], L["shin"], [0.3, -1, 0])
    hand = [pelvis[0], pelvis[1] - BAR_UP - 1, 22]
    p["elbowL"] = joint(p["shoulderL"], hand, L["upper"], L["fore"], [0, -1, 0.4])
    p["handL"] = hand
    return mirror(p)


start, end = pose(TORSO_START), pose(TORSO_END)
props = [slab([[20, 146], [56, 146]], -22, 22, 7), slab([[56, 149], [56, 181]], -22, 22, 5),
         slab([[20, 149], [20, 181]], -22, 22, 5)]
load = {"type": "bar", "at": "pelvis", "offset": [0, -BAR_UP, 0], "length": 92, "plate": 14}
write("hip-thrust", start, end, props, load, tempo=2.8)
