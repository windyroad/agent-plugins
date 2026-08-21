# Problem 506: Staleness-check never asks the registry, so a months-behind install reports as current forever

**Status**: Known Error
**Reported**: 2026-08-20
**Priority**: 20 (Very High) — Impact: 4 × Likelihood: 5 — derived at capture. Impact 4: installed plugins degrade the workflow exactly as the band describes — skills load, but they load a retired contract, so the agent follows months-old instructions and emits artefacts in formats the project abandoned. The adopter has no signal that anything is wrong; the output looks deliberate. Likelihood 5: all three of the band's triggers hold at once — known gap, no control in place, and a previously observed failure (below).
**Origin**: internal
**Effort**: L — derived at capture. The predicate change itself is small, but it lands in `packages/shared/hooks/staleness-check.sh` and syncs to six consumer plugins, and it reverses a ratified network-free design premise (RFC-036 / ADR-088), so it needs an ADR-class decision on whether a per-turn hook may touch the network at all — and if not, where else the currency check lives. Sized above the mechanical edit because the design question is the work.
**WSJF**: 10 — (20 × 2.0) / 4 (2026-08-21 review: auto-transitioned Open → Known Error — root cause confirmed + workaround documented; Known Error multiplier 2.0)
**JTBD**: JTBD-302
**Persona**: plugin-user

## Description

`staleness-check.sh` compares the version of the plugin *this session* loaded against the highest version already present *on disk*. Both operands are local. Nothing on the machine ever asks npm what `latest` is, so a marketplace clone or install cache that has fallen behind the registry is indistinguishable from one that is current — and stays that way indefinitely, because no amount of restarting changes either operand.

The hook is not silent while this happens. It prints, reassuringly:

```
wr-itil: this session is on 0.59.0, 0.59.2 installed — restart to pick it up
```

which reads as "you are one patch behind" while the true gap was **0.59.2 vs 1.1.1**.

### Observed 2026-08-20

- `~/.claude/plugins/marketplaces/windyroad` was pinned at commit `c8f5db4`, carrying `wr-itil` 0.59.2 — 989 commits behind `origin/main`.
- The separate install cache `~/.claude/plugins/cache/windyroad/wr-itil/` held only 0.59.0.
- `npm view @windyroad/itil version` returned **1.1.1**.
- Every project on the machine was therefore running skills roughly forty releases old, with no signal anywhere.

**Adopter blast radius.** The `../addressr` repo, on that stale install, produced `docs/story-maps/draft/STORY-MAP-001-convert-source-inspection-pins-to-behavioural-tests.html` in the retired pre-renderer format: hand-rolled HTML with an embedded `<style>` block, a `<meta name="adrs">` tag, a "Story-map purpose paragraph" placeholder, a single rib placeholder under `--cols: 3`, and a backbone of techniques rather than a journey.

That artefact is not a malfunction. It is faithfully what 0.59.2's `capture-story-map` SKILL.md prescribes — the placeholder paragraph is verbatim from its line 145, and the one-rib shape from its line 211. Current 1.1.1 prescribes a JSON data island plus `wr-itil-render-story-map`, and forbids every one of those elements by name. The maintainer's reaction on discovering it was to assume the plugin was producing rubbish; the plugin was fine, and a three-month-old copy of it was running.

This is precisely the failure JTBD-302's persona constraint names — *"an agent reading a stale README expands stale prose into context and acts on out-of-date instructions"* — with SKILL.md in the README's place, where the consequence is generated artefacts rather than a misread contract.

## Symptoms

- The version nudge reports a small session-vs-disk gap while the disk-vs-registry gap is arbitrarily large.
- Generated artefacts silently conform to a retired format; nothing flags the format as retired.
- `claude plugin install` is a no-op when any version is present (P106), so the ordinary install path cannot self-heal the gap it cannot see.
- The gap survives restarts, since restarting only re-reads the same stale disk.

## Workaround

`claude plugin marketplace update <name>`, then confirm on disk against the registry:

```bash
for d in ~/.claude/plugins/cache/windyroad/*/; do
  p=$(basename "$d"); v=$(ls "$d" | sort -V | tail -1)
  echo "$p installed=$v npm=$(npm view "@windyroad/${p#wr-}" version 2>/dev/null)"
done
```

Manual, uncadenced, and nobody runs it — which is the whole complaint (see `feedback_automatic_cadence_or_it_doesnt_happen`).

## Impact Assessment

- **Who is affected**: every adopter on a machine whose marketplace clone has drifted, across every project on it — the install cache is global (P299). Maintainers dogfooding are hit identically, and were.
- **Frequency**: continuous once drift starts. Drift is unbounded and has no self-correcting pressure.
- **Severity**: silent wrong output. Worse than a hard failure, because the artefact looks intentional and gets committed, ratified, and built upon.
- **Analytics**: none. There is no telemetry on installed-version currency; the 989-commit gap was found by hand while diagnosing an unrelated complaint.

## Root Cause Analysis

`packages/shared/hooks/staleness-check.sh` lines 55-56 compare `$SELF_VERSION` (the version whose script path is executing) against `$HIGHEST` (the highest semver-named local cache directory). Both are local by construction. The hook has no third operand and no notion of an upstream.

This is not an oversight — it is the ratified design. P045's Landing paragraph specifies "the network-free class-B surfacer shape", and the code implements exactly that. So the fix is a **design reversal**, not a patch, and it carries its own questions:

- May a per-turn hook touch the network at all? Latency and offline behaviour both bite.
- If not the hook, what surface owns the currency check, and on what self-firing cadence?
- Fail-open or fail-closed when the registry is unreachable or rate-limits?
- Which upstream is authoritative — the npm registry, or the marketplace clone's own remote? They can disagree, and did.

### Investigation Tasks

- [ ] Decide whether the currency axis belongs in the per-turn hook or on a separate cadenced surface; capture the outcome as an ADR, since it reverses RFC-036 / ADR-088's network-free premise
- [ ] Settle offline / rate-limit / timeout semantics before any network call ships in a per-turn hook
- [ ] Determine whether npm or the marketplace clone's remote is authoritative when the two disagree
- [ ] Apply the fix to the `packages/shared` canonical and run its sync script — never a consumer copy (`feedback_edit_canonical_synced_hook_not_consumer_copy`)
- [ ] Write a behavioural test that fails when a simulated months-behind install reports as current
- [ ] Check whether the same blind comparison exists in the architect / jtbd / risk-scorer / voice-tone / style-guide / tdd consumer copies after sync

## Dependencies

- **Blocks**: (none)
- **Blocked by**: the ADR-class decision above — the fix locus is not determined until it lands
- **Composes with**: P045, P410, P343

## Related

Captured via `/wr-itil:capture-problem`. Hang-off arbitration returned `PROCEED_NEW` over four candidates; each sits on a different axis and none absorbs this scope:

- **P045** (`docs/problems/open/045-auto-plugin-install-after-governance-release.md`) — shipped the very surfacer this ticket reports a gap in, under RFC-036 / ADR-088, and owns the fix-locus file. It is **not** the parent, because its network-free shape is the ratified premise this ticket challenges, and registry currency appears nowhere in its closure criteria. Folding this in would silently reverse P045's own design decision inside a ticket that never asked the question. The next `/wr-itil:review-problems` cluster pass should decide whether the two merge once the ADR settles.
- **P343** (`docs/problems/verifying/343-...md`) — PATH resolution order among versions already on disk. ADR-080's highest-version-wins wrapper resolves correctly here; it just resolves to a version 989 commits behind.
- **P410** (`docs/problems/open/410-...md`) — the inverse: too many old versions retained. This ticket is about the newest never arriving.
- **P115** (`docs/problems/parked/115-...md`) — worktree discovery reachability, parked on user direction. No worktree is involved in the observed drift.
- **P106** — `claude plugin install` is a silent no-op when any version is present, so the ordinary install path cannot close a gap it cannot detect. Compounds this ticket rather than duplicating it.
- **JTBD-302** (`docs/jtbd/plugin-user/JTBD-302-trust-readme-describes-installed-behaviour.proposed.md`) — the anchoring job. Its persona constraint about an agent expanding stale prose and acting on out-of-date instructions is the observed mechanism, one artefact class over.
