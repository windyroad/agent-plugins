# Problem 468: architect-mark-reviewed misses a genuine PASS whose verdict line is a markdown heading rather than bold

**Status**: Open
**Reported**: 2026-07-26
**Priority**: 6 (Medium) — Impact: 2 × Likelihood: 3 — derived at capture from the description per Step 4a
**Origin**: internal
**Effort**: S — derived at capture per Step 4a
**JTBD**: JTBD-101
**Persona**: plugin-developer

## Description

A genuine architect PASS does not fire the `architect-mark-reviewed` PostToolUse marker hook when the agent's output leads with a markdown H2 heading (`## Architecture Review: PASS`) instead of the bold form (`**Architecture Review: PASS**`) the hook matches on.

Witnessed 2026-07-26 in the P438 AFK iteration. A **fresh** `wr-architect:agent` spawn — not a `SendMessage` resume, so not the P400 path — returned an unambiguous PASS verdict. The subsequent Write to `docs/rfcs/RFC-052-portable-rule-routes-free-text-collection-to-copyable-blocks.proposed.md` was denied with *"No architect review marker found for this session"*. The agent fell back to the deny message's own manual-assertion recovery (`touch /tmp/architect-reviewed-$SID && rm -f /tmp/architect-reviewed-$SID.hash`), and even that took two attempts: the deny message instructs deriving the SID from the newest `architect-plan-reviewed-*` / `architect-announced-*` basename, but the SID the gate actually reads comes from the Write's stdin payload, which matched a *different* UUID recorded in `/tmp/itil-runtime-sid-<user>-<n>.current`. The first assertion landed under the announce-marker UUID and the Write re-blocked.

Cost in that iteration: one wasted Write round-trip, two Bash probes into hook internals (`architect-enforce-edit.sh`, `lib/architect-gate.sh`), and a marker asserted under two candidate SIDs to be sure of a hit.

The matcher is brittle against a formatting variation the agent itself controls, and neither `packages/architect/agents/agent.md` nor the hook pins the expected verdict-line form. The recovery directive in `lib/architect-gate.sh` is also under-specified on SID derivation.

## Symptoms

- A fresh architect spawn returns PASS; the next gated Write is still denied with "No architect review marker found for this session".
- The deny message's own recovery recipe can fail on first application because the SID it names (announce-marker basename) is not necessarily the SID the gate reads (the runtime stdin `session_id`).
- **2026-07-26 (P417 iter) — the SID half of this ticket reproduces with a correctly-formatted verdict, so it is an independent defect from the heading-vs-bold half.** A fresh `wr-architect:agent` spawn returned `**Architecture Review: PASS**` in exactly the bold form the hook matches, and the next Edit to `docs/rfcs/README.md` was still denied with *"No architect review marker found for this session"*. `ls -lt /tmp/architect-*` showed the hook HAD fired — `/tmp/architect-reviewed-2f4ccb8f-…` was written at the moment the review returned, complete with its `.hash` sibling — while every `*-announced-*` marker for the session carried `b42604df-…`. The marker landed under the **subagent's** session id, not the session whose Write the gate was evaluating. Recovery took asserting under both UUIDs (`touch` each + `rm -f` each `.hash`), matching this ticket's existing candidate-set workaround. Two consequences worth separating in the fix: the verdict-format matcher and the SID resolution fail independently, and re-spawning the reviewer cannot help — a second PASS lands under a second wrong UUID. Sibling to P368 (marker shims cannot discover the session id) and P260 / ADR-050 Option C (the create-gate's candidate-set answer to the same class).

## Workaround

Assert the marker under **every** recent candidate SID rather than the single newest announce-marker basename — read `/tmp/itil-runtime-sid-*.current` for the runtime values and `touch /tmp/architect-reviewed-<sid>` plus `rm -f` its `.hash` sibling for each. Same candidate-set discipline the create-gate marker already uses per ADR-050 Option C.

## Impact Assessment

- **Who is affected**: plugin-developer, on any session that writes a gated path after an architect review.
- **Frequency**: whenever the architect agent formats its verdict line as a heading rather than bold — agent-controlled and unpinned, so effectively arbitrary.
- **Severity**: Medium — costs round-trips and pushes the agent into hook internals; does not corrupt state, and the recovery is documented (if imprecise).
- **Analytics**: one observed instance 2026-07-26 (P438 iteration). Same class as P181 (verdict-grep fragile on an ISSUES FOUND substring, closed) and P400 / P418 (marker never fires on a SendMessage resume).

## Root Cause Analysis

### Investigation Tasks

- [ ] Confirm the matcher in the `architect-mark-reviewed` PostToolUse hook and whether it anchors on the bold form specifically.
- [ ] Decide the fix locus: loosen the matcher to accept any leading-line form of `Architecture Review: PASS`, or pin the verdict-line format in `packages/architect/agents/agent.md` so the agent cannot vary it — or both.
- [ ] Correct the recovery directive in `packages/architect/hooks/lib/architect-gate.sh` to name the runtime-SID source, not the announce-marker basename.
- [ ] Behavioural coverage per ADR-052: a bats fixture feeding the hook a heading-form PASS and asserting the marker is written.

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)
- **Composes with**: P353 (hash-marker brittleness umbrella), P400 / P418 (the SendMessage-resume miss), P181 (closed — the verdict-grep fragility precedent).

## Related

(captured via /wr-itil:capture-problem.)

Hang-off pre-filter returned 6 candidates, above the 5-candidate cap, so the `wr-itil:hang-off-check` subagent dispatch was skipped per the capture-problem sub-step 2b short-circuit. Candidate list recorded here for re-evaluation at the next `/wr-itil:review-problems` clustering pass:

- `docs/problems/verifying/400-architect-mark-reviewed-posttooluse-never-fires-on-sendmessage-resume.md` — same hook, same silent-miss class, different trigger. The strongest hang-off candidate; a reviewer may prefer folding this in as a second trigger on that ticket if P400 reopens.
- `docs/problems/open/418-reviewer-agent-marker-hooks-do-not-fire-on-sendmessage-resumed-agents.md` — the generalised reviewer-agent form of P400.
- `docs/problems/verifying/353-hash-marker-brittleness-class-external-comms-gate-highest-friction-surface-umbrella.md` — the marker-brittleness umbrella.
- `docs/problems/verifying/313-pre-edit-governance-gate-review-catch-22-pass-withheld-pending-edits.md`
- `docs/problems/verifying/144-p119-hook-deny-no-documented-recovery-agent-attempts-bypass.md` — the under-specified recovery directive here is an instance of that class.
- `docs/problems/verifying/096-pretooluse-posttooluse-hook-injection-volume-unaudited.md`

Also related but not in the prefilter set: `docs/problems/closed/181-architect-mark-reviewed-verdict-grep-fragile-on-issues-found-substring.md` — the same verdict-grep fragility, fixed for the ISSUES FOUND substring case; this is the PASS-side recurrence.
