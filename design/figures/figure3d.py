#!/usr/bin/env python3
"""SpotMe form figures that turn: poses with depth, drawn from any angle. Rules: FIGURES.md, "Turning a
figure" and "The 3D format, complete" (the same reference in prose, for the Swift port).

  python3 figure3d.py check
  python3 figure3d.py svg <id> [--yaw DEG] [--still] [--pose start|end] [--size N]   (no --yaw: opening view)
  python3 figure3d.py turn <id> [--size N] [--seconds S]
  python3 figure3d.py sheet <out.html> [id ...]   review page: turning figure, END at 8 angles, START at
                                                  0 and 90, still at 80 px
Importable: from figure3d import svg, turn_svg. Authoring helpers: authoring3d/rig.py.

FILE  poses3d/<id>.json: {"id", "view": "side"|"front", "floor": 182, "tempo": 2.6 (seconds per rep),
"hold": false, "yaw": 0 (optional), "props": [...], "load": {...} or [{...}, ...], "start": {point: [x, y, z]},
"end": {...}}. "yaw" is the opening view: the angle (degrees, any number, taken mod 360) the figure is first
shown at, for movements hidden at yaw 0 (Pallof press, reverse pec deck, Russian twist). It changes nothing
about the axes or the crop; svg() without a yaw, the turning SVG and the app's Crown turn start from it.
Axes: x right, y down, z toward the viewer in the usual view (yaw 0). Box 200 x 200, floor line at y=floor.

POINTS  all 17 in both poses: head neck pelvis shoulderL shoulderR hipL hipR elbowL handL elbowR handR
kneeL ankleL toeL kneeR ankleR toeR. Side view: L is the near side (+z). Front view: L is the viewer's left.
True 3D bone lengths (+-12%): neck-pelvis 50, neck-head 17, shoulder-elbow 27, elbow-hand 25, hip-knee 38,
knee-ankle 36, ankle-toe 13; neck-shoulder 15 and pelvis-hip 9 (+-1.5). A point that moves must move > 1.

PROPS  grey #8E8E93, static:
  {"line": [[x,y,z], ...], "w": 6}            3D polyline, round caps and joins
  {"slab": [[x,y], ...], "z": [z0, z1], "w": 7}  each segment of the x-y polyline swept from z0 to z1: a
                                              filled quad with a w-wide round outline (edge-on at yaw 0)
LOAD  volt #CCFF3D, moves with the body. "load" is one load object or a list of them (cable fly: two cables
with handle "grip", at handL and handR; a band plus a belt plate); each is drawn by the same rules,
independently (central pieces of all of them share the one "load" part). A point spec ("at") is a body point name, "hands" (= the mean of
handL and handR) or a list of names (their mean). "offset" [x,y,z] (default [0,0,0]) is added in world axes.
"across" = the body's right-to-left unit axis there: shoulderR->shoulderL if any named point is in the upper
body (head neck shoulders elbows hands), else hipR->hipL. Default values in ().
  none        nothing
  dumbbells   axis ([1,0,0]): per hand a bar 18 long along axis, w 7, with 13-long caps across it, w 4.5
  bar         at ("hands"), offset, length (80), plate (14, 0 = none). Centre: mid-hands (axis handR->handL)
              or the point + offset (axis "across"). A bar w 4 of that length centred there; a plate disc
              (radius plate, w 4.5) on the axis 6 in from each end. Barbell 80/14, EZ 56/8, cable or
              pulldown bar 50-60/0, on the back "at": "neck", on the hips "at": "pelvis" with offset.
  cable/band  anchor [x,y,z] (required), handle ("grip"|"bar"|"rope"), at (for grip: one limb point,
              default handL). Cable w 2.5 from anchor (band: dashed 5 4). grip: cable to the point, grip
              12 long w 5 across the cable and "across". bar: cable to mid-hands, bar w 5 from handR to
              handL extended 5 each way. rope: knot 7 from mid-hands toward the anchor, cable to the knot,
              tails knot->handL and knot->handR w 4.
  machine     grips (["handL","handR"]), pivots (none; else one [x,y,z] per grip), axis ([0,1,0]),
              length (14). Per grip: grey lever w 4 pivot->grip (drawn first), volt grip w 6 along axis.
  pad         at (required: one limb point, or a list), offset, pivot (none), length (22), w (10). A roller w thick, length long,
              along "across", centred at the point + offset; grey lever w 4 pivot->centre (drawn first).
  platform    at (["ankleL","ankleR"]), offset, angle (90; 2D degrees, 0 right, 90 down), length (40),
              width (34). Volt quad, fill opacity 0.28, w 5 outline at full opacity: length along angle in the x-y plane, width
              along world z. It follows the point but never turns (leg press sled).
  held        kind ("plate"|"kettlebell"|"ball"|"wheel"), at ("hands"), offset, axis ("across").
              plate: disc r 11 w 4. wheel: disc r 9 w 5. ball: circle r 9. kettlebell: handle w 3, 8 long
              along axis, and a circle r 7 10 below it.

PRIMITIVES  everything is drawn from four: segment/polyline (3D points, width, colour, round caps; optional
dash), slab quad (filled polygon + outline), circle facing the viewer (head r 11, balls), disc (centre,
axis, radius: 16 rim points projected and drawn as a closed outline; e1 = axis x [0,1,0], or axis x [1,0,0]
if that is zero, e2 = axis x e1; rim_i = c + r cos(2 pi i/16) e1 + r sin(2 pi i/16) e2).

DRAWING  centre c = middle of the x range and of the z range of all body points of both poses. The scene
turns by yaw about the vertical line through c, orthographic: dx, dz = x-cx, z-cz; screen x = cx + dx cos
- dz sin, screen y = y, depth (toward viewer) = dx sin + dz cos. Parts, in list order: props, armL, legL,
armR, legR, torso, head, load. Depth: limb = mean of its chain (arm shoulder elbow hand; leg hip knee ankle
toe), torso = mean of neck and pelvis, head = head, prop or load = mean of its projected points (disc:
centre). Drawn far to near by (depth rounded to 0.1, kind: prop < limb < load < torso < head), stable.
Limb: polyline w 9 coloured #FFFFFF->#6E6E73 by dim = clamp((torso depth - mean depth of its upper bone's
two points - 3) / 12, 0, 1). A limb drawn after the torso first gets a black #000000 edge: the same
polyline w 9 + 2*2.5, its first point moved 11 along the bone (max 45%). Torso w 12 white: shoulderL-neck-
shoulderR, neck-pelvis, hipL-pelvis-hipR. Head circle r 11. Floor line #3A3A3C w 2 across the crop.
LOAD DEPTH  A piece on one side of the body (a dumbbell, a grip, a machine grip and its lever, a pad on one
limb, a cable to one hand or ankle) rides with that limb: drawn right after it, opacity 1 - 0.45 dim. A
bar or a pad across both limbs is split at its centre into an L half and an R half that ride with the L
and R arm (upper-body point or hands) or leg (lower body); a pad's lever rides with the half on its pivot's
side. Everything else (a cable to a bar or rope, a held weight, a platform) is one part, "load".

CROP  one square per figure for every angle: the bounds (stroke half-widths and circle radii included) of
both poses at yaw 0, 5, ... 355, widened to floor +-1, side = max(130, width + 20, height + 20), centred.
ANIMATION  pose(k) = start + (end - start) e(k), e(k) = (1 - cos(pi k)) / 2; one rep goes 0 -> 1 -> 0 in
tempo seconds. svg: 16 frames. turn: a full turn from the opening view in 12 s with round(12 / tempo) reps (>= 1). Still: start
at opacity 0.3 under end, both at the same yaw.

SVG output (this file only): each part's geometry is written once in <defs> with every coordinate and colour
as a `values` list, one entry per frame, linear. Ids are <figure id>-turn-<part> (and <figure id>-y<yaw>-<part>
for reps at a fixed angle). The draw order is a stack of slots; a part gets a <use> in every slot it ever
occupies, shown only at the frames it holds that slot (discrete `opacity`). Limbs in slots above the torso
carry their black edge.
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
    raw = fig.get("load", {"type": "none"})
    if isinstance(raw, list):
        if not raw or not all(isinstance(x, dict) for x in raw):
            errors.append("load list must hold one or more load objects")
        else:
            for i, x in enumerate(raw):
                errors += [f"load[{i}]: {m}" for m in check_load(x)]
    elif isinstance(raw, dict):
        errors += check_load(raw)
    else:
        errors.append("load must be an object or a list of objects")
    if "yaw" in fig and (not isinstance(fig["yaw"], (int, float)) or isinstance(fig["yaw"], bool)):
        errors.append(f"yaw {fig['yaw']!r}: must be a number (degrees)")
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

    lds = loads(fig)
    lp = {}
    for ld in lds:
        for k, v in load_prims(ld, p).items():
            lp.setdefault(k, []).extend(v)
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
            for ld in lds:
                if limb == "arm" and ld.get("type") == "dumbbells":
                    items += dumbbell(p["hand" + s], ld.get("axis", [1, 0, 0]), yaw, c, 1 - 0.45 * dim, poly)
            if limb + s in lp:
                items += prim_items(lp[limb + s], yaw, c, poly, 1 - 0.45 * dim)[0]
            out.append({"key": limb + s, "kind": "limb", "depth": d, "items": items, "halo": halo})

    torso = [poly("polyline", [xy["shoulderL"], xy["neck"], xy["shoulderR"]], WHITE, TORSO_W),
             poly("polyline", [xy["neck"], xy["pelvis"]], WHITE, TORSO_W),
             poly("polyline", [xy["hipL"], xy["pelvis"], xy["hipR"]], WHITE, TORSO_W)]
    out.append({"key": "torso", "kind": "torso", "depth": mid, "items": torso, "halo": []})
    h = xy["head"]
    out.append({"key": "head", "kind": "head", "depth": dep["head"], "halo": [],
                "items": [("circle", {"cx": f1(h[0]), "cy": f1(h[1]), "r": str(HEAD_R), "fill": WHITE})]})
    if "load" in lp:
        items, ds = prim_items(lp["load"], yaw, c, poly)
        out.append({"key": "load", "kind": "load", "depth": sum(ds) / len(ds), "items": items, "halo": []})
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


# ---------- loads ----------

LOAD_TYPES = ("none", "dumbbells", "bar", "cable", "band", "machine", "pad", "platform", "held")
HELD_KINDS = ("plate", "kettlebell", "ball", "wheel")
LIMB_POINTS = [n for n in BODY3D if n[-1] in "LR" and not n.startswith(("shoulder", "hip"))]
UPPER = ("head", "neck", "shoulderL", "shoulderR", "elbowL", "elbowR", "handL", "handR")


def norm(v):
    n = math.sqrt(sum(a * a for a in v))
    return [a / n for a in v] if n > 1e-9 else [0.0, 0.0, 0.0]


def add(a, b, k=1.0):
    return [x + k * y for x, y in zip(a, b)]


def cross(a, b):
    return [a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0]]


def names(at):
    """A point spec: a body point name, "hands", or a list of names (their mean)."""
    if at == "hands":
        return ["handL", "handR"]
    return [at] if isinstance(at, str) else list(at)


def point(p, at, off=None):
    ns = names(at)
    m = [sum(p[n][i] for n in ns) / len(ns) for i in range(3)]
    return add(m, off or [0, 0, 0])


def across(p, at):
    """The body's right-to-left axis where the load sits: shoulders for the upper body, hips below."""
    up = any(n in UPPER for n in names(at))
    a, b = ("shoulderR", "shoulderL") if up else ("hipR", "hipL")
    u = norm(add(p[b], p[a], -1))
    return u if any(u) else [0.0, 0.0, 1.0]


def owner(at):
    """The limb a one-sided load piece rides with: arm or leg of the side its point names."""
    ns = names(at)
    side = ns[0][-1]
    return ("arm" if any(n in UPPER for n in ns) else "leg") + side


def loads(fig):
    """The figure's load objects as a list ("load" may be one object or a list)."""
    ld = fig.get("load", {"type": "none"})
    return ld if isinstance(ld, list) else [ld]


def opening(fig):
    """The opening view: the angle the figure is first shown at (top-level "yaw", default 0)."""
    return fig.get("yaw", 0) % 360


def load_prims(ld, p):
    """3D primitives of the load in pose p: {part key: [prim]}. Keys armL/armR/legL/legR ride with that
    limb; "load" is a part of its own. A prim is ("seg", [a, b, ...], colour, w, dashed) |
    ("disc", centre, axis, r, colour, w) | ("ball", centre, r) | ("quad", [4 points], colour)."""
    t = ld.get("type", "none")
    out = {}

    def put(k, *prims):
        out.setdefault(k, []).extend(prims)

    if t == "bar":
        at, half, pr = ld.get("at", "hands"), ld.get("length", 80) / 2, ld.get("plate", 14)
        if at == "hands":
            m, u = point(p, "hands"), norm(add(p["handL"], p["handR"], -1))
            u = u if any(u) else across(p, at)
        else:
            m, u = point(p, at, ld.get("offset")), across(p, at)
        limb = "arm" if any(n in UPPER for n in names(at)) else "leg"
        for s, sg in (("L", 1), ("R", -1)):
            put(limb + s, ("seg", [m, add(m, u, sg * half)], VOLT, 4, False))
            if pr:
                put(limb + s, ("disc", add(m, u, sg * (half - 6)), u, pr, VOLT, 4.5))
    elif t in ("cable", "band"):
        anc, h, dash = ld["anchor"], ld.get("handle", "grip"), t == "band"
        if h == "grip":
            at = ld.get("at", "handL")
            q = point(p, at)
            d = norm(cross(norm(add(q, anc, -1)), across(p, at))) or across(p, at)
            d = d if any(d) else across(p, at)
            put(owner(at), ("seg", [anc, q], VOLT, 2.5, dash),
                ("seg", [add(q, d, -6), add(q, d, 6)], VOLT, 5, False))
        else:
            m = point(p, "hands")
            u = norm(add(p["handL"], p["handR"], -1))
            u = u if any(u) else across(p, "hands")
            if h == "bar":
                put("load", ("seg", [anc, m], VOLT, 2.5, dash),
                    ("seg", [add(p["handR"], u, -5), add(p["handL"], u, 5)], VOLT, 5, False))
            else:  # rope: a knot a little toward the anchor, two tails to the hands
                k = add(m, norm(add(anc, m, -1)), 7)
                put("load", ("seg", [anc, k], VOLT, 2.5, dash), ("seg", [p["handL"], k, p["handR"]], VOLT, 4, False))
    elif t == "machine":
        grips, pivots = ld.get("grips", ["handL", "handR"]), ld.get("pivots")
        ax, half = norm(ld.get("axis", [0, 1, 0])), ld.get("length", 14) / 2
        for i, g in enumerate(grips):
            q = p[g]
            if pivots:
                put(owner(g), ("seg", [pivots[i], q], PROP, 4, False))
            put(owner(g), ("seg", [add(q, ax, -half), add(q, ax, half)], VOLT, 6, False))
    elif t == "pad":
        at = ld["at"]
        q, u, half = point(p, at, ld.get("offset")), across(p, at), ld.get("length", 22) / 2
        w = ld.get("w", 10)
        if isinstance(at, str):     # on one limb: rides with it
            if "pivot" in ld:
                put(owner(at), ("seg", [ld["pivot"], q], PROP, 4, False))
            put(owner(at), ("seg", [add(q, u, -half), add(q, u, half)], VOLT, w, False))
        else:                       # across both limbs: split at the middle, each half rides with its side
            limb = "arm" if any(n in UPPER for n in names(at)) else "leg"
            if "pivot" in ld:
                side = "L" if sum((a - b) * c for a, b, c in zip(ld["pivot"], q, u)) >= 0 else "R"
                put(limb + side, ("seg", [ld["pivot"], q], PROP, 4, False))
            put(limb + "L", ("seg", [q, add(q, u, half)], VOLT, w, False))
            put(limb + "R", ("seg", [q, add(q, u, -half)], VOLT, w, False))
    elif t == "platform":
        q = point(p, ld.get("at", ["ankleL", "ankleR"]), ld.get("offset"))
        a = math.radians(ld.get("angle", 90))
        d = [math.cos(a) * ld.get("length", 40) / 2, math.sin(a) * ld.get("length", 40) / 2, 0]
        z = [0, 0, ld.get("width", 34) / 2]
        put("load", ("quad", [add(add(q, d), z), add(add(q, d, -1), z), add(add(q, d, -1), z, -1),
                              add(add(q, d), z, -1)], VOLT))
    elif t == "held":
        kind, at = ld.get("kind", "plate"), ld.get("at", "hands")
        q = point(p, at, ld.get("offset"))
        u = norm(ld["axis"]) if "axis" in ld else across(p, at)
        if kind == "plate":
            put("load", ("disc", q, u, 11, VOLT, 4))
        elif kind == "wheel":
            put("load", ("disc", q, u, 9, VOLT, 5))
        elif kind == "ball":
            put("load", ("ball", q, 9))
        else:  # kettlebell: handle across the hands, bell hanging below
            put("load", ("seg", [add(q, u, -4), add(q, u, 4)], VOLT, 3, False), ("ball", add(q, [0, 10, 0]), 7))
    return out


def disc_rim(c, axis, r, n=16):
    u = norm(axis)
    e1 = norm(cross(u, [0, 1, 0]))
    if not any(e1):
        e1 = norm(cross(u, [1, 0, 0]))
    e2 = cross(u, e1)
    return [add(add(c, e1, r * math.cos(2 * math.pi * i / n)), e2, r * math.sin(2 * math.pi * i / n))
            for i in range(n)]


def prim_items(prims, yaw, c, poly, opacity=None):
    """SVG items and the depths of the 3D points of a list of prims."""
    items, ds = [], []
    op = {} if opacity is None else {"stroke-opacity": f1(opacity)}
    for pr in prims:
        if pr[0] == "seg":
            pp = [project(q, yaw, c) for q in pr[1]]
            extra = dict(op, **({"stroke-dasharray": "5 4"} if pr[4] else {}))
            items.append(poly("polyline", [q[0] for q in pp], pr[2], pr[3], **extra))
            ds += [q[1] for q in pp]
        elif pr[0] == "disc":
            pp = [project(q, yaw, c) for q in disc_rim(pr[1], pr[2], pr[3])]
            items.append(poly("polygon", [q[0] for q in pp], pr[4], pr[5], fill="none", **op))
            ds.append(project(pr[1], yaw, c)[1])
        elif pr[0] == "quad":
            pp = [project(q, yaw, c) for q in pr[1]]
            fo = {"fill-opacity": f"{0.28 * float(op.get('stroke-opacity', 1)):.2f}".rstrip("0")}
            items.append(poly("polygon", [q[0] for q in pp], pr[2], 5, fill=pr[2], **op, **fo))
            ds += [q[1] for q in pp]
        else:
            (x, y), d = project(pr[1], yaw, c)
            a = {"cx": f1(x), "cy": f1(y), "r": f1(pr[2]), "fill": VOLT}
            if op:
                a["fill-opacity"] = op["stroke-opacity"]
            items.append(("circle", a))
            ds.append(d)
    return items, ds


def check_load(ld):
    errs = []
    t = ld.get("type", "none")
    if t not in LOAD_TYPES:
        return [f"load type {t!r} unknown (one of {', '.join(LOAD_TYPES)})"]

    def spec(field, required=False):
        if field not in ld:
            if required:
                errs.append(f"{t} load needs {field!r}")
            return
        v = ld[field]
        ok = v == "hands" or (isinstance(v, str) and v in BODY3D) or (
            isinstance(v, list) and v and all(isinstance(n, str) and n in BODY3D for n in v))
        if not ok:
            errs.append(f"{t} load {field} {v!r}: not a body point, \"hands\" or a list of body points")

    def vec(field, required=False):
        if field not in ld:
            if required:
                errs.append(f"{t} load needs {field!r} [x, y, z]")
        elif not is3(ld[field]):
            errs.append(f"{t} load {field} must be [x, y, z]")

    vec("offset")
    if t == "dumbbells":
        vec("axis")
    elif t == "bar":
        spec("at")
    elif t in ("cable", "band"):
        vec("anchor", True)
        h = ld.get("handle", "grip")
        if h not in ("grip", "bar", "rope"):
            errs.append(f"{t} handle {h!r} unknown (grip, bar, rope)")
        if h == "grip":
            spec("at")
            if ld.get("at", "handL") not in LIMB_POINTS:
                errs.append(f"{t} grip goes to one limb point (handL, handR, ankleL ...), not {ld.get('at')!r}")
    elif t == "machine":
        g = ld.get("grips", ["handL", "handR"])
        if not (isinstance(g, list) and g and all(n in LIMB_POINTS for n in g)):
            errs.append(f"machine grips {g!r}: must be a list of limb points (handL, handR, ankleL ...)")
        pv = ld.get("pivots")
        if pv is not None and not (isinstance(pv, list) and len(pv) == len(g) and all(is3(v) for v in pv)):
            errs.append("machine pivots: one [x, y, z] per grip")
        vec("axis")
    elif t == "pad":
        spec("at", True)
        vec("pivot")
        if isinstance(ld.get("at"), str) and ld["at"] not in LIMB_POINTS:
            errs.append(f"pad at {ld['at']!r}: one limb point (ankleL, kneeR ...) or a list of points")
    elif t == "platform":
        spec("at")
    elif t == "held":
        if ld.get("kind", "plate") not in HELD_KINDS:
            errs.append(f"held kind {ld.get('kind')!r} unknown ({', '.join(HELD_KINDS)})")
        spec("at")
        vec("axis")
    return errs


PRIORITY = {"prop": 0, "limb": 1, "load": 1.5, "torso": 2, "head": 3}


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


def svg(fid, yaw=None, still=False, pose=None, size=200, _vb=None):
    """The figure seen from `yaw` (default: its opening view). pose='start'|'end': that pose alone.
    still=True: ghost start under solid end. Otherwise the reps animate at this fixed angle."""
    fig = load(fid)
    yaw = opening(fig) if yaw is None else yaw
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
    """The figure turning through a full circle in `seconds` while it does its reps, from its opening view."""
    fig = load(fid)
    y0 = opening(fig)
    c, vb = centre(fig), crop(fig)
    reps = max(1, round(seconds / fig.get("tempo", 2.6)))
    per = max(10, math.ceil(36 / reps))
    n = reps * per
    frames = []
    for i in range(n + 1):
        k = (i % per) / per
        frames.append(parts(fig, lerp_pose(fig, ease(2 * k if k <= 0.5 else 2 - 2 * k)), y0 + 360 * i / n, c))
    return frame(fig, vb, size, animate(f"{fid}-turn", frames, seconds))


# ---------- sheet ----------

def cmd_sheet(out, ids=None):
    rows = []
    for fid in ids or all_ids():
        if check_one(fid):
            rows.append(f'<h2 style="color:#fff">{fid} <span style="color:#FF453A">fails check</span></h2>')
            continue
        vb = crop(load(fid))
        oy = opening(load(fid))
        def cell(pose, y, size=150):
            return f'<div style="text-align:center">{svg(fid, yaw=y, pose=pose, size=size, _vb=vb)}<br>{pose} {y}°</div>'
        cells = ['<div style="display:flex;gap:6px;align-items:flex-end">'
                 + f'<div style="text-align:center">{svg(fid, yaw=oy, pose="end", size=200, _vb=vb)}<br>opening view: end {f1(oy)}°</div>'
                 + f'<div style="text-align:center">{svg(fid, yaw=oy, still=True, size=80, _vb=vb)}<br>still 80 px, {f1(oy)}°</div></div>',
                 '<div style="display:flex;gap:2px">' + "".join(cell("end", y) for y in range(0, 360, 45)) + "</div>",
                 '<div style="display:flex;gap:2px;align-items:flex-end">' + cell("start", 0) + cell("start", 90) + "</div>"]
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
        print(svg(argv[1], yaw=opt(argv, "--yaw", None, float), still="--still" in argv,
                  pose=opt(argv, "--pose", None, str), size=opt(argv, "--size", 200, int)))
        return 0
    if cmd == "turn" and len(argv) >= 2:
        print(turn_svg(argv[1], size=opt(argv, "--size", 200, int), seconds=opt(argv, "--seconds", 12, float)))
        return 0
    if cmd == "sheet" and len(argv) >= 2:
        return cmd_sheet(argv[1], argv[2:])
    print(__doc__)
    return 2


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
