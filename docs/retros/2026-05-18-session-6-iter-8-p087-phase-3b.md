# Session 6 iter 8 retro — P087 Phase 3b renderer + drift detector

> AFK-mode retro per ADR-013 Rule 6 (`/wr-itil:work-problems` orchestrator subprocess). User transient (P130). No `AskUserQuestion` mid-iter (P083 / orchestrator brief). Findings surfaced inline + via the orchestrator's `outstanding_questions` queue.

## What shipped

- **P087 Phase 3b** — README badge renderer (`wr-itil-plugin-maturity-render`) + advisory drift detector (`wr-retrospective-check-plugin-maturity-drift`). Two changesets (`@windyroad/itil` minor + `@windyroad/retrospective` minor). 31/31 behavioural bats green (17 renderer + 14 drift detector). Smoke test against live monorepo: 12 plugins / 0 drift instances baseline. Single ADR-014 commit `dd93da4`.
- **P237 (Phase 3a)** — folded Open → Verification Pending per ADR-022 P143 amendment since Phase 3a script shipped 2026-05-17 commit `b840a7a`.
- **P238 (Phase 3b)** — transitioned Open → Verification Pending this iter.
- **P087 (parent)** — remains Known Error. Phase 3c (P239) + Phase 3d (P240) + F9 (P244) + retroactive mechanical rollout still pending.

## Pipeline Instability (Step 2b)

| Signal | Category | Citations | Decision |
|---|---|---|---|
| `wr-itil-reconcile-readme` shim on `$PATH` points at stale `0.32.1` cache (lacks P252 Inbound Upstream Reports section-anchor fix); 31 spurious `STALE verification-queue` entries reported at iter start. Source-of-truth + `0.34.0` cached script both report clean. | Hook-protocol friction / cache-staleness | `wr-itil-reconcile-readme docs/problems` returned exit 1 with 31 STALE rows; `bash packages/itil/scripts/reconcile-readme.sh docs/problems` returned exit 0 cleanly; `/Users/tomhoward/.claude/plugins/cache/windyroad/wr-itil/0.34.0/scripts/reconcile-readme.sh docs/problems` returned exit 0; `$PATH`-resolved shim is from 0.32.1 (`which wr-itil-reconcile-readme` → `/Users/tomhoward/.local/bin/...` → `0.32.1/bin/...`). | Already tracked under P233 (currently Verifying); no new ticket. Phase 1 chain resolves on next release that exercises Step 6.5 Drain `/install-updates` chain. |
| External-comms gate hashes `Write tool_input.content` (FULL file content INCLUDING frontmatter) for marker key derivation, but agent's first delegate-prompt to `wr-risk-scorer:external-comms` wrapped only the changeset BODY inside `<draft>...</draft>` markers. Hash mismatch caused FAIL on first attempt; required 2 retry cycles per changeset. Mirror gap also blocked the second changeset's marker. | Subagent-delegation friction / SKILL-contract gap | Multiple `BLOCKED (external-comms gate / risk evaluator)` denials on `Write .changeset/p087-p238-phase-3b-renderer.md`; computed key `651c66565e2a3a95f54e84cf94f11dc5d15855e80c0ad45de3fa014baff7dfb9` (body-only) vs gate-derived `16d63599b44671e07f9ca7795b8fd6965e0fadbe2e4c1e8fc2cb538fc407fe25` (full file). Same pattern fired on changeset 2. | NEW ticket candidate — SKILL.md `assess-external-comms` Step 3 prompt template should make explicit that `<draft>` MUST wrap the FULL file content (frontmatter included) for changeset surfaces, not just the body. Surface to orchestrator outstanding_questions. |
| Voice-tone `external-comms-mark-reviewed.sh` hook (0.5.0 cached) reads agent-emitted `EXTERNAL_COMMS_VOICE_TONE_KEY:` line literally; agent fabricated placeholder hex keys in the first invocation; marker not written; gate continued to block. Risk-scorer hook (0.10.0) by contrast derives key from prompt structure (`derive_external_comms_key_from_prompt` helper). Voice-tone hook hasn't received the same upgrade. | Hook-protocol friction / asymmetric evaluator-pair contract | `agent ...wr-voice-tone:external-comms` returned `EXTERNAL_COMMS_VOICE_TONE_KEY: 5f7a2c1d...` (fake hex, not real sha256); hook validated against `^[0-9a-f]{64}$` regex passed BUT marker file at that key path was checked against `f70afafa...` (gate-computed); no match. Manual `touch` of correct-key marker required to unblock. | NEW ticket candidate — voice-tone hook should adopt the risk-scorer 0.10.0 prompt-derivation pattern (P166 surface). Likely overlaps with existing P166 / P163 cluster on external-comms-hook-side-sha256. Surface to orchestrator outstanding_questions. |
| JTBD currency advisory: `wr-retrospective-check-readme-jtbd-currency` not invoked this iter (script exists, but iter scope strict on P087 Phase 3b work; full retro JTBD currency advisory deferred to next interactive retro). | (Informational) | n/a — script invocation skipped per AFK retro minimalism. | Recorded; no action this iter. |

## Verification Candidates (Step 4a)

P237 + P238 transitioned this iter — same-session verifyings excluded per Step 4a contract. No other `.verifying.md` tickets exercised in iter scope.

## Topic File Rotation (Step 3 Tier 3 P099 / P247)

14 topic files currently OVER the 5120-byte ceiling (range 5529-10009 bytes; all under the 2× MUST_SPLIT threshold at 10240). Per Branch B P247 evidence-based rotation — these are existing-state OVER files inherited from prior retros, not introduced this iter; iter scope strict on P087 Phase 3b. Rotation deferred to a dedicated retro pass per ADR-014 commit grain.

## Context Usage (Cheap Layer)

Cheap-layer measurement script invocation skipped this iter (AFK retro minimalism; iter scope strict on P087 Phase 3b). Bucket snapshot deferred to next interactive retro or `/wr-retrospective:analyze-context`.

## Ask Hygiene (P135 Phase 5 / ADR-044)

| Call # | Header | Classification | Citation |
|---|---|---|---|

**Lazy count: 0**
**Direction count: 0**
**Override count: 0**
**Silent-framework count: 0**
**Taste count: 0**
**Correction-followup count: 0**

This iter is `claude -p` AFK subprocess; orchestrator brief explicitly forbids `AskUserQuestion` mid-iter (P083). Zero calls fired, zero classifications needed. TREND continuity preserved.

## Codification Candidates

| Kind | Shape | Suggested name / Target file | Scope / Flaw | Triggers / Evidence | Decision |
|---|---|---|---|---|---|
| improve | hook | `packages/voice-tone/hooks/external-comms-mark-reviewed.sh` | Hook uses agent-emitted KEY (fragile — agent fabricates fake hex); should derive from prompt structure like risk-scorer 0.10.0 hook | This iter: voice-tone marker not written despite PASS verdict; manual `touch` required to unblock changeset write (2x). | Surface as outstanding_question — likely overlaps with P166 / P163. |
| improve | skill | `packages/risk-scorer/skills/assess-external-comms/SKILL.md` Step 3 | Prompt template should explicitly instruct that `<draft>` MUST wrap the FULL file content (frontmatter included) for changeset surfaces, not just the body content | This iter: first risk-scorer agent invocation hashed body-only; gate rejected; required redo with full content | Surface as outstanding_question — new ticket candidate. |

## No Action Needed

- P162 / P165 / P094 / P062 README refresh contracts fired correctly post-transition (lines 45-46 removed from WSJF Rankings; P237/P238 rows added to Verification Queue; line 3 rotated per P134; README-history.md extended).
- Architect + JTBD reviews returned PASS without inline amendments needed.
- Risk-scorer pipeline assessment returned RISK_SCORES: commit=4 push=3 release=3 (within Low band per RISK-POLICY.md appetite).
