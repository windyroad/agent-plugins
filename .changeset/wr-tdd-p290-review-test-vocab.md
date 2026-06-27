---
"@windyroad/tdd": patch
---

Harden the `review-test` agent to behavioural-only (ADR-052 Option 1A). The verdict vocabulary collapses to behavioural / mixed / structural / unclear — STRUCTURAL is now a failing classification, and the `structural-justified` / `structural-permitted` escape-hatch verdicts are removed. Structural assertions on prose-document content (SKILL.md, agent.md, ADRs, policy prose) are no longer permitted under any justification; a test that cannot yet be expressed behaviourally blocks on its harness-gap ticket rather than shipping as structural. ADR-005's preserved exceptions (hooks.json content, file-existence/removal, safety-construct presence on executable bash hooks) remain permitted and classify as behavioural. Paired with a promptfoo agent-prose-verdict eval (dev-only, tarball-excluded).
