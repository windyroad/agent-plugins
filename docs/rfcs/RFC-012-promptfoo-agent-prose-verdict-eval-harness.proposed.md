---
status: proposed
rfc-id: promptfoo-agent-prose-verdict-eval-harness
reported: 2026-05-28
decision-makers: [Tom Howard]
problems: [P324]
adrs: [ADR-075, ADR-052, ADR-005]
jtbd: []
stories: []
---

# RFC-012: Build the promptfoo agent-prose verdict eval harness

**Status**: proposed
**Reported**: 2026-05-28
**Problems**: P324
**ADRs**: ADR-075 (the adoption decision — promptfoo, per-package configs, two-tier cadence), ADR-052 (amended — Surface-2 narrowing for agent-prose), ADR-005 (amended — agent-testing lane)

## Summary

Build the behavioural test harness ADR-075 decided on: **promptfoo** for LLM-agent-prose verdicts (architect/jtbd/voice-tone/risk-scorer review agents). Provider = promptfoo's Anthropic provider with each agent's `agent.md` as the `system` prompt + a fixture proposed-change as the user message; assert on the emitted verdict. **Two-tier** (user-confirmed cadence): **Tier A** (deterministic `contains`/`regex`/`is-json`) blocks the CI pipeline + a pre-commit/pre-push hook; **Tier B** (`llm-rubric`, N-sample pass^k) blocks the release pipeline. Per-package configs at `packages/<plugin>/agents/eval/`, excluded from the published tarball.

This retires the structural-test escape hatch for agent-prose verdicts (unblocking P290), drops the agent-verdict release class within appetite (R009 8/25 → ~4 once Tier B passes at release = the behavioural evidence), and graduates RFC-011 legitimately (no override).

## Driving problem trace

- **P324** — no behavioural harness for agent-prose verdicts → forced reliance on the ADR-052 structural-escape hatch (P081/P290-rejected) + hold-changeset/user-override on every agent-verdict release. This RFC builds the harness that closes that root.

## Scope

Build the harness per ADR-075. In scope: promptfoo adoption + the per-package eval shape + Tier-A/Tier-B wiring + retiring the agent-prose structural bats. Out of scope: re-deciding the tool/cadence/location (settled in ADR-075); the live eval run + RFC-011 graduation **require the CI environment with `ANTHROPIC_API_KEY`** and are not runnable in a keyless sandbox.

## Tasks

- [ ] **S1 — eval primitive (jtbd first slice)**: promptfoo as a root devDependency; `packages/jtbd/agents/eval/` with a promptfooconfig (Anthropic provider, `agent.md` as system prompt), fixtures (a change citing unratified `developer`/`JTBD-001` → expect `[Unratified Dependency]`; a change citing a ratified artifact → expect PASS/silent), and **Tier A** deterministic assertions on the verdict token. `files`-field excludes the eval dir from the tarball. Validate config structure (`promptfoo validate`).
- [ ] **S2 — Tier A wiring**: root `test`-adjacent script to run all `packages/*/agents/eval/` Tier-A configs; add to `ci.yml`; add a pre-commit/pre-push hook (Tier A is secret-free + deterministic, so it gates locally + every PR).
- [ ] **S3 — Tier B + release gate**: add `llm-rubric` assertions (right artifact, right reason, no over-fire) with N-sample pass^k; wire into the **release pipeline** as a blocking gate; provision `ANTHROPIC_API_KEY` as a release-pipeline CI secret (fork-PR exposure avoided by release-gating, not PR-gating, Tier B).
- [ ] **S4 — retire structural escape hatch (P290)**: replace the `tdd-review: structural-permitted` bats for the jtbd `[Unratified Dependency]` (RFC-011) + architect (RFC-010) verdicts with their promptfoo evals; record the ADR-052 Surface-2 narrowing; advance P290.
- [ ] **S5 — graduate RFC-011**: once the jtbd verdict's **Tier B passes at release**, that IS the R009 behavioural evidence (ADR-061 Rule 4) — RFC-011's changeset graduates within appetite, no user-override. Back-fill the same for RFC-010.

## Commits

(maintained automatically — RFC trailer hook per ADR-060 Phase 1 item 12)

## Related

- **P324** — driving problem. **ADR-075** — the adoption decision this builds.
- **P290** — remove the structural escape hatch; unblocked by S4. **P012 / P176** — master harness + agent-side gap this fills. **P081** — structural tests wasteful.
- **RFC-011** (jtbd surface-3) + **RFC-010** (architect surface-3) — the two verdicts whose structural bats S4 retires; RFC-011 graduates at S5.
- **R009** — the 8/25 agent-prose residual class this harness reduces.

(captured via /wr-itil:capture-rfc; design settled in ADR-075. Advance via /wr-itil:manage-rfc.)
