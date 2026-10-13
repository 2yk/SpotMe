"""Stir the pot: forearm plank with the forearms on top of a stability ball, hands together, body straight from
the shoulders to the toes on the floor. The forearms stir the ball in small circles; the body stays still. Two
poses cannot draw a circle, so the elbows move from forward-left to back-right (a diagonal stir that shows the
circle's extent when turned).
The ball, as in stability-ball-rollout: a `pad` with almost no length and the ball's diameter as its width,
a filled volt circle that shifts with the forearms."""
import math, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rig import L, P, along, joint, trunk, mirror, write

GROUND = 177.5
BALL_R = 23
FOREARM_Y = 182 - 2 * BALL_R - 5     # forearm line resting on top of the ball
SHOULDER_X = 132
FOOT = 70                            # ankle -> toe: toes tucked under
ELBOW_Z, HAND_Z = 9, 3


def body():
    neck = [SHOULDER_X, FOREARM_Y - L["upper"] + 1, 0]
    ankle_y = GROUND - L["foot"] * math.sin(math.radians(FOOT))
    tilt = math.degrees(math.asin((ankle_y - neck[1]) / (L["torso"] + L["thigh"] + L["shin"])))
    pelvis = P(neck, 180 - tilt, L["torso"])
    p = trunk(pelvis, -tilt, head_ang=-tilt - 6)
    p["neck"], p["shoulderL"], p["shoulderR"] = neck, [neck[0], neck[1], 15], [neck[0], neck[1], -15]
    p["head"] = P(neck, -tilt - 6, L["head"])
    p["kneeL"] = P([pelvis[0], pelvis[1], 9], 180 - tilt, L["thigh"])
    p["ankleL"] = P(p["kneeL"], 180 - tilt, L["shin"])
    p["toeL"] = P(p["ankleL"], FOOT, L["foot"])
    return mirror(p)


def arms(p, dx, dz):
    """Forearms on the ball, elbows shifted dx forward and dz toward the viewer from under the shoulders."""
    for s, k in (("L", 1), ("R", -1)):
        sh = p["shoulder" + s]
        ez = ELBOW_Z * k + dz
        ex = sh[0] + dx
        elbow = [ex, sh[1] + math.sqrt(L["upper"] ** 2 - dx ** 2 - (ez - sh[2]) ** 2), ez]
        hz = HAND_Z * k + dz
        hand = [ex + math.sqrt(L["fore"] ** 2 - (hz - ez) ** 2 - (FOREARM_Y - elbow[1]) ** 2), FOREARM_Y, hz]
        p["elbow" + s], p["hand" + s] = elbow, hand
    return p


start = arms(body(), 6, 5)
end = arms(body(), -3, -5)
load = {"type": "pad", "at": ["elbowL", "elbowR", "handL", "handR"], "offset": [0, BALL_R + 5, 0],
        "length": 0.5, "w": 2 * BALL_R}
write("stir-the-pot", start, end, [], load, tempo=3.0)
