---
status: accepted
rfc-id: rfc-first-trace-invariant-not-enforced-at-fix-time
reported: 2026-05-17
decision-makers: [Tom Howard]
problems: [P251]
adrs: [ADR-060, ADR-051, ADR-052, ADR-042, ADR-044]
jtbd: [JTBD-008, JTBD-001, JTBD-006, JTBD-101]
stories: []
---

# RFC-005: RFC-first trace invariant not enforced at fix-time

**Status**: accepted
**Reported**: 2026-05-17
**Problems**: P251
**ADRs**: ADR-060 (extends I-series with new symmetric-direction invariant), ADR-051 (load-bearing-from-the-start mandates structural hook), ADR-052 (behavioural-tests-default for B6 coverage), ADR-042 (held-changeset graduation for B10), ADR-044 (decision-delegation-contract for override-hatch + dispatch-refusal classes)
**JTBD**: JTBD-008 (primary — decompose-fix-into-coordinated-changes), JTBD-001 (governance composition), JTBD-006 (AFK orchestrator throughput preservation), JTBD-101 (atomic-fix-adopter friction guard)

## Summary

ADR-060 I1 enforces the RFC→Problem trace at RFC capture time. The inverse direction — Problem→RFC trace at fix-time — is NOT enforced. Problems routinely accrete inline `## Root Cause Analysis` → `### Investigation Tasks` → `## Fix Strategy` checklists as fix work uncovers scope, rather than the agent stopping to scope an RFC + story map + JTBD trace before commencing. P251 captures the gap; JTBD-008 § "Trace invariant" + "Capture-time scoping" Desired Outcomes name the contract this RFC closes.

Scope: design and implement the symmetric Problem→RFC trace gate at the fix-time lifecycle surfaces. Include the atomic-fix carve-out per JTBD-008 § Persona Constraints ("Atomic-fix shapes pay no ceremony") — Effort ≤ M may proceed without RFC ceremony; Effort ≥ L requires RFC trace before fix work commences.

## Driving problem trace

- **P251** (`docs/problems/open/251-rfc-first-trace-invariant-not-enforced-fixes-start-without-rfc-story-map-or-jtbd-trace.md`) — RFC-first trace invariant not enforced at fix-time; fixes start without RFC, story map, or JTBD trace. Captured 2026-05-17 via user correction during /wr-itil:work-problems orchestrator main turn. Status: Open. JTBD trace: JTBD-008. Persona: solo-developer.

## Scope

RFC-005 extends ADR-060's I-series invariant set with a new I13 invariant enforcing the symmetric Problem→RFC trace at fix-time. The seven anticipated facets ratify as follows.

### F1 — Lifecycle gate placement: `Open → Known Error` (single gate; no new state)

**Decision**: The Problem→RFC trace check fires at the `Open → Known Error` transition in `/wr-itil:manage-problem` Step 7. No new lifecycle state is introduced.

**Rationale**: `Known Error` is the existing ITIL semantic for "root cause identified, fix strategy known, work is now real" — exactly the moment JTBD-008 § Capture-time scoping names ("the decomposition decision happens at capture time, not as drift mid-flight"). Gating later (`Known Error → Fix Released`) gates after the body-drift the invariant is designed to prevent has already happened; gating via a new `In Progress` state inflates the lifecycle ontology without adding semantic information beyond what `Known Error` already carries. Single-gate placement composes with ADR-060 I1's "hard-block at the earliest meaningful surface" precedent and avoids ADR-060 I2 (uniform problem ontology) friction.

**ADR-060 taxonomy extension**: Placing I13 at `Open → Known Error` introduces the first gate at that lifecycle transition (existing I-series surfaces: `capture-rfc` for I1, `capture-problem` Step 1.5 for I12, `manage-story` acceptance for I7/I8). The I13 amendment to ADR-060 explicitly extends the gate-surface taxonomy to include `manage-problem <NNN> --to known-error` as a sibling gate surface; this is intentional surface expansion, not clerical detail.

### F2 — Atomic-fix carve-out: Effort ≤ M skips RFC ceremony; override hatch via explicit `--rfc-deferred` flag

**Decision**: Problems with `Effort: S` or `Effort: M` (WSJF divisor 1 or 2) skip the I13 check. Problems with `Effort: L` or `Effort: XL` (WSJF divisor 4 or 8) MUST trace to an RFC at `Open → Known Error`. Override hatch: an explicit `--rfc-deferred <reason>` flag on `/wr-itil:manage-problem <NNN> --to known-error` records a deviation-approval per ADR-044 category 2 (one-time override) and writes a structured log entry to `logs/i13-deviations.jsonl` for the reassessment criterion.

**Rationale**: JTBD-008 § Persona Constraints — "Atomic-fix shapes pay no ceremony" — is the load-bearing scaling-down contract. JTBD-101's atomic-fix-adopter friction guard mandates the override hatch. Effort M is the JTBD-008 capture-time decomposition signal boundary: M-effort work that is genuinely multi-commit gets the override hatch + structured-log signal so reassessment can re-tune the threshold; M-effort work that is genuinely atomic pays zero ceremony. Threshold is gate-enforced, NOT prompt-asked (per P185 derive-don't-ask).

### F3 — Problem-ticket template extension: `rfcs: [RFC-NNN, ...]` frontmatter; cardinality 0..N

**Decision**: Add `rfcs: [RFC-<NNN>, ...]` to problem-ticket frontmatter. Cardinality `0..N`:
- `0` permitted (atomic-fix carve-out; pre-`Known Error` problems)
- `≥ 1` required at `Open → Known Error` for problems above the F2 carve-out
- Mirrors ADR-060 RFC frontmatter `problems: [P<NNN>, ...]` shape (symmetric bidirectional trace)

**Rationale**: Symmetric to ADR-060 I1's RFC→Problem array shape. Cardinality `0..N` (not `1..N`) permits the legitimate atomic-fix case and the legitimate "problem captured, not yet at Known Error" case. Composes with I12 (JTBD trace required on user-business problems) without re-hosting that concern — I13 is RFC-trace specifically. Reverse-trace surface (the existing `## RFCs` section auto-rendered from frontmatter per ADR-060 Phase 1 item 10) continues to work unchanged.

### F4 — Iter dispatch at `/wr-itil:work-problems` Step 5: hard-block with structured deny + recovery routing

**Decision**: `/wr-itil:work-problems` Step 5 dispatch refuses to invoke a fix iter on an `Open` or `Known Error` problem above the F2 carve-out that lacks an RFC trace. Refusal is **hard-block** (loop halts on the ticket; orchestrator advances to next-highest WSJF candidate per existing AFK-no-actionable-tickets shape). Deny emits a structured log entry to `logs/i13-iter-dispatch-denials.jsonl` AND surfaces a recovery prompt naming `/wr-itil:capture-rfc P<NNN> <description>` as the next action.

**Rationale**: Mirrors ADR-060 I1's hard-block precedent at the symmetric surface — soft-route (auto-invoke `/wr-itil:capture-rfc` inline) violates ADR-044 category 1 (direction-setting decisions stay with the user; RFC scope IS direction-setting). Halt-with-recovery-routing composes with the JTBD-006 AFK orchestrator selection contract: the iter doesn't dispatch, but the loop doesn't terminate either — orchestrator skips and continues per the established "skip non-actionable tickets" shape. Hard-block is consistent with ADR-051 load-bearing-from-the-start; soft-route would be advisory-disguised-as-action.

### F5 — Hook enforcement: PreToolUse:Bash gate on `git commit` with staged ticket-state-transition

**Decision**: Ship a structural hook at `packages/itil/hooks/itil-i13-rfc-trace-gate.sh` (PreToolUse:Bash). The hook fires when `git commit` is invoked AND the staged set includes a problem-ticket move from `docs/problems/open/` → `docs/problems/known-error/` AND the ticket's frontmatter has `rfcs: []` (or absent) AND `Effort:` is `L` or `XL` AND no `--rfc-deferred` override is recorded for that ticket in the structured log. Hook emits `permissionDecision: "deny"` with directive naming `/wr-itil:capture-rfc P<NNN>` as the recovery action. Sibling shape to `itil-readme-refresh-discipline.sh` (P165) and to ADR-060 I1's `capture-rfc` problem-trace enforcement.

**Rationale**: ADR-051 mandates structural enforcement on day 1 (no advisory-only contracts for drift class). The PreToolUse:Bash gate on staged ticket-state-transition is the closest enforcement surface to the failure mode (the commit that lands the lifecycle transition). Hook is sibling to existing infrastructure — does not invent a new enforcement category. SKILL.md prose updates in `/wr-itil:manage-problem` Step 7 and `/wr-itil:work-problems` Step 5 compose with (not replace) the hook — prose surfaces inform the user during the skill turn; the hook is the load-bearing gate.

### F6 — Story-map composition: I13 requires RFC trace ONLY; story-map composition deferred to RFC-003

**Decision**: I13 enforces the Problem→RFC trace at fix-time. Story-map presence is NOT part of the I13 check. RFC-005's gate fires on RFC trace alone. Story-map composition with the fix-time gate is a future RFC if and when RFC-003 (Phase 2 story-map framework) ships and dogfood evidence shows fix-time work commencing without story-map context degrades JTBD-008 outcomes.

**Rationale**: ADR-060 I8 already enforces story-trace-to-story-map at story acceptance (Phase 2 framework code); ADR-060 I7 enforces story-trace-to-RFC at story acceptance. Story-map presence at problem-fix-time is therefore transitively assured once an RFC with `stories: [...]` is captured. Layering story-map presence directly into the I13 gate would re-host the I7/I8 contracts at a different surface — violates ADR-060 I2 (uniform ontology, no per-surface re-hosting). If RFC-003 ships and the transitive guarantee proves insufficient in practice, that observation becomes a new problem ticket.

### F7 — New I-series invariant: I13

**Decision**: Amend ADR-060 to add I13 to the Mandatory invariants section:

> **I13 (trace-to-RFC at fix-time)**: every problem whose `Effort` field is `L` or `XL` MUST trace to ≥ 1 RFC in `proposed`, `accepted`, or `in-progress` status before the `Open → Known Error` lifecycle transition. Hard-block at `/wr-itil:manage-problem <NNN> --to known-error` and at `git commit` for staged transitions (sibling shape to I1's hard-block at `capture-rfc`). Override hatch: `--rfc-deferred <reason>` records a deviation-approval per ADR-044 category 2; deviations log to `logs/i13-deviations.jsonl` for reassessment-criterion tracking. Effort `S` or `M` problems are carved out per JTBD-008 § Persona Constraints + JTBD-101 atomic-fix-adopter friction guard.

The ADR-060 amendment lands in the same commit chain as the SKILL + hook + behavioural-test shipment (held-changeset window per ADR-042). A behavioural test asserts the carve-out boundary fires correctly at both directions (M-effort skips; L-effort blocks; override hatch records).

### Deviation-candidate questions surfaced at intake (per ADR-044 cat 2)

Two facets carry residual deviation-candidate uncertainty that the implementer should re-confirm at the first concrete fix-iter post-shipment:

- **D1 — Effort-M boundary** (F2): JTBD-008 § Persona Constraints names "atomic" without naming a specific Effort threshold. M-as-cutoff is the strongest signal-to-noise pick at design time, but field evidence after N=4+ I13-gated problems may show the threshold should sit at S/M boundary instead. Reassessment criterion below tracks the M-as-cutoff hypothesis.
- **D2 — Override hatch granularity** (F2 + F4): `--rfc-deferred <reason>` is a one-shot per-ticket override. If a recurring sub-class of L-effort problems legitimately doesn't decompose into RFC ceremony (incident-driven hotfixes per JTBD-201?), that sub-class warrants its own carve-out rather than per-ticket overrides. Surface at first occurrence; capture as a P-NNN follow-up if observed.

### Reassessment criteria

- **M-as-cutoff calibration**: after N=4+ I13 gate fires (block or override), if the deny/override ratio shows the carve-out boundary systematically miscalibrates (e.g. >50% of L-effort blocks get overridden as "actually atomic"), the F2 threshold needs revisiting. Tracks D1.
- **Override-hatch sub-class emergence**: if `logs/i13-deviations.jsonl` shows a recurring `--rfc-deferred` reason category (e.g. all incident-driven), that sub-class becomes a new carve-out via a follow-up RFC. Tracks D2.
- **Soft-route demand**: if `logs/i13-iter-dispatch-denials.jsonl` shows orchestrator iters repeatedly halting on the same RFC-less problem AND the user repeatedly captures the RFC inline immediately after, the F4 hard-block stance may need to soften to auto-invoke `/wr-itil:capture-rfc` inline. Tracks F4.
- **Story-map gap surface** (F6): if dogfood evidence post-RFC-003 shows fix-time work commencing without story-map context degrades JTBD-008 outcomes despite the transitive I7/I8 guarantee, raise a follow-up RFC to compose story-map presence into the I13 gate.

## Considered Options / Alternatives Rejected

Per the proposed → accepted transition discipline, rejected alternatives recorded for trace clarity at reassessment:

- **F1 alternatives rejected**:
  - `Known Error → Fix Released` gate — gates after the body-drift the invariant prevents has already happened.
  - New `Open → In Progress` lifecycle state — inflates ontology without adding semantic value beyond `Known Error`.
- **F2 alternatives rejected**:
  - Effort-S-only carve-out — too aggressive; M-effort genuinely-atomic work is common in this monorepo, would create friction without benefit.
  - No-carve-out (universal RFC ceremony) — violates JTBD-008 § Persona Constraints "Atomic-fix shapes pay no ceremony" + JTBD-101 atomic-fix-adopter friction guard.
- **F4 alternatives rejected**:
  - Soft-route (orchestrator auto-invokes `/wr-itil:capture-rfc` inline) — violates ADR-044 category 1 (direction-setting decisions stay with user; RFC scope IS direction-setting). Would be advisory-disguised-as-action; not load-bearing.

## Tasks

Ordered slice decomposition (one-purpose-per-commit per ADR-014). Slices land in a held-changeset window per ADR-042 / P162; held window stays paused until B6 bats green + B8 dogfood + B9 reassessment-criteria wiring close.

- [ ] **B1** — Amend ADR-060 Mandatory invariants section to add I13 (Scope F7). Include the carve-out clause, the override hatch, the deviation log path, and the cross-reference to JTBD-008 § Persona Constraints + JTBD-101 atomic-fix-adopter friction guard. Update ADR-060 `prior-amendments:` frontmatter with the 2026-05-17 RFC-005 amendment entry. Explicit ADR-060 gate-surface taxonomy extension to include `manage-problem <NNN> --to known-error`. Architect + JTBD agent re-review per the ADR-060 amendment discipline.
- [ ] **B2** — Extend problem-ticket frontmatter schema (Scope F3): add `rfcs: [RFC-<NNN>, ...]` field with `0..N` cardinality. Update the problem-ticket template + the `/wr-itil:capture-problem` SKILL surface to populate `rfcs: []` by default. Update `/wr-itil:manage-problem` SKILL surface to support appending RFC references when the problem-fix decomposes mid-flight.
- [ ] **B3** — Ship the I13 structural hook (Scope F5) at `packages/itil/hooks/itil-i13-rfc-trace-gate.sh`. PreToolUse:Bash gate on `git commit` whose staged set includes `docs/problems/open/ → docs/problems/known-error/` transition with empty/absent `rfcs:` frontmatter AND `Effort: L|XL` AND no recorded `--rfc-deferred` override. Hook emits `permissionDecision: "deny"` with directive naming `/wr-itil:capture-rfc P<NNN>` as the recovery routing. Wire into `.claude/settings.json` PreToolUse handlers.
- [ ] **B4** — Update `/wr-itil:manage-problem` Step 7 to enforce the I13 gate at `Open → Known Error` (Scope F1). Add the `--rfc-deferred <reason>` flag handling with the structured log entry to `logs/i13-deviations.jsonl`. Add the recovery-routing prose surface alongside the hook (prose + hook compose; hook is load-bearing).
- [ ] **B5** — Update `/wr-itil:work-problems` Step 5 dispatch logic with the I13 hard-block + skip-to-next behaviour (Scope F4). Structured-log dispatch denials to `logs/i13-iter-dispatch-denials.jsonl`. Surface recovery prompt naming `/wr-itil:capture-rfc P<NNN>`. Compose with the existing skip-non-actionable-tickets shape — loop does NOT halt; orchestrator advances to next-highest WSJF candidate.
- [ ] **B6** — Behavioural bats coverage per ADR-052 covering: (a) I13 hook denies L-effort transition without RFC trace; (b) I13 hook passes M-effort transition without RFC trace (carve-out fires); (c) I13 hook passes L-effort transition WITH RFC trace; (d) `--rfc-deferred` override path writes the deviation log entry and admits the transition; (e) work-problems Step 5 dispatch refuses L-effort RFC-less problem and admits L-effort RFC-traced problem; (f) ADR-060 I2 uniformity test extension — manage-problem / work-problems behaviour identical regardless of `type:` value when `rfcs:` is populated.
- [ ] **B7** — Retro migration sweep: enumerate current `docs/problems/open/` + `docs/problems/known-error/` tickets; identify those with `Effort: L|XL` and absent RFC trace. Produce a survey table at `docs/audits/i13-rollout-survey-2026-05-17.md` listing cost-of-retrofit (per ticket: RFC-author-effort estimate + override-hatch-acceptable judgement). Survey informs B8 dogfood selection and the rollout-grandfathering decision.
- [ ] **B8** — Forward-dogfood: capture an RFC against a real L-effort `Open` problem from the B7 survey, run it through `Open → Known Error` under the I13 gate, ship a fix slice, and confirm the gate fires correctly. Mirrors ADR-060 Phase 1 forward-dogfood discipline (Confirmation criterion 9). Document the dogfood evidence inline in RFC-005.
- [ ] **B9** — Wire the three reassessment criteria (M-as-cutoff calibration, override-hatch sub-class emergence, soft-route demand) into `/wr-retrospective:run-retro` Step 2b advisory signal collection. Log paths `logs/i13-deviations.jsonl` and `logs/i13-iter-dispatch-denials.jsonl` become retro inputs.
- [ ] **B10** — Held-changeset graduation: ADR-042 auto-apply paused for the RFC-005 commit chain until B6 bats green + B8 dogfood evidence confirms gate fires correctly + B9 retro wiring shipped. Graduate atomically per ADR-060 architect-review finding 12 (RFC-shaped held changesets graduate atomically — entire chain or nothing).

## Commits

(maintained automatically — populated by the commit-message RFC trailer hook per ADR-060 Phase 1 item 12; lands in Slice 3 task B5.T9)

## Related

- **P251** — driving problem ticket; captured 2026-05-17 via user correction.
- **JTBD-008** — primary anchor; "Trace invariant" + "Capture-time scoping" + "First-class sub-workstream entities" Desired Outcomes all speak directly.
- **ADR-060** — parent framework. This RFC extends the I-series to the symmetric direction. ADR-060 Phase 1 ships RFC→Problem trace; this RFC ships Problem→RFC trace at fix-time.
- **ADR-051** — load-bearing-from-the-start; mandates structural hook over prose-only contract.
- **ADR-052** — behavioural-tests-default; B7 task contract.
- **JTBD-101** — atomic-fix-adopter friction guard; informs the atomic-fix carve-out shape.
- **JTBD-006** — work-backlog-AFK; the carve-out boundary affects AFK orchestrator dispatch latency.
- **JTBD-001** — enforce-governance; the structural hook composes with the existing per-edit governance band.
- **P196** — sibling; agents complete RFC docs without shipping the slices (different premature-completion failure mode; same RFC framework surface).
- **P189** — sibling; agent invents "deferred" framing on tracked phases (same class-of-behaviour at a different SKILL surface).
- **P165** — sibling structural hook shape; PreToolUse:Bash gate on staged ticket surfaces.

(captured via /wr-itil:capture-rfc; expand at next /wr-itil:manage-rfc invocation)
