# SpotMe form figures · rules

Asked by Yeshu, 6 Oct 2026: "dynamic artwork to show which workout is which; most of the time I need to
google it during workouts". Planner: Fable. Status: proof of concept, 12 exercises.

## The idea

Every exercise gets a small moving line figure: one person, the equipment, and the movement from its start
position to its end position and back, on a loop. It is drawn by the app from a few numbers (two poses), not
stored as pictures or video, so it is tiny, sharp at any size, works on the watch, follows the app's colours,
and all 236 exercises look like one family. A still version (end pose solid, start pose as a ghost) covers
Always On and Reduce Motion.

What a figure must do, in order: (1) be recognisable at 80 pt on the watch as that exercise and no other,
(2) show the body position and what moves, (3) show where the load is. It is a reminder, not a coaching video.

## Files

- `poses/<exercise id>.json`: one figure. The id is the database id (`../exercise-db`).
- `figure.py`: reads poses, checks them, and writes SVG. `python3 figure.py check` checks every pose;
  `python3 figure.py svg <id> [--still]` prints one SVG; `python3 figure.py sheet out.html` writes a review
  page with every figure (still pair and animation).

## The drawing space

A 200 × 200 box, x to the right, y down. The floor is a line at `floor` (usually y = 182). Keep everything
inside 8..192. Side view by default; the person faces right unless the equipment says otherwise.

## The body

Thirteen points. In side view "L" is the arm or leg nearer the viewer, "R" the far one (drawn underneath,
dimmer). In front view L is the viewer's left.

`head` (centre), `neck`, `pelvis`, `elbowL`, `handL`, `elbowR`, `handR`, `kneeL`, `ankleL`, `toeL`, `kneeR`,
`ankleR`, `toeR`. Front view adds `shoulderL`, `shoulderR`, `hipL`, `hipR`; in side view the arms start at
`neck` and the legs at `pelvis`.

Bone lengths (the checker allows ±12%; a bone pointing toward or away from the viewer may be shorter, down
to half, never longer):

| Bone | Length | | Bone | Length |
|---|---|---|---|---|
| neck → pelvis | 50 | | pelvis/hip → knee | 38 |
| neck → head centre | 17 | | knee → ankle | 36 |
| neck/shoulder → elbow | 27 | | ankle → toe | 13 |
| elbow → hand | 25 | | head radius | 11 |

Front view: shoulders 15 either side of the neck, hips 9 either side of the pelvis.
A standing figure is about 152 tall: with the floor at 182 the head centre sits near y = 41.

Believable joints: elbows and knees bend one way only; in side view facing right a knee bends so the knee
is in front of the hip-ankle line, an elbow so the hand comes forward of or up from the elbow. Feet rest on the
floor or a prop unless the exercise hangs. Hands are on the load. In a pose where both arms or both legs do the
same thing in side view, give the far limb the same points shifted by 3 to 5 units so it reads as a second limb.

## Props and the load

`props`: things that don't move, drawn grey. Three primitives:
`{"line": [[x,y],[x,y],...], "w": 6}` (rounded polyline), `{"circle": [x, y, r]}` (outline), and
`{"rect": [x, y, w, h, r]}` (filled). Build a bench from two or three lines, a pull-up bar from a small filled
circle (seen end-on in side view) or a line (front view), a machine from a few lines. Use as few as tell the story.

`load`: what the person moves, drawn in volt, attached to body points so it follows the movement:

| `type` | `at` | Drawn as |
|---|---|---|
| `dumbbells` | `hands` | A short thick bar through each hand, horizontal unless `"angle"` is given |
| `barbell` | `hands`, `neck` (on the back) or `pelvis` (hip thrust) | Side view: a plate circle at the point. Front view: a bar through both hands with plates |
| `cable` | `hands` (or `ankleL`) | A thin line from `anchor` `[x, y]` to the point, with a short handle |
| `band` | `hands` | As cable, dashed |
| `kettlebell`, `plate` | `hands` | A small shape hanging from or held at the hands |
| `pad` | `ankleL`, `toeL`, `kneeL` | A short thick bar across the limb (leg machines), with an optional grey `lever` line from a pivot `[x, y]` |
| `none` | | Nothing (bodyweight) |

## One pose file

```json
{
  "id": "plank",
  "view": "side",
  "floor": 182,
  "tempo": 2.6,
  "hold": true,
  "props": [],
  "load": {"type": "none"},
  "start": {"head": [..], "neck": [..], "pelvis": [..], "elbowL": [..], "handL": [..], "elbowR": [..], "handR": [..],
            "kneeL": [..], "ankleL": [..], "toeL": [..], "kneeR": [..], "ankleR": [..], "toeR": [..]},
  "end": { ...the same thirteen points... }
}
```

- `start` is where a rep begins (usually the stretched or lowered position), `end` the other end of the rep.
- `tempo`: seconds for start → end → start. Default 2.6.
- `hold: true` for timed holds: `end` equals `start` except for a small breathing movement (2 units), so it
  still reads as alive.
- Points the movement doesn't change must be identical in both poses, so nothing wobbles.

## The look (what `figure.py` draws)

- Black background is the app's; the SVG itself is transparent.
- Far limbs first in `#6E6E73`, then torso, near limbs and head in `#FFFFFF`. Limbs are 9 wide, the torso 12,
  round caps and joins. The head is a filled circle.
- Props `#8E8E93`. Floor: a 2 px line `#3A3A3C` across the box.
- Load `#CCFF3D`; cable and band lines 2.5 wide; dumbbells 7 wide and 18 long with small end caps.
- Animated: every point moves start → end → start with ease in and out, forever (SMIL `<animate>` inside the SVG,
  no script). Still: the start pose at 30% opacity under the solid end pose, with the load shown in both.
- In side view the near arm and near leg carry a thin black edge, so a white arm crossing the white torso
  still reads. (On a light background that edge must take the background's colour.)
- The picture is cropped to the figure: the viewBox is the smallest square that holds both poses, the props
  and the load, plus 10 units of air, so a plank fills its frame as well as a standing press does. The floor
  line always runs the full width of the crop.
- Every element is plain inline SVG with explicit attributes (no `<style>`, no classes, no ids that could
  clash when several figures share a page: prefix any id with the exercise id).

## How the planner checks a figure

`figure.py check` passes (bone lengths, points inside the box, both poses complete), then the planner looks
at the review sheet: is it that exercise at a glance, do the joints bend the right way, does the load sit in
the hands, do feet stay on the floor.

## Authoring a pose (learned on the first three)

1. Never type coordinates. Write a small script that places each point from its parent with an angle and the
   bone length (`neck = P(pelvis, torso_angle, 50)`), rounds, and writes the JSON. A tweak is then one angle.
2. Work from what is fixed: feet on the floor or a prop and the seat decide where the pelvis is. A seated
   shin of 36 puts the knee near y 140 with the floor at 182.
3. The far limb shares its root with the near one. Shift its joints one by one (the knee across the thigh, the
   ankle and toe along the floor), or the bone comes out short.
4. Overlap is the enemy, not angles. Keep an upper arm at least 30° off the torso line, swing overhead arms a
   little forward of the head, and let the load sit clear of the head.
5. A bench or pad runs parallel to the body part on it, about 9 units away from the body's centre line.
6. A cable's anchor lies on the line the hands travel, extended toward the pulley, so the cable stays straight.
7. Holds: every point identical, the pelvis moving 2 units, tempo 4.
8. Judge a movement from the start and end stills, and look at the figure at 80 px as well as 240.

## What the proof of concept showed (6 Oct 2026)

Twelve figures, authored by four builders in about fifteen minutes each from written descriptions, all
recognisable as their exercise: incline DB press, chest-supported row, lat pulldown, pull-ups (front), cable
lateral raise (front), rope pushdown, Bayesian curl, leg press, Bulgarian split squat, hip thrust, hanging leg
raise, plank. The format, the renderer and the checker held up without changes to the pose format.

Before all 247 are made, the renderer should gain:
- a dark edge on limbs in front view too, so an arm can cross the body;
- a rope handle (two short tails) and a way to choose which hand a cable goes to;
- a load drawn at a fixed angle (a leg-press plate that slides without turning) and a bar that can sit a
  little off its body point (hip thrust);
- a bolder still for sizes under about 80 px: at 72 px the split squat, hip thrust and hanging leg raise get
  thin. Stills that small should drop the ghost pose and thicken the lines.

## Turning a figure (proof of concept, 6 Oct 2026)

Asked by Yeshu: "can we rotate them to see all side angles?" A figure can be turned when its poses store
depth. `poses3d/<id>.json` is the same file with three numbers per point, drawn by `figure3d.py`.

- Axes: x to the right and y down as before, in the figure's usual view; z comes toward the viewer in that
  view. For a side view z = 0 is the plane through the middle of the body.
- All seventeen points are given (shoulders and hips too), whatever the view. Shoulders sit 15 either side of
  the neck along the body's left-right axis, hips 9 either side of the pelvis. Bone lengths are checked in 3D,
  with no foreshortening allowance: a bone is its true length.
- Props and loads get depth too: a bench has width, a bar runs across the body through both hands, each hand
  has its own dumbbell, a cable anchor is a point in space.
- `yaw` turns the scene about the vertical axis through the middle of the figure: 0 is the usual view. The
  drawing is an orthographic projection; parts are drawn far to near, and a limb is dimmed by how far behind
  the body's middle it is, instead of by a fixed near and far side.
- The picture's crop is the same for every angle of one figure, so it does not jump while turning.
- On the watch the Digital Crown turns the figure on the How screen; on the iPhone a finger does.

What the turning proof showed: three figures (incline DB press, Bulgarian split squat, pull-ups) rebuilt with
depth stay recognisable from eight angles and match their 2D versions from the usual side. A figure at one
angle is about 12 KB of SVG; one that turns while it moves is 35 to 68 KB, 5 to 11 KB compressed (the app
draws from the pose numbers, so this only matters for these boards). Weak angles are the ones any real view
has: straight from behind a bench, or a split stance seen head-on. Authoring a pose with depth takes two to
three times as long as a flat one, more for machines and cables, whose frames and pulleys need depth that
looks right from every side. Suggested order if all 247 are made: free-weight and bodyweight exercises with
depth first, machines flat until a few have proven the prop set.

## The 3D format, complete

Settled 6 Oct 2026 for the Swift port (SwiftUI Canvas: per frame interpolate the pose, project with yaw,
depth-sort the parts, draw). `figure3d.py` is the reference implementation and its docstring says the same
as this section. Authoring helpers for builders: `authoring3d/rig.py` (documented at its top); every figure
has its script in `authoring3d/<id>.py`, which writes `poses3d/<id>.json`.

### The file

`poses3d/<id>.json`: `id`, `view` (`side` or `front`), `floor` (y of the floor line, usually 182), `tempo`
(seconds per rep), `hold` (true for holds), `yaw` (optional, default 0), `props`, `load`, `start`, `end`. `yaw` is the *opening
view*: the angle in degrees (any number, taken mod 360) the figure is first shown at, for exercises whose
movement is hidden from the side (Pallof press, reverse pec deck, Russian twist). It changes nothing about the
axes or the crop: the app shows the figure at that yaw and the Crown turn starts from it. Axes: x right, y down, z toward
the viewer in the usual view (yaw 0). Everything sits in a 200 × 200 box from the usual view.

**Points.** Both poses give all seventeen as `[x, y, z]`: `head neck pelvis shoulderL shoulderR hipL hipR
elbowL handL elbowR handR kneeL ankleL toeL kneeR ankleR toeR`. Side view: L is the near side (+z). Front
view: L is the viewer's left. Bones have their true length in 3D (±12%): neck–pelvis 50, neck–head 17,
shoulder–elbow 27, elbow–hand 25, hip–knee 38, knee–ankle 36, ankle–toe 13; neck–shoulder 15 and pelvis–hip 9
(±1.5). A point that moves moves more than 1; a point that does not is identical in both poses.

**Props** (grey `#8E8E93`, never move):

| Prop | Fields | Drawn as |
|---|---|---|
| line | `line`: [[x,y,z], …], `w` (6) | A 3D polyline, round caps and joins |
| slab | `slab`: [[x,y], …], `z`: [z0, z1], `w` (7) | Each segment of the x-y polyline swept from z0 to z1: a filled quad with a w-wide round outline. Edge-on at yaw 0 it is the 2D line |

**Load** (volt `#CCFF3D`, moves with the body). `load` is one load object or a list of them; each is
drawn by the rules below, independently (a cable fly is two `cable` loads with handle `grip`, at handL and at
handR; a band plus a belt plate is a `band` and a `held`). Central pieces of all of them form the one `load`
part. A *point spec* (`at`) is a body point name, `"hands"` (the
mean of handL and handR) or a list of names (their mean). `offset` [x, y, z] (default 0) is added in world
axes. *Across* is the body's right-to-left unit axis there: shoulderR→shoulderL if any named point is in the
upper body (head, neck, shoulders, elbows, hands), else hipR→hipL. Defaults in brackets.

| `type` | Fields | Drawn as |
|---|---|---|
| `none` | | Nothing |
| `dumbbells` | `axis` ([1,0,0]) | Per hand a bar 18 long along axis, w 7, with caps 13 long across it, w 4.5 |
| `bar` | `at` ("hands"), `offset`, `length` (80), `plate` (14; 0 = none) | A bar w 4 centred at mid-hands along handR→handL, or at the point + offset along *across*; a plate disc of radius `plate`, w 4.5, on the bar axis 6 in from each end. Barbell 80/14, EZ bar 56/8, pulldown or cable bar about 55/0; on the back `"at": "neck"`, on the hips `"at": "pelvis"` with an offset up |
| `cable`, `band` | `anchor` [x,y,z] (required), `handle` ("grip", "bar", "rope"), `at` (grip only: one limb point, "handL") | A line w 2.5 from the anchor (band: dashed 5 on 4 off). grip: to the point, plus a grip 12 long, w 5, perpendicular to the cable and to *across*. bar: to mid-hands, plus a bar w 5 from handR to handL extended 5 each way. rope: to a knot 7 from mid-hands toward the anchor, plus tails knot→handL and knot→handR, w 4 |
| `machine` | `grips` (["handL","handR"], limb points), `pivots` (none, or one [x,y,z] per grip), `axis` ([0,1,0]), `length` (14) | Per grip a grey lever w 4 from its pivot (drawn first) and a volt grip w 6, `length` long along `axis` |
| `pad` | `at` (required: one limb point, or a list), `offset`, `pivot` (none), `length` (22), `w` (10) | A roller w thick, `length` long along *across*, centred at the point + offset; a grey lever w 4 from the pivot to the centre (drawn first) |
| `platform` | `at` (["ankleL","ankleR"]), `offset`, `angle` (90; 0 right, 90 down), `length` (40), `width` (34) | A volt quad, fill at opacity 0.28, with a w 5 volt outline at full opacity: `length` along `angle` in the x-y plane, `width` along world z. Follows the point, never turns (leg press sled) |
| `held` | `kind` ("plate", "kettlebell", "ball", "wheel"), `at` ("hands"), `offset`, `axis` (*across*) | plate: disc r 11, w 4. wheel: disc r 9, w 5. ball: circle r 9. kettlebell: a handle 8 long along axis, w 3, and a circle r 7 10 below it |

### Primitives

Everything is drawn from four: a **segment** or polyline (3D points, width, colour, round caps, optional
dash), a **slab quad** (filled polygon with an outline), a **circle** that always faces the viewer (head
r 11, balls), and a **disc** (centre, axis, radius) drawn as the closed outline of 16 projected rim points:
e1 = axis × [0,1,0] normalised (axis × [1,0,0] if that is zero), e2 = axis × e1, rim i = centre + r cos(2πi/16) e1
+ r sin(2πi/16) e2. A disc turns from a ring into an ellipse into a line.

### Drawing one frame

1. Pose: `p = start + (end − start) · e(k)`, e(k) = (1 − cos πk) / 2; one rep runs k 0 → 1 → 0 in `tempo` s.
2. Centre c: the middle of the x range and of the z range over all body points of both poses.
3. Project every 3D point for `yaw` (orthographic, turning about the vertical line through c):
   dx = x − cx, dz = z − cz; screen x = cx + dx cos yaw − dz sin yaw; screen y = y; depth (toward the viewer)
   = dx sin yaw + dz cos yaw. Yaw 90 shows the side that faced +x.
4. Parts, in this list order: each prop, armL, legL, armR, legR, torso, head, and `load` if present.
   Depth: a limb is the mean of its chain (arm: shoulder, elbow, hand; leg: hip, knee, ankle, toe); torso the
   mean of neck and pelvis; head the head; a prop or the load the mean of its projected points (disc: centre).
5. Sort far to near by (depth rounded to 0.1, kind: prop < limb < load < torso < head); equal keys keep list order.
6. Draw. Limb: polyline w 9, colour blended #FFFFFF → #6E6E73 by dim = clamp((torso depth − mean depth of its
   upper bone's two points − 3) / 12, 0, 1). A limb drawn after the torso first gets a black edge: the same
   polyline in #000000, w 9 + 5, its first point moved 11 along the first bone (at most 45% of it). Torso
   w 12 white: shoulderL–neck–shoulderR, neck–pelvis, hipL–pelvis–hipR. Head: circle r 11 white. Floor:
   line #3A3A3C, w 2, across the crop at y = floor, drawn first.

**Load depth.** A load piece on one side of the body (a dumbbell, a single grip or ankle strap, a machine
grip with its lever, a pad on one limb) rides with that limb: it is drawn right after the limb's line, at
opacity 1 − 0.45 · dim. A bar or pad across both sides is split at its centre into halves that ride with the
L and R arm (hands or an upper-body point) or leg; a pad's lever rides with the half on its pivot's side.
Anything else (a cable to a bar or rope, a held weight, a platform) is one part, `load`, sorted by its own depth.

**Crop.** One square per figure, the same at every angle: the bounds (half stroke widths and circle radii
included) of both poses at yaw 0, 5, … 355, widened to include floor ± 1; side = max(130, width + 20,
height + 20), centred on those bounds.

**Still** (Always On, Reduce Motion): the start pose at opacity 0.3 under the end pose, same yaw.
**Turning** (review boards): a full turn, starting at the opening view, in 12 s with round(12 / tempo) reps, at least one.

### Reference figures with the full vocabulary (6 Oct 2026)

rope-pushdown (cable, rope), leg-extension (pad across both ankles with a lever), hip-thrust (bar on the
hips with plates), machine-chest-press (machine grips with overhead levers). Weak angles: a cable column or
machine frame seen from in front of the person covers part of the body (true of the real view); seated
figures from behind show mostly the back pad.

## Status (6 Oct 2026): the plan's 50 figures

Approved by Yeshu for the watch on 6 Oct: every exercise in his plan gets a figure, and every one turns. All
50 are in `poses3d/`, each written by its script in `authoring3d/` (change an angle there, run it, never edit
the JSON). `bundle.py` packs them with the watch cues (`cues.json`, 72 characters at most) into
`bundle/figures.json` for the app; `vectors.py` writes golden values for the Swift port;
`review_sheet.py OUT.png id ...` draws the sheet the planner reviews from. The canvas board 13.3 shows all 50.
The flat format (`poses/`, `figure.py`) stays as the proof of concept and is not shipped.

Known soft spots, to improve when the other 200 are made:
- One dumbbell in one hand has no load of its own (suitcase carry builds it from a short bar with plates).
- A dumbbell keeps one axis for the whole rep, so a hammer curl's dumbbell does not tilt with the forearm.
- A figure lying down and turned dims the far half of the body (bench press legs); it reads as depth but
  loses contrast.
- Russian twist: the near arm partly covers the plate on the far side.
- Stills under 45 pt: the app draws the end pose only, lines 1.4 times wider (not in `figure3d.py`).
