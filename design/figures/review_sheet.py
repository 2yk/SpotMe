#!/usr/bin/env python3
"""review_sheet.py OUT.png id id ...  : per figure a row: START and END at the opening view (220 px), END at
opening+60, +120, +180, +270 (150 px), the 80 px still, the 40 px still."""
import sys, os, json, subprocess
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import figure3d as F
out, ids = os.path.abspath(sys.argv[1]), sys.argv[2:]
rows = []
for fid in ids:
    fig = F.load(fid); y0 = fig.get('yaw', 0)
    cells = [F.svg(fid, yaw=y0, pose='start', size=220), F.svg(fid, yaw=y0, pose='end', size=220)]
    cells += [F.svg(fid, yaw=(y0 + d) % 360, pose='end', size=150) for d in (60, 120, 180, 270)]
    cells += [F.svg(fid, yaw=y0, still=True, size=80), F.svg(fid, yaw=y0, pose='end', size=40)]
    rows.append(f'<div style="color:#ddd;font:600 14px sans-serif;margin:6px 0 2px">{fid} · opens at {y0}° · {fig.get("view")} · hold {fig.get("hold")}</div><div style="display:flex;gap:8px;align-items:flex-end">' + ''.join(f'<div style="background:#000;border:1px solid #333">{c}</div>' for c in cells) + '</div>')
H = 20 + len(ids) * 252
html = f'<!doctype html><body style="margin:10px;background:#1c1c1e;width:1380px">{"".join(rows)}</body>'
p = out.replace('.png', '.html'); open(p, 'w').write(html)
subprocess.run(['flock', '/tmp/chrome22.lock', 'nice', '-n', '19', os.path.expanduser('~/.cache/ms-playwright/chromium_headless_shell-1243/chrome-headless-shell-linux64/chrome-headless-shell'), '--no-sandbox', '--hide-scrollbars', f'--screenshot={out}', f'--window-size=1400,{H}', 'file://' + p], capture_output=True, timeout=240)
print(out, H)
