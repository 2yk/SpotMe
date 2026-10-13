"""Cable pull-through: standing facing away from a low pulley, feet a little wider than the hips, a rope between
the legs held in both hands, arms long. From hips pushed back (a hinge, torso about 45 degrees, knees soft, hands
drawn back between the thighs) to standing tall with the hips through, hands in front of the hips."""
import os, sys, math
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rig import L, P, along, joint, trunk, mirror, slab, line, write

ANKLE = [112, 175, 14]
ANCHOR = [50, 172, 0]               # low pulley behind the person
HZ = 4


def pose(pelvis, torso, hand_ang, s=None):
    p = trunk(pelvis + [0], torso, head_ang=torso + (28 if torso > -60 else 0))
    if s:
        for k in ("ankleL", "toeL"):
            p[k] = s[k]
    else:
        p["ankleL"] = list(ANKLE)
        p["toeL"] = [ANKLE[0] + 12.4, 179, ANKLE[2] + 1]
    p["kneeL"] = joint(p["hipL"], p["ankleL"], L["thigh"], L["shin"], [1, -0.2, 0.15])
    h = P(p["shoulderL"], hand_ang, L["upper"] + L["fore"] - 1)
    p["handL"] = [h[0], h[1], HZ]
    p["elbowL"] = joint(p["shoulderL"], p["handL"], L["upper"], L["fore"], [-1, 0, 0.3])
    return mirror(p)


start = pose([86, 109], -40, 101)        # hips back, hands pulled back between the legs
end = pose([107, 104], -91, 87, start)   # tall, hips through, hands at the front of the hips
props = [line([[40, 181, 0], [40, 46, 0]], 6),                        # cable column
         line([[40, ANCHOR[1], 0], [ANCHOR[0], ANCHOR[1], 0]], 5),
         line([[ANCHOR[0], ANCHOR[1] - 4, 0], [ANCHOR[0], ANCHOR[1] + 3, 0]], 8),   # pulley
         slab([[30, 181], [56, 181]], -14, 14, 4)]
load = {"type": "cable", "handle": "rope", "anchor": ANCHOR}
write("cable-pull-through", start, end, props, load, tempo=2.8, yaw=-28)
