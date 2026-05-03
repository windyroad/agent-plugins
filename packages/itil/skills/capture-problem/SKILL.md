---
name: wr-itil:capture-problem
description: Lightweight problem-capture skill for aside-invocation during foreground work — minimal duplicate-check, skeleton ticket file, single commit per capture, no inline README refresh. Defers full duplicate analysis and README refresh to /wr-itil:review-problems. Use this when the user (or agent mid-iter) wants to capture an observation quickly without disrupting current task flow. For full-intake new-problem creation, use /wr-itil:manage-problem.
allowed-tools: Read, Write, Edit, Bash, Grep, Glob
---

# Capture Problem Skill

Capture a problem ticket quickly during foreground work. Lightweight aside-invocation surface that complements the heavyweight `/wr-itil:manage-problem` flow. See `REFERENCE.md` in this directory for rationale, edge cases, contract trade-offs, and the ADR-032 foreground-lightweight-capture amendment.

This skill is the foreground-lightweight-capture variant of `/wr-itil:manage-problem`'s new-problem path per ADR-032 (P155 amendment, 2026-05-03). The deferred background-capture variant named in ADR-032's original taxonomy remains deferred per P088 settlement.

## When to invoke

- **Mid-iter sibling-finding**: agent observes a tangential ticket-worthy issue while working on a different problem and cannot afford the 10-turn `/wr-itil:manage-problem` ceremony.
- **User-initiated rapid capture**: user says "btw, this is broken too — capture it" during retros, code reviews, or correction conversations.
- **AFK orchestrator main turn captures**: orchestrator captures user-driven mid-loop observations without breaking the iter cadence.

**Use `/wr-itil:manage-problem` instead** when:
- The user wants to walk the full intake flow (priority discussion, multi-concern split, immediate WSJF placement).
- The capture is large enough that deferred-investigation placeholders are unhelpful (the description IS the full ticket body).
- The capture needs to ride alongside an immediate fix (`fix(scope): ... (closes P<NNN>)` shape — manage-problem's Step 7 transition + Step 11 commit handles this; capture-problem does not).

## Rule 6 audit (per ADR-032 + ADR-013)

This skill has **zero AskUserQuestion branches** by design. Each potentially-interactive decision is framework-mediated per ADR-044:

| Decision | Resolution |
|----------|-----------|
| Duplicate-check | Mechanical 3-keyword title-only grep; matches listed in report; capture proceeds regardless. False-positives are cheaper than false-negatives (P155 line 24). |
| Priority default | Framework-policy: `3 (Medium) — Impact 3 × Likelihood 1` flagged "deferred — re-rate at next /wr-itil:review-problems". |
| Effort default | Framework-policy: `M` flagged "deferred — re-rate at next /wr-itil:review-problems". |
| Multi-concern split | Out of scope: capture-problem creates one ticket per invocation. Multi-concern observations route to `/wr-itil:manage-problem` (its Step 4b owns the split). |
| Empty `$ARGUMENTS` | Halt-with-stderr-directive: print "capture-problem requires a description in $ARGUMENTS — invoke /wr-itil:manage-problem instead for the full intake flow" and exit. AFK orchestrators MUST NOT invoke capture-problem with empty arguments — caller-side contract. |

Per ADR-013 Rule 6 fail-safe: every branch above resolves without user input, so AFK and interactive contexts behave identically.

## Steps

### 0. README reconciliation preflight (P118)

Same as `/wr-itil:manage-problem` Step 0 — diagnose-only check. Halt-and-route on Exit 1 (committed cross-session drift); INLINE_REFRESH carve-out (P149) preserved. capture-problem itself does NOT refresh README.md (see Step 6); the preflight is purely a fail-fast on pre-existing drift.

```bash
wr-itil-reconcile-readme docs/problems > /tmp/wr-itil-drift-$$.txt
reconcile_exit=$?
if [ "$reconcile_exit" -eq 1 ]; then
  wr-itil-classify-readme-drift /tmp/wr-itil-drift-$$.txt docs/problems
  classify_exit=$?
  rm -f /tmp/wr-itil-drift-$$.txt
  # classify_exit 0 (INLINE_REFRESH): proceed (no inline refresh in this skill).
  # classify_exit 1 (HALT_ROUTE_RECONCILE): halt; invoke /wr-itil:reconcile-readme.
  # classify_exit 2 (parse error): conservative halt-and-route.
fi
```

### 1. Parse the description from `$ARGUMENTS`

The description is the full free-text payload from `$ARGUMENTS`. Empty arguments halts per the Rule 6 audit above.

Derive a kebab-case title slug from the first 8-10 non-stopword tokens of the description (matching the existing `manage-problem` slug derivation pattern).

### 2. Minimal-grep duplicate check (3-keyword title-only)

Extract up to **3 distinct kebab-cased non-stopword keywords** from the description. Grep the **filenames** of `docs/problems/*.md` (NOT bodies — title-only is the conservative threshold per architect verdict on Q1):

```bash
match_count=$(ls docs/problems/*.md 2>/dev/null \
              | grep -ciE 'kw1|kw2|kw3' || true)
```

The **3-keyword cap** is a hard-coded constant. Do NOT make it env-overridable — the conservative threshold rationale (P155 line 24) is structural to the design, not a tunable knob.

**Title-only**: file bodies are intentionally NOT scanned. Body-content matches would either (a) over-prompt (capture-problem has no AskUserQuestion to surface them) or (b) get silently swallowed. Title-only matches preserve the conservative-threshold contract.

If matches are found: list them in the final report. **Do NOT halt or branch.** Capture proceeds. The user can resolve duplicates at the next `/wr-itil:review-problems` invocation (or invoke `/wr-itil:manage-problem` directly if the duplicate-check shape needs a structured branch).

**After the grep completes**, write the per-session create-gate marker so the `PreToolUse:Write` hook (P119) permits the subsequent Write of the new `.open.md` file:

```bash
source packages/itil/hooks/lib/session-id.sh
source packages/itil/hooks/lib/create-gate.sh
sid=$(get_current_session_id) && mark_step2_complete "$sid"
```

The marker is shared between `manage-problem` and `capture-problem` per ADR-032 amendment — same `/tmp/manage-problem-grep-${SESSION_ID}` path, idempotent across cross-skill ordering.

### 3. Compute the next ID

Same P056-safe local_max + origin_max formula as `/wr-itil:manage-problem` Step 3:

```bash
local_max=$(ls docs/problems/*.md 2>/dev/null | sed 's/.*\///' | grep -oE '^[0-9]+' | sort -n | tail -1)
origin_max=$(git ls-tree --name-only origin/main docs/problems/ 2>/dev/null | sed 's|^docs/problems/||' | grep -oE '^[0-9]+' | sort -n | tail -1)
next=$(printf '%03d' $(( $(echo -e "${local_max:-0}\n${origin_max:-0}" | sort -n | tail -1) + 1 )))
```

Log the renumber decision in the operation report if origin and local diverged.

### 4. Skeleton-fill the ticket

**File path**: `docs/problems/<NNN>-<kebab-title>.open.md`

**Template** (deferred-placeholder pattern — flag every section the capture didn't fill):

```markdown
# Problem <NNN>: <Title>

**Status**: Open
**Reported**: <YYYY-MM-DD>
**Priority**: 3 (Medium) — Impact: 3 x Likelihood: 1 (deferred — re-rate at next /wr-itil:review-problems)
**Effort**: M (deferred — re-rate at next /wr-itil:review-problems)

## Description

<full description from $ARGUMENTS>

## Symptoms

(deferred to investigation)

## Workaround

(deferred to investigation)

## Impact Assessment

- **Who is affected**: (deferred to investigation)
- **Frequency**: (deferred to investigation)
- **Severity**: (deferred to investigation)
- **Analytics**: (deferred to investigation)

## Root Cause Analysis

### Investigation Tasks

- [ ] Re-rate Priority and Effort at next /wr-itil:review-problems
- [ ] Investigate root cause
- [ ] Create reproduction test

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)
- **Composes with**: (none)

## Related

(captured via /wr-itil:capture-problem; expand at next investigation)
```

The deferred-placeholder pattern is load-bearing — `/wr-itil:review-problems` keys off the literal string `(deferred — re-rate at next /wr-itil:review-problems)` to surface captured tickets for re-rating.

### 5. Write the file

Single `Write` to `docs/problems/<NNN>-<kebab-title>.open.md`. The P119 PreToolUse hook permits the Write because Step 2 set the marker.

### 6. Commit per ADR-014 — single commit, no README refresh

**Stage list**: ONLY the new ticket file. **Do NOT** stage `docs/problems/README.md`. The deferred-README-refresh contract is the load-bearing distinction from `/wr-itil:manage-problem` — capture-time speed depends on skipping the regenerate-and-stage cycle.

```bash
git add docs/problems/<NNN>-<kebab-title>.open.md
```

Satisfy the commit gate per ADR-014 — same two-path pattern as manage-problem Step 11:

- **Primary**: delegate to subagent type `wr-risk-scorer:pipeline` via the Agent tool.
- **Fallback**: invoke `/wr-risk-scorer:assess-release` via the Skill tool when the subagent type is unavailable in the current tool surface.

Commit message:

```
docs(problems): capture P<NNN> <title>
```

The `capture` verb in the message is the audit signal that this ticket landed via the lightweight aside path (vs. `open` for manage-problem's full intake).

### 7. Report

After the commit, report:

- The new ticket file path and ID.
- The list of duplicate matches found (if any). If matches found, name them and remind the user to merge at next `/wr-itil:review-problems` if appropriate.
- Trailing pointer: `Run /wr-itil:review-problems next to fold P<NNN> into the WSJF rankings, re-rate the deferred placeholders, and refresh docs/problems/README.md.`

The trailing pointer is **not optional** — it is the user-visible signal that the README is transiently stale and how to reconcile it. Drift here re-opens the deferred-README-refresh contract gap.

## Composition with manage-problem

| Concern | manage-problem | capture-problem |
|---------|----------------|-----------------|
| Duplicate-check | Wide-net grep + AskUserQuestion branch on matches | 3-keyword title-only grep, list-only (no branch) |
| Multi-concern split | Step 4b AskUserQuestion | Out of scope (one ticket per invocation) |
| Skeleton-fill | Full-intake; AskUserQuestion for missing fields | Deferred-placeholder pattern; no AskUserQuestion |
| README refresh | P094 inline (regenerate + stage in same commit) | Deferred to next `/wr-itil:review-problems` |
| Status transitions | Step 7 owns Open → Known Error → Verifying → Closed | Out of scope (creation only) |
| Commit grain | One commit per intake (or per split-concern set) | One commit per capture |
| Use case | Full-intake new problem; user wants to walk the flow | Aside-invocation; capture-and-continue |

The two skills share the `/tmp/manage-problem-grep-${SESSION_ID}` create-gate marker per P119 — calling either skill's Step 2 grep + mark sequence permits new ticket Writes for the rest of the session, regardless of which skill landed first.

## Related

- **P155** (`docs/problems/155-ship-capture-problem-skill.open.md`) — driver ticket.
- **P014** (`docs/problems/014-aside-invocation-for-governance-skills.open.md`) — parent / master tracker.
- **P078** — capture-on-correction OFFER pattern; depends on capture-problem shipping.
- **P119** — manage-problem create-gate hook; capture-problem composes with the same marker.
- **ADR-032** (`docs/decisions/032-governance-skill-invocation-patterns.proposed.md`) — foreground-lightweight-capture variant amendment.
- **ADR-038** — progressive-disclosure pattern (SKILL.md + REFERENCE.md split).
- **ADR-044** — decision-delegation contract (framework-mediated mechanical-stage carve-outs).
- **ADR-049** — bin/ on PATH; capture-problem reuses the existing `wr-itil-reconcile-readme` shim.
- **ADR-052** — behavioural-tests-default for skill testing.
- `packages/itil/skills/manage-problem/SKILL.md` — heavyweight intake counterpart.
- `packages/itil/skills/review-problems/SKILL.md` — re-rates the deferred placeholders + refreshes README.md.

$ARGUMENTS
