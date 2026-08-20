# Changelog

## 1.0.1

- Point the Figma pixel-fidelity contract at `figma-measure` for escalation: `figma-to-react` §7
  remains the authoritative checklist, but the measurement techniques for an element that still
  reads as off now live in that companion skill.

## 1.0.0

- Initial release
- Guards two failure modes when working with skills: (1) picking a generic/plugin skill when a
  more specific project or org/custom skill applies, and (2) invoking a skill but skipping its
  mandatory steps because the result "already renders"
- Section 1: rank matching skills (project-scoped > user/org custom > bundled plugin) and pick
  deliberately; concrete rule that `figma-to-react` beats the bundled `figma:figma-design-to-code`
- Section 2: the chosen skill's "required/do not skip" steps are contractual — structure decision,
  companion-skill offer, content/asset externalization, real verification (not just a build),
  anti-hallucination; pixel-fidelity detail is delegated to `figma-to-react` §7 rather than duplicated
- Section 3: self-check before finishing
