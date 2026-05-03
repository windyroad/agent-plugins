# Ask Hygiene — 2026-05-03 (audit-prep session, parent of 8df1692 / b59c5e4 / df47ad1 / e71fc51 / d944388 / f01331b / ccf9a1a)

Per Step 2d of `/wr-retrospective:run-retro` (P135 Phase 5 / ADR-044). Lazy-AskUserQuestion-count is the regression metric; target 0.

| Call # | Header | Classification | Citation |
|--------|--------|----------------|----------|
| 1 | Detector surface | direction | Gap: ADR-051 Phase 1 names retro-time advisory but does not resolve the load-bearing surface choice (PreToolUse:Edit / PreToolUse:Bash / CI / all three). Genuine new framework decision required. |
| 2 | Auto-fix scope | direction | Gap: ADR-051 Phase 1 is detect-only; auto-fix scope (agent-generated section / mechanical-only / never / defer) is genuine new framework decision not pre-resolved by any existing ADR. |

**Lazy count: 0**
**Direction count: 2**
**Override count: 0**
**Silent-framework count: 0**
**Taste count: 0**
**Correction-followup count: 0**

## Notes

- Both `AskUserQuestion` calls were genuine direction-setting per ADR-044 — the user reshaped the design (commit-hook surface; integrated prose vs section) in answers that existing framework had not anticipated. Surfacing as `AskUserQuestion` was correct (vs assuming an answer the framework did not in fact resolve).
- **Prose-ask regression observed (P085 evidence)**: session emitted ≥3 prose-asks not captured by the AskUserQuestion-call metric — *"Or wrap and let the next session pick it up?"*, *"Want me to start P159 now... or wrap?"*, *"Or if the audit deadline is too tight..."*. Each is an obvious-default-or-AskUserQuestion-not-prose call that should have been resolved by acting on the obvious default OR by routing through `AskUserQuestion`. P085 is `.verifying.md`; this session is regression evidence — prose-ask detector (`itil-assistant-output-review.sh` Stop hook) either missed the pattern or fired silently. Captured in the retro summary's Pipeline Instability section for follow-up.
- Trend script confirms 9 prior retros at `lazy=0` (cross-session window) — the AskUserQuestion-call surface is stable; the prose-ask surface is the gap.
