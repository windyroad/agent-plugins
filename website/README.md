# Documentation website

Public documentation is built from five authored guides and explicitly selected
package and skill metadata. Edit the canonical package source or the relevant
guide. Do not edit the generated `src/content/docs/plugins/` and
`src/content/docs/skills/` folders.

Use Node 24 from the repository root:

```bash
npm ci --ignore-scripts
npx playwright install --with-deps chromium webkit
npm run website:build
npm run website:test
```

`public-sources.json` is the reviewed input list. Source restrictions, synthetic
private-content fixtures and browser checks qualify the public output. A summary
that includes internal references needs a reviewed public replacement. For a
local preview, run `npm exec --workspace @windyroad/website -- astro preview`
after building. Stop that owned preview with `astro preview stop` in the same
workspace. After changing Markdown rendering options, use `astro build --force`
in the website workspace to invalidate cached content.

## Publication and verification

After successful CI for current `main`, the documentation deployment workflow
rebuilds and tests that exact commit, then publishes only its static artifact
to GitHub Pages. Stale, fork, PR and failed runs are rejected. Workflow and
source SHAs must agree. Deployment credentials stay in the artifact-only job;
the `github-pages` environment permits the `main` branch only.

Before reporting delivery, verify live reading, search, navigation and installation
guides on mobile and desktop. Record the source SHA, triggering CI run, deployment
identity and public journey results separately. Deployment success alone does not
prove the reader's journey. Browser emulation does not prove physical-device or
screen-reader behavior.

## Recovery

Revert faulty source through the governed `main` workflow. Wait for successful
CI and documentation deployment, then verify the live public journeys again.
Keep the previous known-good source SHA and deployment receipt in the delivery
record. Do not bypass qualification or publish the repository root as a website.
