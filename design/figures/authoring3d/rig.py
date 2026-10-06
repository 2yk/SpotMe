"""Helpers for authoring 3D poses (poses3d/<id>.json). Run scripts from the figures folder:
python3 authoring3d/<id>.py writes poses3d/<id>.json; then python3 figure3d.py check.

Axes as in figure3d.py: x right, y down, z toward the viewer in the usual view. Angles in the x-y plane
use the 2D convention: 0 = right, 90 = down, -90 (or 270) = up, 180 = left.

  L                          bone lengths: torso 50, head 17, upper 27, fore 25, thigh 38, shin 36, foot 13
  P(parent, ang, length, out=0)
                             a point `length` from parent at angle `ang` in the x-y plane, tilted `out`
                             degrees toward +z (negative: away). The bone is always its true length.
  along(a, direction, length) a point `length` from a along a 3D direction [dx, dy, dz]
  joint(root, end, l1, l2, bend)
                             two-bone solve (knee or elbow): the joint l1 from root and l2 from end, bent
                             toward the direction `bend` (e.g. [1, 0, 0] knee forward, [0, 0, 1] elbow out).
                             If end is out of reach the limb is straight toward it (end is then not reached:
                             check prints the bone error).
  trunk(pelvis, ang, out=0, head_ang=None, left=(0, 0, 1))
                             pelvis, neck, head, hipL/R (9 either side) and shoulderL/R (15 either side) as a
                             dict. `left` is the body's left in the usual view: side view +z (the near
                             side), front view [-1, 0, 0]. head_ang defaults to the torso's angle.
  mirror(pose, z0=0)         adds the R twin of every ...L point, mirrored across the plane z = z0
                             (side-view figures whose two sides do the same thing). Returns pose.
  slab(points2d, z0, z1, w=7) and line(points3d, w=6)   grey props
  write(fid, start, end, props=(), load=None, tempo=2.6, view="side", floor=182, hold=False, yaw=0)
                             rounds every number to 0.1 and writes poses3d/<fid>.json. load: one load
                             object or a list of them. yaw: the opening view (written only when not 0).
Tip: build the start pose as a function of a few angles, call it twice (start, end), and copy fixed points
from start to end so they are identical (the checker asks for that).
"""
import json
import math
import os

L = {"torso": 50, "head": 17, "upper": 27, "fore": 25, "thigh": 38, "shin": 36, "foot": 13}
HERE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def _n(v):
    m = math.sqrt(sum(a * a for a in v))
    return [a / m for a in v]


def P(parent, ang, length, out=0):
    a, o = math.radians(ang), math.radians(out)
    return [parent[0] + math.cos(o) * math.cos(a) * length, parent[1] + math.cos(o) * math.sin(a) * length,
            parent[2] + math.sin(o) * length]


def along(a, direction, length):
    u = _n(direction)
    return [a[i] + u[i] * length for i in range(3)]


def joint(root, end, l1, l2, bend):
    d = [end[i] - root[i] for i in range(3)]
    D = math.sqrt(sum(x * x for x in d))
    if D >= l1 + l2 - 1e-6:
        return along(root, d, l1)
    u = [x / D for x in d]
    b = [bend[i] - sum(bend[j] * u[j] for j in range(3)) * u[i] for i in range(3)]
    b = _n(b)
    a = (l1 * l1 - l2 * l2 + D * D) / (2 * D)
    h = math.sqrt(max(0.0, l1 * l1 - a * a))
    return [root[i] + u[i] * a + b[i] * h for i in range(3)]


def trunk(pelvis, ang, out=0, head_ang=None, left=(0, 0, 1)):
    pelvis = list(pelvis)
    neck = P(pelvis, ang, L["torso"], out)
    head = P(neck, ang if head_ang is None else head_ang, L["head"], out)
    lf = _n(left)
    sh = lambda c, k: [c[i] + lf[i] * k for i in range(3)]
    return {"pelvis": pelvis, "neck": neck, "head": head, "shoulderL": sh(neck, 15), "shoulderR": sh(neck, -15),
            "hipL": sh(pelvis, 9), "hipR": sh(pelvis, -9)}


def mirror(pose, z0=0):
    for k in [k for k in pose if k.endswith("L")]:
        x, y, z = pose[k]
        pose[k[:-1] + "R"] = [x, y, 2 * z0 - z]
    return pose


def slab(points2d, z0, z1, w=7):
    return {"slab": [list(p) for p in points2d], "z": [z0, z1], "w": w}


def line(points3d, w=6):
    return {"line": [list(p) for p in points3d], "w": w}


def _r(v):
    if isinstance(v, (list, tuple)):
        return [_r(x) for x in v]
    if isinstance(v, dict):
        return {k: _r(x) for k, x in v.items()}
    if isinstance(v, float):
        r = round(v, 1)
        return int(r) if r == int(r) else r
    return v


def write(fid, start, end, props=(), load=None, tempo=2.6, view="side", floor=182, hold=False, yaw=0):
    fig = {"id": fid, "view": view, "floor": floor, "tempo": tempo, "hold": hold}
    if yaw:
        fig["yaw"] = _r(yaw)
    fig.update({"props": _r(list(props)), "load": _r(load or {"type": "none"}), "start": _r(start), "end": _r(end)})
    path = os.path.join(HERE, "poses3d", fid + ".json")
    with open(path, "w") as f:
        json.dump(fig, f, indent=1)
    print("wrote", path)
