---
"@windyroad/architect": patch
---

P191 Phase 2: architect gate resolves docs/decisions from the project root, not the hook runtime CWD

The architect PreToolUse gate had the same relative-path bug as the JTBD gate
(P191 Phase 1) but FAILS OPEN — on the CWD misfire `[ ! -d "docs/decisions" ]`
false-negatived and the gate silently went inactive, letting edits bypass
architect review (a governance hole, worse than a fail-closed nuisance).
Anchor every project-relative check on `PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$PWD}"`
across architect-enforce-edit.sh, architect-plan-enforce.sh, architect-detect.sh,
architect-mark-reviewed.sh, architect-refresh-hash.sh, and lib/architect-gate.sh.
Fail-open on genuine docs/decisions absence is preserved. Carried by RFC-020.
