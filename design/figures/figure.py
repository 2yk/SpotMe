#!/usr/bin/env python3
"""SpotMe form figures: check pose files and draw them as SVG. Rules: FIGURES.md.

  python3 figure.py check
  python3 figure.py svg <id> [--still] [--size N]
  python3 figure.py sheet <out.html>

Importable: from figure import svg; svg("plank", still=False, size=200)
"""
import json
import math
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
POSES = os.path.join(HERE, "poses")

BODY = ["head", "neck", "pelvis", "elbowL", "handL", "elbowR", "handR",
        "kneeL", "ankleL", "toeL", "kneeR", "ankleR", "toeR"]
FRONT_EXTRA = ["shoulderL", "shoulderR", "hipL", "hipR"]
LENGTH = {"torso": 50, "head": 17, "upper": 27, "fore": 25, "thigh": 38, "shin": 36, "foot": 13}
TOL = 0.12
BOX = (8, 192)

WHITE, FAR, PROP, FLOOR, VOLT = "#FFFFFF", "#6E6E73", "#8E8E93", "#3A3A3C", "#CCFF3D"
LIMB_W, TORSO_W, HEAD_R = 9, 12, 11
HALO, HALO_W, HALO_TRIM = "#000000", 2.5, 11
AIR = 10          # units of space around the figure in its crop
MIN_SIDE = 130    # smallest crop side: caps the zoom so tight figures do not look heavy
SPLINE = "0.42 0 0.58 1;0.42 0 0.58 1"


# ---------- loading ----------

def load(fig_id):
    with open(os.path.join(POSES, fig_id + ".json")) as f:
        return json.load(f)


def all_ids():
    return sorted(n[:-5] for n in os.listdir(POSES) if n.endswith(".json"))


def required(fig):
    return BODY + (FRONT_EXTRA if fig.get("view") == "front" else [])


def bones(fig):
    """(name, a, b, length) for every bone of this view."""
    front = fig.get("view") == "front"
    out = [("neck-pelvis", "neck", "pelvis", LENGTH["torso"]),
           ("neck-head", "neck", "head", LENGTH["head"])]
    for s in "LR":
        root_a = "shoulder" + s if front else "neck"
        root_l = "hip" + s if front else "pelvis"
        out += [(f"{root_a}-elbow{s}", root_a, "elbow" + s, LENGTH["upper"]),
                (f"elbow{s}-hand{s}", "elbow" + s, "hand" + s, LENGTH["fore"]),
                (f"{root_l}-knee{s}", root_l, "knee" + s, LENGTH["thigh"]),
                (f"knee{s}-ankle{s}", "knee" + s, "ankle" + s, LENGTH["shin"]),
                (f"ankle{s}-toe{s}", "ankle" + s, "toe" + s, LENGTH["foot"])]
        if front:
            out += [(f"neck-shoulder{s}", "neck", "shoulder" + s, 15),
                    (f"pelvis-hip{s}", "pelvis", "hip" + s, 9)]
    return out


def dist(a, b):
    return math.hypot(a[0] - b[0], a[1] - b[1])


# ---------- check ----------

def check_one(fid):
    errors, notes = [], []
    try:
        fig = load(fid)
    except (OSError, ValueError) as e:
        return [f"cannot read: {e}"], notes
    if fig.get("id") != fid:
        errors.append(f"id {fig.get('id')!r} does not match file name {fid!r}")
    if fig.get("view", "side") not in ("side", "front"):
        errors.append(f"view {fig.get('view')!r} is not side or front")
    poses = {}
    for name in ("start", "end"):
        p = fig.get(name)
        if not isinstance(p, dict):
            errors.append(f"{name}: missing")
            continue
        missing = [k for k in required(fig) if k not in p]
        if missing:
            errors.append(f"{name}: missing points {', '.join(missing)}")
        for k, v in p.items():
            if not (isinstance(v, list) and len(v) == 2 and all(isinstance(c, (int, float)) for c in v)):
                errors.append(f"{name}.{k}: not [x, y]")
                continue
            if not all(BOX[0] <= c <= BOX[1] for c in v):
                errors.append(f"{name}.{k} {v} is outside {BOX[0]}..{BOX[1]}")
        if not missing:
            poses[name] = p
    for name, p in poses.items():
        for bname, a, b, length in bones(fig):
            d = dist(p[a], p[b])
            r = d / length
            if r > 1 + TOL:
                errors.append(f"{name}: {bname} is {d:.1f}, {100*(r-1):.0f}% longer than {length} (max +12%)")
            elif r < 0.5:
                errors.append(f"{name}: {bname} is {d:.1f}, {100*(1-r):.0f}% shorter than {length} (min -50%)")
            elif r < 1 - TOL:
                notes.append(f"{name}: {bname} is {d:.1f} ({100*(1-r):.0f}% short; fine only if it points at the viewer)")
    if len(poses) == 2:
        s, e = poses["start"], poses["end"]
        for k in required(fig):
            d = dist(s[k], e[k])
            if fig.get("hold"):
                if d > 3:
                    errors.append(f"{k} moves {d:.1f} in a hold (breathing only, max 3)")
            elif 0 < d <= 1.0:
                errors.append(f"{k} moves only {d:.2f}: make it identical in both poses")
    load_ = fig.get("load", {"type": "none"})
    t = load_.get("type", "none")
    if t not in LOADS:
        errors.append(f"load type {t!r} unknown")
    elif t in ("cable", "band") and "anchor" not in load_:
        errors.append(f"{t} load needs an anchor")
    for i, pr in enumerate(fig.get("props", [])):
        if not any(k in pr for k in ("line", "circle", "rect")):
            errors.append(f"prop {i}: needs line, circle or rect")
    return merge(errors), merge(notes)


def merge(msgs):
    """'start: X' and 'end: X' become 'both poses: X'."""
    out = []
    for m in msgs:
        if m.startswith("end: ") and "start: " + m[5:] in msgs:
            continue
        if m.startswith("start: ") and "end: " + m[7:] in msgs:
            m = "both poses: " + m[7:]
        out.append(m)
    return out


def cmd_check():
    ids = all_ids()
    bad = 0
    for fid in ids:
        errors, notes = check_one(fid)
        print(f"{'FAIL' if errors else 'ok  '} {fid}")
        for m in errors:
            print(f"     error: {m}")
        for m in notes:
            print(f"     note:  {m}")
        bad += bool(errors)
    print(f"{len(ids) - bad}/{len(ids)} figures pass")
    return 1 if bad else 0


# ---------- drawing ----------
# A drawing is a list of (tag, attrs). It is built once per pose; the start and
# end lists have the same shape, and attributes that differ get an <animate>.

def f1(v):
    s = f"{v:.1f}"
    return s[:-2] if s.endswith(".0") else s


def pts(*ps):
    return " ".join(f"{f1(p[0])},{f1(p[1])}" for p in ps)


def line(ps, color, w, **extra):
    a = {"points": pts(*ps), "fill": "none", "stroke": color, "stroke-width": f1(w),
         "stroke-linecap": "round", "stroke-linejoin": "round"}
    a.update(extra)
    return ("polyline", a)


def seg(p, angle_deg, length):
    """Two points: a segment of `length` centred on p at `angle_deg`."""
    a = math.radians(angle_deg)
    dx, dy = math.cos(a) * length / 2, math.sin(a) * length / 2
    return (p[0] - dx, p[1] - dy), (p[0] + dx, p[1] + dy)


def offset(p, angle_deg, d):
    a = math.radians(angle_deg)
    return (p[0] + math.cos(a) * d, p[1] + math.sin(a) * d)


def angle(a, b):
    return math.degrees(math.atan2(b[1] - a[1], b[0] - a[0]))


def draw_dumbbell(p, ang, color, extra):
    a, b = seg(p, ang, 18)
    out = [line([a, b], color, 7, **extra)]
    for q in (a, b):
        c, d = seg(q, ang + 90, 13)
        out.append(line([c, d], color, 4.5, **extra))
    return out


def draw_load(fig, p, side):
    """Load shapes for one side ('far' or 'near') of pose p."""
    ld = fig.get("load", {"type": "none"})
    t = ld.get("type", "none")
    at = ld.get("at", "hands")
    front = fig.get("view") == "front"
    extra = {"stroke-opacity": "0.55"} if side == "far" else {}
    hands = [("handR", "far"), ("handL", "near")] if not front else [("handL", "near"), ("handR", "near")]
    out = []
    if t == "dumbbells":
        for h, s in hands:
            if s == side:
                out += draw_dumbbell(p[h], ld.get("angle", 0), VOLT, extra)
    elif t in ("kettlebell", "plate"):
        for h, s in hands:
            if s != side:
                continue
            q = p[h]
            if t == "kettlebell":
                c = (q[0], q[1] + 10)
                out.append(line([(q[0] - 4, q[1]), (q[0] + 4, q[1])], VOLT, 3, **extra))
                out.append(("circle", dict({"cx": f1(c[0]), "cy": f1(c[1]), "r": "7", "fill": VOLT},
                                           **({"fill-opacity": "0.55"} if extra else {}))))
            else:
                out.append(("circle", {"cx": f1(q[0]), "cy": f1(q[1]), "r": "11", "fill": "none",
                                       "stroke": VOLT, "stroke-width": "4", **extra}))
    elif t == "barbell" and side == "near":
        if front and at == "hands":
            l, r = p["handL"], p["handR"]
            ang = angle(l, r)
            a, b = offset(l, ang, -22), offset(r, ang, 22)
            out.append(line([a, b], VOLT, 4))
            for q, sgn in ((l, -1), (r, 1)):
                for k in (12, 17):
                    c, d = seg(offset(q, ang, sgn * k), ang + 90, 26)
                    out.append(line([c, d], VOLT, 4.5))
        else:
            q = p["handL"] if at == "hands" else p[at]
            out.append(("circle", {"cx": f1(q[0]), "cy": f1(q[1]), "r": "14", "fill": "none",
                                   "stroke": VOLT, "stroke-width": "5"}))
            out.append(("circle", {"cx": f1(q[0]), "cy": f1(q[1]), "r": "3", "fill": VOLT}))
    elif t in ("cable", "band") and side == "near":
        q = p["handL"] if at == "hands" else p[at]
        anc = ld["anchor"]
        dash = {"stroke-dasharray": "5 4"} if t == "band" else {}
        out.append(line([anc, q], VOLT, 2.5, **dash))
        if at == "hands":
            c, d = seg(q, angle(anc, q) + 90, 12)
            out.append(line([c, d], VOLT, 5))
    elif t == "pad" and side == "near":
        q = p[at]
        if "lever" in ld:
            out.append(line([ld["lever"], q], PROP, 4))
        limb = {"ankleL": ("kneeL", "ankleL"), "toeL": ("ankleL", "toeL"), "kneeL": ("pelvis", "kneeL")}[at]
        if front and at == "kneeL":
            limb = ("hipL", "kneeL")
        c, d = seg(q, angle(p[limb[0]], p[limb[1]]) + 90, 16)
        out.append(line([c, d], VOLT, 8))
    return out


LOADS = ("none", "dumbbells", "barbell", "cable", "band", "kettlebell", "plate", "pad")


def draw_body(fig, p):
    front = fig.get("view") == "front"
    out = []
    if front:
        body_color = {"L": WHITE, "R": WHITE}
        arm_root = {"L": "shoulderL", "R": "shoulderR"}
        leg_root = {"L": "hipL", "R": "hipR"}
    else:
        body_color = {"L": WHITE, "R": FAR}
        arm_root = {"L": "neck", "R": "neck"}
        leg_root = {"L": "pelvis", "R": "pelvis"}

    def limbs(s):
        c = body_color[s]
        leg = [p[leg_root[s]], p["knee" + s], p["ankle" + s], p["toe" + s]]
        arm = [p[arm_root[s]], p["elbow" + s], p["hand" + s]]
        out = []
        for pts_ in (leg, arm):
            if s == "L" and not front:
                # a background-coloured edge so a near limb crossing the torso stays readable
                # starts a little way out so the limb stays joined to the torso
                a, b = pts_[0], pts_[1]
                t = min(0.45, HALO_TRIM / max(dist(a, b), 1e-6))
                first = (a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t)
                out.append(line([first] + pts_[1:], HALO, LIMB_W + 2 * HALO_W))
            out.append(line(pts_, c, LIMB_W))
        return out

    if not front:
        out += limbs("R")
        out += draw_load(fig, p, "far")
        out.append(line([p["neck"], p["pelvis"]], WHITE, TORSO_W))
    else:
        out.append(line([p["shoulderL"], p["neck"], p["shoulderR"]], WHITE, TORSO_W))
        out.append(line([p["neck"], p["pelvis"]], WHITE, TORSO_W))
        out.append(line([p["hipL"], p["hipR"]], WHITE, TORSO_W))
        out += limbs("R")
    out += limbs("L")
    out.append(("circle", {"cx": f1(p["head"][0]), "cy": f1(p["head"][1]), "r": str(HEAD_R), "fill": WHITE}))
    out += draw_load(fig, p, "near")
    return out


def draw_props(fig):
    out = []
    for pr in fig.get("props", []):
        if "line" in pr:
            out.append(line(pr["line"], PROP, pr.get("w", 6)))
        elif "circle" in pr:
            x, y, r = pr["circle"]
            out.append(("circle", {"cx": f1(x), "cy": f1(y), "r": f1(r), "fill": "none",
                                   "stroke": PROP, "stroke-width": f1(pr.get("w", 3))}))
        elif "rect" in pr:
            x, y, w, h, *r = pr["rect"] + [0]
            out.append(("rect", {"x": f1(x), "y": f1(y), "width": f1(w), "height": f1(h),
                                 "rx": f1(r[0]), "fill": PROP}))
    return out


def el(tag, attrs, anim=None, dur=None):
    a = " ".join(f'{k}="{v}"' for k, v in attrs.items())
    if not anim:
        return f"<{tag} {a}/>"
    inner = "".join(
        f'<animate attributeName="{k}" values="{s};{e};{s}" keyTimes="0;0.5;1" calcMode="spline" '
        f'keySplines="{SPLINE}" dur="{dur}s" repeatCount="indefinite"/>'
        for k, (s, e) in anim.items())
    return f"<{tag} {a}>{inner}</{tag}>"


def bounds(items):
    """Box (x0, y0, x1, y1) of drawn items, strokes and radii included."""
    xs0, ys0, xs1, ys1 = [], [], [], []
    for tag, a in items:
        if tag == "polyline":
            h = float(a["stroke-width"]) / 2
            for pair in a["points"].split():
                x, y = map(float, pair.split(","))
                xs0.append(x - h); xs1.append(x + h); ys0.append(y - h); ys1.append(y + h)
        elif tag == "circle":
            x, y = float(a["cx"]), float(a["cy"])
            r = float(a["r"]) + float(a.get("stroke-width", 0)) / 2
            xs0.append(x - r); xs1.append(x + r); ys0.append(y - r); ys1.append(y + r)
        elif tag == "rect":
            x, y = float(a["x"]), float(a["y"])
            xs0.append(x); xs1.append(x + float(a["width"])); ys0.append(y); ys1.append(y + float(a["height"]))
    return min(xs0), min(ys0), max(xs1), max(ys1)


def crop(fig):
    """The figure's square viewBox: both poses, props and load, plus AIR, side MIN_SIDE..200."""
    items = draw_props(fig) + draw_body(fig, fig["start"]) + draw_body(fig, fig["end"])
    x0, y0, x1, y1 = bounds(items)
    floor = fig.get("floor", 182)
    y0, y1 = min(y0, floor - 1), max(y1, floor + 1)
    side = min(200.0, max(MIN_SIDE, x1 - x0 + 2 * AIR, y1 - y0 + 2 * AIR))
    # centred on the content; may reach past the 200 box (the SVG is transparent)
    vx, vy = (x0 + x1 - side) / 2, (y0 + y1 - side) / 2
    return vx, vy, side


def svg(fig_id, still=False, size=200, pose=None):
    """Self-contained inline SVG for one figure.
    still=False: animated loop. still=True: ghost start under solid end.
    pose='start' or 'end': that pose alone, still."""
    fig = load(fig_id)
    floor = fig.get("floor", 182)
    vx, vy, side = crop(fig)
    parts = [el("line", {"x1": f1(vx), "y1": str(floor), "x2": f1(vx + side), "y2": str(floor),
                         "stroke": FLOOR, "stroke-width": "2"})]
    parts += [el(t, a) for t, a in draw_props(fig)]
    s, e = fig["start"], fig["end"]
    if pose:
        parts += [el(t, a) for t, a in draw_body(fig, fig[pose])]
    elif still:
        parts.append('<g opacity="0.3">' + "".join(el(t, a) for t, a in draw_body(fig, s)) + "</g>")
        parts += [el(t, a) for t, a in draw_body(fig, e)]
    else:
        dur = f1(fig.get("tempo", 2.6))
        for (t, a), (_, b) in zip(draw_body(fig, s), draw_body(fig, e)):
            anim = {k: (a[k], b[k]) for k in a if a[k] != b[k]}
            parts.append(el(t, a, anim, dur))
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="{f1(vx)} {f1(vy)} {f1(side)} {f1(side)}" width="{size}" height="{size}">'
            + "".join(parts) + "</svg>")


# ---------- sheet ----------

def cmd_sheet(out):
    cell = 240
    rows = []
    for fid in all_ids():
        errors, _ = check_one(fid)
        if errors:
            rows.append(f'<tr><td class="id">{fid}<br><span style="color:#FF453A">fails check</span></td></tr>')
            continue
        cells = [svg(fid, pose="start", size=cell), svg(fid, pose="end", size=cell),
                 svg(fid, still=True, size=cell), svg(fid, size=cell)]
        rows.append(f'<tr><td class="id">{fid}</td>' + "".join(f"<td>{c}</td>" for c in cells) + "</tr>")
    html = f"""<!doctype html><html><head><meta charset="utf-8"><title>SpotMe figures</title></head>
<body style="background:#000;color:#8E8E93;font:13px -apple-system,Helvetica,sans-serif;margin:16px">
<table style="border-collapse:collapse">
<tr style="color:#636366"><td></td><td>start</td><td>end</td><td>still (ghost start + end)</td><td>animated</td></tr>
{''.join(rows).replace('<td class="id">', '<td style="color:#fff;width:150px;vertical-align:middle;padding-right:12px">').replace('<td>', '<td style="padding:4px;border:1px solid #1C1C1E">')}
</table></body></html>"""
    with open(out, "w") as f:
        f.write(html)
    print(f"wrote {out}")
    return 0


def main(argv):
    if not argv:
        print(__doc__)
        return 2
    cmd = argv[0]
    if cmd == "check":
        return cmd_check()
    if cmd == "svg" and len(argv) >= 2:
        size = int(argv[argv.index("--size") + 1]) if "--size" in argv else 200
        print(svg(argv[1], still="--still" in argv, size=size))
        return 0
    if cmd == "sheet" and len(argv) == 2:
        return cmd_sheet(argv[1])
    print(__doc__)
    return 2


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
