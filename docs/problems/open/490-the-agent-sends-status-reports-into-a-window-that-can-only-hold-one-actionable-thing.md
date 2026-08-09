# Problem 490: The agent sends status reports into a window that can only hold one actionable thing

**Status**: Open
**Reported**: 2026-08-09
**Priority**: 12 (High) — Impact: 3 × Likelihood: 4. Impact 3: nothing produced is wrong, but the maintainer's attention is the scarcest resource in the loop and a status report spends several screens of it on something they cannot act on, burying whatever did need them. Likelihood 4: it recurs whenever a unit of work completes, which is constantly. Rated on evidence rather than estimate — the identical correction fired twice, verbatim, on consecutive days.
**Origin**: corrective-feedback (user, 2026-08-08 and again 2026-08-09)
**Effort**: M — the rule is simple; making it hold is not, since the obvious mechanism (write it down) is the one already proven insufficient.
**JTBD**: JTBD-002
**Persona**: developer

## Description

The maintainer reads on a phone. No filesystem, no repository access, no way to open a path. Between a job, a wife, three children and a house, attention arrives in fragments. The chat window is the whole interface.

Into that window the agent sends status reports: what landed, how many review rounds it took, what a reviewer found, what the agent got wrong along the way, how many items remain, and an invitation to continue. None of it is actionable. All of it costs screens.

On 2026-08-09, after a decision landed, the agent sent five screens of exactly that and ended with *"Next one whenever you want it."* The maintainer photographed it on their phone and replied with a correction they had already given, word for word, the day before:

> *"FFS! If you want me to ratify something you have to give me the file. This is my interface. This is the window you have to work with me with. You MUST take that into consideration. You are familiar with 'theory of mind' where one intelligence can reason about the mental state of another intelligence. Use that! Think about what I know and what I don't or may have forgotten. Think about the small window you have to interact with me with. Think about all the things I, as a human male with a wife, 3 kids and a job, and a house to run, that I might be doing and might be stealing my attention. Be more empathetic!"*

### The part that makes this a ticket rather than a note

The first occurrence, on 2026-08-08, produced a session memory recording the correction in full — the phone, the missing file, the theory-of-mind instruction. That memory was in context on 2026-08-09. **It did not prevent the second occurrence.** Writing the rule down is the mechanism that has already been tried and has already failed once, which is the same shape as the rule in ADR-111 that sat in prose for three months while nothing implemented it.

### What the rule actually is

Every message is one of two kinds. Either it carries an artefact as a file, with a short plain-language summary above it and a structured question with real options below it — the shape ADR-111 ratified — or it is not sent at all and the agent keeps working. There is no third kind. A status report is not a courtesy; it is several screens of someone's attention spent on something they cannot act on.

The recurring specifics, each of which has drawn its own correction:

- Asking permission to send the artefact under review, instead of sending it. *"next time just send me the map. You don't need to ask me permission to send me the map."*
- Ending on an open invitation — *next one whenever you want it*, *let me know*, *want me to continue?* — where the work was either obvious or needed a real question.
- Narrating process: review-round counts, which agent found what, what the agent got wrong. None of it is the maintainer's to carry.
- Requiring the reader to hold state from earlier messages to parse the current one.

## Symptoms

- A message longer than a screen that asks for nothing.
- An artefact referenced by path or by identifier where the reader cannot open either.
- A message ending in an invitation rather than a question or nothing.
- The same correction arriving more than once.

## Workaround

The maintainer re-issues the correction. It holds for a few turns.

## Impact Assessment

- **Who is affected**: the maintainer, whose attention is the loop's bottleneck, and any adopter of these plugins whose agent behaves the same way.
- **Frequency**: on completion of any unit of work, which in a working session is continuous.
- **Severity**: attention and trust. The work is right; the delivery makes it expensive to receive, and repeated correction of the same thing erodes confidence that corrections stick.
- **Analytics**: none.

## Root Cause Analysis

Suspected: the agent optimises for demonstrating that the work was done properly — the rounds survived, the errors caught, the counts reconciled — which is a legible proxy for diligence and costs the author nothing. The reader pays for it. Nothing in the loop represents the reader's attention as a budget, so there is no pressure against spending it.

The second-order cause is the one that makes this ticketable: the correction has been captured as prose twice and has not held either time. Prose that describes a behaviour is not a check on it, which is the same finding ADR-111 records about the ratification rule that went undelivered for three months.

### Investigation Tasks

- [ ] Decide whether anything can check this, or whether it is irreducibly a judgement. A length heuristic is trivially gameable and would punish a legitimate long summary attached to a file. Candidates worth weighing: a check that a message containing no file and no structured question is refused; counting invitation-shaped endings the way the retrospective's ask-hygiene pass already counts lazy questions; or accepting that only the two-kinds rule stated at the top of the working contract can carry it.
- [ ] Settle what happens to information that genuinely needs recording but not sending. Most status-report content belongs in a commit message or a ticket, where it is retrievable and costs nobody a screen. That is probably the whole answer to "but the reviewer found something interesting".
- [ ] Check whether this generalises to adopters. If the plugins' own agents narrate progress the same way, the fix belongs in shipped prose rather than only in this repository's working agreement.
- [ ] Reconcile against the ask-hygiene pass in the retrospective, which already counts one class of interaction defect. Adding a second counter there is cheaper than a new mechanism and puts both on the same cadence.

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)

## Related

- **P488** — batching artefacts the maintainer asked for one at a time, then asking permission for the batch. Same root: the agent optimising for its own convenience over the reader's window. Captured the same day.
- **P484** — the reading-context persona constraint, now documented on the `developer` persona: reads away from the repository, no filesystem access, attention divided. This ticket is that constraint being violated in the chat surface rather than in an artefact.
- **ADR-111** — ratified the shape a message must take when it wants a decision: summary, file, structured question. This ticket is the other half — what a message must not be when it wants nothing.
- **P350** — brief the substance before naming anything by identifier, because the reader cannot resolve one.
- **P085** — asking in prose where a structured question is needed.
- **`feedback_theory_of_mind_narrow_window`** — the session memory holding this correction. Written after the first occurrence, in context during the second, and insufficient to prevent it. Its failure is the argument for this ticket.

(captured via /wr-itil:capture-problem at the maintainer's request, immediately after the second identical correction.)
