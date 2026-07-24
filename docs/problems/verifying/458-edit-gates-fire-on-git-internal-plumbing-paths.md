# Problem 458: Edit Gates Fire on Git-Internal Plumbing Paths

**Status**: Verifying
**Reported**: 2026-07-24
**Priority**: 8 (Medium) — Impact: 2 × Likelihood: 4 — derived at capture from the description per Step 4a
**Origin**: internal
**Effort**: S — derived at capture per Step 4a; cf. P004's fix shape (one shared path-scope check + bats across the gate family)
**JTBD**: JTBD-001
**Persona**: developer

## Description

Edit-gate family fires on writes to `.git/` plumbing paths: writing a commit-message scratch file at `.git/cruise-brake-commit-msg.txt` was blocked twice in one session — first by the architect PreToolUse gate, then by the JTBD gate — each requiring a full agent delegation before a non-project git-plumbing file could be written. `.git/` is never a project artefact; the gates' path matchers treat any Write under the repo tree as a project-file edit. Class defect across the shared detector plumbing (architect, JTBD, and likely style-guide/voice-tone/TDD edit gates): `.git/` (and other VCS-internal paths) should be on the class-level exclusion list. Observed 2026-07-24 while releasing the cruise brake fix; cost two synchronous agent reviews (~160k subagent tokens) to write one scratch file, and the user flagged the absurdity twice mid-turn.

Likelihood is Likely (4) because writing the commit message to a `.git/`-resident file is the documented workaround for the external-comms commit-msg gate (P415 `-F <file>` shape and the P303 external-terminal flow both write `.git/<name>.txt`), so every fresh session using that pattern re-hits the gates.

## Symptoms

- `Write` to `.git/cruise-brake-commit-msg.txt` → "BLOCKED: Cannot edit 'cruise-brake-commit-msg.txt' without architecture review"
- After architect review, the same Write → "BLOCKED: Cannot edit 'cruise-brake-commit-msg.txt' without JTBD review"
- Two synchronous agent delegations (~160k subagent tokens) required before one git-plumbing scratch file could be written

## Workaround

Run the per-session architect + JTBD reviews (they unblock the whole session), or write the file via bash redirection instead of the Write tool.

## Impact Assessment

- **Who is affected**: developers in any repo with the wr-architect/wr-jtbd (and sibling) edit gates installed — home repo and adopters alike
- **Frequency**: every session that writes a commit-message file (or any scratch file) under `.git/` before the gates' per-session markers exist
- **Severity**: Minor — latency + token cost + user-visible absurdity; no data loss, gates fail closed not open
- **Analytics**: N/A

## Root Cause Analysis

### Preliminary Hypothesis

P004 added a project-root scope check to all six enforce hooks (files *outside* the repo pass through), but `.git/` sits *inside* the repo root, so it passes the project-scope test and falls through to the extension/path matchers. The exclusion lists never name VCS-internal directories. The fix is the P004 sibling: a `.git/` (VCS-internal) path-prefix exclusion in the shared detector plumbing, covering the whole gate family, with bats per gate.

### Investigation Tasks

- [ ] Confirm which of the six enforce hooks share the detector path-matcher (architect, JTBD, voice-tone, style-guide, risk-policy/WIP, TDD)
- [ ] Add `.git/` path-prefix exclusion at the shared detector layer (edit the packages/shared canonical + run its sync script, not consumer copies)
- [ ] Bats: Write to `.git/<file>` passes each gate without a review marker
- [ ] Create reproduction test

## Fix Released

Released 2026-07-24. Added a `*/.git/*|.git/*) exit 0` VCS-internal exclusion to all five enforce-edit gates, placed before the extension/classification/policy checks so it short-circuits. Shipped in `@windyroad/architect@0.20.2`, `@windyroad/jtbd@0.13.1`, `@windyroad/voice-tone@0.7.1`, `@windyroad/style-guide@0.5.1`, `@windyroad/tdd@0.5.1` (commit `6abb4ef1`). Behavioural bats added to all five scope suites (incl. a contrast "still blocks" case), all green. Verification pending: with the refreshed plugin cache active (restart required), a `Write` to a `.git/` path passes each gate without a review marker.

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)
- **Composes with**: (none)

## Related

- P004 (closed) — Edit Gates Block Non-Project Files: fixed the outside-the-repo case; this ticket is the inside-the-repo `.git/` sibling the P004 fix left uncovered.
- P415 — external-comms commit-msg gate `-F <file>` workaround is what routes commit messages into `.git/`, making this collision recurrent.
- P303 — external-terminal commit flow also writes `.git/<name>.txt`.

(captured via /wr-itil:capture-problem; expand at next investigation)
