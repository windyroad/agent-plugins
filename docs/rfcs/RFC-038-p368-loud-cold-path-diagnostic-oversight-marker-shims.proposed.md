---
status: proposed
rfc-id: p368-loud-cold-path-diagnostic-oversight-marker-shims
reported: 2026-07-03
human-oversight: unconfirmed
decision-makers: [Tom Howard]
problems: [P368]
adrs: []
jtbd: []
stories: []
---

# RFC-038: Loud cold-path diagnostic for oversight-marker shims when no session-id is discoverable

**Status**: proposed
**Reported**: 2026-07-03
**Problems**: P368
**ADRs**: (none)
**JTBD**: (none)

## Summary

Replace the silent `exit 0` cold path in the two `mark-oversight-confirmed.sh` shims with a loud stderr diagnostic, so that when no candidate session-id is discoverable the caller understands *why* the subsequent oversight-marker-discipline hook denies the `human-oversight: confirmed` Edit — instead of the shim masquerading as success and producing a confusing deny loop.

## Driving problem trace

- **P368** (Known Error): the confirmed root cause (macOS `/tmp` → `/private/tmp` symlink defeating `find` without `-L`) was already fixed and released by P380. P380 explicitly deferred one residuum to P368 (P380 Investigation Task, "should it print a stderr diagnostic instead of silent exit 0? … fold into P368"): on the *genuine* cold path — no `CLAUDE_SESSION_ID` and no `*-announced-*` markers at all — the shim writes zero markers and `exit 0` silently; the `architect-oversight-marker-discipline.sh` / `jtbd-oversight-marker-discipline.sh` PreToolUse hook then denies the confirmed-marker Edit, pointing the agent back at the shim it already ran (P368 Description line 21: "creating a confusing loop"). This RFC implements P368 option (b): fail loudly.

## Scope

**In scope** — P368 option (b), the cold-path residuum P380 deferred here:

1. In `packages/architect/scripts/mark-oversight-confirmed.sh`, replace the cold-path line `[ -n "$candidates" ] || exit 0` with a branch that, when `$candidates` is empty, emits a clear multi-line stderr diagnostic naming: no candidate session-id was discoverable (CLAUDE_SESSION_ID empty AND no `*-announced-*` markers in `$MARKER_DIR` within the window), no oversight marker was written for the artefact path, and the remedy (the discipline hook will deny the confirmed-marker Edit until an announce marker exists — start a fresh session, or set `SESSION_MARKER_DIR` to a dir containing a `*-announced-<sid>` file, then re-run the shim). Cite P368.
2. Apply the identical class-fix to the unsynced sibling `packages/jtbd/scripts/mark-oversight-confirmed.sh` (P380 sweep-both-shims discipline; the two shims are intentionally-divergent per-package inlined copies per ADR-002, edited independently — no sync script governs them).
3. Update each script's header `# Exit codes:` block and inline `# No candidate SID — cold path.` comment so they no longer describe the cold path as a silent no-op (architect advisory).

**Preserved contract**: exit code stays `0`. The documented contract ("cold path exits 0 so SKILL flows do not crash before any hook has fired this session") protects `set -e` callers; the harm P368 documents is the *silence*, not the exit code. A loud stderr breaks the confusing loop without changing fail-open behaviour (architect + JTBD gates confirmed 2026-07-03).

**Out of scope** (YAGNI — the failure mode is closed by option b; these are speculative design axes P368 listed then downgraded to "now optional"):
- Option (a) caller-supplies-SID via stdin/env — larger surface, no witnessed need.
- Option (c) session-agnostic path-hash-only marker — re-architects the marker protection mechanism; not warranted.
- `session-id.sh::get_candidate_session_ids` (library layer) — returning empty is correct library behaviour; the diagnostic belongs at the shim (application) layer.

## Tasks

- [ ] Add a behavioural bats cold-path test to `packages/architect/hooks/test/architect-oversight-marker-discipline.bats`: empty marker dir + `CLAUDE_SESSION_ID` unset → shim exit 0, no `oversight-confirmed-*` file written, stderr contains the diagnostic (RED before the fix, GREEN after; ADR-052 behavioural).
- [ ] Add the mirror cold-path test to `packages/jtbd/hooks/test/jtbd-oversight-marker-discipline.bats`.
- [ ] Apply the cold-path diagnostic in `packages/architect/scripts/mark-oversight-confirmed.sh` + update its header/inline comments.
- [ ] Apply the identical diagnostic in `packages/jtbd/scripts/mark-oversight-confirmed.sh` + update its header/inline comments.
- [ ] Run both bats files green.
- [ ] Changeset: patch bump `@windyroad/architect` + `@windyroad/jtbd` (shippable hook/script change).
- [ ] Transition P368 Known Error → Verification Pending with a `## Fix Released` section.

## Commits

(maintained automatically — populated by the commit-message RFC trailer hook per ADR-060 Phase 1 item 12)

## Related

- **P368** — driving Known Error (`docs/problems/known-error/368-...md`).
- **P380** — sibling; fixed the macOS symlink `find` half, deferred this cold-path diagnostic here.
- **ADR-066 / ADR-068** — human-oversight marker mechanism the shims implement.
- **ADR-050** — multi-SID candidate enumeration.
- **ADR-002** — plugin self-containment (why the two shims are unsynced independent copies).
- **ADR-052** — behavioural-tests default.
- Captured via /wr-itil:capture-rfc (fix-time, I13 ADR-072/073); expand at next /wr-itil:manage-rfc invocation.
