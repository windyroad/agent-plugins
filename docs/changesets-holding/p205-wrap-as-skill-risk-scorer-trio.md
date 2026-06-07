---
"@windyroad/risk-scorer": patch
---

P205 slice 1 (risk-scorer trio): wrap-as-Skill pattern lands for the on-demand assessment scoring agents per ADR-015's Confirmation literal phrasing.

Three new invokable wrapper SKILLs ship under `packages/risk-scorer/skills/`:

- `pipeline/SKILL.md` — namespaced `wr-risk-scorer:pipeline`, wraps the pipeline scoring agent.
- `wip/SKILL.md` — namespaced `wr-risk-scorer:wip`, wraps the wip nudge agent.
- `external-comms/SKILL.md` — namespaced `wr-risk-scorer:external-comms`, wraps the external-comms leak-review agent.

Each wrapper is a thin pass-through that internally invokes the corresponding agent via the Agent tool — wrappers exist purely to expose the Skill-tool surface ADR-015 names. PostToolUse `risk-score-mark.sh` continues to fire on the inner Agent invocation and write the bypass markers as before.

Consumer SKILL prose flipped from `subagent_type:` (Agent tool) to `skill:` (Skill tool):

- `assess-release/SKILL.md` step 5 — now `skill: wr-risk-scorer:pipeline`.
- `assess-wip/SKILL.md` step 3 — now `skill: wr-risk-scorer:wip`.
- `assess-external-comms/SKILL.md` step 4 — now `skill: wr-risk-scorer:external-comms`.

Wrapper descriptions disambiguate from end-user surfaces — they direct end users to `/wr-risk-scorer:assess-*` for the gate-satisfying flow and reserve direct wrapper invocation for internal SKILL composition.

18 new behavioural bats at `packages/risk-scorer/skills/assess-release/test/assess-skills-delegate-via-skill-tool.bats` guard the contract surfaces (consumer→skill, wrapper→agent, description disambiguation). All green.

Phase 2 queued (not in this slice): `wr-risk-scorer:inbound-report` wrapper + `wr-architect:agent` (review-design) wrapper + `wr-jtbd:agent` (review-jobs) wrapper. The four other agents named in ADR-015's Scope table will adopt the same pattern in a follow-on iter. Mixed steady state in the interim: the three risk-scorer trio consumer SKILLs now match ADR-015 Confirmation verbatim; the three Phase 2 consumer SKILLs still use the historical Agent-tool path with the prose contradiction P205 documents.

Closes the P205 root cause for the risk-scorer trio surfaces; verifying transition recorded in `docs/problems/verifying/205-*.md`.

---

**Held in `docs/changesets-holding/` per ADR-042 Rule 2** — scored 6/25 (Medium) at commit time with `RISK_BYPASS: reducing` (closes P205 Known Error). Above appetite (Low=4) on Layer 1 because:

- R009 prose-surface modulator: no paired promptfoo eval covers the 3 new wrapper SKILLs (+1 likelihood for the prose subset).
- R002 documentation/index drift: multi-file lifecycle transition (ticket rename + README WSJF/Verification Queue moves + README-history rotation + ADR-002 inventory refresh) — atomically tracked in this commit but high-likelihood class.
- R021 new user-facing surface without dogfood window: the wrappers are discoverable via `/wr-risk-scorer:pipeline` etc.

**Reinstate criterion** (move back to `.changeset/` once any of these is true):

- Phase 2 of P205 (wrapping `wr-risk-scorer:inbound-report` + `wr-architect:agent` + `wr-jtbd:agent`) lands AND the cohort dogfood window has observed any wrapper invocation surface in-session at least once with the structured PASS verdict propagating end-to-end (consumer SKILL → wrapper SKILL → agent → PostToolUse hook → marker write); OR
- A paired promptfoo Tier-A/B eval slice at `packages/risk-scorer/skills/{pipeline,wip,external-comms}/eval/promptfooconfig.yaml` ships per RFC-012/ADR-075 floor (discharges the R009 prose-surface modulator); OR
- The user explicitly directs reinstate at retro time (e.g. "ship slice 1 standalone — Phase 2 is decoupled").

Tracked in P205 verifying ticket under "Outstanding sub-decisions queued".
