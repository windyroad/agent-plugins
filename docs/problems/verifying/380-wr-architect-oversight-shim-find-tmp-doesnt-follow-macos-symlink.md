# Problem 380: wr-architect-mark-oversight-confirmed shim's find /tmp doesn't follow macOS /tmp → /private/tmp symlink

**Status**: Verification Pending
**Reported**: 2026-06-26

## Fix Released

Released 2026-06-27 in `@windyroad/{architect,jtbd,itil}` patches (release vehicle `.changeset/p380-oversight-shim-find-tmp-macos-symlink.md`). The `find` → `find -L` follow-symlink fix landed at 3 candidate-SID enumeration sites (architect + jtbd mark-oversight-confirmed shims + itil session-id.sh); 3 behavioural bats red→green. Transitioned Known Error → Verifying by the work-problems Step 6.5 post-release K→V enumerator (seeded release-vehicle resolved cleanly — the P389 seed-discipline working).

**Awaiting user verification** — confirm on macOS that the oversight-marker enumeration now resolves under the /tmp→/private/tmp symlink (markers written under candidate SIDs, not silently zero).
**Priority**: 3 (Medium) — Impact: 3 x Likelihood: 1 (deferred — re-rate at next /wr-itil:review-problems)
**Origin**: internal
**Effort**: M (deferred — re-rate at next /wr-itil:review-problems)
**JTBD**: JTBD-001
**Persona**: developer
**Release vehicle**: `.changeset/p380-oversight-shim-find-tmp-macos-symlink.md` (patch bump @windyroad/architect + @windyroad/jtbd + @windyroad/itil). Deterministic shell fix — ships within appetite, no R009 eval-floor hold. Transition Known Error → Verifying once the version PR releases.

## Description

The `wr-architect-mark-oversight-confirmed` shim (resolved via ADR-049 `$PATH` to `packages/architect/scripts/mark-oversight-confirmed.sh`) writes the substance-confirm evidence marker that the `architect-oversight-marker-discipline.sh` PreToolUse hook (P348 / ADR-066) reads to permit setting `human-oversight: confirmed` in an ADR frontmatter.

The marker is written under every recent candidate session SID enumerated from `/tmp/*-announced-*` files within a 24h mtime window per ADR-050 Option C. The enumeration uses:

```bash
find "$MARKER_DIR" -maxdepth 1 -name '*-announced-*' -mmin "-${WINDOW_MINS}" 2>/dev/null \
  | sed 's|.*/||; s/.*-announced-//'
```

On macOS, `/tmp` is a symlink to `/private/tmp`. The `find` invocation does NOT follow the symlink — it descends into `/tmp` itself, which on macOS yields zero traversal because the directory entry is a symlink without `-L` or trailing slash. The candidate enumeration silently returns empty. The shim then writes zero markers AND exits 0 (silent cold path per script comment: *"No candidate SID — cold path. Exit 0 so SKILL flows do not crash before any hook has fired this session."*).

Witnessed on 2026-06-25 mid-session during ADR-086 substance-confirm marker landing: `bash -x` trace showed `candidates=` empty; manual workaround was to enumerate via `find -L /tmp` (or `find /private/tmp`) and write markers under each candidate SID by hand.

Consequence: every macOS adopter's `wr-architect:capture-adr` / `wr-architect:create-adr` Step 5 substance-confirm marker write fails silently. The downstream hook then blocks the subsequent Edit/Write of `human-oversight: confirmed`, causing the SKILL flow to surface a misleading "you didn't run mark-oversight-confirmed" error when the shim DID run — it just enumerated nothing. The user has to either rerun the SKILL, write the marker manually, or get blocked indefinitely.

Same shim shape is used for the analogous `wr-jtbd-mark-oversight-confirmed` (P288 / ADR-068 mechanism); the same bug applies there if its script uses the same `find /tmp` enumeration. Sweep is in scope.

## Symptoms

(deferred to investigation)

## Workaround

(deferred to investigation)

## Impact Assessment

- **Who is affected**: (deferred to investigation)
- **Frequency**: (deferred to investigation)
- **Severity**: (deferred to investigation)
- **Analytics**: (deferred to investigation)

## Root Cause Analysis

**Confirmed (2026-06-27).** `find <dir> -maxdepth 1` runs in `find`'s default `-P` (never-follow-symlinks) mode. When the start-point `<dir>` is *itself* a symlink to a directory, `-P` mode does not descend it — `find` treats the symlink as a leaf and emits nothing inside it. On macOS the marker dir defaults to `/tmp`, a symlink to `/private/tmp`, so `find "$MARKER_DIR" -maxdepth 1 -name '*-announced-*'` returned zero rows and the candidate-SID enumeration was silently empty. Verified empirically on Darwin: `find linkdir -maxdepth 1 -name '*-announced-*'` → empty; `find -L linkdir ...` → finds the marker. The `-L` flag (follow symlinks) fixes it portably — no-op on Linux (real `/tmp`), resolves the symlink on macOS.

Note: `get_current_session_id` in `session-id.sh` uses a *shell glob* (`ls -t "${marker_dir}/${system}-announced-"*`), which the shell resolves through the symlink fine — so the single-SID discovery was unaffected. The bug bit only the `find`-based *multi-candidate* enumeration (`get_candidate_session_ids`, ADR-050 Option C) and the two inlined copies in the mark-oversight shims.

### Investigation Tasks

- [ ] Re-rate Priority and Effort at next /wr-itil:review-problems
- [x] Fix candidate: change `find "$MARKER_DIR" -maxdepth 1 ...` to `find -L "$MARKER_DIR" -maxdepth 1 ...` (follow-symlink flag) — **applied**. The `-L` flag is the canonical POSIX answer; works on Linux (no-op) AND macOS.
- [x] Sweep sibling shims for the same pattern. **Three sites fixed**: `packages/architect/scripts/mark-oversight-confirmed.sh`, `packages/jtbd/scripts/mark-oversight-confirmed.sh`, `packages/itil/hooks/lib/session-id.sh` (`get_candidate_session_ids`). The two mark-oversight scripts are NOT synced (independent inlined copies per ADR-002 self-containment); each edited directly. `session-id.sh` is itil-only. No shared canonical exists for these — confirmed no sync-script governs them.
- [x] Update the shim-wrapper template at `packages/shared/lib/shim-wrapper-template.sh` if the pattern appears there. **Not affected** — its `find` is `-type d` over `$CACHE_PARENT` (a real dir, not `/tmp`). `session-marker.sh` (the synced canonical) has no `find -announced-` enumeration. No template/synced-canonical change needed.
- [x] Behavioural bats fixture. **Added 3** — point `SESSION_MARKER_DIR` at a symlink to the marker dir (reproduces the macOS `/tmp` shape on any platform): `session-id.bats` (concurrent-marker enumeration), `architect-oversight-marker-discipline.bats` + `jtbd-oversight-marker-discipline.bats` (end-to-end marker write). Verified RED without `-L`, GREEN with it. The session-id fixture needs a *second* concurrent marker because `get_current_session_id`'s glob masks the bug for the primary SID.
- [ ] Sibling concern: when the shim cold-paths (no candidate SIDs), should it print a stderr diagnostic instead of silent exit 0? **Deferred — out of M scope.** Separate small enhancement; the silent exit no longer masks *this* bug now that enumeration works on macOS, but a VERBOSE/debug stderr advisory would still aid the genuine no-marker cold path (P368 territory). Re-rank at next /wr-itil:review-problems or fold into P368.
- [x] Create reproduction test — covered by the three behavioural fixtures above.

## Dependencies

- **Blocks**: every macOS adopter's smooth ADR substance-confirm flow until fixed
- **Blocked by**: (none)
- **Composes with**: P368 (sibling symptom — shim cannot discover SID when both fallback paths empty)

## Related

- **P368** (`docs/problems/open/368-wr-architect-mark-oversight-confirmed-cannot-discover-session-id-when-clause-empty-and-no-announce-markers.md`) — strongest hang-off candidate. Same shim, adjacent failure mode (no announce markers + no env-var). This ticket adds the macOS-specific failure mode where announce markers DO exist but `find` can't see them because of the symlink traversal bug. Could be folded as P368 Phase 2 OR kept distinct (different root cause: P368 is "no markers anywhere"; this is "markers exist but traversal misses them on macOS"). Review-problems should decide.
- **P348** (`docs/problems/verifying/348-iter-subprocesses-set-human-oversight-confirmed-marker-without-user-confirmation-event.md`) — the parent ADR-066 marker-discipline ticket the shim implements.
- **ADR-049** — bin/ on PATH (shim resolution).
- **ADR-050** — multi-SID candidate enumeration (the contract the shim implements).
- **ADR-066** — human-oversight marker.
- **ADR-080** — highest-version-wins shim-wrapper scaffold.
- `packages/architect/scripts/mark-oversight-confirmed.sh` — the buggy script.
- `packages/shared/lib/shim-wrapper-template.sh` — shim-wrapper template (may need same fix if it has the pattern).
- **Step 2b hang-off-check** result: short-circuit fired (>5 broad candidates on `wr-architect-mark-oversight-confirmed` / `oversight-marker` signals); subagent dispatch skipped per ADR-032 5th invocation pattern. P368 is the strongest semantic overlap; review-problems re-evaluation is the canonical absorb-vs-proceed surface.
- Captured via /wr-itil:capture-problem; expand at next investigation.
