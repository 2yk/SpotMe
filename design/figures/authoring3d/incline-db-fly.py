"""Incline DB fly: back on a bench inclined about 30 degrees, feet on the floor, palms facing in, elbows softly
bent the whole rep. The arms open wide to a stretch, dumbbells level with the chest out to the sides, then hug
up and together over the face. Body and bench as incline-db-press (same 30-degree bench); the movement is wide
(in depth), so it opens turned."""
import os, sys, math
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rig import L, P, along, joint, slab, line, write

BODY = {
    "pelvis": [98, 140, 0],
    "neck": [54.7, 115.0, 0.0],
    "head": [38.9, 108.6, 0.0],
    "shoulderL": [54.7, 115.0, 15.0],
    "shoulderR": [54.7, 115.0, -15.0],
    "hipL": [98, 140, 9],
    "hipR": [98, 140, -9],
    "kneeL": [135.6, 139.2, 14.6],
    "ankleL": [139.0, 175.0, 15.0],
    "toeL": [151.4, 178.8, 15.0],
    "kneeR": [135.5, 139.0, -14.9],
    "ankleR": [134.0, 175.0, -15.0],
    "toeR": [146.4, 178.8, -15.0]}

pel, nk = BODY["pelvis"], BODY["neck"]
t = [nk[0] - pel[0], nk[1] - pel[1]]
tl = math.hypot(*t)
t = [t[0] / tl, t[1] / tl]                # pelvis -> neck, along the back
up = [-t[1], t[0]]                        # off the chest, away from the bench
if up[1] > 0:
    up = [-up[0], -up[1]]
REACH = 49                                # shoulder to hand, elbows soft


def arm(side, d_up, d_out, d_head, bend):
    """Hand from the shoulder along up (off the chest), out (to this side) and toward the head."""
    k = 1 if side == "L" else -1
    sh = BODY["shoulder" + side]
    d = [up[0] * d_up + t[0] * d_head, up[1] * d_up + t[1] * d_head, k * d_out]
    hand = along(sh, d, REACH)
    elbow = joint(sh, hand, L["upper"], L["fore"], [bend[0], bend[1], k * bend[2]])
    return elbow, hand


def pose(d_up, d_out, d_head, bend):
    p = {k: list(v) for k, v in BODY.items()}
    for s in "LR":
        p["elbow" + s], p["hand" + s] = arm(s, d_up, d_out, d_head, bend)
    return p


start = pose(-0.12, 1, 0.08, [0, 0.6, 0.3])       # wide open, dumbbells level with the chest, elbows down
end = pose(1, -0.16, 0.12, [0, 0.4, 1])           # over the face, dumbbells nearly touching, elbows out
end["handL"][2], end["handR"][2] = max(end["handL"][2], 6), min(end["handR"][2], -6)

PAD = 9
base = [pel[0] - up[0] * PAD, pel[1] - up[1] * PAD]
SEAT_Y = 151
k = (SEAT_Y - 2 - base[1]) / t[1]
pad_low = [base[0] + t[0] * k, base[1] + t[1] * k]
pad_top = [base[0] + t[0] * 68, base[1] + t[1] * 68]
props = [slab([pad_low, pad_top], -12, 12, 7),                     # back pad
         slab([[88, SEAT_Y], [124, SEAT_Y]], -12, 12, 7),           # seat
         line([[104, 153, 0], [104, 181, 0]], 5),                   # seat post
         slab([[84, 181], [124, 181]], -14, 14, 4),                 # base
         line([[88.6, 144, 0], [104, 165, 0]], 4)]                  # brace under the back pad
load = {"type": "dumbbells", "axis": [t[0], t[1], 0]}              # handles along the back: palms face in
write("incline-db-fly", start, end, props, load, tempo=3, yaw=55)
