---
"@windyroad/jtbd": patch
---

P191: JTBD edit gate resolves docs/jtbd from the project root, not the hook runtime CWD

The JTBD PreToolUse edit gate (jtbd-enforce-edit.sh) false-blocked legitimate
edits with "no JTBD documentation exists" even when docs/jtbd/ was present,
because the activation check `[ -d "docs/jtbd" ]` used a relative path resolved
against the hook process's runtime CWD — which Claude Code can launch divergent
from the session/project dir. Anchor every project-relative check on
`PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$PWD}"` (mirrors jtbd-oversight-nudge.sh) in
both jtbd-enforce-edit.sh and jtbd-mark-reviewed.sh. Fail-closed on genuine
docs/jtbd absence is preserved. Carried by RFC-020.
