# Session Retrospective — 2026-05-30 work-problems iter 7 (P281)

Scope: AFK orchestrator iter 7 closed the capture-problem-specific sub-shape of P281 (SKILL.md template-refresh) and captured the sibling-SKILL drift as descendant P329.

## Briefing Changes
- Added: none (no new generalisable learning this iter — P281 fix is a literal correction to a ratified ADR-031 contract, already covered by the existing P317 published-path-class learning in `docs/briefing/hooks-and-gates.md` and the SKILL-authoring discipline learnings already present).
- Removed: none.
- Updated: none.
- README index refreshed: none.

## Signal-vs-Noise Pass (P105)

Skipped per AFK-iter scope — the iter's tool-call activity cited 0 briefing entries (selection was driven by the orchestrator's task prompt, not briefing signals). Decay (-1) applies to all entries this cycle but classification + persistence is deferred to the next interactive retro that touches more briefing entries — applying -1 decay alone over a narrow iter would noisy-classify entries that simply weren't relevant to the iter's scope. Same approach as iter 4 / iter 5 / iter 6 ask-hygiene siblings.

## Problems Created/Updated
- **P281** (`docs/problems/known-error/281-capture-problem-skill-template-references-pre-adr-031-flat-path-shape.md`): Status Open → Known Error. RCA confirmed (SKILL.md template lines 188/246/253 carried the flat shape); capture-problem-specific sub-shape fix shipped. Sibling-SKILL drift (manage-problem Step 4, review-problems, transition-problem(s), reconcile-readme, capture-rfc) deferred to descendant P329.
- **P329** (`docs/problems/open/329-sibling-skill-template-drift-pre-adr-031-flat-path-shape.md`): created. Captures the sibling-SKILL drift naming 6 specific files + line numbers + same architect/JTBD-302 alignment as P281.

## Verification Candidates

(No `.verifying.md` tickets were exercised by this iter's tool-call activity — the iter's scope was narrow to capture-problem SKILL.md + paired bats + ticket lifecycle. The 109 `.verifying.md` tickets in the queue are not surfaceable from this iter's evidence.)

## Pipeline Instability

(Step 2b detected no new pipeline-level friction this iter. The P119 hook firing on the descendant ticket Write was expected behaviour — the hook protects against unduplicated ticket creation, and the documented mitigation (`wr-itil-mark-create-gate` shim) worked as designed.)

**README inventory currency**: clean (13 packages, 0 drift instances).

**Briefing budgets**: 4 OVERS (none MUST_SPLIT, all between 1.04× and 1.28× threshold):
- `docs/briefing/governance-workflow-archive.md` — 6551 / 5120 (1.28×)
- `docs/briefing/governance-workflow.md` — 5839 / 5120 (1.14×)
- `docs/briefing/hooks-and-gates-archive.md` — 5429 / 5120 (1.06×)
- `docs/briefing/releases-and-ci.md` — 6156 / 5120 (1.20×)

Surfaced as Topic File Rotation Candidates below (deferred this iter — outside the narrow P281 scope; archive-file overflow suggests 2nd-tier archive rotation may be warranted as a separate ticket).

## Topic File Rotation Candidates

| Topic file | Bytes | Threshold | Proposed rotation | Decision |
|------------|-------|-----------|-------------------|----------|
| `docs/briefing/governance-workflow-archive.md` | 6551 | 5120 | split-by-date (2nd-tier archive) | flagged (AFK iter — out of scope this iter; archive-overflow may warrant new ticket) |
| `docs/briefing/governance-workflow.md` | 5839 | 5120 | split-by-date (safe default) | flagged (AFK iter — out of scope) |
| `docs/briefing/hooks-and-gates-archive.md` | 5429 | 5120 | split-by-date (2nd-tier archive) | flagged (AFK iter — out of scope this iter; archive-overflow may warrant new ticket) |
| `docs/briefing/releases-and-ci.md` | 6156 | 5120 | split-by-date (safe default) | flagged (AFK iter — out of scope) |

## Ask Hygiene (P135 Phase 5 / ADR-044)

Trail file: `docs/retros/2026-05-30-work-problems-iter7-p281-ask-hygiene.md`.

**Lazy count: 0** — the orchestrator's AFK-iter constraint forbids mid-loop AskUserQuestion (P135 / ADR-044). All decisions framework-resolved or pre-pinned by the orchestrator's selection prompt.

## Codification Candidates

(No codification candidates this iter — the P281 fix is a literal correction to an existing SKILL.md template against a ratified ADR, not a new pattern requiring codification. The architect's flagged "agent inference vs literal SKILL template precedence" NEW-ADR candidate is mentioned in P329's Related section as a sibling-ticket follow-on; surfaced for direction-class queueing in this iter's outstanding_questions.)

## No Action Needed
- The "git mv + Edit" interaction (re-stage required after Edit) — already captured in `MEMORY.md` briefing entries and the project briefing critical-points roll-up.
- The P119 create-gate hook firing on the descendant ticket Write — expected behaviour, documented in capture-problem SKILL.md Step 2 + ADR-049 PATH shim.
- The external-comms gates (risk + voice-tone) on the changeset draft — expected behaviour per P073 + RISK-POLICY.md; both passed after a minor scrub of named third-party adopter reference.
