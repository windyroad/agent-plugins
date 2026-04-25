---
"@windyroad/itil": patch
---

`/wr-itil:report-upstream` gains Step 4b dedup + Step 5c comment path (P070): close the two duplication windows that were the skill's most externally-visible failure mode. Step 4b.1 own re-run check greps the local ticket for an existing `## Reported Upstream` URL and halts-and-surfaces if present. Step 4b.2 third-party search uses `gh issue list --repo <upstream> --search "<keywords>" --state all --json ... --limit 10` as a cheap pre-filter, then performs an inline LLM semantic match against each candidate's body via `gh issue view <n> --json body,title` (no subagent dispatch — per Direction decision 2026-04-21, the gh-search prefilter trims input to ~5-10 candidates which keeps the inline check affordable). Step 5c comment path lands cross-references via `gh issue comment <n>` when a dedup match is selected, and the local ticket records `Disclosure path: commented-on-existing-issue <URL>` in `## Reported Upstream` rather than `public issue`.

**Modified files:**
- `packages/itil/skills/report-upstream/SKILL.md` — adds Step 4b (own re-run + third-party search branches), Step 5c (comment path), and extends Step 7 disclosure-path enumeration with `commented-on-existing-issue`.
- `docs/decisions/024-cross-project-problem-reporting-contract.proposed.md` — Decision Outcome adds Step 4b + Step 5c; Out-of-scope dedup bullet narrowed to residual `update-mode`; Confirmation criterion 2 gains the new bats coverage line; Related lists P070 as driver.
- `packages/itil/skills/report-upstream/test/report-upstream-contract.bats` — 9 new behavioural assertions (Step 4b presence, own-re-run detection language, third-party `gh issue list --search` language, Step 5c comment-path, AFK halt-and-save behaviour, disclosure-path enumeration); file 24/24 green.

**AFK behaviour (interim):** halt-and-save the drafted report to the local ticket's `## Drafted Upstream Report` section per ADR-013 Rule 6. The maintainer-annoyance risk evaluator that would gate auto-comment is **DEFERRED** to compose with `wr-risk-scorer:external-comms` per ADR-028 line 117 — keeps P070 effort at M and avoids cross-cutting work blocking on P064. When P064 lands, a follow-up bundling commit will wire the maintainer-annoyance evaluator + P064 leak gate together so the AFK auto-comment branch can fire at appetite.

**Architect verdict**: PASS x3 (overall shape, bats, ADR-024 amendment) — confirmed inline LLM check (no subagent) is the right scope and that maintainer-annoyance evaluator deferral is the right architectural call. **JTBD verdict**: PASS — JTBD-004 primary fit (cross-repo coordination protected from spam); JTBD-001 / JTBD-006 / JTBD-101 protected by halt-and-surface fallback. **Risk**: 2/25 Very Low; reduces silent-duplicate risk on the report-upstream surface.

P070 (Open → Verification Pending). Verification path: exercise the skill twice against the same upstream + local ticket (4b.1 should halt on second run); exercise against an upstream with overlapping existing issues (4b.2 should offer comment path or halt-and-save in AFK).
