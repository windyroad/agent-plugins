---
status: proposed
rfc-id: feature-discoverability-adoption-surface-invariant
reported: 2026-07-03
human-oversight: unconfirmed
decision-makers: [Tom Howard]
problems: [P412, P297, P395, P375]
adrs: []
jtbd: [JTBD-101, JTBD-302, JTBD-003]
stories: []
---

# RFC-040: Feature discoverability / adoption-surface invariant — prevent shipping capabilities adopters can't find or activate

**Status**: proposed
**Reported**: 2026-07-03
**Problems**: P412, P297, P395, P375
**ADRs**: (none yet — will spawn ADR-091 governance-surface-activation + an ADR-060 amendment)
**JTBD**: JTBD-101, JTBD-302, JTBD-003

## Summary

We keep shipping capabilities — framework tiers, agent review axes, governance
artefacts — with **no surface that makes an adopter (or even ourselves)
discover or activate them**. The capability lands, nothing points at it,
nothing nudges, nothing fails visibly when it's skipped, and it stays
dormant/invisible. It surfaced concretely when the **bbstats** adopter used the
plugin actively for problems + ADRs + JTBD but never entered the RFC / Story /
Story-map tiers — those directories simply never got created (P412).

This is a **recurring class**, not a one-off:

- **P412** — RFC/Story/Story-map tiers invisible to adopters (missing-TIER).
- **P395** — external-comms credibility axis silently dormant when the policy
  section is absent, with no nudge to author it (missing-SECTION).
- **P297** — governance artefacts not scaffolded for adopters on other machines
  (missing-DIR); Phase 2 = guided onboarding (JTBD-302).
- **P375** — the meta-ticket: a *named re-entry point* ("run this skill when you
  remember") is **not** a self-firing cadence; uncadenced deferrals rot.

User direction (2026-07-03): build a **two-layer prevention** — proactive
(don't let future features ship invisible) **and** reactive (surface what's
already dormant, including the existing back-catalogue).

## Driving problem trace

- **P412** (primary, Open) — RFC/Story/Story-map tiers have no scaffold, nudge,
  or entry-point; the problem skeleton even emits a dangling "Create INVEST
  story" task nothing actions. This RFC's runtime layer (B) makes the tiers
  discoverable and closes P412.
- **P297** (Open) — the SessionStart-hook scaffold direction; this RFC's Layer B
  generalises that hook shape, and Layer A + the guided-onboarding framing feed
  P297 Phase 2.
- **P395** (Open) — its committed "sibling generalisation ADR for policy-file →
  governance-surface-activation nudges" IS this RFC's Layer-B ADR (ADR-091).
- **P375** (Known Error) — its Class-B "self-firing cadence" rule + the shipped
  `itil-deferral-cadence-gate.sh` are the glue Layer A composes with (a declared
  discoverability surface must terminate in a self-firing trigger).

## Scope

Two layers, both user-ratified 2026-07-03. **Different populations, and that is
what keeps the scope boundary honest** (architect Q3): Layer A fires only at
RFC/Story `accepted` — so it applies only to people *already authoring in the
tier* and cannot force adoption; Layer B's nudge is the adopter-facing lever.

### Layer A — build-time acceptance invariant (ADR-060 amendment: new I14)

New invariant **I14 "declare-discoverability-surface"**: at RFC `accepted` AND
Story `accepted`, the artefact MUST declare its adopter-facing discoverability
surface (SessionStart nudge / scaffold / list empty-state / entry-point /
autocomplete pairing), AND that surface MUST terminate in a **self-firing
trigger**. Enforced like the I10 INVEST check — mechanical section-presence +
behavioural bats, hard-block at the `accepted` transition. Adds a
`## Discoverability surface` section to the RFC + Story skeletons. Promotes
JTBD-101's agent→skill discoverability criterion (*"discoverable via `/`
autocomplete, not just accessible via hooks"*) from aspiration to enforced gate;
JTBD-302 supplies the adopter-facing half (*"every shipped skill/agent/hook has
a corresponding README mention; inventory drift is detectable, not silent"*).

- **Self-firing-trigger definition is NOT re-authored here** (architect Issue 2,
  P234 divergent-vocabulary trap): I14 MUST cite **ADR-087's self-firing-CLASS
  predicate** (hook `*.sh`, SessionStart, Pre/PostToolUse, `.github/workflows/`,
  cron, work-problems pre-flight) + the `DEFERRAL_MARKER_RE` sibling in ADR-084.
  The declared surface being self-firing is exactly the check
  `itil-deferral-cadence-gate.sh` (P375) already performs.
- **Carried by a ratified sibling ADR that amends ADR-060** (the ADR-089/ADR-090
  precedent), not a bare in-place edit — downgrades ADR-060's oversight marker
  pending re-ratify (P357 pattern) + requires compendium regen (ADR-077).

### Layer B — runtime dormancy safety-net (new ADR-091: governance-surface-activation)

Generalise the class-B SessionStart nudge predicate from `policy-file ×
missing-DIR` (ADR-047) to `governance-surface × dormant` — covering missing-DIR
(P297), missing-file (P379), missing-SECTION (P395), missing-TIER (P412). Reuse
the `risk-scorer-scaffold-nudge.sh` hook shape (read-only,
`WR_SUPPRESS_OVERSIGHT_NUDGE`-guarded). Add an itil nudge arm for the framework
tiers + empty-state pointers in `list-rfcs`/`list-stories`/`list-story-maps`
("none yet — run `/wr-itil:capture-rfc` to start").

- **ADR-091 MUST reconcile / supersede ADR-047 Phase 2's exclusion reasoning**
  (architect Issue 1 — latent decision conflict): ADR-047 Phase 2 argues
  architect/JTBD dirs "do not need a scaffold-nudge — decisions live IN the
  directory, no separate policy file points AT it." The RFC/Story/Story-map
  tiers are exactly that no-policy-file shape; ADR-091's `governance-surface ×
  dormant` predicate **overturns that exclusion** by dropping the policy-file
  precondition for dormant-surface detection. ADR-091's Decision Outcome must
  name ADR-047 Phase 2 and state this explicitly, or it is a live contradiction
  between two in-force ADRs.
- **Reconcile ADR-047's now-stale "install-updates scaffolds…" title/text** with
  the shipped SessionStart-nudge behaviour + re-confirm its oversight (P375
  human decision).

**Layer B is adopter-facing** (JTBD review): the P412 origin is an adopter
project (bbstats). Layer B is the runtime continuation of **JTBD-003** (Compose
Only the Guardrails I Need — the adopter's "which capabilities do I adopt"
axis). Neither JTBD-101 (a plugin-developer authoring-discipline job) nor
JTBD-302 (a *pull* job — adopter reads the README at their own initiative)
squarely owns the adopter *proactive-activation* flow ("surface a dormant
capability I'm entitled to, so I actually adopt it"). Before Layer B's
implementation slice (S3) lands, either broaden JTBD-302's desired outcomes to
include proactive dormancy-surfacing, or add a plugin-user proactive-activation
job (tracked as an S3 precondition below).

**Scope boundary — grounded, not asserted** (JTBD review): this is
make-discoverable / invite, NOT enforce-RFC-first-on-adopters. ADR-071 stays
windyroad-internal. The invite-not-force boundary is load-bearing because of the
**plugin-user persona constraints**: reporting/adoption is *incidental, not their
job*, friction at the surface risks abandonment, and there is *no brand loyalty*
— a nagging nudge in an adopter's own project erodes trust and gets muted.
Therefore Layer B's nudge MUST be **dismissable, low-cadence (not every
SessionStart), opt-in to activate, agent-actionable, and context-cheap** (an
agent reading a verbose nudge expands it into every session's context — JTBD-302
constraint). These persona constraints are the *reason* for invite-not-force.

## Open decisions deferred to the downstream create-adr flows

These are settled in the ADR confirmations / S3 precondition, NOT at RFC capture (architect Issues 3-5 + JTBD gaps):

- **Layer B adopter-job coverage** (JTBD gap): before S3, broaden JTBD-302 or add
  a plugin-user proactive-dormancy-activation job (+ broaden the persona "Who"
  to name the feature-adoption context). S3 precondition.
- **ADR-091 — advisory shape + host** (architect Issue 3): emit a **single
  consolidated, once-per-session** advisory (ADR-045 Pattern 5 / ADR-038
  progressive disclosure), never one line per dormant surface — SessionStart
  co-tenancy already carries ADR-040 briefing + ADR-047 scaffold-nudge + ADR-084
  census. Deliberately choose the lifecycle host — SessionStart (ADR-047 lineage)
  vs UserPromptSubmit (ADR-088 precedent) — and record why.
- **I14 — rollout mode** (architect Issue 4, Needs-Direction): **blocking-at-accepted**
  (like I10 INVEST) vs **advisory-first** (like ADR-087/ADR-057, chosen because a
  self-firing-trigger check has a high false-positive profile). Architect lean:
  advisory-first per ADR-057 staged rollout. Surface as a dedicated
  `AskUserQuestion` at the ADR-060-amendment create-adr Step 5.
- **Sequencing guard** (architect Issue 5, ADR-074): **no implementation slice
  (S3/S4/S5) commences until BOTH ADR-091 and the ADR-060 I14 amendment carry
  `human-oversight: confirmed`.** This is the P315 substance-before-build
  discipline P412's sibling class exists to enforce.

## Tasks

- [ ] **S1** — this RFC (captured) + author **ADR-091** governance-surface-activation (Layer B; P395-committed) via `/wr-architect:create-adr` — bake architect Issues 1 + 3
- [ ] **S2** — **ADR-060 amendment**: add invariant I14 "declare-discoverability-surface" (Layer A) via `/wr-architect:create-adr` amendment flow — bake architect Issues 2 + 4
- [ ] **S3** — Layer B runtime: itil SessionStart tier-dormancy nudge hook (model on `risk-scorer-scaffold-nudge.sh`) + empty-state pointers in `list-rfcs`/`list-stories`/`list-story-maps` + behavioural bats (gated on both ADRs confirmed + the Layer-B adopter-job coverage above)
- [ ] **S4** — Layer A build-time: I14 gate at `manage-story`/`manage-rfc` accepted + `## Discoverability surface` section in RFC/Story skeletons + behavioural bats (gated on both ADRs confirmed)
- [ ] **S5** — direct P412 close: verify tiers discoverable via S3 against the bbstats shape; reconcile ADR-047 stale text
- [ ] Populate/refine Scope + Tasks at `/wr-itil:manage-rfc accepted` transition

## Commits

(maintained automatically — populated by the commit-message RFC trailer hook)

## Related

(captured via /wr-itil:capture-rfc; expand at next /wr-itil:manage-rfc invocation)

- ADR-060 (Problem-RFC-Story framework) — Layer A amends this (new I14).
- ADR-047 (install-updates scaffolds governance artefacts) — Layer B generalises its class-B SessionStart nudge AND supersedes its Phase 2 no-policy-file exclusion; ADR-047 text reconciled in S5.
- ADR-084 / ADR-087 (self-firing deferral census + cadence-annotation contract) — the authoritative self-firing-CLASS predicate I14 cites (do NOT re-author — P234).
- ADR-071 (every fix through an RFC) — the windyroad-internal enforcement this RFC explicitly does NOT extend to adopters.
- ADR-057 — staged advisory-first rollout precedent for the I14 rollout-mode choice.
- JTBD-101 (Extend the Suite), JTBD-302 (Trust the README describes the plugin I installed), JTBD-003 (Compose Only the Guardrails I Need — Layer B's adopter runtime continuation).
- `packages/itil/hooks/itil-deferral-cadence-gate.sh` (P375) — the self-firing-cadence gate Layer A composes with.
- `packages/risk-scorer/hooks/risk-scorer-scaffold-nudge.sh` (ADR-047) — the Layer-B hook template.
