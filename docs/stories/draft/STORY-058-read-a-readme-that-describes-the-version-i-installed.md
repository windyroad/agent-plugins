---
status: draft
story-id: read-a-readme-that-describes-the-version-i-installed
reported: 2026-08-09
decision-makers: [Tom Howard]
problems: [P152]
rfcs: [RFC-064]
jtbd: [JTBD-302, JTBD-101]
story-maps: [STORY-MAP-008]
estimated-effort: M
---

# STORY-058: Read a README that describes the version I installed

## User value (INVEST Valuable)

In order to act on a plugin's README without checking it against the source first, as a developer who has just installed one and wants to know what it does, I want the prose to describe the version I actually have — so the skills it names can be invoked, the hooks it describes are the ones that will fire, and reading it is enough.

## Acceptance criteria (INVEST Testable)

- [ ] A README describes the version it ships with. Every skill, agent and hook it names is present in that version's own manifest, and anything the version ships that the README omits is surfaced rather than left silent.
- [ ] Drift is caught before an adopter receives it, not after. A detector exists and runs today, but it is **advisory** — its exit code is always 0 by design, so a release carrying a drifted README is not stopped by anything. Whether that becomes load-bearing is P152's Phase 2 question and is settled there, not here; what this story requires is that the answer is not "nothing noticed".
- [ ] A renamed or split skill takes its README references with it. The instance on record is a skill invoked as a subcommand becoming its own command, leaving the README naming an invocation that no longer resolves.
- [ ] The reader can tell which version they are reading about. An adopter comparing a README against their installed version currently has no anchor in the prose to compare against.
- [ ] Behavioural test: a package whose README names a skill absent from its manifest is flagged, and one whose README matches is not. Both directions — a check that only fires one way trains people to ignore it.

## Notes

This story is the adopter-side face of P152, which records the asymmetry that produced it: this project has a pressure stack keeping *code* honest — architecture, jobs, risk, style and voice each have an agent enforcing conformance — and nothing applying the same pressure to whether a README still describes the package it ships with. P152 is rated Likelihood 5, almost certain, because prose drifts every time behaviour changes and nothing objects.

Its Phase 1 shipped the structure and a detector. The detector is deliberately advisory under the declarative-first pattern: emit the signal, watch whether it fires, escalate only on evidence. So the gap this story closes is not "nobody thought about it" — it is that the signal currently has no consequence, and an adopter still receives whatever the last release happened to contain.

The card this backs sits in **"Read what it claims"** on STORY-MAP-008 — the second step of the adopter's journey, straight after choosing what to install and before letting it write anything into their tree. It is the point where trust is either established or quietly spent.
