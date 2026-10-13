"""Decline barbell bench press: lying head-down on a bench declined about 20 degrees, knees bent over the high end
and the shins hooked under the foot rollers (feet off the floor); a barbell from touching the lower chest to arms
straight up over the chest. The head-down slope and the hooked legs tell it apart from the flat bench."""
import os, sys, math
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rig import L, P, joint, trunk, mirror, slab, line, write

PELVIS = [112, 118, 0]
DECLINE = 20
TORSO = 180 - DECLINE           # pelvis -> neck: toward the head end (left), sloping down
GRIP = 26                       # hands a bit wider than the shoulders
BOTTOM = [-13, 8]               # bottom: bar from the shoulder, [along the torso toward the hips, off the chest]
TOP_UP = 49                     # top: hand this far above the shoulder, arms straight up
T = [math.cos(math.radians(TORSO)), math.sin(math.radians(TORSO))]     # toward the head
N = [T[1], -T[0]]                                                      # off the chest (up)
if N[1] > 0:
    N = [-N[0], -N[1]]
KNEE = [146, 104]               # knee over the top of the leg section
ANKLE_ANG = 100                 # shin down and a touch back to the rollers


def pose(top):
    p = trunk(PELVIS, TORSO, head_ang=TORSO + 6)
    p["kneeL"] = P(p["hipL"], math.degrees(math.atan2(KNEE[1] - PELVIS[1], KNEE[0] - PELVIS[0])), L["thigh"], 2)
    p["ankleL"] = P(p["kneeL"], ANKLE_ANG, L["shin"])
    p["toeL"] = P(p["ankleL"], 10, L["foot"])
    sh = p["shoulderL"]
    bx = sh[0] + T[0] * BOTTOM[0] + N[0] * BOTTOM[1]
    by = sh[1] + T[1] * BOTTOM[0] + N[1] * BOTTOM[1]
    if top:
        hand = [bx - 2, sh[1] - TOP_UP, GRIP]
        el = joint(sh, hand, L["upper"], L["fore"], [0.2, 0, 1])
    else:
        hand = [bx, by, GRIP]
        el = joint(sh, hand, L["upper"], L["fore"], [0.3, 1, 0.6])
    p["elbowL"], p["handL"] = el, hand
    return mirror(p)


start, end = pose(False), pose(True)
for k in ("kneeL", "ankleL", "toeL", "kneeR", "ankleR", "toeR"):
    end[k] = start[k]
PAD = 9
pad0 = [PELVIS[0] - N[0] * PAD + T[0] * -8, PELVIS[1] - N[1] * PAD + T[1] * -8]     # back pad, hips end
pad1 = [PELVIS[0] - N[0] * PAD + T[0] * 76, PELVIS[1] - N[1] * PAD + T[1] * 76]     # under the head
kn = start["kneeL"]
leg0 = [kn[0] - 6, kn[1] + 9]                                                    # leg section under the knees
an = start["ankleL"]
ROLL = [an[0] + 7, an[1] - 6]                                                    # foot rollers in front of the shins
props = [slab([pad1, pad0], -12, 12, 7),                                         # back pad
         slab([pad0, leg0], -11, 11, 7),                                          # leg section, own part so the legs sort in front
         line([[ROLL[0], ROLL[1], -14], [ROLL[0], ROLL[1], 14]], 9),             # foot rollers
         line([[leg0[0], leg0[1] + 4, 0], [ROLL[0], ROLL[1], 0]], 4),            # roller arm
         line([[(pad0[0] + pad1[0]) / 2, (pad0[1] + pad1[1]) / 2 + 4, 0], [86, 181, 0]], 5),   # post
         line([[leg0[0] - 4, leg0[1] + 4, 0], [128, 181, 0]], 5),                # front post
         slab([[60, 181], [140, 181]], -14, 14, 4)]                               # base
load = {"type": "bar", "length": 92, "plate": 14}
write("decline-barbell-bench-press", start, end, props, load, tempo=2.6, yaw=-15)
