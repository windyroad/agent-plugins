# Problem 483: Amendment sections are not a legitimate mechanism — a ratified decision is immutable

**Status**: Open
**Reported**: 2026-08-08
**Priority**: 16 (High) — Impact: 4 × Likelihood: 4. Impact 4: an amendment section changes what a ratified document says without a new confirm event, so it carries the earlier ratification's authority onto text the human never saw. That is a governance failure, not a legibility one, and it is the mechanism behind P479 and P480 rather than a sibling of them. Likelihood 4: the pattern is pervasive — 27 amendment sections sit across 9 in-force decisions, ADR-060 has been amended by several, and the review contract actively coached toward the pattern until it was changed.
**Origin**: corrective-feedback
**Effort**: L — a rule, a corpus sweep across many decisions, a change to the review contract, and behavioural tests
**JTBD**: JTBD-008
**Persona**: plugin-developer

## Description

A decision document records **one choice between options**. Its lifecycle has exactly two phases:

- **Before ratification it is mutable.** Edit it freely — rewrite the context, sharpen the outcome, *add another option to the set being weighed*. Nothing is fixed yet, because no human has confirmed anything.
- **After ratification it is immutable.** The only legitimate moves are to **deprecate** it or to **supersede** it with a new decision. You do not edit it, and you do not reach into it from another document.

The maintainer, 2026-08-08:

> If you want to amend a decision, you need to create a new one that supersedes it. As it stands ADR-106 is much more than a single decision.

and on the lifecycle:

> The decision can be changed multiple times until it is ratified. A decision is a single choice between options. You can add another choice in that one decision. Once ratified, you can't change it except to deprecate it or supersede it.

**`### Amendment to ADR-NNN` sections are not a legitimate mechanism.** They are how a ratified decision gets rewritten without a confirm event, and how one document acquires authority over another's text.

### The instance

ADR-106 was written to record a single decision — a story map carries no decision trace. As ratified it held four things: that decision, an `### Amendment to ADR-060`, an `### Amendment to ADR-102`, and narration of a separate ADR-103 amendment. It also carried `amends: [ADR-060, ADR-102]` in frontmatter, and the change edited both of those accepted/ratified documents in place.

Every one of those edits was reasonable in isolation. That is the trap: the schema in ADR-060 really is stale, and ADR-102's "preserved verbatim" sentence really is false. Amending was the cheap, obvious response, and it produced a document that decides one thing and changes three.

### Why this is the parent of P479 and P480

- **P479** — decisions accrete into the nearest ADR because amending is cheaper than deciding.
- **P480** — an ADR's ratification is document-scoped, so riders that were never weighed inherit its authority.

Both describe consequences of amendment being available at all. Remove the mechanism and neither has a vector: there is nowhere for a decision to accrete *into*, and no way for unweighed text to land inside a confirmed document. This ticket is the fix locus those two point at.

### The review contract carries the wrong rule too

Across roughly twenty architect reviews of the ADR-106 change, `wr-architect:agent` repeatedly **required** amendment sections — flagging a missing `amends:` entry as `[Missing Supersession]`, directing that ADR-060's schema be struck under ADR-106's authority, and citing ADR-095/096/103's amendment sections as the established precedent to follow. The agent was applying the corpus's own convention faithfully. So the rule cannot land only in authoring guidance; the review contract enforces the opposite today.

## Symptoms

- An `### Amendment to ADR-NNN` heading inside a decision document.
- An `amends:` frontmatter key.
- A ratified decision whose body carries text dated after its `oversight-date`.
- A decision document that changes more documents than it decides things.

## Workaround

Before ratification, edit freely. After ratification, write a new decision that supersedes the old one and say so in both — the superseding document names what it replaces, and the superseded one is marked and left otherwise untouched.

## Impact Assessment

- **Who is affected**: whoever ratifies a decision and every later reader who takes a confirmed document as settled.
- **Frequency**: pervasive. 27 amendment sections across 9 decisions, and 12 documents carrying an `amends:` key.
- **Severity**: governance. A ratified document can be rewritten without a confirm event.
- **Analytics**: none.

## Root Cause Analysis

Suspected: amendment is structurally cheaper than superseding. It needs no new file, no options section, no ratification event and no ID allocation — so under any time pressure it is the path taken, and nothing refuses it. Superseding forces the question "is this actually a new decision?", which is the question that should be asked.

### Investigation Tasks

- [ ] Write the rule down where authoring happens: `/wr-architect:create-adr`, the decisions README, and the ADR template. Mutable until ratified — including adding an option; immutable after, deprecate or supersede only.
- [x] **Change the review contract.** Done 2026-08-08. `wr-architect:agent` gained a `[Amendment To Ratified Decision]` issue type and an "a ratified decision is immutable" section stating the two-phase lifecycle, refusing `### Amendment` sections and the `amends:` key, and naming supersession as the route. It explicitly refuses three remedies that look reasonable and are not: clearing the marker and re-ratifying, calling the edit a clarification, and citing the corpus's existing amendment sections as precedent — that last one is why the rule needed stating, since the reviewer used it repeatedly.

  Proven behaviourally against the real agent. Before: *"Editing a ratified decision in place is acceptable — and here it's required"*, citing ADR-052's and ADR-090's own amendment sections. After: two `[Amendment To Ratified Decision]` findings plus the supersession mechanics, and it inferred unprompted that retiring a decision leaves its marker alone because retiring is not rewriting. Over-fire checked separately: a change that merely cites an ADR carrying three existing amendment sections draws no flag, with the reason given correctly. A promptfoo eval case pins both halves.
- [ ] Sweep the corpus — **27 amendment sections across 9 ADRs**, plus 12 carrying an `amends:` key. Maintainer direction 2026-08-08 is to convert **every** one into supersession. Each conversion is a new decision needing its own ratification, so the cost falls on the maintainer's review attention rather than on implementation time. Now safe to start: the review contract no longer re-teaches the pattern behind the sweep.
- [ ] Decide what happens to the `amends:` frontmatter key. It probably goes, replaced by `supersedes:` / `superseded-by:`.
- [ ] Build a detector: an `### Amendment` heading, or an `amends:` key, or body text dated after `oversight-date` in a `confirmed` document.
- [x] ADR-103's 2026-08-08 amendment — removed 2026-08-08. It postdated its own confirm event by a day, which was this ticket's shape on the document the current change depends on. Its substance is now ADR-107, a decision in its own right.

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)

## Related

- **P479**, **P480** — both are consequences of this. Worth re-reading them as symptoms once the rule lands; they may fold in.
- **ADR-106** — the instance. Cut back to one decision 2026-08-08; both amendment sections removed and the documents they edited reverted untouched.
- **ADR-107** — what the removed ADR-103 amendment became: a separate decision rather than an edit to a ratified one. The worked example of the remedy.
- **ADR-060**, **ADR-102** — edited in place by ADR-106; those edits are being reverted.
- **ADR-103** — carries three amendment sections, all predating its ratification. A fourth, added and then removed on 2026-08-08, postdated it by a day.
- Maintainer correction, 2026-08-08: *"Don't do that shit."*

(captured via /wr-itil:capture-problem; expand at next investigation)
