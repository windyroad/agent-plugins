# Session Retrospective — P428 iteration

## Briefing Changes

- Added the macOS Bash 3.2-safe Step 5 dispatch rule to `docs/briefing/afk-subprocess.md` and refreshed its Topic Index summary.
- Classified 202 briefing entries across 36 topic and archive files. Nine entries were signal and 193 were noise for this cycle.
- Kept the 106 entries now scoring at or below -3 in a delete queue because this retrospective runs inside a work-problems iteration. No Critical Points entry was promoted or demoted.

## Signal-vs-Noise Pass

| Entry | Topic file | Classification | Citation |
|---|---|---|---|
| Bash 3.2-safe Step 5 dispatch | `afk-subprocess.md` | signal, new score 1 | P428 implementation and `/bin/bash` behavioral fixture in commit `35ae243f` |
| Repeated commit-message flags need the complete reviewed body | `external-comms-commit-msg-gate.md` | signal, 13 to 14 | Installed 0.18.17 hook reproduced first-message-only extraction; the source fix is already documented as released in 0.18.19 |
| Hand-invoke the completion hook with a genuine verdict when required | `external-comms-gate.md` | signal, -2 to -1 | The completed risk review was passed through the installed mark hook before commit `35ae243f` |
| Installed plugin shims may require absolute paths | `plugin-distribution-cache-mechanics.md` | signal, 4 to 5 | Retrospective shims were absent from this shell's PATH and ran from the installed cache |
| Existing ratified map approves the new story | `afk-ratification-hold.md` | signal, 10 to 11 | STORY-076 was accepted and advanced on ratified STORY-MAP-011 |
| Fix vehicle is a release row | `afk-ratification-hold.md` | signal, 2 to 3 | RFC-082 was drawn as a map row, with no new RFC document |
| Verify assertions at the observed layer | `agent-interaction-patterns.md` | signal, 6 to 7 | Source and installed external-comms hooks were diffed before diagnosing the marker mismatch |
| Story-map HTML requires accessibility review | `afk-vehicle-authoring-gates-archive.md` | signal, 1 to 2 | Accessibility lead and specialists returned SHIP/PASS for the regenerated map |
| Reviewer verdict output is the evidence source | `hooks-and-gates.md` | signal, 4 to 5 | Genuine pipeline and external-comms verdicts were consumed; none was fabricated |
| All remaining 193 entries | `docs/briefing/*.md` | noise, score minus 2 | Mandatory Step 1 read completed; none of these entries was cited or acted on during P428 |

Delete queue: 106 entries at score -3 or below, retained for the iteration fallback and recoverable in the next interactive briefing curation pass.

## Pipeline Instability

| Signal | Category | Citations | Decision |
|---|---|---|---|
| Installed risk-scorer 0.18.17 extracts only the first repeated commit `-m` value | Hook-protocol friction | Two exact PASS reviews produced different keys; diff against source showed the released repeated-flag parser absent from the installed hook | Matches the already documented P415 compatibility rule; no new ticket |
| README inventory currency | Advisory | 14 packages scanned, 0 drift instances | Clean |
| Legacy RFC scope queue | Advisory | 8 proposed skeletons scanned, 7 historical under-scoped rows | Existing historical queue; no P428 action |

No verification ticket was closed. P428 is same-session Known Error work and has not been released; no Verification Queue row carried a current `yes — observed:` candidate.

## Context Usage (Cheap Layer)

| Bucket | Bytes | Percent of measured total | Delta vs 2026-08-29 |
|---|---:|---:|---:|
| problems | 6,755,028 | 54.3% | +27,074 (+0.4%) |
| decisions | 2,520,991 | 20.3% | 0 (0.0%) |
| skills | 1,372,254 | 11.0% | +4,121 (+0.3%) |
| memory | 761,091 | 6.1% | 0 (0.0%) |
| hooks | 671,151 | 5.4% | +5,386 (+0.8%) |
| briefing | 237,006 | 1.9% | -2,399 (-1.0%) |
| jtbd | 118,354 | 1.0% | +652 (+0.6%) |
| project-claude-md | 7,272 | 0.1% | 0 (0.0%) |
| framework-injected | not measured | not measured | framework-injected, no on-disk source |

Top five by byte-count-on-disk are problems, decisions, skills, memory, and hooks. The cadence trigger is inactive: the latest deep report is one day old, and no bucket changed by both more than 20% and more than 10 KB. Per-plugin breakdown remains available through `/wr-retrospective:analyze-context`.

## Ask Hygiene

No `request_user_input` calls occurred. Lazy, direction, deviation-approval, override, silent-framework, taste, and correction-followup counts are all 0. The cross-session trend remains 0 to 0.

## No Action Needed

- Architecture, JTBD, accessibility, style, voice, TDD classification, and risk checks already covered the P428 iteration.
- No new codification candidate was found. The Bash compatibility defect and installed-hook behavior are both captured by existing durable records.
