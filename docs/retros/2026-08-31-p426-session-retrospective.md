# Session Retrospective - P426 first-match review heuristic

## Briefing Changes

- Added one Promptfoo execution learning: invoke the installed entrypoint with the Node binary matching the native dependency ABI when `npx` selects a different runtime.
- Added one external-communications gate learning: a Codex changeset edit can be keyed to the edit payload rather than the normalized changeset body, so the governed Changesets CLI is the reliable recovery after a reducing risk assessment.
- Scanned the indexed briefing tree. The P426 workflow exercised the ratified-map release-row contract, behavioural agent evaluation, package dry-run, external-communications marker recovery, and path-scoped staging. No Critical Points entry changed and no unrelated briefing entry was removed under the P426-only scope.

## Signal-vs-Noise Pass

| Entry | Topic file | Classification | Citation |
|-------|------------|----------------|----------|
| Ratified map approves the story | `afk-ratification-hold.md` | signal | Confirmed STORY-MAP-011 allowed RFC-084 and STORY-078 to carry the P426 implementation. |
| Fix vehicle is a release row | `afk-ratification-hold.md` | signal | RFC-084 remained a row on STORY-MAP-011; the unconfirmed legacy RFC-048 document was not used. |
| Story-map accessibility gate | `afk-vehicle-authoring-gates-archive.md` | signal | Accessibility review, keyboard smoke, and 55 renderer tests covered the regenerated row. |
| Reviewer marker non-persistence | `external-comms-gate.md` | signal | Completed Codex reviewers returned PASS while the changeset edit gate still lacked a usable marker. |
| Promptfoo agent-prose execution | `promptfoo-eval-authoring.md` | signal | The focused P426 suite passed 2/2 only after binding Promptfoo to the Node 24 entrypoint that matched `better-sqlite3`. |
| Package eval exclusion | `promptfoo-eval-authoring-archive.md` | signal | The architect package dry-run included `agents/agent.md` and excluded `agents/eval/`. |
| Remaining entries | indexed `docs/briefing/*.md` topics | noise | The mandatory topic-tree read completed; these entries were not cited or acted on during P426. |

**Critical Points changes**: none.

## Pipeline Instability

| Signal | Category | Citations | Decision |
|--------|----------|-----------|----------|
| `npx promptfoo eval` selected Node 26 while the installed native module was built for Node 24 | Tooling instability | Node module 147 versus 137 failure; direct Node 24 Promptfoo entrypoint completed 2/2 | Recorded in the briefing; no P426 product defect. |
| Codex changeset edit remained denied after both external-communications reviewers passed | Hook-protocol friction | Reviewed summary, full patch, and replacement line all returned PASS; governed Changesets CLI succeeded after a 4/25 reducing assessment | New observation queued for human review; no new problem created because this iteration was limited to P426. |
| README inventory currency | Advisory | 14 packages scanned, 0 drift instances | Clean. |
| Legacy RFC scope queue | Advisory | 8 proposed skeletons scanned, 7 historical under-scoped rows | Existing closed population; no P426 action. |

## Context Usage - Cheap Layer

| Bucket | Bytes | Percent of measured total | Delta vs 2026-08-29 |
|--------|------:|--------------------------:|--------------------:|
| problems | 6,758,700 | 54.3% | +30,746 (+0.5%) |
| decisions | 2,520,991 | 20.2% | 0 (0.0%) |
| skills | 1,374,322 | 11.0% | +6,189 (+0.5%) |
| memory | 761,091 | 6.1% | 0 (0.0%) |
| hooks | 671,151 | 5.4% | +5,386 (+0.8%) |
| briefing | 239,286 | 1.9% | -119 (-0.0%) |
| jtbd | 118,704 | 1.0% | +1,002 (+0.9%) |
| project-claude-md | 7,272 | 0.1% | 0 (0.0%) |
| framework-injected | not measured | not measured | framework-injected, no on-disk source |

Top five by byte-count-on-disk are problems, decisions, skills, memory, and hooks. The cadence trigger is inactive: the latest deep report is two days old and no bucket changed by both more than 20% and more than 10 KB. Per-plugin breakdown remains available through `/wr-retrospective:analyze-context`.

## Ask Hygiene

No `request_user_input` calls occurred. Lazy, direction, deviation-approval, override, silent-framework, taste, and correction-followup counts are all 0. The persisted trail is `docs/retros/2026-08-31-p426-ask-hygiene.md`.

## No Action Needed

- P426 remains Known Error until the minor package release is published and verified; this iteration did not push or release.
- The two user-owned outbound-response files remained modified and unstaged throughout the iteration.
