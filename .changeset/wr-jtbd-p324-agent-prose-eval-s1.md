---
"@windyroad/jtbd": patch
---

P324 / RFC-012 S1: add the first behavioural test harness for an agent-prose verdict surface — a promptfoo eval for the jtbd review agent at `packages/jtbd/agents/eval/`. The exec provider runs the real agent (`claude -p --system-prompt`, subscription auth) against fixture proposed-changes and asserts on the emitted verdict (Tier-A `icontains` anchors + Tier-B `llm-rubric` for negative-clause semantics). Two fixtures: a ratified-job citation that must PASS without over-firing, and the inverse-P078/P132 over-fire guard that must NOT raise `[Unratified Dependency]` on a dependency-free change. The eval directory is dev-only and excluded from the published tarball via the `files`-field negation `!agents/eval/` — no adopter-facing runtime change.
