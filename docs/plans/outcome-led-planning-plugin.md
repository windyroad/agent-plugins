# Independent outcome-led planning plugin

## Confirmed objective

By the end of Sunday 18 October 2026, Australia/Sydney, publish outcome-led
planning as its own installable Claude Code and Codex plugin, update public
documentation, and verify fresh installation, discovery and core planning
behaviour in both runtimes. Keep the existing personal `$outcome-led-planning`
skill usable throughout. The user confirmed this complete playback.

Completion requires registry publication, fresh runtime evidence and deployed
documentation. Source, packed artifacts and CI establish their own stages only.

## Current plan: revision 3

Revision 2 package, installer and website checks passed, but the full model
qualification returned 20/22. One response bundled beneficiary and deficiency
into one purported question; another invented future features and queried an
ambiguous relative Friday. Revision 3 clarifies the existing single-fact
interview and evidence-led horizon rules, and pins that confirmed-date fixture
without weakening its rubric. It does not add a capability or change the goal.

Architecture and JTBD passed the revised plan and expanded source scope. Plan
and projected release risk passed at 4/25. Update the personal skill first by
atomic replacement, retaining a recoverable copy, bare name, permissions and
picker metadata; then apply the equivalent canonical and compatibility bodies.
Rerun all 22 behavioral cases and native vague-outcome scenarios before claiming
the repair verified. All branch-only and publication constraints below remain.

## Now: branch implementation and qualification

Deliver a complete, tested implementation on `codex/planning-plugin` and a draft
PR with PR CI. The existing independently installable package model applies
(ADR-002, ADR-017, ADR-083). No new architectural decision is needed.

- Add skill-only `@windyroad/planning`, plugin `wr-planning`, using the shared
  installer with no automatic plugin dependencies, hooks or agents.
- Own the generic skill body in the planning package. Generate the
  existing full-body ITIL skill from it, preserving its command and independent
  operation, with a checked synchronization boundary.
- Update marketplace selection, package inventories and public installation and
  runtime guidance. Preserve the public guide and old ITIL skill URL.
- Preserve the personal skill's identity, availability, permissions and picker
  metadata during the local-first clarification. Compare bodies and record the
  authorized content change separately from packaging continuity checks.
- Verify extracted tarballs, isolated installer boundaries, correct Codex skill
  names, absence of ITIL runtime assets, compatibility drift, existing behavioral
  scenarios, and built-site navigation/search/accessibility checks.

This is one coherent, independently reviewable migration increment. Its means
remain negotiable, its user value is selective installation, and its bounded
package/compatibility/docs surface is testable. No numerical estimate or extra
story is manufactured to satisfy INVEST.

**Release hold:** npm CLI and browser are signed out. Do not merge or push the
new public package to main, merge a release PR or publish until first-package
bootstrap and the existing `release.yml` trusted publisher are established.
Both stable and preview paths would otherwise attempt unauthorized publication.
Do not add a token, second workflow or speculative flag to bypass this boundary.

## Next (provisional)

Once the complete artifact is reviewable, resolve the precise owner-only npm
action. Obtain fresh concrete risk reviews, integrate the safe slice into green
trunk, and use the existing release workflow. Qualify fresh registry installs
and native planning behaviour in both runtimes outside this repository, then
verify the deployed public docs and retained URLs. Replan from that evidence.

## Later (provisional)

No additional capability is required. Retire compatibility only if separately
justified; preserving existing invocations is the default for this move.

## Assessment

Revision 1 was rejected by risk review because a written release hold would not
prevent the main-only workflow from attempting publication. Revision 2 confines
Now to a branch and draft PR. Architecture and JTBD passed revision 2 and the
concrete source scope. Plan and projected release residual risk passed at 4/25,
within appetite 5. These assessments do not replace commit, push or publication
reviews. Artifact, runtime and website controls above remain forecast until run.

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

Main is unchanged and its existing CI, Release and documentation deployment are
green at the baseline. PR CI, publication, fresh registry runtime qualification
and live documentation evidence remain pending.

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
