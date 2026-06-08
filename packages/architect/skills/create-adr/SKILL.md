---
name: wr-architect:create-adr
description: Create a new Architecture Decision Record (MADR 4.0) in docs/decisions/. Examines existing decisions, asks about the problem and options, and writes a properly formatted ADR.
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion
---

# Architecture Decision Record Generator

Create a new ADR in `docs/decisions/` following MADR 4.0 format. The wr-architect:agent reviews these files to enforce architectural compliance.

## Needs-Direction handoff + confirm-every-ADR (ADR-064)

When a `wr-architect:agent` review returns a **NEEDS DIRECTION** verdict (a new decision with 2+ viable options and no pinned direction, per ADR-064), the option choice is the user's, not the agent's — this skill is the translation surface. The architect's named question + options become the Step 2 cat-1 `AskUserQuestion` calls (Considered Options / Decision Outcome), and the Step 5 confirm is the load-bearing **review-and-confirm-every-ADR** gate: an ADR must not stand as a human-oversighted decision (reach `accepted`) without that confirm pass. A `/wr-architect:capture-adr` skeleton — zero-ask precisely because its decision was pre-pinned in `$ARGUMENTS` — must be run through this skill's confirm before promotion to `accepted`. When direction IS already pinned (same-turn / same-session / accepted ADR / RISK-POLICY.md / CLAUDE.md mandatory rule), act on it — do not re-ask (P132 inverse-P078 guard).

## Steps

### 1. Discover existing decisions

Scan for existing ADRs:
- Glob `docs/decisions/*.md` (skip `README.md`)
- Note the highest numbered decision to determine the next sequence number
- Read any decisions related to the topic being discussed (if the user has mentioned a topic)
- If `docs/decisions/` does not exist, create it

### 2. Gather context (P132 derive-first; ADR-044 category-4 silent-framework on derivable fields; category-1 direction-setting only on user-judgment fields)

**Shared dispatch helper**: this surface invokes `packages/architect/lib/derive-first-dispatch.sh` for the canonical slug derivation (Title) and I2-isomorphic stderr advisory format. The canonical source-of-truth lives at `packages/shared/derive-first-dispatch.sh`; the architect package carries a synced per-package copy at `packages/architect/lib/derive-first-dispatch.sh` per ADR-017 (Shared code duplicated into per-package lib/ kept in sync). The same helper is sourced by `/wr-itil:capture-problem` Step 1.5, `/wr-itil:manage-incident` Step 4, and `/wr-itil:manage-problem` Step 4 (each from its own per-package `packages/itil/lib/` copy); drift in the advisory shape across the four surfaces re-opens P132.

**Derive-first dispatch.** ADR creation is fundamentally user-judgment-bound — only the user knows the decision space, the alternatives considered, and the chosen-option rationale. But the **declaration-skeleton fields** (Title, status, date, reassessment-date, context-and-problem-statement) carry observable evidence in the user's prose, the working tree, and the wall-clock — the framework can resolve them without firing `AskUserQuestion`. The retained `AskUserQuestion` surfaces (Decision Drivers, Considered Options, Decision Outcome, Consequences, Confirmation, decision-makers) are the genuine **category-1 direction-setting** fields.

The P132 inverse-P078 trap (`docs/problems/known-error/132-...md`) is the load-bearing motivation. create-adr Step 2 is the **fourth declaration-skill surface** under Phase 2a to ship the derive-first dispatch (after `/wr-itil:capture-problem` Step 1.5, `/wr-itil:manage-incident` Step 4, and `/wr-itil:manage-problem` Step 4). The pattern is I2-isomorphic across all four — the stderr advisory shape `<skill>: derived <field>=<value> from <source>; <reversibility>` is identical beyond substituted values per the helper's `emit_stderr_advisory` function (architect verdict 2026-05-16 P132 Phase 2a-iii-B: pattern lock-in across the 4-surface set).

Resolve each field via the following dispatch. **The order is load-bearing** — every derivable field resolves silently with a stderr advisory citing the source; only user-judgment fields fire `AskUserQuestion`.

| Field | Dispatch | ADR-044 category |
|-------|----------|------------------|
| **Title** | Derive silently. Kebab-case the first 8-10 non-stopword tokens of the user's prose problem-statement (same slug derivation as `/wr-itil:capture-problem` Step 1.4, `/wr-itil:manage-incident` Step 4, and `/wr-itil:manage-problem` Step 4 — uses the shared helper's `derive_kebab_slug` function). At intake the derived slug typically encodes the **question** (the problem-statement is question-shaped); the title-as-outcome convention in Step 2a below names the GOOD/BAD shapes, and Step 5a's mechanical retitle-after-decision check renames the file to the chosen-option's outcome shape after substance-confirm passes. Emit stderr advisory: `create-adr: derived title='<slug>' from problem-statement; re-invoke with the desired title or rename the file if the slug is wrong`. Do NOT fire AskUserQuestion. | category-4 silent-framework |
| **status** (frontmatter) | Always `proposed` for new ADRs per Step 4 template convention. No ask, no advisory needed — SKILL convention is unambiguous. | category-4 silent-framework |
| **date** (frontmatter) | Today's date (`date +%Y-%m-%d`) per Step 4 template. No ask, no advisory needed — wall-clock derivation is unambiguous. | category-4 silent-framework |
| **reassessment-date** (frontmatter) | Today + 3 months (`date -v+3m +%Y-%m-%d` on BSD-date / `date -d '+3 months' +%Y-%m-%d` on GNU-date) per Step 4 template. Emit stderr advisory: `create-adr: derived reassessment-date='<YYYY-MM-DD>' from today+3-months default; re-invoke with --reassessment-date= or edit the frontmatter to override`. | category-4 silent-framework |
| **Context and Problem Statement** | Pull verbatim from `$ARGUMENTS` prose into the Step 4 template's `## Context and Problem Statement` section. **Fallback**: when `$ARGUMENTS` carries NO problem prose (only flags or empty body), fire AskUserQuestion as the genuine category-1 direction-setting surface — *"only the user knows the problem being solved."* Question text: *"What problem does this ADR solve? Why is a decision needed now?"* This is the prose-fallback path; the typical maintainer invocation carries the problem-statement in arguments. | category-1 direction-setting (fallback only; category-4 silent-framework on the typical path where prose is present) |
| **decision-makers** | Retain AskUserQuestion. Architect verdict 2026-05-16: silent derivation from `git config user.name` would conflate "who committed the ADR" with "who made the decision" — a multi-party decision is one of the canonical mis-attribution risks ADR-013's identity model rejects. Once-per-ADR ask is low-friction in absolute terms. Question text: *"Who are the decision-makers?"* | category-1 direction-setting |
| **Decision Drivers** | Retain AskUserQuestion. Only the user knows which factors weighted the decision. This is the create-adr-equivalent of manage-problem Step 4's Description (the user-judgment surface). | category-1 direction-setting |
| **Considered Options** | Retain AskUserQuestion. Only the user knows the alternatives evaluated. ADR-044 cat-5 (taste) would only apply if the framework could offer 2+ valid options — but the alternative space is genuinely user-knowledge (the framework can offer "do nothing" + a status-quo option but the actual alternatives are the user's). Architect verdict 2026-05-16: confirmed cat-1 over cat-5. Per MADR 4.0: ≥2 alternatives including "do nothing" where applicable. | category-1 direction-setting |
| **Decision Outcome** / **Rationale** | Retain AskUserQuestion. The chosen option + primary reason for the choice. | category-1 direction-setting |
| **Consequences** (Good / Neutral / Bad) | Retain AskUserQuestion. Only the user knows the expected consequences of the decision. | category-1 direction-setting |
| **Confirmation** | Retain AskUserQuestion. Testable verification criteria. | category-1 direction-setting |
| **consulted** / **informed** (frontmatter) | Default to empty list per Step 4 template; fold into the decision-makers AskUserQuestion call if the user surfaces stakeholders. | category-4 silent-framework (default empty); category-1 (when user cites stakeholders) |

**Inferred fields (no ask, no advisory needed)**:

- **supersedes** (frontmatter): empty list by default; populated only via Step 6 supersession handling when the user explicitly cites a superseded decision.

**Stderr advisory contract**: each derived field emits a SINGLE line to stderr (NOT stdout, NOT in the ADR body) via the shared helper's `emit_stderr_advisory` function in `packages/architect/lib/derive-first-dispatch.sh`. The canonical format produced by the helper:

```
create-adr: derived <field>=<value> from <source>; <reversibility-clause>
```

The advisory text shape is I2-isomorphic — same sentence structure across all four derive-first declaration-skill surfaces (`capture-problem`, `manage-incident`, `manage-problem`, `create-adr`) beyond substituted values + source names. The helper is the single source-of-truth for this format; drift here re-opens P132. Embedding the advisory in stdout would risk machine-readers parsing it as an ADR-body line; embedding it in the ADR body would violate the MADR 4.0 schema. Stderr is the correct channel — visible to interactive maintainers in the terminal; invisible to ADR consumers; loggable by orchestrators that capture subprocess stderr.

**ADR-026 cost-source grounding**: each derived field cites its source in the advisory (problem-statement token sequence for Title; today's date for date / reassessment-date; default convention for status). The `re-invoke or update if mis-rated` clause carries the reversibility marker ADR-026 mandates for ungrounded outputs.

**AFK fail-safe (ADR-013 Rule 6)**: under AFK orchestration, derivable fields (Title / status / date / reassessment-date / Context-when-prose-present) resolve without interactive input. The 6 retained cat-1 AskUserQuestion surfaces (decision-makers / Decision Drivers / Considered Options / Decision Outcome / Consequences / Confirmation) WILL halt AFK execution — that is **correct behaviour** because ADR creation is genuinely user-judgment-bound (the user authors the decision; the framework cannot). JTBD-006 protection: AFK orchestrators that need ADR creation should call `/wr-architect:capture-adr` (the lightweight aside surface) for the skeleton + Title derivation, then defer the cat-1 field collection to the user's next interactive session via the capture-adr deferred-flagged-sections mechanism.

**Cross-skill consistency note**: this is the **fourth declaration-skill surface** to ship the derive-first dispatch (after `/wr-itil:capture-problem` Step 1.5, `/wr-itil:manage-incident` Step 4, and `/wr-itil:manage-problem` Step 4 in commits b7cc645 / 43255d2 / 30fd22b). Phase 2a-iii-B (2026-05-16) closes Phase 2a's full 4-surface scope — the I2-isomorphic stderr advisory format is now locked-in across `capture-problem`, `manage-incident`, `manage-problem`, AND `create-adr` via the shared helper at `packages/shared/derive-first-dispatch.sh` with synced per-package lib/ copies. Per ADR-017, drift between copies is caught by `npm run check:derive-first-dispatch` in CI.

If the user has already provided context in `$ARGUMENTS` or earlier conversation, use what they've given and only fire AskUserQuestion for the cat-1 fields still missing.

### 2a. Title-as-outcome convention (P354)

ADR titles must name the **decision outcome** as a short noun phrase, not the question / option-pair being decided. The title is the skim-surface — a reader scanning `docs/decisions/` or the ADR-077 compendium should resolve what was decided from the title alone, without opening the file. User direction 2026-06-03 (P354): *"ADR titles are supposed to be the short version of what was decided, so they are skimmable. Titles like this force the reader to read the document to find the details of what was decided."*

**GOOD** (outcome — short noun phrase naming the decided thing; drawn from corpus):

- `marketplace-only-distribution`
- `monorepo-per-plugin-packages`
- `progressive-disclosure-for-governance-tooling-context`
- `behavioural-tests-default-for-skill-testing`
- `plugin-script-resolution-via-bin-on-path`
- `every-fix-goes-through-an-rfc`

**BAD** (question / option-pair / deliberation — reader must open file to learn outcome):

- `npm-release-auth-stored-token-vs-oidc` (option-pair pattern `-vs-`)
- `should-we-adopt-oidc-for-npm-release-auth` (deliberation pattern `should-`)
- `whether-to-monorepo-or-polyrepo` (open-question pattern `whether-`)
- `marketplace-or-direct-distribution` (pure option-set pattern `-or-`)

**At intake the derived title is acceptable in either shape**: Step 2's `derive_kebab_slug` runs against the problem-statement, which is typically question-shaped. The title-as-outcome convention is enforced at Step 5a's mechanical retitle-after-decision check (post substance-confirm, when the chosen option is locked in). The title need not be outcome-shaped before the decision is made.

(Serves JTBD-001 — skimmable titles speed the read path for the governance-enforcement persona.)

### 2b. Decision-boundary analysis (multi-decision check)

Before writing the ADR file, perform a decision-boundary analysis on the gathered context to prevent conflated ADRs that block independent status transitions and weaken auditability (P017).

**Self-check**: Read the context gathered in step 2. Answer: "How many distinct decisions are present? If each could be independently accepted, rejected, or superseded without affecting the others, they are distinct."

- **Single decision** (one coherent question with one chosen option): proceed directly to step 3.
- **Multiple decisions** (two or more distinct questions, different components, or different decision drivers that do not share the same trade-off): present a split prompt.

**Split prompt** — use `AskUserQuestion`:
- `header: "Multi-decision input"`
- `multiSelect: false`
- Options:
  1. `Split into separate ADRs (Recommended)` — description: "Create one ADR per distinct decision, with consecutive IDs. Each ADR can be accepted, rejected, or superseded independently."
  2. `Keep as a single ADR` — description: "Create one ADR covering all decisions. Use this only if the decisions are so tightly coupled that they cannot be made independently."

**Non-interactive fallback**: When `AskUserQuestion` is unavailable (e.g., non-interactive/AFK mode), automatically split into separate ADRs with consecutive IDs and note the auto-split in output. Do not block creation.

**ADR-013 Rule 6 carve-out audit (P352, 2026-06-06 amendment)**: the universal AFK default is **queue-and-continue**; this site is a documented **AUTO-DEFAULT** carve-out. Authorising principle: policy-authorised safe default per ADR-044 category 4 (silent framework). Splitting is fully reversible (manual combine via supersession), the framework's WSJF / lifecycle model rewards explicit per-decision ranking, and "split when in doubt" is the persona-correct safe heuristic for JTBD-006 (the loop progresses; over-splits are cheap to combine; halt would cost more loop throughput than the over-split risk). Note: the Step 5 substance-confirm HALT below is a separate carve-out authorised by ADR-074 — substance-confirm cannot AUTO-DEFAULT because the dependent work (Decision Outcome / Consequences / Confirmation / Pros and Cons drafting) is built ON the chosen option.

**Split implementation**: When splitting, assign consecutive IDs. Cross-reference each ADR in the other's Related section or as a linked decision in the consequences.

**Scope**: Scoped to new ADR creation only (steps 2–5). Does not apply to supersession handling (step 6), where the scope of the new decision is already known and bounded.

### 3. Determine sequence number and filename

- Next number = **max of the local and origin highest decision numbers**, plus 1 (or 001 if none exist).
- Filename: `NNN-decision-title-in-kebab-case.proposed.md`
- Pad the number to 3 digits (001, 002, ... 010, 011, etc.)

**Why compare against origin?** Per ADR-019 confirmation criterion 2, ticket-creator skills MUST re-check next-number assignment against `git ls-tree origin/<base>` before assigning. Without it, parallel sessions can mint the same ADR number for different decisions, causing a destructive surgical rebase on push (this was the failure mode that motivated ADR-019 itself).

```bash
# Local-max number
local_max=$(ls docs/decisions/*.md 2>/dev/null | sed 's/.*\///' | grep -oE '^[0-9]+' | sort -n | tail -1)

# Origin-max number — reads remote-tracking ref; no fetch needed here
# because `wr-architect:agent` upstream callers (e.g. work-problems) run
# the Step 0 preflight that does the fetch.
#
# `--name-only` is required (P056): without it, each ls-tree line is
# `<mode> <type> <sha>\t<path>` and the 40-char blob SHA can contain
# three-digit runs that `grep -oE '[0-9]{3}'` false-matches. `sed` strips
# the path prefix so the anchored `grep -oE '^[0-9]+'` only picks up
# filename IDs.
origin_max=$(git ls-tree --name-only origin/main docs/decisions/ 2>/dev/null | sed 's|^docs/decisions/||' | grep -oE '^[0-9]+' | sort -n | tail -1)

# Take the max of the two and increment.
next=$(printf '%03d' $(( 10#$(echo -e "${local_max:-0}\n${origin_max:-0}" | sort -n | tail -1) + 1 )))
```

If the local choice would have collided with an origin ADR created since the last fetch, the `git ls-tree origin/<base>` lookup catches it here and the renumber is automatic. Log the renumber in the user-facing report (e.g. "Bumped next ADR number from 020 → 021 to avoid collision with origin").

### 4. Write the ADR

Write the file to `docs/decisions/` with this structure:

```markdown
---
status: "proposed"
date: YYYY-MM-DD
decision-makers: [from user input]
consulted: [from user input, or empty list]
informed: [from user input, or empty list]
reassessment-date: YYYY-MM-DD  # 3 months from today
---

# Title

## Context and Problem Statement

[What problem does this solve? Why is a decision needed now?]

## Decision Drivers

- [Key factors influencing the decision]

## Considered Options

1. **Option A** - Brief description
2. **Option B** - Brief description

## Decision Outcome

Chosen option: **"Option X"**, because [primary justification].

## Consequences

### Good

- [Positive outcomes]

### Neutral

- [Trade-offs that are neither clearly good nor bad]

### Bad

- [Negative outcomes or risks accepted]

## Confirmation

[How to verify implementation compliance. Concrete, testable criteria.]

## Pros and Cons of the Options

### Option A

- Good: [advantage]
- Bad: [disadvantage]

### Option B

- Good: [advantage]
- Bad: [disadvantage]

## Reassessment Criteria

[When should this decision be revisited? What conditions would trigger a review?]
```

Use today's date for the `date` field. Set `reassessment-date` to 3 months from today unless the user specifies otherwise.

### 5. Confirm with the user — two separate fires (P339 + P340)

Step 5 fires TWO separate `AskUserQuestion` passes, in this order:

1. **Substance-confirm fire** — the user picks the chosen option from the considered-options set. THIS fire gates the born-confirmed marker write.
2. **Draft-quality review fire** (optional, after substance-confirm passes) — narrow questions on prose quality, consulted/informed list, edge cases. Does NOT gate the marker.

This split closes the P339 / P340 gap: previously Step 5 fired ONE bundled "review pass" AskUserQuestion ("does the problem statement + Decision Outcome (Option X) capture the situation? — yes/no/edits/different-option"), and the user's "Yes" was treated as substance-ratification when in practice the user was confirming draft quality alone. The bundled answer landed the human-oversight marker on substance the user never explicitly affirmed. ADR-078 commit 5196e3d is the in-session exemplar; user correction 2026-05-31: *"I never approved the scripted extraction. You are supposed to run decisions by me"* + *"the previous iteration of the decision, with the programmatic extraction was not approved. How did that ADR skip ratification?"*. ADR-074 § Enforcement surface 1 is what this step now operationalises at the create-adr surface.

#### 5a. Substance-confirm fire (P340 — load-bearing for the marker write)

The substance-confirm fire MUST satisfy ALL FIVE interaction-pattern requirements pinned by user direction 2026-05-31 (encoded in ADR-064 + ADR-066 amendments + P340 § Root Cause Analysis):

1. **Briefing in main-turn prose** — emit the considered-options + selected-option + rationale as plain main-turn text BEFORE the `AskUserQuestion` fires. The briefing carries the substance-of-the-decision in a form the user can read and reason about. Long AskUserQuestion text is NOT readable on some devices (mobile clients, accessibility tooling, certain notification surfaces); long prose + short question IS readable across the full device matrix. The split is load-bearing — briefing carries the briefing; the AskUserQuestion stays narrow.

2. **AskUserQuestion is option-shaped, NOT yes/no** — the `options:` array MUST contain each considered option as a selectable option (one entry per considered option). The user picks the substantive direction positively (chooses ONE option), not by clicking "yes" on a bundled "is this OK?" question. Yes/no shape is forbidden at this fire.

3. **No IDs as explainers** — neither the briefing prose nor the `AskUserQuestion` text/options/descriptions may use IDs (`ADR-NNN`, `P-NNN`, `JTBD-NNN`, `RFC-NNN`) as the carrier of meaning. The user does NOT have access to those IDs on all devices (mobile clients without the project filesystem; notification surfaces; accessibility readers that can't follow links). Every option's substance MUST be self-contained in the briefing prose + the option label/description. IDs may appear ONLY as audit-trail annotations after a self-contained explanation, never as the explanation itself.

4. **Informed-decision-without-external-document-lookup** — the briefing + question + options is a self-contained surface. If understanding a chosen option requires the user to first read another document, the briefing has failed. The briefing carries enough context that a user reading ONLY the main-turn text and the AskUserQuestion can pick.

5. **Each option's substance is the actual chosen option** — the options array contains the actual considered options from the ADR draft (Option A / Option B / Option C / ... as worded in the Considered Options section), NOT meta-options ("yes accept draft" / "ask differently"). The label is a short readable phrase; the description carries the trade-off. Picking an option IS the substantive choice.

**Suggested AskUserQuestion shape** (each considered option as one selectable option):

```text
question: "Which option should this ADR record as the chosen direction?"
header: "Chosen option"
multiSelect: false
options:
  - label: "<Option A short name>"
    description: "<Option A self-contained trade-off summary, no IDs as explainers>"
  - label: "<Option B short name>"
    description: "<Option B self-contained trade-off summary, no IDs as explainers>"
  - ...one entry per considered option
```

**Born-confirmed marker write (ADR-066 — tightened by P340 amendment + structurally gated by P348 amendment 2026-06-02).** The marker write fires ONLY when the substance-confirm answer specifies a substantive option from the considered-options set AND that option matches the option the draft was authored against. On a substantive match, IMMEDIATELY call the marker-evidence helper THEN insert the two lines:

```bash
wr-architect-mark-oversight-confirmed docs/decisions/<NNN>-<slug>.proposed.md
```

```yaml
human-oversight: confirmed
oversight-date: YYYY-MM-DD   # today
```

The `wr-architect-mark-oversight-confirmed` call writes the session-scoped evidence marker (`/tmp/oversight-confirmed-<sha>-<sid>`) that the `architect-oversight-marker-discipline.sh` PreToolUse hook reads to authorise the subsequent Edit/Write — without the helper call, the hook will DENY the marker write. AFK iter subprocesses spawned via `claude -p` have no `AskUserQuestion` access; they MUST write `human-oversight: unconfirmed` instead (the AFK fallback enum value codified in ADR-066 amendment 2026-06-02), which the drain (`/wr-architect:review-decisions`) later promotes interactively. Calling the helper without a real user substance-confirm event is the P348 hollow-marker bug — every legitimate marker write traces back to an `AskUserQuestion` answer in the same turn.

**ADR-013 Rule 6 carve-out audit (P352, 2026-06-06 amendment)**: the universal AFK default is queue-and-continue. This Step 5 substance-confirm HALT-and-write-`human-oversight: unconfirmed` shape is a documented carve-out, authorised by **ADR-074** (Confirm decision substance before building dependent work). Rationale: an ADR with `human-oversight: confirmed` enters the world born-confirmed (it does not appear in `/wr-architect:review-decisions`' unoversighted set), so dependent work — every implementation that cites this ADR as authority — would be built on substance that was never user-affirmed. AFK writing `human-oversight: unconfirmed` IS the queue-and-continue shape: the loop continues; the substance-confirm decision is queued to the next interactive drain. Persona-correct for JTBD-006 ("queued for my return, not guessed at"); the carve-out is from the auto-confirm shape, not from queue-and-continue itself.

**Mismatch handling.** If the substance-confirm answer selects a DIFFERENT option than the draft was authored against:

- DO NOT write the marker.
- Re-draft Decision Outcome + Consequences + Confirmation + Pros and Cons (and Reassessment Criteria if affected) against the newly-chosen option.
- Re-fire the substance-confirm `AskUserQuestion` against the re-drafted text to verify the substance now matches the user's pick.
- The marker writes ONLY after a substance-confirm pass whose answer matches the draft on disk.

This is NOT a soft "warn and proceed" path — the marker only ever writes when the draft on disk encodes the user's substantive pick. Mismatch is a re-draft trigger, not an override.

**What the marker means.** This is the load-bearing born-confirmed gate: an ADR recorded through create-adr enters the world already human-oversighted (it does not appear in `/wr-architect:review-decisions`' unoversighted set) ONLY because the substance-confirm fire above explicitly affirmed the chosen option. Do NOT write the marker if the user has not confirmed substance (rejected / still-iterating ADRs stay unmarked). The marker is orthogonal to `status:` — a `proposed` ADR can be `human-oversight: confirmed`.

**Retitle-after-decision check (P354 — ADR-044 category-4 silent-framework).** After the marker write lands, check the on-disk filename slug for a question-shape pattern (`-vs-`, `should-`, `whether-`, `-or-`). If matched, the title was derived at intake against a question-shaped problem-statement and must be retitled to the chosen-option's outcome shape now that the substance is locked in. The convention is named in Step 2a above.

This step is **mechanical — no AskUserQuestion fires** (per P132 inverse-P078 guard). The chosen option is now known from the substance-confirm answer just above; derive the outcome slug from the chosen-option short name via the same `derive_kebab_slug` helper Step 2's Title derivation uses (`packages/architect/lib/derive-first-dispatch.sh`). Sequence (ordered to preserve marker-discipline hook semantics — the marker-introducing Edit must land BEFORE `git mv`):

1. Derive `new_slug = derive_kebab_slug "<chosen option short name>"`.
2. Edit the H1 in the on-disk file to the new outcome shape (H1 stays human-readable Title Case; the slug is for the filename). The `human-oversight: confirmed` line is already in `OLD_CONTENT` so `architect-oversight-marker-discipline.sh` allows this Edit per its "old content already had the marker" branch.
3. `git mv docs/decisions/<NNN>-<old-slug>.proposed.md docs/decisions/<NNN>-<new-slug>.proposed.md` (Bash command — no Edit/Write hook fires; rename is captured as a rename in git history).
4. Emit the I2-isomorphic stderr advisory: `create-adr: retitled <NNN>-<old-slug>.proposed.md -> <NNN>-<new-slug>.proposed.md from chosen-option '<short-name>'; git mv reversible via inverse rename.`
5. The subsequent compendium regen below picks up the new filename automatically.

If the on-disk slug does NOT match a question-shape pattern (already outcome-shaped at intake), skip this step silently — no advisory needed.

(Serves JTBD-001 — outcome-shaped on-disk title; category-4 silent-framework per ADR-044.)

#### 5b. Draft-quality review fire (optional, after 5a passes)

After the substance-confirm fire passes and the marker is written, fire a separate narrow `AskUserQuestion` for draft-quality review:

1. Does the problem statement accurately capture the situation?
2. Are the pros/cons fair and complete?
3. Are the confirmation criteria testable?
4. Should anyone else be listed as consulted or informed?

Apply any feedback by editing the file. This fire is OPTIONAL — when the agent has high confidence the prose is sound and the consulted/informed list is complete, this fire MAY be skipped. The draft-quality review does NOT gate the marker — the marker writes (or doesn't) on the substance-confirm answer alone. Surfacing a draft-quality fire after marker-write is correct; gating the marker on draft-quality answers is what P340 prohibits.

**Refresh the decisions compendium (ADR-077).** After the ADR file is written and any born-confirmed marker is applied, regenerate `docs/decisions/README.md` so the architect-agent routine load surface includes the new entry. Run:

```bash
wr-architect-generate-decisions-compendium
git add docs/decisions/README.md
```

The compendium is the architect agent's primary load surface per ADR-077; skills own keeping it fresh. The `architect-compendium-refresh-discipline.sh` PreToolUse hook is the safety-net backstop — it will DENY a commit that stages the new `docs/decisions/<NNN>-*.md` without a matching `docs/decisions/README.md`. Regenerating here makes that hook a no-op on the happy path.

### 6. Handle supersession (if applicable)

If the user mentions this decision replaces an existing one:
1. Add `supersedes: [NNN-old-decision-title]` to the new decision's frontmatter
2. Rename the old decision file from `.accepted.md` (or `.proposed.md`) to `.superseded.md` using `git mv`
3. Update the old decision's frontmatter status to `superseded`
4. Add a "Superseded by" section to the old decision referencing the new one
5. **Re-stage the renamed file explicitly after the `Edit` tool runs**: `git add docs/decisions/<NNN>-<title>.superseded.md`. `git mv` stages only the rename — the subsequent frontmatter and "Superseded by" edits must be added again before commit, or they leak into the next commit (P057 staging trap).

$ARGUMENTS
