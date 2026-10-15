# Independent outcome-led planning plugin

## Confirmed objective

By the end of Sunday 18 October 2026, Australia/Sydney, publish outcome-led
planning as its own installable Claude Code and Codex plugin, update public
documentation, and verify fresh installation, discovery and core planning
behaviour in both runtimes. Keep the existing personal `$outcome-led-planning`
skill usable throughout. The user confirmed this complete playback.

Completion requires registry publication, fresh runtime evidence and deployed
documentation. Source, packed artifacts and CI establish their own stages only.

## Current plan: revision 5

Keep the confirmed objective unchanged. Publish the independently installable
package before activating website guidance that recommends its npm command.
Architecture, JTBD recommendation and pre-edit reviews passed this exact split;
plan and projected release residual risk passed at 5/25, within appetite 5.
These assessments do not replace concrete provider, commit, push or release reviews.

## Now: qualify the package foundation

Deliver the complete tested package and compatibility foundation through draft
PR 529 on `codex/planning-plugin`, with exact-head PR CI. ADR-002, ADR-017 and
ADR-083's independently installable package model applies; no new ADR is needed.

- Retain skill-only `@windyroad/planning`, plugin `wr-planning`, shared installer,
  marketplace and meta-installer selection. No automatic dependencies, hooks or
  reviewer agents are bundled.
- Own the canonical workflow in planning. Keep the complete ITIL command as an
  independently usable generated compatibility entrypoint, checked for drift.
- Preserve the personal `$outcome-led-planning` skill and its picker metadata.
- Restore the seven website files to current green main. The existing ITIL guide
  remains valid. Package README body prose is not copied into generated pages;
  the old website allowlist does not include planning.
- Preserve the qualified website changes in the original implementation commit
  and a checked seven-file patch under ignored audit storage. Verify the patch
  applies to the restored baseline; activate it only after stable publication.
- Rebuild and test the retained website journeys, reconfirm packed installation
  and compatibility, obtain fresh concrete commit/push reviews, then qualify the
  exact new PR head in CI. Revise the PR around the package foundation and its
  explicit remaining delivery hold.

This is a coherent independently reviewable foundation increment, valuable for
selective installation and compatibility. Its bounded scope is estimable with
uncertainty disclosed and testable; means remain negotiable. No manufactured
numerical estimate or extra story is needed to satisfy INVEST.

**Release hold:** npm CLI and browser are signed out. Do not integrate the new
package into main, merge a release PR or publish before first-package bootstrap
and the existing `release.yml` trusted publisher are established. Main's stable
and preview paths would otherwise attempt unauthorized publication. Do not add
a token, second workflow or speculative flag.

## Next (provisional)

After exact-head CI passes, complete owner npm web sign-in and verify identity
and organization authority. Under separate fresh concrete provider reviews,
stage only the exact qualified planning 0.0.0 tarball with a bootstrap tag;
verify stage identity and integrity. Do not approve or publicly publish that
bootstrap version. Configure and read back only the existing
`windyroad/agent-plugins` / `release.yml` direct-publish trust, with owner 2FA.
Staging is documented to create a nonpublic package, but whether that package
can receive trust configuration remains unproven. If it cannot, investigate;
do not substitute manual public publication or a second workflow.

Only once publisher readiness is established, integrate the package foundation
into fresh green trunk using concrete reviews and the existing OIDC release
workflow. Verify stable registry availability, fresh installation, discovery
and core behavior in both runtimes, including coexistence with the personal
skill. Then restore the preserved website changes through fresh source reviews,
checks and governed integration, and verify deployed old/new URLs. Reject the
unused bootstrap stage only after successful normal publication and exact
owner/state verification. Replan from the actual evidence at each checkpoint.

## Later (provisional)

No additional capability is required. Compatibility retirement needs separate
justification; preserving existing invocations is the default for this move.

## Assessment history

Revision 1 failed risk review because a written release hold would not prevent
main-only publication attempts. Revision 2 confined delivery to a branch and
draft PR. Revision 3 clarified two behavior failures, updating the local skill
first, and passed architecture, JTBD and risk review at 4/25. Revision 4's
conditional unpublished bootstrap and restricted publisher setup passed all
three reviews at 5/25 but remains unexecuted. Revision 5 makes the reviewed
package-before-docs ordering concrete without flags or history rewriting.

JTBD alignment: JTBD-003 (select only needed guardrails), JTBD-005 (invoke
assessments), JTBD-007 (keep plugins current), JTBD-101 (extend the suite without
breaking existing plugins). No new persona, job or story is required solely by
this extraction.

## Local continuity baseline

Initial personal-file baseline, retained for provenance:

- `SKILL.md`: SHA-256 `bd6bfc374ad94a77529b1bee36fee6189df38e89118f382c59ea8876f9129fa4`.
- `agents/openai.yaml`: SHA-256 `766a2ed79d04f2768790ed364591db97727f793e9a90b1b4358d66a3afe86799`.

## Evidence and remaining work

The package and docs are implemented on the isolated branch. Twenty-five focused
package/harness/manifest/shared-copy checks, six ITIL pack/install checks, 23
website unit checks and four browser checks passed. Browser coverage includes
the new planning pages and retained ITIL route, mobile and desktop, both themes,
keyboard search and WebKit phone layout. Initial native artifact checks discover
the command in both runtimes and demonstrate interview, playback and reuse of a
confirmed objective. They do not establish fresh registry delivery or reviewer
dispatch.

Final qualification: all 22 model scenarios passed, with zero errors. The two
earlier campaigns remain retained: 20/22 before contract clarification, then
21/22 before correcting an underspecified three-turn fixture. Architecture and
JTBD verified that providing CSV-to-JSON scope, exact comparison and available
schemas removes unintended ambiguity while preserving the three-turn sequence
and unchanged acceptance rubric. The separate unknown-format and vague-outcome
scenarios remain. Actual native post-clarification interview invocations in both
runtimes request one missing fact and wait. Final website build and all 23 unit
plus four browser checks passed, including the expanded planning routes.

The personal skill was updated first atomically, with a recoverable snapshot.
Its final file equals the canonical skill at SHA-256
`20c5f6f35fa707ba542dfaa4b38a21ca7462619cb8d564dee3256b9f0997a43f`;
its picker metadata retains its baseline hash. No installation or removal gap
was introduced. Temporary native authentication references and runtime homes
were removed. The native checks establish artifact loading and response
behaviour, not registry publication, reviewer dispatch or existing-chat reload.

Changesets derives planning 0.1.0, ITIL 3.1.1 and meta-installer 0.3.0 for the
eventual release. These are planned versions, not publication receipts.

Native coexistence checks also installed the extracted plugin alongside a copy
of the personal skill: both bare and qualified invocations loaded their own
expected source and waited for objective confirmation. This proves coexistence
in an isolated runtime home, not installation of the new plugin in the user's
current desktop session.

The initial PR CI passed model and website jobs but failed the metadata lint
as described below. The repaired head's CI is running; the new split requires
its own exact-head CI. Main remains unchanged and green. Publication, fresh
registry runtime qualification and live standalone documentation remain pending.

## CI metadata compatibility repair

The initial PR head passed model evaluation and website CI, but the maturity
doc lint rejected the new skill's incomplete rich record. The existing
population tool generated the planning record from current transcript and git
measurement streams in an isolated workspace; only its maturity subtree was
copied back. Planning has zero measured age and closed tickets, no breaking
marker, and the measurement tool's zero-invocation fallback. That fallback does
not contradict the separately captured native runtime invocations. The full
suite evidence determines that bootstrapping is inactive.

This retains compatibility with the shipped F2 population/render/lint tooling.
ADR-063's later F1 simplification remains an incomplete migration tracked by
Problem 300; this repair does not implement F1 or close that problem. Architecture
and JTBD approved this bounded generated-metadata repair without changing the
confirmed outcome, skill body, lint or shared toolchain. Revised-head CI must
pass before dependent provider actions.
