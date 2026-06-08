# @windyroad/jtbd

## 0.12.6

### Patch Changes

- 6197434: P301: oversight-marker-only ADR diffs are now exempt from the architect
  and JTBD enforce-edit gates.

  Multi-batch `/wr-architect:review-decisions` (ADR-066) and
  `/wr-jtbd:confirm-jobs-and-personas` (ADR-068) drains previously paid
  2-3 no-op-PASS architect + JTBD review round-trips per batch because
  each `human-oversight: confirmed` / `oversight-date` frontmatter write
  to a `docs/decisions/*.md` ADR re-tripped the full enforce-edit gate.
  The marker write is the mechanical output of a decision the user
  already substance-confirmed via `AskUserQuestion`; the review had
  nothing substantive to assess.

  Both plugins now ship a shared `is_marker_only_diff OLD NEW` predicate
  at `hooks/lib/marker-only-diff.sh` (sibling-copied per the existing
  `gate-helpers.sh` duplicate-shared pattern, ADR-017). The predicate
  returns 0 when every added/removed non-empty line in the Edit/Write
  diff matches the narrow oversight-marker frontmatter grammar:
  `human-oversight:`, `oversight-date:`, `decision-makers:`, or
  `supersede-ticket:`. When marker-only and the file is under
  `docs/decisions/`, the enforce-edit hook short-circuits to exit 0
  silently.

  **Safety contracts preserved.** The
  `architect-oversight-marker-discipline.sh` and
  `jtbd-oversight-marker-discipline.sh` hooks remain active and enforce
  the per-ADR session evidence marker for `human-oversight: confirmed`
  introductions (P348 / ADR-066 amendment 2026-06-02). AFK iter
  subprocesses still cannot silently ship `confirmed` markers without
  the user's substance-confirm event. The exemption is exact — any
  non-marker line (body content, `status:` / `date:` changes, frontmatter
  keys outside the four-key grammar) fails the predicate and the diff
  falls through to the normal gate. Fail-safe: the predicate returns 1
  (NOT marker-only) on any parse error, so the gate proceeds with its
  normal review requirement.

  User-visible impact: fewer no-op architect + JTBD review delegations
  during `/wr-architect:review-decisions` and
  `/wr-jtbd:confirm-jobs-and-personas` drain batches; the drain finishes
  faster without the round-trip context cost.

  12 new behavioural bats (7 architect + 5 jtbd) cover the four critical
  shapes: marker-only ADD exempts, marker-only UPDATE exempts,
  mixed-marker+body still gates, pure body change still gates. Full
  hook suite green: 198/198 architect + JTBD (no regression).

  Architect PASS — no new ADR; the exemption mirrors the existing P029
  governance-doc gate exemption shape at narrower scope, and the
  ADR-009 / ADR-066 / ADR-068 marker contracts are unchanged. JTBD
  PASS — serves JTBD-006 (Progress the Backlog While I'm Away) and
  upholds JTBD-001 (Enforce Governance Without Slowing Down) by removing
  no-op review round-trips on marker-only edits.

  Closes P301.

## 0.12.5

### Patch Changes

- 9a9eed6: P213: PostToolUse:Skill matcher coverage for the slide-marker hook (ADR-009
  Option D — P111 matcher expansion).

  Long-running SKILL invocations (the `/wr-risk-scorer:assess-{release,wip,
external-comms,inbound-report}` sibling-assessor SKILLs run by the
  `/wr-itil:work-problems` AFK orchestrator) previously did not refresh the
  parent session's gate markers on completion. The slide-marker hook was
  registered on the `Agent|Bash` PostToolUse matcher list only, so a SKILL
  that ran longer than the gate TTL window could push the parent's marker
  mtime past TTL between SKILL boundaries even when the parent was actively
  orchestrating throughout. The symptom: a fresh subagent re-delegation
  forced after the SKILL returns, just to satisfy the gate.

  This release widens the matcher list to `Agent|Bash|Skill` across the
  five review plugins. The slide helper
  (`slide_marker_on_subprocess_return` in each plugin's
  `hooks/lib/gate-helpers.sh`) is matcher-agnostic — it reads
  `tool_response.is_error` and `tool_response.content` from
  `_HOOK_INPUT`, both of which are present in Claude Code's uniform
  PostToolUse JSON contract regardless of which tool fired. No helper code
  change; ADR-017 byte-identity across the four shared lib copies
  preserved.

  User-visible impact: fewer "gate denied — please re-delegate to
  architect/JTBD/risk-scorer" friction events during AFK loops and
  interactive sessions that chain multiple SKILL invocations.

  ADR-009 2026-06-08 amendment records the contract. The 2×TTL hard-cap
  from `<action>-born` continues to bound total marker life; the wider
  matcher coverage does not defeat the hard-cap, only makes marker
  freshness more reliable within the cap window.

  6 new behavioural bats (5 across the byte-identical
  `slide-marker-on-subprocess-return.bats` files + 1 hook-level
  integration test in `architect-slide-marker.bats`). Full hook suite:
  420/420 green (no regression).

  Closes P213 on the substance dimension; verification moves to the next
  AFK orchestrator session. Architect PASS + JTBD PASS 2026-06-08.

## 0.12.4

### Patch Changes

- 5a1d26f: P215: architect-gate deny-reason now carries an explicit recovery directive. `check_architect_gate` exposes `ARCHITECT_GATE_REASON` per failure mode (no marker / TTL expired / drift detected) mirroring the sibling `REVIEW_GATE_REASON` pattern; `architect-enforce-edit.sh` and `architect-plan-enforce.sh` append the reason to the BLOCKED deny message so the agent sees a clear "Re-delegate to wr-architect:agent via the Agent tool (subagent_type: 'wr-architect:agent') to refresh the marker." directive without having to read source. Sibling `REVIEW_GATE_REASON` messages in `@windyroad/jtbd`, `@windyroad/voice-tone`, and `@windyroad/style-guide` review-gate.sh sharpened from vague "Re-run the X agent" to the same explicit re-delegation form for symmetry. Marker mechanics unchanged per ADR-009. 7 new behavioural bats green covering the three failure-mode branches plus the enforce-edit deny output. RFC-021 carries the fix per ADR-071.

## 0.12.3

### Patch Changes

- b13b9e9: Exempt `docs/retros/` from architect + JTBD edit-enforce gates (P203).

  The ask-hygiene + run-retro narrative trail under `docs/retros/` (written by
  `/wr-retrospective:run-retro` Step 2d + Step 5) is not load-bearing
  architecture or user-job content. Both gates were firing BLOCKED on every
  retro append, forcing two subagent round-trips for a routine narrative
  artefact. Mirrors the existing peer-plugin-policy exemptions for
  `docs/problems/`, `docs/jtbd/`, `docs/briefing/`, `docs/story-maps/`, and
  `docs/stories/`. Behavioural bats coverage added in both
  `architect-enforce-scope.bats` and `jtbd-enforce-scope.bats`.

## 0.12.2

### Patch Changes

- e197424: Substance-aware drift detection + atomic verdict-write for the governance gate libs. Closes P303 (architect-gate multi-decision-file deadlock — drift-relock facet) and P353 (hash-marker brittleness umbrella class root cause).

  The shared `gate-helpers.sh` lib (byte-identical across architect / jtbd / voice-tone / style-guide / risk-scorer) gains two helpers per the user-ratified contract (ADR-009 amendment 2026-06-06):

  - `_substance_hash_path` — normalises CRLF / trailing whitespace / trailing newlines before hashing. Trivial post-PASS edits (whitespace, line-ending) no longer invalidate the marker. Conservative boundary preserved: single-numeral edits and frontmatter-key changes are still treated as substantive (re-review fires) — fail toward MORE governance when in doubt.
  - `_atomic_mark_with_hash` — writes the marker + hash file as an atomic mktemp + rename pair. Either both files land or neither does. Closes the "marker doesn't land after PASS" failure mode P353 measured as ~12 subagent invocations + 3 `BYPASS_RISK_GATE=1` uses per 3-filing session.

  `review-gate.sh` (jtbd / voice-tone / style-guide) and `architect-gate.sh` route their drift check through `_substance_hash_path`; `store_review_hash` + `architect-mark-reviewed.sh` + `architect-refresh-hash.sh` route the verdict-write through `_atomic_mark_with_hash`. ADR-028 carries the cross-amendment for the external-comms gate. 25 new behavioural bats green across architect / jtbd / voice-tone / style-guide; 259/259 existing hook bats remain green.

## 0.12.1

### Patch Changes

- db91d5f: P191: JTBD edit gate resolves docs/jtbd from the project root, not the hook runtime CWD

  The JTBD PreToolUse edit gate (jtbd-enforce-edit.sh) false-blocked legitimate
  edits with "no JTBD documentation exists" even when docs/jtbd/ was present,
  because the activation check `[ -d "docs/jtbd" ]` used a relative path resolved
  against the hook process's runtime CWD — which Claude Code can launch divergent
  from the session/project dir. Anchor every project-relative check on
  `PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$PWD}"` (mirrors jtbd-oversight-nudge.sh) in
  both jtbd-enforce-edit.sh and jtbd-mark-reviewed.sh. Fail-closed on genuine
  docs/jtbd absence is preserved. Carried by RFC-020.

## 0.12.0

### Minor Changes

- 4694239: P348: structurally gate `human-oversight: confirmed` writes against a session-scoped substance-confirm evidence marker; add `unconfirmed` as a fourth enum value for AFK-iter-deferred decisions/jobs.

  Closes the P348 fix-strategy (user-ratified 2026-06-02). AFK iter subprocesses spawned via `claude -p` have no `AskUserQuestion` access (ADR-013 Rule 6 fail-safe-defer territory) yet were silently authoring ADRs through `/wr-architect:capture-adr` and `/wr-architect:create-adr` and writing `human-oversight: confirmed` without any user confirmation event — contradicting ADR-066's write-once-permanent-on-substance-confirm contract and JTBD-006's "audit trail — every action taken during AFK mode should be traceable" outcome. Sibling failure mode on the JTBD/persona surface contradicts ADR-068 + JTBD-201/202 auditability constraints. The bogus-ratification class P340 captured (ADR-078 born `confirmed` after a draft-quality review answer) was the SKILL-prose-tightening surface; P348 is the structural escalation.

  Two prongs ship together:

  1. **PreToolUse:Edit|Write structural gate.** `architect-oversight-marker-discipline.sh` and the sibling `jtbd-oversight-marker-discipline.sh` deny any Edit/Write that INTRODUCES `human-oversight: confirmed` into a `docs/decisions/*.md` or `docs/jtbd/**/*.md` frontmatter unless a session-scoped evidence marker `/tmp/oversight-confirmed-<sha256-of-path>-<session-id>` exists for THAT specific artefact under THIS session. Existing-marker Edit/Write paths (re-stamps, status transitions, file moves that preserve the line) are exempted — only INTRODUCING the marker is gated. AFK-fallback writes (`unconfirmed`, `rejected-pending-supersede`) are unconditionally allowed.

  2. **`unconfirmed` enum value** on the same `human-oversight:` axis. AFK iter subprocesses MUST write `human-oversight: unconfirmed`, which the drains (`/wr-architect:review-decisions`, `/wr-jtbd:confirm-jobs-and-personas`) later promote interactively. The existing detectors (`detect-unoversighted.sh`) already treat anything-not-`confirmed`-and-not-`rejected-pending-supersede`-with-ticket as unoversighted, so `unconfirmed` flows naturally into the drain queue without a detector change. Naming it explicitly carries the iter's intent — this is NOT a missing marker (a pre-ADR-066 ADR), it is an EXPLICITLY-DEFERRED confirmation the iter knows the user needs to resolve.

  Marker namespace `/tmp/oversight-confirmed-<sha>-<sid>` is SHARED between architect and JTBD hooks — data-schema convergence, not code coupling (mirrors the "shared cross-plugin contracts" section in ADR-068). Each plugin's helper script independently writes the same-shape marker file; each plugin's hook independently reads it. Multi-SID write per ADR-050 Option C — the helper enumerates every recent candidate SID and writes one marker per candidate, so concurrent orchestrator + subprocess sessions don't miss the match.

  Shipped:

  - `packages/architect/hooks/architect-oversight-marker-discipline.sh` + registration in `packages/architect/hooks/hooks.json` (new PreToolUse:Edit|Write entry, sibling of `architect-enforce-edit.sh`).
  - `packages/jtbd/hooks/jtbd-oversight-marker-discipline.sh` + registration in `packages/jtbd/hooks/hooks.json` (same shape).
  - `packages/architect/scripts/mark-oversight-confirmed.sh` + ADR-049 PATH shim `packages/architect/bin/wr-architect-mark-oversight-confirmed` (regenerated from the ADR-080 highest-version-wins template; `npm run check:shim-wrappers` confirms 42/42 in sync after regeneration).
  - `packages/jtbd/scripts/mark-oversight-confirmed.sh` + ADR-049 PATH shim `packages/jtbd/bin/wr-jtbd-mark-oversight-confirmed`.
  - 12 behavioural bats for the architect hook (`packages/architect/hooks/test/architect-oversight-marker-discipline.bats`) — positive marker-present-allow paths (Write + Edit), negative marker-absent-deny paths, AFK-`unconfirmed` allow, `rejected-pending-supersede` allow, scope/non-fire paths (non-ADR, README, no-marker-introduction, re-stamp), end-to-end `mark-oversight-confirmed.sh` → hook satisfaction.
  - 10 behavioural bats sibling for the JTBD hook (`packages/jtbd/hooks/test/jtbd-oversight-marker-discipline.bats`).
  - `docs/decisions/066-human-oversight-marker-and-review-decisions-drain.proposed.md` — Amendment 2026-06-02 codifying the structural guard + the `unconfirmed` enum value. Marker-write authority moves from SKILL-prose discipline to a PreToolUse hook backstop; `unconfirmed` is purely additive (no detector change required).
  - `docs/decisions/068-jtbd-persona-human-oversight-marker-and-confirm-drain.proposed.md` — mirror Amendment 2026-06-02 on the JTBD/persona surface.
  - `packages/architect/skills/create-adr/SKILL.md` Step 5a — gains explicit step calling `wr-architect-mark-oversight-confirmed <adr-path>` immediately after the substance-confirm `AskUserQuestion` answer lands; AFK fallback prose names `unconfirmed` as the iter-correct enum value.
  - `packages/architect/skills/capture-adr/SKILL.md` — skeleton frontmatter now emits `human-oversight: unconfirmed` (capture is the AFK-friendly aside surface with no substance-confirm pass; `confirmed` at capture would be a hollow marker).
  - `packages/jtbd/skills/update-guide/SKILL.md` — both persona and job born-confirmed write sites now call `wr-jtbd-mark-oversight-confirmed <artefact-path>` before the marker write; AFK fallback prose names `unconfirmed`.
  - `packages/itil/skills/capture-rfc/SKILL.md` — skeleton frontmatter now emits `human-oversight: unconfirmed` (RFCs ratify at `/wr-itil:manage-rfc accepted`, not at capture).
  - `packages/itil/skills/work-problems/SKILL.md` Step 2.4 gate (a) — adds an oversight-unconfirmed drain sub-surface alongside the outstanding-questions surface, running `wr-architect-detect-unoversighted` + `wr-jtbd-detect-unoversighted` and nudging the user toward the drain skills when the loop's iters have queued `unconfirmed` markers.

  Architect verdict (2026-06-02): PASS. No new ADR required — the structural guard extends ADR-066's existing marker-write authority via amendment, and `unconfirmed` composes with the existing 3-value enum (`confirmed`, `rejected-pending-supersede`, absent) without migration. ADR-049 + ADR-080 shim grammar followed; ADR-002 plugin packaging respected (each plugin self-contained, byte-identical scripts copied per-plugin); ADR-050 multi-SID candidate enumeration applied; ADR-045 Pattern 1 silent-on-pass PreToolUse shape; ADR-052 behavioural-tests default. Two non-blocking advisories honoured (shims registered with sync-shim-wrappers; SKILL prose names `unconfirmed` as the AFK-derived default per the JTBD-101 clear-patterns constraint).

  JTBD verdict (2026-06-02): PASS. Primary job served: JTBD-006 (Progress the Backlog While I'm Away — the change directly fixes a P348 defect in this job's core flow, restoring honest signalling so AFK iters can ship work without claiming oversight they didn't earn). Secondary: JTBD-201/202 (auditability persona constraints satisfied by structural enforcement), JTBD-101 (sibling-hook + per-plugin script + ADR-049 PATH-shim is exactly the plugin-self-contained pattern), JTBD-001 (structural PreToolUse deny is "reviewed against relevant policy before it lands" applied to oversight-confirmation writes). No persona conflicts.

  Migration audit deferred: 63 ADRs + 17 JTBDs in this repo currently carry `human-oversight: confirmed`. Per the design spec, markers SET in this session are legitimate; markers from prior sessions WITHOUT findable substance-confirm audit trail should flip to `unconfirmed`. The audit + flip pass is captured as a follow-up — implementation iter scope was the structural prongs.

## 0.11.0

### Minor Changes

- 300d5da: ADR-080: `bin/wr-jtbd-*` shims now resolve to the highest-version cached sibling at every invocation (was: dispatch to own scripts/). Closes P343 mid-session staleness — `/install-updates` mid-session no longer requires Claude Code restart for shim resolution to pick up the new version. Source-monorepo execution is preserved via a source-repo guard that falls through to `$(dirname "$0")/../scripts/<name>.sh`. The `wr-jtbd-<kebab-script-name>` naming grammar is unchanged.

## 0.10.0

### Minor Changes

- 96696aa: JTBD + persona decision-oversight mechanism (P288, ADR-068 — sibling of ADR-066). The jtbd plugin now records human oversight on jobs and personas with a `human-oversight: confirmed` + `oversight-date` frontmatter marker (orthogonal to `status:`), detects unoversighted jobs/personas with a token-cheap grep (`wr-jtbd-detect-unoversighted`), nudges at session start when jobs/personas lack oversight (self-suppressing inside AFK iterations via the shared `WR_SUPPRESS_OVERSIGHT_NUDGE` guard), and drains the unconfirmed set via the new `/wr-jtbd:confirm-jobs-and-personas` skill (confirm/amend/reject per artifact via AskUserQuestion). Jobs/personas created through `update-guide` are born oversighted. This is the read-write oversight drain — distinct from the read-only `/wr-jtbd:review-jobs` alignment reviewer.

## 0.9.0

### Minor Changes

- aef160c: ADR-066 marker vocabulary gains a third value: `human-oversight: rejected-pending-supersede` + companion `supersede-ticket: P<NNN>` scalar. The detector (`detect-unoversighted.sh`) and build-upon predicate (`is-decision-unconfirmed.sh`) treat the marker+ticket pair as ratified-equivalent — the `/wr-architect:review-decisions` drain stops re-asking ADRs the user explicitly rejected with a tracked supersede. The same grammar mirrors onto the JTBD sibling (`detect-unoversighted.sh` + `is-job-or-persona-unconfirmed.sh` + `/wr-jtbd:confirm-jobs-and-personas`). Compendium renderer surfaces the disposition: `**Oversight:** rejected-pending-supersede (P<NNN>)`. Closes P316.

## 0.8.4

### Patch Changes

- 115b2f2: JTBD review flags changes built on an unratified persona or job (ADR-068 surface 3, RFC-011, P323).

  The jtbd agent now emits a new [Unratified Dependency] verdict: when a change or plan explicitly cites, implements, or serves a persona or job that lacks `human-oversight: confirmed` (unratified, and not superseded), it reports ISSUES FOUND with the action "ratify it via /wr-jtbd:confirm-jobs-and-personas before this lands." This is the JTBD twin of the architect side's surface-3 control (RFC-010 / P318).

  - Keyed on the human-oversight marker, NOT on `status:` — building on a ratified job is fine even when its status is still `proposed` (status and oversight are orthogonal axes).
  - The agent runs the new `wr-jtbd-is-job-or-persona-unconfirmed` predicate by exit code (the jtbd agent has Bash) — the single-artifact sibling of the architect's `is-decision-unconfirmed`, resolving `persona: <name>` and `JTBD-NNN` refs over the ADR-008 layout and keeping its marker grammar in sync with `detect-unoversighted`.
  - Bounded to explicit cite/implement (not ambient alignment); the inverse-P078 over-fire guard. Unlike the architect surface, the JTBD unratified set is currently large (P288 drain in progress), so this fires more often until that drain completes — the intended forcing function.
  - Closes the JTBD-surface half of the build-on-unratified gap (the ADR-surface half is P318/RFC-010); completes the JTBD oversight surface-set (surfaces 1 & 2 shipped via ADR-068/P288).

## 0.8.3

### Patch Changes

- 7ca47ef: P087 Phase 3 (P269) — amend `packages/itil/scripts/plugin-maturity-populate.sh` rollup-emission to write `rollup_invocations_30d` (sum of non-null per-surface `invocations_30d`; null when all-null) and `bootstrapping` (populate-time snapshot of the bootstrapping-window state) onto the plugin root `maturity:` rollup. Restores compliance with ADR-053 §Bootstrapping clause Phase 3 rendering requirement — the renderer's compound-form predicate at `plugin-maturity-render.sh` line 144-147 is AND-gated on both fields, so pre-amendment all 11 plugins fell through to bare-band during the bootstrapping window even though the band derivation correctly applied the bootstrapping rule.

  Schema additions are **additive-within-2.0** per ADR-058 §Confirmation #8 — no schema_version bump. Contrast with the §Amendment 2026-05-18 P0 hotfix which bumped `"1.0" → "2.0"` because that amendment was non-additive (path move). The P269 amendment strictly adds two new keys to the rollup dict; old consumers reading `{schema_version, band}` continue to work unchanged.

  Changes:

  - `packages/itil/scripts/plugin-maturity-populate.sh` rollup-emission block: collects per-surface `invocations_30d` during the surface walk; emits `rollup_invocations_30d` as sum-of-non-null (or null when all-null per the hook-only honesty contract); emits `bootstrapping` copied from the existing module-scope `bootstrapping_active` flag.
  - `docs/decisions/063-plugin-maturity-presentation-layer.proposed.md` — new dated amendment block §Amendment 2026-05-18 (P269 — rollup compound-evidence write); rollup schema example updated; P0 hotfix corrected-schema example updated with the two new fields and a forward-reference to the P269 amendment.
  - `packages/itil/scripts/test/plugin-maturity-populate.bats` — 5 new behavioural tests (sum-of-non-null, null-when-all-hook, bootstrapping-true-during-window, bootstrapping-false-post-sunset) + amended existing rollup-shape test for the new fields. Now 22 tests (up from 17).
  - `packages/itil/scripts/test/plugin-maturity-render.bats` — 2 new behavioural tests covering the AND-gated predicate edge cases (`bootstrapping=true + null-invocations → bare-band`, `bootstrapping=false + integer → bare-band`). Now 19 tests (up from 17).
  - `packages/itil/scripts/test/plugin-maturity-doc-lint.bats` — 2 new shape-when-present tests covering `rollup_invocations_30d: int | null` and `bootstrapping: bool` shapes. Now 13 tests (up from 11).
  - `docs/problems/open/269-...md` — Description amendment per architect Adjustment E naming both fields with the AND-gated predicate citation.
  - Retroactive rollout (separate commit per architect Adjustment C): re-ran populate + render against the live monorepo. All 11 plugins' `plugin.json` now carry the two new rollup fields (additive-within-2.0); 7 plugins' README compound-rendering activated; 4 plugins unchanged (already at the rendered shape).

  Architect verdict (P269 implementation pre-edit 2026-05-18) PASS with 5 adjustments folded in (in-place amendment over new ADR; additive-within-2.0; two-commit shape; behavioural tests; both fields in scope). JTBD verdict PASS — restores the JTBD-302 honesty signal (bootstrapping-window evidence is the load-bearing calibration anchor).

  Single multi-package patch changeset per ADR-021 — declares all 11 monorepo plugins because the populate rerun adds the two new rollup fields to every plugin.json (additive, but per-package source change per P141 changeset-discipline-hook precedent set by the §Amendment 2026-05-18 P0 hotfix `3cfa6fc`).

  Closes P269 — restores compound rendering across all bootstrapping-window plugins. P087 closure path advances: this was the last named outstanding-question on P087.

## 0.8.2

### Patch Changes

- 3cfa6fc: **P0 hotfix**: Phase 3 retroactive rollout (d33bb7d, shipped as @windyroad/itil@0.35.1 + 10 sibling plugins) wrote per-surface maturity records at top-level `plugin.json` keys (`skills:` / `agents:` / `hooks:` / `commands:`). Claude Code's plugin manifest validator rejects that shape with `Validation errors: hooks: Invalid input, skills: Invalid input`. All 11 plugins were unparseable by `claude plugin install`.

  **Fix** (ADR-063 Amendment 2026-05-18): per-surface maturity records nest UNDER the top-level `maturity:` key at `plugin_doc.maturity.<kind>.<name>`. Schema version bumps to "2.0" (path move is NOT additive per ADR-058 §Confirmation #8). Populate script (`packages/itil/scripts/plugin-maturity-populate.sh`) writes to the new nested location; render script (`packages/itil/scripts/plugin-maturity-render.sh`) reads from the new nested location. Defensive cleanup of legacy top-level keys on re-runs. Bats fixtures (populate + render + drift) updated to new shape — 17 + 17 + 14 green. Manifest fix-up applied to all 11 affected plugin.json files.

  **Hotfix-class bypass** per ADR-013 Rule 5 (reducing — closes a defect that broke `claude plugin install` for all adopters).

## 0.8.1

### Patch Changes

- d33bb7d: P087 Phase 3 — retroactive maturity rollout across all 11 `@windyroad/*` plugins. Each plugin's `plugin.json` now carries a populated `maturity:` field per top-level surface (skills, agents, hooks, commands) plus a `{schema_version, band}` rollup on the plugin root entry per ADR-063 §plugin.json field schema. Each plugin's README now carries a prose-woven rollup badge (`*Maturity: <Band>.*`) in the value-framing lead prose line per ADR-051 anti-pattern + ADR-063 §README badge rendering format.

  Mechanical activation of Phase 3a (`wr-itil-plugin-maturity-populate`) and Phase 3b (`wr-itil-plugin-maturity-render`) against the live monorepo. Bootstrapping window active (suite-oldest surface 39 days shipped, less than 60-day threshold per ADR-053 §Bootstrapping clause); most surfaces land at Experimental with one Alpha bootstrapping surface (`wr-architect:agent` — meets the ≥100 invocations + ≥14 days criterion). Plugin root rollups all resolve to Experimental per the worst-case granularity contract (ADR-053 §granularity contract).

  Drift detector (`wr-retrospective-check-plugin-maturity-drift`) reports 0 drift instances across all 12 packages — rendered badges match canonical records. Anti-pattern absence verified: no standalone `## Maturity` section, no shields.io URL, no compound bootstrapping rendering in per-skill cells (compound stays at rollup per ADR-063).

  Closes the P087 Phase 3 retroactive mechanical rollout investigation task (P087 line 133). Activates the four Phase 3d JTBD outcome amendments shipped in P240: JTBD-302 maturity-band visibility, JTBD-007 maturity-band currency, JTBD-101 promotion-criteria visibility, JTBD-003 at-glance stability.

## 0.8.0

### Minor Changes

- b60f576: P170 Phase 2 Slice 2.5 — hook exemption globs for the governance-managed story-map + story surfaces (ADR-060 § Phase 2 amendment 2026-05-12 lines 481-496). Adds path-based exemptions for `docs/story-maps/**/*.html` and `docs/stories/**/*.md` across four PreToolUse enforce-edit hooks:

  - `packages/architect/hooks/architect-enforce-edit.sh` — case-statement exemption alongside existing `docs/problems/` and `docs/jtbd/` entries
  - `packages/jtbd/hooks/jtbd-enforce-edit.sh` — same case-statement exemption pattern
  - `packages/style-guide/hooks/style-guide-enforce-edit.sh` — exemption short-circuit BEFORE the `*.css|*.html|*.jsx|...` opt-in extension check
  - `packages/voice-tone/hooks/voice-tone-enforce-edit.sh` — exemption short-circuit BEFORE the `*.html|*.jsx|...` opt-in extension check; closes the empirical block documented at P170 line 297 (STORY-MAP-001 bootstrap rejected on first HTML write)

  `packages/risk-scorer/hooks/risk-policy-enforce-edit.sh` left untouched — it gates only `RISK-POLICY.md` and never fires on story-maps/stories paths, so no exemption is needed (the ADR's "5 hooks" framing is structurally inaccurate at this surface; documented in commit body).

  Behavioural bats coverage (per ADR-052) across all four hooks: 6 new test cases each in architect-enforce-scope + jtbd-enforce-scope (extending existing files); new style-guide-enforce-scope.bats (5 cases) + new voice-tone-enforce-scope.bats (6 cases). 159 total tests across the four affected plugins' hook suites pass with zero regressions.

  Unblocks Phase 2 Slices 3-6 (story-map skills) and Slice 14 (STORY-MAP-001 bootstrap migration) per architect finding 1 on the P170 Phase 2 Slice 3 design review 2026-05-12 — these slices were blocked because their behavioural bats fixtures must perform HTML writes that the unmodified hooks rejected outright. Takes effect for adopters (including this repo) after the next marketplace release cycle + `/install-updates` + session restart.

## 0.7.3

### Patch Changes

- 670929a: P170 / ADR-060 Phase 1 Slice 5 B8.T3 — RFC-002 T1: dual-pattern hook glob widening for `docs/problems/` migration

  `packages/architect/hooks/architect-enforce-edit.sh` and `packages/jtbd/hooks/jtbd-enforce-edit.sh` gain a sibling exemption pattern (`docs/problems/*/*.md` + `*/docs/problems/*/*.md`) alongside the existing flat-layout pattern (`docs/problems/*.md` + `*/docs/problems/*.md`). The dual-pattern shape is forward-compatible: the new pattern matches zero files today (the per-state subdirs do not exist yet); the existing pattern continues to exempt the current flat-layout ticket files.

  **Why this is the first sub-task of RFC-002**:

  ADR-031 § Hook exemption glob contract notes that the flat-layout pattern matches zero files post-migration (shell `*` does not cross `/`), so any subsequent commit that migrates ticket files would immediately trigger architect+jtbd edit-gate denials on its own transition bookkeeping (`git mv` + Edit + re-stage on a ticket file). ADR-031 originally required hook update + migration in ONE big landing commit to bridge this gap.

  ADR-014 single-purpose grain dominates that single-shot framing. T1 lands the dual-pattern as a separate ADR-014-grain commit BEFORE the migration; T6 (post-migration cleanup) drops the flat-layout half once T5's bulk migration verifies. The dual-pattern window spans T1 → T6 and bounds the transient layout-coexistence exposure flagged in JTBD-001 amendment-drift (per ADR-060 Reassessment criterion).

  **No current behaviour changes**:

  - Flat-layout ticket-edits continue to skip the architect+jtbd gate (existing pattern matches).
  - Per-state subdir ticket-edits (none today) would also skip the architect+jtbd gate (new pattern would match if such files existed).
  - All other file paths continue to enter the gate as before.

  **ADR-014 single-purpose grain check**: the commit changes one logical thing — the exemption-glob shape on the two enforce-edit hooks — across two package boundaries that share the same exemption contract. Per ADR-014 § "single-purpose" guidance, "one logical change across multiple files" satisfies the grain when the files share the contract being changed.

  **JTBD impact**:

  - **JTBD-001** (governance without slowing down) — neutral now; enables the directory-skimmability win when T5 ships.
  - **JTBD-101** (atomic-fix-adopter friction guard) — neutral; no new gate, no new prompt; dual-pattern preserves existing adopter behaviour.
  - **JTBD-006** (AFK orchestrator) — neutral; the hooks remain idempotent.
  - **JTBD-201** (tech-lead audit trail) — neutral now; enables the directory-as-audit-trail win when T5 ships.
  - **JTBD-301** (plugin-user no-pre-classification) — untouched.

  **Held-changeset window scope**:

  This entry lands under the ADR-060 § Confirmation criterion 6 atomicity contract — held alongside the Slice 4 entries (`wr-itil-p170-slice-4-b7-type-tag-bulk-migration.md` + `wr-itil-p170-slice-4-b7-capture-problem-type-prompt.md`) and the Slice 2-3 entries (`wr-itil-p170-rfc-framework-phase-1.md` + `wr-itil-p170-rfc-framework-phase-1-slice-3.md` + `wr-itil-p170-rfc-framework-phase-1-slice-3-second-half.md`). The full chain graduates atomically per architect finding 12 once RFC-001 reaches `closed` post-Slice-5 forward-dogfood (which RFC-002 itself drives to closure).

  **Out of scope (deferred to subsequent T-tasks)**:

  - T2: dual-tolerant SKILL.md glob updates across `manage-problem`, `work-problems`, `manage-incident`, `report-upstream`, `run-retro` (plus forward audit on `capture-rfc` + `manage-rfc` per architect advisory 2026-05-07).
  - T3: bats fixture audit + dual-tolerant assertions.
  - T4: `docs/problems/README.md` generation logic dual-tolerant.
  - T5: bulk migration commit (rename + ADR-031 proposed→accepted + ADR-022 / ADR-016 / ADR-024 amendments).
  - T6: drop dual-pattern compatibility post-verification.
  - T7-T11: Slice B adopter auto-migration (shared routine, manage-problem + work-problems integration, bats, ADR-014 commit-gate marker).

  Refs: RFC-002

## 0.7.2

### Patch Changes

- 1fe2cad: Gate markers now survive long-running Agent and Bash subprocesses (P111).

  A new PostToolUse hook (`*-slide-marker.sh`) fires on Agent and Bash tool
  completion in the parent session. If the parent already holds a valid gate
  marker, the hook touches it — sliding the TTL window forward — so the wall-
  clock time spent inside an Agent-tool subagent or a `claude -p` iteration
  subprocess no longer counts against the parent's TTL.

  The slide is bounded:

  - The hook only TOUCHES an existing marker. It NEVER creates one — creation
    still requires a real gate review with verdict parsing in
    `*-mark-reviewed.sh`.
  - The hook skips the touch when `tool_response.is_error` is true. A failed
    subprocess does not extend the parent's trust window.
  - For risk-scorer, only the score files (`commit`, `push`, `release`) are
    slid. The `*-born` markers are deliberately invariant under sliding so
    the 2×TTL hard-cap from P090 still bounds total marker life.

  This replaces the symptom-treatment of P107 (TTL bumped 1800s → 3600s) with
  the architectural fix per ADR-009's new "Subprocess-boundary refresh"
  subsection. Adopters who configured a non-default `ARCHITECT_TTL` /
  `REVIEW_TTL` / `RISK_TTL` envvar do not need to change anything.

## 0.7.1

### Patch Changes

- 5d367e9: P100 slice 1 — `jtbd-enforce-edit.sh` + `jtbd-eval.sh` extended to exempt `docs/briefing/*` from the JTBD edit gate, alongside the existing `docs/BRIEFING.md` exemption. Mirrors the architect plugin update so the new per-topic briefing layout works with both governance plugins installed. Scope bats test added.

## 0.7.0

### Minor Changes

- db104da: P095 — UserPromptSubmit hooks across all five windyroad plugins now emit the full MANDATORY instruction block only on the first prompt of a session; subsequent prompts emit a ≤150-byte terse reminder. Reclaims ~120KB / ~30k tokens per 30-turn session in a 3-active-hook project (~80% of the prior per-prompt hook preamble). Detection and enforcement semantics are unchanged — the `PreToolUse` edit gate remains the enforcement surface; only the reminder prose is gated.

  **New:**

  - Canonical helper `packages/shared/hooks/lib/session-marker.sh` with `has_announced` + `mark_announced` functions (empty-SESSION_ID fallback: no-op, never crashes).
  - Five per-plugin byte-identical copies at `packages/<plugin>/hooks/lib/session-marker.sh` for `architect`, `jtbd`, `tdd`, `style-guide`, `voice-tone`. Distributed via `scripts/sync-session-marker.sh` with `--check` mode + `npm run check:session-marker` + CI step per ADR-017 / ADR-028.
  - ADR-038 "Progressive disclosure + once-per-session budget for UserPromptSubmit governance prose" codifies the pattern, the marker-path convention (`/tmp/${SYSTEM}-announced-${SESSION_ID}`), the ≤150-byte per-prompt budget, the four-element terse-reminder shape (MANDATORY signal word + gate name + trigger artifact + delegation affordance), and the `tdd-inject.sh` dynamic-state carve-out.

  **Changed:**

  - `packages/architect/hooks/architect-detect.sh` — gates the full MANDATORY ARCHITECTURE CHECK block behind `has_announced "architect" "$SESSION_ID"`; subsequent prompts emit `MANDATORY architecture gate active (docs/decisions/ present). Delegate to wr-architect:agent before editing project files.` Absent-`docs/decisions/` branch unchanged.
  - `packages/jtbd/hooks/jtbd-eval.sh` — same pattern for the JTBD CHECK; terse reminder cites `docs/jtbd/ present` and `wr-jtbd:agent`. Absent-`docs/jtbd/README.md` branch unchanged.
  - `packages/tdd/hooks/tdd-inject.sh` — special case per ADR-038 carve-out: static prose (STATE RULES table, WORKFLOW, IMPORTANT) is gated; dynamic TDD state (IDLE/RED/GREEN/BLOCKED) and tracked test files list emit every prompt. No-test-script fallback branch unchanged.
  - `packages/style-guide/hooks/style-guide-eval.sh` — same pattern; terse reminder cites `docs/STYLE-GUIDE.md present` and `wr-style-guide:agent`.
  - `packages/voice-tone/hooks/voice-tone-eval.sh` — same pattern; terse reminder cites `docs/VOICE-AND-TONE.md present` and `wr-voice-tone:agent`.

  **Tests (bats):**

  - `packages/shared/test/session-marker.bats` — 9 unit tests for the helper.
  - `packages/shared/test/sync-session-marker.bats` — 6 drift-check tests.
  - `packages/architect/hooks/test/architect-detect-once-per-session.bats` — 8 behavioural tests.
  - `packages/jtbd/hooks/test/jtbd-eval-once-per-session.bats` — 8 behavioural tests.
  - `packages/tdd/hooks/test/tdd-inject-once-per-session.bats` — 8 behavioural tests, including the dynamic-state carve-out assertion.
  - `packages/style-guide/hooks/test/style-guide-eval-once-per-session.bats` — 7 behavioural tests.
  - `packages/voice-tone/hooks/test/voice-tone-eval-once-per-session.bats` — 7 behavioural tests.
  - Full suite: 735/735 green.

  Backward-compatible for consumers: first-prompt output is byte-identical to the pre-change behaviour; only the second+ prompts see the terse reminder. Downstream tooling that parses the MANDATORY block text (none known) would still see the full text on the first prompt.

  Closes P095. Transitions the ticket from `.known-error.md` to `.verifying.md` per ADR-022.

## 0.6.0

### Minor Changes

- 6dd6a77: **Breaking change for external adopters**: remove the `docs/JOBS_TO_BE_DONE.md` runtime fallback. Canonical JTBD layout is now `docs/jtbd/` only (ADR-008 Option 3 chosen 2026-04-20 per P019).

  **Who is affected**: any project still using the legacy single-file `docs/JOBS_TO_BE_DONE.md` layout. The JTBD gate, agent, and CI validation no longer consult the legacy file.

  **Migration**: run `/wr-jtbd:update-guide` — it is the **sole** component in the suite permitted to read `docs/JOBS_TO_BE_DONE.md`, and only for one-shot migration into the `docs/jtbd/` directory layout. After migration, the legacy file can be deleted (git history is the archive).

  **Runtime changes**:

  - `@windyroad/jtbd` eval hook no longer injects the "docs/JOBS_TO_BE_DONE.md" enforcement variant; missing `docs/jtbd/` triggers an update-guide recommendation.
  - `@windyroad/jtbd` enforce hook no longer exempts the legacy file and no longer falls back to it. On projects without `docs/jtbd/`, the gate blocks with a `/wr-jtbd:update-guide` suggestion.
  - `@windyroad/jtbd` mark-reviewed hook no longer stores a hash against the legacy file; it exits early when `docs/jtbd/` is absent.
  - `@windyroad/jtbd` agent description and lookup logic now reference only `docs/jtbd/`.
  - `@windyroad/architect` enforce hook no longer exempts `docs/JOBS_TO_BE_DONE.md` as a peer-plugin policy artefact (it is no longer a recognised governance artefact).
  - `@windyroad/architect` detect hook's "does not apply to" list no longer mentions `docs/JOBS_TO_BE_DONE.md`.

  **Documentation changes**:

  - ADR-008 amended: Option 3 "Directory-only, no fallback" added as the chosen option; Option 1 retained with dated rejection (2026-04-19) so the rationale chain is readable.
  - ADR-005 line 138 rephrased to reflect the single canonical path.
  - ADR-007 supersession note extended to call out the artefact-name change (format, not just structure).
  - `wr-jtbd:update-guide` SKILL.md documents the migration carve-out explicitly.
  - This repository's own `docs/JOBS_TO_BE_DONE.md` stub is deleted (it was a 5-line redirect with no unique content).
  - Bats tests in `jtbd-eval`, `jtbd-enforce-scope`, `jtbd-mark-reviewed`, and `architect-enforce-scope` inverted to assert the legacy-file path is not consulted.

## 0.5.2

### Patch Changes

- 6e7c2e4: Strengthen the `wr-jtbd:agent` output contract to forbid bare verdicts without remediation guidance (closes P037). The agent now treats the inline response as the primary authoritative channel and the `/tmp/jtbd-verdict` file as a subordinate internal signal. Every response must begin with a structured `JTBD Review: PASS | ISSUES FOUND | JOB UPDATE NEEDED | PERSONA UPDATE NEEDED` line and, on non-PASS verdicts, include file + line + issue + affected job + suggested fix. "FAIL" alone or a bare file list is now explicitly forbidden. Includes a 7-test doc-lint bats regression file.

## 0.5.1

### Patch Changes

- 8a15336: Fix `--update` flag failing with "Plugin not found" (P025). The `updatePlugin` command was missing the `@windyroad` marketplace suffix and `--scope project`, causing all `npx @windyroad/<pkg> --update` invocations to fail. The correct command is now used: `claude plugin update "<name>@windyroad" --scope project`.

## 0.5.0

### Minor Changes

- b7d6739: Add on-demand assessment skills (P020)

  New user-invocable skills per ADR-015:

  - `wr-risk-scorer:assess-release` — pipeline risk score on demand; pre-satisfies the commit gate
  - `wr-risk-scorer:assess-wip` — WIP risk nudge for the current uncommitted diff
  - `wr-architect:review-design` — on-demand ADR compliance review
  - `wr-jtbd:review-jobs` — on-demand persona/job alignment check

  All four skills are discoverable via `/` autocomplete and delegate to existing
  governance subagents. No hook gate changes; bypass marker is still written by
  the PostToolUse hook after the pipeline subagent runs.

## 0.4.0

### Minor Changes

- fe1b903: Gate markers now persist across prompts (ADR-009). Removed Stop-hook reset scripts from all 5 review plugins. Marker lifecycle is now governed entirely by TTL (30 min default, configurable via `*_TTL` env vars) + drift detection of policy files. Resolves P001 — reviews no longer need to re-run on every prompt. Note: this is a behaviour change; users who relied on fresh-review-every-prompt should set a shorter TTL.

## 0.3.1

### Patch Changes

- ec16630: Add project-root check to all enforce hooks (P004). Absolute file paths outside the current project (e.g., ~/.claude/channels/discord/access.json) are no longer gated — gates now only fire on files within the project root.

## 0.3.0

### Minor Changes

- 2b39c9e: Migrate JTBD plugin to docs/jtbd/ directory structure with per-persona directories and individual job files (ADR-008). Backward compatible with docs/JOBS_TO_BE_DONE.md.

## 0.2.1

### Patch Changes

- e6a916a: Fix chicken-and-egg bug where JTBD enforce hook blocked creation of docs/JOBS_TO_BE_DONE.md itself (P002)

## 0.2.0

### Minor Changes

- 93527a5: Broaden JTBD enforcement to all project files, not just web UI files. JTBD is a product-level concern that applies to any project type.

## 0.1.3

### Patch Changes

- 7ee97ba: Add README.md to every package and rewrite the root README with better engagement, problem statement, and project-scoped install documentation.

## 0.1.2

### Patch Changes

- eda2a15: Fix release preview to use pre-release versions (e.g., 0.1.2-preview.42) instead of exact release versions, preventing version collision with changeset publish.

## 0.1.1

### Patch Changes

- 3833199: Fix: bundle shared install utilities into each package so bin scripts work when installed via npx.
