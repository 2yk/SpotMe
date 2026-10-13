"""Bodyweight reverse lunge: standing tall, hands on the hips (elbows out), no load; the near leg steps back and the back knee
drops toward the floor (front shin near vertical, front thigh near level), then the near leg comes back to stand.
The front (far) foot stays planted; the body travels back, which tells it from a split squat or a forward lunge.
Built from reverse-lunge.py (same legs), with the arms changed: hands on the hips tell it from the DB version."""
import os, sys, math
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rig import L, P, along, joint, trunk, mirror, slab, line, write

FRONT = [124, 175, -10]               # the planted foot (far leg, R)
HAND_Z = 19


def arms(p, sx=0):
    for s, z in (("L", 1), ("R", -1)):
        hand = [p["pelvis"][0] + 3, p["pelvis"][1] - 9, z * 13]          # hands on the hips
        p["hand" + s] = hand
        p["elbow" + s] = joint(p["shoulder" + s], hand, L["upper"], L["fore"], [-0.35, 0, z])
    return p


def stand():
    p = trunk([121, 105, 0], -90)
    p["ankleR"], p["ankleL"] = list(FRONT), [121, 175, 10]
    p["toeR"], p["toeL"] = P(FRONT, 17, L["foot"]), P(p["ankleL"], 17, L["foot"])
    for s in "LR":
        p["toe" + s][1] = 179
        p["knee" + s] = joint(p["hip" + s], p["ankle" + s], L["thigh"], L["shin"], [1, 0, 0])
    return arms(p)


def lunge():
    knee = P(FRONT, -80, L["shin"])
    hipR = P(knee, 189, L["thigh"])
    pel = [hipR[0], hipR[1], 0]
    p = trunk(pel, -87, head_ang=-88)
    p["ankleR"], p["kneeR"] = list(FRONT), [knee[0], knee[1], -10]
    p["hipR"] = [pel[0], pel[1], -9]
    kL = P(p["hipL"], 101, L["thigh"])
    p["kneeL"] = [kL[0], kL[1], 10]                                     # back knee just off the floor
    p["ankleL"] = P(p["kneeL"], 185, L["shin"])
    dy = 179 - p["ankleL"][1]
    p["toeL"] = P(p["ankleL"], math.degrees(math.asin(min(1, dy / L["foot"]))), L["foot"])   # on the toes
    return arms(p)


start, end = stand(), lunge()
end["toeR"] = start["toeR"]
write("bodyweight-reverse-lunge", start, end, [], None, tempo=2.8)
