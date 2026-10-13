"""Seated DB lateral raise: front view, sitting tall on the end of a flat bench that runs back behind the body,
feet flat, knees toward the viewer. Arms from hanging beside the bench to straight out at shoulder height."""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rig import L, P, along, joint, trunk, mirror, slab, line, write

PELVIS = [100, 136, 0]
LEFT = [-1, 0, 0]


def legs(p):
    for s, dx in (("L", -1), ("R", 1)):
        hip = p["hip" + s]
        p["ankle" + s] = [hip[0] + dx * 5, 175, hip[2] + 36]
        p["toe" + s] = along(p["ankle" + s], [dx * 0.2, 0, 1], L["foot"])
        p["knee" + s] = joint(hip, p["ankle" + s], L["thigh"], L["shin"], [0, -1, 1])


def pose(upper, fore, out_u, out_f):
    p = trunk(PELVIS, -90, left=LEFT)
    legs(p)
    p["elbowL"] = P(p["shoulderL"], upper, L["upper"], out_u)
    p["handL"] = P(p["elbowL"], fore, L["fore"], out_f)
    p["elbowR"] = P(p["shoulderR"], 180 - upper, L["upper"], out_u)
    p["handR"] = P(p["elbowR"], 180 - fore, L["fore"], out_f)
    return p


start = pose(106, 99, 2, 6)         # hanging beside the bench, dumbbells a little in front of the hips
end = pose(180, 171, 8, 14)         # upper arm level with the shoulder, hand just below the elbow
for k in ("pelvis", "neck", "head", "shoulderL", "shoulderR", "hipL", "hipR", "kneeL", "ankleL", "toeL",
          "kneeR", "ankleR", "toeR"):
    end[k] = start[k]
props = [slab([[88, 145], [112, 145]], -64, 8, 7)]          # bench top, running back from under the hips
for z in (-56, 0):
    props.append(line([[91, 148, z], [91, 181, z]], 5))
    props.append(line([[109, 148, z], [109, 181, z]], 5))
write("seated-db-lateral-raise", start, end, props, {"type": "dumbbells", "axis": [0, 0, 1]}, tempo=2.6,
      view="front", yaw=20)
