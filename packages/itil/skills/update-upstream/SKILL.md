---
name: wr-itil:update-upstream
description: Post a lifecycle-update comment to an upstream issue when a local problem ticket transitions. Drafts a transition-specific update (root-cause confirmed / fix released / closed), composes the prose through the external-comms risk gate + voice-tone gate, auto-posts within appetite, queues above-appetite. Reciprocal sibling to /wr-itil:report-upstream — initial-filing vs lifecycle-update split per ADR-024 amendment (P080).
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion, Skill, Agent
---

<!--
  @jtbd JTBD-301 (Report a Problem Without Pre-Classifying It — reporter feedback loop)
  @jtbd JTBD-001 (Enforce Governance Without Slowing Down — no manual policing of upstream issues)
  @jtbd JTBD-201 (Restore Service Fast with an Audit Trail — symmetric local/upstream audit trail)
  @jtbd JTBD-101 (Extend the Suite with Clear Patterns — downstream adopters inherit bidirectional contract)
  @problem P080
  @adr ADR-024 (amended P080 — bidirectional lifecycle updates; Phase 2 — --catchup migration mode + idempotency)
  @adr ADR-049 (catchup worklist scanner invoked via wr-itil-catchup-scan bin shim)
  @adr ADR-028 (voice-tone gate on `gh issue comment` / `gh issue close`)
  @adr ADR-013 (Rule 1 AskUserQuestion; Rule 6 AFK fail-safe)
  @adr ADR-014 (single-commit grain — transition + back-write + upstream comment)
  @adr ADR-010 amended (sibling-skill naming; split execution ownership)
  @adr ADR-044 (decision-delegation contract — framework-resolution boundary)
  @adr ADR-075 (Amendment 2026-06-02 — paired promptfoo eval discharges R009 prose floor)
  @adr ADR-061 Rule 4 (evidence-floor — paired Tier-A/B eval ships in same commit as SKILL)
-->

# Update Upstream — Lifecycle-Update Skill

Post a lifecycle-update comment to an upstream issue (or close it) when the local problem ticket transitions. Reads the local ticket's `## Reported Upstream` section, drafts a transition-specific update from the templates below, composes the draft through the external-comms risk gate (`wr-risk-scorer:external-comms`) and voice-tone gate (`wr-voice-tone:external-comms`), auto-posts via `gh issue comment` (or `gh issue close` on Verifying → Closed) when both gates pass within appetite, and queues an `outstanding_questions` entry when either gate scores above appetite.

This skill is the **reciprocal sibling** to [`/wr-itil:report-upstream`](../report-upstream/SKILL.md) — that skill files the initial upstream report; this skill keeps the upstream record in sync as the local ticket walks its lifecycle. The split is per [ADR-010](../../../docs/decisions/010-rename-wr-problem-to-wr-itil.proposed.md) amended Skill Granularity rule (one skill per distinct user intent) — initial-filing and lifecycle-update are distinct user intents with distinct autocomplete surfaces.

This skill implements the bidirectional extension to ADR-024's outbound contract — see the **ADR-024 amendment (P080)** entry in the ADR's `## Amendments` section. The amendment authorises this sibling skill, defines the transition-template shape, and pins the same external-comms + voice-tone gate composition that the post-P270 amendment uses for the initial-filing path.

## Invocation

```
/wr-itil:update-upstream <NNN>          # single-ticket lifecycle update
/wr-itil:update-upstream --catchup      # batch-retroactive migration (Phase 2)
```

- `<NNN>`: the three-digit local ticket ID (e.g. `080`). The ticket file is discovered via the same dual-tolerant lookup as [`/wr-itil:report-upstream`](../report-upstream/SKILL.md) (flat layout + per-state subdir per RFC-002 migration window).
- `--catchup`: one-shot batch-retroactive migration mode (P080 Phase 2 — see [§ Catchup migration mode](#catchup-migration-mode-phase-2)). Walks the existing `.verifying.md` + `.closed.md` corpus and posts the lifecycle update each ticket should have received but did not (because it was reported upstream / transitioned before the per-ticket auto-update path shipped). Idempotent — already-updated tickets are skipped.

The single-ticket form is typically invoked from `/wr-itil:transition-problem` Step 7's advisory subsection when the transitioning ticket carries a `## Reported Upstream` section (per ADR-024 Confirmation criterion 3a — the back-write that `/wr-itil:report-upstream` Step 7 writes). User-initiated single-ticket invocation is also supported. The `--catchup` form is user-initiated only (a deliberate one-shot migration, never auto-fired from a transition).

## Scope

**In scope:**
- Read the local ticket's `## Reported Upstream` section and extract each upstream URL + matched template + disclosure path recorded there.
- Determine the local ticket's current Status from the filename suffix.
- Draft a transition-specific lifecycle-update comment per the templates below (Open→KE / KE→Verifying / Verifying→Closed).
- Compose the drafted prose through `wr-risk-scorer:external-comms` + `wr-voice-tone:external-comms` gates.
- Within appetite → post via `gh issue comment <n>`; on Verifying→Closed also run `gh issue close <n>`.
- Above appetite → AskUserQuestion (interactive) / queue `outstanding_questions` (AFK, per P352 queue-and-continue).
- Back-write a `## Upstream Lifecycle Updates` log entry to the local ticket recording the transition, the matched URL, the posted comment URL, and the disclosure path.
- **Historical catch-up migration (`--catchup`, P080 Phase 2)** — one-shot retroactive scan of the existing `.verifying.md` + `.closed.md` corpus; posts the lifecycle update each linked-upstream ticket should already carry. Idempotent — re-running is safe. See [§ Catchup migration mode](#catchup-migration-mode-phase-2).

**Out of scope:**
- Initial upstream filing — that's `/wr-itil:report-upstream`.
- Cross-tracker propagation (linking the upstream update back into a different upstream's parallel issue) — out of scope; one local ticket → N upstream URLs is supported, but each URL update is independent.

## Step-0 deferral (ADR-027)

This skill does NOT implement ADR-027's Step-0 auto-delegation pattern. Same rationale as [`/wr-itil:report-upstream`](../report-upstream/SKILL.md) Step-0 deferral: the local ticket and the `## Reported Upstream` extraction must stay in main-agent context for the gate composition and the back-write, so wrapping the flow in a subagent would not reduce main-agent context cost. Trigger to revisit per ADR-024's Reassessment Criteria — if a third skill that reads `## Reported Upstream` lands, factor the read into a Step-0-delegated subagent.

## Voice-tone gate interaction (ADR-028)

The skill's `gh issue comment` and `gh issue close` calls are **on the gated surface list per [ADR-028](../../../docs/decisions/028-voice-tone-gate-external-comms.proposed.md)** (Voice-tone gate on external communications). Expected behaviour during these tool calls:

1. The voice-tone gate fires `PreToolUse:Bash` with a deny-plus-delegate response.
2. The hook delegates to `wr-voice-tone:agent` to review the drafted body for brand-voice + tone alignment against `docs/VOICE-AND-TONE.md`.
3. Once the agent's marker lands, the same `gh issue comment` or `gh issue close` call retries and proceeds.

The skill should treat this transient deny-plus-delegate as the expected path, not as an error.

If `wr-voice-tone:agent` is not installed in the project, the gate is dormant and the skill proceeds without delegation.

## Steps

### 1. Read the local problem ticket

Dual-tolerant lookup spans flat layout AND per-state subdir layout (RFC-002 migration window):

```bash
LOCAL_TICKET=$(ls docs/problems/${LOCAL_ID}-*.{open,known-error,verifying,closed,parked}.md docs/problems/*/${LOCAL_ID}-*.md 2>/dev/null | head -1)
[ -n "$LOCAL_TICKET" ] || { echo "Error: local ticket P${LOCAL_ID} not found in docs/problems/"; exit 1; }
```

Extract:
- Title (from H1).
- Current Status (from filename suffix — `.open.md` / `.known-error.md` / `.verifying.md` / `.closed.md` / `.parked.md`).
- The `## Reported Upstream` section (zero or more upstream entries, each with URL + disclosure path).
- For `.verifying.md` tickets: the `## Fix Released` section (release marker, version, commit SHA, PR number).
- For `.known-error.md` tickets: the `## Fix Strategy` section (planned fix path; cited in KE updates so the reporter knows the direction).

If the ticket has no `## Reported Upstream` section, exit cleanly with a one-line message: `No ## Reported Upstream section in P${LOCAL_ID}; nothing to update.` This is the **no-op exit** — most local tickets never reported upstream, and the skill's invocation from `transition-problem` Step 7 is unconditional; a missing section is the common case, not an error.

### 2. Parse each upstream entry

For each `- **URL**: <url>` line under `## Reported Upstream`, extract:
- The upstream URL.
- The matched template name (`- **Template used**: <name>`).
- The disclosure path (`- **Disclosure path**: <path>`).
- The reported date (`- **Reported**: <YYYY-MM-DD>`).

Skip entries whose disclosure path is `drafted-and-saved (mailbox / out-of-band)` — those reports were never filed via `gh`, so there is no issue to comment on. Log a one-line skip note: `Skipping upstream entry <url> — disclosure path is out-of-band; user follow-up required.` The skip is **not** queued as an `outstanding_questions` entry (the user already owns the out-of-band channel per the ADR-024 no-infra-for-email constraint).

Multiple `## Reported Upstream` entries are supported (the local ticket may have been filed to multiple upstream trackers). Process each entry independently — the gate composition + post + back-write all run per-entry; one above-appetite entry queues only that entry, the rest proceed.

### 3. Determine the transition that fired this invocation

The skill is typically invoked AFTER the local ticket's filename suffix has changed (the `transition-problem` Step 7 advisory subsection fires AFTER the `git mv` + Status edit + re-stage). Compare the current suffix against the most recent `## Upstream Lifecycle Updates` log entry (if any) to identify which transition just fired:

| Last logged Status | Current suffix | Transition fired |
|---|---|---|
| (none) | `.known-error.md` | Open → Known Error |
| (none) | `.verifying.md` | Open → Known Error (skipped) → Verification Pending |
| Open | `.known-error.md` | Open → Known Error |
| Known Error | `.verifying.md` | Known Error → Verification Pending |
| Verification Pending | `.closed.md` | Verification Pending → Closed |
| any | matching last logged | no transition since last update — exit no-op |

If the current suffix matches the last logged Status, exit clean: `No transition since last upstream update; nothing to post.` This guards against re-firing on a manage-problem update that doesn't change Status (Priority/Effort/WSJF edits, root-cause refinement edits).

If the current suffix is `.parked.md`, exit clean: `Local ticket is Parked; no upstream lifecycle update applies.` Parking is a transient hold (per ADR-022) and does not warrant an upstream comment.

### 4. Draft the lifecycle-update comment

Per-transition templates. Each template's `<placeholders>` are filled from the local ticket's sections (per Step 1's extraction).

#### Open → Known Error template

```markdown
Update from <downstream-repo-url>/<local-ticket-relative-path>:

**Status**: Root cause identified (local ticket transitioned to Known Error).

**Investigation findings**:

<one-paragraph synthesis from the local ticket's Root Cause Analysis section — substantive, not just "we found it">

**Planned fix path**:

<from the local ticket's Fix Strategy section, or "Fix path under design" if absent>

**Workaround**:

<from the local ticket's Workaround section, or "None identified yet" if absent>

We'll post here again when the fix releases. Local tracking: P<NNN>.
```

#### Known Error → Verification Pending template

```markdown
Update from <downstream-repo-url>/<local-ticket-relative-path>:

**Status**: Fix released (local ticket transitioned to Verification Pending).

**Release**:

- **Package**: `<package>@<version>` (or "see release notes" if not derivable)
- **Merge PR**: #<N> (or commit SHA if direct-to-main)
- **Released**: <YYYY-MM-DD>

**Fix summary**:

<one-sentence summary from the local ticket's ## Fix Released section>

Please upgrade and verify when convenient. We'll close this issue after your confirmation OR after a 14-day quiet period (per P048 default). Local tracking: P<NNN>.
```

#### Verification Pending → Closed template

```markdown
Update from <downstream-repo-url>/<local-ticket-relative-path>:

**Status**: Closed locally after user-side verification.

Closing this issue to match. Thanks for the report — your filing is what got this on the queue. Local tracking: P<NNN>.
```

After posting the Verifying → Closed comment, the skill also runs `gh issue close <n>` (per Step 5b below) so the upstream tracker matches local state.

#### Template-filling rules

- **No invention**: if a section the template cites is absent from the local ticket, write the explicit "absent" phrasing ("Fix path under design", "None identified yet") rather than synthesising content. The risk gate and voice-tone gate cannot guard against invented technical claims; the no-invention rule does.
- **Source-citation**: every template starts with `Update from <downstream-repo-url>/<local-ticket-relative-path>:` so the upstream maintainer can navigate back to the source ticket without ambiguity. The cross-reference URL uses the same shape as `/wr-itil:report-upstream` Step 5's `## Cross-reference` section.
- **No "we" assumptions about the upstream maintainer**: the lifecycle templates are written from the downstream-reporter perspective. Use "we" only when referring to the downstream team; do not use it to suggest joint authorship of the upstream fix unless the local ticket's Fix Strategy explicitly records an upstream-collaborative path.

### 5. Compose through external-comms + voice-tone gates

#### 5a. External-comms risk gate

Score the drafted comment body via the `wr-risk-scorer:external-comms` agent (shipped per [ADR-028](../../../docs/decisions/028-voice-tone-gate-external-comms.proposed.md) — the same agent the post-P270 amendment uses for the initial-filing path's pre-fire gate). Invocation: delegate via the Agent tool with `subagent_type: "wr-risk-scorer:external-comms"` passing the drafted body + the upstream URL + the transition type as context.

The agent returns a structured verdict:

```
EXTERNAL_COMMS_RISK_VERDICT
band: Low (<=4/25) | Medium (5..16) | High (17+)
score: <0..25>
pass: true | false
reason: <one-line rationale>
```

- **`pass: true` AND band ≤ Low (4/25)**: within appetite per RISK-POLICY.md commit-layer. Proceed to 5b (voice-tone).
- **`pass: false` OR band > Low**: above appetite. Branch to 5c (above-appetite handling).

#### 5b. Voice-tone gate

`gh issue comment` and `gh issue close` are on the ADR-028 gated surface list. The PreToolUse:Bash hook fires deny-plus-delegate to `wr-voice-tone:agent`. The agent reads the drafted body against `docs/VOICE-AND-TONE.md` and writes the bypass marker on PASS; the original `gh` call retries automatically.

A FAIL verdict on the voice-tone gate is treated identically to an above-appetite risk verdict — branch to 5c.

#### 5c. Above-appetite handling

The decision policy here is **framework-resolved** per [ADR-044](../../../docs/decisions/044-decision-delegation-contract.proposed.md) (decision-delegation contract) and ADR-013 Rule 6 (AFK fail-safe). No per-transition `AskUserQuestion` for the GATE FIRING — the gate scoring is itself the framework. The above-appetite handling differs by orchestrator context:

- **Interactive context** (per ADR-013 Rule 1): use `AskUserQuestion` to surface the drafted comment + the gate verdict + the matched URL, with options:
  - `Post the comment anyway (Recommended after review)` — user has read the draft and judged the post warranted; the skill bypasses the gate for this single post.
  - `Risk-reduce and re-score` — invoke a tighter draft (shorter / fewer claims / stricter source-citation) and re-run the gate.
  - `Queue for later review` — save the draft to `## Queued Upstream Update` on the local ticket; user acts on return.
  - `Skip this update` — exit no-op for this upstream entry; the next transition's invocation re-considers.

- **AFK / non-interactive context** (per ADR-013 Rule 6 + P352 queue-and-continue): the skill applies **silent risk-reduce + re-score** first — re-draft the comment with tighter source-citation + shorter prose, then re-invoke the external-comms gate. If the re-scored verdict is within appetite, proceed via 5b. Otherwise, save the drafted comment to the local ticket's `## Queued Upstream Update` section (shape below) and queue an `outstanding_questions` entry (category: `deviation-approval`) naming the local ticket ID + the matched URL + the residual band + the risk-reduce attempts taken. **The orchestrator continues per P352** — do NOT halt the loop on an above-appetite upstream update.

The silent risk-reduce step is **mechanical** per ADR-044 framework-resolution boundary — the skill owns the re-draft; per-iter `AskUserQuestion` for risk-reduce vocabulary is the lazy-deferral anti-pattern P132 closes.

#### Queued Upstream Update save format

```markdown
## Queued Upstream Update

- **Drafted**: <YYYY-MM-DD>
- **Transition**: Open → Known Error | Known Error → Verification Pending | Verification Pending → Closed
- **Target URL**: <upstream-issue-url>
- **Halt reason**: above-appetite external-comms gate (band: <verdict band>; score: <verdict score>; reason: <verdict reason>) | above-appetite voice-tone gate (reason: <verdict reason>)
- **Risk-reduce attempts**: <count, e.g. "1 — tighter source-citation; re-scored band Medium">
- **Drafted comment body**:

  <the body that would have been posted as a `gh issue comment`, ready for manual review>
```

Per [ADR-024](../../../docs/decisions/024-cross-project-problem-reporting-contract.proposed.md) amendment (P080), the section name `## Queued Upstream Update` is the lifecycle-update analogue of `## Queued Upstream Report` (the initial-filing analogue per the 2026-06-04 second-amendment leaf (c) rename). Same shape; distinct section so a single local ticket can carry both a queued report (initial filing held) and a queued update (lifecycle update held) without collision.

### 5b. (final). Post via gh issue comment

Within-appetite path. Post the drafted comment:

```bash
gh issue comment "${UPSTREAM_ISSUE_NUMBER}" \
  --repo "${UPSTREAM_OWNER_REPO}" \
  --body "${DRAFTED_COMMENT_BODY}"
```

Capture the returned comment URL (gh prints `https://github.com/<owner>/<repo>/issues/<n>#issuecomment-<id>`).

On the **Verifying → Closed** transition, after posting the comment, also close the upstream issue:

```bash
gh issue close "${UPSTREAM_ISSUE_NUMBER}" \
  --repo "${UPSTREAM_OWNER_REPO}" \
  --comment "" \
  --reason completed
```

`--comment ""` suppresses gh's own auto-comment (we already posted the closing comment above); `--reason completed` matches the `.closed.md` semantics.

If the issue is already closed upstream (someone else closed it manually), `gh issue close` returns a benign error — capture the existing state and continue to Step 6 with `closed-already-upstream` recorded in the back-write disclosure path.

### 6. Back-write to local ticket

Append a log entry to the local ticket's `## Upstream Lifecycle Updates` section (create the section if absent — never inserted mid-document; appended after all existing sections per the same discipline as `## Reported Upstream` in `/wr-itil:report-upstream` Step 7):

```markdown
## Upstream Lifecycle Updates

- **<YYYY-MM-DD>** — Open → Known Error
  - **Target URL**: <upstream-issue-url>
  - **Comment URL**: <posted-comment-url> (or "queued — see ## Queued Upstream Update" when above-appetite)
  - **Disclosure path**: posted-comment | posted-comment-and-closed (Verifying → Closed) | queued-above-appetite | closed-already-upstream | skipped-out-of-band
  - **Gate verdict**: external-comms <band/score> + voice-tone <pass|fail>

- **<YYYY-MM-DD>** — Known Error → Verification Pending
  - ... (next entry appends; never replaces earlier entries)
```

The log is append-only — each transition adds an entry; earlier entries are never overwritten. The log is the audit trail per JTBD-201's symmetric-audit-trail outcome and per ADR-024 Confirmation criterion 3a's `## Reported Upstream` back-write pattern (extended for the bidirectional case).

### 7. Commit per ADR-014

When invoked from `transition-problem` Step 7's advisory subsection, the upstream comment + back-write + the ticket rename + the README refresh all join the **same single commit** per ADR-014's single-commit grain — never split across commits. The transition-problem skill owns the commit; this skill's edits ride that commit as additional staged changes.

When invoked user-initiatedly (no transition in this session, e.g. retroactive catch-up), the skill commits its own work:

1. `git add docs/problems/<state>/<NNN>-<title>.md` (the back-write + any `## Queued Upstream Update` appendage).
2. Score commit/push/release risk via `wr-risk-scorer:pipeline` subagent (or fall back to `/wr-risk-scorer:assess-release` skill per ADR-015).
3. `git commit -m "docs(problems): P<NNN> upstream lifecycle update — <transition>"`.

If the cumulative pipeline risk lands above appetite and `AskUserQuestion` is unavailable, apply the [ADR-013 Rule 6](../../../docs/decisions/013-structured-user-interaction-for-governance-decisions.proposed.md) non-interactive fail-safe: skip the commit and report the uncommitted state. Do NOT auto-commit above appetite without the user's call.

## Catchup migration mode (Phase 2)

`/wr-itil:update-upstream --catchup` runs a one-shot batch-retroactive migration. It exists because the per-ticket auto-update path (Phase 1) only fires on transitions that happen *after* it shipped — every ticket reported upstream and transitioned *before* Phase 1 silently missed its lifecycle update, leaving upstream issues looking abandoned. Catchup back-fills that history. Authority: [ADR-024](../../../docs/decisions/024-cross-project-problem-reporting-contract.proposed.md) amendment (P080 Phase 2).

This mode is **user-initiated only** — it is never auto-fired from a transition. It is a deliberate corpus-wide migration the maintainer runs once (or re-runs safely, thanks to idempotency).

### C1. Build the worklist (read-only scan)

Invoke the worklist scanner via its [ADR-049](../../../docs/decisions/049-plugin-script-resolution-via-bin-on-path.proposed.md) `$PATH` shim — **never** via a repo-relative `packages/...` path (that path does not resolve in adopter trees):

```bash
wr-itil-catchup-scan
```

The scanner (`packages/itil/scripts/catchup-scan.sh`, dispatched by the `wr-itil-catchup-scan` bin shim) is **read-only and local** — it makes no `gh` calls and writes nothing. It walks the `.verifying.md` + `.closed.md` corpus (dual-tolerant flat + per-state subdir per RFC-002), filters to tickets carrying a `## Reported Upstream` section, applies marker-based idempotency, and prints a worklist:

```
CATCHUP P<NNN> <url> state=<verifying|closed> transition=<KE->Verifying|Verifying->Closed>
SKIP    P<NNN> <url> reason=already-logged
SKIP    P<NNN> <url> reason=out-of-band
```

plus a `SUMMARY scanned=… catchup=… skip-logged=… skip-out-of-band=…` line on stderr. Tickets with no `## Reported Upstream` section produce no line (the common case). Open / Known-Error / Parked tickets are out of the catchup corpus — only post-fix states (Verifying, Closed) carry the lifecycle updates a reporter most wants retroactively.

### C2. Idempotency contract

Catchup is **idempotent** (P080 Phase 2 acceptance criterion 3). The scanner skips a ticket whose `## Upstream Lifecycle Updates` log already records an entry for the current target state:

- `.verifying.md` → already-logged iff the log contains a `→ Verification Pending` entry.
- `.closed.md` → already-logged iff the log contains a `→ Closed` entry.

The append-only log (written by Step 6 on every post) is the source of truth — the same marker the per-ticket path writes. Re-running `--catchup` therefore never double-posts. As defence-in-depth, before posting each `CATCHUP` entry the SKILL MAY also scan the upstream issue for a prior `Update from …` comment authored by the posting account (`gh issue view <n> --json comments`); if one already matches the target transition, treat it as already-logged, back-write the log entry to reconcile, and skip the post. The body-marker check is primary (cheap, no `gh` round-trip); the comment scan is the belt-and-braces fallback for tickets whose log predates Phase 1's back-write.

### C3. Process each CATCHUP entry

For each `CATCHUP` line, run the **existing per-ticket flow** (Steps 4–6) against that ticket ID:

1. Draft the transition template (Step 4) for the entry's transition (`KE->Verifying` → Known Error → Verification Pending template; `Verifying->Closed` → Verification Pending → Closed template, which also runs `gh issue close`).
2. Compose through the external-comms + voice-tone gates (Step 5) — **identical** dual-gate composition as the per-ticket path. Above-appetite handling (Step 5c) is unchanged: silent risk-reduce + re-score, then queue to `## Queued Upstream Update` + `outstanding_questions` (category `deviation-approval`) per P352 if still above. Catchup does NOT bypass the gates.
3. Post within appetite (Step 5b final) and back-write the `## Upstream Lifecycle Updates` log (Step 6).

Process entries one at a time so a single above-appetite entry queues only itself; the rest proceed. There is no batch-cap on the number of catchup posts — the gate composition is the rate-limit, and the corpus is bounded (one pass over local tickets).

### C4. Commit per ADR-014

The catchup migration is user-initiated, so it owns its commit per the Step 7 user-initiated path: stage every touched ticket's back-write (and any `## Queued Upstream Update` appendage), score commit/push/release risk via `wr-risk-scorer:pipeline`, and commit once covering the whole pass — `docs(problems): upstream lifecycle catchup migration — <N> tickets (P080 Phase 2)`. Above-appetite-and-no-AskUserQuestion → ADR-013 Rule 6 fail-safe (report the uncommitted state, do not auto-commit).

### C5. Verification

The live-upstream end-to-end confirmation (P080 acceptance criterion 7 — a catchup comment actually lands on a real upstream issue) is the overall P080 verification step. Running `--catchup` against the real corpus (e.g. P113's `https://github.com/anthropics/claude-code/issues/52831`) and confirming the comment posts is what closes P080 to Verifying once a fresh release ships the mode.

## AFK behaviour summary

Four distinct AFK branches. Per the [ADR-024](../../../docs/decisions/024-cross-project-problem-reporting-contract.proposed.md) amendment (P080) — same composition shape as the post-P270 initial-filing path — ALL pre-post branches route through the `wr-risk-scorer:external-comms` + `wr-voice-tone:external-comms` gates. Below-appetite proceeds; above-appetite silent risk-reduces + re-scores; if still above, queues per P352 queue-and-continue without halting the loop.

| Branch | AFK behaviour | Authority |
|---|---|---|
| Below-appetite post (Step 5b final) | Post via `gh issue comment`; on Verifying→Closed also `gh issue close`. Back-write to `## Upstream Lifecycle Updates`. Voice-tone gate per ADR-028 may delegate-and-retry on the post; treat as expected. | ADR-024 amendment (P080); ADR-028 |
| Above-appetite — silent risk-reduce + re-score within appetite | Re-draft with tighter source-citation + shorter prose; re-invoke `wr-risk-scorer:external-comms`. If within → post per the below-appetite branch. | ADR-024 amendment (P080); ADR-044 framework-resolution boundary; ADR-042 within-axis precedent (open-vocabulary risk-reducing measures) |
| Above-appetite — silent risk-reduce did not bring within appetite | Save drafted comment to `## Queued Upstream Update` + queue `outstanding_questions` entry (category: `deviation-approval`). Orchestrator continues per P352. | ADR-024 amendment (P080); ADR-013 Rule 6; P352 |
| Above-appetite commit (Step 7) | Skip the commit, report uncommitted state. | ADR-013 Rule 6 |

The pre-amendment "halt-the-orchestrator on above-appetite" semantics are **superseded** by queue-and-continue per P352 — same shape as the post-P270 initial-filing path.

## Triggered from transition-problem Step 7

[`/wr-itil:transition-problem`](../transition-problem/SKILL.md) Step 7 hosts an advisory subsection that fires this skill when the transitioning ticket carries a `## Reported Upstream` section. The advisory wires the trigger; this skill owns the execution. The same "copy, not move" pattern (per [ADR-010](../../../docs/decisions/010-rename-wr-problem-to-wr-itil.proposed.md) amended Split-skill execution ownership rule, P093) replicates the advisory in `/wr-itil:manage-problem`'s in-skill Step 7 block so in-skill callers (Step 9b auto-transition, Step 9d closure, the Parked path) also fire the lifecycle update.

Both call sites delegate via the Skill tool:

```
/wr-itil:update-upstream <NNN>
```

The skill's no-op exit (Step 1) means firing the trigger unconditionally on every transition is cheap — most tickets have no `## Reported Upstream` section and exit immediately.

## References

- [ADR-024](../../../docs/decisions/024-cross-project-problem-reporting-contract.proposed.md) — primary contract this skill extends. The P080 amendment in `## Amendments` authorises the bidirectional lifecycle-update sibling skill, the transition-template shape, and the external-comms + voice-tone gate composition; the **P080 Phase 2 amendment** authorises the `--catchup` migration mode, the read-only worklist scanner, and the marker-based idempotency contract.
- [ADR-049](../../../docs/decisions/049-plugin-script-resolution-via-bin-on-path.proposed.md) — the catchup worklist scanner is invoked as `wr-itil-catchup-scan` ($PATH shim), never via a repo-relative `packages/...` path.
- [`packages/itil/scripts/catchup-scan.sh`](../../scripts/catchup-scan.sh) — read-only local worklist scanner for `--catchup`; behavioural bats at `packages/itil/scripts/test/catchup-scan.bats`.
- [ADR-028](../../../docs/decisions/028-voice-tone-gate-external-comms.proposed.md) — voice-tone gate on `gh issue comment` and `gh issue close`.
- [ADR-013](../../../docs/decisions/013-structured-user-interaction-for-governance-decisions.proposed.md) — interaction policy; Rule 1 governs the interactive above-appetite path; Rule 6 governs the AFK fail-safe.
- [ADR-014](../../../docs/decisions/014-governance-skills-commit-their-own-work.proposed.md) — single-commit grain for transition + back-write + upstream post.
- [ADR-010](../../../docs/decisions/010-rename-wr-problem-to-wr-itil.proposed.md) amended — sibling-skill naming + split execution ownership (P093 "copy, not move").
- [ADR-044](../../../docs/decisions/044-decision-delegation-contract.proposed.md) — framework-resolution boundary; the gate verdict IS the framework, no per-transition AskUserQuestion for the gate firing itself.
- [ADR-042](../../../docs/decisions/042-auto-apply-scorer-remediations-open-vocabulary.proposed.md) — within-axis precedent for open-vocabulary risk-reducing measures.
- [ADR-075](../../../docs/decisions/075-promptfoo-agent-prose-verdict-eval-harness.proposed.md) Amendment 2026-06-02 — paired promptfoo Tier-A/B eval discharges the R009 prose-floor for SKILL surfaces.
- [ADR-061](../../../docs/decisions/061-dogfood-graduation-criteria.proposed.md) Rule 4 — evidence-floor; the paired eval ships in the same commit as this SKILL prose for atomic R009 discharge.
- **P080** — driving problem ticket (No bidirectional update of upstream-reported problems).
- **P079** — sibling problem (inbound-discovery leg); together P079 + P080 close the reporter-loop end-to-end.
- **P078** — capture-on-correction; the manage-problem trap this skill closes (manual upstream-update step gets forgotten under load).
- [`packages/itil/skills/report-upstream/SKILL.md`](../report-upstream/SKILL.md) — reciprocal sibling (initial-filing path); shares the `## Reported Upstream` contract this skill consumes.
- [`packages/itil/skills/transition-problem/SKILL.md`](../transition-problem/SKILL.md) — Step 7 advisory subsection fires this skill.
- [`packages/itil/skills/manage-problem/SKILL.md`](../manage-problem/SKILL.md) — in-skill Step 7 copy fires this skill (per ADR-010 amended "copy, not move").

$ARGUMENTS
