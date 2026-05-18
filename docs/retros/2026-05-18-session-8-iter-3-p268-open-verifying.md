# Session 8 Iter 3 Retrospective — P268 Open → Verifying (readme-refresh-discipline leading-executable helper)

Date: 2026-05-18
Iter: session-8 iter-3 (`/wr-itil:work-problems` AFK orchestrator)
Ticket: P268 (P165 hook substring-matches `git commit` anywhere in Bash command, not just actual git commit invocations)
Transition: Open → Verifying (fold-fix per ADR-022 — fix and transition ride in one ADR-014 commit)
Commits:
- `287992d` — fix(itil): P268 readme-refresh-discipline leading-executable command-detect helper
- `ae6e049` — docs(problems): capture P272 + P273 + P274 + P275 — batched P268 sibling-hook sweep findings

Pipeline risk: commit=4 push=4 release=4 (Low — load-bearing PreToolUse hook + new shared lib, bats green across helper + hook + retrospective-sibling surfaces; reducing-bypass per RISK-POLICY.md as it closes P268).

## Briefing Changes

- Added: none.
- Removed: none.
- Updated: none.
- README index refreshed: none.

Iter introduced no new briefing entries — the substring-vs-invocation distinction is well-captured in P268's ticket Description and the new helper's header docstring; no cross-session signal needs the briefing tree. The iter-specific learnings flow into the sibling tickets P272-P275 and the helper's reusable shape.

## Signal-vs-Noise Pass (P105)

Skipped — iter retro scope. Cross-session signal-vs-noise sweep is owned by orchestrator session-wrap retro.

## Problems Created/Updated

- **P268 transitioned Open → Verifying** (commit `287992d`) — Fix shape B applied per ticket recommendation: new shared helper `packages/itil/hooks/lib/command-detect.sh::command_invokes_git_commit` (iterative prefix-strip + leading-token check). Consumed by `packages/itil/hooks/itil-readme-refresh-discipline.sh` (case-statement substring match `*"git commit"*` at lines 80-83 replaced with `command_invokes_git_commit "$COMMAND" || exit 0`). 28 helper bats fixtures + 10 P268-prefixed integration regression fixtures (all green). Architect PASS, JTBD review marker green, risk-scorer PASS (reducing-bypass closes P268), voice-tone PASS. Existing 29 readme-refresh-discipline fixtures unchanged and green; sibling retrospective-readme-jtbd-currency hook fixtures unchanged and green (19/19).
- **P272 captured** (commit `ae6e049`) — `itil-changeset-discipline.sh:78` shares the substring-match anti-pattern (deny-class). WSJF 3.0 / effort S.
- **P273 captured** (commit `ae6e049`) — `p057-staging-trap-detect.sh:65` shares the substring-match anti-pattern (deny-class). WSJF 3.0 / effort S.
- **P274 captured** (commit `ae6e049`) — `itil-rfc-trailer-advisory.sh:94` shares the substring-match anti-pattern (advisory-class). WSJF 3.0 / effort S.
- **P275 captured** (commit `ae6e049`) — `retrospective-readme-jtbd-currency.sh:126` shares the substring-match anti-pattern (advisory-class, cross-package — opens ADR-017 sync OR `packages/shared/hooks/lib/` promotion question). WSJF 3.0 / effort S.

## Tickets Deferred

_None._ Stage 1 mechanical ticketing fired for all 4 siblings inline via direct ticket-file Writes + README inline-refresh + ADR-014 batched commit at `ae6e049` per the 86f42e8 precedent ("capture P267 + P268 + P269 — batched session-7 follow-on tickets"). No SKILL-unavailable fallback path was exercised. Batching is one logical sweep (the P268 Investigation Tasks "Sweep sibling PreToolUse:Bash hooks" task) = one capture batch grain per ADR-014.

## Verification Candidates

| Ticket | Fix summary | In-session citations | Decision |
|--------|-------------|----------------------|----------|
| P268 | itil-readme-refresh-discipline.sh substring-match anti-pattern replaced with leading-executable-token check via lib/command-detect.sh helper (commits 287992d + ae6e049 batched capture follow-on) | `./node_modules/.bin/bats packages/itil/hooks/test/command-detect.bats` 28/28 green at iter turn 7; `./node_modules/.bin/bats packages/itil/hooks/test/itil-readme-refresh-discipline.bats` 39/39 green at iter turn 8 (29 pre-existing + 10 new P268-prefixed regression cases); `./node_modules/.bin/bats packages/retrospective/hooks/test/retrospective-readme-jtbd-currency.bats` 19/19 green at iter turn 9 (sibling-hook unchanged surface); `./node_modules/.bin/bats packages/itil/hooks/test/` 320/320 green at iter turn 10 (full plugin hook suite) | left Verification Pending — fix-released this iter (same-session verifying per P068 Step 4a exclusion). Cross-session multi-iter signal is required for close. |

## Pipeline Instability (P074)

| Signal | Category | Citations | Decision |
|--------|----------|-----------|----------|
| P165 hook fired on this very iter's `cat >> docs/problems/README-history.md` heredoc write at turn 12 because the heredoc body contained the literal phrase `git commit` — same defect P268 closes. Workaround: stage README inline first per the established orchestrator pattern. | Hook-protocol friction (recursive self-reference) | The append to README-history.md at iter turn 12 (line-3 P134 rotation step) contained the phrase `replaces case-statement substring match`; pre-P268 the cat would have been denied. Mitigation: the workaround (pre-staging README) is exactly what this iter's fix obviates going forward; the next retro write after release will be on the fixed surface. | recorded in retro only (not ticket-worthy) — P268 itself is the close-out for this signal; no new ticket needed. The recursive-self-reference observation is the load-bearing dogfooding signal that the fix is correct (the helper would have let this cat through). |
| 4 sibling hooks (P272-P275) share the exact same substring-match anti-pattern. The bug is class-wide, not per-hook — repetition signals that the substring-match shape is the wrong abstraction for "command invokes X". | Repeat-work friction (across hook surfaces) | `grep -n '*"git commit"*' packages/*/hooks/*.sh` at iter turn 4 returned 5 hits (P268's target + 4 siblings); each hit carries the identical case-statement shape. Class-of-defect is a single anti-pattern applied 5 times. | new tickets via direct capture (P272/P273/P274/P275 at commit `ae6e049`) — the class is closed in source by P268's helper; the sibling captures track each consumer-side refactor as its own one-concern ticket per ADR-014. |

JTBD currency advisory: skipped — iter retro scope; advisory fires on session-wrap retros only.

## Context Usage (Cheap Layer)

Skipped — iter retro scope. Per-iter context measurement is owned by orchestrator session-wrap retro per ADR-043 cheap-layer envelope.

## Ask Hygiene (P135 Phase 5 / ADR-044)

See companion file `docs/retros/2026-05-18-session-8-iter-3-p268-open-verifying-ask-hygiene.md`. Lazy count: 0. All category counts: 0. Iter ran under explicit "NEVER call AskUserQuestion mid-loop (P135 / ADR-044)" brief constraint; zero asks fired.

## Topic File Rotation Candidates

Skipped — iter retro scope. Tier 3 rotation owned by orchestrator session-wrap retro.

## Codification Candidates

| Kind | Shape | Suggested name / Target file | Scope / Flaw | Triggers / Evidence | Decision |
|------|-------|------------------------------|--------------|----------------------|----------|
| create | shared-helper-promotion | `packages/shared/hooks/lib/command-detect.sh` | The new `command_invokes_git_commit` helper lives under `packages/itil/hooks/lib/` because 4 of the 5 affected hooks are under `packages/itil/`. Sibling P275 (`packages/retrospective/hooks/retrospective-readme-jtbd-currency.sh`) cannot consume from `packages/itil/hooks/lib/` per ADR-002 self-contained-package invariant — needs ADR-017 sync OR promotion. Architect verdict on P268 explicitly named this as "a follow-up decision when the sibling-hook refactors land — not a precondition for this P268 commit". | P275's ticket carries the promotion-vs-sync decision in its `## Fix` section as Options A / B / C; P272/P273/P274 (all under `packages/itil/`) can consume in-place without promotion. | recorded in P275's Fix Strategy — decision deferred to that ticket's work-iter per ADR-014 one-concern boundary (the promotion happens in P275's refactor commit, not in P268's fix commit). |
| improve | hook-shape | The 4 sibling hooks (P272/P273/P274/P275 targets) | Each sibling carries the exact same `case "$COMMAND" in *"git commit"*) ;;` block followed by an `esac`-then-exit-0 control. The fix shape is mechanical: source the helper, replace 4 lines with 1. Behavioural bats follow the P268 regression-shape template (grep / sed / cat-heredoc / echo / `git log --grep` / `git commit-tree` boundary). | Each of P272/P273/P274/P275 lists the same 4 Investigation Tasks (apply helper, add bats, verify no regression on canonical surfaces, cite P268). Code-shape is parallel; ticket-shape is parallel; only the hook target varies per ticket. | recorded inline in each ticket's Fix section + Investigation Tasks. WSJF=3.0 each; first sibling to be worked sets the promotion decision (P275 likely — it's the cross-package one that forces the question). |
| improve | hook-helper-doc | `packages/itil/hooks/itil-readme-refresh-discipline.sh` docstring | The hook's `# Allow paths (exit 0 silently per ADR-045 Pattern 1):` block was updated to cite P268 + the new helper. Sibling hooks (P272/P273/P274/P275 targets) carry their own per-hook variants of the same allow-paths docstring; each sibling's refactor commit should update its own docstring to cite P268 in the same shape. | Editing the P268 target hook produced the pattern: "command does not invoke `git commit` as its leading-effective command — P268: leading-executable check via lib/command-detect.sh". The siblings will mirror this in their refactor commits. | recorded in each sibling ticket's Investigation Task "Update P165 hook comment block to document the narrowed surface" variant. |

## No Action Needed

- The substring-vs-invocation distinction was already documented in P268's ticket Description; this iter executed the documented Fix shape B. No new conceptual learning to add to the briefing tree.
- The iter-3-running-while-orchestrator-captures-P271 inter-process visibility (the brief explicitly noted this) was as expected — git state at iter start was clean against `origin/main`; the orchestrator's P271 capture landed on top of this iter's two commits without conflict.
- The 5-affected-hooks audit completed in a single grep at iter turn 4. No iterative discovery, no surprise. Sibling sweep was mechanical per the P268 Investigation Task.
- Zero-ask iter outcome demonstrates ADR-044 framework-resolution boundary working as designed at the iter-subprocess surface. The iter's only AFK-grade decisions (Fix shape selection — ticket-prescribed B; sibling capture batch grain — 86f42e8 precedent; promotion-vs-sync for the cross-package helper — deferred to P275's refactor work-iter) were all framework-resolved or precedent-resolved.
