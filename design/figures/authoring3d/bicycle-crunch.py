"""Bicycle crunch: on the back, shoulders curled about 25 off the floor, hands at the sides of the head with
the elbows forward. Start: the left knee pulled in over the hips (thigh vertical, shin level) and the
shoulders turned a little toward it, the right leg long and low. End: the same with the legs swapped."""
import math, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rig import L, P, along, joint, trunk, write

PELVIS = [108, 176, 0]
CURL = 205                            # pelvis -> neck: shoulders about 25 off the floor
TURN = 20                             # shoulder turn toward the bent knee: about 10 units of depth between them
LEG_LONG = -15                        # the long leg


def start_pose():
    p = trunk(PELVIS, CURL, head_ang=CURL + 12)
    neck, head = p["neck"], p["head"]
    a = math.radians(CURL)
    up = [math.cos(a), math.sin(a), 0]
    front = [math.cos(a + math.pi / 2), math.sin(a + math.pi / 2), 0]     # chest normal, toward the ceiling
    t = math.radians(TURN)
    for s, k in (("L", 1), ("R", -1)):
        # turning toward the left knee: the right shoulder comes up off the floor, the left goes back
        d = [front[0] * -math.sin(t) * k, front[1] * -math.sin(t) * k, k * math.cos(t)]
        p["shoulder" + s] = along(neck, d, 15)
        ear = [head[i] - up[i] * 10 - front[i] * 2 for i in range(3)]
        ear[2] = k * 12
        # elbow forward toward the knees and a little out; the hand goes back from it to the ear
        p["elbow" + s] = along(p["shoulder" + s], [front[0] * 0.95 - up[0] * 0.1, front[1] * 0.95 - up[1] * 0.1,
                                                   k * 0.3], L["upper"])
        p["hand" + s] = along(p["elbow" + s], [ear[i] - p["elbow" + s][i] for i in range(3)], L["fore"])
    for s, bent in (("L", True), ("R", False)):
        hip = p["hip" + s]
        if bent:
            p["knee" + s] = P(hip, -90, L["thigh"])
            p["ankle" + s] = P(p["knee" + s], 0, L["shin"])
            p["toe" + s] = P(p["ankle" + s], -45, L["foot"])
        else:
            p["knee" + s] = P(hip, LEG_LONG, L["thigh"])
            p["ankle" + s] = P(p["knee" + s], LEG_LONG, L["shin"])
            p["toe" + s] = P(p["ankle" + s], -75, L["foot"])
    return p


def swap_legs(p):
    q = {k: list(v) for k, v in p.items()}
    for j in ("knee", "ankle", "toe"):
        for s, o in (("L", "R"), ("R", "L")):
            x, y, z = p[j + o]
            q[j + s] = [x, y, -z]
    for s, o in (("L", "R"), ("R", "L")):                                   # the turn goes the other way
        for j in ("shoulder", "elbow", "hand"):
            x, y, z = p[j + o]
            q[j + s] = [x, y, -z]
    return q


start = start_pose()
end = swap_legs(start)
write("bicycle-crunch", start, end, (), {"type": "none"}, tempo=2.6, yaw=10)
