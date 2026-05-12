---
"@windyroad/risk-scorer": patch
---

Narrative-only: consolidate `packages/risk-scorer/agents/wip.md` governance-artefact detection glob from dual `docs/problems/*.md` + `docs/problems/*/*.md` to a single recursive `docs/problems/**/*.md` (behavioural superset — matches both pre-T5a flat-layout and post-T5a per-state-subdir-layout adopter repos). Aligns wip.md with ADR-016's amended path-list shape per P170 Slice 5 T5b cross-reference reconciliation. No behavioural change to the governance-artefact detection set; clarifies the post-ADR-031 (accepted 2026-05-12) encoding canonical.
