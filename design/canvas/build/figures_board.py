#!/usr/bin/env python3
"""Writes ../project/F133-PlanFigures.dc.html: every plan exercise's figure, moving, at its opening view.
A gallery board put together by script, as allowed for figure galleries (its content is the renderer's output).

  python3 figures_board.py
"""
import html, json, os, sys
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '..', '..', 'figures'))
import figure3d as F

COLS, FIG, W = 8, 116, 1280
db = json.load(open(os.path.join(HERE, '..', '..', 'exercise-db', 'exercises.json')))
db = db['exercises'] if isinstance(db, dict) else db
plan = [e for e in db if e.get('planIds') and os.path.exists(os.path.join(F.POSES3D, e['id'] + '.json'))]
cells = []
for e in plan:
    cells.append('<div style="background: #000000; border-radius: 20px; padding: 10px 6px 10px; display: flex; flex-direction: column; align-items: center; gap: 6px">'
                 + F.svg(e['id'], size=FIG)
                 + f'<span style="font-size: 13px; line-height: 17px; font-weight: 600; color: #FFFFFF; text-align: center; height: 34px; display: flex; align-items: center">{html.escape(e["name"])}</span></div>')
rows = -(-len(plan) // COLS)
H = 40 + 44 + 24 + rows * (10 + FIG + 6 + 34 + 10) + (rows - 1) * 12 + 40
mark = '<svg aria-hidden="true" width="40" height="40" viewBox="122 130 780 780"><circle cx="512" cy="439" r="150" fill="#CCFF3D"></circle><path d="M760.56 404.07A251 251 0 1 1 263.44 404.07" fill="none" stroke="#FFFFFF" stroke-width="122" stroke-linecap="round"></path></svg>'
doc = f'''<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>SpotMe · Your plan's figures</title>
<script src="./support.js"></script>
</head>
<body>
<x-dc>
<helmet>
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Nunito:wght@500..900&amp;display=swap">
<style>
body{{margin:0;background:#000000}}
button{{font:inherit;color:inherit;border:0;background:none;padding:0;margin:0;text-align:inherit;cursor:pointer}}
a{{color:#CCFF3D}}a:hover{{color:#DFFF87}}
</style>
</helmet>
<div style="position: relative; width: {W}px; height: {H}px; box-sizing: border-box; padding: 40px; background: #0B0B0C; border-radius: 0; overflow: hidden; color: #FFFFFF; font-family: ui-rounded, 'SF Pro Rounded', 'Nunito', system-ui, sans-serif; font-variant-numeric: tabular-nums; display: flex; flex-direction: column">
<div style="display: flex; align-items: center; gap: 16px">{mark}<span style="font-size: 40px; line-height: 44px; font-weight: 800; color: #FFFFFF">Your plan's figures</span><span style="margin-left: auto; font-size: 20px; line-height: 24px; font-weight: 800; letter-spacing: 0.06em; color: #8E8E93">{len(plan)} FIGURES · EVERY ONE TURNS ON THE WATCH</span></div>
<div style="margin-top: 24px; display: grid; grid-template-columns: repeat({COLS}, minmax(0, 1fr)); gap: 12px">
{chr(10).join(cells)}
</div>
</div>
</x-dc>
<script type="text/x-dc" data-dc-script data-props='{{"$preview":{{"width":{W},"height":{H}}}}}'>
class Component extends DCLogic {{
renderVals() {{
return {{}};
}}
}}
</script>
</body>
</html>
'''
out = os.path.join(HERE, '..', 'project', 'F133-PlanFigures.dc.html')
open(out, 'w').write(doc)
print(f'{len(plan)} figures, {W} x {H}, {os.path.getsize(out) // 1024} KB')
