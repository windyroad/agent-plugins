---
name: wr-architect:capture-adr
description: Lightweight ADR-capture skill for aside-invocation during foreground work — derives full MADR substance (Considered Options / Decision Drivers / Consequences / Confirmation / Reassessment) silently from the in-session decision context, single commit, no inline architect-review handoff, no AskUserQuestion. Lightweight means zero-interaction + single-commit, not skimpy content (RFC-045). Use this when the user (or agent mid-iter) wants to record a decision quickly without the ~10-15 turn ceremony of /wr-architect:create-adr. For interactive full-intake new ADR creation where the user authors the options + drivers + consequences + confirmation, use /wr-architect:create-adr.
allowed-tools: Read, Write, Edit, Bash, Grep, Glob
---

# Capture ADR Skill

Capture an Architecture Decision Record quickly during foreground work. Lightweight aside-invocation surface that complements the heavyweight `/wr-architect:create-adr` flow. See `REFERENCE.md` in this directory for rationale, edge cases, contract trade-offs, and the ADR-032 foreground-lightweight-capture amendment.

This skill is the foreground-lightweight-capture variant of `/wr-architect:create-adr`'s new-ADR path per ADR-032 (P156 amendment, 2026-05-03). The deferred background-capture variant named in ADR-032's original taxonomy remains deferred per P088 settlement.

## When to invoke

- **Mid-iter design decision**: agent or user lands on a design choice during foreground work and cannot afford the ~10-15 turn ceremony of `/wr-architect:create-adr`.
- **Architect-review verdict capture**: a `wr-architect:agent` review yields a substantive PASS-WITH-NOTES / ISSUES-FOUND verdict whose rationale deserves an ADR-shaped record (today the verdict lands in commit messages and the rationale rots).
- **User-driven design conversations**: user resolves options (a)/(b)/(c) during conversational work; today the settlement gets buried in a problem-ticket RCA section instead of codified.

**Use `/wr-architect:create-adr` instead** when:
- The user wants to walk the full interactive intake flow and author the sections themselves (Considered Options ≥2, Decision Drivers, full Consequences, Confirmation criteria, Pros/Cons of Options via AskUserQuestion).
- The decision is contested or under-specified in-session — silent derivation needs a real decision context to derive FROM; if the options were never actually weighed, create-adr's interactive intake is the honest surface.
- The decision needs immediate architect review + acceptance (capture-adr writes `.proposed.md`; acceptance review is a follow-up via `/wr-architect:create-adr` or direct architect-agent review).

## Rule 6 audit (per ADR-032 + ADR-013)

This skill has **zero AskUserQuestion branches** by design. Each potentially-interactive decision is framework-mediated per ADR-044:

| Decision | Resolution |
|----------|-----------|
| Considered Options ≥2 | Silent derivation (ADR-044 category-4): write the chosen option PLUS every alternative that was actually weighed and rejected in the decision context (`$ARGUMENTS` + the invoking session). Real options with one-line summaries — never a placeholder sibling. If the context genuinely weighed only one option, derive the strongest do-nothing / status-quo alternative and say why it lost. |
| Decision drivers | Silent derivation: extract the forces that actually drove the decision from the context (the problem's symptoms, the constraint that ruled options out, the user's stated priorities). |
| Consequences | Silent derivation: real Good/Neutral/Bad trade-off analysis of the chosen option. The invoking agent performs the analysis at capture — it has more decision context in-session than any later expansion pass would. |
| Confirmation criteria | Silent derivation: testable criteria (a command, an observable behaviour, a hook that fires) confirming the decision is implemented and holding. |
| Reassessment criteria | Silent derivation: real conditions that would reopen the decision, plus `reassessment-date` default 3 months from today (matches `create-adr` Step 4 default). |
| Decision-makers / consulted / informed | Silent derivation: `decision-makers: [<git config user.name>]` plus any decision-owner named in `$ARGUMENTS`; `consulted`/`informed` from context or `[]`. Never a sentinel string. |
| Empty `$ARGUMENTS` | Halt-with-stderr-directive: print "capture-adr requires Title + 1-line Context + 1-line Decision in $ARGUMENTS — invoke /wr-architect:create-adr instead for the full intake flow" and exit. AFK orchestrators MUST NOT invoke capture-adr with empty arguments — caller-side contract. |

**No placeholder, pointer, or sentinel strings of any kind** (RFC-045 / P375, derived-substance amendment to ADR-032 2026-07-06). The previous deferred-placeholder pattern (`(deferred to /wr-architect:create-adr canonical review)`) named a re-entry point nothing self-firing ever triggered — the sections rotted. Same correction class as ADR-067's silent derivation of capture-problem ratings: derive a real value, always. The derived substance is provisional — that is what `human-oversight: unconfirmed` states honestly, and the SessionStart oversight nudge → `/wr-architect:review-decisions` drain is the self-firing surface where a human ratifies or amends it (ADR-066).

Per ADR-013 Rule 6 fail-safe: every branch above resolves without user input, so AFK and interactive contexts behave identically.

## Steps

### 1. Parse Title + 1-line Context + 1-line Decision from `$ARGUMENTS`

The expected `$ARGUMENTS` shape is free-text describing **(a) Title**, **(b) one-line Context** (the problem being solved), and **(c) one-line Decision** (the chosen option in one sentence).

Parsing heuristic: split on the first newline (Title) and second newline (Context); the rest is Decision. If only one line is supplied, treat it as Title and derive Context + Decision from the invoking session's decision context. If two lines, treat as Title + Decision and derive Context. Derivation is real prose from the context at hand — never a placeholder.

Empty `$ARGUMENTS` halts per the Rule 6 audit above.

Derive a kebab-case title slug from the first 8-10 non-stopword tokens of the Title (matching the existing `create-adr` slug derivation pattern).

#### Title-as-outcome convention (P354)

ADR titles must name the **decision outcome** as a short noun phrase, not the question being decided. The title is the skim-surface for `docs/decisions/` and the ADR-077 compendium — readers should resolve what was decided from the title alone, without opening the file. User direction 2026-06-03 (P354): *"ADR titles are supposed to be the short version of what was decided, so they are skimmable."*

**GOOD** (outcome — short noun phrase; drawn from corpus): `marketplace-only-distribution`, `monorepo-per-plugin-packages`, `behavioural-tests-default-for-skill-testing`, `plugin-script-resolution-via-bin-on-path`, `every-fix-goes-through-an-rfc`.

**BAD** (question / option-pair / deliberation): `<X>-vs-<Y>` (option-pair), `should-<Z>` (deliberation), `whether-<Z>` (open question), `<X>-or-<Y>` (pure option-set).

In `capture-adr` the chosen Decision is pinned in `$ARGUMENTS` at invocation, so the caller SHOULD supply a Title already in outcome shape — the framework does not retitle here (the canonical-outcome short-name is the caller's to author, not the framework's to derive). If the parsed Title slug matches a question-shape pattern (`-vs-`, `should-`, `whether-`, `-or-`), emit an advisory in the I2-isomorphic shape via the shared `emit_stderr_advisory` helper:

```
capture-adr: derived title='<slug>' from $ARGUMENTS — slug appears question-shaped (matched <pattern>); the Decision is pinned in $ARGUMENTS so an outcome-shaped Title is recommended; re-invoke with an outcome-shaped Title or rename the file before acceptance review.
```

The advisory is **advisory-only** (no halt, no retitle). The caller may proceed with the question-shaped slug if they choose; a subsequent `/wr-architect:create-adr <NNN>` acceptance pass picks up the retitle in its Step 5a mechanical retitle-after-decision check.

(Serves JTBD-001 — skimmable titles on the on-disk record; ADR-044 category-4 silent-framework — advisory, not ask.)

### 2. Compute the next ADR ID

Same P056-safe `local_max + origin_max + 1` formula as `/wr-architect:create-adr` Step 3:

```bash
local_max=$(ls docs/decisions/*.md 2>/dev/null | sed 's/.*\///' | grep -oE '^[0-9]+' | sort -n | tail -1)
origin_max=$(git ls-tree --name-only origin/main docs/decisions/ 2>/dev/null | sed 's|^docs/decisions/||' | grep -oE '^[0-9]+' | sort -n | tail -1)
next=$(printf '%03d' $(( 10#$(echo -e "${local_max:-0}\n${origin_max:-0}" | sort -n | tail -1) + 1 )))
```

`--name-only` is required (P056): without it, each `git ls-tree` line includes the 40-char blob SHA which can contain three-digit runs that the digit-extraction regex false-matches.

Log the renumber decision in the operation report if origin and local diverged.

### 3. Derive-fill the MADR template

**File path**: `docs/decisions/<NNN>-<kebab-title>.proposed.md`

**Template** (derived-substance pattern per RFC-045 — every section carries real content derived from `$ARGUMENTS` + the invoking session's decision context; no placeholder, pointer, or sentinel strings of any kind):

```markdown
---
status: "proposed"
date: <YYYY-MM-DD>
human-oversight: unconfirmed
decision-makers: [<git config user.name>, <any decision-owner named in $ARGUMENTS>]
consulted: [<from context, or empty>]
informed: [<from context, or empty>]
reassessment-date: <YYYY-MM-DD + 3 months>
---

# <Title>

> Captured via /wr-architect:capture-adr (foreground-lightweight aside-invocation per ADR-032, derived-substance amendment 2026-07-06 / RFC-045). Section content was derived by the capturing agent from the in-session decision context; human-oversight: unconfirmed until ratified at the /wr-architect:review-decisions drain.

## Context and Problem Statement

<Context from $ARGUMENTS, expanded with the problem the session was actually solving when the decision arose>

## Decision Drivers

- <the real forces that drove the decision: symptoms, constraints, stated priorities — one bullet each>

## Considered Options

1. **<Chosen option> (chosen)** — <one-line summary>
2. **<Rejected alternative actually weighed in context>** — <one-line summary>
<further alternatives if the context weighed them; if only one option was ever on the table, the status-quo/do-nothing alternative and why it lost>

## Decision Outcome

Chosen option: **"<Chosen option>"**, because <the real reason from $ARGUMENTS/context>.

## Consequences

### Good

- <real benefits of the chosen option>

### Neutral

- <real neutral effects, or omit bullets that would be filler>

### Bad

- <real costs/risks accepted by choosing this option>

## Confirmation

<testable criteria: a command, an observable behaviour, a gate that fires — how a future reader verifies the decision is implemented and holding>

## Pros and Cons of the Options

### <Chosen option>

- Good, because <...>
- Bad, because <...>

### <Rejected alternative>

- Good, because <...>
- Bad, because <...>

## Reassessment Criteria

<real conditions that would reopen this decision — e.g. the constraint that forced it lifts, the chosen mechanism's false-positive rate exceeds tolerance>
```

Content-quality bar: each section must be true to the decision context at hand, not boilerplate. A section the context genuinely gives nothing for gets the honest one-liner saying so in real prose (e.g. "No neutral consequences identified at capture") — never a deferral marker. The capturing agent has more decision context in-session than any later pass will; capture is the cheapest moment to write the substance down.

### 4. Write the file

Single `Write` to `docs/decisions/<NNN>-<kebab-title>.proposed.md`.

### 4.5. Refresh the decisions compendium (ADR-077)

After the ADR lands, regenerate `docs/decisions/README.md` so the architect-agent routine load surface includes the new entry:

```bash
wr-architect-generate-decisions-compendium
```

The compendium is the architect agent's primary load surface per ADR-077; capture-adr owns keeping it fresh (skills + agent are PRIMARY; the `architect-compendium-refresh-discipline.sh` hook is the safety-net backstop). The next step stages both files together.

### 5. Commit per ADR-014 — single commit, no architect-review handoff

**Stage list**: the new ADR file AND the refreshed compendium (ADR-077 — both move in the same commit so the architect-compendium-refresh-discipline hook passes).

```bash
git add docs/decisions/<NNN>-<kebab-title>.proposed.md docs/decisions/README.md
```

Satisfy the commit gate per ADR-014 — same two-path pattern as `manage-problem` Step 11 / `capture-problem` Step 6:

- **Primary**: delegate to subagent type `wr-risk-scorer:pipeline` via the Agent tool.
- **Fallback**: invoke `/wr-risk-scorer:assess-release` via the Skill tool when the subagent type is unavailable in the current tool surface.

Commit message:

```
docs(decisions): capture ADR-<NNN> <title>
```

The `capture` verb is the audit signal that this ADR landed via the lightweight aside path (vs. `add` / `accept` for canonical create-adr's full intake). The status remains `proposed` until acceptance review (with human substance-ratification per ADR-064) promotes it.

### 6. Report

After the commit, report:

- The new ADR file path and ID.
- Trailing pointer: `ADR-<NNN> was captured with derived substance and is human-oversight: unconfirmed — the SessionStart oversight nudge will surface it for ratification at /wr-architect:review-decisions (or ratify now if interactive).`
- Note any renumber-from-origin-collision log line from Step 2.

The trailing pointer is **not optional** — it is the user-visible signal that the derived substance awaits human ratification. Unlike the pre-RFC-045 contract there is no expansion step: the sections are already real; the drain confirms or amends them.

**Confirm-every-ADR gate (ADR-064):** a capture-adr ADR is recorded `proposed` with derived substance but WITHOUT human review of that substance. It must NOT be promoted to `accepted` until a human has ratified the derived content via `/wr-architect:review-decisions` (or a `/wr-architect:create-adr` review-and-confirm pass). Capture records the decision quickly; the ratification — not the capture — is what gives it human oversight. This is prong 1 of P283 (lift auto-/quick-recorded decisions to human-confirmed before they stand).

**Oversight marker discipline (ADR-110 / P348).** A capture-adr ADR MUST be born `human-oversight: unconfirmed` — NOT `confirmed`. Capture is the AFK-friendly aside surface; there is no substance-confirm `AskUserQuestion` pass in this flow, so `confirmed` would be a hollow marker (the P348 bug class). The `architect-oversight-marker-discipline.sh` PreToolUse hook will DENY any Edit/Write that introduces `human-oversight: confirmed` without a matching session-scoped evidence marker. The frontmatter (Step 3 above) MUST include `human-oversight: unconfirmed` so the ADR enters the world honestly self-identified as needing user confirmation. The drain (`/wr-architect:review-decisions`) and a `/wr-architect:create-adr <NNN>` review pass are the surfaces that legitimately promote it to `confirmed` via `wr-architect-mark-oversight-confirmed` + the gated marker write.

## Composition with create-adr

| Concern | create-adr | capture-adr |
|---------|------------|-------------|
| Considered Options | AskUserQuestion gathering ≥2 options + pros/cons (user authors) | Silent derivation of chosen + actually-rejected alternatives (agent authors, human ratifies at drain) |
| Decision Drivers | AskUserQuestion gathering | Silent derivation from decision context |
| Consequences | AskUserQuestion gathering Good/Neutral/Bad | Silent derivation — real Good/Neutral/Bad trade-off analysis at capture |
| Confirmation | AskUserQuestion gathering testable criteria | Silent derivation of testable criteria |
| Reassessment criteria | AskUserQuestion gathering | Silent derivation + 3-month default date |
| Frontmatter | Full populated frontmatter | Derived values (git user.name etc.) — no sentinels |
| Decision-boundary check (Step 2b) | Multi-decision split via AskUserQuestion | Out of scope (one ADR per invocation) |
| Supersession (Step 6) | Handles `git mv .accepted.md → .superseded.md` | Out of scope (capture is creation only) |
| Confirm-with-user (Step 5) | AskUserQuestion review pass at intake | Deferred to the self-firing oversight drain (`human-oversight: unconfirmed` → SessionStart nudge → `/wr-architect:review-decisions`) |
| Commit grain | One commit per intake | One commit per capture |
| Use case | Full-intake new ADR; user wants to author the flow interactively | Aside-invocation; capture-and-continue |

The two skills share the `docs/decisions/*.proposed.md` directory and the next-ID formula. Category-1 reconciliation (per the ADR-032 derived-substance amendment): create-adr's Step 2 dispatch table classifies Drivers/Options/Consequences/Confirmation as category-1 "only the user knows" — that governs the interactive intake surface. On the capture surface the same fields are derived-provisional substance under `human-oversight: unconfirmed`, ratified at the ADR-066 drain (the ADR-067 lift-auto-decisions-to-human pattern). Capture derives-then-ratifies; create-adr asks-then-records.

## Related

- **P156** (`docs/problems/156-ship-capture-adr-skill.open.md`) — driver ticket.
- **P014** (`docs/problems/014-aside-invocation-for-governance-skills.open.md`) — parent / master tracker.
- **P155** (`docs/problems/155-ship-capture-problem-skill.verifying.md`) — sibling capture-problem skill.
- **P157** — sibling pending-questions-surface hook.
- **ADR-032** (`docs/decisions/032-governance-skill-invocation-patterns.proposed.md`) — foreground-lightweight-capture variant amendment (P156 amendment, 2026-05-03).
- **ADR-038** — progressive-disclosure pattern (SKILL.md + REFERENCE.md split).
- **ADR-044** — decision-delegation contract (framework-mediated mechanical-stage carve-outs).
- **ADR-049** — bin/ on PATH (capture-adr is self-contained; no shim required, same as create-adr).
- **ADR-052** — behavioural-tests-default for skill testing.
- `packages/architect/skills/create-adr/SKILL.md` — heavyweight intake counterpart.
- `packages/architect/agents/agent.md` — wr-architect:agent review surface; reviews `.proposed.md` ADRs at acceptance delegation.

$ARGUMENTS
