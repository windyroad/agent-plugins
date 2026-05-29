---
"@windyroad/architect": minor
---

`wr-architect:agent` now loads a compact generated `docs/decisions/README.md` **Decisions Compendium** for routine compliance review instead of every full ADR body (ADR-077; P327 inbound).

For projects with many ADRs the load drops from N full bodies (~1.6 MB across 75 ADRs in the dogfood repo) to a single ~40 KB compendium — about a **40× reduction** in the routine architect-agent load path. The per-ADR body remains the authoritative substance (ADR-031); the compendium is a derived view carrying each ADR's chosen option, confirmation criteria, and relationship graph in one line each. Decision Drivers, Considered Options bodies, Pros and Cons, Consequences narrative, and Reassessment Criteria stay in the per-ADR body for deep-dive surfaces.

- **Generator**: `packages/architect/scripts/generate-decisions-compendium.sh` (canonical body) + `packages/architect/bin/wr-architect-generate-decisions-compendium` (ADR-049 PATH shim). Idempotent — same ADR bodies produce byte-identical output.
- **Architect agent prompt amended** (`packages/architect/agents/agent.md` Step 1) to read the compendium first; falls back to globbing `docs/decisions/*.md` when the compendium is absent (fresh installs, projects predating ADR-077). Deep-dive surfaces (`/wr-architect:create-adr`, `/wr-architect:capture-adr`, `/wr-architect:review-decisions`, explicit contested-change review) still load the full ADR body directly.
- **Initial compendium** generated for the 75 dogfood-repo ADRs and committed.

Enforcement machinery — a commit-time PreToolUse hook (`architect-compendium-refresh-discipline.sh` mirroring the P165 `itil-readme-refresh-discipline.sh` pattern) that denies commits staging ADR edits without a refreshed compendium, plus a CI drift-detection bats — lands in the next minor release alongside `/wr-architect:create-adr` / `/wr-architect:capture-adr` / `/wr-architect:review-decisions` skill integrations that author and refresh the compendium at decision time.
