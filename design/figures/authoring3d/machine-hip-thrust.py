"""Machine hip thrust (Glute Drive): seated on the machine's base, upper back on its back pad, feet flat, a padded
lever across the hips that pivots low at the front. Hands on the pad's ends. Hips from low to level with knees
and shoulders."""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rig import L, P, joint, trunk, mirror, slab, line, write

NECK = [44, 139, 0]
TORSO_START, TORSO_END = 33, 0      # angle neck -> pelvis: hips low, then level
PAD_UP = 13                         # roller sits on top of the hips, clear of the torso line
PIVOT = [150, 152, 0]               # the lever's pivot, low at the front (about the same distance at both ends)


def pose(ang):
    pelvis = P(NECK, ang, L["torso"])
    p = trunk(pelvis, ang + 180, head_ang=196)
    p["ankleL"] = [134, 175, 12]
    p["toeL"] = [146.4, 179, 12]
    p["kneeL"] = joint(p["hipL"], p["ankleL"], L["thigh"], L["shin"], [0.3, -1, 0])
    hand = [pelvis[0] - 2, pelvis[1] - PAD_UP - 1, 21]
    p["elbowL"] = joint(p["shoulderL"], hand, L["upper"], L["fore"], [0, -1, 0.4])
    p["handL"] = hand
    return mirror(p)


start, end = pose(TORSO_START), pose(TORSO_END)
props = [slab([[22, 145], [58, 149]], -20, 20, 8),                 # back pad, a little declined
         line([[40, 151, 0], [40, 180, 0]], 6),                     # its post
         slab([[30, 180], [160, 180]], -24, 24, 4),                 # base under the seat and the feet
         line([[PIVOT[0], PIVOT[1], 0], [PIVOT[0] + 4, 180, 0]], 6)]  # the lever's upright at the front
load = {"type": "pad", "at": ["hipL", "hipR"], "offset": [-2, -PAD_UP, 0], "pivot": PIVOT, "length": 40, "w": 12}
write("machine-hip-thrust", start, end, props, load, tempo=2.8, yaw=330)
