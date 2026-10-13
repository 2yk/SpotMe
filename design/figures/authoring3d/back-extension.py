"""Back extension (45 degree bench): legs straight on the incline, heels against the foot pad, hip pad just below
the hips; arms crossed holding a plate to the chest. Hinge down until the torso hangs toward the floor, then rise
to one straight line from heels to head."""
import os, sys, math
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rig import L, P, along, joint, trunk, mirror, slab, line, write

ANKLE = [38, 152, 0]
LEG = -40                     # leg line angle (rising to the right)
TORSO_START, TORSO_END = 58, -40   # hinged down toward the floor, then in line with the legs
PAD_OFF = 12                  # pad surface below the thigh line


def pose(t):
    a = math.radians(LEG)
    pelvis = [ANKLE[0] + math.cos(a) * 74, ANKLE[1] + math.sin(a) * 74, 0]
    p = trunk(pelvis, t, head_ang=t + (12 if t > 0 else 0))
    for s, z in (("L", 1), ("R", -1)):
        k = [ANKLE[0] + math.cos(a) * 36, ANKLE[1] + math.sin(a) * 36]
        p["ankle" + s] = [ANKLE[0], ANKLE[1], z * 8]
        p["knee" + s] = [k[0], k[1], z * 8.5]
        p["toe" + s] = P(p["ankle" + s], LEG + 90 + 15, L["foot"])
        # arms crossed: each hand on the opposite side of the chest, elbows in front
        tr = math.radians(t)
        chest = [p["neck"][0] - math.cos(tr) * 12, p["neck"][1] - math.sin(tr) * 12]
        front = [math.cos(tr + math.pi / 2), math.sin(tr + math.pi / 2)]   # chest side (the body is face down)
        hand = [chest[0] + front[0] * 9, chest[1] + front[1] * 9, -z * 4]
        p["hand" + s] = hand
        p["elbow" + s] = joint(p["shoulder" + s], hand, L["upper"], L["fore"],
                               [front[0], front[1], z * 0.8])
    return p


start, end = pose(TORSO_START), pose(TORSO_END)
for k in ("ankleL", "ankleR", "toeL", "toeR", "kneeL", "kneeR", "pelvis", "hipL", "hipR"):
    end[k] = start[k]
a = math.radians(LEG)
nrm = [math.cos(a + math.pi / 2), math.sin(a + math.pi / 2)]       # below the leg line
def on_leg(d, off):
    return [ANKLE[0] + math.cos(a) * d + nrm[0] * off, ANKLE[1] + math.sin(a) * d + nrm[1] * off]
pad0, pad1 = on_leg(56, PAD_OFF), on_leg(70, PAD_OFF)
heel0, heel1 = on_leg(-4, -2), on_leg(-4, 14)
frame = on_leg(4, 22)
props = [slab([pad0, pad1], -12, 12, 11),                         # hip pad
         slab([heel0, heel1], -10, 10, 6),                       # heel pad
         slab([on_leg(-2, 9), on_leg(2, 12)], -10, 10, 5),       # foot plate
         line([[frame[0], frame[1], 0], [pad0[0] + nrm[0] * 6, pad0[1] + nrm[1] * 6, 0]], 6),   # frame rail
         line([[pad0[0] + nrm[0] * 6, pad0[1] + nrm[1] * 6, 0], [pad0[0] + 10, 181, 0]], 6),    # front leg
         line([[frame[0], frame[1], 0], [frame[0], 181, 0]], 6),                               # back leg
         slab([[frame[0] - 8, 181], [pad0[0] + 18, 181]], -18, 18, 4)]
load = {"type": "held", "kind": "plate", "at": ["handL", "handR"]}
write("back-extension", start, end, props, load, tempo=3.0)
