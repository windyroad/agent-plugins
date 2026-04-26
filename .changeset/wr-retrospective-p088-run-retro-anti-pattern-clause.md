---
"@windyroad/retrospective": patch
---

P088: run-retro SKILL.md — add "Never invoke as a background agent" anti-pattern clause; ADR-032 defers `capture-retro` sibling pending context-marshalling resolution.

Settles the user direction (2026-04-21) on P088's three in-iter scope items: (a) ADR-032 amendment marks `/wr-retrospective:capture-retro` as deferred at both enumeration sites (initial three-sibling list + "New background siblings" list) with cross-reference to P088; (b) `packages/retrospective/skills/run-retro/SKILL.md` gains a "When to use" preamble naming the supported invocation surfaces (foreground `/wr-retrospective:run-retro` + `claude -p` subprocess per P086) and an anti-pattern clause forbidding `Agent(run_in_background: true)` invocation; (c) P086 ticket file gains a settlement note clarifying retro-inside-`claude -p`-subprocess remains correct and distinct from the deferred background-agent surface. Item (d) (extending run-retro with a session-log parser) is OUT OF SCOPE per ticket hedge.

- New behavioural-contract bats fixture `packages/retrospective/skills/run-retro/test/run-retro-anti-pattern-clause.bats` — six structural assertions on the SKILL.md anti-pattern clause (presence, P088 driver citation, supported-surface enumeration, deferred-surface explicit naming, preamble placement, ADR-032 cross-reference). Documents the structural-with-fallback-note path per architect verdict (ADR-037 permitted exception); P081 follow-up tracks the behavioural-test infrastructure (synthetic subagent surface) that would replace structural assertions once a subagent-mock harness exists.
- ADR-032 amendment is **minimal** per architect verdict: only the in-scope three-sibling enumeration sites are touched. Background-capture pattern wording stays unchanged because the pattern still works for `capture-problem` and `capture-adr` (their inputs are self-contained aside payloads). The retro-context-layer taxonomy ADR is deliberately deferred — landing taxonomy prose without that ADR pre-empts a design decision P088's Investigation Tasks explicitly leave open.

Closes P088 → Verification Pending.
