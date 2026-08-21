# Problem 506: Staleness-check never asks the registry, so a months-behind install reports as current forever

**Status**: Known Error
**Reported**: 2026-08-20
**Priority**: 20 (Very High) — Impact: 4 × Likelihood: 5 — derived at capture. Impact 4: installed plugins degrade the workflow exactly as the band describes — skills load, but they load a retired contract, so the agent follows months-old instructions and emits artefacts in formats the project abandoned. The adopter has no signal that anything is wrong; the output looks deliberate. Likelihood 5: all three of the band's triggers hold at once — known gap, no control in place, and a previously observed failure (below).
**Origin**: internal
**Effort**: M — re-rated 2026-08-21 (was L). The L rationale was "the design question is the work", and that question is now framed: ADR-120 records five options with evidence, and the recommended one is network-free, so the two sub-questions that made it expensive (may a per-turn hook touch the network; what are the offline / rate-limit / timeout semantics) are dissolved rather than answered. Remaining marginal work is one canonical edit to `packages/shared/hooks/staleness-check.sh`, a mechanical fan-out via `scripts/sync-staleness-check.sh` to seven consumers, behavioural bats (consumer test files are not synced and each needs separate work), a threshold config key per ADR-098, and a changeset naming the bumping plugins.
**WSJF**: 20 — (20 × 2.0) / 2 (2026-08-21: effort re-rated L → M once the design question was framed; Known Error multiplier 2.0. Severity unchanged at 20 — the Impact 4 rationale rests on observed adopter blast radius, not on any inference about this project's product line, so the P466 check passes.)
**Held**: implementation is held pending ratification of ADR-120 (ADR-074 substance-confirm-before-build). The ticket stays Known Error rather than Parked — a Severity-20 silent-wrong-output defect should remain visible in the ranked queue — but an AFK iteration selecting it will correctly hold again until the decision is confirmed.
**JTBD**: JTBD-007
**Persona**: developer

> **Re-anchored 2026-08-21** by `wr-jtbd:agent` review, doc-only. The capture-time header (`JTBD-302` / `plugin-user`) was an AFK auto-capture default. JTBD-302's contract — that a README describes the version you just installed — was **never breached** in the observed incident: 0.59.2's SKILL.md accurately described 0.59.2, and the artefact was faithful to it. None of JTBD-302's desired outcomes covers installed-version-vs-upstream currency. JTBD-007 (keep plugins current across projects) owns the fix locus outright; its desired outcome *"the refresh mechanism actually fetches the latest marketplace version"* is the breached clause, and the `developer` persona's pain point names the defect verbatim. JTBD-302 is retained below as a composes-with on the mechanism axis.

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

The **mechanism** here is the one JTBD-302's persona constraint names — *"an agent reading a stale README expands stale prose into context and acts on out-of-date instructions"* — with SKILL.md in the README's place, and generated artefacts rather than a misread contract as the consequence. That is a shared mechanism, not a breached contract: JTBD-302 promises the prose matches *the version you installed*, and here it did. The breached job is JTBD-007 (see the header re-anchor note).

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

This is not an oversight — it is the ratified design. P045's Landing paragraph specifies "the network-free class-B surfacer shape", and the code implements exactly that.

### Correction 2026-08-21 — the "design reversal" premise was wrong

This ticket was captured asserting that the fix is a **design reversal**, and that every currency signal is blocked behind reversing ADR-088's network-free premise. Investigation this iteration falsifies that on three counts:

1. **ADR-088 already retains the axis.** Its Considered Option 5 (npm-registry check) was rejected *as core* and explicitly "retained as an opt-in secondary axis". Building a currency axis is therefore *inside* what ADR-088 ratified, not a reversal of it. The ticket's claim that the fix locus is undetermined until a reversal lands overstated the block.
2. **The vehicle ADR-088 names is unavailable.** Its Reassessment Criteria says *"If the secondary cache-vs-npm network axis is built, it lands as an amendment here."* That instruction predates **ADR-116** (ratified decisions change only by supersession), which forbids amendment sections on any decision carrying `human-oversight: confirmed`. ADR-088 line 73 is stale instruction, not live authority — so the substance lands in a **new** decision, **ADR-120**, which carries no `supersedes:` claim because ADR-088's core is unchanged.
3. **A network-free option exists that nobody had considered.** The marketplace clone at `~/.claude/plugins/marketplaces/<name>` is a git clone, so its HEAD commit date is **local** information. `git -C <clone> log -1 --format=%ct HEAD` returns clone age with zero network calls. Probed 2026-08-21 on the maintainer's machine: `ui-ux-pro-max-skill` 164 days, `openai-codex` 124, `community-access` 85, `windyroad` 0 — the signal discriminates. The 2026-08-20 clone was roughly three months old, so any threshold at or below 90 days would have caught it. (Evidence limits: n=1 machine, one point in time, four clones; the counterfactual is threshold-conditional and no threshold is chosen yet.)

Consequence: two of the four open questions below are **dissolved rather than answered** by the recommended option, which is why effort re-rated L → M. The questions are not deleted — they remain live for Options B, C and D in ADR-120.

**Known weakness of the network-free option, recorded so ratification sees it:** clone HEAD date is a proxy for currency, not currency. A marketplace whose upstream genuinely has not moved in 100 days reads as 100 days stale while being perfectly current. That false-positive class does not exist in the network-bearing options.

### Open questions (now carried by ADR-120, not by this ticket)

- May a per-turn hook touch the network at all? Latency and offline behaviour both bite. — *Recommended option makes this not arise.*
- If not the hook, what surface owns the currency check, and on what self-firing cadence? — *Options A and C compose; they are not rivals.*
- Fail-open or fail-closed when the registry is unreachable or rate-limits? — *Fail-open is already ratified in ADR-088 and ADR-013 Rule 6; only relevant to Options B/C/D.*
- Which upstream is authoritative — the npm registry, or the marketplace clone's own remote? They can disagree, and did. — *Option D answers "the marketplace remote" and was added to the option set precisely so this is decided rather than resolved by omission.*

### Investigation Tasks

- [x] **Decide whether the currency axis belongs in the per-turn hook or on a separate cadenced surface; capture the outcome as an ADR** — options captured in **ADR-120** (2026-08-21). The ADR is drafted, **not ratified**; the choice itself is the outstanding question. It does not reverse ADR-088 (see the correction above), so it carries no `supersedes:` claim.
- [x] **Determine whether npm or the marketplace clone's remote is authoritative when the two disagree** — surfaced as an explicit answer-bearing option rather than settled unilaterally: Option A makes it not arise, Options B/C answer "npm", Option D answers "the marketplace remote". Carried into the ratification answer set per ADR-111.
- [x] **Check whether the same blind comparison exists in the consumer copies** — **yes, in all seven, byte-identically.** Verified 2026-08-21 by md5 across `packages/{shared,architect,itil,jtbd,risk-scorer,style-guide,tdd,voice-tone}/hooks/staleness-check.sh`: all eight files hash to `51411aace3203dfeb77cb0a4db4fd791`. The sync discipline is healthy, so one canonical edit plus `scripts/sync-staleness-check.sh` fixes all seven. Note that `scripts/sync-staleness-check.sh` records `connect`, `retrospective`, `c4`, `wardley` and `agent-plugins` as a deferred RFC-036 task — whether the currency axis reaches them is ADR-120 open sub-decision 4.
- [ ] **Ratify ADR-120** — blocking. Answer set is Options A–E plus the 30-day threshold default; per ADR-068 lockstep the `developer` persona connectivity-constraint amendment and the JTBD-007 detection-axis outcome ratify in the **same** event.
- [ ] Settle offline / rate-limit / timeout semantics — **only if** ratification picks Option B, C or D. Option A does not need them.
- [ ] Apply the fix to the `packages/shared` canonical and run its sync script — never a consumer copy (`feedback_edit_canonical_synced_hook_not_consumer_copy`)
- [ ] Write a behavioural test that fails when a simulated months-behind install reports as current. Guard the search roots — a `run grep` over a missing dir asserts nothing and passes vacuously; prove RED by injecting a stale clone before trusting GREEN. Assert the **combined** emission path against ADR-038's byte budget, not each line separately. Consumer test `.bats` files are **not** synced and each needs separate work.
- [ ] Implement the once-per-session read of the clone HEAD date. This is a **clause of ADR-120, not an optimisation**: without it the worst-case aggregate is ~105 ms per turn for a maintainer with seven plugins, which breaks the "stat + one compare, near-zero" premise ADR-088's per-plugin-retention argument rests on.
- [ ] Wire the clone-age threshold as an ADR-098 config key in `~/.claude/cruise.config.json` with a stated default — **not** a constant buried in the hook (P444; ADR-091 is the precedent for deriving rather than hardcoding a threshold).

## Fix Strategy

**No approach is pinned.** The candidate approaches are recorded as the five considered options of **ADR-120** (`docs/decisions/120-plugin-currency-is-detected-from-the-local-marketplace-clone-not-the-registry.proposed.md`), which is born `human-oversight: unconfirmed`. Naming a chosen approach here would be the propose-fix act, and the approach is exactly what is unratified — so this section deliberately records the option set and its recommendation rather than a decision.

Per **ADR-119**, once ADR-120 ratifies the implementation is proposed as a **release row**, never as an RFC document. No `docs/rfcs/RFC-*.md` is to be created for this ticket; the `wr-itil-check-fix-rfc-trace` predicate's `no-rfc-trace` directive and the I13 gate's ADR-073 auto-create text are known stale-line debt (P508) superseded by ADR-119, and were deliberately not followed.

Implementation is held under the **ADR-074 / P315 substance-confirm-before-build guard**: a fix must not be built on a decision whose substance is unconfirmed, because a born-proposed decision the maintainer later rejects produces rework (the P314 shape). The guard sits *before* the I13 RFC-trace gate in `manage-problem` SKILL.md, so it short-circuits first — fix-time is never reached.

## Dependencies

- **Blocks**: (none)
- **Blocked by**: ratification of **ADR-120**. Note this is narrower than the original capture-time claim that *every* currency signal is blocked: ADR-088 already retains an opt-in secondary registry axis, so an opt-in, non-per-turn check would arguably need no reversal at all. What is genuinely blocked is picking *which* axis ships and on what threshold. The un-park trigger is self-firing (ADR-087): an unconfirmed decision is surfaced by the session-start oversight nudge and drained by `/wr-architect:review-decisions`, so this does not rot as a named-but-unfired re-entry point (P375).
- **Composes with**: P045, P410, P343

## Related

Captured via `/wr-itil:capture-problem`. Hang-off arbitration returned `PROCEED_NEW` over four candidates; each sits on a different axis and none absorbs this scope:

- **P045** (`docs/problems/open/045-auto-plugin-install-after-governance-release.md`) — shipped the very surfacer this ticket reports a gap in, under RFC-036 / ADR-088, and owns the fix-locus file. It is **not** the parent, because its network-free shape is the ratified premise this ticket challenges, and registry currency appears nowhere in its closure criteria. Folding this in would silently reverse P045's own design decision inside a ticket that never asked the question. The next `/wr-itil:review-problems` cluster pass should decide whether the two merge once the ADR settles.
- **P343** (`docs/problems/verifying/343-...md`) — PATH resolution order among versions already on disk. ADR-080's highest-version-wins wrapper resolves correctly here; it just resolves to a version 989 commits behind.
- **P410** (`docs/problems/open/410-...md`) — the inverse: too many old versions retained. This ticket is about the newest never arriving.
- **P115** (`docs/problems/parked/115-...md`) — worktree discovery reachability, parked on user direction. No worktree is involved in the observed drift.
- **P106** — `claude plugin install` is a silent no-op when any version is present, so the ordinary install path cannot close a gap it cannot detect. Compounds this ticket rather than duplicating it.
- **JTBD-302** (`docs/jtbd/plugin-user/JTBD-302-trust-readme-describes-installed-behaviour.proposed.md`) — **composes with, not the anchoring job** (re-anchored 2026-08-21). Its persona constraint about an agent expanding stale prose and acting on out-of-date instructions is the observed *mechanism*, one artefact class over — but its own contract was never breached here, since the stale SKILL.md accurately described the stale version that was installed.
- **JTBD-007** (`docs/jtbd/developer/JTBD-007-keep-plugins-current.proposed.md`) / persona `developer` — the anchoring job. Breached clause: *"the refresh mechanism actually fetches the latest marketplace version"*. JTBD-007 has **no desired outcome covering currency detection at all** — the surfacer arrived via STORY-034 / ADR-088 without the job gaining the clause, which is part of why this ticket drifted to JTBD-302 looking for a home. Adding that outcome is queued into the same ADR-068 lockstep ratification batch as ADR-120.
- **STORY-034** (`docs/stories/draft/STORY-034-plugin-staleness-surfacer-warns-once-per-new-version.md`) — the story that shipped `staleness-check.sh`, carrying `jtbd: [JTBD-007]` and `rfcs: [RFC-036]`. Its fourth acceptance criterion is still unticked.
- **ADR-120** (`docs/decisions/120-plugin-currency-is-detected-from-the-local-marketplace-clone-not-the-registry.proposed.md`) — the decision vehicle drafted by this iteration. Born unconfirmed; nothing may be built on it until ratified.
- **JTBD-303** is deliberately **not** cited: it is `human-oversight: unconfirmed`, and citing it as a served job would fire an unratified-dependency block.
