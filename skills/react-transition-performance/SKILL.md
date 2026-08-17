---
name: react-transition-performance
description: Diagnose and fix janky view transitions and animations in a React app — a fade or slide that stutters, content that lands in one lump, a flicker as a transition ends. Use when the user says an animation is "rough", "janky", "stuttering", or "not smooth", when a screen change drops frames, or when adding a transition that a design file does not specify. Teaches profiling first (which of the four frame phases is at fault) instead of guessing.
metadata:
  version: 1.0.0
  author: ART+COM
---

# React Transition Performance

Design files usually carry **end states only**, so a transition between them is something you author
rather than a value you port. That makes it the one part of an implementation with no source of truth
to check against — and the part where jank shows up.

The risk scales with the **animated area**: a full-screen layer on a large canvas (a kiosk wall, a
4K display) can cost far more per frame than a small component on a phone-sized viewport. Guidance
that is safely ignorable on a phone becomes the difference between smooth and unusable at installation
scale.

## 1. Get one profile before theorising

A "the animation is rough" report has four candidate phases — **scripting, layout, paint,
compositing** — and they need opposite fixes. Guessing costs rounds and fixes things that were never
broken. Ask for (or take) DevTools **Rendering → Paint flashing** plus one **Performance** recording
of the interaction, then read the signature:

| What you see | Phase | Where to look |
| --- | --- | --- |
| Nothing flashing, one long task under `Event: click` | Scripting | The incoming view is being *built* inside the handler — section 2 |
| Green flashing at the end of the fade | Paint or image decode | Content painting/decoding late — section 2 |
| Long frames in Rasterize/GPU, no scripting | Compositing | Too much area, or a layer losing promotion — section 3 |

Do not skip to a fix because one seems obvious. The three signatures above look identical to the
user and are caused by unrelated code.

## 2. Do not construct the incoming view inside the interaction

Building a view of any size can exceed a frame's budget, and a whole screen reliably does. The
animation then starts with frames already spent, and the content lands in one lump instead of easing
in.

- **For a switch between two known states** (tabs, a two-way toggle): keep **both mounted** and
  animate only a class. No build, no layout, no decode in the animation path.
- **Where mounting is unavoidable:** mount invisibly, wait until it has actually painted **and its
  images are `decode()`d** — not merely `complete` — and only then start the animation. `complete`
  means the bytes arrived; the decode still happens on the first paint, which is exactly the frame
  you were trying to protect.

## 3. Disturb nothing else while animating

The transition's own state changes are the second most common cause, because they reach code that
looks unrelated to the animation:

- **Don't re-render the parent per layer.** If the transition's state lives in a parent whose render
  function rebuilds each layer, you get a second long task mid-animation. Memoise each layer on its
  key.
- **Don't move a settled layer or let it lose its promotion.** Relocating a layer to another
  container remounts it, and a compositor demotion drops it back to main-thread painting. Both read
  to the user as content *flicking into place* as the fade ends — which is usually misreported as "the
  fade is broken".
- **Keep the outgoing layer opaque underneath rather than fading it out.** Two half-transparent
  layers let the page show through both, and the whole transition visibly dips in brightness at the
  midpoint.

## 4. Prefer properties the compositor can animate alone

`transform` and `opacity` can be animated off the main thread. Animating layout properties (`width`,
`height`, `top`, `left`, `margin`) forces layout and paint every frame, which is the same cost
section 2 is trying to avoid — just spread across the whole animation instead of concentrated at its
start.

## 5. Verify with the same recording you started from

Re-record the interaction after the fix and confirm the phase you identified in section 1 is the one
that changed. A transition can feel better while the original long task is still there — you moved it
rather than removed it, and it returns on slower hardware or a larger canvas.

## Relation to other skills

Motion that a Figma file **does** specify (prototype interactions, Smart Animate, motion values) is a
translation task, not a performance one — use the Figma connector's own motion skill for that, and
this skill for how the result behaves once it runs. When implementing a design, the
[`figma-to-react`](../figma-to-react/SKILL.md) skill points here for transitions the design leaves
unspecified.
