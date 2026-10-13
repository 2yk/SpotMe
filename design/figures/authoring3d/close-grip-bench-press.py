"""Close-grip bench press: as the barbell bench press (flat bench under a rack, feet on the floor), but the hands
are shoulder-width and the elbows stay tucked to the sides: the bar touches the lower chest with the upper arms
running toward the hips, then presses to lockout over the shoulders. Opens turned so the narrow grip shows."""
import os, sys, math
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rig import L, P, joint, trunk, mirror, slab, line, write

PELVIS = [114, 137, 0]          # body centre line 9 above the bench top (146)
BENCH_TOP = 146
GRIP = 14                       # hands shoulder-width (shoulders are 15 either side)
ELBOW_Z = 19                    # bottom: elbows tucked, just outside the body
ELBOW_DROP = 12                 # bottom: elbow this far below the shoulder
TOP = [4, -50]                  # top: hand from the shoulder, arm nearly straight above the shoulder
KNEE_BEND = [1, -1, 0]


def pose(top):
    p = trunk(PELVIS, 180, head_ang=180)
    p["ankleL"] = [146, 175, 16]
    p["toeL"] = [158.4, 179, 16]
    p["kneeL"] = joint(p["hipL"], p["ankleL"], L["thigh"], L["shin"], KNEE_BEND)
    sh = p["shoulderL"]
    if top:
        hand = [sh[0] + TOP[0], sh[1] + TOP[1], GRIP]
        p["elbowL"] = joint(sh, hand, L["upper"], L["fore"], [0.2, 0, 1])
    else:
        h = math.sqrt(L["upper"] ** 2 - ELBOW_DROP ** 2)
        dz = ELBOW_Z - sh[2]
        dx = math.sqrt(h * h - dz * dz)
        p["elbowL"] = [sh[0] + dx, sh[1] + ELBOW_DROP, ELBOW_Z]     # elbow tucked, toward the hips
        hz = GRIP - ELBOW_Z
        hand = P([p["elbowL"][0], p["elbowL"][1], GRIP], -96, math.sqrt(L["fore"] ** 2 - hz * hz))
    p["handL"] = hand
    return mirror(p)


def stagger(p, dx):
    p["ankleR"][0] += dx
    p["toeR"][0] += dx
    p["kneeR"] = joint(p["hipR"], p["ankleR"], L["thigh"], L["shin"], KNEE_BEND)
    return p


start, end = stagger(pose(False), -6), stagger(pose(True), -6)
for k in ("ankleL", "toeL", "kneeL", "ankleR", "toeR", "kneeR"):
    end[k] = start[k]
props = [slab([[36, BENCH_TOP], [122, BENCH_TOP]], -12, 12, 7)]
for x in (44, 114):                                          # four bench legs
    for z in (-9, 9):
        props.append(line([[x, 149, z], [x, 181, z]], 5))
RX, HOOK_Y = 46, 92                                          # rack uprights at the head end, hooks over the face
for z in (-34, 34):
    props.append(line([[RX, 181, z], [RX, 74, z]], 5))
    props.append(line([[RX, HOOK_Y, z], [RX + 7, HOOK_Y, z], [RX + 7, HOOK_Y - 5, z]], 4))
props.append(slab([[RX - 8, 181], [RX + 8, 181]], -38, 38, 4))
load = {"type": "bar", "length": 92, "plate": 14}
write("close-grip-bench-press", start, end, props, load, tempo=2.6, yaw=-60)
