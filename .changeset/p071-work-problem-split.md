---
"@windyroad/itil": minor
---

feat(itil): P071 split slice 3 — /wr-itil:work-problem (+ manage-problem forwarder)

Phase 3 of P071's phased-landing plan: the "pick the highest-WSJF ticket and work it" user intent gets its own skill so `/` autocomplete surfaces it directly. Previously hidden behind `/wr-itil:manage-problem work` — a word-argument subcommand that Claude Code autocomplete does not surface.

CRITICAL naming distinction: `/wr-itil:work-problem` is **singular** — one ticket per invocation, interactive `AskUserQuestion` selection. It is distinct from the already-existing plural `/wr-itil:work-problems` (AFK batch orchestrator). The two names coexist per P071's acknowledged trade-off; the singular skill is the per-iteration execution unit the plural orchestrator delegates into via the Agent tool (P077 + ADR-032).

`/wr-itil:work-problem` (new skill):
- Frontmatter: `allowed-tools: Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion, Skill, Agent` — the selection tool surface plus delegation to `/wr-itil:review-problems` (refresh) and `/wr-itil:manage-problem <NNN>` (execution).
- Step 1 reads `docs/problems/README.md` if fresh (git-history staleness test per P031); delegates to `/wr-itil:review-problems` for the refresh if stale (P062 canonical-writer discipline — no fork).
- Step 2 fires `AskUserQuestion` selection: Recommended single top-WSJF option, or per-tied-ticket peer options for multi-way ties, with per-option rationale. Never prose "(a)/(b)/(c)" (P053 + ADR-013 Rule 1 regression guard).
- Step 3 delegates the execution to `/wr-itil:manage-problem <NNN>` via the Skill tool — thin-router discipline; the full investigate/transition/fix/release workflow stays on a single authoritative host.
- Step 4 fires the standard scope-change `AskUserQuestion` (Continue / Re-rank / Pick-different) on effort drift.
- Step 5 reports the outcome; does NOT loop automatically (that's the plural orchestrator's job).
- AFK branch (ADR-013 Rule 6): when invoked inside a `/wr-itil:work-problems` iteration, skips `AskUserQuestion` and executes the pre-selected ticket. Within-day tiebreak matches the orchestrator spec.

`/wr-itil:manage-problem` (deprecated-argument forwarder for `work`):
- Step 1 `work` argument now delegates to `/wr-itil:work-problem` via the Skill tool and emits the canonical systemMessage verbatim per ADR-010's pinned template: `"/wr-itil:manage-problem work is deprecated; use /wr-itil:work-problem directly. This forwarder will be removed in @windyroad/itil's next major version."`
- Forwarder does not re-implement the selection logic (thin-router per ADR-010).
- `deprecated-arguments: true` frontmatter flag already present from slice 1; no change.

Tests (ADR-037 contract-assertion pattern):
- `packages/itil/skills/work-problem/test/work-problem-contract.bats` — 19 assertions covering: frontmatter (name singular + regression guard against plural drift; description names pick/highest-WSJF + singular distinction; allowed-tools AskUserQuestion + Skill); singular-vs-plural naming-distinction documentation; delegation to `/wr-itil:manage-problem` (anti-fork); defer-to-`/wr-itil:review-problems` for cache refresh (P062 ownership); git-history freshness test (P031); `AskUserQuestion` selection prompt fires (ADR-013 Rule 1); prose-selection fallback forbidden (P053); AFK branch documented (Rule 6); scope-expansion 3-option shape; one-ticket-per-invocation singular contract; no `deprecated-arguments: true` flag on clean-split skill; no word-argument subcommand branching regression; P071 + ADR-010 + P077 + ADR-032 traceability citations.
- `packages/itil/skills/manage-problem/test/manage-problem-work-forwarder.bats` — 5 assertions covering: forwarder targets `/wr-itil:work-problem` (singular); singular-vs-plural name-collision guard; canonical deprecation notice emission; no inline re-implementation; parser-line pattern matches slice-1 + slice-2 shape.

Cross-references:
- P071 (docs/problems/071-*.open.md) — originating ticket; phased plan's slice 3.
- ADR-010 amended (Skill Granularity section) — canonical split-naming + forwarder contract.
- ADR-013 Rule 1 — structured user interaction; Rule 6 — AFK fallback.
- ADR-014 — governance skills commit their own work; delegated manage-problem owns per-ticket commits.
- ADR-032 + P077 — plural AFK orchestrator delegates iterations via Agent tool; this singular skill is the canonical execution unit.
- P031 — git-history freshness test; P062 — review-problems canonical README cache writer.
- P053 + ADR-013 Rule 1 — no prose-selection fallback.
