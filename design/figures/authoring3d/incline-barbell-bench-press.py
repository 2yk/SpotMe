"""Incline barbell bench press: back on a bench inclined about 30 degrees under a rack, feet on the floor; a barbell
from touching the upper chest (elbows a little in, under the bar) to arms straight above the shoulders. The body
and bench match incline-db-press; the rack's uprights with their hooks stand behind the head."""
import os, sys, math
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rig import L, P, joint, trunk, mirror, slab, line, write

PELVIS = [98, 140, 0]
TORSO = 210                     # pelvis -> neck: 30 degrees above horizontal, toward the head end (left)
GRIP = 26                       # hands a bit wider than the shoulders
BOTTOM = [-11, 8]                # bottom: bar from the shoulder, [along the torso toward the hips, off the chest]
TOP = [3, -49]                  # top: hand from the shoulder, arm nearly straight above the shoulder
KNEE_BEND = [1, -1, 0]
T = [math.cos(math.radians(TORSO)), math.sin(math.radians(TORSO))]     # toward the head
N = [-T[1], T[0]]                                                      # off the chest (up and right)
if N[1] > 0:
    N = [-N[0], -N[1]]


def pose(top):
    p = trunk(PELVIS, TORSO, head_ang=202)
    p["ankleL"] = [139, 175, 15]
    p["toeL"] = [151.4, 178.8, 15]
    p["kneeL"] = joint(p["hipL"], p["ankleL"], L["thigh"], L["shin"], KNEE_BEND)
    p["ankleR"] = [134, 175, -15]
    p["toeR"] = [146.4, 178.8, -15]
    p["kneeR"] = joint(p["hipR"], p["ankleR"], L["thigh"], L["shin"], KNEE_BEND)
    sh = p["shoulderL"]
    if top:
        hand = [sh[0] + TOP[0], sh[1] + TOP[1], GRIP]
        el = joint(sh, hand, L["upper"], L["fore"], [0.2, 0, 1])
    else:
        hand = [sh[0] + T[0] * BOTTOM[0] + N[0] * BOTTOM[1], sh[1] + T[1] * BOTTOM[0] + N[1] * BOTTOM[1], GRIP]
        el = joint(sh, hand, L["upper"], L["fore"], [0.3, 1, 0.5])
    p["elbowL"], p["handL"] = el, hand
    for k in ("elbow", "hand"):
        x, y, z = p[k + "L"]
        p[k + "R"] = [x, y, -z]
    return p


start, end = pose(False), pose(True)
PAD = 9                                   # pad surface below the body's centre line
base = [PELVIS[0] - N[0] * PAD, PELVIS[1] - N[1] * PAD]
SEAT_Y = 151
k = (SEAT_Y - 2 - base[1]) / T[1]
pad_low = [base[0] + T[0] * k, base[1] + T[1] * k]
pad_top = [base[0] + T[0] * 68, base[1] + T[1] * 68]
props = [slab([pad_low, pad_top], -12, 12, 7),                     # back pad
         slab([[88, SEAT_Y], [124, SEAT_Y]], -12, 12, 7),           # seat
         line([[104, 153, 0], [104, 181, 0]], 5),                   # seat post
         slab([[84, 181], [124, 181]], -14, 14, 4),                 # base
         line([[pad_low[0] + 2, pad_low[1] + 4, 0], [104, 165, 0]], 4)]   # brace under the back pad
RX, HOOK_Y = 22, 72                                          # rack uprights behind the head, hooks at the top
for z in (-34, 34):
    props.append(line([[RX, 181, z], [RX, 56, z]], 5))
    props.append(line([[RX, HOOK_Y, z], [RX + 8, HOOK_Y, z], [RX + 8, HOOK_Y - 5, z]], 4))
props.append(slab([[RX - 8, 181], [RX + 8, 181]], -38, 38, 4))
load = {"type": "bar", "length": 92, "plate": 14}
write("incline-barbell-bench-press", start, end, props, load, tempo=2.6, yaw=-30)
