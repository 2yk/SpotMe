#!/usr/bin/env python3
"""Render and check SpotMe canvas boards in headless Chromium (one at a time, nice 19: this server trades live).

  python3 render.py sheet OUT.png Board1.dc.html Board2.dc.html ...   one picture of several boards, labelled
  python3 render.py check Board1.dc.html ...                           layout checks (no args: every board)
Boards are looked up in ../project; sizes come from ../project/canvas.json.
Chromium here has no SF fonts, so boards show in the fallback (Nunito). Yeshu's devices show SF Rounded.
"""
import html, json, os, re, subprocess, sys, tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
PROJ = os.path.join(HERE, '..', 'project')
CHROME = os.path.expanduser('~/.cache/ms-playwright/chromium_headless_shell-1243/chrome-headless-shell-linux64/chrome-headless-shell')
TMP = os.environ.get('RENDER_TMP') or tempfile.mkdtemp(prefix='spotme-render-')

def chrome(*args):
    return subprocess.run(['flock', '/tmp/chrome22.lock', 'nice', '-n', '19', CHROME, '--no-sandbox', '--hide-scrollbars',
                           '--allow-file-access-from-files', '--virtual-time-budget=7000', *args],
                          capture_output=True, text=True, timeout=240)

def sizes():
    idx = json.load(open(os.path.join(PROJ, 'canvas.json')))
    return {k: (v['w'], v['h'], v.get('title', k), v.get('radius', 0)) for k, v in idx['boards'].items()}

def sheet(out, names, cols=5):
    sz = sizes()
    cells, x, y, rowh, W = [], 20, 20, 0, 0
    for i, n in enumerate(names):
        w, h, title, rad = sz.get(n, (416, 496, n, 0))
        if i and i % cols == 0:
            x, y, rowh = 20, y + rowh + 60, 0
        src = 'file://' + os.path.abspath(os.path.join(PROJ, n))
        cells.append(f'<div style="position:absolute;left:{x}px;top:{y}px;font:600 15px sans-serif;color:#ddd;width:{w}px;white-space:nowrap;overflow:hidden">{html.escape(title)}</div>'
                     f'<iframe src="{src}" style="position:absolute;left:{x}px;top:{y + 24}px;width:{w}px;height:{h}px;border:0;background:#000;border-radius:{rad}px"></iframe>')
        x += w + 24
        W = max(W, x)
        rowh = max(rowh, h + 24)
    H = y + rowh + 20
    page = os.path.join(TMP, 'sheet.html')
    open(page, 'w').write(f'<!doctype html><html><body style="margin:0;background:#3a3a3e;width:{W}px;height:{H}px;position:relative">{"".join(cells)}</body></html>')
    chrome(f'--window-size={W},{H}', f'--screenshot={os.path.abspath(out)}', 'file://' + page)
    print(f'{out}: {len(names)} boards, {W}x{H}')

JS = r'''
<script>
function spotcheck(){
  const root = document.querySelector('x-dc > div') || document.body;
  const rb = root.getBoundingClientRect();
  const out = {outside: [], cut: [], overlap: [], small: [], tap: [], holes: []};
  const leaves = [];
  const tw = document.createTreeWalker(root, NodeFilter.SHOW_TEXT);
  while (tw.nextNode()) {
    const t = tw.currentNode, s = t.textContent.trim(); if (!s) continue;
    const el = t.parentElement, cs = getComputedStyle(el);
    if (cs.visibility === 'hidden' || cs.display === 'none' || parseFloat(cs.opacity) === 0) continue;
    if (/\{\{|\}\}/.test(s)) out.holes.push(s.slice(0, 40));
    const rg = document.createRange(); rg.selectNodeContents(t);
    let box = null;
    for (const q of rg.getClientRects()) { if (q.width < 1) continue;
      box = box ? {l: Math.min(box.l, q.left), t: Math.min(box.t, q.top), r: Math.max(box.r, q.right), b: Math.max(box.b, q.bottom)} : {l: q.left, t: q.top, r: q.right, b: q.bottom}; }
    if (!box) continue;
    // what shows after every clipping ancestor
    let vis = {...box}, a = el, clipped = false;
    while (a && a !== document.body) {
      const s2 = getComputedStyle(a);
      if (s2.overflow !== 'visible' || s2.overflowX !== 'visible' || s2.overflowY !== 'visible') {
        const b = a.getBoundingClientRect();
        if (box.r > b.right + 1 || box.b > b.bottom + 1 || box.l < b.left - 1 || box.t < b.top - 1) { if (a !== root && !a.hasAttribute('data-scroll')) clipped = true; }
        vis = {l: Math.max(vis.l, b.left), t: Math.max(vis.t, b.top), r: Math.min(vis.r, b.right), b: Math.min(vis.b, b.bottom)};
      }
      a = a.parentElement;
    }
    const label = s.slice(0, 40);
    if (vis.r - vis.l < 1 || vis.b - vis.t < 1) continue;               // fully scrolled away: fine
    if (clipped) out.cut.push(label);
    if (box.r > rb.right + 1 || box.l < rb.left - 1) out.outside.push(label);
    const fs = parseFloat(cs.fontSize); if (fs < MINFS) out.small.push(label + ' @' + fs);
    // glyphs are shorter than the font box: trim it, or big tight lines look like they overlap their neighbours
    leaves.push({el, label, l: vis.l, r: vis.r, t: vis.t + fs * 0.22, b: vis.b - fs * 0.2});
  }
  for (let i = 0; i < leaves.length; i++) for (let j = i + 1; j < leaves.length; j++) {
    const p = leaves[i], q = leaves[j];
    if (p.el === q.el || p.el.contains(q.el) || q.el.contains(p.el)) continue;
    const ox = Math.min(p.r, q.r) - Math.max(p.l, q.l), oy = Math.min(p.b, q.b) - Math.max(p.t, q.t);
    if (ox > 3 && oy > 3) out.overlap.push(p.label + ' × ' + q.label);
  }
  root.querySelectorAll('button, a[href]').forEach(b => { const r = b.getBoundingClientRect();
    if (r.bottom > rb.top && r.top < rb.bottom && (r.height < MINTAP || r.width < MINTAP)) out.tap.push((b.getAttribute('aria-label') || b.textContent.trim()).slice(0, 30) + ' ' + Math.round(r.width) + 'x' + Math.round(r.height)); });
  out.root = Math.round(rb.width) + 'x' + Math.round(rb.height);
  const pre = document.createElement('pre'); pre.id = 'spotcheck'; pre.textContent = JSON.stringify(out); document.body.appendChild(pre);
}
window.addEventListener('load', () => { (document.fonts ? document.fonts.ready : Promise.resolve()).then(() => setTimeout(spotcheck, 80)); });
</script>
'''

def check(names):
    sz = sizes()
    names = names or sorted(sz)
    bad = 0
    for n in names:
        path = os.path.join(PROJ, n)
        if not os.path.exists(path): print(f'{n}: MISSING FILE'); bad += 1; continue
        src = open(path).read()
        problems = []
        if '<script src="./support.js"></script>' not in src: problems.append('support.js line missing')
        if 'data-dc-script' not in src: problems.append('dc script block missing')
        if '—' in src: problems.append('em-dash in text')
        w, h, _, _ = sz.get(n, (416, 496, n, 0))
        p = os.path.join(TMP, n.replace('.dc.html', '.chk.html'))
        # the copy sits next to nothing, so point relative assets back at the project folder
        phone = n[0] in 'POF'
        lim = f'<script>const MINFS = {10 if phone else 20}, MINTAP = {30 if phone else 60};</script>'
        open(p, 'w').write(src.replace('</body>', lim + JS + '</body>', 1))
        dom = chrome(f'--window-size={w},{h}', '--dump-dom', 'file://' + p).stdout
        m = re.search(r'<pre id="spotcheck">(.*?)</pre>', dom, re.S)
        if not m: print(f'{n}: no result from the browser'); bad += 1; continue
        r = json.loads(html.unescape(m.group(1)))
        if r['root'] != f'{w}x{h}': problems.append(f'root is {r["root"]}, frame is {w}x{h}')
        for k, what in (('outside', 'text outside the board'), ('cut', 'text cut off'), ('overlap', 'text overlapping'),
                        ('small', 'text too small'), ('tap', 'small tap target'), ('holes', 'unfilled {{hole}}')):
            if r[k]: problems.append(f'{what}: {r[k][:6]}')
        if problems: bad += 1
        print(f'{n}: ' + ('ok' if not problems else ' | '.join(problems)))
    print(f'{len(names)} boards checked, {bad} with findings')
    return bad

if __name__ == '__main__':
    if len(sys.argv) >= 4 and sys.argv[1] == 'sheet': sheet(sys.argv[2], sys.argv[3:])
    elif len(sys.argv) >= 2 and sys.argv[1] == 'check': sys.exit(1 if check(sys.argv[2:]) else 0)
    else: print(__doc__)
