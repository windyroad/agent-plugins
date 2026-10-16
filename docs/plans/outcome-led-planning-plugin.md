# Independent outcome-led planning plugin

## Confirmed objective

By the end of Sunday 18 October 2026, Australia/Sydney, publish outcome-led
planning as its own installable Claude Code and Codex plugin, update public
documentation, and verify fresh installation, discovery and core planning
behaviour in both runtimes. Keep the existing personal `$outcome-led-planning`
skill usable throughout. The user confirmed this complete playback.

Completion requires registry publication, fresh runtime evidence and deployed
documentation. Source, packed artifacts and CI establish their own stages only.

## Current plan: revision 10

Keep the confirmed objective unchanged. Publish the independently installable
package before activating website guidance that recommends its npm command.
Architecture, JTBD recommendation and pre-edit reviews passed this exact split;
plan and projected release residual risk passed at 5/25, within appetite 5.
These assessments do not replace concrete provider, commit, push or release reviews.

The user subsequently requested an "Improvise, overcome, adapt" mentality.
Revision 6 clarifies the existing requirement to exhaust useful authorized work:
diagnose recoverable failures, use available equivalents, repair within scope,
and continue independent work without handing routine choices back to the user.
Preserve the confirmed result, evidence, constraints, authority and reviews;
retain precise handoff for genuine gaps and ambiguous remote effects. This is
an explicitly requested behavioral clarification, not a different delivery goal.
Architecture and JTBD recommendation/pre-edit reviews passed. Plan risk passed
at 4/25 and projected release risk at 5/25.

The local skill was updated first by atomic replacement, preserving identity,
mode and picker metadata; its current body equals the canonical skill at
SHA-256 `b2cc720581088027037b30389d18dee693ca1f5733042c93718464ff339d0a4e`.
A recoverable pre-change snapshot is retained. The ITIL compatibility body and
Codex projection carry the same clarification. All prior model scenarios remain,
with two new paired scenarios for recoverable tool failure and genuine authority
gaps. All 26 scenarios passed with zero failures or errors. Both actual native CLI
checks executed Python verification after finding the preferred helper absent,
matched totals of 15 and 7 against the independent reference, and completed
without asking the user to resolve the missing tool. Claude also recovered
from an unnecessarily prefixed command denied by its tool permissions, using
a fixture-local permitted invocation. No files were changed or software installed;
temporary authentication references and fixture homes were removed. These
prove the bounded fallback behavior, not registry publication. The held
website activation patch now also explains this behavior, without activating it.

## Verified increment: publisher readiness

The package foundation is qualified on draft PR 529 at
`102238e5d1c3597ca6785501b5b1684d04122f2b`. Exact-head CI 38818202574 passed
all three required jobs. Main remains green and unchanged at the baseline.
The existing website guidance remains operational; its seven-file activation
patch is preserved separately until stable registry availability is verified.

Authentication succeeded using the 1Password desktop app, including its
one-time code, through npm's normal web flow. The authenticated identity has
verified owner authority for the intended npm organization. No 1Password CLI,
publish token in CI or credential change was introduced.

A fresh concrete staging assessment passed at 4/25. The exact qualified
11-file planning 0.0.0 tarball was submitted once with tag `bootstrap`; stage
`0473c71c-cb32-48d2-a2d7-c3f906c5aa2c` is now `staged`. Its package, version,
actor, tag and SHA-1 match the qualified archive; the submission response also
matches its SHA-512 integrity. The archive's SHA-256 is
`2d9239fd444a27e24c78bd89ac621595be58ce8211d5de81744efb01251c95c7`.
Do not approve this bootstrap payload.

Corrected assumption: staging a new package creates a **public 0.0.0-stage
placeholder**, while the qualified 0.0.0 payload remains unpublished pending
approval. [npm documents this distinction](https://docs.npmjs.com/staged-publishing/).
Public registry readback confirms only 0.0.0-stage is available; this does not
establish installation or publication of the skill. The downloaded remote staged
archive matches the qualified SHA-256 byte-for-byte.

A concrete provider assessment passed at 5/25 before one trusted-publisher
creation. Owner-authenticated independent readback confirms exactly one GitHub
publisher, ID `06d074e5-a99f-4b6b-a875-ec2b443c5c0c`, bound to
`windyroad/agent-plugins` and `release.yml`, with no environment restriction.
Permissions are direct publishing and staging; no dist-tag permission is granted.

Corrected assumption: [npm requires staging permission on every newly created
trusted publisher](https://docs.npmjs.com/trusted-publishers/). It cannot be
removed. Direct publishing is separately enabled for the existing release
workflow. This is the provider's minimum supported configuration for that path;
no revoke/recreate attempt is warranted. OIDC cannot approve staged payloads.
Revision 9 architecture, JTBD and plan/projected release reviews passed this
correction within appetite at 5/25. Configuration establishes readiness for the
normal OIDC attempt; it does not prove successful publication.

## Now: publish and qualify the standalone plugin

Revision 10 architecture, JTBD recommendation/pre-edit and plan/projected release
reviews passed this increment within appetite at 5/25. The prior readiness hold
is satisfied. No executable package source changed after exact-head qualification.

- Record the provider evidence and this revised plan through fresh concrete
  commit/push review, then require revised-head branch CI.
- Reconcile with fresh green main and obtain concrete integration/release review
  before making PR 529 ready and merging its package foundation.
- Watch the exact main CI and existing OIDC release workflow. Preview publication
  and the automated version PR are intermediate stages.
- Inspect the actual version PR, generated versions/manifests and release scope;
  merge only after its checks and concrete release review pass. Use the existing
  normal OIDC workflow for stable publication.
- Verify exact stable registry availability and provenance, fresh installation,
  discovery and core behavior in both native runtimes, including coexistence
  with the personal skill. Preserve its body and picker metadata.
- Inspect exact state before retrying any ambiguous external action. Exhaust
  useful authorized alternatives when a prerequisite fails.

This coherent increment delivers an independently usable published plugin.
Its means remain negotiable, dependencies and uncertainty are explicit, and
registry/runtime evidence makes completion testable. A story or invented
estimate is unnecessary. Public website activation remains a separate increment.

Do not approve the bootstrap payload, substitute a manual public plugin release,
add a reusable CI token, create another publishing workflow or weaken security
controls. Package source, green CI and configured trust establish their own
stages; the published-plugin increment remains unfinished until qualified.

## Next (provisional)

After stable registry/runtime qualification, restore the preserved website
changes through fresh plan and source reviews, checks and governed integration.
Verify deployed old/new URLs and advertised installation commands against the
stable package. Reject the unused bootstrap stage only after successful normal
publication and exact owner/state verification, through concrete provider review.

## Later (provisional)

No additional capability is required. Compatibility retirement needs separate
justification; preserving existing invocations is the default for this move.

## Assessment history

Revision 1 failed risk review because a written release hold would not prevent
main-only publication attempts. Revision 2 confined delivery to a branch and
draft PR. Revision 3 clarified two behavior failures, updating the local skill
first, and passed architecture, JTBD and risk review at 4/25. Revision 4's
conditional unpublished bootstrap and restricted publisher setup passed all
three reviews at 5/25. Revision 5 made the reviewed
package-before-docs ordering concrete without flags or history rewriting.
Revision 6 added the explicitly requested persistence clarification and passed
all 26 model scenarios and native fallback checks. Revision 7 reassessed the
publisher-readiness increment after foundation qualification. Revision 8 corrects
the public-placeholder assumption and records actual authentication and staging;
architecture, JTBD recommendation/pre-edit and plan/projected release risk
reviews passed, with the latter within appetite at 5/25. Revision 9 records
verified publisher readiness and replaces the unsupported direct-only permission
assumption with npm's mandatory staging baseline. Revision 10 makes normal OIDC
publication and fresh registry/runtime qualification Now; all three substantive
reviews passed at 5/25 before dependent execution. Website activation remains
Next, conditional on stable package qualification.

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
Its interview/horizon clarification-stage file equaled the canonical skill at SHA-256
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
as described below. Exact-head CI now passes for the package foundation and persistence clarification.
Main remains unchanged and green. Publication, fresh
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
confirmed outcome, skill body, lint or shared toolchain. Revised-head CI passed before dependent provider actions.
