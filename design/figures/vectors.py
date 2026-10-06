#!/usr/bin/env python3
"""Golden values for the Swift port of figure3d.py: bundle/vectors.json.

  python3 vectors.py

For each listed figure, at several angles and points in the rep:
  centre [cx, cz], crop [x, y, side]
  points   every body point projected: [screen x, screen y, depth]
  order    part keys in draw order (far to near); "edge" lists the limbs that carry the black edge
  depths   depth per part
and, at yaw 40 only, "draw": the complete draw list in order, each item [tag, points or circle, stroke
width, colour, opacity, dash]. k is the eased position in the rep (0 = start pose, 1 = end pose).
Numbers are rounded to 2 decimals (draw list coordinates to 1, as the SVG prints them).
"""
import json, os
import figure3d as F

HERE = os.path.dirname(os.path.abspath(__file__))
WANT = ["incline-db-press", "pull-ups", "rope-pushdown", "leg-extension", "hip-thrust", "machine-chest-press",
        "leg-press", "low-to-high-cable-fly", "plank", "weighted-pull-ups", "ab-wheel-rollout", "preacher-curl"]
YAWS = [0, 40, 200]

def r2(v): return round(v + 0.0, 2)

def item(tag, a):
    if tag == "circle":
        geo = [float(a["cx"]), float(a["cy"]), float(a["r"])]
    else:
        geo = [[float(n) for n in p.split(",")] for p in a["points"].split()]
    return [tag, geo, float(a.get("stroke-width", 0)), a.get("stroke") or a.get("fill"), a.get("fill", "none"),
            float(a.get("opacity", 1)), a.get("stroke-dasharray", "")]

def case(fig, yaw, k):
    c = F.centre(fig)
    p = F.lerp_pose(fig, k)
    ps = F.parts(fig, p, yaw, c)
    out = {"yaw": yaw, "k": k,
           "points": {n: [r2(F.project(v, yaw, c)[0][0]), r2(v[1]), r2(F.project(v, yaw, c)[1])] for n, v in p.items()},
           "order": [], "edge": [], "depths": {q["key"]: r2(q["depth"]) for q in ps}}
    seen = False
    draw = []
    for i in F.order(ps):
        q = ps[i]
        out["order"].append(q["key"])
        if q["kind"] == "limb" and seen:
            out["edge"].append(q["key"])
            draw += [item(*it) for it in q["halo"]]
        draw += [item(*it) for it in q["items"]]
        seen = seen or q["kind"] == "torso"
    if yaw == 40:
        out["draw"] = draw
    return out

def main():
    figs = {}
    for fid in WANT:
        if not os.path.exists(os.path.join(F.POSES3D, fid + ".json")):
            print("not yet:", fid)
            continue
        fig = F.load(fid)
        c = F.centre(fig)
        figs[fid] = {"centre": [r2(c[0]), r2(c[1])], "crop": [r2(v) for v in F.crop(fig)],
                     "cases": [case(fig, y, k) for y in YAWS for k in (0, 1)] + [case(fig, 40, 0.5)]}
    os.makedirs(os.path.join(HERE, "bundle"), exist_ok=True)
    path = os.path.join(HERE, "bundle", "vectors.json")
    json.dump({"version": 1, "figures": figs}, open(path, "w"), separators=(",", ":"), sort_keys=True)
    print(f"{len(figs)} figures, {os.path.getsize(path) // 1024} KB")

if __name__ == "__main__":
    main()
