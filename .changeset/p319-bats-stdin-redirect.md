---
"@windyroad/architect": patch
"@windyroad/jtbd": patch
---

Fix hook tests that could hang indefinitely under a full `bats --recursive` run. The `architect-detect.sh` and `jtbd-eval.sh` hooks read their input from stdin (`INPUT=$(cat)`); the scope and eval tests invoked them with no stdin redirect, so when the suite inherited an open terminal `cat` blocked forever instead of receiving EOF. Each bare `run bash "$HOOK"` invocation now redirects stdin from `/dev/null`, matching the convention already used by the sibling hook tests, so the suite terminates reliably as a pre-push verify gate.
