---
"@windyroad/itil": patch
---

work-problems: add preflight to reconcile with origin before iteration (P040)

Adds Step 0 (Preflight) to the work-problems AFK orchestrator per ADR-019.
Before opening the work loop, the orchestrator now runs `git fetch origin`
and compares local HEAD with `origin/<base>`. On trivial fast-forward
divergence, it pulls non-interactively (`git pull --ff-only`). On
non-fast-forward divergence (local has unpushed commits AND origin has
advanced), it stops with a clear divergence report (`git log --oneline
HEAD..origin/<base>` and reverse). Non-interactive rebase or merge is
explicitly forbidden — the persona requires user judgment for those.

Network failure on `git fetch origin` defaults to fail-closed (stop and
report); the user can retry when network is restored.

Adds row to Non-Interactive Decision Making table covering origin
divergence. Adds bats test (7 assertions) covering ADR-019 confirmation
criteria: skill cites ADR-019; references `git fetch origin` and
`pull --ff-only`; has discrete preflight step; non-interactive table
covers it; explicitly forbids non-interactive merge/rebase.

The next-ID collision guard (ADR-019 confirmation criterion 2) belongs in
ticket-creator skills (manage-problem, wr-architect:create-adr) and is
tracked in a separate problem ticket.

Closes P040 pending user verification.
