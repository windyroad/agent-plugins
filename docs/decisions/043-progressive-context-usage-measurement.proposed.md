---
status: "proposed"
human-oversight: confirmed
oversight-date: 2026-05-26
amended: 2026-06-08
amendment-driver: P295 — settles the Amendment 2026-05-26 follow-up. Combined trigger (calendar-elapse >14 days OR delta >20% any bucket since prior snapshot) auto-invokes the deep layer from run-retro Step 2c with a once-per-day guard (presence of `docs/retros/<TODAY>-context-analysis.md`). Prior amendment (2026-05-26, P283-prong-2-oversight): deep layer MUST have an automatic trigger, not on-demand-only (user direction 2026-05-26 — "it shouldn't rely on someone remembering"; the automatic-cadence principle). See "Amendment 2026-06-08" in Decision Outcome.
date: 2026-04-26
decision-makers: [tomhoward]
consulted: [wr-architect:agent, wr-jtbd:agent]
informed: [Windy Road plugin users, windyroad-claude-plugin adopters]
reassessment-date: 2026-07-26
---

# Progressive context-usage measurement and reporting for retrospective sessions

## Context and Problem Statement

Context-budget problems (`P091` Session-wide context budget — meta and its cluster `P095` / `P096` / `P097` / `P098` / `P099` / `P100`) are detected and addressed **reactively** — the user notices bloat, opens a ticket, the cluster audits a specific surface, fixes land per surface. There is no **proactive measurement** baked into the normal workflow. Each retro session ends without the assistant ever computing "where did the tokens go this session" and without suggesting "these files / hooks / skills ate the largest budget this session — consider trimming."

`P101` (`wr-retrospective has no context-usage analysis — opaque where session tokens are consumed; no guidance on what to trim`) makes this gap explicit. User direction 2026-04-22:

> *"context tends to bloat over time. It would be nice if the retrospective plugin could analyse where tokens are being consumed (maybe the same way that https://github.com/getagentseal/codeburn does) and suggest improvements or flag problems, either as part of the run-retro skill or as part of a new skill. I'd prefer it to be part of run-retro, but if it's really heavy and consumes lots of tokens to execute, then I don't want to do it every retro as that would be its own bloat."*

The user's delivery-mode preference is **two-layer**: a cheap layer integrated into `run-retro` that runs every retro, plus a deep on-demand layer for richer analysis. Expensive-always-on is explicitly rejected ("the analyzer must not itself be bloat").

`ADR-038` (Progressive disclosure + once-per-session budget for `UserPromptSubmit` governance prose) and `ADR-040` (Session-start briefing surface) are the precedent surfaces — each addresses **one** P091-cluster surface (UserPromptSubmit hook prose; SessionStart consumer surface). `P101`'s measurement layer sits **one level out** — it is the observability layer that **consumes** what every other progressive-disclosure ADR individually budgets. ADR-038 explicitly defers `P096` and `P097` to sibling ADRs in its "Out of scope" section; ADR-040 is itself a sibling rather than an extension. The same pattern applies here: P101's measurement+reporting policy is a sibling, not an extension.

## Decision Drivers

- **JTBD-001** (Enforce Governance Without Slowing Down) — measurement is the meta-governance loop catching bloat before it degrades the gate-firing budget. Cheap layer's `< 5%` session budget cap operationalises "without the overhead."
- **JTBD-006** (Progress the Backlog While I'm Away) — AFK loops are the pathological case for per-turn context cost (every iteration pays the preamble); the delta-from-last-retro pointer extends visibility from problem-progress to context-cost-progress for the same persona.
- **JTBD-005** (Invoke Governance Assessments On Demand) — the deep-layer skill `/wr-retrospective:analyze-context` is precisely the shape JTBD-005 prescribes: discoverable via `/` autocomplete, invokable without leaving task context, structured output.
- **ADR-026** (Agent output grounding — cite + persist + uncertainty) — both layers' suggestions and findings MUST cite specific surfaces, MUST persist evidence in re-readable form, MUST mark ungrounded fields with explicit sentinels. Forbids qualitative-only phrases ("load is negligible", "small change").
- **ADR-038** (Progressive disclosure for UserPromptSubmit governance prose) — sibling ADR. Its tiered-disclosure pattern + per-row byte budget + advisory-script-plus-bats-fixture triplet is the precedent shape this ADR mirrors.
- **ADR-040** (Session-start briefing surface) — sibling ADR. Its Tier 1 / Tier 2 / Tier 3 budget envelope is the parent measurement infrastructure the cheap layer aggregates over for the briefing surface; its HTML-comment-trailer pattern is the precedent for snapshot persistence.
- **ADR-014** (Governance skills commit their own work) — both layers commit their own output per the `work → score → commit` ordering. New commit-message convention `docs(retros): context analysis YYYY-MM-DD` for the deep-layer artefact, amended into ADR-014's Commit Message Convention table.
- **ADR-013** Rule 6 (AFK fallback) — both layers must have explicit non-interactive behaviour. Cheap layer is silent in AFK; the deep layer is silent (never invokes `AskUserQuestion`) and auto-fires from Step 2c when the combined trigger holds (calendar-elapse >14 days OR delta >20% any bucket since prior snapshot, once-per-day guard via `docs/retros/<TODAY>-context-analysis.md` presence) — see Amendment 2026-06-08. The deep layer remains user-invokable on demand via `/wr-retrospective:analyze-context`.
- **ADR-009** (Gate marker lifecycle) — does NOT apply. Snapshot persistence uses HTML-comment trailers in the deep layer's report file, not `/tmp` markers. ADR-009's TTL+drift primitive is purpose-built for clearance-marker semantics and would over-engineer a session-frequency snapshot.
- **`P091`** (parent meta — Session-wide context budget) — this ADR closes P091's "Build a measurement harness" investigation task as subsumed by the broader analyzer+suggestion design.
- **`P099`** (briefing bloat) and **`P105`** (signal-vs-noise pass) — sibling measurement surfaces; the cheap layer aggregates over them rather than re-measuring.

## Considered Options

1. **Two-layer (chosen)** — cheap measurement integrated into `run-retro` Step 2c (every retro, < 5% budget) + deep analyzer skill `/wr-retrospective:analyze-context` (on demand, full per-turn attribution + suggestions). Fail-open: if cheap layer's static budget proof becomes invalid, disable cheap layer and route everything to on-demand.
2. **Cheap-only embedded in `run-retro`** — single layer, every retro. Rejected: insufficient depth for actionable suggestions; per-turn attribution requires `.jsonl` parse cost the cheap layer cannot absorb. Defaults users to "see the totals; trim by guesswork."
3. **Deep-only on-demand skill** — single layer, user-invoked. Rejected by user direction: *"I'd prefer it to be part of run-retro"* — proactive surfacing every session is the load-bearing affordance. Without the cheap layer, bloat re-emerges between manual invocations.
4. **Expensive-always-on integrated into `run-retro`** — single layer, every retro, full deep heuristics. Rejected by user direction: *"if it's really heavy and consumes lots of tokens to execute, then I don't want to do it every retro as that would be its own bloat."*

## Decision Outcome

**Chosen: Option 1 — two-layer.** Cheap layer (Step 2c in `run-retro`) + deep layer (new `/wr-retrospective:analyze-context` skill). Fail-open guard: if the cheap layer's static budget proof becomes invalid (e.g. byte-count operations grow beyond `< 5%` of session budget), the cheap layer disables itself and Step 2c emits a one-line pointer to the deep layer.

> **Amendment 2026-05-26 — deep layer MUST be automatically triggered (human-oversight correction, P283 prong 2).** The deep layer as originally specified is **on-demand only** (`/wr-retrospective:analyze-context` invoked by the user). User direction 2026-05-26: *"We need a way to automatically trigger the deep layer. It shouldn't rely on someone remembering."* This realises the automatic-cadence principle (a maintenance action with no automatic cadence never happens — the analyzer that's never run is no analyzer). **Requirement:** the deep layer MUST have an automatic trigger, not on-demand-only. On-demand invocation remains available but is no longer the *sole* path. Settlement deferred to follow-up ticket P295 — see Amendment 2026-06-08 below.

> **Amendment 2026-06-08 — combined-trigger settlement (P295 settles the Amendment 2026-05-26 follow-up).** User direction 2026-05-25: *"the second layer should happen proactively as well with less frequency than the first layer. Generally speaking, if there is no automatic cadence, it does not happen."* The deep layer auto-fires from `run-retro` Step 2c (cheap layer) when the **combined whichever-comes-first trigger** holds:
>
> 1. **Calendar-elapse trigger** — the most recent `docs/retros/*-context-analysis.md` (lex-desc sort on date in filename) is **older than 14 days**.
> 2. **Delta-breach trigger** — any bucket's byte total has BOTH changed by **more than 20%** versus the prior snapshot (HTML-comment trailer of the most recent deep-layer report) AND changed by more than the **absolute minimum-delta floor of 10 KB** (`|current − prior| > 10240` bytes). Both gates are required (Amendment 2026-06-17, P372 — see sub-note below).
>
> **Once-per-day guard**: if `docs/retros/<TODAY>-context-analysis.md` already exists, the trigger is treated as already-satisfied and auto-fire is skipped this retro. No new persistent state file is needed — the snapshot artefact itself is the state (mirrors ADR-009's explicit non-use in this ADR — see Decision Drivers; the snapshot persistence is via the HTML-comment trailer, not via `/tmp` markers).
>
> **Threshold grounding (ADR-026 line 92)**: the chosen values (`>14 days`, `>20%`, `>10 KB`) are `not estimated — chosen as initial values, reassess after 6 months of cross-project use` per ADR-026's no-prior-data sentinel. The 14-day cadence aligns with the ADR-040 session-start refresh envelope (≥2 retro cycles between deep runs in typical solo-developer cadence); the 20% delta-breach threshold aligns with ADR-040's Tier 3 briefing-budget breach grain; the 10 KB absolute floor is the same order as the cheap-layer report envelope (`CONTEXT_BUDGET_MAX_BYTES` default 10240, the 5% / 200K cap) — a delta below it cannot be a dominant context cost. All three are *initial values*, subject to reassessment per the Reassessment Criteria below. The 10 KB floor is **not** calibrated from observed data — the P372 example (`project-claude-md` 4277→5897 = +1620 bytes) illustrates the failure mode the floor closes, but is not the source of the value.
>
> **Behaviour when triggered**: Step 2c invokes `/wr-retrospective:analyze-context` via the Skill tool (silent — the deep layer never invokes `AskUserQuestion`; it writes a committed report at `docs/retros/<TODAY>-context-analysis.md`). Identical contract in interactive and AFK modes (per ADR-013 Rule 6 + ADR-044 framework-resolution boundary — auto-invocation is framework-resolved mechanical action, not user-decided).
>
> **"Analyzer must not itself be bloat" preservation**: the cheap layer's static-budget proof (~2.5 KB / retro) is unaffected — the auto-invocation acts only on the trigger condition the cheap layer was already computing. The deep layer fires at most once per day (once-per-day guard) and only when the trigger condition holds — far less than every retro, satisfying the original "less frequency than the cheap layer" user direction.
>
> **Sub-note — Amendment 2026-06-17 (P372 absolute-floor gate on the delta-breach axis).** The delta-breach axis as settled above (`>20%` change in any bucket) lacked an absolute-byte floor, so it fired the deep layer on negligible absolute deltas to *small* buckets: a `project-claude-md` or `jtbd` bucket trips 20% on a sub-2 KB edit (observed P314 iter 3, 2026-06-17 — `project-claude-md` grew 4277→5897 bytes = +37.9% on a single CLAUDE.md MANDATORY-block addition, a +1620-byte change). The percentage tripped though the absolute delta does not warrant the deep layer's committed-report + subagent cost. **Fix**: the delta-breach trigger now requires BOTH the `>20%` relative gate AND a `>10 KB` (`>10240` bytes) absolute gate (`|current − prior|`). This is a **noise-suppression gate on the existing delta axis**, not a new firing axis. The capture-time framing also raised the inverse concern ("a large-but-stable bucket — e.g. the multi-MB `docs/problems` corpus — never re-fires despite being the dominant cost"); that concern is **already covered by the calendar-elapse axis** (≥14 days re-fires every bucket regardless of delta), so no separate third firing axis is added — adding one would only *increase* fires and cannot fix an over-fire. The combined trigger remains "whichever-comes-first" across the two axes; the delta axis simply gains a floor. Surfaces updated in lockstep: `run-retro` Step 2c step 4 (Delta-breach bullet + the "trigger does NOT hold" note), `analyze-context/SKILL.md` (3 trigger-description lines), and the paired promptfoo eval case (`run-retro/eval/promptfooconfig.yaml` Step 2c contract). Floor grounded as an initial value above.

### Scope

**In scope (this ADR):**

- `packages/retrospective/skills/run-retro/SKILL.md` — new Step 2c (cheap layer), placed between Step 2b (Pipeline-instability scan) and Step 3 (Update the briefing tree).
- `packages/retrospective/skills/analyze-context/SKILL.md` — new skill (deep layer), discoverable as `/wr-retrospective:analyze-context`.
- `packages/retrospective/scripts/measure-context-budget.sh` — read-only diagnostic script that reports per-source bucket byte totals. Mirrors `check-briefing-budgets.sh` shape (advisory, exit 0 always, machine-readable output, ≤150 bytes per row).
- `packages/retrospective/scripts/test/measure-context-budget.bats` — behavioural bats fixture per ADR-005 + ADR-037.
- `docs/retros/<date>-context-analysis.md` — deep-layer report artefact path. Directory created on first run (`mkdir -p`) by the deep skill.
- ADR-026 amendment — add `packages/retrospective/skills/analyze-context/SKILL.md` to the "Per-agent prompt amendments" target list (lines 94–101 in current ADR-026).
- ADR-014 amendment — add `docs(retros): context analysis YYYY-MM-DD` to the Commit Message Convention table (lines 110–123).

**Out of scope (follow-up tickets or future ADRs):**

- LLM-side `usage` token accounting beyond the deep layer's optional cross-check from `claude -p --output-format json` `.jsonl` logs. Full per-turn token attribution is a deep-layer feature only; the cheap layer reports byte-counts on disk.
- Cross-project measurement (aggregating bloat metrics across multiple adopter repositories). Single-project scope only this ADR.
- CI-time budget enforcement that fails the build on overflow. Both layers are advisory only; the budget is honour-system + bats drift checks per ADR-038's precedent.
- Automated trim suggestions that auto-apply (e.g. auto-rewrite an over-budget SKILL.md). Out of scope; suggestions are advisory and require user action.

### Measurement methodology

**Cheap layer — byte-counting on disk:**

- Bucket source surfaces (one row per bucket):
  - `hooks` — `wc -c` aggregate over `packages/*/hooks/**/*.sh` and any project-local `.claude/hooks/**/*.sh`.
  - `skills` — `wc -c` aggregate over `packages/*/skills/**/SKILL.md` and any project-local `.claude/skills/**/SKILL.md`.
  - `memory` — `wc -c` aggregate over user-owned memory (`~/.claude/projects/*/memory/*.md`); ungrounded if directory inaccessible.
  - `briefing` — `wc -c` aggregate over `docs/briefing/*.md` (single row; per-file detail composed via P099's `check-briefing-budgets.sh`; per-entry detail composed via P105's signal-vs-noise pass).
  - `decisions` — `wc -c` aggregate over `docs/decisions/*.md`.
  - `problems` — `wc -c` aggregate over `docs/problems/*.md` (cheap-layer view of the ticket inventory).
  - `jtbd` — `wc -c` aggregate over `docs/jtbd/**/*.md`.
  - `project-claude-md` — `wc -c` over `CLAUDE.md` (project-local).
  - `framework-injected` — sentinel value `not measured — framework-injected, no on-disk source` (per ADR-026 ungrounded-field rule). Covers `available-skills` listing, `subagent-types` listing, `deferred-tools` listing.
- Per-bucket attribution explicit when buckets aggregate cross-plugin (e.g. `hooks` row may decompose to `architect`, `jtbd`, `tdd`, `style-guide`, `voice-tone`, `risk-scorer`, `itil`, `retrospective` plugin contributions — surfaced when the deep layer runs; the cheap layer reports the aggregate only).
- Output shape: top-level `## Context Usage (Cheap Layer)` section in the retro summary (Step 5 — see SKILL.md Step 2c's reporting clause). One row per bucket: `<bucket>: <bytes> bytes (<percent of total>%)`. Top-5 offenders surfaced as a separate table.

**Deep layer — byte-count + `usage` aggregation + per-turn attribution:**

- Reuses the cheap layer's bucket totals as a baseline.
- Parses `${CLAUDE_PROJECT_DIR}/.afk-run-state/*.jsonl` (when present, AFK loops only) or invokes `claude -p --output-format json` against representative session log paths to extract `usage.{input,output,cache_creation,cache_read}_tokens` per turn.
- Per-turn attribution: maps each tool-call's input/output bytes to the bucket(s) the tool referenced (e.g. an Edit on `packages/itil/skills/manage-problem/SKILL.md` attributes to `skills/itil`).
- Per-plugin attribution: when the `hooks` or `skills` bucket dominates, decomposes by plugin (`packages/<plugin>/...`).
- Suggestion generation: per-bucket "trim candidate" output citing a specific surface and a comparable prior reclamation (e.g. *"P095 reclaimed ~120KB by once-per-session gating; this surface emits Z bytes per session — applying the same pattern would reclaim ~Y bytes"*). Suggestions MUST follow ADR-026 grounding — cite surface + cite comparable prior + emit explicit uncertainty when no prior exists.

**Frequency guard for cheap layer (static upper-bound, not recursive):**

- Step 2c reads `wc -c` aggregates over file lists — content is NOT loaded into LLM context (the script returns aggregate byte counts only). The briefing tree's content is already loaded by Step 1; Step 2c does not re-load it.
- Cheap-layer report output: one bucket row × ~10 buckets × ≤150 bytes/row + top-5 offenders × ≤150 bytes/row + a 200-byte preamble = ~2.5 KB ceiling, well under the 5% / 200K ≈ 10 KB session-budget envelope.
- **Static proof** that the cheap layer is within budget — no recursive measurement needed.
- **Defensive trip** (fail-open): if `measure-context-budget.sh` exits non-zero or the report exceeds the 10 KB ceiling at runtime, Step 2c emits a one-line "cheap layer disabled — invoke `/wr-retrospective:analyze-context` for context measurement" pointer and skips the bucket table. The trip is logged in the retro summary's Pipeline Instability section (Step 2b) so the regression is captured as a problem ticket candidate per the existing ticket-creation flow.

### Snapshot persistence — HTML-comment trailer in deep-layer report

Delta-from-last-retro requires comparing this retro's bucket totals to the prior measurement. ADR-026's grounding requirement forbids ephemeral storage (the snapshot must be re-readable by another agent in a future session). Three storage options were considered:

1. **HTML-comment trailer in `docs/retros/<date>-context-analysis.md` (chosen)** — committed artefact, citable in subsequent retros, mirrors the per-entry HTML-comment-block pattern in ADR-040 lines 99–104 and `run-retro` Step 1.5.
2. `docs/retros/.last-context-snapshot.json` (gitignored) — rejected: fails ADR-026's "persist" criterion; creates a hidden second source-of-truth.
3. `.claude/.context-snapshot` (per-session ephemeral) — rejected: fails persist; breaks delta-across-sessions.

Concrete trailer shape, mirroring ADR-040's signal-score precedent:

```markdown
<!--
context-snapshot:
  total-bytes: 178432
  hooks: 31200
  skills: 28100
  memory: 14000
  briefing: 5800
  decisions: 24800
  problems: 51000
  jtbd: 4400
  project-claude-md: 880
  framework-injected: not measured
  measurement-method: byte-count-on-disk
  measured-at: 2026-04-26T14:30:00Z
-->
```

Cheap layer reads the trailer of the most-recent `docs/retros/<date>-context-analysis.md` (sorted lex-desc on date) for the prior snapshot. **First-retro / no-prior path**: cheap layer reports `no prior snapshot — first measurement this project` per ADR-026's `not estimated — no prior data` sentinel. Deep layer writes a fresh trailer on every report.

Per the JTBD review's plugin-user / OSS-adopter affordance: when `docs/retros/` is absent (project has never run the deep layer), the cheap layer reports the bucket table without a delta column — never emits errors or warnings about missing prior data.

### Composition with sibling measurements (no double-counting)

- **`P099`** (briefing bloat — Tier 3 advisory `check-briefing-budgets.sh`) measures **per-topic-file** budget on `docs/briefing/<topic>.md`.
- **`P105`** (signal-vs-noise pass) measures **per-entry** signal scores on briefing entries.
- **This ADR** (cheap layer) measures **per-source-bucket** budget — `briefing` is a single row aggregating `wc -c` over `docs/briefing/*.md`.

The three measurements are at three different granularities and compose by hierarchy: cheap-layer total `briefing: 5800 bytes` is the sum of the per-file detail; the per-entry detail is drillable via P105. Deep layer cites P099 + P105 outputs as evidence sources for "where is briefing growing" attribution rather than re-measuring. This prevents drift where two scripts measure the same surface differently.

### Per-plugin attribution (plugin-developer affordance per JTBD review)

Plugin-developers iterating on a single plugin need to know whether *their* plugin's hook output is the offender, distinct from sibling plugins (per `docs/jtbd/plugin-developer/persona.md` line 16). The cheap layer's `hooks` and `skills` rows present an aggregate; the deep layer decomposes both by plugin (`packages/<plugin>/hooks/*` byte aggregates per plugin).

Per-plugin attribution is **deep-layer only** to keep the cheap layer's report under the static budget. Cheap-layer aggregate row carries a one-line affordance: *"per-plugin breakdown available in deep layer."*

### AFK / non-interactive behaviour (ADR-013 Rule 6)

- **Cheap layer (Step 2c)** — runs unconditionally in every retro, including AFK. Output lands in the retro summary; no `AskUserQuestion` fired. The combined-trigger branch (per Amendment 2026-06-08 — calendar-elapse >14 days OR delta >20% any bucket, once-per-day guard) auto-invokes the deep layer via the Skill tool when triggered; otherwise emits a one-line non-blocking note to the summary's "Context Usage" section. Never prompts the user.
- **Deep layer (`/wr-retrospective:analyze-context`)** — auto-fires from Step 2c when the combined trigger holds (silent, no `AskUserQuestion`; identical behaviour in interactive and AFK modes per Amendment 2026-06-08). Also remains user-invokable on demand. AFK orchestrators read the resulting `docs/retros/<TODAY>-context-analysis.md` report on iteration close; the user reviews on return.

### Suggestion grounding (ADR-026 amendment)

The new `analyze-context` skill is added to ADR-026's "Per-agent prompt amendments" target list (lines 94–101). Both layers' SKILL.md prose explicitly:

- Bans qualitative-only phrases per ADR-026 Confirmation line 148 (forbidden phrase list: `load is negligible`, `microseconds only`, `minimal`, `small change`, `trim X to reduce bloat` without comparable prior).
- Requires every suggestion to cite a comparable prior (e.g. P095 / P099 / P100 reclamation precedents) or emit `not estimated — no prior data` per ADR-026 line 90.
- Requires every top-N offender row to carry a concrete byte count + measurement-method citation.

### Commit-message convention (ADR-014 amendment)

ADR-014's Commit Message Convention table gains one row:

| Operation | Format | Example |
|-----------|--------|---------|
| Context analysis report | `docs(retros): context analysis YYYY-MM-DD` | `docs(retros): context analysis 2026-04-26` |

Skill-produced commits ride this convention. The deep skill stages the report file + (when newly created) `docs/retros/README.md` index alongside the report.

## Consequences

### Good

- Every session ends with a per-bucket context-usage summary in the retro report. Bloat detected at session-time, not after the user notices.
- Two-layer split honours user direction (cheap + deep) without compromising on coverage.
- AFK loops gain a cheap-layer summary in every iteration's retro summary — early-warning signal for context-bloat regressions across long-running orchestrators.
- ADR-026 grounding compliance from day one: the new skill is on the per-agent amendment list; bats fixtures pin the forbidden-qualitative-phrase ban.
- Pattern reusable for future measurement surfaces (per-plugin telemetry, per-tool latency) — the read-only-script + bats-fixture + ADR-budget-amendment triplet established by ADR-040 / P099 / this ADR is the documented shape.
- ADR-014 amendment closes the commit-message-convention gap for retro-produced artefacts.
- P091's investigation task ("Build a measurement harness") closes as subsumed; P101 transitions to Verification Pending on landing this ADR + implementation.

### Neutral

- The deep-layer report (`docs/retros/<date>-context-analysis.md`) is a new accumulator artefact in adopter projects. JTBD-002's audit-trail requirement absorbs the cost (`docs/jtbd/solo-developer/JTBD-002-ship-with-confidence.proposed.md` line 18 explicitly requires persistent governance evidence). Per-report budget is honour-system; future drift triggers a P099-style advisory script for `docs/retros/`.
- The cheap layer's report adds ~2.5 KB to every retro summary. Within static budget; visible to the user who can re-tune by editing `measure-context-budget.sh` thresholds if needed.
- HTML-comment-trailer snapshot is a new pattern in `docs/retros/`. Mirrors ADR-040's pattern in `docs/briefing/`; precedent already established in this repo.

### Bad

- **Cheap-layer false-confidence risk**: a budget-clean cheap layer could mask deep-layer issues (e.g. a single hook that emits 100 KB on every prompt would show as `hooks: 100KB` aggregate but the per-prompt re-emission is invisible without parsing the `.jsonl` log). Mitigation: cheap-layer report explicitly notes "per-turn attribution available in deep layer" so the user knows the cheap-layer aggregate is upper-bound, not per-turn.
- **Snapshot drift across project clones**: a fresh checkout of the repo has no prior snapshot until the first deep retro runs. Mitigation: cheap layer's `no prior snapshot — first measurement this project` sentinel is explicit, never silent.
- **Bats fixture maintenance**: every change to `measure-context-budget.sh` ripples through the bats fixture. Standard maintenance cost; mitigated by the same advisory shape `check-briefing-budgets.sh` already uses.
- **Framework-injected surfaces remain unmeasured**: `available-skills`, `subagent-types`, `deferred-tools` listings are emitted by the framework on every turn but cannot be byte-counted from the project filesystem. Sentinel `not measured — framework-injected` is explicit; future work would be an upstream contribution to the framework or an LLM-side `usage` calibration in the deep layer.

## Confirmation

Compliance is verified by:

1. **Source review:**
   - `packages/retrospective/skills/run-retro/SKILL.md` contains a Step 2c block named `Context-usage measurement (cheap layer, P101)`, placed between Step 2b and Step 3, citing this ADR + ADR-026.
   - `packages/retrospective/skills/analyze-context/SKILL.md` exists, citing this ADR + ADR-026 + ADR-014 + ADR-013 Rule 6.
   - `packages/retrospective/scripts/measure-context-budget.sh` exists, executable, mirrors `check-briefing-budgets.sh` shape (read-only, exit 0 always, machine-readable per-row output ≤150 bytes per ADR-038 progressive-disclosure budget, exit 2 on parse error).
   - `packages/retrospective/scripts/test/measure-context-budget.bats` exists; covers script-existence + executable + per-bucket output shape + missing-source ungrounded-sentinel + the `BRIEFING_TIER3_MAX_BYTES`-style `CONTEXT_BUDGET_MAX_BYTES` overrideable threshold.
   - `docs/decisions/026-agent-output-grounding.proposed.md` "Per-agent prompt amendments" list includes `packages/retrospective/skills/analyze-context/SKILL.md`.
   - `docs/decisions/014-governance-skills-commit-their-own-work.proposed.md` Commit Message Convention table includes the `docs(retros): context analysis YYYY-MM-DD` row.

2. **Tests (bats):**
   - `packages/retrospective/scripts/test/measure-context-budget.bats` — script behaviour (green).
   - `packages/retrospective/skills/run-retro/test/run-retro-context-usage-step-2c.bats` — Step 2c structural pin (Permitted Exception per ADR-005, doc-lint shape; minimal grep-based assertions: section header present, ADR-043 cited, ADR-026 cited, AFK Rule 6 fallback prose present).
   - `packages/retrospective/skills/analyze-context/test/analyze-context-skill-contract.bats` — new skill structural pin (same shape).

3. **Behavioural replay (end-to-end):**
   - Fresh adopter project running `/wr-retrospective:run-retro`: cheap-layer bucket table appears in the retro summary; `no prior snapshot — first measurement this project` sentinel printed in delta column.
   - Same project after `/wr-retrospective:analyze-context` runs: `docs/retros/<today>-context-analysis.md` exists with HTML-comment trailer; subsequent retro reads trailer and emits delta column populated.
   - Adopter project without `docs/retros/` or `docs/briefing/`: cheap layer emits bucket table with `not measured` sentinels for absent surfaces; never errors; never warns.

4. **ADR-022 transition:** P101 transitions from `.open.md` to `.known-error.md` in the same commit that lands this ADR + Step 2c + new skill + supporting script + bats fixtures. Verification Pending transition follows a subsequent release per ADR-022.

5. **ADR-038 + ADR-040 + ADR-014 + ADR-026 cross-references:** Related sections of those ADRs link to this one once accepted.

## Pros and Cons of the Options

### Option 1 — Two-layer (chosen)

- Good: honours user direction (cheap + deep); covers proactive surfacing without per-retro bloat.
- Good: composes cleanly with P099 / P105 / ADR-040 measurement infrastructure.
- Good: ADR-026-grounded suggestions from day one.
- Bad: highest implementation surface (script + skill + step + ADR + 2 ADR amendments + bats fixtures).

### Option 2 — Cheap-only embedded in `run-retro`

- Good: smallest implementation surface.
- Bad: insufficient depth for actionable suggestions; per-turn attribution missing.

### Option 3 — Deep-only on-demand skill

- Good: simplest deep-layer architecture; no Step 2c plumbing.
- Bad: rejected by user direction — proactive surfacing is the load-bearing affordance.

### Option 4 — Expensive-always-on integrated into `run-retro`

- Good: maximal depth on every retro.
- Bad: rejected by user direction — analyzer would itself be bloat ("if it's really heavy and consumes lots of tokens to execute, then I don't want to do it every retro").

## Reassessment Criteria

Revisit this decision if:

- **Cheap-layer static budget proof becomes invalid**: e.g. file count grows substantially in adopter repos or new measurement surfaces push the report past ~2.5 KB. Rework the cheap-layer fail-open path or reshape the bucket aggregation.
- **Deep-layer report itself bloats**: `docs/retros/<date>-context-analysis.md` grows past ~5 KB consistently. Promote a `check-retros-budgets.sh` advisory script per the P099 pattern.
- **`claude -p --output-format json` `.jsonl` schema changes**: per-turn attribution depends on the framework's logged `usage` shape; revisit if framework changes break the deep-layer parse.
- **Per-plugin attribution proves insufficient for plugin-developer persona**: e.g. plugin authors need finer-grained breakdown (per-skill within a plugin, per-hook within a plugin). Extend the deep layer's decomposition; cheap-layer aggregates remain.
- **A sibling measurement surface ships** (e.g. P102 risk-register tier; per-tool latency telemetry): generalise the script + skill pattern to a `measure-*-budget.sh` family or refactor common code into `packages/retrospective/lib/`.
- **Suggestion grounding proves stricter than ADR-026 needs**: e.g. comparable-prior citation requirement blocks legitimate first-of-its-kind suggestions. Relax the rule with an explicit `first-of-kind — no prior data` sentinel path.
- **Snapshot trailer drifts** (e.g. multi-format trailers from third-party tooling): codify a stable trailer schema and validate via the bats fixture.

## Related

- **`P101`** (this ADR's driver ticket — transitions Open → Known Error on landing this ADR + implementation; → Verification Pending on subsequent release).
- **`P091`** (parent meta — Session-wide context budget) — this ADR's measurement layer subsumes P091's "Build a measurement harness" investigation task.
- **`P095` / `P096` / `P097` / `P098` / `P099` / `P100` / `P105`** — sibling P091-cluster surfaces. This ADR's measurement aggregates over each surface's individual budget.
- **`JTBD-001`** (Enforce Governance Without Slowing Down) — primary served job.
- **`JTBD-006`** (Progress the Backlog While I'm Away) — AFK surfacing primary.
- **`JTBD-005`** (Invoke Governance Assessments On Demand) — deep-layer skill primary.
- **`ADR-038`** (Progressive disclosure for `UserPromptSubmit` governance prose) — sibling ADR; tiered-disclosure pattern + advisory-script triplet precedent.
- **`ADR-040`** (Session-start briefing surface) — sibling ADR; HTML-comment trailer pattern precedent (lines 99–104).
- **`ADR-026`** (Agent output grounding) — amended within reassessment window: `analyze-context/SKILL.md` added to per-agent prompt amendments list.
- **`ADR-014`** (Governance skills commit own work) — amended within reassessment window: `docs(retros): context analysis YYYY-MM-DD` row added to Commit Message Convention table.
- **`ADR-013`** Rule 1 / Rule 6 — interactive AskUserQuestion path / AFK fallback. Cheap layer is silent in AFK; deep layer never auto-fires.
- **`ADR-009`** (gate marker lifecycle) — explicitly NOT used; trailer-based persistence chosen over `/tmp` markers.
- **`ADR-022`** (problem lifecycle Verification Pending) — P101's transition path from this ADR's landing.
- **`ADR-005`** (plugin testing strategy) / **`ADR-037`** (skill testing strategy) — bats fixture shape.
- **Codeburn** (https://github.com/getagentseal/codeburn) — user reference for the conceptual shape; investigated at design time, divergent from the on-disk-byte-count + JSONL-usage hybrid chosen here.
- `packages/retrospective/scripts/check-briefing-budgets.sh` — script-shape precedent.
- `packages/retrospective/scripts/test/check-briefing-budgets.bats` — bats-shape precedent.
