"""Pike push-up: hands and toes on the floor, hips high, body an upside-down V, legs straight. The elbows bend
and the head lowers toward the floor just in front of the hands, then presses back up. Feet and hands stay put."""
import math, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rig import L, P, along, joint, trunk, mirror, slab, line, write

GROUND = 177.5
TOE = [62, GROUND]
FOOT = 50                            # ankle -> toe: up on the balls of the feet
HAND_Z = 18
LEG = L["thigh"] + L["shin"]
ANKLE = [TOE[0] - L["foot"] * math.cos(math.radians(FOOT)), GROUND - L["foot"] * math.sin(math.radians(FOOT))]
HAND_X = 127


def pose(leg_ang, torso_ang, head_ang, s=None):
    """leg_ang: ankle -> pelvis direction; torso_ang: pelvis -> neck direction (2D degrees)."""
    pelvis = P([ANKLE[0], ANKLE[1], 0], leg_ang, LEG)
    p = trunk(pelvis, torso_ang, head_ang=head_ang)
    for s_, k in (("L", 1), ("R", -1)):
        hip = p["hip" + s_]
        p["ankle" + s_] = [ANKLE[0], ANKLE[1], 8 * k]
        p["toe" + s_] = P(p["ankle" + s_], FOOT, L["foot"])
        p["knee" + s_] = joint(hip, p["ankle" + s_], L["thigh"], L["shin"], [1, -1, 0])
        hand = [HAND_X, GROUND, HAND_Z * k]
        p["hand" + s_] = hand
        p["elbow" + s_] = joint(p["shoulder" + s_], hand, L["upper"], L["fore"], [-0.6, -0.5, 1.2 * k])
    return p


def solve(f, lo, hi):
    for _ in range(60):
        mid = (lo + hi) / 2
        if (f(lo) > 0) == (f(mid) > 0):
            lo = mid
        else:
            hi = mid
    return (lo + hi) / 2


def start_pose(torso_ang):
    """Arms straight: the leg angle that puts the shoulder an arm's length (50) from the hand."""
    def gap(a):
        pel = P([ANKLE[0], ANKLE[1], 0], a, LEG)
        nk = P(pel, torso_ang, L["torso"])
        return math.hypot(nk[0] - HAND_X, nk[1] - GROUND) - 50
    a = solve(gap, -89, -30)
    return pose(a, torso_ang, torso_ang + 12)


def end_pose(head, head_ang):
    """Head at this point: the torso angle that keeps the pelvis a straight leg from the ankle."""
    nk = P([head[0], head[1], 0], head_ang + 180, L["head"])
    def gap(t):
        pel = P(nk, t + 180, L["torso"])
        return math.hypot(pel[0] - ANKLE[0], pel[1] - ANKLE[1]) - LEG
    t = solve(gap, 20, 89)
    pel = P(nk, t + 180, L["torso"])
    a = math.degrees(math.atan2(pel[1] - ANKLE[1], pel[0] - ANKLE[0]))
    return pose(a, t, head_ang)


start = start_pose(56)               # arms straight, in line with the back
end = end_pose([HAND_X + 4, 166], 80)   # crown of the head just in front of the hands, elbows bent back and out
for k in ("ankleL", "toeL", "ankleR", "toeR", "handL", "handR"):
    end[k] = start[k]
write("pike-push-up", start, end, [], None, tempo=2.8, yaw=25)
