---
name: wr-retrospective:analyze-context
description: Deep on-demand context-usage analyzer. Runs richer heuristics than run-retro Step 2c — per-turn attribution, per-plugin decomposition, suggestion generation, policy-breach detection. Produces a markdown report at docs/retros/<date>-context-analysis.md with an HTML-comment trailer carrying the bucket-snapshot for delta-from-prior comparison. User-invoked only; never auto-fires.
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, Skill
---

# Analyze Context (Deep Layer)

On-demand deep analysis of session context-usage — per-turn attribution, per-plugin decomposition, suggestion generation. Produces a committed markdown report at `docs/retros/<date>-context-analysis.md` whose HTML-comment trailer is the snapshot subsequent runs of `run-retro` Step 2c (cheap layer) compare against.

This skill is the **deep layer** of the two-layer design in **ADR-043** (Progressive context-usage measurement and reporting for retrospective sessions; P101). The **cheap layer** lives in `packages/retrospective/skills/run-retro/SKILL.md` Step 2c and runs every retro at < 5% session budget. This skill runs only on explicit user direction.

## When to use

- The user invokes `/wr-retrospective:analyze-context` directly.
- The cheap layer (run-retro Step 2c) surfaced a delta anomaly (>+20% in any bucket since prior snapshot) and the user wants the per-turn / per-plugin decomposition.
- The user is preparing to trim context — e.g. before a release that introduces new hooks or skills, or after observing early compaction in long-running AFK loops.
- The user wants a baseline snapshot at a known-good moment (e.g. immediately after a P091-cluster fix lands).

**Never auto-fires.** Per ADR-043 + ADR-013 Rule 6 (AFK fallback), this skill is invoked only by explicit user direction. AFK orchestrators that observe anomalies via the cheap layer surface them in iteration summaries; the user runs this skill on return.

## Output Formatting

Per **ADR-026** (Agent output grounding), this skill's prose, suggestions, and findings MUST cite specific surfaces, MUST persist evidence in re-readable form, and MUST mark ungrounded fields with explicit sentinels. Forbidden phrases (Banned per ADR-026 Confirmation line 148): `load is negligible`, `microseconds only`, `minimal`, `small change`, `trim X to reduce bloat` (without a comparable prior). Every top-N offender row and every trim suggestion MUST carry a concrete byte count + measurement-method citation. Comparable-prior reclamation suggestions (e.g. `P095 reclaimed ~120KB by once-per-session gating`) cite the specific prior; when no prior exists, emit `not estimated — no prior data` per ADR-026 line 90.

When referencing problem IDs, ADR IDs, or JTBD IDs in prose output, include the human-readable title on first mention. Format `P101 (wr-retrospective has no context-usage analysis)` rather than bare `P101`.

## Steps

### 0. Verify the cheap-layer primitive exists

The deep layer reuses the cheap layer's measurement script as its byte-count baseline. Verify the primitive is available:

```bash
test -x packages/retrospective/scripts/measure-context-budget.sh
```

If the script is missing or not executable, halt with a directive: *"measure-context-budget.sh is the cheap-layer measurement primitive (P101 / ADR-043). Verify the wr-retrospective plugin is installed and up to date before running the deep analyzer."*

### 1. Capture the bucket-totals baseline

Invoke the script to capture the canonical per-source-bucket byte totals. Identical contract to run-retro Step 2c:

```bash
wr-retrospective-measure-context-budget "${CLAUDE_PROJECT_DIR:-.}"
```

The `wr-retrospective-measure-context-budget` command is a `$PATH`-resolved shim shipped in `packages/retrospective/bin/` that dispatches the canonical `packages/retrospective/scripts/measure-context-budget.sh` body. ADR-049 — never invoke the canonical script via repo-relative path; the path does not resolve in adopter trees.

The output is the deep layer's baseline. Parse each `BUCKET <name> bytes=<N>` row into a structured map; preserve `BUCKET <name> not-measured reason=<reason>` rows verbatim — the sentinels carry into the report unchanged.

### 2. Decompose per-plugin attribution

The cheap layer reports `hooks` and `skills` as aggregates. The deep layer decomposes each by plugin, citing concrete byte counts per plugin:

```bash
wr-retrospective-list-plugin-attribution "${CLAUDE_PROJECT_DIR:-.}"
```

The `wr-retrospective-list-plugin-attribution` command is a `$PATH`-resolved shim shipped in `packages/retrospective/bin/` that dispatches the canonical `packages/retrospective/scripts/list-plugin-attribution.sh` body. ADR-049 — never invoke the canonical script via repo-relative path; the path does not resolve in adopter trees. Equivalent contract to ADR-049's `wr-retrospective-measure-context-budget` shim.

Output rows (one per plugin, terse machine-readable per ADR-038 ≤150 bytes):

```
PLUGIN-HOOKS  <plugin> bytes=<N>
PLUGIN-SKILLS <plugin> bytes=<N>
PLUGIN-ATTRIBUTION not-measured reason=<reason>
```

Resolution order (handled by the helper, transparent to this skill):

1. **Source-tree mode** — when invoked from a windyroad source-repo session, walks `packages/<plugin>/{hooks,skills}` directly.
2. **Cache-fallback mode** — when invoked from an adopter session (no `packages/` under `${CLAUDE_PROJECT_DIR}`), the helper sniffs `$PATH` for plugin-cache `bin/` entries (`*/cache/<owner>/<plugin>/<version>/bin`) and back-walks each plugin's root for hooks + skills byte counts.
3. **Neither resolves** — emits a `PLUGIN-ATTRIBUTION not-measured reason=no-plugin-source-resolvable` sentinel per ADR-026. Treat as ungrounded; do NOT fabricate per-plugin numbers when this row appears.

Per-row contract: each `PLUGIN-HOOKS` / `PLUGIN-SKILLS` row carries a concrete byte count from the helper's `find ... -name '*.sh' / SKILL.md` + `wc -c` measurement chain. The aggregate cheap-layer `hooks` row equals the sum of all `PLUGIN-HOOKS` rows (sanity-check the report); `skills` row equals the sum of all `PLUGIN-SKILLS` rows.

P153 / ADR-049 — do NOT re-introduce repo-relative `packages/*/hooks` (or `skills` / `scripts` / `bin`) directory-enumeration glob loops in SKILL.md prose; route every plugin walk through `wr-retrospective-list-plugin-attribution` (or an equivalent bin-shimmed helper). The grep-as-lint at `packages/shared/test/no-repo-relative-script-paths-in-skills.bats` fails CI on regression.

### 3. Per-turn attribution (when session log is available)

When `${CLAUDE_PROJECT_DIR}/.afk-run-state/*.jsonl` exists (AFK orchestrator session) OR the user supplies an explicit session-log path, parse the per-turn `usage` field per ADR-043's deep-layer methodology:

```bash
log_paths=( "${CLAUDE_PROJECT_DIR:-.}"/.afk-run-state/*.jsonl )
shopt -s nullglob
log_paths=( "${log_paths[@]}" )
shopt -u nullglob
```

For each log file:

- Extract `usage.{input,output,cache_creation,cache_read}_tokens` per turn.
- Map each tool-call's input/output bytes to the bucket(s) the tool referenced (e.g. an Edit on `packages/itil/skills/manage-problem/SKILL.md` attributes to `skills/itil`).
- Aggregate per-turn totals; flag turns whose token cost exceeds 2× the median turn-cost as **anomalous turns**.
- When no session log is available, emit `per-turn attribution: not measured — no session log accessible` per ADR-026.

### 4. Suggestion generation (ADR-026 grounding)

For each non-trivial bucket (top-5 by byte count), generate a trim-candidate suggestion citing:

1. **The specific surface** that dominates the bucket (e.g. `packages/itil/skills/manage-problem/SKILL.md`).
2. **A comparable prior reclamation** (e.g. `P095 reclaimed ~120KB by once-per-session gating; P099 promoted Tier 3 to advisory enforcement; P100 split BRIEFING.md into per-topic files`). When no comparable prior exists, emit `not estimated — no prior data` per ADR-026 line 90.
3. **A concrete byte-saving estimate** anchored to the prior or marked ungrounded.

**Forbidden suggestion shapes** (ADR-026 Confirmation line 148): bare `trim X` without a citation; `consider reducing` without a target byte count; `optimise this skill` without a comparable prior. Every suggestion is auditable end-to-end or it is not emitted.

### 5. Detect policy breaches

For surfaces with explicit budgets, check for breach:

- **ADR-038 hook prose budget** (≤150 bytes per subsequent-prompt reminder) — verify by sampling each `UserPromptSubmit` hook's terse-reminder branch. Emit a `BREACH` row per offending hook with citation.
- **ADR-040 Tier 1 / Tier 2 / Tier 3 budgets** — invoke `packages/retrospective/scripts/check-briefing-budgets.sh` and surface any `OVER` rows verbatim in the deep report.
- **ADR-038 SKILL.md size cluster (P097)** — when a single `SKILL.md` exceeds 50KB, emit a `BREACH` row citing the file path + byte count + the P097 ticket as the evolving budget anchor.

When a breach is detected, the report includes a `## Policy Breaches` section. Each breach cites the specific budget rule + the offending file path + a concrete byte count.

### 6. Render the report

Write the deep-layer report to `docs/retros/<TODAY>-context-analysis.md` where `<TODAY>` is the current ISO date.

If `docs/retros/` does not exist, create it (`mkdir -p docs/retros`). If `docs/retros/README.md` does not exist, scaffold a minimal one-line index pointing at the report directory shape:

```markdown
# Retro Reports

Per-date context-analysis reports produced by the wr-retrospective deep layer (`/wr-retrospective:analyze-context`). Each report carries an HTML-comment snapshot trailer; see ADR-043 for the schema.
```

**Report shape:**

```markdown
# Context Analysis — YYYY-MM-DD

> Source: `/wr-retrospective:analyze-context` (deep layer per ADR-043).
> Methodology: byte-count-on-disk + per-plugin decomposition + per-turn attribution (when session log available).
> Cheap-layer baseline: `packages/retrospective/scripts/measure-context-budget.sh`.

## Bucket Totals

| Bucket | Bytes | % of measured | Δ vs prior |
|--------|-------|---------------|------------|
| ... | ... | ... | ... |

(Bucket rows ordered by byte count descending. `not-measured` buckets ride a separate row with the reason sentinel.)

## Per-Plugin Decomposition

### Hooks (aggregate from cheap layer: <N> bytes)

| Plugin | Bytes | % of hooks |
|--------|-------|------------|
| ... | ... | ... |

### Skills (aggregate from cheap layer: <N> bytes)

| Plugin | Bytes | % of skills |
|--------|-------|-------------|
| ... | ... | ... |

## Top-N Offenders

| Surface | Bytes | Bucket | Comparable prior |
|---------|-------|--------|------------------|
| ... | ... | ... | ... |

## Per-Turn Attribution

(Populated only when a session log is accessible; otherwise: `per-turn attribution: not measured — no session log accessible`.)

| Turn | Input tokens | Output tokens | Cache creation | Cache read | Notes |
|------|--------------|---------------|----------------|------------|-------|
| ... | ... | ... | ... | ... | ... |

## Suggestions

(Per ADR-026 — each suggestion cites specific surface + comparable prior + concrete byte estimate, or marks `not estimated — no prior data`.)

1. **[Bucket / Surface]** — Suggestion text. Comparable prior: `P<NNN> reclaimed ~<N>KB by <approach>`. Estimated byte saving: `~<N>KB` / `not estimated — no prior data`.

## Policy Breaches

(Populated only when a breach is detected per Step 5; otherwise: `no policy breaches detected`.)

| Budget | Offender | Bytes | Citation |
|--------|----------|-------|----------|
| ... | ... | ... | ... |

<!--
context-snapshot:
  total-bytes: <N>
  hooks: <N>
  skills: <N>
  memory: <N>
  briefing: <N>
  decisions: <N>
  problems: <N>
  jtbd: <N>
  project-claude-md: <N>
  framework-injected: not measured
  measurement-method: byte-count-on-disk
  measured-at: <ISO timestamp>
-->
```

The HTML-comment trailer is the snapshot subsequent retros (run-retro Step 2c) read for delta-from-prior comparison. Schema mirrors ADR-040's per-entry signal-score block.

### 7. Commit per ADR-014

Stage and commit per the ADR-014 commit-message convention added by ADR-043:

1. `git add docs/retros/<TODAY>-context-analysis.md` plus, if newly created, `docs/retros/README.md`.
2. Satisfy the commit gate — two paths are valid:
   - **Primary**: delegate to the `wr-risk-scorer:pipeline` subagent-type via the Agent tool.
   - **Fallback**: invoke `/wr-risk-scorer:assess-release` via the Skill tool. Per ADR-015 it wraps the same pipeline subagent and produces an equivalent bypass marker.
3. `git commit -m "docs(retros): context analysis YYYY-MM-DD"` per ADR-014's amended Commit Message Convention table.

If risk is above appetite per ADR-013 Rule 5 + ADR-042: do NOT commit; report the uncommitted state and let the user resolve. Do NOT call `AskUserQuestion` as a shortcut out of the auto-apply loop.

### 8. Report

After the commit lands, report:

- The path of the new report file.
- The total measured bytes + delta-vs-prior summary line.
- The number of suggestions generated.
- The number of policy breaches detected.
- A pointer to run-retro Step 2c: *"Subsequent `/wr-retrospective:run-retro` invocations will read this report's HTML-comment trailer for delta comparison."*

## Non-interactive / AFK behaviour (ADR-013 Rule 6)

This skill is **never auto-invoked** in AFK or non-interactive mode. The cheap layer (run-retro Step 2c) surfaces anomalies in the iteration summary; the user runs `/wr-retrospective:analyze-context` on return.

If invoked in a non-interactive context with `AskUserQuestion` unavailable AND the commit gate flags above-appetite risk: skip the commit, report the uncommitted report path clearly, and let the user resolve on return. The report file itself is still written — it is the evidence the user reviews.

## Further reading (REFERENCE.md — lazy-loaded per ADR-054)

> Read `REFERENCE.md` § `Composition with sibling measurements` for sibling-skill cross-references (run-retro Step 2c bidirectional contract, P099 briefing-budgets co-citation, P105 signal-vs-noise composition, ADR-040 tier-budget composition).
>
> Read `REFERENCE.md` § `ADRs cited` for the full source-decision provenance index when investigating a behavioural change against this skill's design lineage.

$ARGUMENTS
