---
status: "proposed"
date: 2026-05-25
human-oversight: confirmed
oversight-date: 2026-05-25
decision-makers: [Tom Howard]
consulted: [wr-architect:agent, wr-jtbd:agent]
informed: []
reassessment-date: 2026-08-25
---

# ADR-068: JTBD + persona human-oversight marker + `/wr-jtbd:confirm-jobs-and-personas` drain (sibling of ADR-066)

## Context and Problem Statement

ADR-066 established that recorded **decisions** (ADRs) must carry human oversight — a `human-oversight: confirmed` + `oversight-date` frontmatter marker, a token-cheap grep detector, a session-start nudge, a `/wr-architect:review-decisions` drain, and born-confirmed recording via `create-adr`.

P288 (user direction 2026-05-25: *"new jobs to be done and new personas need human confirmation too"*) observes the same risk for the **other auto-derivable governance artifacts**: JTBDs (`docs/jtbd/<persona>/JTBD-NNN-*.md`) and personas (`docs/jtbd/<persona>/persona.md`). These can be agent-derived without a human confirming they reflect real user/business need — and the JTBD edit gate (`jtbd-enforce-edit.sh`) reviews *every* project edit against `docs/jtbd/`, so a drifted auto-made job/persona propagates wrong alignment verdicts suite-wide. As of this ADR, **17 jobs/personas** (4 personas + 13 JTBDs) carry no oversight marker.

## Decision Drivers

- Same drivers as ADR-066: token-cheap grep detection; orthogonal to `status:`; born-confirmed-going-forward; never-re-ask (ADR-009 principle); adopter portability (the mechanism ships in the plugin; each adopter drains its own `docs/jtbd/`).
- **Cross-surface consistency** — reuse the ADR-066 marker field verbatim so one detector grammar and one AFK guard cover both the ADR and the JTBD surfaces.

## Considered Options

- **Separate ADR-068 vs amend ADR-066.** Chosen: **separate**, citing ADR-066 as the precedent. The mechanisms are plugin-specific (`@windyroad/architect` vs `@windyroad/jtbd`, independently published per ADR-002); a shared hook/script would couple their release cycles. This mirrors how the two plugins already carry sibling — not shared — gate hooks (ADR-009 precedent).
- **Drain-skill name** (genuinely open — `/wr-jtbd:review-jobs` is already the read-only *alignment* reviewer, the analog of `/wr-architect:review-design`, not of `review-decisions`). Chosen: **`/wr-jtbd:confirm-jobs-and-personas`** (user, via `AskUserQuestion` 2026-05-25) — a distinct "confirm" verb that won't be confused with the alignment reviewer, naming both surfaces it drains. Rejected: a mode on `review-jobs` (conflates a read-only compliance review with a read-write oversight drain; the mode arg also fails the subcommand-discoverability rule).

## Decision Outcome

Chosen: **mirror ADR-066 as a wr-jtbd sibling**.

1. **Marker.** `human-oversight: confirmed` + `oversight-date: YYYY-MM-DD` on JTBD files AND persona files — the ADR-066 field verbatim, orthogonal to `status:`. **Additive to the ADR-008 JTBD-file frontmatter contract** (so a future ADR-008 reader does not flag it as undocumented). Write-once-permanent except on material amendment (see Reassessment).
2. **Detector.** `wr-jtbd-detect-unoversighted` (ADR-049 shim → `packages/jtbd/scripts/detect-unoversighted.sh`) greps `docs/jtbd/**/*.md` frontmatter for absence of `human-oversight: confirmed`; excludes `README.md`. **Token-cheap ceiling restated for the JTBD path: one grep, no body reads, no per-file LLM call** (a heavy detector would tax every session start).
3. **Session-start nudge.** A new wr-jtbd `SessionStart` hook (matcher `startup`; the jtbd plugin has no SessionStart event yet — this adds one, mirroring ADR-040 / ADR-066), emitting `N job(s)/persona(s) lack human oversight — run /wr-jtbd:confirm-jobs-and-personas`. **Self-suppresses on `WR_SUPPRESS_OVERSIGHT_NUDGE=1`.**
4. **Drain skill.** `/wr-jtbd:confirm-jobs-and-personas` drains the unoversighted set in batches via `AskUserQuestion` (confirm / amend / reject), writing the marker on confirm; never re-asks.
5. **Born-confirmed.** `packages/jtbd/skills/update-guide/SKILL.md` (the job/persona authoring surface — the JTBD equivalent of `create-adr`) writes the marker when the user confirms a new/edited job or persona.
6. **Confirm-gate.** A `proposed` job/persona is not treated as human-oversighted without a confirm pass.

### Amendment 2026-05-27 — enforcement surface 3: the build-upon guard (P323; user-confirmed via AskUserQuestion 2026-05-27)

Items 1–6 above are oversight enforcement **surfaces 1 (born-confirmed record via `update-guide`) and 2 (interactive drain via `confirm-jobs-and-personas`)** — the JTBD twins of ADR-066's `create-adr` + `review-decisions`. They confirm an artifact's substance and let a human drain the unconfirmed set, but they do **not** stop *dependent work* from being built on a job/persona whose substance is still unconfirmed. That third surface — the **build-upon guard** — was added to the ADR side by ADR-074 / RFC-010 (the architect agent's `[Unratified Dependency]` verdict, 2026-05-27) and had no JTBD equivalent (P323; the asymmetry was a sequencing artifact — ADR-068 was authored 2026-05-25, before surface 3 existed on the ADR side, so there was nothing to mirror). This amendment adds the JTBD surface 3. The decision home (amend ADR-068 vs new ADR vs amend ADR-074) was confirmed by the user via `AskUserQuestion` on 2026-05-27: **amend ADR-068** — surface 3 completes the JTBD-oversight surface-set in its cohesive home, mirroring how ADR-074 carried the ADR-side surface 3 as an amendment to the contract it extends.

7. **Build-upon guard (surface 3).** The `wr-jtbd:agent` reviewer emits an `[Unratified Dependency]` verdict (ISSUES FOUND / FAIL) when a change or plan **explicitly cites, implements, or serves** a specific persona or job — an `@jtbd JTBD-NNN` annotation, a `persona: <name>` reference, or it authors that artifact's own flow — whose frontmatter lacks `human-oversight: confirmed` and which is not superseded. Action: "ratify `<persona | JTBD-NNN>` via `/wr-jtbd:confirm-jobs-and-personas` before this lands." **Keyed on the marker, never on `status:`** (orthogonal axes, item 1) — building on a *ratified* job whose `status` is still `proposed` is fine. **Bound to explicit cite/implement, NOT ambient alignment** — the reviewer already matches every change to a job for its PASS verdict; surface 3 must not fire on that mere match, only on an explicit dependency (the inverse-P078 / P132 over-fire guard). The reviewer runs the single-artifact predicate `wr-jtbd-is-job-or-persona-unconfirmed` (ADR-049 shim → `packages/jtbd/scripts/is-job-or-persona-unconfirmed.sh`, the sibling of the architect's `is-decision-unconfirmed.sh`) **by exit code** — the jtbd agent has `Bash` (the architect agent does not, which is why it greps frontmatter inline; the JTBD instruction therefore differs in form, which is correct, not a fidelity gap). The predicate shares the marker grammar with `detect-unoversighted.sh` (item 2) per the cross-surface-consistency driver. **Does NOT wait on the P288 drain** — surface 3 is the forcing function; the currently-large unratified set is exactly what it gates against, so its first real fires are expected, not false positives. (Live instance as of 2026-05-27: after P289 renamed `solo-developer` → `developer` and ratified the persona, its jobs `JTBD-001`..`007` remain unratified pending the P288 drain — those are surface 3's canonical first-fire cases.)

### Shared cross-plugin contracts (named so they are not refactored away)

- **`WR_SUPPRESS_OVERSIGHT_NUDGE` is the suite-wide oversight-nudge AFK guard** — shared across ALL oversight-nudge hooks (architect today, jtbd here, any future surface). AFK orchestrators export it **once** (`work-problems` Step 5 already does); one var silences every oversight nudge with zero per-plugin orchestrator change. Do NOT split into per-plugin guard vars.
- **Marker field grammar is shared** (`human-oversight: confirmed` + `oversight-date`) — data-schema convergence, NOT code coupling. Each plugin's detector independently greps its own corpus.
- **Unoversighted ≠ unusable.** An unconfirmed job/persona remains fully readable and review-anchorable while it awaits confirmation — the marker records provenance, it does not quarantine the doc. The gate MUST NOT block reviews from reading unoversighted jobs (that would break the `wr-jtbd:agent` review flow itself).

## Consequences

**Good:** human oversight of the JTBD corpus becomes a first-class, grep-checkable, git-tracked fact (JTBD-202 / JTBD-201 auditability; JTBD-101 adopter reusability). The unconfirmed set only shrinks (born-confirmed via update-guide).

**Neutral:** two frontmatter lines on jobs/personas; reuses ADR-066's field + detector algorithm near-verbatim.

**Bad / costs:** the 17 existing unoversighted jobs/personas must be drained — a focused interactive sweep, not a blocking pass. Adds a `SessionStart` event to the jtbd plugin (none existed); it carries the AFK self-suppress guard **from day one**. Adds a `scripts/` dir to the jtbd plugin (none existed).

## Confirmation

Behavioural (per ADR-052), mirroring ADR-066's set:

1. `wr-jtbd-detect-unoversighted` resolves on `$PATH` and emits the correct count + path-list over a `docs/jtbd/` fixture tree (persona.md + JTBD-*.md; README excluded) — behavioural bats.
2. The SessionStart nudge emits the count line and is silent (a) on zero and (b) under `WR_SUPPRESS_OVERSIGHT_NUDGE=1` — behavioural bats.
3. `/wr-jtbd:confirm-jobs-and-personas` writes the marker on confirm and leaves it absent on amend/reject — behavioural bats.
4. `update-guide` writes the marker on the Step-N confirm (born-confirmed) — assertion against the update-guide contract.
5. **Dogfood self-check:** ADR-068 carries `human-oversight: confirmed` in its own frontmatter (it does — recorded through the asking flow, with the one open sub-decision resolved by `AskUserQuestion`).
6. **(Surface 3, amendment 2026-05-27)** The `wr-jtbd:agent` emits `[Unratified Dependency]` (FAIL) on a change that explicitly cites an unratified persona/job, and PASS when the cited artifact carries the marker — structural-permitted per ADR-052 Surface 2 (P176: the agent verdict is prompt-driven, not behaviourally testable until the skill-invocation harness lands; mirrors `architect-unratified-dependency-verdict.bats`). The single-artifact predicate `is-job-or-persona-unconfirmed.sh` is behaviourally tested (exit-code over a `docs/jtbd/` fixture tree — marker-present→0, marker-absent→1, superseded→0), the sibling of `is-decision-unconfirmed.bats`.

## Reassessment Criteria

- Mirror ADR-066: the marker is write-once-permanent EXCEPT when a job's statement/outcomes (or a persona's definition) are materially rewritten — a material amend clears `human-oversight` so the changed artifact is re-confirmed.
- If a future surface needs per-confirm accountability, add an `oversight-by:` scalar without migration.
- Reassess at 2026-08-25.

## Related

- **P288** — driving ticket (surfaces 1 & 2). **P283 / ADR-066** — the precedent mechanism this mirrors.
- **P323** — driving ticket for the surface-3 amendment (2026-05-27). **ADR-074 / RFC-010 / P318** — the ADR-side surface-3 build-upon guard this JTBD surface mirrors. **P289** — the `solo-developer` → `developer` rename (landed 2026-05-27); the persona is now ratified, and its still-unratified jobs (`JTBD-001`..`007`, pending the P288 drain) are surface 3's live instances.
- **ADR-008** — JTBD directory structure; the marker is additive to its frontmatter contract.
- **ADR-049** — shim grammar. **ADR-040** — SessionStart nudge shape. **ADR-009** — never-re-ask principle (not its TTL lifecycle). **ADR-002** — per-plugin packaging (why sibling not shared). **ADR-013 / ADR-044** — structured user interaction + decision-delegation taxonomy.
- `packages/jtbd/skills/update-guide/SKILL.md` — born-confirmed write site. `packages/jtbd/skills/review-jobs/SKILL.md` — the read-only alignment reviewer (distinct from this drain).
- `packages/architect/scripts/detect-unoversighted.sh` + `architect-oversight-nudge.sh` + `skills/review-decisions/` — the templates mirrored here.
