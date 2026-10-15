# Problem 558: No public searchable documentation site for plugin users

**Status**: Closed (closed-on-evidence 2026-10-16 - deployed source 29f566b6, successful Pages workflow 38750360372 and live public reading/search/mobile/desktop journeys; see Verification. Recovery: rerun `/wr-itil:transition-problem 558 known-error` to reopen)
**Reported**: 2026-10-15
**Priority**: 8 (Medium) - Impact 2 × Likelihood 4. Readers must navigate repository Markdown or local paths to find plugin and skill guidance on phones; broader demand has not been measured.
**Origin**: internal
**Effort**: M - reuse static documentation tooling, qualify content and deploy through repository automation.
**WSJF**: 0 - Closed multiplier 0
**JTBD**: JTBD-003, JTBD-007
**Persona**: developer

## Description

A developer choosing and using Windy Road Agent Plugins has no public docs site
with search, mobile reading and shareable plugin and skill pages. A local skill
path cannot be opened from an iPhone, and GitHub Markdown does not supply the
requested documentation journey. This is missing functionality, with no observed
interruption of an established docs service.

The user confirmed a public site comparable to Em See Pea's navigation, search
and mobile reading, covering plugin and skill discovery and accurate Claude
Code/Codex installation guidance, maintained from this repository. Deadline:
end of Sunday 18 October 2026, Australia/Sydney.

## Workaround

Read the public package README and skill sources on GitHub. These links are
shareable but do not provide the requested searchable documentation website.

## Root Cause Analysis

Documentation was distributed across package sources without a public static
site, a controlled content build or a deployment/verification workflow.

## Investigation Tasks

- [x] Confirm the requested objective and deadline with the user.
- [x] Inspect the reference site architecture and current repository boundaries.
- [x] Review the plan against architecture, jobs and risk policy.
- [x] Build a private website workspace outside plugin package directories.
- [x] Qualify selected public content, search, runtime guidance and accessibility locally; exact trunk CI and live acceptance remain separate gates.
- [x] Deploy the qualified artifact and verify live mobile and desktop journeys.

## Fix Released

<!-- no-changeset-reference: private website deployment, not an npm package release -->

Source `29f566b63b74496fb68bfc3dca5a24e9e2d56c62` passed
[CI 38748545880](https://github.com/windyroad/agent-plugins/actions/runs/38748545880)
and was published by
[Pages workflow 38750360372](https://github.com/windyroad/agent-plugins/actions/runs/38750360372).
Environment deployment `7095198494` reports success for that exact SHA at
<https://windyroad.github.io/agent-plugins/>. The site supplies selected public
plugin/skill references, runtime guides, navigation and browser search.

Verification is evaluated against the observed public journeys below. No user
confirmation or npm package release is inferred from the deployment.

## Verification

- Initial provider prereads returned 404 for Pages and its environment. The live
  site now returns HTTP 200 for all 80 documentation routes, including nested
  plugin/skill and installation pages. This exercises the original absent-site gap.
- The publication workflow passed 23 unit/artifact/configuration/guard tests and
  four browser tests before uploading only its static output. The actual guard
  CLI covers 14 successful/rejected source-identity scenarios. The root Node 20
  suite passed 4,396 tests; exact source CI and Release both succeeded.
- Live Chromium checks covered 320, 390 and 1280 pixels in both themes. Live
  WebKit iPhone 13 emulation covered both themes. Reading, wrapped commands,
  navigation, keyboard search, positive/no-result status, canary exclusion,
  focus return, deep links and installation-guide copy payloads passed. Reading
  and native mobile navigation also passed with JavaScript disabled.
- Independent live review repeated the key phone journeys in Chromium and WebKit.
  Root inspected live screenshots. Physical devices, spoken screen-reader output
  and operating-system clipboard writes were not tested.
- The fetched live home page SHA-256 is
  `6f0141297ebcf025017bb56d22943c4a947e3b34165b0b46fdcb1db8d08f54a7`, matching
  the actual CI artifact receipt. The local build differs, so it is not used as
  deployed-byte identity proof. Independent review of the downloaded deployment
  tar read all 188 files, including 81 HTML pages and 85 decompressed search
  assets, and passed disclosure, maturity, helper-link and route checks.
- Provider readback confirms workflow-based Pages, enforced HTTPS and exactly
  one environment policy permitting the main branch. Actual run logs show the
  build's read-only repository token and the artifact-only deployment job's
  reviewed permissions. Repository updates pass CI and rebuild the qualified
  artifact; maintenance and source-revert recovery are documented in website/README.md.

## Transition preflight

Root cause, initial 404 reproduction, workaround and all investigation tasks are
documented. Effort remains M; the folded Known Error WSJF would be 8 with the
2.0 multiplier. The deployed fix and its exact source/CI marker satisfy the
folded Open to Verification Pending checks. No conditional work remains deferred.

## Close criteria

The public deployed site supports reading, plugin/skill discovery, shareable deep
links, search and runtime-specific installation guidance. Verify key journeys on
mobile and desktop, source-to-site maintenance and deployment controls. Build,
CI, deployment and live journey evidence are distinct. Do not close on a local
preview or a published workflow alone.

## Dependencies

- **Blocked by**: none; the public delivery and verification criteria are satisfied.
- **Composes with**: existing plugin installation and documentation sources.

## Related

Fresh hang-off review returned PROCEED_NEW. P152 addresses documentation-currency
nudges, P493 docs-only CI cost and P524 disclosure in ticket history; none covers
creating the requested public documentation website. The public build must not
expose that history or other internal planning sources.

## RFCs

- RFC-107: Find plugin documentation from any device, on STORY-MAP-008.


## Stories

| ID | Title | Status |
|----|-------|--------|
| STORY-107 | STORY-107: Find the plugin and instructions I need on my phone | done |

## History

- 2026-10-15 - Captured the confirmed public docs objective and reviewed its
  existing-map delivery vehicle before implementation.
- 2026-10-16 - Integrated the qualified foundation, then the separately reviewed
  hosting workflow; each passed its exact trunk pipeline before dependent effects.
- 2026-10-16 - Executed the ordered batch `558 verifying 558 close`: populated
  the shipped release and composed preflight, moved Open to Verification Pending
  and re-staged, then rediscovered it, observed close-block exit 1 and the cited
  live evidence, and moved Verification Pending to Closed with explicit re-stage.
  Both operations succeeded; no intermediate Git commit or user confirmation is claimed.
