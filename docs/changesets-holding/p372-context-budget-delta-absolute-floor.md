---
"@windyroad/retrospective": patch
---

Add an absolute-byte floor to the ADR-043 context-budget delta-breach trigger (P372). The `run-retro` Step 2c deep-layer auto-fire trigger has a delta-breach axis that fired `/wr-retrospective:analyze-context` (a committed report plus subagent calls) whenever any bucket changed by more than 20% versus the prior snapshot. Relative-only is scale-blind: a small bucket trips 20% on a trivial edit — observed when the `project-claude-md` bucket grew 4277→5897 bytes (+37.9%) on a single CLAUDE.md addition, a +1620-byte change that does not warrant the deep layer's cost.

The delta-breach axis now requires both a more-than-20% relative change AND a more-than-10 KB absolute change (`|current − prior| > 10240` bytes). Both gates are required, suppressing tiny-bucket noise while preserving every fire on a bucket large enough for a 20% delta to be a real bloat signal. The inverse concern — a large-but-stable bucket never re-firing — is already covered by the existing calendar-elapse axis (more than 14 days re-fires every bucket regardless of delta), so no separate firing axis is added.

Surfaces: `run-retro` Step 2c step 4 (Delta-breach bullet plus the trigger-inactive note), `analyze-context/SKILL.md` trigger-description lines, ADR-043 (Amendment 2026-06-17 sub-note plus threshold grounding), and a second paired promptfoo eval case on the Step 2c contract asserting the floor gate (small-bucket-does-not-fire, large-delta-does-fire).
