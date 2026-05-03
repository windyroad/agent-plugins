---
"@windyroad/itil": minor
---

P155: ship `/wr-itil:capture-problem` skill — lightweight aside-invocation surface for problem capture during foreground work

Closes the heavyweight-only-capture-path gap (parent P014 ADR-032 child) — the lightweight aside-invocation surface for problem capture during foreground work. The current capture path is `/wr-itil:manage-problem <description>`, a ~10-turn ceremony designed for canonical new-problem creation. This is wrong for the **aside-invocation** use case where the user (or agent mid-iter) wants to capture an observation quickly without disrupting current task flow.

Three repeating patterns surfaced the friction:

- **Mid-AFK-iter sibling-findings** — agent observes a tangential ticket-worthy issue while working on a different problem. The ~10-turn ceremony breaks iter cadence; the observation gets buried in `notes` field of `ITERATION_SUMMARY` and ~50% never reach the backlog.
- **User-initiated rapid captures** during retros, code reviews, or correction conversations — "btw, this is broken too — capture it" should not consume 10 turns of the conversation.
- **AFK orchestrator main turn captures** — user-driven mid-loop interjections (P151 / P152 / P154 in the session that surfaced P155). Each capture took 5-15 minutes wall-clock through the heavyweight flow.

`/wr-itil:capture-problem` is the source-side fix.

Adds:

- `packages/itil/skills/capture-problem/SKILL.md` (~150 lines, ADR-038 progressive-disclosure budget). Steps 0-7: reconciliation preflight; description parse with empty-arg halt-with-stderr-directive; minimal 3-keyword title-only duplicate-grep + create-gate marker via existing `packages/itil/hooks/lib/create-gate.sh` helper composing with manage-problem's `/tmp/manage-problem-grep-${SESSION_ID}` per P119; P056-safe local_max + origin_max next-ID formula; deferred-placeholder skeleton-fill template (`Priority 3 (Medium) — Impact 3 × Likelihood 1 (deferred — re-rate at next /wr-itil:review-problems)`, `Effort M (deferred — …)`, narrative sections marked `(deferred to investigation)`); single Write; single commit `docs(problems): capture P<NNN> <title>` per ADR-014; trailing pointer to `/wr-itil:review-problems` for WSJF fold + README refresh.
- `packages/itil/skills/capture-problem/REFERENCE.md` — rationale (capture vs manage trade-off; capture-time false-positives cheaper than false-negatives), edge cases (empty `$ARGUMENTS` halt, kebab-stopword-soup slug fallback, ID collision with origin, cross-skill marker idempotence, P057 not applicable, multi-concern routing to manage-problem), composition with manage-problem create-gate (P119) + review-problems (deferred WSJF/README refresh) + work-problems iter subprocesses (foreground-lightweight is AFK-compatible; background-capture remains AFK-excluded per ADR-032 line 85).
- `packages/itil/skills/capture-problem/test/capture-problem.bats` — 14 behavioural tests per ADR-052: P119 create-gate composition (mark_step2_complete writes marker / check_create_gate exit transition / cross-skill idempotence), next-ID formula (P056-safe mixed-suffix glob / empty-dir first-ticket), title-only conservative duplicate-grep (filename match / body-content non-match), skeleton-fill template (Status / Description / deferred-placeholder / re-rate-investigation-task), allowed-tools surface (no AskUserQuestion / Bash present / Write present), deferred-README-refresh contract presence; 14/14 green.

Amends:

- `docs/decisions/032-governance-skill-invocation-patterns.proposed.md` — appends "Foreground-lightweight-capture variant (P155 amendment, 2026-05-03)" section between Observable-output contract and Scope. Names the new variant alongside the deferred background-capture variant per P088 settlement; documents the deferred-README-refresh contract inline (capture-time speed vs README authoritativeness; on-disk inventory is source of truth, README is derived view); pin variant-selection precedence (foreground-lightweight is LEAD post-P155; background-capture remains deferred sibling slot).

Architectural design (zero AskUserQuestion branches per ADR-044 framework-mediated mechanical-stage carve-out):

| Decision | Resolution |
|---|---|
| Duplicate-check | 3-keyword title-only grep; matches listed in report; capture proceeds regardless. False-positives cheaper than false-negatives (P155 line 24). |
| Priority default | Framework-policy `3 (Medium)`, flagged for re-rate. |
| Effort default | Framework-policy `M`, flagged for re-rate. |
| Multi-concern split | Out of scope; route to `/wr-itil:manage-problem`. |
| Empty `$ARGUMENTS` | Halt-with-stderr-directive (AFK-safe). |

Deferred-README-refresh contract:

- capture-problem does **not** regenerate `docs/problems/README.md` inline (the P094 block from manage-problem Step 5 is intentionally omitted).
- README ranking lags new captures until next `/wr-itil:review-problems` invocation, which folds captured-but-not-rated tickets via Step 9b auto-transition pass (keys off the literal deferred-placeholder string).
- Trade-off: capture-time speed vs README authoritativeness. On-disk ticket inventory is always source of truth; README is derived view.
- Trailing pointer in Step 7 is the user-visible signal that the README is transiently stale and how to reconcile.

Composes with:

- ADR-032 (governance skill invocation patterns) — this skill is the foreground-lightweight-capture variant amendment 2026-05-03.
- ADR-038 (progressive disclosure) — SKILL.md + REFERENCE.md split shape.
- ADR-044 (decision-delegation contract) — framework-mediated mechanical-stage carve-outs justify zero-AskUserQuestion design.
- ADR-049 (bin/ on PATH) — capture-problem reuses existing `wr-itil-reconcile-readme` shim; no new shim needed.
- ADR-052 (behavioural-tests-default) — bats fixtures exercise primitives, not SKILL.md prose.
- P119 (manage-problem create-gate hook) — capture-problem composes with the same per-session marker.

Unblocks:

- **P078** (capture-on-correction OFFER pattern) — depends on capture-problem shipping; user can now OFFER `/wr-itil:capture-problem` on strong-affect correction signals.
- **P148** (Tickets Deferred retro section) — becomes legacy when capture-problem ships; the ~50%-loss class observation no longer needs a retro-summary surface.

Sibling P156 (capture-adr) and P157 (pending-questions-surface hook) remain Open under the same parent P014; ship in subsequent iters.
