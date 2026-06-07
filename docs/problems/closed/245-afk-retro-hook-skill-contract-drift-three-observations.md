# Problem 245: AFK iter retro surfaces three hook-vs-SKILL-contract drift observations (external-comms key derivation; P165 README refresh on capture; P141 changeset-discipline held-area awareness)

**Status**: Closed
**Reported**: 2026-05-17
**Closed**: 2026-06-08 (work-problems AFK iter — superseded; all three observations addressed by subsequent fixes)
**Priority**: 3 (Medium) — Impact: 3 x Likelihood: 1 (deferred — re-rate at next /wr-itil:review-problems)
**Effort**: M (deferred — re-rate at next /wr-itil:review-problems)

## Description

AFK iter retros (observed in P087 iter-9 session 4) surface three hook-vs-SKILL-contract friction observations that compose into a single coordinating fix per Step 4b coordinating-ticket rule:

**(1) External-comms marker key derivation byte-equality requirement is under-documented.** The hook computes `sha256(DRAFT + '\n' + SURFACE)` where DRAFT is extracted from the agent prompt's `<draft>...</draft>` block (`packages/risk-scorer/hooks/lib/external-comms-key.sh` line 25-43). The PreToolUse gate (`external-comms-gate.sh` line 234) hashes the full Write tool `content` field. For the marker to match, the agent's `<draft>` block content must byte-equal the eventual Write tool `content` — including YAML frontmatter, leading/trailing whitespace, and exact line breaks. The SKILL.md text (`/wr-risk-scorer:assess-external-comms` Step 3) says *"wrap the draft body verbatim inside `<draft>...</draft>` markers"* without clarifying whether `body` means file-content (frontmatter + body) or post-frontmatter prose. Observed P087 iter-9 session 4 at three retries: agent reviewed body-only first (marker `faa124b7...`), then re-reviewed with frontmatter included (marker `8da8ad96...`), eventually bypassed by writing the file via Bash heredoc to dodge the Write/Edit gate entirely. Each retry re-invokes the wr-risk-scorer:external-comms agent (≥1 minute + tokens per retry).

**(2) P165 README refresh hook fires on capture-problem commits despite the SKILL contract's deferred-refresh promise.** `/wr-itil:capture-problem` Step 6 explicitly contracts *"Do NOT stage docs/problems/README.md ... deferred to next /wr-itil:review-problems"*. P165 readme-refresh hook (`packages/itil/hooks/itil-readme-refresh-discipline.sh` + `readme-refresh-detect.sh`) detects ticket-file change + missing README staged file and denies. The hook is unaware of the SKILL's deferred-refresh contract; documented workaround is `BYPASS_README_REFRESH_GATE=1`. Inline env vars on `git commit` do NOT propagate to the hook subprocess — propagation requires `.claude/settings.json` `env:` block. AFK iters thus either (a) fight the hook with three deny cycles before falling back to inline README refresh + add (defeating the SKILL's speed promise), or (b) edit `.claude/settings.json` env block (harness-config edit during AFK; risky). Observed P087 iter-9 capture of P244 — Step 6 commit denied, agent inline-refreshed README and re-staged, ~3 minutes of friction for a "lightweight aside" capture.

**(3) P141 changeset-discipline hook denies the documented held-area `git mv` as a single commit.** `docs/changesets-holding/README.md` Process line 17 names *"`git mv .changeset/<name>.md docs/changesets-holding/<name>.md`"* as the standard reinstate pattern. The P141 hook (`packages/itil/hooks/itil-changeset-discipline.sh` + `lib/changeset-detect.sh`) recognises `.changeset/*.md` as a valid changeset location but NOT `docs/changesets-holding/*.md`. A commit shipping `packages/<plugin>/` source plus a `.changeset/*.md` move to held-area in ONE operation gets denied because the hook sees source change + no `.changeset/*.md` staged. AFK iters must split into (a) commit source + changeset in `.changeset/` first, (b) commit the `git mv` move to held-area second — 2-commit decomposition for one logical concern. Observed P087 iter-9 at the Phase 3a → held-area transition; both commits were single-concern and clean but the split is purely hook-imposed friction. The hook bypass `BYPASS_CHANGESET_GATE=1` doesn't propagate as inline env (same friction as observation 2).

All three observations are AFK-iter-retro friction sources where hook contracts have drifted from documented SKILL-level carve-outs. Each is a narrow, well-bounded per-hook amendment.

## Symptoms

- External-comms gate retries (observation 1): agent invocation ≥3× per gated Write/Edit; ~1 minute + agent tokens per retry. Observed P087 iter-9 session 4.
- P165 deny on capture (observation 2): one or more `BLOCKED: P165` denies per capture-problem invocation; documented bypass requires harness-config edit. Observed P087 iter-9 P244 capture.
- P141 deny on held-area move (observation 3): one `BLOCKED: P141` deny per multi-concern (`source + held-area move`) commit attempt; forces 2-commit decomposition. Observed P087 iter-9 Phase 3a → held-area transition.

## Workaround

- Observation 1: write the gated file via Bash heredoc (`cat > .changeset/... <<EOF`) to bypass Write/Edit gating; OR re-invoke external-comms agent with `<draft>` block byte-matching the eventual Write content.
- Observation 2: inline-refresh README.md and stage it alongside the ticket — defeats the deferred-refresh SKILL contract but satisfies the hook.
- Observation 3: split into 2 commits (source + changeset in `.changeset/` first, then `git mv` to held-area).

## Impact Assessment

- **Who is affected**: solo-developer + tech-lead personas running AFK `/wr-itil:work-problems` iters that publish (which triggers changeset gates, README-refresh gates, and external-comms gates). Frequency scales with publish frequency. Plugin-developer persona authoring capture-problem-shape skills is also affected.
- **Frequency**: 100% of capture-problem invocations in AFK iters (observation 2); 100% of held-area moves in single-commit shape (observation 3); ≥50% of changeset-author surfaces in AFK iters when the agent reviews body-only first (observation 1).
- **Severity**: Moderate — each observation produces 1-3 minutes of friction per iter + ≥1 agent re-invocation. Cumulative across iters: significant token cost + AFK iter-time bloat.
- **Analytics**: Observed P087 iter-9 session 4 specifically; pattern is presumed recurrent across prior AFK iters but not measured.

## Root Cause Analysis

### Structural

Three hooks were authored at different times against different SKILL contract surfaces; the hooks pre-date or post-date the SKILL contracts in different patterns. Common root: hooks check syntactic conditions (file path / staged set / hash equality) rather than reading the SKILL contract's deferred-refresh / held-area-pattern / agent-prompt-shape semantics.

### Investigation Tasks

- [ ] Re-rate Priority and Effort at next /wr-itil:review-problems
- [ ] **Observation 1 amendment**: extend `packages/risk-scorer/hooks/lib/external-comms-key.sh` docstring with an explicit example showing the YAML frontmatter inside `<draft>...</draft>`; OR extend `/wr-risk-scorer:assess-external-comms` Step 3 with a worked example for changeset-author surface specifically. Behavioural bats fixture asserts a frontmatter-including `<draft>` block produces a hash matching the Write tool's full-content hash.
- [ ] **Observation 2 amendment**: extend `packages/itil/hooks/lib/readme-refresh-detect.sh` with a commit-message-pattern allowlist for capture-shape commits (`docs(problems): capture P<NNN> ...`) per ADR-014; OR extend the `/wr-itil:capture-problem` SKILL Step 6 to acknowledge the hook fires and document the recommended pattern (inline refresh + stage, dropping the deferred-refresh promise from the SKILL). Behavioural bats fixture asserts capture-shape commits pass without README.md staged.
- [ ] **Observation 3 amendment**: extend `packages/itil/hooks/lib/changeset-detect.sh` to recognise `docs/changesets-holding/*.md` as a valid changeset location for the held-area-pattern carve-out; OR extend `docs/changesets-holding/README.md` Process to name the 2-commit decomposition as canonical. Behavioural bats fixture asserts a commit with source + held-area `git mv` (no `.changeset/*.md` staged) passes when the held-area README is also staged.
- [ ] Consider whether the three observations warrant a unified "hook contract awareness of SKILL contract carve-outs" pattern ADR.

## Dependencies

- **Blocks**: (none — observations are independent)
- **Blocked by**: (none — each amendment is bounded)
- **Composes with**: P165 (README refresh hook), P141 (changeset-discipline hook), P166 (external-comms hook-side sha256), capture-problem SKILL contract, held-area README Process

## Related

- P087 — observation source (iter-9 session 4 retro)
- P244 — same iter sibling: F9 plugin-maturity-list shim capture (exhibited observation 2 during its commit)
- P165 — readme-refresh-discipline hook (observation 2 target)
- P141 — changeset-discipline hook (observation 3 target)
- P166 — external-comms hook-side sha256 derivation (observation 1 hook-side surface)
- P155 — capture-problem driver
- ADR-014 — single-commit grain (held-area move violates this when split as 2 commits per observation 3)
- ADR-042 — auto-apply move-to-holding remediation (observation 3 surfaces in this surface)
- ADR-049 — bin/ on PATH (amendment shim grammar)
- ADR-052 — behavioural-tests-default for hook amendments

(captured via /wr-itil:capture-problem; expand at next investigation)

## Closure

Closed 2026-06-08 (work-problems AFK iter — superseded; all three bundled observations addressed by subsequent fixes shipped this session and earlier). ADR-079 Phase 2 shape 3 (sibling-fix-supersedes).

**Observation 1 (external-comms key derivation byte-equality)** — addressed by **P010 / ADR-028 amended 2026-05-25**. `packages/risk-scorer/hooks/lib/external-comms-key.sh::compute_external_comms_key` (lines 48-61) is the SINGLE canonical normalization shared byte-identically between the gate (PreToolUse) and the mark hook (PostToolUse). For `changeset-author` surface it strips the leading YAML frontmatter block (`re.sub(r'^---\n.*?\n---\n\n?', '', draft, count=1, flags=re.DOTALL)`) and for all surfaces it rstrips trailing whitespace. Whether the agent wraps body-only or includes the frontmatter inside `<draft>`, both sides hash to byte-equal keys — the gate sees the FULL Write content and strips frontmatter; the mark hook sees the `<draft>` body and strips frontmatter if present. The retry-loop symptom from the ticket (≥3 invocations of the external-comms agent per gated Write) cannot recur. The deny message in `external-comms-gate.sh:311` also explicitly instructs the agent on body scope: *"for the changeset-author surface the body is the changeset summary WITHOUT the leading `---` frontmatter block — the gate strips frontmatter before hashing the marker key"*.

**Observation 2 (P165 README refresh on capture)** — addressed by **P262 / P265** (`@windyroad/itil` ≥ 0.35.x; sibling `capture-deferred-readme` RISK_BYPASS trailer). `packages/itil/hooks/lib/readme-refresh-detect.sh` line 149 registers `capture-deferred-readme` in `_README_REFRESH_BYPASS_TRAILERS`; lines 195-197 clear the gate when a registered trailer is present. The `/wr-itil:capture-problem` Step 6 commit subject (`docs(problems): capture P<NNN> ...`) carries `RISK_BYPASS: capture-deferred-readme` in its message body per ADR-014 commit-message bypass-token table. The SKILL's deferred-refresh contract is preserved — no inline README refresh required at capture time, deferred to the next `/wr-itil:review-problems` per ADR-032.

**Observation 3 (P141 changeset-discipline held-area awareness)** — addressed by **P177** (`packages/itil/hooks/lib/changeset-detect.sh` lines 209-223). The hook now explicitly recognises `docs/changesets-holding/*.md` as a held-window changeset per ADR-042 Rule 7 held-window blessing (`has_changeset=1` on this path; `docs/changesets-holding/README.md` excluded as meta-doc mirroring the `.changeset/README.md` exclusion). A commit shipping `packages/<plugin>/` source + a `git mv` of a changeset to the held-area clears the gate in one operation — no 2-commit decomposition required. Release/drain semantics unchanged (the Release workflow reads `.changeset/` only).

All three Investigation Tasks satisfied at verification — each by a sibling fix landed without requiring P245's own coordinating-ticket Phase 2/3 amendments. KE→Closed direct per ADR-079 lifecycle extension. No code change at this closure. Reversible via `/wr-itil:transition-problem 245 known-error`.
