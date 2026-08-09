---
status: draft
story-id: pick-up-a-captured-ticket-and-know-what-was-observed
reported: 2026-08-09
decision-makers: [Tom Howard]
problems: [P375]
rfcs: [RFC-066]
jtbd: [JTBD-006, JTBD-001]
story-maps: [STORY-MAP-011]
estimated-effort: M
---

# STORY-060: Pick up a captured ticket and know what was observed

## User value (INVEST Valuable)

In order to work a problem against evidence rather than against my own reconstruction of it, as whoever picks the ticket up — usually an agent with no memory of the session that wrote it — I want the capture to state what was observed, so the work starts from a finding instead of from an inference about one.

## Acceptance criteria (INVEST Testable)

- [ ] A captured ticket states what was observed. That is the evidence the problem is real, and it is not investigation — something was seen, which is why it was captured. A ticket that cannot name a symptom has recorded a hunch.
- [ ] Sections that genuinely need investigation are **absent, not stubbed**. A missing section reads as not yet done; `(deferred to investigation)` reads as done and empty, which is why 18 have survived — six since May, the oldest since 17 May.
- [ ] The rule holds for every capture, not only unattended ones. An interactive capture has a human in the session who can be asked; the ticket outlives the session either way, and the next reader has neither.
- [ ] The template stops contradicting itself. It refuses a deferral on the rating fields, naming that mechanism as the single largest source of this rot, and emits the same mechanism into six body fields twelve lines later.
- [ ] Capture stays cheap. This is not "investigate at capture" — it is the observation already in hand, on the same argument that made rating-at-capture affordable.
- [ ] Behavioural test: a capture whose description carries an observation produces a real Symptoms section and no placeholder anywhere; a capture with genuinely nothing to say about root cause omits that section rather than stubbing it.

## Notes

**The reader who suffers most is an agent.** A ticket is picked up long after the session that wrote it, and in this project that is usually an agent working the backlog — which is why the persona is the developer role as documented here, a developer using AI coding agents, with the agent inside that role rather than beside it.

That changes the severity of an empty Symptoms section. A human reading a bare title knows they do not know, and goes looking. An agent reading a bare title will reconstruct a plausible premise and proceed on it confidently — which is the same failure mode already recorded as capture flows writing unverified claims. The remedy for that one is testing claims against the tree; this is its precondition. A tested claim about a symptom nobody recorded is still a claim about the wrong thing.

That also makes this a correctness concern rather than a legibility one. The work gets done against an invented problem.

**It is not confined to the loop.** Every capture uses this template. An interactive capture merely hides the gap, because a human is still in the session to be asked; the ticket outlives that session and the next reader has neither the human nor the context.

The gap is structural, not stylistic. The prose in these tickets is fine. The body is a form with six fields filled in by a placeholder, and because every ticket carries it, the incompleteness is invisible by ubiquity. P298 is the shape: a genuinely useful title, then Symptoms reading `(deferred to investigation)`, an empty Workaround, and a Root Cause section holding only its own subheading.

The rule that decides which sections belong at capture is the maintainer's: **investigation does not need to happen at capture — capture needs enough to confirm the problem is real.** Symptoms is that confirmation. Workaround and root cause are the investigation, and belong to whoever does it.

This is the unfinished half of a fix already made. On 2026-06-24 the rating placeholders were removed from this same template, over a mid-fix correction when the deferral came back under another name — *"that's just another deferral."* The numbers were fixed; the prose was not.
