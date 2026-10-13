"""Seated cable row: sitting on the low seat of a row station, feet on the foot plates, knees soft; a V-handle
from arms reaching forward (a slight lean into the stretch) to the belly, elbows close and back past the body,
sitting tall. The cable runs level from a pulley between the feet; two cable grips from one pulley draw the V."""
import os, sys, math
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rig import L, P, along, joint, trunk, mirror, slab, line, write

PELVIS = [60, 151, 0]
SEAT_Y = 160
ANKLE = [132, 150, 11]
HZ = 4                                  # hands 4 either side of the middle: a V-handle
REACH = [111, 125]                      # hands at the stretch
PULL = [74, 122]                        # hands at the belly
T_START, T_END = -77, -91


def pose(hand, lean, s=None):
    p = trunk(PELVIS, lean, head_ang=lean - 3 if lean > -85 else -92)
    if s:
        for k in ("kneeL", "ankleL", "toeL", "hipL"):
            p[k] = s[k]
    else:
        p["ankleL"] = list(ANKLE)
        p["toeL"] = P(ANKLE, -78, L["foot"])                     # sole flat on the upright plate
        p["kneeL"] = joint(p["hipL"], p["ankleL"], L["thigh"], L["shin"], [0.2, -1, 0])
    p["handL"] = [hand[0], hand[1], HZ]
    p["elbowL"] = joint(p["shoulderL"], p["handL"], L["upper"], L["fore"], [-1, 0.25, 0.35])
    return mirror(p)


start = pose(REACH, T_START)
end = pose(PULL, T_END, start)
_t = (148 - PULL[0]) / (REACH[0] - PULL[0])
ANCHOR = [148, PULL[1] + (REACH[1] - PULL[1]) * _t, 0]        # on the line the hands travel
props = [slab([[36, SEAT_Y], [86, SEAT_Y]], -13, 13, 7),          # seat
         line([[60, 163, 0], [60, 181, 0]], 6),                   # seat post
         slab([[30, 181], [180, 181]], -14, 14, 4),               # floor rail
         slab([[138, 132], [141, 163]], 6, 20, 5),                # foot plates, a gap for the cable
         slab([[138, 132], [141, 163]], -20, -6, 5),
         line([[141, 163, 13], [150, 181, 13]], 4), line([[141, 163, -13], [150, 181, -13]], 4),
         line([[ANCHOR[0], ANCHOR[1] - 4, 0], [ANCHOR[0], ANCHOR[1] + 4, 0]], 9),   # pulley
         line([[ANCHOR[0], ANCHOR[1], 0], [172, ANCHOR[1], 0]], 5),
         line([[172, 181, 0], [172, 62, 0]], 6),                  # weight stack tower
         slab([[166, 70], [178, 70]], -12, 12, 4)]
load = [{"type": "cable", "handle": "grip", "at": "handL", "anchor": ANCHOR},
        {"type": "cable", "handle": "grip", "at": "handR", "anchor": ANCHOR}]
write("seated-cable-row", start, end, props, load, tempo=2.8)
