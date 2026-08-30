# Session Retrospective - P512 release reconciliation

## Briefing Changes

- Added one P512-derived learning to `docs/briefing/agent-interaction-patterns.md`: lifecycle reconciliation scripts do not inspect literal cross-ticket paths, so a repository-wide old-path search is the final rename check.
- Updated three existing signal scores after this session acted on reviewer-verdict handling, the commit-file workaround, stale installed caches, and absolute installed shim paths.
- Scanned 202 briefing entries across the indexed topic tree. Seven were exercised by the P512 delivery workflow; no Critical Points entry changed and no unrelated briefing entry was removed under the user's P512-only scope.

## Signal-vs-Noise Pass

| Entry | Topic file | Classification | Citation |
|-------|------------|----------------|----------|
| Reviewer verdict output is the evidence source | `hooks-and-gates.md` | signal, 5 to 6 | Pipeline and external-communications agents returned explicit PASS verdicts before both governed commits. |
| Commit-file message workaround | `external-comms-commit-msg-gate.md` | signal, 14 to 15 | Both P512 reconciliation commits used reviewed message files and passed the commit hooks. |
| Registry-to-installed-cache drift | `plugin-distribution-cache-mechanics.md` | signal, -1 to 0 | The installed ITIL 2.1.2 renderer stripped row status text; the current source renderer restored the published behavior. |
| Absolute installed shim path | `plugin-distribution-cache-mechanics.md` | signal, 5 to 6 | Retrospective diagnostics ran from the installed 0.28.0 cache because its shims were not on this shell's PATH. |
| Ratified map approves the story | `afk-ratification-hold.md` | signal | STORY-MAP-002's confirmed oversight allowed STORY-077 delivery without a new ratification question. |
| Fix vehicle is a release row | `afk-ratification-hold.md` | signal | RFC-083 was completed as the delivered row on STORY-MAP-002. |
| Story-map accessibility gate | `afk-vehicle-authoring-gates-archive.md` | signal | The accessibility lead and specialists returned SHIP/PASS for the regenerated map. |
| Literal cross-ticket path search | `agent-interaction-patterns.md` | signal, new score 1 | The staged risk review found P519's stale `known-error/512` path after all reconcilers passed. |
| Remaining entries | indexed `docs/briefing/*.md` topics | noise | The mandatory topic-tree read completed; these entries were not cited or acted on during the P512 reconciliation. |

**Critical Points changes**: none.

## Pipeline Instability

| Signal | Category | Citations | Decision |
|--------|----------|-----------|----------|
| Installed ITIL cache renderer was older than the published source and stripped visible release-row status labels | Skill-contract violation | Installed 2.1.2 render followed by current-source rerender; accessibility review then confirmed `Delivered: RFC-083` and 84 links with 0 missing | Existing plugin-cache staleness class already captured by P506; no duplicate ticket. |
| Commit-message review marker was not needed when using the documented `git commit -F` compatibility path | Hook-protocol friction | Governed commits `7453b012` and `43ef36ae` both passed with reviewed message files | Existing P415/P402 guidance; no duplicate ticket. |
| README inventory currency | Advisory | 14 packages scanned, 0 drift instances | Clean. |
| Legacy RFC scope queue | Advisory | 8 proposed skeletons scanned, 7 historical under-scoped rows | Existing closed population; no P512 action. |

P512 was created as Verification Pending in this session and is excluded from close-on-evidence. Publication and source tests do not replace a later installed invocation.

## Context Usage - Cheap Layer

| Bucket | Bytes | Percent of measured total | Delta vs 2026-08-29 |
|--------|------:|--------------------------:|--------------------:|
| problems | 6,758,204 | 54.3% | +30,250 (+0.4%) |
| decisions | 2,520,991 | 20.2% | 0 (0.0%) |
| skills | 1,374,322 | 11.0% | +6,189 (+0.5%) |
| memory | 761,091 | 6.1% | 0 (0.0%) |
| hooks | 671,151 | 5.4% | +5,386 (+0.8%) |
| briefing | 238,783 | 1.9% | -622 (-0.3%) |
| jtbd | 118,597 | 1.0% | +895 (+0.8%) |
| project-claude-md | 7,272 | 0.1% | 0 (0.0%) |
| framework-injected | not measured | not measured | framework-injected, no on-disk source |

Top five by byte-count-on-disk are problems, decisions, skills, memory, and hooks. The cadence trigger is inactive: the latest deep report is one day old and no bucket changed by both more than 20% and more than 10 KB. Per-plugin breakdown remains available through `/wr-retrospective:analyze-context`.

## Ask Hygiene

No `request_user_input` calls occurred. Lazy, direction, deviation-approval, override, silent-framework, taste, and correction-followup counts are all 0. The persisted trail is `docs/retros/2026-08-30-p512-reconciliation-ask-hygiene.md`.

## No Action Needed

- The stale installed renderer is an instance of the existing plugin-cache staleness class, not a new P512 defect.
- The commit-file workaround is already documented for installed sessions whose external-communications parser or marker compatibility path is stale.
- No new codification candidate met the recurring-pattern threshold.
