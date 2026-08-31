# Problem 468: architect-mark-reviewed misses a genuine PASS whose verdict line is a markdown heading rather than bold

**Status**: Known Error
**Reported**: 2026-07-26
**Priority**: 6 (Medium) — Impact: 2 × Likelihood: 3 — derived at capture from the description per Step 4a
**Origin**: internal
**Effort**: S — derived at capture per Step 4a
**WSJF**: 12 — (6 × 2.0) / 1 (Known Error multiplier applied 2026-08-31)
**JTBD**: JTBD-001
**Persona**: developer

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

Until the parser repair is released and installed, require the documented bold verdict heading from a fresh architect reviewer and close that same reviewer through the native completion transport. If the reviewer returns an H2, malformed, or conflicting verdict, stop and run a fresh review. Do not create review markers manually.

## Impact Assessment

- **Who is affected**: plugin-developer, on any session that writes a gated path after an architect review.
- **Frequency**: whenever the architect agent formats its verdict line as a heading rather than bold — agent-controlled and unpinned, so effectively arbitrary.
- **Severity**: Medium — costs round-trips and pushes the agent into hook internals; does not corrupt state, and the recovery is documented (if imprecise).
- **Analytics**: one observed instance 2026-07-26 (P438 iteration). Same class as P181 (verdict-grep fragile on an ISSUES FOUND substring, closed) and P400 / P418 (marker never fires on a SendMessage resume).

## Root Cause Analysis

`packages/architect/hooks/architect-mark-reviewed.sh` recognizes only the bold verdict form and searches the complete output for PASS before checking ISSUES FOUND. It therefore rejects a genuine H2 PASS and can approve conflicting output when any later bold PASS exists.

The separate wrong-session symptom is already repaired by the generated Codex completion transport. It records the parent session, checkout, reviewer role, and target at spawn time, then sends the completed reviewer output to the shared marker writer under that parent context. The existing caller-binding tests reject unmatched targets, non-architect targets, and stale target reuse. No identity broadening or gate recovery change is needed for this fix.

### Investigation Tasks

- [x] Confirm the matcher in the `architect-mark-reviewed` PostToolUse hook and whether it anchors on the bold form specifically. **Confirmed 2026-08-31:** it accepts only the bold form.
- [x] Decide the fix locus. **Decided 2026-08-31:** strictly parse canonical bold or H2 verdict lines in the shared marker writer and require one unambiguous verdict.
- [x] Trace the recovery and session-binding path. **Confirmed 2026-08-31:** the generated Codex completion transport already binds a completed reviewer to its parent session; the old candidate-SID marker workaround is obsolete and must not be restored.
- [x] Behavioural coverage per ADR-052: the focused Bats fixture drives the real hook with canonical H2, conflicting, malformed, quoted, narrative, and caller-bound completion payloads.

## Fix Strategy

RFC-089 and STORY-083 carry the repair. Replace the PASS-first whole-output grep with one strict stdlib parser that accepts the two canonical heading shapes only and writes markers only for one unambiguous PASS. Preserve the current Claude dispatcher, generated Codex completion transport, caller binding, hash pairing, and fail-closed behavior.

Source and extracted packed-candidate tests can establish release readiness, but they do not verify an installed session. P468 remains open as a Known Error until the package is released and the shipped hook is exercised through its supported completion path.

## Release evidence, 2026-08-31

- Parent correction `27c772111cba389e9af219fcebb90a1dadf68cb1` reproduced a fenced PASS example granting markers, then required one canonical verdict on the first nonblank line. Whole-output uniqueness includes NEEDS DIRECTION. The regression failed before the correction; 32 selected source checks and 16 extracted-candidate parser checks passed afterwards.
- Source CI [33398261385](https://github.com/windyroad/agent-plugins/actions/runs/33398261385) passed: 4,299 hook tests passed, two skipped, and all 31 agent-prose evaluations passed.
- Release PR [471](https://github.com/windyroad/agent-plugins/pull/471) merged as `f556363148d841074f2101f161519c4e833c7627`. Release workflow [33399599819](https://github.com/windyroad/agent-plugins/actions/runs/33399599819) succeeded; npm publishes `@windyroad/architect@0.22.2` as `latest`.
- The published tarball's parser and gate-helper bytes match the release checkout. All 22 parser and dispatcher checks passed against that tarball using the existing fixture's canonical package path and isolated environment. An initial dispatcher assertion failed when the temporary package path used macOS's `/var` alias; resolving that path restored the expected Node entrypoint behavior without changing package code.
- The separate PR-triggered CI [33398364163](https://github.com/windyroad/agent-plugins/actions/runs/33398364163) failed before starting any jobs. GitHub CLI reported a likely workflow-file issue; the cause is not established. This is not passing test evidence. Merge CI [33399599748](https://github.com/windyroad/agent-plugins/actions/runs/33399599748) is tracked separately.
- User-disabled hooks and live runtime configuration remain unchanged. No installed-session completion journey is verified; P468 remains Known Error and STORY-083 remains in progress. No further backlog iteration is started, as requested.

## Installed-session verification, 2026-09-01

- `@windyroad/architect@0.22.2` was installed at user scope and reported enabled from `/Users/tomhoward/.codex/plugins/cache/windyroad-architect-local/wr-architect/0.22.2`. Architect hook entries were enabled only as command-line overrides for isolated `codex exec --ephemeral` journeys; the user's persistent hook configuration was not changed.
- A negative Bash-write control without an architect review was denied and wrote no file, confirming that the installed PreToolUse gate was active on that supported path.
- In the positive journey, a fresh native `wr-architect:agent` completed with canonical `## Architecture Review: PASS`. The completion hook then logged that it could not resolve the parent transcript because no rollout existed for the parent thread. No parent review marker was written, the subsequent Bash write was denied, and `proof.txt` remained absent. The shipped completion journey therefore failed installed verification; P468 remains Known Error.
- A separate negative `apply_patch` control was allowed without any architect review, even with the architect hook entries enabled for the isolated invocation. This establishes an additional uncovered Codex edit path; the Bash denial result must not be generalized to all edit tools.

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


## Stories

| ID | Title | Status |
|----|-------|--------|
| STORY-083 | STORY-083: A canonical architect PASS unlocks the guarded edit | in-progress |
