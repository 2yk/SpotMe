"""Single-leg glute bridge: on the back, the far (right) foot flat on the floor, the near (left) knee pulled to
the chest and held there; arms on the floor at the sides. Hips from the floor up until the planted knee, the
hips and the shoulders are in one line; the raised leg rides along with the pelvis."""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rig import L, P, joint, trunk, write

NECK = [62, 176, 0]
TORSO_START, TORSO_END = 0, -23       # angle neck -> pelvis: on the floor, then the hips up in line
ANKLE = [154, 175]
FOOT_W = 8
ARM_OUT = 13
TUCK = 100                            # raised thigh: degrees from the torso line toward the chest
SHIN = 122                            # raised shin: degrees from the thigh (knee well bent)


def pose(ang):
    pelvis = P(NECK, ang, L["torso"])
    p = trunk(pelvis, ang + 180, head_ang=197)
    p["neck"] = list(NECK)
    # planted leg (far side)
    p["ankleR"] = [ANKLE[0], ANKLE[1], -FOOT_W]
    p["toeR"] = [ANKLE[0] + 12.4, 179, -FOOT_W]
    p["kneeR"] = joint(p["hipR"], p["ankleR"], L["thigh"], L["shin"], [0.2, -1, 0])
    # raised leg (near side): thigh toward the chest, shin hanging forward-up, foot relaxed
    leg = ang - TUCK                  # neck->pelvis is `ang`; the thigh swings up from the hip
    p["kneeL"] = P(p["hipL"], leg, L["thigh"])
    p["ankleL"] = P(p["kneeL"], leg + SHIN, L["shin"])
    p["toeL"] = P(p["ankleL"], leg + SHIN - 55, L["foot"])
    for s, k in (("L", 1), ("R", -1)):
        p["elbow" + s] = P(p["shoulder" + s], 2, L["upper"], k * ARM_OUT)
        p["hand" + s] = P(p["elbow" + s], 2, L["fore"], k * 4)
    return p


start, end = pose(TORSO_START), pose(TORSO_END)
for k in ("neck", "head", "shoulderL", "shoulderR", "elbowL", "handL", "elbowR", "handR", "ankleR", "toeR"):
    end[k] = list(start[k])
write("single-leg-glute-bridge", start, end, (), {"type": "none"}, tempo=2.8)
