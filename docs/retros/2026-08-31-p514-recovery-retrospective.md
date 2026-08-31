# Session Retrospective - P514 isolated recovery

## Briefing Changes

- Corrected the reviewer-spawn briefing so a genuine PASS without a supported parent-session marker handoff is a fail-closed blocker, never authority to touch, replay, or synthesize marker state.
- Scanned all 18 indexed briefing topics. The session exercised reviewer marker persistence, Promptfoo behavioral-eval authoring, hook portability, ratified-map implementation authority, path-scoped staging, and AFK recovery discipline. No Critical Points entry changed and no unrelated entry was removed in this P514-only iteration.

## Signal-vs-Noise Pass

| Entry | Topic file | Classification | Citation |
|-------|------------|----------------|----------|
| Reviewer PASS that does not land | `afk-reviewer-spawn-failures.md` | signal | Fresh architecture and JTBD reviewers passed, but the native runtime exposed no completed-agent close operation and the next P514 test edit denied for a missing JTBD review marker. |
| Background reviewer marker non-persistence | `external-comms-gate.md` | signal | Its completed-agent-close handshake identified the missing native operation; no marker was replayed or fabricated. |
| Hook shell portability | `hook-authoring-portability.md` | signal | The P514 handoff parser uses first-nonblank-line `awk`; Bats exposed a positive fixture typo before completion. |
| Promptfoo behavioral gate | `promptfoo-eval-authoring.md` | signal | The isolated Node 24 run completed all six actual-agent cases: four recommendation outcomes and two edit regressions passed, while the live global verdict remained unchanged. |
| Ratified map approves the story | `afk-ratification-hold.md` | signal | STORY-079 is accepted on ratified STORY-MAP-002, so this recovery was authorized to implement without a new decision or persona. |
| Remaining entries | indexed `docs/briefing/*.md` topics | noise | The required topic-tree read completed; the remaining entries were not used to choose or validate P514 actions. |

**Critical Points changes**: none.

## Pipeline Instability

| Signal | Category | Citations | Decision |
|--------|----------|-----------|----------|
| Native Codex collaboration lacks the completed-agent close operation expected by the installed JTBD compatibility hook | Hook-protocol friction | Fresh canonical reviewer PASS plus subordinate verdict; the available collaboration surface has no completed-agent close operation | Already covered by P402 (background reviewer PASS does not persist a live-session marker); no duplicate ticket created and no marker was replayed or fabricated. |
| Promptfoo runner previously reserved the same global verdict path as ordinary review | Test-environment blocker | The inherited 4-error run refused to overwrite the live verdict; the corrected runner used a unique owned `JTBD_VERDICT_FILE`, then actual eval `eval-Snt-2026-08-31T04:08:53` passed 6/6 without changing the global file hash | Root cause fixed within P514; the broader behavioural-harness surface remains documented by P324 (agent-prose verdicts lack a behavioural harness). |
| Erroneous goal blockage interrupted the earlier recovery | Skill-contract friction | The user reported the blockage and identified its durable class before this bounded recovery | Already captured as P532 (Codex safety-system error interrupts problem capture and backlog goal); not duplicated. |
| README inventory currency | Advisory | 14 packages scanned, 0 drift instances | Clean. |
| Legacy RFC scope queue | Advisory | 8 proposed skeletons scanned, 7 historical under-scoped rows | Existing population; no P514 action. |

## Context Usage - Cheap Layer

| Bucket | Bytes | Percent of measured total |
|--------|------:|--------------------------:|
| problems | 6,787,226 | 54.3% |
| decisions | 2,520,991 | 20.2% |
| skills | 1,374,322 | 11.0% |
| memory | 761,091 | 6.1% |
| hooks | 672,721 | 5.4% |
| briefing | 241,391 | 1.9% |
| jtbd | 118,996 | 1.0% |
| project-claude-md | 7,272 | 0.1% |
| framework-injected | not measured | not measured |

The latest deep analysis is two days old and no measured bucket established both a greater-than-20-percent and greater-than-10-KB delta, so no deep analysis auto-fired. Per-plugin detail remains available through `/wr-retrospective:analyze-context`.

## Ask Hygiene

No `request_user_input` calls occurred. Lazy, direction, deviation-approval, override, silent-framework, taste, and correction-followup counts are all 0. The persisted trail is `docs/retros/2026-08-31-p514-recovery-ask-hygiene.md`.

## No Action Needed

- Protected outbound-response files remained modified and unstaged throughout.
- P514 source implementation is complete: 48/48 focused shell tests passed, `npm run check:agent-instructions` passed, and actual-agent Promptfoo evaluation `eval-Snt-2026-08-31T04:08:53` passed 6/6 under Node 24.
- A local `@windyroad/jtbd@0.14.1` pack contained the updated agent, hooks, and generated Codex surfaces. Its extracted hooks passed isolated prompt-injection, recommendation, edit-PASS, edit-FAIL, malformed, and stale-disagreement smoke cases. This proves packed content only; no publication or installed-runtime proof exists.
- Claude Code 2.1.245 loaded that packed candidate non-persistently through `--plugin-dir`, registered `wr-jtbd:agent`, performed an actual prefixed recommendation review, rejected the contradictory option, and left the global verdict hash unchanged. This is runtime-loaded candidate proof, not a published or persistently installed-plugin claim.
- No push or release was attempted. P514 remains Known Error until the outer orchestrator delivers it and a later installed exercise supplies verification evidence.
