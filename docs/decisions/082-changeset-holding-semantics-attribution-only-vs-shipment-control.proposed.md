---
status: "proposed"
date: 2026-06-17
human-oversight: confirmed
oversight-date: 2026-06-17
decision-makers: [Tom Howard]
consulted: [wr-architect:agent, wr-jtbd:agent]
informed: [Windy Road plugin users]
problems: [P359]
---

# Changeset holding semantics — attribution-only governance vs a real shipment control

## Context and Problem Statement

ADR-042 Rule 7 blessed the `docs/changesets-holding/` convention: when residual push/release risk is above appetite, the orchestrator may `git mv .changeset/<name>.md docs/changesets-holding/` to drop the change "out of the active release queue" until evidence lands (R009 / R1 risk remediation). The framework describes holding as a **shipment control** — a way to *not ship* an above-appetite change.

P359 establishes that this description is false. Moving the changeset file withholds only **version attribution + CHANGELOG entry**. `npm publish` packages main's package directory contents verbatim, so any *sibling* changeset that drives a release ships **all committed code on main — held or not**. The held change is already on main; the only thing the hold removes is its name from the next version bump and changelog.

Evidence (2026-06-11, P220 AFK iter): P220's Step 0d fix changeset was held 2026-06-08 (scored 8/25, above the 4/Low appetite, on R009). Yet `npm pack @windyroad/itil@0.49.3` contained every fix file, because 0.48.0 / 0.49.x released sibling changesets hours after the fix commit (`0f58210c`) landed on main. Class-wide: all currently-held changesets whose code is committed on main have already shipped to adopters; the risk-mitigation intent of the hold (don't ship above-appetite changes) is not achieved.

Root cause: the user's ADR-042 direction (2026-04-22) was *"it can move the changes or feature-flag them or roll them back"* — **move the changes** (the code). The implementation moved **the changeset** (attribution). The two diverge precisely when a sibling release fires.

Secondary symptom (P228 sibling): the problem-ticket lifecycle keys "release" to changeset graduation, so Known-Error → Verifying deferrals ("until next release") read as pending when the fix is de-facto released. P220 sat misclassified for 3 days.

The user has ratified the current *state* (2026-06-11): *"don't revert what's already shipped but going forward if we need to hold then we need a mechanism that's gonna work."* This ADR records the going-forward decision so a human can direct it; it does **not** unwind anything already shipped.

## Decision Drivers

- **JTBD-002 (Ship AI-Assisted Code with Confidence)** — "agent cannot bypass governance"; a hold that does not actually withhold is a governance-integrity gap. Whatever option is chosen must make the framework's self-description match reality.
- **JTBD-006 (Progress the Backlog While I'm Away)** — the AFK release-cadence path (ADR-018 / ADR-042 Rule 1) currently uses holding as a within-appetite remediation that does not work; the chosen option must restore a real above-appetite remediation the AFK loop can rely on.
- **Never-release-above-appetite invariant (ADR-042 Rule 1)** — the load-bearing invariant holding was meant to serve. If holding is not a shipment control, the invariant has been silently unenforced for above-appetite changes whose code is already committed.
- **Reversibility / cost** — option (a) is documentation-only (cheap, no behaviour change); option (b) changes the commit/release mechanics (higher cost, real control); option (c) is a lifecycle-semantics reconciliation orthogonal to (a)/(b).
- **Adopter portability** — any mechanism shipped in `@windyroad/*` skills must resolve in adopter installs, not just the source monorepo (ADR-049 PATH shims).

## Considered Options

1. **(a) Attribution-only governance + prose correction.** Accept that holding is attribution-only by design. Amend ADR-042 (and the risk-scorer remediation prose, holding-area README, and any SKILL prose) to stop describing holding as a shipment control and instead describe it as a CHANGELOG/version-attribution deferral. Pair with the release-often + within-appetite-drain discipline as the actual above-appetite mitigation. **Lowest cost; does not give the user the "mechanism that's gonna work" they asked for** for genuinely withholding above-appetite code.
2. **(b) Real shipment control.** Make holding (or a new mechanism) actually withhold the code: hold the CODE off main (feature branch / revert-on-main-until-evidence), or gate `npm publish` to exclude held slices. **Gives a working shipment control; higher cost and higher mechanism risk; needs adopter-portable design.** This is the direction the user's "a mechanism that's gonna work" points at.
3. **(c) Reconcile K→V "release" lifecycle semantics.** Independently of (a)/(b), fix the secondary symptom: stop keying problem-ticket "release" to changeset graduation when code is de-facto shipped on main (P228 sibling). May ship alongside (a) or (b), or as its own change.

Options (a)/(b) are mutually exclusive on the *primary* question (is holding a shipment control or not). Option (c) is orthogonal and likely needed regardless.

## Decision Outcome

Chosen option: **"(b) Real shipment control + (c) Reconcile K→V release lifecycle — riding together in a single RFC-first fix path"**, confirmed by the user via `AskUserQuestion` 2026-06-17 (`/wr-architect:review-decisions` drain across two ratification calls: primary a/b, then orthogonal c), because the user's 2026-06-11 direction "if we need to hold then we need a mechanism that's gonna work" rejects option (a)'s attribution-only acceptance of the governance-integrity gap, and the K→V lifecycle reconciliation rides in the same RFC because the misclassification symptom (P220 misclassified 3 days) shares the same shipment-vs-attribution root cause.

Option (a) — attribution-only governance + prose correction — is **rejected** as the going-forward shape: it would accept the governance-integrity gap (the false "holding is a shipment control" self-description) rather than close it. JTBD-002's *"agent cannot bypass governance"* outcome is non-negotiable; a hold that does not withhold IS the governance-bypass JTBD-002 names. The interim discipline (release-often + within-appetite-drain) remains in force until (b) ships.

For (b), the going-forward mechanism for "changeset holding" must actually withhold code from shipping — not merely defer version attribution and CHANGELOG entry. The implementation shape (hold code off main on a feature branch, revert-on-main-until-evidence, gate `npm publish` to exclude held slices, or a different mechanism) is the next RFC's design space; this ADR records only that the framework's self-description must match reality and that "a mechanism that's gonna work" — per the user's 2026-06-11 prose direction — is the required shape. Adopter portability via ADR-049 PATH shims is a load-bearing constraint on whatever mechanism the RFC builds.

For (c), problem-ticket lifecycle must stop keying "release" to changeset graduation when code is de-facto shipped on main; the witnessing case (P220 misclassified for 3 days) is in scope. P228 is the sibling problem ticket this rolls up.

Next step: an RFC-first fix path (per ADR-060) tracing this ADR, P359 (driving), and P228 (sibling). No dependent work outside that RFC is built ahead of it (ADR-074 build-upon gate).

## Consequences

### Good

- The going-forward decision is recorded in `docs/decisions/` where the ADR-066 oversight detector (and the `/wr-architect:review-decisions` drain) can surface it — closing the P310 RFC-decision-invisibility hole that ADR-070 exists to prevent.
- Option (b) makes the framework's holding self-description match reality: the developer persona's *"plugins must carry the guardrails regardless"* constraint becomes load-bearing rather than advisory — an above-appetite hold actually withholds the code, so the never-release-above-appetite invariant (ADR-042 Rule 1) is enforced in mechanism, not in prose.
- Option (c) closes the secondary problem-ticket-misclassification symptom in the same RFC, so AFK iterations don't continue to accumulate Known-Error → Verifying entries that read as pending when the code is de-facto shipped.

### Neutral

- Until the follow-up RFC builds (b), the framework prose (ADR-042 Rule 7, risk-scorer remediation descriptions, holding-area README) still describes holding as a shipment control. Agents reading the existing prose may continue to "hold to remediate above-appetite risk" expecting it to withhold code; the de-facto mitigation in the interim is the release-often + within-appetite-drain discipline. The P359 ticket workaround documents this. The prose correction is dependent work that rides with the RFC (it is NOT a separate prose-only change — option (a) is rejected).

### Bad

- The above-appetite never-release invariant has been silently unenforced for held changesets whose code is on main. The remediation lands when the RFC ships, not at this ratification. Mitigation: the user has ratified the current state and the interim discipline; this is a recorded known error (P359 → Known Error), not a hidden one.
- Option (b) is higher-cost than (a) and carries mechanism risk; the follow-up RFC must satisfy adopter portability (ADR-049 PATH shims) or the mechanism will not resolve in adopter installs. Mitigation: RFC-first design path (per ADR-060) surfaces the design constraints before mechanism work begins.

## Confirmation

Compliance is verified by:

1. ~~A human ratifies one of options (a)/(b)/(c)~~ — **satisfied 2026-06-17**: ratified options (b) + (c) via `/wr-architect:review-decisions`, recorded in Decision Outcome; `human-oversight: confirmed`.
2. The dependent work — the real shipment-control mechanism (b) and the K→V lifecycle reconciliation (c) — is proposed via an ADR-060 RFC-first fix path tracing this ADR, P359 (driving), and P228 (sibling). The RFC carries the ADR-042 Rule 7 prose correction and any risk-scorer remediation prose updates as part of its scope.
3. After the RFC ships and the mechanism is validated in production, this ADR's `status:` may be promoted from `proposed` to `accepted` (the oversight marker is orthogonal to status per ADR-066; status flip is gated on dependent-work landing per ADR-074).

## Reassessment Triggers

Revisit if:

- The `npm publish` packaging model changes such that uncommitted-but-not-in-changeset code no longer ships (would make holding a de-facto shipment control without further work).
- ADR-042 is superseded — Rule 7 holding convention's basis moves.
- P228 (K→V "release" semantics) is resolved independently — option (c) may drop out of scope.

## Related

- **P359** (`docs/problems/known-error/359-changeset-holding-does-not-withhold-shipment-held-code-ships-with-sibling-release.md`) — driving problem ticket; root-cause finding.
- **ADR-042** (`docs/decisions/042-auto-apply-scorer-remediations-open-vocabulary.proposed.md`) — Rule 7 holding convention; the prose this ADR's option (a) would correct. NOT edited until an option is ratified.
- **ADR-070** (`docs/decisions/070-rfcs-hold-no-independent-decisions.proposed.md`) — why this decision is homed in an ADR, not an RFC body.
- **ADR-066** — human-oversight marker; Amendment 2026-06-02 (P348) AFK `unconfirmed` path this ADR follows.
- **ADR-074** — confirm substance before building dependent work; the born-proposed-no-build contract this iteration honoured.
- **P220** — witnessing case: de-facto-released held changeset (`@windyroad/itil@0.49.3`).
- **P228** — K→V enumerator keys on deleted-from-tree changesets; same blind spot as the secondary symptom (option (c)).
- **R009** — SKILL-prose floor standing risk; the risk that drove P220's hold.
