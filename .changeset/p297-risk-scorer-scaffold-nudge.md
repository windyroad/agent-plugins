---
"@windyroad/risk-scorer": minor
---

Add SessionStart scaffold-nudge hook for `docs/risks/` (P297 Phase 1).

When `RISK-POLICY.md` is present in an adopter project but `docs/risks/` (the
ISO 31000 / ISO 27001 standing-risk register directory) is missing, the new
`risk-scorer-scaffold-nudge.sh` SessionStart hook emits a one-line stderr
advisory pointing at `/wr-risk-scorer:bootstrap-catalog` to scaffold the
register. The hook is read-only — the scaffold write happens only when the
user invokes the consumer skill.

Why: ADR-047's original chosen mechanism (inline `/install-updates` step)
only fires for sibling projects reachable from the source repo's manual
`/install-updates` run, missing every adopter on every other machine.
SessionStart fires in every project on every machine, closing the
discovery gap.

The hook respects the suite-wide AFK guard `WR_SUPPRESS_OVERSIGHT_NUDGE=1`
per ADR-068, so AFK orchestrators never see the interactive prompt fire
into an absent-user subprocess.

No breaking change. Adopters with `RISK-POLICY.md` and an existing
`docs/risks/` see no behaviour change — the hook is silent on every state
except the gap it surfaces.
