---
status: proposed
rfc-id: promptfoo-agent-prose-verdict-eval-harness
reported: 2026-05-28
decision-makers: [Tom Howard]
problems: [P324, P012]
adrs: [ADR-075, ADR-052, ADR-005, ADR-037]
jtbd: []
stories: []
---

# RFC-012: Build the promptfoo agent-prose AND SKILL-prose verdict eval harness

**Status**: proposed
**Reported**: 2026-05-28 (agent-prose scope) · **Amended**: 2026-06-02 (SKILL-prose scope extension per ADR-075 amendment of same date)
**Problems**: P324 (agent-prose harness gap) · P012 (SKILL-prose harness gap — closes on first SKILL eval landing)
**ADRs**: ADR-075 (the adoption decision — promptfoo, per-package configs, two-tier cadence; amended 2026-06-02 to extend scope to SKILL prose), ADR-052 (amended — Surface-2 narrowing for both agent-prose AND SKILL-prose verdicts), ADR-005 (amended — agent-testing lane), ADR-037 (superseded 2026-05-03 by ADR-052; supersession trail extended 2026-06-02 — harness gap closed)

## Summary

Build the behavioural test harness ADR-075 decided on: **promptfoo** for LLM-agent-prose verdicts (architect/jtbd/voice-tone/risk-scorer review agents). Provider = promptfoo's **exec provider wrapping `claude -p --system-prompt "$(cat agent.md)" "{{change}}"`** (Claude Code **subscription auth, no API key** — ADR-075 amendment 2026-05-28; proven in-session) + a fixture proposed-change as the user message; assert on the emitted verdict. **Two-tier** (user-confirmed cadence): **Tier A** (deterministic `contains`/`regex`/`is-json`) blocks the CI pipeline + a pre-commit/pre-push hook; **Tier B** (`llm-rubric`, N-sample pass^k) blocks the release pipeline. Per-package configs at `packages/<plugin>/agents/eval/`, excluded from the published tarball.

This retires the structural-test escape hatch for agent-prose verdicts (unblocking P290), drops the agent-verdict release class within appetite (R009 8/25 → ~4 once Tier B passes at release = the behavioural evidence), and graduates RFC-011 legitimately (no override).

## Driving problem trace

- **P324** — no behavioural harness for **agent-prose** verdicts → forced reliance on the ADR-052 structural-escape hatch (P081/P290-rejected) + hold-changeset/user-override on every agent-verdict release. This RFC builds the harness that closes that root (S1–S5).
- **P012** (amended 2026-06-02) — no behavioural harness for **SKILL-prose** surfaces → same structural-escape pattern propagated to SKILL.md prose (e.g. P330's `tdd-review: structural-permitted` bats backstop deferring to Investigation Task #3 for the behavioural retrofit). ADR-037 (the original P012-driven decision) was superseded 2026-05-03 by ADR-052; its named-harness-gap deferral via skill-creator reassessment triggers now closes on the first SKILL eval landing under S6 below. **P012 closes when S6 lands.**

## Scope

Build the harness per ADR-075 — **both agent-prose AND SKILL-prose surfaces** (SKILL-prose scope added 2026-06-02 per ADR-075 amendment of same date). In scope: promptfoo adoption + the per-package eval shape (agents/eval/ for agent prose, skills/<skill>/eval/ for SKILL prose) + Tier-A/Tier-B wiring + retiring the agent-prose AND SKILL-prose structural bats. Out of scope: re-deciding the tool/cadence/location (settled in ADR-075 + its 2026-06-02 amendment). Note (corrected 2026-05-28): the eval is **driveable via `claude -p` subscription auth — no API key** (the manual two-fixture proof ran in-session and already graduated RFC-011 on ADR-061 Rule 4 evidence). CI/release uses `CLAUDE_CODE_OAUTH_TOKEN` (subscription OAuth), the local pre-push hook uses the dev's own session. **SKILL evals use `--append-system-prompt` (not `--system-prompt`)** to preserve harness session context for skill-graph traversal (per ADR-075 Amendment 2026-06-02).

## Tasks

- [ ] **S1 — eval primitive (jtbd first slice)**: promptfoo as a root devDependency; `packages/jtbd/agents/eval/` with a promptfooconfig (exec provider wrapping `claude -p --system-prompt`, subscription auth), fixtures (a change citing unratified `developer`/`JTBD-001` → expect `[Unratified Dependency]`; a change citing a ratified artifact → expect PASS/silent), and **Tier A** deterministic assertions on the verdict token. `files`-field excludes the eval dir from the tarball. Validate config structure (`promptfoo validate`).
- [ ] **S2 — Tier A wiring**: root `test`-adjacent script to run all `packages/*/agents/eval/` Tier-A configs; add to `ci.yml`; add a pre-commit/pre-push hook (Tier A is secret-free + deterministic, so it gates locally + every PR).
- [ ] **S3 — Tier B + release gate**: add `llm-rubric` assertions (right artifact, right reason, no over-fire) with N-sample pass^k; wire into the **release pipeline** as a blocking gate; provision `CLAUDE_CODE_OAUTH_TOKEN` (subscription OAuth via `claude setup-token`), NOT `ANTHROPIC_API_KEY`, as the release-pipeline CI secret (fork-PR exposure avoided by release-gating, not PR-gating, Tier B; local pre-push needs no secret).
- [ ] **S4 — retire structural escape hatch (P290)**: replace the `tdd-review: structural-permitted` bats for the jtbd `[Unratified Dependency]` (RFC-011) + architect (RFC-010) verdicts with their promptfoo evals; record the ADR-052 Surface-2 narrowing; advance P290.
- [ ] **S5 — graduate RFC-011**: once the jtbd verdict's **Tier B passes at release**, that IS the R009 behavioural evidence (ADR-061 Rule 4) — RFC-011's changeset graduates within appetite, no user-override. Back-fill the same for RFC-010.
- [x] **S6 — SKILL-surface first slice (manage-problem)** *(added 2026-06-02 — P012 closure)*: promptfoo at root (`devDependencies`); `packages/itil/skills/manage-problem/eval/promptfooconfig.yaml` with exec provider wrapping `claude -p --append-system-prompt "$(cat ../SKILL.md)" "$PROMPT"`; fixture exercises the **P330 Option B Release-vehicle-seed behaviour** (asserts the SKILL emits `**Release vehicle**: .changeset/<name>.md` into the `.known-error.md` ticket body BEFORE the `git mv` to `.verifying.md`). **Tier A** deterministic regex/contains assertions on the emitted explanation; `--append-system-prompt` (not `--system-prompt`) preserves harness session context for skill-graph traversal. Per-plugin `.npmignore` at `packages/itil/` excludes `skills/*/eval/` from the published tarball (npm `files` field allowlist denied at this granularity). Root `package.json` `test` script glob extends to `packages/*/skills/*/eval/` (Tier A only; Tier B remains release-gated). **Closes P012** (skill testing harness scope undefined) — the harness gap ADR-037 deferred via skill-creator reassessment triggers now exists, identical in shape to the agent-prose harness.

## Commits

(maintained automatically — RFC trailer hook per ADR-060 Phase 1 item 12)

## Related

- **P324** — driving problem. **ADR-075** — the adoption decision this builds.
- **P290** — remove the structural escape hatch; unblocked by S4. **P012 / P176** — master harness + agent-side gap this fills. **P081** — structural tests wasteful.
- **RFC-011** (jtbd surface-3) + **RFC-010** (architect surface-3) — the two verdicts whose structural bats S4 retires; RFC-011 graduates at S5.
- **R009** — the 8/25 agent-prose residual class this harness reduces.

(captured via /wr-itil:capture-rfc; design settled in ADR-075. Advance via /wr-itil:manage-rfc.)
