# Ask Hygiene Trail — 2026-06-17 main-turn (outstanding-questions drain)

Second retro of the day. Covers the drain of `.afk-run-state/outstanding-questions.jsonl` (15 → 0) — 4 AskUserQuestion calls totalling 11 questions.

| Call # | Header | Classification | Citation |
|--------|--------|----------------|----------|
| 1.1 | RFC-014 seq (Batch 1 Q1) | direction | Gap: deviation-approval framing the queued question requested at ask-time; turned out moot post-investigation but the ask was legitimate per ADR-074 substance-confirm. |
| 1.2 | P305 race (Batch 1 Q2) | direction | Gap: ≥2-option fix-strategy decision blocked under ADR-074. User picked Option B (per-iter git worktree). |
| 1.3 | P304 bundler (Batch 1 Q3) | direction | Gap: bundler mechanism choice for P304/RFC-023; user redirected to coordinate with RFC-025 markdown-toggle tool (cross-RFC composition). |
| 1.4 | P248 Phase 2 (Batch 1 Q4) | direction | Gap: Q1+Q3 substance-confirm; user picked Cost-primary + Dual-axis coexistence. |
| 2.1 | P179 enforce (Batch 2 Q1) | direction | Gap: enforcement-form choice on no-unauthorized-defer rule; user picked Option A hard rule + behavioural test. |
| 2.2 | P178 carve (Batch 2 Q2) | direction | Gap: framework position on architect-PASS substitute for RCA; user picked hard-block. |
| 2.3 | P357 enforce (Batch 2 Q3) | direction | Gap: structural enforcement form for freeform-amendment substance-ratification; user picked Option (b) pre-write hook. |
| 2.4 | Turn-end class (Batch 2 Q4) | direction | Gap: capture-vs-append-vs-defer for turn-end-mid-background class; user picked capture new ticket (P370). |
| 3.1 | P080 split (Batch 3 Q1) | direction | Gap: split-into-sibling vs deferred-amendment for Phase 2 catchup; user requested more substance, then redirected to "reopen P080" (Verifying → Known Error rename). |
| 3.2 | P297 Phase 2 (Batch 3 Q2) | direction | Gap: A/B/C/D Phase 2 substance choice; user picked Option D (guided invocations). |
| 4.1 | P080 catchup re-ask | direction | Gap: clarification follow-up after user requested more info on --catchup; user directed reopen + implement. |

**Lazy count: 0**
**Direction count: 11**
**Override count: 0**
**Silent-framework count: 0**
**Taste count: 0**
**Correction-followup count: 0**

## Notes

11 ratifications zero lazy — all calls were genuine substance-confirm-before-build per ADR-074. The two-step pattern on P080 (initial ask → user asked "tell me more" → re-ask with substance) is the correct response to a "more substance needed" signal; the re-ask is direction (clarification follow-up), not lazy, per ADR-044 cat-1 inclusion of "confirming the SUBSTANCE of a genuine ≥2-option decision".

User push-back on Batch 1 Q1 (RFC-014 "huh? this sounds terribly complex and wasteful") surfaced a session-context-staleness signal: the question was queued iter-10 BEFORE Stories A+B+D landed atomically in commit `0e7222be`. The drain skill SHOULD have verified question freshness against current ticket state before asking. Adding to forward-action notes.
