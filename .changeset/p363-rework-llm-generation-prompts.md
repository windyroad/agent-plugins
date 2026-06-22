---
"@windyroad/itil": patch
---

P363 rework — replace the inbound-verdict templates with LLM-generation prompts (`update-upstream` SKILL § Inbound-origin verdict dispatch leg I3) per user direction.

Four directives folded in:

1. **Templates → LLM-generation prompts** — the three transitions (O→KE / K→V / V→Closed) now each describe what to communicate + which sections of the local ticket to draw from (`## Description`, `## Workaround`, `## Root Cause Analysis`, `## Fix Released`). Generated prose adapts to each reporter's specific context rather than repeating the same form-letter shape.

2. **KE-status comments share the workaround** — by definition a Known Error has both root cause and workaround documented; the O→KE comment now includes the workaround so the reporter can keep working while the fix ships. Empty `## Workaround` triggers an honest "we don't have a workaround yet" instead of fabrication.

3. **Visibility-gated anti-leakage** — for PUBLIC repos, problem / ADR / RFC / JTBD / Story references use the title plus a permalink (not bare IDs); for PRIVATE / INTERNAL / indeterminate repos the prior strict ban stays. Classification tokens, internal step IDs, agent-internal vocabulary, and `docs/problems/...` path strings remain banned regardless of visibility.

4. **Workaround-provenance credit** — when the workaround the LLM is about to share was originally provided by the reporter or another commenter (semantic match against the upstream issue's body and comments), the generated prose credits them by `@handle` and confirms the exact details. Four provenance branches: maintainer-authored / reporter-provided / commenter-provided / both.

Gate chain reserved for cognitive-accessibility evaluation first when `@windyroad/cognitive-a11y` ships (P338-gated; do NOT block today — the chain degrades to risk + voice-tone). ADR-028 amendment 2026-06-23 declares the evaluator class and reserves the wiring; the SKILL marks the cog-a11y step "when-available". Tests assert the chain composition under a "when-available" pattern.

Supersedes the templates leg of @windyroad/itil@0.51.1 (no template firing window — no inbound ticket transitioned to V between 0.51.1 and this rework).
