"""Captain's chair knee raise: side view, back on the upright pad, forearms on the arm rests, hands on the
grips, legs hanging; the knees come up bent to the chest while the pelvis curls off the pad, then lower."""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rig import L, P, along, joint, trunk, mirror, slab, line, write

NECK = [96, 46, 0]
FLOOR = 194
ELBOW_Z = 17
PAD_X = 86                             # back pad, 10 behind the torso line
POST_X, POST_Z = 78, 20


def pose(torso, thigh, shin, toe):
    """torso: neck -> pelvis angle (90 hanging straight; more swings the pelvis forward)."""
    pelvis = P(NECK, torso, L["torso"])
    p = trunk(pelvis, torso + 180, head_ang=-90)
    p["elbowL"] = [NECK[0] + 1, NECK[1] + (L["upper"] ** 2 - 1 - 2 ** 2) ** 0.5, ELBOW_Z]
    p["handL"] = [p["elbowL"][0] + L["fore"], p["elbowL"][1], ELBOW_Z]
    p["kneeL"] = P(p["hipL"], thigh, L["thigh"])
    p["ankleL"] = P(p["kneeL"], shin, L["shin"])
    p["toeL"] = P(p["ankleL"], toe, L["foot"])
    return mirror(p)


def chair(elbow, hand):
    rest_y = elbow[1] + 7
    props = [slab([[PAD_X, NECK[1] + 2], [PAD_X, NECK[1] + 58]], -13, 13, 8)]           # back pad
    for z in (-POST_Z, POST_Z):
        props.append(line([[POST_X, NECK[1] - 4, z], [POST_X, FLOOR - 1, z]], 5))       # upright
        props.append(line([[POST_X, rest_y + 3, z], [hand[0] + 3, rest_y + 3, z]], 4))  # arm rest frame
        props.append(line([[POST_X - 12, FLOOR - 1, z], [POST_X + 30, FLOOR - 1, z]], 5))  # base
    for k in (-1, 1):
        props.append(slab([[elbow[0] - 6, rest_y], [hand[0] - 3, rest_y]], k * 13, k * 21, 6))  # rest pad
        props.append(line([[hand[0] + 3, rest_y + 3, k * ELBOW_Z], [hand[0] + 3, hand[1] - 6, k * ELBOW_Z]], 5))  # grip
    props.append(line([[POST_X, NECK[1] + 60, 0], [POST_X, NECK[1] + 60, POST_Z]], 4))
    return props


if __name__ == "__main__":
    start = pose(90, 86, 93, 45)
    end = pose(102, -58, 66, 15)
    write("captains-chair-knee-raise", start, end, chair(start["elbowL"], start["handL"]), None,
          tempo=2.8, floor=FLOOR, yaw=20)
