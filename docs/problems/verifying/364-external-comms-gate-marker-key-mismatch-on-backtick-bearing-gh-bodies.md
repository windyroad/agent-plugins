# Problem 364: External-comms gate marker key mismatch on backtick-bearing gh bodies

**Status**: Verification Pending
**Reported**: 2026-06-11
**Priority**: 3 (Medium) — Impact: 3 x Likelihood: 1 (deferred — re-rate at next /wr-itil:review-problems)
**Origin**: internal
**Effort**: S (actual — one gate-extraction edit + behavioural bats in both consumers + one ADR amendment)
**JTBD**: JTBD-001
**Persona**: developer

## Description

External-comms gate marker key derivation mismatches on backtick-bearing gh bodies — a PASS-reviewed draft containing markdown backticks never unlocks the gh issue comment post, because the --body shell argument carries backslash-escaped backticks while the reviewed `<draft>` block carries plain ones; the PostToolUse marker key hash differs and the PreToolUse gate denies repeatedly. Witnessed 2026-06-11 AFK iter 3 (P228 upstream comment to windyroad/agent-plugins#42): two structured-format reviews (~21K subagent tokens each) blocked until the body was re-drafted without backticks, after which the identical flow passed both evaluators serially. Fix candidates: normalize/unescape the body before hashing on both PreToolUse + PostToolUse sides, or document a --body-file canonical contract, or strip markdown code-span formatting in the gate's hash input. Composes with P276 (over-fire on PASS-class content edits — different failure mode: this is key-mismatch, not over-fire) and P360 (serial evaluator discovery also witnessed this iter).

## Symptoms

(deferred to investigation)

## Workaround

Re-draft the outbound body WITHOUT backticks (plain names instead of code spans) so the double-quoted `--body "..."` shell argument is byte-identical to the reviewed `<draft>` content; then run the structured review (`SURFACE: gh-issue-comment` first line + `<draft>` wrapper) once per evaluator (risk, then voice-tone) and retry the post.

## Impact Assessment

- **Who is affected**: (deferred to investigation)
- **Frequency**: (deferred to investigation)
- **Severity**: (deferred to investigation)
- **Analytics**: (deferred to investigation)

## Root Cause Analysis

**Root cause**: The marker-key byte-symmetry invariant (ADR-028's load-bearing property — the PreToolUse gate's extracted `DRAFT` and the PostToolUse mark hook's `<draft>` body must hash byte-identical input) is violated on the gh double-quoted surface. On the Bash surface the gate extracts `--body "..."` from the **raw command text** via regex (`packages/shared/hooks/external-comms-gate.sh`). When the body contains markdown backticks, an orchestrator must backslash-escape them to survive bash double-quote parsing — `--body "Fixed in \`code\` ..."` — so the gate's captured `DRAFT` carries literal backslash-escaped backticks. The mark hook (`lib/external-comms-key.sh` `compute_external_comms_key`) hashes the **logical** `<draft>` body the agent emitted (plain backticks). `sha256(\`\\\`code\\\`\` + '\n' + surface) ≠ sha256(\`\`code\`\` + '\n' + surface)`, so the PASS marker lands at a key the gate never re-reads → permanent deny-after-PASS. Confirmed empirically: the double-quote regex `--body[= ]"([^"]*)"` captures the raw inter-quote bytes without any shell unescaping. This is a **shell-escaping-layer** asymmetry that exists only because the gate reads shell-escaped command text whereas the mark hook (and the changeset `Write` path) read already-logical text — **distinct from** P276/P010 (whitespace/CRLF/frontmatter inside `compute_external_comms_key`).

**Fix**: Unescape bash double-quote backslash-escapes in the gate's **Bash-surface body extraction only**. After a **double-quoted** capture group matches (`--body "…"`, `--field x="…"`, `-m`/`--message "…"`), pass the captured text through `unescape_dq` (`\$`→`$`, `` \` ``→`` ` ``, `\"`→`"`, `\\`→`\`, line-continuation removed) in a single left-to-right pass so an escaped backslash adjacent to another escape (`\\\`` → `\` + `` ` ``) is not mis-collapsed. The gate's `DRAFT` thereby becomes byte-equal to the logical `<draft>` body, **restoring** the invariant. Single-quoted `'…'` and `<<'EOF'` heredoc forms stay literal (bash does not process backslashes there — unescaping them would *introduce* a mismatch); each pattern carries an explicit `unescape` flag, `True` only for the three double-quoted forms. `compute_external_comms_key` is left **unchanged** — it is the single shared normaliser used by the gate, the mark hook, and the changeset `Write` path (the latter two carry logical text; unescaping there would corrupt them). Canonical edit at `packages/shared/hooks/external-comms-gate.sh`, synced byte-identically to `packages/{risk-scorer,voice-tone}/hooks/` (ADR-017, `--check` green). Recorded as an ADR-028 dated amendment (2026-06-16, P364).

### Investigation Tasks

- [x] Re-rate Priority and Effort at next /wr-itil:review-problems — Effort confirmed **S** (one gate-extraction edit + behavioural bats + ADR amendment); Priority unchanged at 3 (re-rate formally at next review)
- [x] Investigate root cause — gate hashes the **raw shell-escaped** `--body` argument text while the mark hook hashes the **logical** `<draft>` body; the escaping layer is bash double-quote backslash-escaping of backticks/`$`/`"`/`\` (above). Confirmed empirically with the `--body[= ]"([^"]*)"` capture regex.
- [x] Create reproduction test — behavioural bats added to both consumers' `external-comms-gate.bats`: (1) backtick-bearing double-quoted `--body` permits when the marker is keyed on the unescaped logical body; (2) adjacency edge case `\\\`` → literal backslash + backtick (single-pass guard); (3) single-quoted `--body` with literal backticks stays literal (no-unescape regression guard). RED on (1)+(2) before the fix, GREEN after; (3) green throughout. Behavioural per ADR-052 (exercises the gate hook end-to-end, not a structural grep on its source).

## Fix Released

- **2026-06-16 (this session, AFK work-problems iter 35)** — `unescape_dq` bash double-quote unescape added to the gate's Bash-surface body extraction at canonical `packages/shared/hooks/external-comms-gate.sh`, synced to `packages/{risk-scorer,voice-tone}/hooks/external-comms-gate.sh` (`scripts/sync-external-comms-gate.sh --check` green). Behavioural bats added to both consumers' `external-comms-gate.bats` (26 + 25 cases green). ADR-028 dated amendment recorded. `@windyroad/{risk-scorer,voice-tone}` patch changeset added. Committed under ADR-014 single-commit grain. **Pending**: release verification (no push/release in AFK) — after release, confirm a backtick-bearing `gh issue comment --body "…\`code\`…"` post unlocks on a single PASS review, then close.

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)
- **Composes with**: P276, P360

## Related

(captured via /wr-itil:capture-problem; expand at next investigation)

- **P276** — external-comms gate marker over-fires on PASS-class content edits; different failure mode at the same gate surface (over-fire vs key-mismatch).
- **P360** — gates discover unmet evaluators serially (~19K tokens each round-trip); the serial risk-then-voice-tone discovery was re-witnessed during this capture's driver incident.
- **P163** (closed) — external-comms agent emitted placeholder marker key on first invocation; prior marker-key defect class at the same gate, fixed separately.
- Driver incident: 2026-06-11 AFK work-problems iter 3 — P228 fix-released lifecycle comment to windyroad/agent-plugins#42; two blocked posts with backticked body, success after backtick-free re-draft. Briefing entry added to `docs/briefing/hooks-and-gates.md` § What Will Surprise You same session.

## Fix Strategy

**Kind**: improve
**Shape**: hook
**Target file**: the external-comms gate hook pair (PreToolUse deny + PostToolUse marker-writer) in `packages/risk-scorer/hooks/` — marker-key derivation path.
**Edit summary**: make the marker-key hash input canonical across both sides — e.g. unescape shell backslash-escapes (or hash the parsed `--body` argument value rather than raw command text) so a PASS review of the literal draft unlocks the literal post; alternatively document and support a `--body-file` canonical contract.
**Evidence**: 2026-06-11 iter 3 — backticked body: review PASS, post BLOCKED (×2, ~21K subagent tokens each); backtick-free body: identical flow, both evaluators unlocked serially, post succeeded.
