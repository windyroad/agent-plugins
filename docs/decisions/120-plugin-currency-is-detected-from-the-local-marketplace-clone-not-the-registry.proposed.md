---
status: "proposed"
date: 2026-08-21
human-oversight: unconfirmed
decision-makers: [Tom Howard]
consulted: [wr-architect:agent, wr-jtbd:agent]
informed: []
reassessment-date: 2026-11-21
---

# Plugin currency is detected from the local marketplace clone, not the registry

> **Born unconfirmed.** This decision was drafted by an AFK iteration working P506 and has **not** been ratified. Nothing may be built on it until a human confirms the substance (ADR-074 / ADR-110 / ADR-111). The five options below are the answer set for that ratification — a yes/no confirmation does not ratify it (ADR-111).

## Context and Problem Statement

ADR-088 shipped a plugin-staleness surfacer that compares **this session's running plugin version** against the **highest version installed on disk**. Both operands are local by construction, and the hook has no third operand. So an install whose *disk* has fallen behind its upstream is indistinguishable from one that is current, and stays that way indefinitely — restarting only re-reads the same stale disk.

Witnessed 2026-08-20 (P506): the `windyroad` marketplace clone was pinned at commit `c8f5db4` carrying `wr-itil` 0.59.2, 989 commits behind `origin/main`, while `npm view @windyroad/itil version` returned 1.1.1. The hook was not silent — it printed `wr-itil: this session is on 0.59.0, 0.59.2 installed — restart to pick it up`, which reads as "you are one patch behind" while the true gap was roughly forty releases. A downstream repo on that install then produced a story map in a **retired** format, faithfully following what 0.59.2's SKILL.md prescribed. The maintainer's first conclusion was that the plugin was producing rubbish; the plugin was fine, and a three-month-old copy of it was running.

**Why this needs its own decision.** ADR-088's Considered Option 5 (npm-registry check) was rejected *as core* and "retained as an opt-in secondary axis", and its Reassessment Criteria says *"If the secondary cache-vs-npm network axis is built, it lands as an amendment here."* That instruction predates **ADR-116** (Ratified decisions change only by supersession, confirmed 2026-08-13), which closes the body of any decision carrying `human-oversight: confirmed` and forbids amendment sections. ADR-088 line 73 is therefore **stale instruction, not live authority**, and the currency axis lands here instead.

**ADR-088's core stands; this decision is additive, not a supersession.** Per-turn trigger, per-plugin shape, surface-not-install, fail-open, once-per-detected-version, and the **network-free core path** are all untouched by the recommended option and carry no `supersedes:` claim. ADR-088's promised amendment is discharged *by a superseding vehicle rather than followed*, so a later reader does not find an unkept promise and have to guess whether it was honoured or missed. If Option A lands as the only currency axis, it fills the slot ADR-088 reserved for its Option 5 **without building Option 5** — the opt-in npm axis remains unbuilt and available.

## Decision Drivers

- **Catch the observed failure**: an install whose upstream has moved on must stop reporting as current.
- **Automatic cadence or it doesn't happen.** The documented workaround is a manual shell loop nobody runs; an on-demand-only check is not a fix (ADR-087; P375).
- **Do not reverse a property the maintainer individually ratified.** ADR-088's `oversight-confirmed-date` names **network-free** as one of five properties confirmed by name in the 2026-07-02 AskUserQuestion. Adding a network call to the per-turn path is a reversal; measuring a local artefact is not.
- **Fail open** — any detector error is a silent proceed, never a blocked turn (ADR-013 Rule 6).
- **Stay inside the per-turn injection budget** (ADR-038) — bytes *and* latency.
- **Per-plugin self-containment** (ADR-002 / ADR-003) — no hook may enumerate sibling plugins it does not own.
- **Connectivity constraint — PENDING PERSONA RATIFICATION.** Options B, C and D are shaped by the assumption that adopter machines are sometimes offline, metered, rate-limited or on slow links. `docs/jtbd/` documents **no such constraint** — a grep for offline / network / rate-limit / latency / slow-network across the whole tree returns zero hits. ADR-088 rejected registry-as-core on exactly this ground and it too had nothing to cite. This driver is therefore recorded as **assumed, not documented**, and the `developer` persona amendment adding it must ratify in the same event as this decision (ADR-068 lockstep — see Confirmation). No option below may be rejected *solely* on this driver until it is documented. This repo has been bitten by this precise shape before: the `developer` persona's `oversight-note` records that its reading-context constraint was hosted at persona tier because ADR-105 argued it from first principles with nothing to cite and ADR-107 then leaned on it and left half its argument out.

## Considered Options

The decision question is: **which upstream is authoritative for "current", and by what mechanism is it read?** Options A–D are genuinely different answers to it; E is the null.

### Option A — clone-age proxy, network-free (recommended)

Each plugin's hook additionally reads the git HEAD commit date of **its own** marketplace clone and emits one advisory when that clone's HEAD is older than a configured threshold. No network, no cache, no TTL, no opt-in surface, no offline semantics.

**Evidence.** Probed 2026-08-21 on the maintainer's machine — `git -C <clone> log -1 --format=%ct HEAD` returns instantly and discriminates: `ui-ux-pro-max-skill` 164 days, `openai-codex` 124, `community-access` 85, `windyroad` 0. **Limits of this evidence: n=1 machine, a single point in time, four clones.** The counterfactual that the 2026-08-20 failure would have been caught is **threshold-conditional** — the clone was roughly three months old, so it is caught by any threshold ≤ 90 days and missed by a larger one. No threshold exists yet (see Open sub-decisions).

Two clauses are load-bearing and must ship as clauses, not as implementation details:

- **Own marketplace only.** The hook derives its marketplace from its **own script path** — the canonical already parses `<cache>/windyroad/<key>/<version>/hooks/`, so the marketplace name is available without looking at anything else, and the clone is `~/.claude/plugins/marketplaces/<that name>`. One directory: the one this plugin came from, zero sibling knowledge. Iterating `~/.claude/plugins/marketplaces/*` — as the diagnostic probe above did — **is** the ADR-088-Option-3 / ADR-002 / ADR-003 violation and is out of bounds for the shipped hook.
- **Read only, never fetch.** ADR-088's ratified surface-not-install property means `git log -1` yes, `git fetch` / `claude plugin marketplace update` **never**. The clone is shared and the plugin does not own it. This is written down because "just add a fetch" is a one-line change that silently breaks both network-free *and* surface-not-install.

**Rejected sub-option — a shared marker to suppress duplicate lines.** The marketplace clone is shared across plugins, so N installed plugins each emit a line about the same clone. Keying the dedup marker on clone path + HEAD sha would fix that, and is **rejected**: ADR-088's Decision Outcome ratified "no aggregation, no shared cross-plugin marker, and no coordination between hooks… eliminates the P260 shared-marker race class outright." A clone-keyed marker is exactly a shared cross-plugin marker, and adopting it would make this decision a partial supersession of ADR-088 rather than an additive one. Instead **accept N bounded homogeneous lines** — the same tradeoff ADR-088 already took for N simultaneously-stale plugins. The existing per-`(session, key, HIGHEST)` dedup means each is emitted once per session.

### Option B — opt-in npm registry axis, TTL cache, detached refresh

The hook reads a cached `latest` version and compares it against the highest installed version. When opt-in is enabled and the cache is past TTL, a **detached** `npm view @windyroad/<pkg> version` refreshes it so the turn never waits; the answer lands for a later turn. Cache lives in machine-scoped agent-written state per **ADR-035** (`~/.claude/review-reports/` is the established precedent for this tier). TTL semantics follow `packages/itil/lib/check-upstream-cache-staleness.sh` — that helper is a **TTL-semantics precedent only**, not a location precedent, since it writes repo-local (`docs/problems/.upstream-cache.json`).

**This option reverses a ratified property, and Option A does not.** "Never waits" is a *different* property from "network-free"; a detached subprocess preserves the former and abandons the latter. That asymmetry is the load-bearing difference between A and B.

### Option C — cadenced network check on a separate surface

Move the network call entirely off the per-turn hook onto a SessionStart-tier check (ADR-040's surface, which is self-firing and therefore satisfies ADR-087) that refreshes at most once per TTL. The UserPromptSubmit hook only *reads* the cache, so the per-turn path stays a pure file read.

**ADR-088 rejected SessionStart-only and that rejection does not transfer.** It rejected SessionStart for the *session-vs-disk* trigger because that gap opens **mid-session** — you run `/install-updates` and the installed version advances under a live session. Registry currency does not change mid-session in any way the adopter can act on, so the reasoning that killed SessionStart there does not apply here.

### Option D — compare the clone's HEAD against its own remote

`git -C <clone> ls-remote` / `rev-list --count HEAD..@{u}` measures the **actual stale thing** — how far this clone has drifted from the remote it tracks. This answers the authority question *differently* from A, B and C: the authoritative upstream is the marketplace remote, not npm. It needs network, so it is B-class on the connectivity axis, but it produces a true drift count rather than a proxy or a package-version comparison.

This option exists because **the two upstreams demonstrably disagree**: on 2026-08-20 the clone carried 0.59.2 while npm carried 1.1.1. An option set that omits D resolves P506's "npm or the marketplace remote?" question by omission rather than by decision.

### Option E — do nothing

Keep the documented manual workaround. **Rejected**: it is manual and uncadenced, which is the complaint (ADR-087; P375; `feedback_automatic_cadence_or_it_doesnt_happen`).

## Decision Outcome

**Proposed — NOT RATIFIED.** Recommended: **Option A**, on the grounds that it removes the observed risk with the smallest diff, reverses no ratified property, and needs neither an opt-in surface nor offline/rate-limit/timeout semantics — dissolving two of P506's four open questions instead of answering them.

**A and C compose; they are not rivals.** A cheap local proxy every turn plus an authoritative check on a session cadence are two halves of a layered answer. Presenting them as exclusive would mis-frame the choice, so the ratification may select A, C, or A+C.

**P506's premise that this is a "design reversal" is falsified by Option A** and its RCA is corrected accordingly.

### Open sub-decisions carried into ratification

1. **The clone-age threshold.** It must be an **ADR-098 config key** (`~/.claude/cruise.config.json`, machine tier) with a stated default — **not a constant buried in the mechanism**. ADR-091 is the corpus precedent: it explicitly rejected a hardcoded constant, derived the threshold from a stated cadence, and named a fallback. Proposed default: **30 days**. This default is surfaced as part of the ratification rather than smuggled in as mechanism (P444).
2. **Duplicate-line policy** when N plugins share one clone — accept N lines (recommended, preserves ADR-088's no-coordination clause) versus a shared marker (rejected above, re-opens P260).
3. **Authoritative upstream when npm and the marketplace remote disagree** — Option A makes the question not arise; Options B/C answer "npm"; Option D answers "the marketplace remote".
4. **Scope of the sync fan-out.** `scripts/sync-staleness-check.sh` currently carries seven consumers (architect, itil, jtbd, tdd, risk-scorer, style-guide, voice-tone); its own comment records `connect`, `retrospective`, `c4`, `wardley` and `agent-plugins` as an explicit deferred RFC-036 task. Whether the currency axis reaches them is undecided.
5. **A third operand this decision does not close.** The proxy measures the clone. The 2026-08-20 incident *also* had the install cache at 0.59.0 while the clone carried 0.59.2 — and P106 makes `claude plugin install` a silent no-op when any version is present, so a freshly-pulled clone with a stale install cache is invisible to both the current predicate and to Option A. Named here so the gap is recorded rather than discovered later; closing it is not in this decision's scope.

## Consequences

### Good

- An install whose upstream has moved on stops reporting as current, on an automatic per-turn cadence that needs nobody to remember anything.
- Under Option A: no network dependency, no offline failure mode, no rate-limit exposure, no opt-in that the adopter who most needs it would never switch on.
- ADR-088's ratified core is preserved intact rather than reversed.

### Bad / accepted costs

- **Clone HEAD date is a proxy for currency, not currency.** A marketplace whose upstream genuinely has not moved in 100 days reads as 100 days stale while being perfectly current. That false-positive class does not exist in Options B, C or D and is the honest price of trading the network call for a local read. It also bites ADR-088's ratified *"silent when the session is current"* property, so the advisory must be worded as the **fact** ("last updated N days ago") rather than the **inference** ("you are stale").
- N installed plugins sharing one clone emit N lines (bounded, homogeneous, once each per session).

### Latency — ungoverned, explicitly accepted

ADR-038's budget governs **bytes, not milliseconds**, and a `performance-budget-*` decision does not exist in the corpus. Grounding per ADR-026:

- Today's check is `ls` + `sort -V` + a string compare — roughly 1–3 ms.
- Option A adds one `git log -1 --format=%ct HEAD` against a local clone: a single `.git` object read, **estimated** 5–15 ms warm and worst-case tens of ms cold. **This is a worst-case assumption, not a measurement.**
- Frequency is once per UserPromptSubmit per installed windyroad plugin. Per ADR-088 § Consequences a typical adopter runs 2–3; N≈10 is the maintainer/dogfood case only.
- Worst-case aggregate: 7 consumers × 15 ms ≈ **105 ms per turn** for the maintainer, ≈45 ms for a typical adopter — roughly 3 s / 1.4 s of added wall-clock across a 30-turn session.

That is materially above the *"stat + one compare, near-zero"* premise on which ADR-088's entire per-plugin-retention argument rests. **Mitigation, which is a clause of this decision and not an optimisation:** the clone's HEAD date only changes when the clone is updated, so it is read **once per session** via ADR-038's own announcement-marker primitive, collapsing the per-turn cost back to a marker stat. With the mitigation the premise holds; without it, it does not.

ADR-088 § Consequences classifies this surface as outside ADR-023's runtime-path performance-review trigger. That classification still holds — this is per-turn hook cost, not an HTTP request path.

### ADR-038 cluster assessment

This adds a **second emission to existing hooks**, not a seventh hook, so ADR-038's 6th-hook consolidation trigger does not re-fire. Recorded explicitly, the way ADR-088 § Consequences recorded its own assessment, so the next reader can tell it was assessed rather than missed. Byte cost: an advisory such as `windyroad marketplace clone is 92 days old — run: claude plugin marketplace update windyroad` is ~95 bytes, inside ADR-038's ≤150-byte reminder budget; fired alongside the existing version line the combined path is ~180 bytes, inside the ≤250-byte test slack.

## Confirmation

Ratification is an **AskUserQuestion whose answer set is Options A–E** (ADR-111 — a yes/no does not ratify), carrying the proposed 30-day threshold default as a surfaced sub-decision (P444). Per ADR-068 lockstep the `developer` persona amendment adding the connectivity constraint, and the JTBD-007 desired-outcome addition for the currency-**detection** axis, ratify in the **same confirm event** — one event, not three.

Implementation, once ratified, is verified by:

- Behavioural bats (ADR-052): a simulated months-behind clone emits the advisory; a fresh clone stays silent; a missing or non-git clone fails open silent; a clone at exactly the threshold boundary; the **combined** emission path asserted against the ADR-038 byte budget rather than each line separately.
- Canonical edit at `packages/shared/hooks/staleness-check.sh` + `scripts/sync-staleness-check.sh`, with CI `npm run check:staleness-check` green (ADR-017). Consumer test `.bats` files are **not** synced and each needs separate work.
- Per **ADR-119**, the implementation is proposed as a **release row**, never as an RFC document.
- `docs/decisions/README.md` compendium regenerated per ADR-077 / ADR-078.

## Reassessment Criteria

- **If the clone-age proxy produces a false positive in practice** (an advisory on a genuinely-current clone of a quiet marketplace), revisit Options C and D — the proxy's known weakness has become real rather than theoretical. **Self-firing trigger** (ADR-087): the `/wr-retrospective:run-retro` friction pass, which already reads advisory noise as a signal class.
- **If the once-per-session mitigation is not implemented**, the latency premise above fails and per-plugin retention must be re-argued against ADR-038's consolidation option. This is a **ratification-blocking** condition, not a deferral.
- Open sub-decision 5 (clone fresh, install cache behind) is deliberately unclosed here; it belongs to P106's surface.

## Related

- **P506** — the driving problem (staleness-check never asks the registry).
- **ADR-088** — the surfacer this extends. Core unchanged; its line-73 amendment instruction is discharged by this vehicle rather than followed.
- **ADR-116** — why an amendment to ADR-088 is unavailable.
- **ADR-119** — a fix proposal draws a release row, never a document.
- **ADR-074 / ADR-110 / ADR-111** — born-unconfirmed discipline; nothing may be built on this until ratified.
- **ADR-098** — layered config file; hosts the threshold key. **ADR-091** — precedent for deriving a threshold rather than hardcoding it.
- **ADR-035** — machine-scoped agent-written state location (Option B's cache).
- **ADR-038** — per-turn injection budget. **ADR-040** — SessionStart surface (Option C). **ADR-087** — self-firing cadence contract.
- **ADR-002 / ADR-003** — per-plugin self-containment (the own-marketplace-only clause). **ADR-017** — shared-code sync discipline.
- **ADR-068** — job/persona oversight lockstep (the same-event ratification above).
- **JTBD-007** (keep plugins current across projects) / persona `developer` — the anchoring job, re-anchored from JTBD-302 on 2026-08-21 JTBD review.
- **STORY-034** — the story that shipped `staleness-check.sh`; its fourth acceptance criterion is still unticked.
- **P045 / P375 / P402 / P106 / P260 / P444** — lineage and composing problems.
