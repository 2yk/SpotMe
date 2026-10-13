"""Kneeling side plank: on the right forearm, knees bent and stacked with the shins back behind the body, front
of the body toward the viewer. Hips lifted so knees, hips and shoulders are in one line; top arm reaching
straight up to the ceiling (the side-plank signature). Hold."""
import math, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rig import L, P, along, joint, trunk, write

GROUND = 177.5
SHOULDER_R = [146, GROUND - L["upper"], 0]   # bottom shoulder straight above the bottom elbow


def add(a, b, k=1):
    return [a[i] + b[i] * k for i in range(3)]


def frame(tilt):
    a = math.radians(-tilt)
    head_dir = [math.cos(a), math.sin(a), 0]        # pelvis -> neck
    left = [math.sin(a), -math.cos(a), 0]           # up off the floor (the body's left)
    return head_dir, left


def knee_r_y(tilt):
    head_dir, left = frame(tilt)
    neck = add(SHOULDER_R, left, 15)
    pelvis = add(neck, head_dir, -L["torso"])
    return add(add(pelvis, left, -9), head_dir, -L["thigh"])[1]


lo, hi = 0.0, 40.0                                   # tilt so the bottom knee rests on the floor
for _ in range(60):
    mid = (lo + hi) / 2
    lo, hi = (mid, hi) if knee_r_y(mid) < GROUND else (lo, mid)
TILT = (lo + hi) / 2


def pose(lift):
    head_dir, left = frame(TILT)
    neck = add(SHOULDER_R, left, 15)
    pelvis = add(neck, head_dir, -L["torso"])
    p = trunk(pelvis, -TILT, left=left)
    p["head"] = P(neck, -TILT, L["head"])
    p["elbowR"] = [SHOULDER_R[0], GROUND, 0]
    p["handR"] = along(p["elbowR"], [0.55, 0, 1], L["fore"])
    p["kneeR"] = add(p["hipR"], head_dir, -L["thigh"])
    p["kneeL"] = add(p["hipL"], head_dir, -L["thigh"])
    p["ankleR"] = along(p["kneeR"], [-0.12, 0, -1], L["shin"])              # shin back along the floor
    p["ankleR"][1] = GROUND
    p["ankleL"] = add(p["ankleR"], left, 9)                                  # top shin stacked on it
    for s in "LR":
        p["toe" + s] = along(p["ankle" + s], [-0.2, 0.1, -1], L["foot"])
    p["toeR"][1] = GROUND
    p["elbowL"] = P(p["shoulderL"], -90, L["upper"])                         # top arm straight up
    p["handL"] = P(p["elbowL"], -90, L["fore"])
    if lift:
        for k in ("pelvis", "hipL", "hipR"):
            p[k] = add(p[k], left, lift)
    return p


start, end = pose(0), pose(2)
# opening view: chest to the viewer, turned a little so the shins, bent back behind the body, show
write("kneeling-side-plank", start, end, [], None, tempo=4, hold=True, yaw=20)
