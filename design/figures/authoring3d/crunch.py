"""Crunch: on the back on the floor, knees bent, feet flat, fingertips at the temples with the elbows out; the
ribs curl toward the hips until the shoulder blades are off the floor, the low back stays down."""
import math, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rig import L, P, along, joint, trunk, write

PELVIS = [112, 176, 0]
TORSO_START, TORSO_END = 182, 212      # pelvis -> neck: shoulders down, then curled up
ANKLE = [160, 175]
FEET = 9


def temples(p, ang):
    """Fingertips at the sides of the head, elbows flared out wide."""
    a = math.radians(ang)
    up = [math.cos(a), math.sin(a), 0]                       # pelvis -> neck
    front = [math.cos(a + math.pi / 2), math.sin(a + math.pi / 2), 0]
    if front[1] > 0:
        front = [-front[0], -front[1], 0]                      # chest normal, toward the ceiling
    for s, k in (("L", 1), ("R", -1)):
        ear = [p["head"][i] - up[i] * 3 + front[i] * 1 for i in range(3)]
        ear[2] = k * 11
        p["hand" + s] = ear
        p["elbow" + s] = joint(p["shoulder" + s], ear, L["upper"], L["fore"],
                               [front[0] * 0.3, front[1] * 0.3, k * 1.0])
    return p


def pose(torso):
    p = trunk(PELVIS, torso, head_ang=torso + (15 if torso < 190 else 22))
    temples(p, torso)
    for s, k in (("L", 1), ("R", -1)):
        p["ankle" + s] = [ANKLE[0], ANKLE[1], k * FEET]
        p["toe" + s] = [ANKLE[0] + 12.4, 179, k * FEET]
        p["knee" + s] = joint(p["hip" + s], p["ankle" + s], L["thigh"], L["shin"], [0.2, -1, 0])
    return p


if __name__ == "__main__":
    start, end = pose(TORSO_START), pose(TORSO_END)
    for k in ("pelvis", "hipL", "hipR", "kneeL", "ankleL", "toeL", "kneeR", "ankleR", "toeR"):
        end[k] = list(start[k])
    write("crunch", start, end, (), {"type": "none"}, tempo=2.4, yaw=340)
