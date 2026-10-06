"""Low-to-high cable fly: standing between two low pulleys, hands sweep from low and wide up and together in front of the chin."""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rig import L, P, along, joint, trunk, mirror, slab, line, write

PELVIS = [100, 101, 0]
HAND_START = [-40, 41, -4]      # from the neck: out at the side, hip height, a little behind
HAND_END = [-5, 4, 30]          # from the neck: in front of the chin, nearly together
ANCHOR = [16, 174, -14]         # low pulley on the viewer's left (mirrored for the right)


def pose(h, bend):
    p = trunk(PELVIS, -90, left=[-1, 0, 0])
    p["ankleL"] = [p["hipL"][0] - 2, 175, -2]
    p["toeL"] = along(p["ankleL"], [0, 0.3, 1], L["foot"])
    p["kneeL"] = joint(p["hipL"], p["ankleL"], L["thigh"], L["shin"], [0, 0, 1])
    n = p["neck"]
    hand = [n[0] + h[0], n[1] + h[1], n[2] + h[2]]
    p["handL"] = hand
    p["elbowL"] = joint(p["shoulderL"], hand, L["upper"], L["fore"], bend)
    for k in [k for k in p if k.endswith("L")]:
        x, y, z = p[k]
        p[k[:-1] + "R"] = [2 * PELVIS[0] - x, y, z]
    return p


start = pose(HAND_START, [-0.4, 0.3, -1])
end = pose(HAND_END, [-1, 0.6, 0])
for k in ("ankleL", "toeL", "kneeL", "ankleR", "toeR", "kneeR"):
    end[k] = start[k]
props = []
for s in (1, -1):
    px = 100 + s * (ANCHOR[0] - 100)
    props.append(slab([[px - 5, 181], [px + 5, 181]], ANCHOR[2] - 6, ANCHOR[2] + 6, 4))
    props.append(line([[px, 181, ANCHOR[2]], [px, ANCHOR[1] - 2, ANCHOR[2]]], 9))
load = [{"type": "cable", "handle": "grip", "at": "handL", "anchor": ANCHOR},
        {"type": "cable", "handle": "grip", "at": "handR", "anchor": [200 - ANCHOR[0], ANCHOR[1], ANCHOR[2]]}]
write("low-to-high-cable-fly", start, end, props, load, tempo=2.6, view="front")
