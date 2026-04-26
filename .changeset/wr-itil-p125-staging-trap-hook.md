---
"@windyroad/itil": patch
---

P057 staging-trap recurrence is now denied at commit time by a new `PreToolUse:Bash` hook (`packages/itil/hooks/p057-staging-trap-detect.sh`) that fires on `git commit` invocations and surfaces the recovery command inline. Documentation alone did not prevent recurrence — P125 evidence: P122 batch shipped commit `e7564ff` with rename-only after multiple retros had cited the rule. The hook removes reliance on agent attention.

Detection delegates to a new shared helper `packages/itil/hooks/lib/staging-detect.sh::detect_p057_trap`. The helper runs `git diff --staged --name-status` and `git diff --name-only`; if any staged rename's `<new>` path also appears in the working-tree modification list, the trap is present. The helper echoes the trap'd path on stdout and emits a one-line recovery hint on stderr, returning 1 (deny) or 0 (allow / fail-open). Cost is bounded — two `git diff` invocations per commit invocation (~10-50ms on this repo's working tree).

Fail-open contract mirrors `lib/create-gate.sh`: outside a git working tree, on parse-incomplete input, or when `git diff` errors for any reason, the helper returns 0 — a hook that fails-closed on hostile environments would block legitimate commits in non-git contexts. ADR-013 Rule 1's "deny redirects to recovery" contract is satisfied via the mechanical-recovery shape — re-staging a file is a single command, no skill round-trip required.

10 behavioural bats assertions per ADR-005 + P081 (`packages/itil/hooks/test/p057-staging-trap-detect.bats`) pin the contract: trap detected → deny with file + recovery + P057 cite; trap recovered via re-stage → allow; pure rename → allow; modify-only batch → allow; empty batch → allow; non-Bash tool → allow; non-commit Bash command → allow; empty JSON (parse-incomplete) → allow (fail-open); deny message names file + `git add <FILE>` + P057 cite; deny message stays under ADR-038 progressive-disclosure budget (<400 bytes; observed ~348 bytes).

Hook registered in `packages/itil/hooks/hooks.json` under `PreToolUse` with `matcher: "Bash"`. `docs/briefing/agent-interaction-patterns.md` line 8 cites the new hook as the enforcement layer the documentation alone didn't provide. JTBD-001 (Enforce Governance Without Slowing Down) primary fit. JTBD-006 (Progress the Backlog While I'm Away) composes — AFK iter loops are the highest-frequency offenders.
