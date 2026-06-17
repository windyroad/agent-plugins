# Problem 276: external-comms gate marker over-fires on PASS-class content edits (P073 surface)

**Status**: Verification Pending
**Reported**: 2026-05-19
**Priority**: 3 (Medium) — Impact: 3 x Likelihood: 1 (excluded from WSJF — Verification Pending per ADR-022)
**Effort**: S (actual — single-file normalize() extension in 3 byte-identical copies + 7 behavioural bats; re-rated down from M after root cause confined to one helper)

## Description

Two `wr-risk-scorer:external-comms` re-reviews fired during session 8 iter 2 (P269) work — once for changeset frontmatter expansion, once for a "12 → 11 plugins" single-numeral edit. Both reviews returned PASS unconditionally. ~20s + token spend per re-review on edits the gate cannot meaningfully assess.

The content-hash marker derivation (P073 surface) considers any change to the affected file as a marker invalidation, triggering a fresh review-cycle. For edits that are syntactically minor and semantically PASS-class (whitespace normalisation, single-numeral updates, frontmatter shape expansion), the re-review cost exceeds the value the gate adds.

**Proposed fix shape**: amend the content-hash marker derivation to either (a) normalise whitespace + single-numeral edit-distance before hashing OR (b) provide a re-review affordance for trivial post-PASS tweaks.

## Symptoms

A `wr-risk-scorer:external-comms` (or `wr-voice-tone:external-comms`) subagent re-review fires on the second-and-later Write/Edit/Bash of an outbound-prose surface within a session, even when the only change since the prior PASS was semantically PASS-class (interior CRLF/CR line endings, per-line trailing whitespace, frontmatter shape). Each re-review costs ~20s + tokens and returns PASS unconditionally.

## Workaround

User explicit direct or agent manual affordance. Friction.

## Impact Assessment

- **Who is affected**: any maintainer + AFK orchestrator iter that touches changeset frontmatter or docs/problems/README.md inline during a multi-commit iter.
- **Frequency**: ~2 per AFK iter where iter touches gated content surfaces; cost ~20s + tokens per re-review.
- **Severity**: Low — friction/cost only (redundant tokens + ~20s latency); no correctness or leak-safety impact (the re-review always PASSes and the leak pre-filter runs regardless).

## Root Cause Analysis

**Root cause (confirmed 2026-06-17).** The external-comms review marker is keyed on the *byte content* of the draft: `compute_external_comms_key(draft, surface) = sha256(normalize(draft, surface) + '\n' + surface)` (`packages/{shared,risk-scorer,voice-tone}/hooks/lib/external-comms-key.sh`, consumed by `external-comms-gate.sh` at PreToolUse and the PostToolUse mark hook). Before the fix, `normalize()` did only two things: (1) strip the leading YAML frontmatter block on the `changeset-author` surface, and (2) a single whole-draft trailing-whitespace rstrip. Every *other* byte difference in the draft — including semantically PASS-class reformatting (interior CRLF/CR line endings, per-line trailing whitespace) — produced a different key, so the prior PASS marker no longer matched and the gate re-fired a full subagent re-review (~20s + tokens) on edits it cannot meaningfully re-assess.

**The two original trigger cases, resolved separately:**

1. **Changeset frontmatter expansion** — already neutralised by the `changeset-author` frontmatter strip shipped in 56bae5ff (#149 / P010). On that surface the entire `---…---` block is stripped before hashing, so frontmatter shape changes are invisible to the key. No further work needed for this case.
2. **`12 → 11 plugins` single-numeral edit** — a genuine content-byte change. Deliberately **not** neutralised (see decision below).

**Decision — option (a) whitespace-normalise hashing vs option (b) re-review affordance:** option (a) chosen, in its security-safe form.

- **Option (a) adopted (security-safe subset).** Extend `normalize()` to tolerate trivial reformatting (CRLF/CR → LF, per-line rstrip, whole-draft rstrip) to parity with the ADR-009 `_substance_normalize_then_hash` precedent already used by the policy-file-drift gates. This neutralises the reformatting class of over-fire deterministically, with no agent judgement. Key *shape* is unchanged (no trailing `\n` appended), so existing session markers and all prior key computations stay byte-stable.
- **Single-numeral / edit-distance tolerance REJECTED on security grounds.** A single-numeral change can itself be a confidential-figure leak (a financial figure or a user/customer count — exactly the business-context-paired classes `leak-detect.sh` targets). The leak pre-filter is pattern-based and not exhaustive; the subagent re-review is the defense-in-depth layer behind it. Tolerating numeral edits inside the key would open a bypass: obtain a PASS marker on benign content, then mutate a numeral to inject a leak with no re-review. So single-numeral and word/content edits stay **substantive** — the key changes and review re-fires (boundary bats 4 + 5).
- **Option (b) re-review affordance NOT pursued.** A "mark this tweak trivial, reuse the prior PASS" affordance re-introduces agent self-certification into a security gate — the precise judgement the content-hash marker exists to remove. Option (a)'s deterministic normalisation delivers the same friction reduction without that judgement, so (b) is unnecessary.

**Residual reclassification.** P276's remediable over-fire (trivial reformatting) is fixed. The residual single-numeral re-review is **correct behaviour, not a defect** — it is the price of the leak-detection guarantee. The ticket's proposed fix shape is therefore satisfied in full.

### Investigation Tasks

- [x] Re-rate Priority and Effort — Effort re-rated M → S (single helper, 3 byte-identical copies); Priority now excluded from WSJF (Verification Pending per ADR-022)
- [x] Investigate root cause — content-hash marker derivation keys on draft bytes; pre-fix `normalize()` tolerated only frontmatter-strip + whole-draft rstrip (see above)
- [x] Survey value-add of re-review for genuinely different content vs whitespace/numeral edits — whitespace/CRLF reformatting = zero value-add (tolerated); single-numeral/content edits = real leak-surface (review correctly re-fires)
- [x] Create reproduction test — `packages/risk-scorer/hooks/test/external-comms-key-substance.bats` (7/7 GREEN), with synced copies in shared + voice-tone

## Fix Released

Substance-aware draft normalization landed in `compute_external_comms_key` (commit `60e94d2a`, changeset backfill `8ed545a1`) and released in **@windyroad/risk-scorer@0.13.1** and **@windyroad/voice-tone@0.5.11** (version-bump `3d8f45b0`, 2026-06-16; both since superseded by 0.13.4 / 0.5.14). `normalize()` now applies CRLF/CR → LF + per-line rstrip + whole-draft rstrip; ADR-028 carries the Amendment 2026-06-16 P276 follow-on entry. 7 behavioural bats GREEN (`external-comms-key-substance.bats`), broader suites GREEN (157/157 risk-scorer + 65/65 voice-tone).

**To verify:** make a trivial PASS-class reformatting tweak (e.g. add/remove trailing whitespace or change line endings) to a draft already reviewed PASS in-session — the external-comms gate should permit silently with no re-review. Then make a single-numeral or word edit — the gate should correctly re-fire the subagent review.

## Dependencies

- **Composes with**: P073 (content-hash marker derivation), P166 + P163 + P198 (external-comms gate marker friction cluster), ADR-028 (external-comms voice-tone gate)

## Related

(captured 2026-05-19 from /wr-itil:work-problems session 8 iter 2 (P269) deviation-approval queue, user-directed via AskUserQuestion at Step 2.5)

- P073 — content-hash marker derivation parent
- P166, P163, P198 — sibling external-comms gate friction
- ADR-028 — external-comms voice-tone gate
