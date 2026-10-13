"""DB walking lunge: side view, dumbbells hanging at the sides. Start at the bottom of a long lunge (front shin
near vertical, back knee just off the floor); drive up and forward over the front foot while the back (near)
leg swings through, knee forward, ready for the next step. The body travels forward over the planted foot,
which tells it from a reverse lunge (travels back) and a split squat (both feet stay put).
Legs of the lunge as in reverse-lunge.py; the planted front foot is the far leg (R)."""
import os, sys, math
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rig import L, P, along, joint, trunk, mirror, slab, line, write

FRONT = [128, 175, -10]               # the planted foot (far leg, R)


def arms(p):
    for s, z, dx in (("L", 1, 0), ("R", -1, -3)):
        sh = p["shoulder" + s]
        p["elbow" + s] = P(sh, 91, L["upper"], z * 4)
        p["hand" + s] = P(p["elbow" + s], 89, L["fore"], z * 2)
    return p


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


def passing():
    p = trunk([FRONT[0] - 3, 104, 0], -86, head_ang=-88)
    p["ankleR"] = list(FRONT)
    p["kneeR"] = joint(p["hipR"], p["ankleR"], L["thigh"], L["shin"], [1, 0, 0])
    p["kneeL"] = P(p["hipL"], 22, L["thigh"])                           # back leg swings through, knee forward
    p["ankleL"] = P(p["kneeL"], 98, L["shin"])
    p["toeL"] = P(p["ankleL"], 10, L["foot"])
    return arms(p)


start, end = lunge(), passing()
start["toeR"] = P(FRONT, 17, L["foot"])
start["toeR"][1] = 179
end["toeR"] = start["toeR"]
write("walking-lunge", start, end, [], {"type": "dumbbells", "axis": [1, 0, 0]}, tempo=3.0)
