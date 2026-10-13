"""Hack squat: back flat on the machine's reclined pad, shoulders under the volt shoulder pads, feet on the angled
platform ahead of the body; the body slides down the rail (parallel to the pad) into a deep knee bend and back up
to legs nearly straight. The grey pad and rail stay put: the body slides along them."""
import os, sys, math
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rig import L, P, along, joint, trunk, mirror, slab, line, write

TORSO = -128                         # neck from pelvis: reclined about 38 degrees from vertical
TOP = [92, 106]                      # pelvis at the top
TRAVEL = 37                          # how far the pelvis slides down the rail
ANKLE = [120, 170, 11]
FOOT_TILT = -16                      # platform rises toward the front
ru = [math.cos(math.radians(TORSO)), math.sin(math.radians(TORSO))]     # up the rail
front = [-ru[1], ru[0]] if -ru[1] > 0 else [ru[1], -ru[0]]                # the way the chest faces
back = [-front[0], -front[1]]


def pose(s):
    pel = [TOP[0] - ru[0] * s, TOP[1] - ru[1] * s, 0]
    p = trunk(pel, TORSO, head_ang=TORSO + 16)
    p["ankleL"] = list(ANKLE)
    p["toeL"] = P(ANKLE, FOOT_TILT, L["foot"])
    p["kneeL"] = joint(p["hipL"], p["ankleL"], L["thigh"], L["shin"], [1, -0.3, 0])
    sh = p["shoulderL"]
    p["handL"] = [sh[0] + front[0] * 13 - ru[0] * 3, sh[1] + front[1] * 13 - ru[1] * 3, 22]   # handle by the pad
    p["elbowL"] = joint(sh, p["handL"], L["upper"], L["fore"], [1, 0.7, 0.4])
    return mirror(p)


start, end = pose(0), pose(TRAVEL)        # start standing at the top, end at the bottom
for k in ("ankleL", "toeL", "ankleR", "toeR"):
    end[k] = start[k]
# back pad: parallel to the torso, 9 behind its centre line, long enough for both positions
b0 = [TOP[0] + back[0] * 9 - ru[0] * (TRAVEL + 4), TOP[1] + back[1] * 9 - ru[1] * (TRAVEL + 4)]
b1 = [TOP[0] + back[0] * 9 + ru[0] * 54, TOP[1] + back[1] * 9 + ru[1] * 54]
r0 = [b0[0] + back[0] * 8, b0[1] + back[1] * 8]
r1 = [b1[0] + back[0] * 8 + ru[0] * 6, b1[1] + back[1] * 8 + ru[1] * 6]
# foot platform under the soles
fu = [math.cos(math.radians(FOOT_TILT)), math.sin(math.radians(FOOT_TILT))]
fn = [-fu[1], fu[0]] if fu[0] > 0 else [fu[1], -fu[0]]                   # down from the sole
s0 = [ANKLE[0] + fn[0] * 5 - fu[0] * 8, ANKLE[1] + fn[1] * 5 - fu[1] * 8]
s1 = [s0[0] + fu[0] * 32, s0[1] + fu[1] * 32]
props = [slab([b0, b1], -14, 14, 7),                                     # back pad
         line([[r0[0], r0[1], -12], [r1[0], r1[1], -12]], 4),            # rails behind it
         line([[r0[0], r0[1], 12], [r1[0], r1[1], 12]], 4),
         line([[r1[0], r1[1], 0], [r1[0], 181, 0]], 5),                  # rear post
         slab([s0, s1], -20, 20, 5),                                     # foot platform
         line([[s1[0] - 4, s1[1] + 3, 0], [s1[0] - 4, 181, 0]], 5),
         slab([[r1[0] - 4, 181], [s1[0] + 6, 181]], -22, 22, 4)]         # base
load = {"type": "pad", "at": ["shoulderL", "shoulderR"],
        "offset": [front[0] * 8 - ru[0] * 1, front[1] * 8 - ru[1] * 1, 0], "length": 40}
write("hack-squat", start, end, props, load, tempo=2.8)
