#!/usr/bin/env python3
"""SpotMe form figures that turn: poses with depth, drawn from any angle. Rules: FIGURES.md, "Turning a figure".

  python3 figure3d.py check
  python3 figure3d.py svg <id> [--yaw DEG] [--still] [--pose start|end] [--size N]
  python3 figure3d.py turn <id> [--size N] [--seconds S]
  python3 figure3d.py sheet <out.html>

Importable: from figure3d import svg, turn_svg

Pose files: poses3d/<id>.json, the 2D format with [x, y, z] points. x right, y down, z toward the viewer
in the figure's usual view. All seventeen body points (shoulders and hips too). Side view: L is the
near side (+z). Front view: L is the viewer's left (-x).

Props (grey, static), two primitives:
  {"line": [[x,y,z], ...], "w": 6}        a 3D polyline with round caps and joins (posts, braces, a bar)
  {"slab": [[x,y], ...], "z": [z0, z1], "w": 7}
                                          a 2D polyline in the x-y plane swept from z0 to z1: bench pads,
                                          seats, bases, panels. Drawn as the filled swept surface with a
                                          w-wide rounded outline, so edge-on (yaw 0) it is the 2D line.
Load: as in 2D. "dumbbells" gain "axis": [x, y, z] (default [1, 0, 0]): each hand holds its own bar,
18 long along the axis, with 13-long end caps across it.

Drawing: the scene turns by `yaw` degrees about the vertical axis through the middle of the figure
(yaw 90 shows the side that faced +x), orthographic projection. Depth-sorted parts: each limb (its
dumbbell rides with the arm), the torso, the head, each prop. A limb is blended from #FFFFFF to
#6E6E73 by how far behind the torso's middle it is (upper bone 3 behind: still white; 15 behind: fully dim); a limb drawn after the torso
gets the black edge. One square crop per figure holds every angle (5 deg steps) and both poses.

Turning SVG: each part's geometry is written once in <defs> (ids prefixed with the figure id) with
every coordinate and colour as a `values` list, one entry per frame, linear. Ids are
<figure id>-turn-<part> (and <figure id>-y<yaw>-<part> for reps at a fixed angle). The draw order is a stack
of slots; a part gets a <use> in every slot it ever occupies, shown only at the frames it holds that
slot (discrete `opacity`). Limbs in slots above the torso carry their black edge.
"""
import json
import math
import os
import sys

from figure import (LENGTH, TOL, WHITE, FAR, PROP, FLOOR, VOLT, LIMB_W, TORSO_W, HEAD_R,
                    HALO, HALO_W, HALO_TRIM, AIR, MIN_SIDE, f1, merge)

HERE = os.path.dirname(os.path.abspath(__file__))
POSES3D = os.path.join(HERE, "poses3d")
BODY3D = ["head", "neck", "pelvis", "shoulderL", "shoulderR", "hipL", "hipR", "elbowL", "handL",
          "elbowR", "handR", "kneeL", "ankleL", "toeL", "kneeR", "ankleR", "toeR"]
DIM_DEPTH = 15.0   # fully dim this far behind the torso
DIM_FROM = 3.0     # starts dimming this far behind
CROP_STEP = 5


def load(fid):
    with open(os.path.join(POSES3D, fid + ".json")) as f:
        return json.load(f)


def all_ids():
    return sorted(n[:-5] for n in os.listdir(POSES3D) if n.endswith(".json"))


def dist(a, b):
    return math.sqrt(sum((x - y) ** 2 for x, y in zip(a, b)))


def bones():
    out = [("neck-pelvis", "neck", "pelvis", LENGTH["torso"]), ("neck-head", "neck", "head", LENGTH["head"])]
    for s in "LR":
        out += [(f"neck-shoulder{s}", "neck", "shoulder" + s, 15), (f"pelvis-hip{s}", "pelvis", "hip" + s, 9),
                (f"shoulder{s}-elbow{s}", "shoulder" + s, "elbow" + s, LENGTH["upper"]),
                (f"elbow{s}-hand{s}", "elbow" + s, "hand" + s, LENGTH["fore"]),
                (f"hip{s}-knee{s}", "hip" + s, "knee" + s, LENGTH["thigh"]),
                (f"knee{s}-ankle{s}", "knee" + s, "ankle" + s, LENGTH["shin"]),
                (f"ankle{s}-toe{s}", "ankle" + s, "toe" + s, LENGTH["foot"])]
    return out


# ---------- check ----------

def is3(v):
    return isinstance(v, list) and len(v) == 3 and all(isinstance(c, (int, float)) for c in v)


def check_one(fid):
    errors = []
    try:
        fig = load(fid)
    except (OSError, ValueError) as e:
        return [f"cannot read: {e}"]
    if fig.get("id") != fid:
        errors.append(f"id {fig.get('id')!r} does not match file name {fid!r}")
    poses = {}
    for name in ("start", "end"):
        p = fig.get(name)
        if not isinstance(p, dict):
            errors.append(f"{name}: missing")
            continue
        missing = [k for k in BODY3D if k not in p]
        if missing:
            errors.append(f"{name}: missing points {', '.join(missing)}")
        bad = [k for k, v in p.items() if not is3(v)]
        for k in bad:
            errors.append(f"{name}.{k}: not [x, y, z]")
        if not missing and not bad:
            poses[name] = p
    for name, p in poses.items():
        for bname, a, b, length in bones():
            d = dist(p[a], p[b])
            tol = 1.5 / length if bname.startswith(("neck-sh", "pelvis-hip")) else TOL
            if abs(d / length - 1) > tol:
                errors.append(f"{name}: {bname} is {d:.1f}, should be {length} (±{100*tol:.0f}%)")
    if len(poses) == 2:
        s, e = poses["start"], poses["end"]
        for k in BODY3D:
            d = dist(s[k], e[k])
            if fig.get("hold"):
                if d > 3:
                    errors.append(f"{k} moves {d:.1f} in a hold (breathing only, max 3)")
            elif 0 < d <= 1.0:
                errors.append(f"{k} moves only {d:.2f}: make it identical in both poses")
    for i, pr in enumerate(fig.get("props", [])):
        if "line" in pr:
            if not all(is3(v) for v in pr["line"]):
                errors.append(f"prop {i}: line points must be [x, y, z]")
        elif "slab" in pr:
            z = pr.get("z")
            if not (isinstance(z, list) and len(z) == 2) or not all(len(v) == 2 for v in pr["slab"]):
                errors.append(f"prop {i}: slab needs [[x, y], ...] and z: [z0, z1]")
        else:
            errors.append(f"prop {i}: needs line or slab")
    t = fig.get("load", {}).get("type", "none")
    if t not in ("none", "dumbbells"):
        errors.append(f"load type {t!r} not drawn in 3D yet (none, dumbbells)")
    return merge(errors)


def cmd_check():
    ids = all_ids()
    bad = 0
    for fid in ids:
        errors = check_one(fid)
        print(f"{'FAIL' if errors else 'ok  '} {fid}")
        for m in errors:
            print(f"     error: {m}")
        bad += bool(errors)
    print(f"{len(ids) - bad}/{len(ids)} figures pass")
    return 1 if bad else 0


# ---------- scene ----------

def centre(fig):
    ps = list(fig["start"].values()) + list(fig["end"].values())
    xs, zs = [p[0] for p in ps], [p[2] for p in ps]
    return (min(xs) + max(xs)) / 2, (min(zs) + max(zs)) / 2


def lerp_pose(fig, k):
    s, e = fig["start"], fig["end"]
    return {n: [a + (b - a) * k for a, b in zip(s[n], e[n])] for n in s}


def project(p, yaw, c):
    """Screen (x, y) and depth (toward the viewer) of 3D point p."""
    t = math.radians(yaw)
    dx, dz = p[0] - c[0], p[2] - c[1]
    return (c[0] + dx * math.cos(t) - dz * math.sin(t), p[1]), dx * math.sin(t) + dz * math.cos(t)


def blend(t):
    a, b = (255, 255, 255), (0x6E, 0x6E, 0x73)
    return "#" + "".join(f"{round(x + (y - x) * t):02X}" for x, y in zip(a, b))


def parts(fig, p, yaw, c):
    """Depth-sortable parts for pose p at yaw: list of dicts
    {key, kind ('limb'|'torso'|'head'|'prop'), depth, items: [(tag, attrs)], halo: [(tag, attrs)]}.
    The list always has the same parts in the same order, with items of the same shape."""
    P = {k: project(v, yaw, c) for k, v in p.items()}
    xy = {k: v[0] for k, v in P.items()}
    dep = {k: v[1] for k, v in P.items()}
    mid = (dep["neck"] + dep["pelvis"]) / 2
    out = []

    def poly(tag, ps, color, w, **extra):
        a = {"points": " ".join(f"{f1(q[0])},{f1(q[1])}" for q in ps)}
        if tag == "polyline":
            a.update({"fill": "none"})
        a.update({"stroke": color, "stroke-width": f1(w), "stroke-linecap": "round", "stroke-linejoin": "round"})
        a.update(extra)
        return (tag, a)

    for i, pr in enumerate(fig.get("props", [])):
        if "line" in pr:
            pp = [project(q, yaw, c) for q in pr["line"]]
            items = [poly("polyline", [q[0] for q in pp], PROP, pr.get("w", 6))]
            d = sum(q[1] for q in pp) / len(pp)
        else:
            z0, z1 = pr["z"]
            items, ds = [], []
            ln = pr["slab"]
            for a, b in zip(ln, ln[1:]):
                quad = [project([a[0], a[1], z0], yaw, c), project([b[0], b[1], z0], yaw, c),
                        project([b[0], b[1], z1], yaw, c), project([a[0], a[1], z1], yaw, c)]
                items.append(poly("polygon", [q[0] for q in quad], PROP, pr.get("w", 6), fill=PROP))
                ds += [q[1] for q in quad]
            d = sum(ds) / len(ds)
        out.append({"key": f"prop{i}", "kind": "prop", "depth": d, "items": items, "halo": []})

    ld = fig.get("load", {"type": "none"})
    for s in "LR":
        for limb, chain in (("arm", ["shoulder" + s, "elbow" + s, "hand" + s]),
                            ("leg", ["hip" + s, "knee" + s, "ankle" + s, "toe" + s])):
            d = sum(dep[k] for k in chain) / len(chain)
            # dimmed by where the upper bone sits (a shin bent back does not grey a front-view leg)
            upper = (dep[chain[0]] + dep[chain[1]]) / 2
            dim = min(1.0, max(0.0, (mid - upper - DIM_FROM) / (DIM_DEPTH - DIM_FROM)))
            ps = [xy[k] for k in chain]
            items = [poly("polyline", ps, blend(dim), LIMB_W)]
            a, b = ps[0], ps[1]
            t = min(0.45, HALO_TRIM / max(math.dist(a, b), 1e-6))
            first = (a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t)
            halo = [poly("polyline", [first] + ps[1:], HALO, LIMB_W + 2 * HALO_W)]
            if limb == "arm" and ld.get("type") == "dumbbells":
                items += dumbbell(p["hand" + s], ld.get("axis", [1, 0, 0]), yaw, c, 1 - 0.45 * dim, poly)
            out.append({"key": limb + s, "kind": "limb", "depth": d, "items": items, "halo": halo})

    torso = [poly("polyline", [xy["shoulderL"], xy["neck"], xy["shoulderR"]], WHITE, TORSO_W),
             poly("polyline", [xy["neck"], xy["pelvis"]], WHITE, TORSO_W),
             poly("polyline", [xy["hipL"], xy["pelvis"], xy["hipR"]], WHITE, TORSO_W)]
    out.append({"key": "torso", "kind": "torso", "depth": mid, "items": torso, "halo": []})
    h = xy["head"]
    out.append({"key": "head", "kind": "head", "depth": dep["head"], "halo": [],
                "items": [("circle", {"cx": f1(h[0]), "cy": f1(h[1]), "r": str(HEAD_R), "fill": WHITE})]})
    return out


def dumbbell(hand, axis, yaw, c, opacity, poly):
    n = math.sqrt(sum(a * a for a in axis))
    u = [a / n for a in axis]
    # cap direction: across the bar, vertical unless the bar is vertical
    cr = [-u[1], u[0], 0] if abs(u[2]) < 0.9 else [0, 1, 0]
    m = math.sqrt(sum(a * a for a in cr)) or 1
    cr = [a / m for a in cr] if abs(u[1]) < 0.9 else [0, 0, 1]
    ends = [[hand[i] + sg * 9 * u[i] for i in range(3)] for sg in (-1, 1)]
    op = {"stroke-opacity": f1(opacity)}
    items = [poly("polyline", [project(q, yaw, c)[0] for q in ends], VOLT, 7, **op)]
    for q in ends:
        a = [q[i] - 6.5 * cr[i] for i in range(3)]
        b = [q[i] + 6.5 * cr[i] for i in range(3)]
        items.append(poly("polyline", [project(a, yaw, c)[0], project(b, yaw, c)[0]], VOLT, 4.5, **op))
    return items


PRIORITY = {"prop": 0, "limb": 1, "torso": 2, "head": 3}


def order(ps):
    """Draw order (far to near). Ties go props, limbs, torso, head."""
    return sorted(range(len(ps)), key=lambda i: (round(ps[i]["depth"], 1), PRIORITY[ps[i]["kind"]]))


def draw(ps):
    """Elements in draw order; a limb drawn after the torso carries its black edge."""
    out, seen_torso = [], False
    for i in order(ps):
        q = ps[i]
        if q["kind"] == "limb" and seen_torso:
            out += q["halo"]
        out += q["items"]
        seen_torso = seen_torso or q["kind"] == "torso"
    return out


# ---------- svg ----------

def attrs(a):
    return " ".join(f'{k}="{v}"' for k, v in a.items())


def el(t, a):
    return f"<{t} {attrs(a)}/>"


def bounds(items):
    xs0, ys0, xs1, ys1 = [], [], [], []
    for tag, a in items:
        if tag == "circle":
            x, y, r = float(a["cx"]), float(a["cy"]), float(a["r"])
            xs0.append(x - r); xs1.append(x + r); ys0.append(y - r); ys1.append(y + r)
        else:
            h = float(a["stroke-width"]) / 2
            for pair in a["points"].split():
                x, y = map(float, pair.split(","))
                xs0.append(x - h); xs1.append(x + h); ys0.append(y - h); ys1.append(y + h)
    return min(xs0), min(ys0), max(xs1), max(ys1)


def crop(fig):
    c = centre(fig)
    items = []
    for yaw in range(0, 360, CROP_STEP):
        for name in ("start", "end"):
            for q in parts(fig, fig[name], yaw, c):
                items += q["items"]
    x0, y0, x1, y1 = bounds(items)
    floor = fig.get("floor", 182)
    y0, y1 = min(y0, floor - 1), max(y1, floor + 1)
    side = max(MIN_SIDE, x1 - x0 + 2 * AIR, y1 - y0 + 2 * AIR)
    return (x0 + x1 - side) / 2, (y0 + y1 - side) / 2, side


def frame(fig, vb, size, body):
    vx, vy, side = vb
    floor = fig.get("floor", 182)
    fl = el("line", {"x1": f1(vx), "y1": str(floor), "x2": f1(vx + side), "y2": str(floor),
                     "stroke": FLOOR, "stroke-width": "2"})
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="{f1(vx)} {f1(vy)} {f1(side)} {f1(side)}" '
            f'width="{size}" height="{size}">' + fl + body + "</svg>")


def ease(k):
    return (1 - math.cos(math.pi * k)) / 2


def svg(fid, yaw=0, still=False, pose=None, size=200, _vb=None):
    """The figure seen from `yaw`. pose='start'|'end': that pose alone. still=True: ghost start under
    solid end. Otherwise the reps animate at this fixed angle."""
    fig = load(fid)
    c, vb = centre(fig), _vb or crop(fig)
    if pose:
        body = "".join(el(t, a) for t, a in draw(parts(fig, fig[pose], yaw, c)))
    elif still:
        body = ('<g opacity="0.3">' + "".join(el(t, a) for t, a in draw(parts(fig, fig["start"], yaw, c)))
                + "</g>" + "".join(el(t, a) for t, a in draw(parts(fig, fig["end"], yaw, c))))
    else:
        n = 16
        frames = [parts(fig, lerp_pose(fig, ease(2 * i / n if i <= n / 2 else 2 - 2 * i / n)), yaw, c)
                  for i in range(n + 1)]
        body = animate(f"{fid}-y{f1(yaw % 360).replace('.', '_')}", frames, fig.get("tempo", 2.6))
    return frame(fig, vb, size, body)


def animate(fid, frames, dur):
    """SMIL for a list of part lists (one per frame, the last equal to the first). `fid` prefixes the ids:
    the figure id plus the variant, so two animated views of one figure can share a page."""
    n = len(frames)
    kt = ";".join(f"{i / (n - 1):.4f}".rstrip("0").rstrip(".") for i in range(n))
    common = f'dur="{f1(dur)}s" repeatCount="indefinite"'

    def anim_item(seq):
        tag, a0 = seq[0]
        inner = ""
        for k in a0:
            vals = [a[k] for _, a in seq]
            if len(set(vals)) > 1:
                inner += f'<animate attributeName="{k}" values="{";".join(vals)}" keyTimes="{kt}" {common}/>'
        return f"<{tag} {attrs(a0)}>{inner}</{tag}>" if inner else el(tag, a0)

    nparts = len(frames[0])
    defs, uses = [], []
    for j in range(nparts):
        key = frames[0][j]["key"]
        defs.append(f'<g id="{fid}-{key}">' + "".join(
            anim_item([f[j]["items"][m] for f in frames]) for m in range(len(frames[0][j]["items"]))) + "</g>")
        if frames[0][j]["halo"]:
            defs.append(f'<g id="{fid}-{key}-h">' + "".join(
                anim_item([f[j]["halo"][m] for f in frames]) for m in range(len(frames[0][j]["halo"]))) + "</g>")
    ranks = [order(f) for f in frames]          # ranks[frame] = part indices far to near
    torso_slot = [r.index(next(i for i in r if frames[0][i]["kind"] == "torso")) for r in ranks]
    for slot in range(nparts):
        for j in sorted({r[slot] for r in ranks}):
            on = [r[slot] == j for r in ranks]
            front = [on[f] and slot > torso_slot[f] for f in range(n)]
            key = frames[0][j]["key"]
            if frames[0][j]["halo"] and any(front):
                uses.append(use(f"{fid}-{key}-h", front, n, common))
            uses.append(use(f"{fid}-{key}", on, n, common))
    return "<defs>" + "".join(defs) + "</defs>" + "".join(uses)


def use(ref, on, n, common):
    if all(on):
        return f'<use href="#{ref}"/>'
    vals, kts = [], []
    for f in range(n):
        if f == 0 or on[f] != on[f - 1]:
            vals.append("1" if on[f] else "0")
            kts.append(f"{f / (n - 1):.4f}".rstrip("0").rstrip(".") or "0")
    return (f'<use href="#{ref}" opacity="{vals[0]}"><animate attributeName="opacity" calcMode="discrete" '
            f'values="{";".join(vals)}" keyTimes="{";".join(kts)}" {common}/></use>')


def turn_svg(fid, size=200, seconds=12):
    """The figure turning through a full circle in `seconds` while it does its reps."""
    fig = load(fid)
    c, vb = centre(fig), crop(fig)
    reps = max(1, round(seconds / fig.get("tempo", 2.6)))
    per = max(10, math.ceil(36 / reps))
    n = reps * per
    frames = []
    for i in range(n + 1):
        k = (i % per) / per
        frames.append(parts(fig, lerp_pose(fig, ease(2 * k if k <= 0.5 else 2 - 2 * k)), 360 * i / n, c))
    return frame(fig, vb, size, animate(f"{fid}-turn", frames, seconds))


# ---------- sheet ----------

def cmd_sheet(out):
    rows = []
    for fid in all_ids():
        if check_one(fid):
            rows.append(f'<h2 style="color:#fff">{fid} <span style="color:#FF453A">fails check</span></h2>')
            continue
        vb = crop(load(fid))
        cells = []
        for pose in ("start", "end"):
            cells.append('<div style="display:flex;gap:2px;align-items:center"><span style="width:40px">'
                         + pose + "</span>" + "".join(
                             f'<div style="text-align:center">{svg(fid, yaw=y, pose=pose, size=150, _vb=vb)}'
                             f"<br>{y}°</div>" for y in range(0, 360, 45)) + "</div>")
        rows.append(f'<div style="display:flex;gap:16px;align-items:center;margin-bottom:18px">'
                    f'<div><div style="color:#fff;margin-bottom:6px">{fid}</div>{"".join(cells)}</div>'
                    f"<div>{turn_svg(fid, size=240)}<br>turning</div></div>")
    html = ('<!doctype html><html><head><meta charset="utf-8"><title>SpotMe figures 3D</title></head>'
            '<body style="background:#000;color:#8E8E93;font:12px -apple-system,Helvetica,sans-serif;margin:12px">'
            + "".join(rows) + "</body></html>")
    with open(out, "w") as f:
        f.write(html)
    print(f"wrote {out}")
    return 0


def opt(argv, name, default, cast):
    return cast(argv[argv.index(name) + 1]) if name in argv else default


def main(argv):
    if not argv:
        print(__doc__)
        return 2
    cmd = argv[0]
    if cmd == "check":
        return cmd_check()
    if cmd == "svg" and len(argv) >= 2:
        print(svg(argv[1], yaw=opt(argv, "--yaw", 0, float), still="--still" in argv,
                  pose=opt(argv, "--pose", None, str), size=opt(argv, "--size", 200, int)))
        return 0
    if cmd == "turn" and len(argv) >= 2:
        print(turn_svg(argv[1], size=opt(argv, "--size", 200, int), seconds=opt(argv, "--seconds", 12, float)))
        return 0
    if cmd == "sheet" and len(argv) == 2:
        return cmd_sheet(argv[1])
    print(__doc__)
    return 2


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
