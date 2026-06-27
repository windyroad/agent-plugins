---
"@windyroad/architect": patch
---

Add a promptfoo behavioural eval for the architect review agent's verdict surface (`packages/architect/agents/eval/`). It exercises the real agent against fixture proposed-changes and asserts on the emitted verdict — Tier-A `icontains` on the `PASS` outcome plus a Tier-B `llm-rubric` for the negated `[Unratified Dependency]` over-fire guard. The eval directory is dev-only and excluded from the published package (`!agents/eval/` in the `files` field), so the installed runtime is unchanged. This mirrors the jtbd agent eval and completes the architect + jtbd agent-prose harness pair (RFC-012, P324).
