---
status: proposed
rfc-id: authoring-time-deferral-cadence-gate
reported: 2026-06-28
human-oversight: unconfirmed
decision-makers: [Tom Howard]
problems: [P375]
adrs: [ADR-087]
jtbd: [JTBD-001, JTBD-006]
stories: []
---

# RFC-035: Authoring-time deferral-cadence enforcement gate

**Status**: proposed
**Reported**: 2026-06-28
**Problems**: P375 (Repo conflates a "named re-entry point" with a self-firing cadence — uncadenced deferrals rot)
**ADRs**: ADR-087 (the cadence-annotation contract design decision)
**JTBD**: JTBD-001 (enforce governance without slowing down), JTBD-006 (progress the backlog while I'm away)

## Summary

P375's root cause: the repo conflates a **named re-entry point** (a `/skill`, a lifecycle
transition, "next review") with a **self-firing cadence**. A deferral that names
`/wr-itil:manage-rfc` rots because nothing self-fires `manage-rfc` on that artefact — it
waits for a human or AFK loop to *choose* to run it, which per P291/P295 never happens.
The user's ratified direction (2026-06-28, work-problems loop-end): build **Option C — the
authoring-time enforcement gate**, the root-cause fix that intervenes when a new uncadenced
deferral is *authored*, not (as Option A's shipped SessionStart census does) only when the
accumulated rot is *surfaced* every session.

This RFC is the I13 fix vehicle for P375 (ADR-071/072/073: a fix proposed on a Known Error
requires a problem-traced RFC). It carries the **core slice** (a working advisory gate +
its bats + the design ADR) and explicitly enumerates the **deferred tail** with cadence
annotations so this very RFC does not reproduce the rot it fixes.

## Driving problem trace

- **P375** (Known Error) — the systemic/meta ticket for the uncadenced-deferral class
  (~12 prior single-instance captures). Its 4-agent reachability audit (2026-06-23)
  enumerated the rot surfaces and named the class-B self-surfacing pattern as the fix
  template. This RFC implements the audit's Option-C rung (authoring-time enforcement),
  the root-cause complement to the already-shipped Option-A census (ADR-084).

## Scope

**The fix being proposed**: a PostToolUse:Write|Edit|MultiEdit hook
(`packages/itil/hooks/itil-deferral-cadence-gate.sh`) that fires at authoring time on the
**newly-authored text** (diff-aware — Edit `new_string` / Write `content` / MultiEdit joined
`new_string`s, so descriptive prose already on disk never re-triggers) of a shipped authoring
surface — `SKILL.md`, `docs/decisions/*.md` (ADRs), `docs/rfcs/*.md` (RFCs), and hook `*.sh`
— and emits a stderr advisory when an uncadenced-deferral phrasing is introduced WITHOUT a
**cadence annotation** naming a self-firing trigger within the +/-5 line window.

**The cadence-annotation contract** (designed in ADR-087): a deferral is legal iff its window
carries a citation of a SELF-FIRING trigger — a hook `*.sh`, `SessionStart`,
`PreToolUse`/`PostToolUse`, a `.github/workflows/` CI step, `cron`, or a `work-problems`
pre-flight. The recommended carrier is an explicit `<!-- cadence: <trigger> -->` comment, but a
bare prose mention of a self-firing surface also satisfies. **The load-bearing P375 refinement**:
a bare named on-demand skill (`/wr-foo:bar`) or a bare ticket ID (`Pnnn`/`RFC-nnn`/`ADR-nnn`)
does NOT satisfy the requirement — naming an on-demand re-entry point and treating it as a
cadence IS the conflation P375 names illegal. (The P234 sibling `itil-fictional-defer-detect.sh`
wrongly accepts both; converging the two is a tracked follow-on, not done here per ADR-002/003.)

**Implementation approach**: clone the proven `itil-fictional-defer-detect.sh` window-scan
shape (per-line defer-match → +/-5 line citation check) but (a) operate on the payload's new
text rather than the on-disk file, (b) scope to authoring surfaces with `docs/problems/`
excluded, (c) narrow the citation set to self-firing CLASSES only. Advisory (exit 0 always)
per ADR-040/045 declarative-first + ADR-013 Rule 6 fail-open + ADR-057 staged rollout.

**Rollout mode**: the core slice ships **advisory** (PostToolUse, stderr). Escalation to a
PreToolUse hard block is a queued user-owned rollout-mode decision (see Tasks B9 / P375
Outstanding Questions) once the advisory's false-positive rate is measured — the ADR-057
advisory→block staging pattern. The architect review (2026-06-28) judged the user's loop-end
ratification was at the *mechanism-class* grain (Option C vs Option A), leaving block-vs-advisory
unratified at the *rollout-mode* grain.

## Tasks

- [x] **B1 — core gate hook** `packages/itil/hooks/itil-deferral-cadence-gate.sh` (advisory,
  diff-aware, self-firing-class citation vocabulary, `docs/problems/` excluded,
  `WR_SUPPRESS_DEFERRAL_CADENCE_GATE` AFK self-suppress).
- [x] **B2 — behavioural bats** `packages/itil/hooks/test/itil-deferral-cadence-gate.bats`
  (15 tests: fires on bare-skill / bare-ticket-ID / no-citation / cadence-comment-naming-an-
  on-demand-skill; silent on hook.sh / SessionStart / CI / explicit-PostToolUse-annotation /
  excluded-surface / non-authoring-file / non-deferral; fail-open; suppress).
- [x] **B3 — register** in `packages/itil/hooks/hooks.json` PostToolUse `Write|Edit|MultiEdit`.
- [x] **B4 — ADR-087** records the cadence-annotation-contract design decision (born
  `human-oversight: unconfirmed` per P357 — ratified separately, see B9 / Confirmation).
- [x] **B5 — changeset** (new shippable `@windyroad/itil` hook).
- [ ] **B6 — transitive-reachability graph validation** (the DEFERRED hard tail): validate
  that a cited cadence trigger ACTUALLY self-fires on that artefact (registered hook / wired
  CI step), not merely names a self-firing *class*. The core slice checks class, not
  existence — citing a plausible-but-fictional hook name passes today.
  <!-- cadence: this RFC's ## Tasks is re-surfaced every SessionStart by retrospective-deferral-census.sh (ADR-084) until B6 is built; promotion driven by work-problems backlog drain -->
- [ ] **B7 — converge** `itil-fictional-defer-detect.sh` onto a shared deferral vocabulary +
  the stricter self-firing citation set (drop its skill/ticket-ID exemptions).
  <!-- cadence: tracked task re-surfaced every SessionStart by retrospective-deferral-census.sh; drained via work-problems -->
- [ ] **B8 — retrofit** cadence annotations onto the ~12 existing uncadenced deferrals the
  P375 audit enumerated (the census backlog), now that the gate exists to keep new ones out.
  <!-- cadence: census line items re-surfaced every SessionStart by retrospective-deferral-census.sh; drained via work-problems -->
- [ ] **B9 — rollout-mode decision**: advisory (shipped) vs escalate-to-PreToolUse-block,
  decided by the user once the advisory false-positive rate is measured (ADR-057 staging).
  <!-- cadence: queued as a P375 Outstanding Question; surfaced at the next interactive review-decisions / work-problems loop-end drain -->

## Commits

(maintained automatically — populated by the commit-message RFC trailer hook per ADR-060 Phase 1 item 12)
<!-- cadence: the RFC-trailer render is a PostToolUse/skill-side projection per ADR-060; not an uncadenced human deferral -->

## Confirmation

The core slice (B1–B5) is verified by the 15 green behavioural bats (`npm test`). B6–B9 are
the deferred tail, each carrying a cadence annotation naming the self-firing surface
(`retrospective-deferral-census.sh` SessionStart census) that re-surfaces it — dogfooding the
contract this RFC introduces. Substance ratification of ADR-087's contract design (and the B9
rollout-mode call) is queued to the next interactive drain per P357 (born `unconfirmed`).

## Related

- **P375** — driver problem ticket (the systemic uncadenced-deferral class).
- **ADR-087** — the cadence-annotation contract design decision.
- **ADR-084** — the shipped Option-A SessionStart census this gate complements.
- **ADR-057** — staged advisory→block rollout precedent for cluster-shaped governance rules.
- **`itil-fictional-defer-detect.sh`** (P234) — the PostToolUse sibling whose window-scan
  shape this gate clones; convergence is tracked task B7.
- **captured via /wr-itil:capture-rfc; expanded inline at fix-time per the I13 ADR-073 P399 spirit.**
