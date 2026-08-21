# Problem 469: style-guide and voice-tone reviewer agents spawn without Bash, so they cannot write the verdict marker their own gate reads

**Status**: Open
**Reported**: 2026-07-26
**Priority**: 6 (Medium) — Impact: 2 × Likelihood: 3 — derived at capture from the description per Step 4a
**Origin**: internal
**Effort**: S — derived at capture per Step 4a
**WSJF**: 6 — (6 × 1.0) / 1 (added 2026-08-21 review)
**JTBD**: JTBD-101
**Persona**: plugin-developer

## Description

The `wr-style-guide:agent` and `wr-voice-tone:agent` reviewers are spawned with a read-only tool surface (Read, Glob, Grep — no Bash and no Write). Their gate contract expects them to record a verdict at `/tmp/style-guide-verdict` and `/tmp/voice-tone-verdict`, and they cannot: both agents said so unprompted at the end of their reviews during the P438 AFK iteration on 2026-07-26.

Style-guide, verbatim: *"Verdict file not written. I was given only Read, Glob and Grep in this invocation — no Bash or Write — so I could not execute `printf 'PASS' > /tmp/style-guide-verdict`. The calling agent will need to write PASS to /tmp/style-guide-verdict on my behalf, or re-invoke me with Bash access if the marker hook requires the file to be written by this agent."*

Voice-tone, verbatim: *"I have no execution tool in this thread (Read / Glob / Grep only), so I could not run `printf 'FAIL' > /tmp/voice-tone-verdict`. The launching agent needs to write that verdict file itself, or re-run me with Bash available, otherwise the gate will read a stale or absent marker."*

The failure is quiet in the common case. If the gate falls back to a PostToolUse mark-hook keyed on the agent's returned text, the verdict file is redundant and the agents' warnings are noise; if the gate genuinely reads the file, then a **stale marker from a previous review governs the next write** — a PASS left over from an earlier artefact silently authorises an unreviewed one, which is the hollow-marker class. Either way the contract and the tool surface disagree, and the agent is left telling the caller to forge its verdict — which would defeat the point of an independent reviewer.

Two possible resolutions, both cheap: grant the reviewers Bash (or a narrow write affordance) so they can record their own verdicts, or strike the verdict-file instruction from the agent definitions if the mark-hook is the real mechanism. Determining which is the actual live path is the first investigation task.

## Symptoms

- `wr-style-guide:agent` and `wr-voice-tone:agent` end their reviews reporting that they could not write their verdict file and asking the caller to write it for them.
- Neither agent can distinguish "the gate does not need the file" from "the gate will read a stale one".
- **(Evidence 2026-07-26, P424 iter — scope is wider than the title says.)** Three distinct reviewers hit this in one iteration, and one is outside the ticket's current title: `wr-style-guide:agent` ("I have no Bash tool in this session... Please run `printf 'PASS' > /tmp/style-guide-verdict` on my behalf"), `wr-voice-tone:agent` on all three of its rounds ("this thread has Read, Glob and Grep only, with no write or shell tool"), and `accessibility-agents:accessibility-lead`, whose report likewise carried no verdict-file write. The `wr-architect:agent` and `wr-jtbd:agent` reviewers did NOT hit it — the jtbd agent's toolset includes Bash and it wrote `/tmp/jtbd-verdict` successfully. So the split is per-agent toolset, and the fix should be derived from the agent frontmatter `tools:` lists rather than patched per named agent. Notably the gates still passed: the `.html` write succeeded after the voice-tone PASS, so the PostToolUse output-grep path is what actually writes the marker and the verdict file the agents are asking for is either vestigial or a second, unused mechanism. Worth settling which, because right now every affected review ends by asking the caller to perform a write that may do nothing.

## Workaround

Treat the agent's returned verdict text as the authority and check the gate's actual behaviour on the next gated write. Do not have the calling agent forge the verdict file on the reviewer's behalf — a caller-written verdict is not an independent review, and if the file is load-bearing that forgery is exactly the hollow-marker defect P348 names.

## Impact Assessment

- **Who is affected**: plugin-developer, on any session that edits a `.css` or UI-component path (style-guide gate) or `.html` / user-facing copy (voice-tone gate).
- **Frequency**: every invocation of either reviewer — the tool surface is fixed by the agent definition, so this is not intermittent.
- **Severity**: Medium — a stale-marker read would be a governance hole rather than a break; if the file is inert, the cost is confusion plus the agents' closing warnings on every review.
- **Analytics**: both agents reported it independently in the same iteration, 2026-07-26 (P438 fix-vehicle authoring).

## Root Cause Analysis

### Investigation Tasks

- [ ] Determine which mechanism is live for each gate: a PostToolUse mark-hook keyed on the agent's returned text, or a verdict file read from `/tmp`. Check `style-guide-enforce-edit.sh` and `voice-tone-enforce-edit.sh` plus their mark-hook siblings.
- [ ] If the verdict file is load-bearing: grant the two agents the affordance to write it, and check whether a stale verdict from a prior review can authorise a later unreviewed write.
- [ ] If the verdict file is inert: strike the instruction from `packages/style-guide/agents/*.md` and `packages/voice-tone/agents/*.md` so the reviewers stop asking callers to forge verdicts.
- [ ] Audit the sibling reviewers (architect, jtbd, risk-scorer, tdd) for the same contract-versus-tool-surface mismatch.
- [ ] Behavioural coverage per ADR-052 for whichever mechanism is retained.

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)
- **Composes with**: P353 (hash-marker brittleness umbrella), P348 (hollow oversight markers — a stale verdict authorising an unreviewed write is that class), P468 (the architect-side marker miss observed in the same iteration).

## Related

(captured via /wr-itil:capture-problem.)

Hang-off pre-filter matched on the marker-and-verdict signal set; the strongest candidate was `docs/problems/verifying/353-hash-marker-brittleness-class-external-comms-gate-highest-friction-surface-umbrella.md`, which is an umbrella for marker *hashing* brittleness rather than for a reviewer that cannot write its marker at all. Captured separately because the fix locus is the agent definitions' tool surface, not the marker-key derivation. Re-evaluate the clustering at the next `/wr-itil:review-problems` pass.
