---
"@windyroad/itil": minor
---

New advisory hook `itil-fix-title-lifecycle-advisory.sh` (PostToolUse:Bash): when a just-landed commit's subject is fix-typed (`fix: ...` / `fix(<pkg>): ...`) and names a `P<NNN>` problem ticket that is still in `docs/problems/open/`, the hook emits a stderr nudge to pair the fix with its lifecycle transition. Advisory-only — it never blocks and never auto-transitions, because Open → Known Error asserts root cause is known, which a commit title cannot establish (ADR-092). Bypass with `BYPASS_FIX_TITLE_LIFECYCLE_ADVISORY=1`. Closes the fix-without-paired-transition seam of P345 (RFC-044, STORY-038).
