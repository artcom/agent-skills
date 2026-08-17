# Changelog

## 1.0.0

- Initial release, extracted from `figma-to-react` 1.6.0's "Motion the design does not specify"
  section — that content was browser performance debugging rather than Figma-to-code translation,
  and every `figma-to-react` run paid for it whether or not any animation was involved
- Profile-first diagnosis: a signature table mapping what DevTools shows (paint flashing, a long task
  under `Event: click`, long Rasterize/GPU frames) to which of the four frame phases is at fault
- Rules for not building the incoming view inside the interaction (keep both states mounted for a
  two-way switch; otherwise mount invisibly and wait for paint plus image `decode()`)
- Rules for not disturbing settled layers (memoise per key, avoid remounts and compositor demotion,
  keep the outgoing layer opaque instead of cross-fading)
- Added beyond the extracted content: prefer `transform`/`opacity` over layout properties, and
  re-record the profile to confirm the identified phase is the one that improved
