# Problem 225: Docs-only changes should not invoke risk scorer or trigger drift detection

**Status**: Open
**Reported**: 2026-05-15
**Priority**: 3 (Medium) — Impact: 3 x Likelihood: 1 (deferred — re-rate at next /wr-itil:review-problems)
**Effort**: M (deferred — re-rate at next /wr-itil:review-problems)
**Type**: technical

> **safe-high-fix-risk flag** (per dual-axis-risk classifier): "skip the gate when path matches `*.md`" is a classic load-bearing-safety-check-bypass shape. An over-broad allowlist could let ADR-text changes (which materially affect framework behaviour) or hook-adjacent READMEs escape review. Maintainer must adjudicate the precise allowlist scope (which docs? including `docs/decisions/`?) before merge.

## Description

The risk-scorer hooks treat documentation-only changes (problem tickets, decision records, risk reports, markdown files in `docs/`) the same as code changes. This causes: (1) wasted scoring, (2) false drift detection on architect / jtbd / style-guide gates for routine docs writes.

## Investigation Tasks

- [ ] Re-rate Priority and Effort at next /wr-itil:review-problems
- [ ] **Architect call (safe-high-fix-risk)**: define the docs-only allowlist precisely. `docs/decisions/` changes are NOT docs-only — they materially affect framework behaviour. Likely scope: `docs/problems/*.md`, `docs/retros/`, `docs/audits/`, `docs/briefing/`, ticket READMEs. Excludes: `docs/decisions/`, `docs/jtbd/`, `RISK-POLICY.md`, `STYLE-GUIDE.md`, `VOICE-AND-TONE.md`, hook-adjacent READMEs.
- [ ] Each gate hook adds the docs-only short-circuit at the top: `is_docs_only_change && exit 0`.

## Related

- **Reported Upstream**: https://github.com/windyroad/agent-plugins/issues/58
- **Pipeline classification**: **safe-high-fix-risk** (cache_audit_note: high-fix-risk-flag); route=safe-and-valid + flag.
- **Affected plugin**: all gate plugins.
