"""Suspension trainer row: facing the anchor, heels on the floor, body straight and leaning back on two straps
from one point overhead; pull the hands to the ribs so the body rises toward the anchor, pivoting at the heels.
Straps are drawn as two cable loads with grip handles from the same anchor."""
import os, sys, math
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rig import L, P, along, joint, trunk, mirror, slab, line, write

ANKLE = [128, 174, 0]
BODY_START, BODY_END = -132, -116   # body line from the heels, leaning back up-left toward the head
ANCHOR = [178, 12, 0]
HAND_Z = 13


def body_point(ang, d):
    a = math.radians(ang)
    return [ANKLE[0] + math.cos(a) * d, ANKLE[1] + math.sin(a) * d]


def pose(ang, pulled):
    pelvis = body_point(ang, 74) + [0]
    p = trunk(pelvis, ang, head_ang=ang + 8)
    for s, z in (("L", 1), ("R", -1)):
        k = body_point(ang, 36)
        p["ankle" + s] = [ANKLE[0], ANKLE[1], z * 7]
        p["knee" + s] = [k[0], k[1], z * 8]
        p["toe" + s] = [ANKLE[0] + 12, ANKLE[1] + 3, z * 7.5]
        sh = p["shoulder" + s]
        to_anchor = [ANCHOR[0] - sh[0], ANCHOR[1] - sh[1], z * HAND_Z - sh[2]]
        if pulled:
            back = math.radians(ang + 180)                          # along the body toward the feet
            hand = along(sh, to_anchor, 16)
            hand = [hand[0] + math.cos(back) * 12, hand[1] + math.sin(back) * 12, z * HAND_Z]
            front = math.radians(ang + 90)
            bend = [-math.cos(front), -math.sin(front), z * 0.6]   # elbow behind the body
        else:
            hand = along(sh, to_anchor, 50.5)
            bend = [0, 1, z * 0.3]
        p["hand" + s] = hand
        p["elbow" + s] = joint(sh, hand, L["upper"], L["fore"], bend)
    return p


start, end = pose(BODY_START, False), pose(BODY_END, True)
for k in ("ankleL", "ankleR", "toeL", "toeR"):
    end[k] = start[k]
props = [line([[ANCHOR[0] - 8, ANCHOR[1] - 4, 0], [ANCHOR[0] + 12, ANCHOR[1] - 4, 0]], 6)]   # overhead beam
load = [{"type": "cable", "handle": "grip", "at": "handL", "anchor": ANCHOR},
        {"type": "cable", "handle": "grip", "at": "handR", "anchor": ANCHOR}]
write("suspension-trainer-row", start, end, props, load, tempo=2.6)
