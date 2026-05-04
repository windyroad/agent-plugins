---
risk_id: R007
slug: ambient-state-leaks-into-commits
status: Active
category: operational
identified: 2026-05-04
owner: plugin-maintainer
last_reviewed: 2026-05-04
next_review: 2026-08-04
asset_path: [.claude/settings.json, .claude/settings.local.json, .afk-run-state/, .claude/.intake-scaffold-*, .claude/.install-updates-consent, /tmp/<system>-announced-<UUID>, /tmp/manage-problem-grep-<SESSION>, .claude/projects/.../memory/]
cascade_scope: every commit that uses `git add -A` or `git add .` or that doesn't carefully constrain `git add <files>` scope; every push that includes ambient state
afk_class: both — interactive surfaces visibly via gitStatus; AFK loops can pass uninspected gitStatus through commit-time hooks if discipline lapses
reversal_class: git-recoverable (revert / amend) within the unpushed window; git-history-permanent post-push (recoverable via filter-repo + force-push but treats history as malleable)
control_budget_class: free-discipline (developer convention) + .gitignore as static control; no runtime cost
dogfood_days: ongoing (gitignore-based controls have been live since project inception; ambient-state-publish risk surfaces ~weekly per retro evidence)
authority_class: framework-resolved (gitignore is mechanical); user-direction (per-commit explicit-add discipline)
prompt_cache_window: ongoing
ci_a: confidentiality (settings.json may contain user-machine-specific config; .afk-run-state may contain session metadata); integrity (committed ambient state corrupts the project's intended-shape)
agentic_category: drift (ambient ↔ project boundary)
---

# Risk R007: Ambient / unstaged state leaks into commits

## Description

Agentic sessions accumulate ambient state on the developer machine: `.claude/settings.json` modifications (consent caches, model preferences, MCP configurations), `.afk-run-state/*.jsonl` queues (outstanding-questions, risk-register-queue), `/tmp/` markers (per-session SID announcements, create-gate markers), `.claude/projects/<path>/memory/*.md` (auto-memory). Most of this is gitignored. But the ambient state OFTEN appears in `git status` as modified-but-unstaged files for the duration of a session — and the agent is one `git add -A` away from committing it.

The risk has a structural property unique to agentic systems: the agent has Bash access including `git add`, and the ambient state `git status` shows is non-deterministic (varies per session, per OS, per Claude Code version). A `.gitignore` covers the known classes; novel ambient-state classes appear with new plugin features and aren't covered until someone adds them.

**Source → event → consequence chain**: source = ambient state appears in `git status` (modified .claude/settings.json, untracked .afk-run-state/) during a session; event = agent uses `git add -A` / `git add .` OR git-add-with-glob that captures the ambient files; consequence = ambient state lands in commit; secondary consequence = if pushed, the state becomes part of public-repo history (settings preferences may be confidential; queue files reveal session structure that's project-internal).

## Inherent Risk

- **Impact**: 2/5 (Minor) — ambient state landing in commits is recoverable in-session via `git reset` or `git revert`; post-push, the public-repo history contains the state but the impact is bounded (no business metrics typically; just session-internal config). Some classes (settings.json with API key fragments) escalate to higher impact.
- **Likelihood**: 3/5 (Possible) — corpus evidence: "Ambient unstaged `.claude/settings.json` modification leaks into a later commit" surfaced at least 3 times across `.risk-reports/`; gitStatus throughout this session itself shows `M .claude/settings.json` AND untracked `.claude/settings.local.json` AND untracked `docs/retros/2026-05-04-p159-iter.md`. Discipline-only mitigation produces a non-zero rate of failures.
- **Inherent Score**: 6
- **Inherent Band**: Medium

## Controls

- **`.gitignore`** — covers `.claude/settings.local.json`, `.afk-run-state/`, `/tmp/` (system default), `node_modules/`, etc. **Effectiveness**: high for known classes; zero for novel classes (e.g., a new plugin introduces `.claude/.foo-marker` that .gitignore doesn't cover). Reduces likelihood from 3 to 2 for the known-class subset.
- **CLAUDE.md "Never write project-generated artefacts under `.claude/`"** (P131) — discipline rule preventing agents from creating new ambient classes that escape .gitignore. **Effectiveness**: medium — depends on agent compliance; surfaces the rule per-prompt.
- **`git add <specific-paths>` discipline** (over `git add -A` / `git add .`) — pattern of staging only the files an agent actually intends to commit. Codified in MANY SKILL.md files (manage-problem, transition-problem, etc.). **Effectiveness**: medium-high — when SKILL contracts cite specific paths, the agent stages those; lower when agent improvises.
- **gitStatus visibility per session** — every prompt's gitStatus snapshot shows ambient unstaged files; agent can see them and avoid staging. **Effectiveness**: medium — visible to agents that look; ineffective when agents bulk-stage without inspecting.
- **`docs/decisions/058-plugin-maturity-measurement-mechanism.proposed.md`** — read-only NDJSON pattern for runtime state in `.claude/`. **Effectiveness**: low (recent addition); pattern-codification only.

## Residual Risk

- **Impact**: 2/5 (Minor) — controls don't change consequence shape; recoverable in-session, bounded post-push for the typical class.
- **Likelihood**: 2/5 (Unlikely) — gitignore + per-commit discipline + gitStatus visibility each contribute. Residual likelihood is the rate of ambient-class-novelty + git-add-improvisation slips.
- **Residual Score**: 4
- **Residual Band**: Low
- **Within appetite?**: Yes (= 4/Low — at the boundary).

## Treatment

**Mitigate** — at the appetite boundary; one more control increment would push residual to 2/Very-Low. Active mitigations:

1. Continue gitignore expansion as new ambient-state classes surface.
2. SKILL.md contracts cite specific paths to stage rather than bulk-add patterns.
3. Audit gitStatus before commit (most SKILL.md flows do this; some don't).
4. P131 rule prevents new agent-generated classes under `.claude/`.

Future mitigation if residual moves: a PreToolUse:Bash hook on `git add -A` / `git add .` that requires explicit acknowledgement of ambient-state inclusion. Deferred until evidence warrants the cost (currently: discipline + gitignore is sufficient for residual = appetite).

**Owner**: plugin-maintainer (Tom Howard).

## Monitoring

- **Trigger to re-assess**: an ambient-state file lands in a commit and is pushed (post-push detection from `git log --diff-filter=A` / scan). Or: a new plugin introduces an ambient-state class that .gitignore doesn't cover for >1 week (signals .gitignore-update lag). Or: corpus shows >1 instance/week of "ambient state unstaged" risk-item over a 2-week window (signals discipline regression).
- **Metrics**: count of ambient-state-leak commits / quarter (target 0); count of .gitignore amendments / quarter (signal: rate of new ambient classes); count of `.risk-reports/` items mentioning ambient-state risk / week (target trending down).

## Related

- **Criteria**: `RISK-POLICY.md`
- **Realised-as**: No specific problem ticket as driver — surfaced via `.risk-reports/` recurring pattern. P131 (`.claude/` write-discipline rule) is the closest meta-rule.
- **Treatment ADRs**: P131 in CLAUDE.md, ADR-058 (plugin maturity measurement — read-only NDJSON pattern), ADR-049 (plugin-bundled scripts via $PATH bin — separates project artefacts from .claude/).
- **Personas affected**: plugin-developer (JTBD-101 "extend the suite without painted-into-corner" — ambient state is a corner); solo-developer (post-push discovery is recovery-cost).

## Source Evidence

- `git status` throughout this session — `M .claude/settings.json`, `?? .claude/settings.local.json`, `?? docs/retros/2026-05-04-p159-iter.md` are persistent.
- `.risk-reports/*.md` — "Ambient unstaged `.claude/settings.json` modification leaks into a later commit" (R3.1 risk item) and "Staleness / accidental inclusion (`.claude/settings.json` modified, `.afk-run-state/` untracked per gitStatus)" recurring.
- `.gitignore` — current control inventory.
- `CLAUDE.md` P131 — write-discipline rule for `.claude/`.

## Change Log

- 2026-05-04: Bootstrapped from corpus evidence post-wipe. NEW class — not covered by pre-wipe R001-R006 register. Surfaced from gitStatus persistence pattern + recurring `.risk-reports/` items. Residual at appetite boundary; not over-engineering controls until evidence warrants.
