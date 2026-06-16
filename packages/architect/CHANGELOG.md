# @windyroad/architect

## 0.17.3

### Patch Changes

- bac08b1: fix(architect): fail-closed post-condition guard on the compendium-update-entry hook (P367)

  The `architect-compendium-update-entry` PostToolUse hook now verifies that its
  re-author of `docs/decisions/README.md` changed only the edited ADR's entry. Before
  patching it snapshots the ADR-id set, the `## ` section-header count, and a full
  backup; after patching it asserts the id-set is preserved (plus exactly the edited
  id when the ADR is new), the edited id appears once, and the section count is
  unchanged. On any deviation — a dropped entry (silent tail truncation) or a
  spurious id/section injected by a malformed subprocess emit — it restores the
  original README, warns in degraded mode, and does not stage, rather than shipping a
  corrupted compendium. Same non-blocking contract as the existing subprocess-failure
  path (ADR-078 criterion l).

## 0.17.2

### Patch Changes

- dcf85b4: Make the architect README-pairing commit gate reuse the shared command-detection helper instead of its own inline parser. The gate decides whether a Bash command is a real `git commit` invocation before it checks that a staged decision-record change is paired with its compendium update. The previous inline parser recognised a direct `git commit` and an environment-variable-prefixed one, but silently missed a commit prefixed with a directory change (`cd <path> && git commit`), so that shape slipped past the gate. The gate now delegates to the same helper the ITIL and retrospective gates use, which already handles directory-change and environment prefixes and is portable across the awk implementations shipped on Linux and macOS. Behaviour is otherwise unchanged: commands that merely mention the phrase "git commit" still pass, and `git commit-tree` is still treated as a different command.

## 0.17.1

### Patch Changes

- c0b5515: Fix hook tests that could hang indefinitely under a full `bats --recursive` run. The `architect-detect.sh` and `jtbd-eval.sh` hooks read their input from stdin (`INPUT=$(cat)`); the scope and eval tests invoked them with no stdin redirect, so when the suite inherited an open terminal `cat` blocked forever instead of receiving EOF. Each bare `run bash "$HOOK"` invocation now redirects stdin from `/dev/null`, matching the convention already used by the sibling hook tests, so the suite terminates reliably as a pre-push verify gate.

## 0.17.0

### Minor Changes

- ec21121: P337 / RFC-014 Phase 1 (Stories A+B+D, C-partial) — architect-on-edit compendium entries

  Replaces the programmatic generator-based compendium drift mechanism with a hook pair (ADR-078 Option 9):

  - **Story A** — new `PostToolUse:Edit|Write` hook `architect-compendium-update-entry.sh`. On every `docs/decisions/<NNN>-*.md` body edit, spawns `claude -p` (`wr-architect:agent`) to re-author that ADR's `README.md` compendium entry (replace-in-place / sorted-insert / section-migrate) and stages the README for same-commit pairing. Opt-out via `ARCHITECT_AUTO_UPDATE_COMPENDIUM=0`. Degraded-mode-warn never blocks the body edit.
  - **Story B** — new `PreToolUse:Bash` hook `architect-readme-pairing-check.sh`. Denies a git-commit that stages an ADR body without the README. Replaces the ADR-077 criterion (g) drift gate.
  - **Story D** — retire `architect-compendium-refresh-discipline.sh` (deleted + unregistered from `hooks.json`). Its `--check` generator-match is incompatible with LLM-authored entries — so A+B+D land atomically. The original RFC-014 dogfood-before-D sequence is corrected to A+B+D atomic swap (architect agent independently confirmed; deviation-approval queued for RFC-014 § Sequencing amendment).
  - **Story C (partial)** — generator gains an ADR-078 deprecation notice (criterion j); drift-gate bats test 2145 marked skip. Script kept as a backstop until full removal (gated on one-minor-version backstop window).

  20 new behavioural bats GREEN (Story A 9 + Story B 6 + registration/portability 5). Full architect hooks+scripts suite 162/164 GREEN (the 2 pre-existing failures relate to oversight-nudge counts and are unrelated to this work).

## 0.16.0

### Minor Changes

- 4459d38: P354 Phase 1: name the title-as-outcome convention for ADR filenames at the two ADR-authoring SKILL surfaces.

  `/wr-architect:create-adr` SKILL prose amended:

  - New Step 2a "Title-as-outcome convention (P354)" — ADR titles must name the decision outcome as a short noun phrase (GOOD: `marketplace-only-distribution`, `monorepo-per-plugin-packages`, `behavioural-tests-default-for-skill-testing`), NOT the question / option-pair being decided (BAD: `<X>-vs-<Y>`, `should-<Z>`, `whether-<Z>`, `<X>-or-<Y>`). At intake the derived slug is acceptable in either shape — the convention is enforced post-substance-confirm.
  - Step 2 dispatch table Title row points readers at the convention + the Step 5a retitle check.
  - New Step 5a mechanical retitle-after-decision check — after the substance-confirm marker write lands, if the on-disk filename slug matches a question-shape pattern (`-vs-`, `should-`, `whether-`, `-or-`), derive the outcome slug from the chosen-option short name via `derive_kebab_slug`, edit the H1, `git mv` the file. ADR-044 category-4 silent-framework — no AskUserQuestion fire (per P132 inverse-P078 guard). Sequence preserves `architect-oversight-marker-discipline.sh` semantics (marker-introducing Edit lands BEFORE `git mv`; subsequent H1 Edit allowed by hook's "old content already had marker" branch).

  `/wr-architect:capture-adr` SKILL prose amended:

  - Step 1 names the same title-as-outcome convention. At the capture surface the chosen Decision is pinned in `$ARGUMENTS` at invocation time, so the caller SHOULD supply an outcome-shaped Title; if the parsed slug is question-shaped, the skill emits an I2-isomorphic stderr advisory (advisory-only — no halt, no retitle; the canonical-outcome short-name is the caller's to author).

  Driver: user direction 2026-06-03 — _"ADR titles are supposed to be the short version of what was decided, so they are skimmable. Titles like this force the reader to read the document to find the details of what was decided."_ P354 captures the recurring authoring habit.

  Held in `docs/changesets-holding/` per ADR-042 Rule 2 (commit risk score 8/25 Medium above the 4/25 appetite — R009 SKILL-prose floor + R005 no-paired-release-coordination at this commit). Graduates per ADR-061 once Phase 2 paired-coverage (promptfoo Tier-A/B eval + behavioural bats for the title-as-outcome convention) lands and the residual risk drops to within appetite. Corpus currently has zero question-shaped titles (audit 2026-06-08); no historical sweep needed.

## 0.15.7

### Patch Changes

- cd8d04f: P324 Phase 4: paired promptfoo Tier-A/B eval for the `/wr-architect:create-adr` SKILL surface (6/6 GREEN, twice). New eval artefact at `packages/architect/skills/create-adr/eval/promptfooconfig.yaml` covers 6 ADR-authoring behavioural contracts — Step 2 derive-first dispatch for the Title field (ADR-044 category-4 silent-framework via the shared `derive_kebab_slug` helper; stderr advisory; no `AskUserQuestion`), Step 5 two-fire split (P339 + P340; substance-confirm precedes draft-quality review; substance-confirm gates the born-confirmed marker write while draft-quality does not), Step 5a brief-before-ID at the option-shape `AskUserQuestion` (P350-architect; substance precedes any bare `ADR-NNN` / `P-NNN` annotation), Step 5a born-confirmed marker write on substantive match (ADR-074 + ADR-066 amended P340 + P348; mismatch is a re-draft trigger not an override; AFK iter subprocesses write `human-oversight: unconfirmed` as the queue-and-continue equivalent), Step 5a retitle-after-decision mechanical pass (P354; ADR-044 category-4 silent-framework; H1 Edit lands BEFORE `git mv` to preserve `architect-oversight-marker-discipline.sh` hook semantics), and Step 2b multi-decision auto-split AUTO-DEFAULT carve-out (ADR-013 Rule 6 amended; authorised by ADR-044 category-4 because splitting is fully reversible via supersession and "split when in doubt" is the persona-correct safe heuristic for JTBD-006). Tier-B llm-rubric grader is the authoritative check for the negative-clause semantics (marker NOT written on mismatch; no AskUserQuestion fires on Title or retitle; auto-split does NOT halt) — same routing as the Phase 1 work-problems + Phase 2 review-problems + Phase 3 capture-problem precedents per the P012 reopen findings 2026-06-04. New `packages/architect/.npmignore` excludes `skills/*/eval/` from the published tarball (first eval-bearing release in the architect plugin — mirrors the precedent set by `packages/itil/.npmignore` for the itil plugin in Phase 1). Per ADR-061 Rule 4 evidence-floor: this paired-and-passing eval IS the per-class evidence that flips the R009 prose-surface modulator +1 → -1 for `create-adr`, making the held architect-plugin cohort (`docs/changesets-holding/wr-architect-p350-brief-before-id-discipline.md` + `docs/changesets-holding/wr-architect-p354-title-as-outcome-convention.md`) graduation candidates at the next cohort-graduation pre-check. Architect PASS + JTBD PASS (header annotation set: JTBD-001 / JTBD-006 / JTBD-007 / JTBD-101; ADRs cited: ADR-075 / ADR-061 / ADR-074 / ADR-066 / ADR-044 / ADR-013 / ADR-014).

## 0.15.6

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

## 0.15.5

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

## 0.15.4

### Patch Changes

- 5a1d26f: P215: architect-gate deny-reason now carries an explicit recovery directive. `check_architect_gate` exposes `ARCHITECT_GATE_REASON` per failure mode (no marker / TTL expired / drift detected) mirroring the sibling `REVIEW_GATE_REASON` pattern; `architect-enforce-edit.sh` and `architect-plan-enforce.sh` append the reason to the BLOCKED deny message so the agent sees a clear "Re-delegate to wr-architect:agent via the Agent tool (subagent_type: 'wr-architect:agent') to refresh the marker." directive without having to read source. Sibling `REVIEW_GATE_REASON` messages in `@windyroad/jtbd`, `@windyroad/voice-tone`, and `@windyroad/style-guide` review-gate.sh sharpened from vague "Re-run the X agent" to the same explicit re-delegation form for symmetry. Marker mechanics unchanged per ADR-009. 7 new behavioural bats green covering the three failure-mode branches plus the enforce-edit deny output. RFC-021 carries the fix per ADR-071.

## 0.15.3

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

## 0.15.2

### Patch Changes

- e197424: Substance-aware drift detection + atomic verdict-write for the governance gate libs. Closes P303 (architect-gate multi-decision-file deadlock — drift-relock facet) and P353 (hash-marker brittleness umbrella class root cause).

  The shared `gate-helpers.sh` lib (byte-identical across architect / jtbd / voice-tone / style-guide / risk-scorer) gains two helpers per the user-ratified contract (ADR-009 amendment 2026-06-06):

  - `_substance_hash_path` — normalises CRLF / trailing whitespace / trailing newlines before hashing. Trivial post-PASS edits (whitespace, line-ending) no longer invalidate the marker. Conservative boundary preserved: single-numeral edits and frontmatter-key changes are still treated as substantive (re-review fires) — fail toward MORE governance when in doubt.
  - `_atomic_mark_with_hash` — writes the marker + hash file as an atomic mktemp + rename pair. Either both files land or neither does. Closes the "marker doesn't land after PASS" failure mode P353 measured as ~12 subagent invocations + 3 `BYPASS_RISK_GATE=1` uses per 3-filing session.

  `review-gate.sh` (jtbd / voice-tone / style-guide) and `architect-gate.sh` route their drift check through `_substance_hash_path`; `store_review_hash` + `architect-mark-reviewed.sh` + `architect-refresh-hash.sh` route the verdict-write through `_atomic_mark_with_hash`. ADR-028 carries the cross-amendment for the external-comms gate. 25 new behavioural bats green across architect / jtbd / voice-tone / style-guide; 259/259 existing hook bats remain green.

## 0.15.1

### Patch Changes

- 159dbcd: P191 Phase 2: architect gate resolves docs/decisions from the project root, not the hook runtime CWD

  The architect PreToolUse gate had the same relative-path bug as the JTBD gate
  (P191 Phase 1) but FAILS OPEN — on the CWD misfire `[ ! -d "docs/decisions" ]`
  false-negatived and the gate silently went inactive, letting edits bypass
  architect review (a governance hole, worse than a fail-closed nuisance).
  Anchor every project-relative check on `PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$PWD}"`
  across architect-enforce-edit.sh, architect-plan-enforce.sh, architect-detect.sh,
  architect-mark-reviewed.sh, architect-refresh-hash.sh, and lib/architect-gate.sh.
  Fail-open on genuine docs/decisions absence is preserved. Carried by RFC-020.

## 0.15.0

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

## 0.14.1

### Patch Changes

- 3a0535f: P287: retire technical/user-business type classification from problems

  Per twice-confirmed user direction (2026-05-25 + 2026-06-02 "GET RID OF IT"), the `type: technical | user-business` axis is retired from `/wr-itil:capture-problem`. The axis was already redundant with RFC/Story persona-anchoring per ADR-060 Phase 4.

  **@windyroad/itil (minor)**:

  - `/wr-itil:capture-problem` SKILL: removed Step 1.5 Type classification (lexical-signal classifier + AskUserQuestion + stderr advisory); removed Rule 6 type-classification row; removed flag table rows for `--type=technical`, `--type=user-business`, `--no-prompt`; removed `**Type**:` line from Step 4 skeleton template; removed type-tag row from Composition table.
  - `/wr-itil:capture-problem` SKILL Step 1.5b (JTBD-trace + persona dispatch): decoupled from `type_value = user-business`; fires unconditionally; I12 hard-block retired (type-keyed JTBD-required halt no longer applies).
  - `packages/itil/lib/derive-first-dispatch.sh`: removed `lexical_classify_two_sided` function (no remaining consumer); synced from `packages/shared/derive-first-dispatch.sh` per ADR-017.
  - Behavioural fixtures: removed P185 classifier tests + stderr-advisory tests + flag-precedence tests + meta-recursive corpus test from `capture-problem.bats`; removed 4 `lexical_classify_two_sided` tests from `derive-first-dispatch.bats`; renamed `i2-no-type-branching.bats` → `no-type-regression-guard.bats` with positive-state assertions (no `**Type**:` field in tickets/template/SKILL; no `lexical_classify_two_sided` function; per-package lib sync intact); amended `capture-problem-step-1-5b-jtbd-trace.bats` I12 hard-block tests to assert the predicate never blocks (regression guard).
  - Mass-strip `**Type**:` body field from 347 docs/problems/\*_/_.md tickets (one-shot inverse of the original `migrate-problems-add-type.sh` migration; the original migration script is preserved in git history per architect verdict).

  **@windyroad/architect (patch)**:

  - `packages/architect/lib/derive-first-dispatch.sh`: byte-identical sync of the `lexical_classify_two_sided` removal from `packages/shared/derive-first-dispatch.sh` per ADR-017. No surface change in `/wr-architect:create-adr` (it never used the two-sided classifier).

  **Out of scope this iter (queued for user re-confirmation per ADR-074)**:

  - ADR-060 amendment substance: in-place strike of type-tag clauses (Decision Outcome item 1, I2 invariant body, I12 invariant body, Phase-4 type-keyed dispatch); decision on I12 replacement shape; Phase-4 persona/jtbd rework keyed off some other discriminator (or unconditionally). The ADR-060 body and the SKILL implementation are intentionally inconsistent until the amendment lands — this is the P287 trade-off the user accepted twice.
  - Clearing ADR-060 `human-oversight: confirmed` marker.
  - JTBD-008 line 31 amended in this changeset to strike `type: user-business` clause; JTBD-201/JTBD-301 verified unaffected per JTBD agent review.

  P287 transitions Open → Known Error per ADR-022; Verification Pending transition follows next release.

## 0.14.0

### Minor Changes

- 300d5da: ADR-080: `bin/wr-architect-*` shims now resolve to the highest-version cached sibling at every invocation (was: dispatch to own scripts/). Closes P343 mid-session staleness — `/install-updates` mid-session no longer requires Claude Code restart for shim resolution to pick up the new version. Source-monorepo execution is preserved via a source-repo guard that falls through to `$(dirname "$0")/../scripts/<name>.sh`. The `wr-architect-<kebab-script-name>` naming grammar is unchanged.

## 0.13.0

### Minor Changes

- 4a36ae1: P339 + P340: `/wr-architect:create-adr` Step 5 now splits the bundled "review pass" `AskUserQuestion` into two separate fires — (5a) substance-confirm fire and (5b) optional draft-quality review fire — closing the bogus-ratification class where a "Yes" answer to a draft-quality question was being treated as substance-ratification and landing the `human-oversight: confirmed` marker on substance the user had never explicitly affirmed (ADR-078 commit 5196e3d exemplar; user correction 2026-05-31 _"I never approved the scripted extraction"_ + _"How did that ADR skip ratification?"_).

  The new Step 5a encodes the substance-confirmation interaction pattern pinned by user direction 2026-05-31: briefing in main-turn prose BEFORE the `AskUserQuestion` fires; `AskUserQuestion` is option-shaped not yes/no (each considered option is a selectable option); no IDs (`ADR-NNN` / `P-NNN` / `JTBD-NNN` / `RFC-NNN`) as explainers; user can make an informed decision without external document lookup. The born-confirmed marker writes ONLY when the substance-confirm answer selects a specific option matching the draft on disk; mismatch triggers a re-draft + re-fire (not a soft warn-and-proceed). Step 5b (draft-quality review) is separate, optional, and does NOT gate the marker.

  ADR-064 § Decision Outcome carries the five interaction-pattern requirements as a 2026-05-31 amendment extending the 2026-05-27 ADR-074 amendment. ADR-066 § Decision Outcome item 5 carries the marker-write-only-on-substantive-answer tightening as a 2026-05-31 amendment. Both amendments retain `human-oversight: confirmed` (mechanism tightening, not substance change). Closes P339 (subsumed) + P340.

### Patch Changes

- a1939e7: P181: `packages/architect/hooks/architect-mark-reviewed.sh` verdict-classification grep now anchors to the canonical heading shape from `packages/architect/agents/agent.md` "How to Report" — `^[[:space:]]*>?[[:space:]]*\*\*Architecture Review: (PASS|ISSUES FOUND)\*\*` — replacing the literal-substring `grep -q "ISSUES FOUND"` that matched anywhere in agent output. Body prose that narratively references the ISSUES FOUND verdict (e.g. a NEEDS DIRECTION response distinguishing itself from ISSUES FOUND, or a PASS response noting non-blocking follow-ups in adjacent files) no longer false-positives FAIL → silent marker-drop → next-edit lockout. Optional `> ` blockquote prefix tolerated. New behavioural bats fixture (`packages/architect/hooks/test/architect-mark-reviewed-verdict-grep.bats`) exercises canonical PASS / ISSUES FOUND headings, the two P181 substring-false-positive scenarios, blockquote-prefixed headings, and the PASS-precedence rule. Sibling mark-reviewed hooks (jtbd, style-guide, voice-tone) use a separate `/tmp/<name>-verdict` file mechanism and are not affected. Closes P181.

## 0.12.2

### Patch Changes

- 252702a: ADR-077 Slice 3 — close the two remaining Confirmation items deferred from Slice 2 (commit 9832593).

  **(f) `/wr-architect:review-decisions` integration.** New Step 4.5 + amended Step 5 stage list: after the drain's Confirm/Amend/Reject writes land, regenerate `docs/decisions/README.md` via `wr-architect-generate-decisions-compendium` and stage it with the batch. Mirrors the regen + stage-with-commit pattern shipped in Slice 2 for `/wr-architect:create-adr` Step 5 and `/wr-architect:capture-adr` Step 4.5. Defer-only batches skip the refresh. Confirm projects the `human-oversight: confirmed` badge; Amend refreshes the substance projection (primary drift surface this closes); Reject/supersede projects the `rejected-pending-supersede (P<NNN>)` badge per P316.

  **(g) CI drift-detection bats.** New `packages/architect/scripts/test/generate-decisions-compendium.bats` (13 behavioural tests). Asserts: the committed `docs/decisions/README.md` matches generator output for the current ADR bodies (load-bearing CI drift gate); generator idempotency on a fixture set; `--check` exit 1 on mutated ADR body + missing compendium; two-section split (in-force vs historical) honours `status:` frontmatter; deterministic header (no timestamp); per-entry shape; oversight badge + P316 rejected-pending-supersede badge projection. Defence-in-depth in case `architect-compendium-refresh-discipline.sh` fails open or is bypassed.

  Closes P327 (ADR bodies dominate session token usage) at the load-bearing slice — ADR-077 Confirmation items (a)–(j) all green. Token-load reduction (~40× on the routine architect-agent compliance path) now defended at three layers: skill-time regen (primary), PreToolUse commit hook (safety net), CI drift bats (audit trail).

- 3945878: P334: `generate-decisions-compendium.sh` is now byte-portable across BSD awk (macOS) and GNU awk (Linux). Two layered changes: (1) ASCII `...` instead of Unicode `…` (U+2026) for truncation markers, and (2) `export LC_ALL=C` at script top so both awks operate on raw bytes consistently (BSD already does by default; GNU under any UTF-8 locale was counting characters). Without (2), ADR bodies containing em-dashes / smart quotes still drifted because `length()` and `substr()` diverged at the truncation threshold. The committed compendium now matches on-machine regenerations on both platforms. CI test `committed compendium matches generator output (CI drift gate)` closes. Sibling: P328 (broader BSD-vs-GNU UTF-8 class — sidesteps the LC_ALL coupling at the caller layer by setting it script-internally).

## 0.12.1

### Patch Changes

- d1de917: Presentation rule for decision-confirmation prompts (P302). The `/wr-architect:review-decisions` Step 3 now directs the `AskUserQuestion` `question` field to lead with the one-line Decision Outcome ("This ADR decides: X"). Sibling-ADR relationships, supersession lineage, and Considered-Options recording-shape meta belong in a trailing clause or are omitted. Worked bad/good examples grounded in two 2026-05-25 drain re-asks (ADR-045, ADR-020) where the user couldn't tell what they were confirming. Applies ADR-074 _name the substance, not the grain_ to the confirm-prompt surface; extends ADR-026 grounding from artifact body to the `AskUserQuestion` `question` text.

  The mirrored rule in `/wr-jtbd:confirm-jobs-and-personas` (held in `docs/changesets-holding/p288-jtbd-persona-oversight.md`) ships with that drain skill's graduation; the agent-interaction briefing note generalises the rule to any decision-presentation surface (`docs/briefing/agent-interaction-patterns.md`).

## 0.12.0

### Minor Changes

- aef160c: ADR-066 marker vocabulary gains a third value: `human-oversight: rejected-pending-supersede` + companion `supersede-ticket: P<NNN>` scalar. The detector (`detect-unoversighted.sh`) and build-upon predicate (`is-decision-unconfirmed.sh`) treat the marker+ticket pair as ratified-equivalent — the `/wr-architect:review-decisions` drain stops re-asking ADRs the user explicitly rejected with a tracked supersede. The same grammar mirrors onto the JTBD sibling (`detect-unoversighted.sh` + `is-job-or-persona-unconfirmed.sh` + `/wr-jtbd:confirm-jobs-and-personas`). Compendium renderer surfaces the disposition: `**Oversight:** rejected-pending-supersede (P<NNN>)`. Closes P316.

## 0.11.0

### Minor Changes

- 9832593: ADR-077 Slice 2: compendium enforcement hook + two-section format + skill integrations.

  **Two-section compendium.** `docs/decisions/README.md` now splits ADRs into an **In-force decisions** section (`proposed` + `accepted` — the current rules to follow) and a **Historical decisions** section (`superseded` + `rejected` + `deprecated` — direction for what NOT to do, useful when a proposed change re-treads a path already tried). The status badge on each entry signals which kind it is. Both sections share the compact per-ADR format from Slice 1 (chosen option + confirmation criteria + relationship graph). All 75 ADRs in the dogfood repo are present (68 in-force, 7 historical).

  **Skills + agent are primary; hook is safety net.** `/wr-architect:create-adr` Step 5 and `/wr-architect:capture-adr` Step 4.5 now invoke `wr-architect-generate-decisions-compendium` after writing the ADR and stage `docs/decisions/README.md` in the same commit. The `wr-architect:agent` reviewer carries an explicit check for compendium freshness when reviewing ADR changes. These are the PRIMARY mechanism for keeping the compendium current.

  **Safety net: `architect-compendium-refresh-discipline.sh`.** New PreToolUse:Bash hook (mirroring the P165 `itil-readme-refresh-discipline.sh` pattern at the decisions surface) denies `git commit` invocations whose staged set includes a `docs/decisions/<NNN>-*.md` change but either (a) does NOT also stage `docs/decisions/README.md`, or (b) the staged compendium does not match the generator output for the current ADR bodies (stale). The hook catches edits that bypass the skill/agent flows — hand-edits via Edit/Write, off-skill bulk renames, direct file modifications. Override: `RISK_BYPASS: architect-compendium-deferred` in the commit message (intentional follow-up split) or `BYPASS_COMPENDIUM_REFRESH_GATE=1` env (batch/migration).

  **Generator gains `--check` flag.** `wr-architect-generate-decisions-compendium --check` writes to a temp file and diffs against the on-disk compendium. Exits 0 if up-to-date, 1 if stale (with a diff hint), 2 on directory error. Used by the enforcement hook to verify the staged compendium matches the working-tree ADR bodies without mutating any file. Idempotency contract preserved: same input bodies produce byte-identical output (sha1-verified across consecutive runs).

  ADR-077 amended in-place with both substance refinements (two-section format + skills-primary / hook-safety-net split). Next slice deferred: `/wr-architect:review-decisions` integration (regenerate on status transitions) + drift-detection CI bats.

## 0.10.0

### Minor Changes

- 846b5f2: `wr-architect:agent` now loads a compact generated `docs/decisions/README.md` **Decisions Compendium** for routine compliance review instead of every full ADR body (ADR-077; P327 inbound).

  For projects with many ADRs the load drops from N full bodies (~1.6 MB across 75 ADRs in the dogfood repo) to a single ~40 KB compendium — about a **40× reduction** in the routine architect-agent load path. The per-ADR body remains the authoritative substance (ADR-031); the compendium is a derived view carrying each ADR's chosen option, confirmation criteria, and relationship graph in one line each. Decision Drivers, Considered Options bodies, Pros and Cons, Consequences narrative, and Reassessment Criteria stay in the per-ADR body for deep-dive surfaces.

  - **Generator**: `packages/architect/scripts/generate-decisions-compendium.sh` (canonical body) + `packages/architect/bin/wr-architect-generate-decisions-compendium` (ADR-049 PATH shim). Idempotent — same ADR bodies produce byte-identical output.
  - **Architect agent prompt amended** (`packages/architect/agents/agent.md` Step 1) to read the compendium first; falls back to globbing `docs/decisions/*.md` when the compendium is absent (fresh installs, projects predating ADR-077). Deep-dive surfaces (`/wr-architect:create-adr`, `/wr-architect:capture-adr`, `/wr-architect:review-decisions`, explicit contested-change review) still load the full ADR body directly.
  - **Initial compendium** generated for the 75 dogfood-repo ADRs and committed.

  Enforcement machinery — a commit-time PreToolUse hook (`architect-compendium-refresh-discipline.sh` mirroring the P165 `itil-readme-refresh-discipline.sh` pattern) that denies commits staging ADR edits without a refreshed compendium, plus a CI drift-detection bats — lands in the next minor release alongside `/wr-architect:create-adr` / `/wr-architect:capture-adr` / `/wr-architect:review-decisions` skill integrations that author and refresh the compendium at decision time.

## 0.9.2

### Patch Changes

- e72a721: Architect flags changes built on an unratified ADR (ADR-074 surface 3, RFC-010, P318).

  The architect review (every file edit + plans via review-design) now emits a new [Unratified Dependency] verdict: when a change or plan explicitly cites or implements an ADR that lacks `human-oversight: confirmed` (unratified, and not superseded), it reports ISSUES FOUND with the action "ratify it via /wr-architect:review-decisions before this lands."

  - Keyed on the human-oversight marker, NOT on `status:` — building on a ratified ADR is fine even when its status is still `proposed` (status and oversight are orthogonal axes).
  - The agent performs the read-only equivalent of the is-decision-unconfirmed predicate via a frontmatter-scoped marker grep (it has Read/Glob/Grep, no Bash).
  - Bounded to explicit cite/implement (not transitive dependence); near-zero noise in steady state.
  - Closes the residual gap where work built on an unratified decision outside the ITIL propose-fix surface went unflagged.

## 0.9.1

### Patch Changes

- 476e419: Enforce confirm-substance-before-build (ADR-074, RFC-008, closes the P315 mechanical layer).

  A genuine ≥2-option decision the framework cannot resolve must have its **substance** human-confirmed before any dependent work is built on it — recording a born-`proposed` decision is not a licence to build on its unconfirmed substance.

  - **architect**: the Needs-Direction verdict now requires naming the _substantive_ choice, not a meta/grain framing question. New `wr-architect-is-decision-unconfirmed` predicate (PATH shim per ADR-049) + the `is-decision-unconfirmed.sh` script answer "is this referenced decision unconfirmed?" for the build-upon guard.
  - **itil**: `manage-problem` adds a substance-confirm-before-build guard at the propose-fix surface (ADR-060 I13) — surfaces the unconfirmed decision's substance via `AskUserQuestion` before building. `work-problems` queues it to `outstanding_questions` (category `direction`) under AFK rather than blocking or guessing.
  - **retrospective**: substance-confirm-before-build asks are classified as ADR-044 cat-1 `direction` and excluded from the lazy-AskUserQuestion regression metric (run-retro Step 2d + `check-ask-hygiene.sh`).

## 0.9.0

### Minor Changes

- 20cfe5f: Decision-oversight mechanism (P283 prong 2, ADR-066). The architect plugin now records human oversight on ADRs with a `human-oversight: confirmed` + `oversight-date` frontmatter marker (orthogonal to `status:`), detects unoversighted decisions with a token-cheap grep (`wr-architect-detect-unoversighted`), nudges at session start when decisions lack oversight, and drains the unconfirmed set via the new `/wr-architect:review-decisions` skill (confirm / amend / reject per ADR, in batches via AskUserQuestion). New ADRs are born oversighted — `create-adr` writes the marker on the Step 5 confirm. The session-start nudge self-suppresses inside AFK iterations; `@windyroad/itil` work-problems Step 5 now exports `WR_SUPPRESS_OVERSIGHT_NUDGE=1` so the nudge never fires into an absent-user subprocess (the paired sender for the hook's self-suppress receiver).

## 0.8.0

### Minor Changes

- d4367a7: Add a Needs-Direction verdict to the architect agent. When the architect detects a new decision with two or more viable options and no pinned direction, it now names the decision question and the candidate options instead of auto-picking one or asking in prose — and the main agent turns that into a structured AskUserQuestion before the decision is recorded. When direction is already pinned (a same-turn or same-session choice, an accepted ADR, RISK-POLICY.md, or a CLAUDE.md rule), the architect notes it and the agent acts without re-asking. The create-adr and capture-adr skills document the handoff, and a capture-adr skeleton now needs an AskUserQuestion confirm pass before it can be accepted. See ADR-064.

## 0.7.4

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

## 0.7.3

### Patch Changes

- 3cfa6fc: **P0 hotfix**: Phase 3 retroactive rollout (d33bb7d, shipped as @windyroad/itil@0.35.1 + 10 sibling plugins) wrote per-surface maturity records at top-level `plugin.json` keys (`skills:` / `agents:` / `hooks:` / `commands:`). Claude Code's plugin manifest validator rejects that shape with `Validation errors: hooks: Invalid input, skills: Invalid input`. All 11 plugins were unparseable by `claude plugin install`.

  **Fix** (ADR-063 Amendment 2026-05-18): per-surface maturity records nest UNDER the top-level `maturity:` key at `plugin_doc.maturity.<kind>.<name>`. Schema version bumps to "2.0" (path move is NOT additive per ADR-058 §Confirmation #8). Populate script (`packages/itil/scripts/plugin-maturity-populate.sh`) writes to the new nested location; render script (`packages/itil/scripts/plugin-maturity-render.sh`) reads from the new nested location. Defensive cleanup of legacy top-level keys on re-runs. Bats fixtures (populate + render + drift) updated to new shape — 17 + 17 + 14 green. Manifest fix-up applied to all 11 affected plugin.json files.

  **Hotfix-class bypass** per ADR-013 Rule 5 (reducing — closes a defect that broke `claude plugin install` for all adopters).

## 0.7.2

### Patch Changes

- d33bb7d: P087 Phase 3 — retroactive maturity rollout across all 11 `@windyroad/*` plugins. Each plugin's `plugin.json` now carries a populated `maturity:` field per top-level surface (skills, agents, hooks, commands) plus a `{schema_version, band}` rollup on the plugin root entry per ADR-063 §plugin.json field schema. Each plugin's README now carries a prose-woven rollup badge (`*Maturity: <Band>.*`) in the value-framing lead prose line per ADR-051 anti-pattern + ADR-063 §README badge rendering format.

  Mechanical activation of Phase 3a (`wr-itil-plugin-maturity-populate`) and Phase 3b (`wr-itil-plugin-maturity-render`) against the live monorepo. Bootstrapping window active (suite-oldest surface 39 days shipped, less than 60-day threshold per ADR-053 §Bootstrapping clause); most surfaces land at Experimental with one Alpha bootstrapping surface (`wr-architect:agent` — meets the ≥100 invocations + ≥14 days criterion). Plugin root rollups all resolve to Experimental per the worst-case granularity contract (ADR-053 §granularity contract).

  Drift detector (`wr-retrospective-check-plugin-maturity-drift`) reports 0 drift instances across all 12 packages — rendered badges match canonical records. Anti-pattern absence verified: no standalone `## Maturity` section, no shields.io URL, no compound bootstrapping rendering in per-skill cells (compound stays at rollup per ADR-063).

  Closes the P087 Phase 3 retroactive mechanical rollout investigation task (P087 line 133). Activates the four Phase 3d JTBD outcome amendments shipped in P240: JTBD-302 maturity-band visibility, JTBD-007 maturity-band currency, JTBD-101 promotion-criteria visibility, JTBD-003 at-glance stability.

## 0.7.1

### Patch Changes

- da1a3fe: P132 Phase 2a-iii-B: `/wr-architect:create-adr` Step 2 retrofitted as the 4th adopter of the shared derive-first dispatch helper. Canonical helper relocated from `packages/itil/lib/derive-first-dispatch.sh` to `packages/shared/derive-first-dispatch.sh` per ADR-017 (architect verdict: cross-package source would have violated the self-contained-published-package property). Synced per-package copies at `packages/itil/lib/` and `packages/architect/lib/`; new `scripts/sync-derive-first-dispatch.sh` (with `--check` mode) + `npm run check:derive-first-dispatch` + CI step + drift-detection bats. create-adr SKILL.md Step 2 rewritten from single AskUserQuestion-everything to 12-field derive-first dispatch table: silent-framework cat-4 on Title (kebab from prose), status=proposed, date=today, reassessment-date=today+3mo, Context-and-Problem-Statement (verbatim from `$ARGUMENTS`), consulted/informed defaults; cat-1 direction-setting retained on Decision Drivers, Considered Options, Decision Outcome, Consequences, Confirmation, decision-makers (architect verdict: no silent `git config user.name` derive — multi-party-decision mis-attribution risk). 13 new ADR-044-contract bats for create-adr; 7 new drift bats for sync; 2 new 4-surface assertions in derive-first-dispatch.bats. P132 transitions Known Error → Verification Pending per ADR-022 fold-fix. Phase 2b detection hook remains DEFERRED. Full suite green.

## 0.7.0

### Minor Changes

- b60f576: P170 Phase 2 Slice 2.5 — hook exemption globs for the governance-managed story-map + story surfaces (ADR-060 § Phase 2 amendment 2026-05-12 lines 481-496). Adds path-based exemptions for `docs/story-maps/**/*.html` and `docs/stories/**/*.md` across four PreToolUse enforce-edit hooks:

  - `packages/architect/hooks/architect-enforce-edit.sh` — case-statement exemption alongside existing `docs/problems/` and `docs/jtbd/` entries
  - `packages/jtbd/hooks/jtbd-enforce-edit.sh` — same case-statement exemption pattern
  - `packages/style-guide/hooks/style-guide-enforce-edit.sh` — exemption short-circuit BEFORE the `*.css|*.html|*.jsx|...` opt-in extension check
  - `packages/voice-tone/hooks/voice-tone-enforce-edit.sh` — exemption short-circuit BEFORE the `*.html|*.jsx|...` opt-in extension check; closes the empirical block documented at P170 line 297 (STORY-MAP-001 bootstrap rejected on first HTML write)

  `packages/risk-scorer/hooks/risk-policy-enforce-edit.sh` left untouched — it gates only `RISK-POLICY.md` and never fires on story-maps/stories paths, so no exemption is needed (the ADR's "5 hooks" framing is structurally inaccurate at this surface; documented in commit body).

  Behavioural bats coverage (per ADR-052) across all four hooks: 6 new test cases each in architect-enforce-scope + jtbd-enforce-scope (extending existing files); new style-guide-enforce-scope.bats (5 cases) + new voice-tone-enforce-scope.bats (6 cases). 159 total tests across the four affected plugins' hook suites pass with zero regressions.

  Unblocks Phase 2 Slices 3-6 (story-map skills) and Slice 14 (STORY-MAP-001 bootstrap migration) per architect finding 1 on the P170 Phase 2 Slice 3 design review 2026-05-12 — these slices were blocked because their behavioural bats fixtures must perform HTML writes that the unmodified hooks rejected outright. Takes effect for adopters (including this repo) after the next marketplace release cycle + `/install-updates` + session restart.

## 0.6.2

### Patch Changes

- d3468c4: P164 — apply `10#` base-10 prefix to next-ID formula across 6 ticket-creator skills to prevent latent octal-eval failure at the `099 → 100` ID transition

  **Bug shape**: The next-ID formula `next=$(printf '%03d' $(( $(echo -e "${local_max:-0}\n${origin_max:-0}" | sort -n | tail -1) + 1 )))` in 6 ticket-creator SKILL.md files passes its zero-padded ID string through bash's `$(( ... ))` arithmetic context. Bash treats leading-zero numbers as octal; `099` is invalid octal (digit ≥ 8) and bash emits `bash: 099: value too great for base (error token is "099")`, exiting non-zero before the skill writes its marker, before opening the file. The user sees a cryptic bash error.

  **Trigger**: latent until any ticket-creator surface's `local_max` returns `099`. Fires once per surface per project lifetime (the 099 → 100 transition). Has not yet fired in this repo because problem-ticket IDs already crossed 099 before this formula's shape solidified, but any new ticket-creator surface (or any adopter project today) hits the bug as soon as their backlog reaches 099 entries.

  **Fix**: standard `10#` base-10 prefix on the inner `$(echo ... | sort -n | tail -1)` expansion. Applied uniformly across all 6 affected SKILL.md (scope expanded from the originally-named 4 to 6 after grep verification per the ticket's Investigation Task):

  - `packages/itil/skills/manage-problem/SKILL.md` Step 3
  - `packages/itil/skills/capture-problem/SKILL.md` Step 2
  - `packages/itil/skills/capture-rfc/SKILL.md` Step 2
  - `packages/architect/skills/create-adr/SKILL.md` Step 3
  - `packages/architect/skills/capture-adr/SKILL.md` Step 2
  - `packages/risk-scorer/skills/create-risk/SKILL.md`

  **Regression coverage**:

  - `packages/architect/skills/capture-adr/test/capture-adr.bats` test 6 — synthetic `098-foo.proposed.md` + `099-bar.proposed.md` fixture asserts `local_max=099` and `next=100` cleanly without bash error.
  - `packages/itil/skills/capture-problem/test/capture-problem.bats` test 21 — synthetic `098-foo.open.md` + `099-bar.open.md` fixture asserts `local_max=099` and `next=100` cleanly without bash error.
  - Existing 26 bats updated in-place with `10#` prefix; full 28-test contract bats green.
  - Manual sanity check confirms unfixed formula fires the documented octal error and fixed formula returns `100`.

  **Why three packages in one changeset**: ADR-014 single-purpose grain — one logical change (the octal-eval defect) across three package boundaries that share the next-ID formula shape. Per ADR-014 "one logical change across multiple files / packages" guidance, the grain holds. The bats fixtures and SKILL.md edits are byte-symmetric across packages by design.

  **Shared helper deferred**: the ticket's optional Investigation Task to extract a shared `lib/next-id.sh` is deferred. DRY benefit is small (~6 byte-identical formulas) versus the regression risk of introducing sourcing-order coupling across 6 currently-independent skills. Re-evaluate if a 7th ticket-creator surface lands.

  **ADR alignment**:

  - ADR-014 (one ticket = one commit) — holds; one logical change.
  - ADR-019 (orchestrator preflight) — unaffected; preflight is about origin fetch, not ID computation.
  - ADR-031 (per-state subdir layout) — unaffected; formula input glob unchanged.
  - ADR-044 (decision-delegation contract) — aligned; one viable shape (`10#` is the standard bash idiom); scope-expansion from 4 → 6 is empirical evidence-driven (grep verified), exactly the framework-mediated mechanical action ADR-044 endorses.
  - ADR-052 (behavioural tests default) — aligned; new regression tests assert formula output not SKILL.md prose.
  - ADR-055 (namespace-prefixed IDs) — unaffected; no shipped-artefact IDs touched.

  **JTBD alignment**:

  - JTBD-301 (Report a Problem Without Pre-Classifying It) — primary; a cryptic `bash: 099: value too great for base` failure at ID rollover would break the "under 2 minutes or the report will be abandoned" constraint.
  - JTBD-001 (Enforce Governance Without Slowing Down) — composes; ticket-creator skills are the substrate that lets solo-developers and tech-leads create ADRs, problems, RFCs, and risks automatically.
  - JTBD-201 (Restore Service Fast with an Audit Trail) — composes; reliable next-ID computation is load-bearing for the audit trail.

  Refs: P164

## 0.6.1

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

## 0.6.0

### Minor Changes

- d28bd51: P156: ship `/wr-architect:capture-adr` skill — lightweight aside-invocation surface for ADR capture during foreground work

  Closes the heavyweight-only-capture-path gap on the architect plugin namespace (parent P014 ADR-032 child, sibling to P155's `/wr-itil:capture-problem`). The current ADR-creation surface is `/wr-architect:create-adr`, a ~10-15 turn ceremony designed for canonical new-ADR creation that walks Considered Options ≥2 (with pros/cons), Decision Drivers, full Consequences (Good/Neutral/Bad), Confirmation criteria, Pros/Cons of Options, Reassessment Criteria, plus a Step 5 confirm-with-user AskUserQuestion review pass. This is wrong for the **aside-invocation** use case where a foreground work session generates a decision worth recording but the agent / user can't afford the full ceremony.

  Three repeating patterns surfaced the friction:

  - **Mid-AFK-iter design decisions** — agent or user lands on a design choice during a foreground iter (e.g. iter 17 P137 Option C namespace-prefix; iter 19 ADR-056 Phase 2a back-channel write contract). The ~10-15 turn ceremony breaks iter cadence; decisions get buried inline in commit bodies or RCA sections.
  - **Architect-review verdict capture** — a `wr-architect:agent` review yields a substantive PASS-WITH-NOTES / ISSUES-FOUND verdict whose rationale deserves an ADR-shaped record. Today the verdict + rationale lands in commit messages and rots; future readers grep history but lose the structured trace.
  - **User-driven design conversations** — user resolves options (a)/(b)/(c) during conversational work; the settlement currently lives in a problem-ticket RCA section instead of a discoverable ADR.

  `/wr-architect:capture-adr` is the source-side fix.

  Adds:

  - `packages/architect/skills/capture-adr/SKILL.md` (~190 lines, ADR-038 progressive-disclosure budget). Steps 1-6: parse Title + 1-line Context + 1-line Decision from `$ARGUMENTS` (graceful-degradation on partial payload, halt-with-stderr-directive on empty); P056-safe `git ls-tree --name-only` next-ID formula reused from `create-adr` Step 3 (local_max + origin_max + 1); skeleton-fill MADR template with status `proposed`, full minimum frontmatter (sentinel `decision-makers: [unspecified — fill at canonical review]`, default `reassessment-date` 3 months from today), numbered-options placeholder `1. Option A (chosen) — <one-line>` + `2. (deferred — see /wr-architect:create-adr canonical review)` to preserve MADR ≥2-options surface for any doc-lint, deferred-flagged Decision Drivers / Consequences (Good/Neutral/Bad) / Confirmation / Pros-Cons / Reassessment Criteria; single Write; single commit `docs(decisions): capture ADR-<NNN> <title>` per ADR-014; trailing pointer to `/wr-architect:create-adr` for canonical expansion.
  - `packages/architect/skills/capture-adr/REFERENCE.md` — rationale (capture vs create trade-off; skeleton-MADR validity at status `proposed`; numbered-options placeholder rationale; frontmatter sentinel values vs truly minimal), edge cases (empty `$ARGUMENTS` halt, partial-payload graceful-degradation, title slug collision, ID collision with origin via P056-safe `--name-only`, captured-ADR-never-expanded path, architect-review-verdict capture pattern, cross-namespace consistency with capture-problem), composition with create-adr (auto-detect-and-expand path is follow-up scope) + wr-architect:agent (deferred-canonical-expansion contract; review fires at canonical expansion not at skeleton time) + capture-problem (compose for problem+decision capture in ~6-8 turns) + work-problems iter subprocesses (foreground-lightweight is AFK-compatible).
  - `packages/architect/skills/capture-adr/test/capture-adr.bats` — 12 behavioural tests per ADR-052: existence/wiring (SKILL.md + REFERENCE.md present, frontmatter declares `wr-architect:capture-adr`), next-ID formula (P056-safe mixed-suffix glob / empty-dir first-ADR / origin-collision-guard prefers origin_max when origin > local), skeleton-fill MADR shape (status proposed / decision-makers sentinel / Title at H1 / Context survives verbatim / Decision survives verbatim / deferred-flag literal pointer string / numbered-options placeholder), default reassessment-date 3 months from today, allowed-tools surface (no AskUserQuestion / Bash present / Write present), deferred-canonical-expansion contract presence; 12/12 green.

  Amends:

  - `docs/decisions/032-governance-skill-invocation-patterns.proposed.md` — appends "Foreground-lightweight-capture variant — capture-adr (P156 amendment, 2026-05-03)" section after the P155 amendment block. Names the new variant under the foreground-synchronous taxonomy distinguishing **full-intake** (`/wr-architect:create-adr`, ~10-15 turns) from **lightweight-capture** sub-variants (~3-4 turns) on the architect plugin namespace, symmetric with the ITIL plugin precedent. Documents the deferred-canonical-expansion contract (no inline architect-agent review handoff; review fires at canonical expansion). Pins variant-selection precedence (foreground-lightweight is LEAD post-P156; background-capture remains deferred sibling slot per P088). Files auto-detect-and-expand path as follow-up scope under P014.

  Architectural design (zero AskUserQuestion branches per ADR-044 framework-mediated mechanical-stage carve-out):

  | Decision                                                                           | Resolution                                                                                                                                                                            |
  | ---------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
  | Considered Options ≥2                                                              | Mechanical skeleton placeholder (`1. Option A (chosen)` + `2. (deferred — see /wr-architect:create-adr canonical review)`); MADR enforcement deferred to canonical-acceptance review. |
  | Decision Drivers / Consequences / Confirmation / Pros-Cons / Reassessment-criteria | Framework-policy deferred flag (literal pointer string `(deferred to /wr-architect:create-adr canonical review)`).                                                                    |
  | Reassessment-date                                                                  | Framework-policy default 3 months from today (matches create-adr Step 4).                                                                                                             |
  | decision-makers / consulted / informed                                             | Framework-policy sentinel `[unspecified — fill at canonical review]`.                                                                                                                 |
  | Multi-decision split                                                               | Out of scope; route to `/wr-architect:create-adr` Step 2b.                                                                                                                            |
  | Empty `$ARGUMENTS`                                                                 | Halt-with-stderr-directive (AFK-safe).                                                                                                                                                |

  Deferred-canonical-expansion contract:

  - capture-adr does **not** invoke the `wr-architect:agent` review inline (the create-adr Step 5 confirm-with-user AskUserQuestion pass is intentionally omitted).
  - Architect review fires when canonical expansion runs (`/wr-architect:create-adr <NNN>` or direct architect-agent delegation).
  - The architect-agent reviewing a `.proposed.md` skeleton sees `status: proposed` + deferred-flag literals and treats it as a not-yet-accepted ADR; reviews focus on whether the captured Decision conflicts with existing accepted ADRs.
  - Trailing pointer in Step 6 is the user-visible signal that canonical expansion is needed.

  Composes with:

  - ADR-032 (governance skill invocation patterns) — this skill is the foreground-lightweight-capture variant amendment 2026-05-03 for capture-adr.
  - ADR-038 (progressive disclosure) — SKILL.md + REFERENCE.md split shape.
  - ADR-044 (decision-delegation contract) — framework-mediated mechanical-stage carve-outs justify zero-AskUserQuestion design.
  - ADR-049 (bin/ on PATH) — capture-adr is self-contained (no shim needed; same as create-adr).
  - ADR-052 (behavioural-tests-default) — bats fixtures exercise primitives, not SKILL.md prose.
  - P155 (sibling capture-problem) — same shape, symmetric on the ITIL namespace; capture-on-correction OFFER pattern (P078) gains an `/wr-architect:capture-adr` companion.

  P157 (pending-questions-surface hook) remains Open under the same parent P014; ships in a subsequent iter.

## 0.5.2

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

## 0.5.1

### Patch Changes

- 5d367e9: P100 slice 1 — `architect-enforce-edit.sh` + `architect-detect.sh` extended to exempt `docs/briefing/*` from the architect edit gate, alongside the existing `docs/BRIEFING.md` exemption. Adopter projects that adopt the `docs/briefing/` tree layout (split-per-topic briefing introduced in P100 slice 1) no longer trip architect review on every retrospective append. Scope bats test added to assert the SCOPE prose advertisement.

## 0.5.0

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

## 0.4.1

### Patch Changes

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

- f9bfa56: Fix the next-ID origin-max lookup in `manage-problem` Step 3 and `create-adr` Step 3 (P056). The prior bash pipeline ran `git ls-tree origin/main <path>/ | grep -oE '[0-9]{3}'` — default `git ls-tree` output includes the 40-char blob SHA, whose hex run can contain three consecutive decimal digits that the regex falsely matches (observed `origin_max=997` on 2026-04-20 opening P055). The fix adds `--name-only` to drop mode/type/SHA columns and pipes through `sed` to strip the path prefix, so the anchored `grep -oE '^[0-9]+'` only picks up real filename IDs. ADR-019's next-ID invariant and P043's collision guard both presume this pipeline is sound; this change restores the invariant. Two new bats doc-lint tests (8 assertions) guard the contract.
- 3bf2074: Document the `git mv` + Edit + `git add` staging-ordering trap (P057) in `manage-problem` Step 7 and `create-adr` Step 6. `git mv` alone stages only the rename — subsequent `Edit`-tool modifications must be re-staged explicitly (`git add <new>`) before commit. Without the re-stage, transition commits capture the rename but drop the `Status:` / `## Fix Released` content edits, which then leak into an unrelated later commit and corrupt the audit trail (observed 2026-04-19 in P054's `.verifying.md` transition).

  Changes:

  - `manage-problem` Step 7: new warning block applying to all three transition arrows (Open → Known Error, Known Error → Verification Pending, Verification Pending → Closed), plus an explicit `git add <new>` line in each code block.
  - `manage-problem` Step 11: commit convention now recommends `git add -u` as a safety-net for tracked modifications.
  - `create-adr` Step 6: supersession rename now instructs authors to `git add` the file again after the frontmatter + "Superseded by" edits.
  - Two new bats doc-lint tests guard the contract in both SKILL.md files.

## 0.4.0

### Minor Changes

- b2f1646: Add runtime-path performance review to `wr-architect:agent` per ADR-023 (closes P046). When a proposed change touches HTTP cache directives, rate limits, throttles, response size, or per-request handler behaviour, the architect now MUST report a per-request cost delta (concrete units: ms, bytes), a request-frequency estimate (with cited source — ADR, JTBD, telemetry, or explicit "worst-case assumption"), their product as aggregate load delta, and a verdict against any in-scope `performance-budget-*` ADR. Qualitative phrases like "load is negligible" or "microseconds only" are now forbidden without concrete numeric backing. Includes a 9-test bats regression file enforcing the prompt wording. Rationale: the same architect agent reviews many downstream projects; a systemic blind spot for per-request cost trade-offs (addressr 2026-04-18 incident) affects every consumer.

## 0.3.2

### Patch Changes

- 359ec7c: ticket-creators: next-ID collision guard against origin (P043)

  Adds the next-ID collision guard from ADR-019 confirmation criterion 2 to
  both ticket-creator skills:

  - `manage-problem` step 3 (Assign the next ID): now computes max of
    local-max and `git ls-tree origin/<base>` max, then increments. Catches
    collisions between local work and parallel sessions before the ticket
    file is written.
  - `create-adr` step 3 (Determine sequence number): same mechanism applied
    to `docs/decisions/`.

  Both skills cite ADR-019 and log renumber decisions in the user-facing
  report. Sibling fix to P040 (work-problems Step 0 preflight, shipped in
  @windyroad/itil@0.4.2): preflight catches divergence at loop start; this
  ticket catches collisions at ticket-creation time as a defence in depth.

  Adds bats tests (3 assertions per skill) verifying ADR-019 references and
  the collision-guard pattern.

  Closes P043 pending user verification.

## 0.3.1

### Patch Changes

- 8a15336: Fix `--update` flag failing with "Plugin not found" (P025). The `updatePlugin` command was missing the `@windyroad` marketplace suffix and `--scope project`, causing all `npx @windyroad/<pkg> --update` invocations to fail. The correct command is now used: `claude plugin update "<name>@windyroad" --scope project`.

## 0.3.0

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

## 0.2.0

### Minor Changes

- fe1b903: Gate markers now persist across prompts (ADR-009). Removed Stop-hook reset scripts from all 5 review plugins. Marker lifecycle is now governed entirely by TTL (30 min default, configurable via `*_TTL` env vars) + drift detection of policy files. Resolves P001 — reviews no longer need to re-run on every prompt. Note: this is a behaviour change; users who relied on fresh-review-every-prompt should set a shorter TTL.

## 0.1.5

### Patch Changes

- ec16630: Add project-root check to all enforce hooks (P004). Absolute file paths outside the current project (e.g., ~/.claude/channels/discord/access.json) are no longer gated — gates now only fire on files within the project root.

## 0.1.4

### Patch Changes

- dbb2e79: Exempt peer-plugin policy files from architect gate (P009): docs/JOBS_TO_BE_DONE.md, docs/PRODUCT_DISCOVERY.md, docs/jtbd/, docs/VOICE-AND-TONE.md, docs/STYLE-GUIDE.md. Each plugin governs its own policy files — the architect should not re-gate them.

## 0.1.3

### Patch Changes

- 7ee97ba: Add README.md to every package and rewrite the root README with better engagement, problem statement, and project-scoped install documentation.

## 0.1.2

### Patch Changes

- eda2a15: Fix release preview to use pre-release versions (e.g., 0.1.2-preview.42) instead of exact release versions, preventing version collision with changeset publish.

## 0.1.1

### Patch Changes

- 3833199: Fix: bundle shared install utilities into each package so bin scripts work when installed via npx.
