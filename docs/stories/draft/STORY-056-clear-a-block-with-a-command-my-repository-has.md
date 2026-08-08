---
status: draft
story-id: clear-a-block-with-a-command-my-repository-has
reported: 2026-08-09
decision-makers: [Tom Howard]
problems: [P435]
jtbd: [JTBD-303, JTBD-101]
story-maps: [STORY-MAP-008]
estimated-effort: M
---

# STORY-056: Clear a block with a command my repository actually has

## User value (INVEST Valuable)

In order to get past a guardrail without reverse-engineering what the plugin assumed about my project, as a developer whose repository is not shaped like the plugin author's, I want every block to name a remedy that exists here — so the way out is something I can run rather than something I have to translate.

## Acceptance criteria (INVEST Testable)

- [ ] A block names a remedy the adopter's repository can actually execute. The push gate currently tells the reader to run `npm run push:watch`, which exists only in the plugin author's repository — an adopter reads an instruction that cannot be followed and has to work out the intent from the hook source.
- [ ] Where the remedy depends on repository shape, the gate detects the shape rather than assuming it. A repository with no npm scripts, or a non-npm project entirely, gets a remedy that fits it.
- [ ] Where no remedy can be determined, the block says what condition must become true rather than naming a command that will not work. "Nothing to run here" is a better instruction than a wrong one.
- [ ] Behavioural test: a gate firing in a fixture repository with no matching script emits a remedy that references nothing absent from that fixture.

## Notes

The card this story backs sits in the `collide` activity of STORY-MAP-008 — the moment an adopter hits one of the plugin's rules. That is the point at which a guest that assumed your house looks like its own is most obvious, and most expensive.

P435 records both faces of the class: the push gate over-firing on non-npm repositories, and external-comms under-firing because its scope was written against one repository's surfaces. This story is the over-fire face — the one an adopter hits directly and cannot work around without reading the plugin's source.
