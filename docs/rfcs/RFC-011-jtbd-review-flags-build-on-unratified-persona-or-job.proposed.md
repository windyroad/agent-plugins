---
status: proposed
rfc-id: jtbd-review-flags-build-on-unratified-persona-or-job
reported: 2026-05-27
decision-makers: [Tom Howard]
problems: [P323]
adrs: [ADR-068, ADR-074, ADR-066]
jtbd: []
stories: []
---

# RFC-011: JTBD review flags changes built on an unratified persona or job

**Status**: proposed
**Reported**: 2026-05-27
**Problems**: P323
**ADRs**: ADR-068 (amended 2026-05-27 to record this as JTBD oversight enforcement **surface 3**; decision home user-confirmed via AskUserQuestion), ADR-074 (substance-before-build contract this extends to the JTBD surface), ADR-066 (orthogonal status/oversight axes + the "unconfirmed = marker absent + not superseded" predicate definition)

## Summary

Close the JTBD-surface half of the build-on-unratified gap. The JTBD oversight machinery (ADR-068) has surfaces 1 (born-confirmed record via `update-guide`) and 2 (interactive drain via `confirm-jobs-and-personas`) but no **surface 3** — the build-upon guard the ADR side just got via ADR-074 / RFC-010 / P318. This RFC adds the JTBD twin: the `wr-jtbd:agent` reviewer emits an `[Unratified Dependency]` verdict when a change/plan explicitly cites/implements/serves a persona or job lacking `human-oversight: confirmed`.

Key framing (mirrors RFC-010): the trigger is the **oversight marker**, NOT `status:`. Building on a ratified job (even `status: proposed`) is fine; only marker-less, non-superseded dependencies flag. Bound to **explicit cite/implement**, never ambient alignment (inverse-P078 / P132 over-fire guard) — the reviewer already matches every change to a job for its PASS verdict and surface 3 must not fire on that mere match.

## Driving problem trace

- **P323** — the jtbd agent reviews changes for *alignment* with documented jobs/personas but has zero awareness of the `human-oversight: confirmed` marker (`grep` → 0); a change built on an unratified persona/job passes with no flag. The ADR-side twin (P318/RFC-010) shipped 2026-05-27; this is its missing JTBD mirror.

## Scope

- **`packages/jtbd/agents/agent.md`**: add issue type **[Unratified Dependency]** + a "When to flag" instruction. When a change/plan explicitly cites/implements/serves a specific persona or job (`@jtbd JTBD-NNN` annotation, `persona: <name>` reference, or it authors that artifact's flow), the agent runs `wr-jtbd-is-job-or-persona-unconfirmed <persona|JTBD-NNN>` **by exit code** (the jtbd agent has `Bash`, unlike the architect agent which greps inline). Exit 1 (marker absent, not superseded) → emit **ISSUES FOUND / FAIL / [Unratified Dependency]** with action "ratify `<persona|JTBD-NNN>` via `/wr-jtbd:confirm-jobs-and-personas` before this lands." Status-agnostic; never key on `proposed`.
- **`packages/jtbd/scripts/is-job-or-persona-unconfirmed.sh`** + **`packages/jtbd/bin/wr-jtbd-is-job-or-persona-unconfirmed`** (ADR-049 shim): single-artifact predicate, the sibling of `packages/architect/scripts/is-decision-unconfirmed.sh`. Resolves a `persona: <name>` ref to `docs/jtbd/<name>/persona.md` and a `JTBD-NNN` ref to `docs/jtbd/<persona>/JTBD-NNN-*.md` (ADR-008 layout — larger ref-resolution surface than the ADR predicate's `ADR-NNN | NNN | path`). Frontmatter-scoped `human-oversight: confirmed` match (case-insensitive, trailing-ws-tolerant); `*.superseded.md` → exit 0 (ratified-equivalent). Shares the marker grammar with `detect-unoversighted.sh` per the ADR-068 cross-surface-consistency driver.
- **Bound** to explicit cite/implement (not transitive/ambient). Unlike the ADR side (4/65 unratified), the JTBD unratified set is large (17 per P288) — the explicit-cite bound keeps surface 3 proportionate; it does **not** wait on the P288 drain (surface 3 is the forcing function).
- **Tests**: (a) behavioural bats for the predicate — marker-present→0, marker-absent→1, superseded→0 over a `docs/jtbd/` fixture tree (sibling of `is-decision-unconfirmed.bats`); (b) structural-permitted bats for the agent verdict-presence (`ADR-052` Surface 2, P176 — agent verdict is prompt-driven, not behaviourally testable until the skill-invocation harness lands; carries the `tdd-review: structural-permitted (justification: P323/RFC-011)` header; mirrors `architect-unratified-dependency-verdict.bats`).

Out of scope: the P288 drain itself (surfaces 1 & 2, already shipped); the `solo-developer` → `developer` rename (P289 — surface 3 will fire on the held persona, which is expected); re-deciding the marker-vs-status framing (settled by ADR-066/ADR-074).

## Tasks

- [x] **T0 DONE** — recorded **enforcement surface 3** as the 2026-05-27 amendment to ADR-068 (item 7 + Confirmation criterion 6 + Related). Decision home user-confirmed via AskUserQuestion (amend ADR-068). Architect PASS + JTBD PASS.
- [ ] **T1** — `packages/jtbd/scripts/is-job-or-persona-unconfirmed.sh` + the `wr-jtbd-is-job-or-persona-unconfirmed` shim (sibling of the architect predicate; ADR-008 ref-resolution; frontmatter-scoped marker; superseded-skip).
- [ ] **T2** — behavioural bats for the predicate (marker-present/absent/superseded over a fixture tree).
- [ ] **T3** — `packages/jtbd/agents/agent.md`: add the `[Unratified Dependency]` issue type + the "When to flag" instruction (explicit-cite-bound, runs the predicate by exit code, marker-keyed-not-status).
- [ ] **T4** — structural-permitted bats for the agent verdict-presence (ADR-052 Surface 2 header citing P323/RFC-011).
- [ ] **T5** — changeset for `@windyroad/jtbd`.

## Commits

(maintained automatically — RFC trailer hook per ADR-060 Phase 1 item 12)

## Related

- **P323** — driving problem.
- **P318 / RFC-010** — the ADR-surface twin this mirrors.
- **P315** — grandparent (substance-confirm-before-build); P318 + P323 are its uncovered ADR / JTBD foreground surfaces.
- **ADR-068** — this extends its JTBD oversight surface-set from 1 & 2 to surface 3.
- **ADR-074** — the build-upon contract; this is its JTBD-surface enforcement.
- **ADR-066** — orthogonal status/oversight axes + the predicate's "unconfirmed" definition.
- **P288** — built surfaces 1 & 2; the 17-artifact unratified set is surface 3's current would-fire scope.
- **P289** — `solo-developer` → `developer`; the held-unratified persona is the live instance.

(captured via /wr-itil:capture-rfc; design settled + architect/JTBD PASS. Advance via /wr-itil:manage-rfc.)
