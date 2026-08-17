# Changelog

## 3.0.0

- Every prototype is now private before its first production deploy. Netlify Password Protection is
  set through the API right after the site is created, and `has_password` is verified before
  deploying, so a prototype URL is never briefly public
- The shared ART+COM preview password is read from the `ARTCOM_PREVIEW_PASSWORD` team variable
  instead of being asked for. It must stay non-secret, because a Netlify secret variable cannot be
  read back, and is scoped to `functions` so it never enters a build environment
- The brief asks whether a prototype is covered by a strict client NDA; those get their own
  generated password, reported once, instead of the shared one
- Pages carry `X-Robots-Tag: noindex` headers and a `robots.txt`. Netlify only sends `noindex` on
  deploy previews, never on the production URL that actually gets shared
- Netlify site names carry the `project-slug` prefix, matching the GitLab repository name. A site
  name is a globally unique public subdomain, so unprefixed names collided and were easy to guess
- The preflight refuses to continue on a personal Netlify account: it cannot password-protect a
  prototype and has none of the shared broker variables
- Environment variables are listed by name and scope through `getEnvVars`, never with
  `netlify env:list`, which prints values

Note: Netlify's team-wide default Password Protection is an Enterprise feature, so on Pro every
site is protected individually. Prototypes created before this release are still public — set a
password on each one, or recreate them.

## 2.0.0

- Renamed to `prototyping`, replacing `ac-prototype-workflow`

## 1.0.0

- Initial release
