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
