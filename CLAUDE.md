# Project: windyroad-claude-plugin

Plugin-development monorepo publishing `@windyroad/*` Claude Code plugins — architecture governance, risk management, ITIL, TDD, JTBD, retrospectives, and delivery quality — by Windy Road Technology. These plugins promote Windy Road's service offering to the community; they are NOT internal project utilities.

Not a web UI project — accessibility-first global guidance (injected by the `accessibility-agents` plugin into `~/CLAUDE.md`) does not apply here.

**MANDATORY — act on obvious, AskUserQuestion for ambiguous, NEVER prose-ask** (P085): when the user has pinned a direction (yes / go / proceed / act / just do it) or the next step is obvious from session context or RISK-POLICY.md appetite, act and report — do not surface a consent gate. When genuinely ambiguous, use the `AskUserQuestion` tool. Prose asks ("Want me to...?", "Should I...?", "Option A or Option B?", "(a)/(b)/(c)?") are non-compliant and unanswerable under AFK notifications. Canonical phrasing list + hook enforcement: `packages/itil/hooks/lib/detectors.sh`.
