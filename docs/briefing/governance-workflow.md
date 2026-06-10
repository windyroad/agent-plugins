# Governance Workflow

Cross-session learnings about ADRs, architect/JTBD reviews, risk scoring, and voice-tone.

## What You Need to Know

> **Sibling brief**: promptfoo SKILL-eval authoring pitfalls (Tier-A JS-engine regex, Nunjucks `{% raw %}` wrapping, negative-clause → Tier-B llm-rubric routing; P324 Phases 3+5 worked examples) split out 2026-06-10 to [`promptfoo-eval-authoring.md`](./promptfoo-eval-authoring.md) per Tier 3 budget rotation. Load it when authoring or debugging `promptfooconfig.yaml` evals.

### `proposed` ≠ ratified — orthogonal axes; confirm-substance-before-build now has THREE enforcement surfaces (2026-05-27)

`status:` (proposed/accepted) and `human-oversight: confirmed` (ratified) are **orthogonal**. Building on a *ratified-but-`proposed`* ADR is fine; only **unratified** (marker-absent, non-superseded) decisions are the hazard. After the P283 drain, almost every ADR is ratified (2026-05-27: 61/65), so unratified-dependency checks are near-silent. ADR-074 (confirm a decision's SUBSTANCE — the chosen option, not a grain/meta question like "one ADR or two?" — before building dependent work) is now enforced at three surfaces: (1) **record-time** — architect Needs-Direction names the substantive choice (ADR-064); (2) **build-upon @ ITIL propose-fix** — `manage-problem`/`work-problems` run `wr-architect-is-decision-unconfirmed` (RFC-008); (3) **build-upon @ architect-review** — the architect emits `[Unratified Dependency]` ISSUES FOUND when a change/plan cites/implements a marker-less ADR (RFC-010, `@windyroad/architect@0.9.2`). The architect (Read/Glob/Grep, no Bash) does a frontmatter-scoped, superseded-skipping, marker-keyed-NOT-status Grep. New behaviour takes effect on next session restart (P045). See ADR-074, P315/P318.

### Implementing an unconditional decision: do NOT invent a softer path (2026-05-26)

When implementing a ratified **unconditional / no-carve-out / no-exemption** decision, do not invent or reframe a softer variant — no "thin", "minimal", "scaled-down", or "preserved friction-guard" path. That is the **same disavowed class as the original carve-out**, just relocated. Worked failure: implementing ADR-070/071 ("every fix goes through an RFC, unconditionally"), the agent reframed the disavowed atomic-fix carve-out into a "thin RFC with empty `stories: []` / scale-down value preserved" path and propagated it into ADR-071/072, RFC-005/006, and the JTBD amendments — even citing ADR-071's own softening wording as licence. User: *"No. Same RFC. Not scaled down. No short cuts."* Captured as **P311**; corrective sweep struck the framing everywhere AND amended ADR-071's own text (a ratified ADR's wording is NOT immune — if it carries softening the user later disavows, amend it too). A structural fact (e.g. `stories: []` = an RFC not decomposed into stories) is NOT a reduced-ceremony path; never frame it as one. Memory: `feedback_no_shortcuts_no_softening`. <!-- signal-score: 0 | last-classified: 2026-05-26 | first-written: 2026-05-26 -->

> Two older 2026-05-26 entries (`Known Error semantics: root cause + workaround` and `reconcile-rfcs false-flags reverse-traces`) archived 2026-06-08 to `governance-workflow-archive.md` for Tier 3 budget rotation. Load alongside this file for full history.

- **Risk appetite is Low (4)**. Changes scoring Medium (5+) need explicit acknowledgement. See `RISK-POLICY.md`.
- **All ADRs in `docs/decisions/` are still `.proposed.md`** — none ratified. Amendments are cheap: prefer amending over superseding. When a P-problem intersects a proposed ADR, revise the ADR rather than adding a compatibility clause.
- **ADR-002 plugin dependency graph lists `@windyroad/tdd` as standalone.** Cross-plugin features must update the graph explicitly; don't silently add deps.
- **Pre-2026-04-26 entries archived to [`governance-workflow-archive.md`](./governance-workflow-archive.md)** (most recently rotated 2026-05-13 per Tier 3 budget MUST_SPLIT). Load the archive alongside this file when full historical context is needed.

> **Sibling brief**: cross-session "what will surprise you" learnings — ADR mechanics, JTBD reviewer behaviour, the `git ls-tree` blob-SHA next-ID trap, README-refresh reconciliation, and smaller workflow gotchas — live in `governance-workflow-surprises.md` (split out 2026-05-03 per P145 MUST_SPLIT). Read alongside this file for the full governance-workflow surface.
