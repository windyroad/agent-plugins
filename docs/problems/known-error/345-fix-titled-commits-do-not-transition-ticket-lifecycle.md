# Problem 345: Fix-titled commits do not transition the ticket lifecycle in the same commit grain — ticket stays Open across release + CI-verify + multiple intervening commits

**Status**: Known Error
**Reported**: 2026-05-31
**Priority**: 8 (Medium) — Impact: 2 × Likelihood: 4 = 8. Rated at review 2026-07-02: auto-K→V gap; fires every fix commit.
**Origin**: internal
**Effort**: M. WSJF = (8 × 1.0) / 2 = 2.0.
## Description

Recurring class: when fix code lands in commits titled `fix(<pkg>): P<NNN> ...`, the named ticket's lifecycle (Open → Known Error or Known Error → Verifying) is NOT transitioned in the same commit grain. The ticket stays Open across the release that ships the fix, across CI verification, and across N intervening commits — until a later session manually closes the lifecycle gap.

P334 evidence (this iter's witness):
- `3945878` "fix(architect): P334 awk substr Unicode portability — ASCII '...' for cross-platform compendium" — landed the awk-portability code; ticket stayed Open.
- `3e53a94` "fix(architect): P334 follow-up — LC_ALL=C wrap for compendium generator" — landed the byte-locale wrap; ticket stayed Open.
- `e9f7ce4` "fix(architect): regenerate compendium with @windyroad/architect@0.12.2 (unblocks CI test 2145)" — shipped compendium regen as part of `@windyroad/architect@0.12.2` release; ticket stayed Open.
- CI workflow "CI" green on commit `bad2eac` (main, run `26701674556`) — cross-platform drift gate test 2145 passes on Linux GNU awk; ticket stayed Open.
- This iter (session-9 work-problems AFK iter 1) was needed to manually close P334 despite all fix-shipping + CI-verification evidence being available 1+ day prior.

Why this matters: the ADR-022 Known-Error → Verifying auto-detection at release time has nothing to act on because the Open → Known Error transition never fires for fix-titled commits. The ticket lifecycle is effectively orphaned by the fix-without-paired-transition pattern.

Sibling class: P228 (`docs/problems/known-error/228-adr-022-known-error-md-verifying-md-transition-not-happening-consistently-at-release-time.md`) covers the K→V seam — this ticket covers the O→KE seam upstream. The session 8 wrap dispositions (`docs/retros/2026-05-30-work-problems-wrap-dispositions.md`) names the belt-and-braces direction on P228: "consider whether run-retro Step 4a or transition-problem release-path should belt-and-braces the K→V transition". This O→KE class is the upstream extension — the belt-and-braces design should cover BOTH seams (or whichever shape ends up unified).

Composes with: P206 (open `docs/problems/known-error/206-work-problems-iter-workers-dont-add-changesets-fix-commits-accumulate-without-release.md`) sibling-class on the changeset axis; P234 (closed) umbrella class for "defer-with-rationalization"; P335 inverse class (over-claim completion in ITERATION_SUMMARY).

Fix-strategy candidates (deferred to investigation):
- (a) Post-fix-commit advisory hook that diffs `fix(<pkg>): P<NNN>` commit titles against the named ticket's Status — emit advisory when fix-titled commits land without paired lifecycle transition.
- (b) Extend P228's belt-and-braces design surface (run-retro Step 4a or transition-problem release-path) to scan for `fix-titled-with-PNNN + ticket-still-Open` pattern at release time.
- (c) manage-problem-style commit hook that requires a paired lifecycle transition for any `fix(<pkg>): P<NNN> ...` commit.

## Investigation Findings (2026-06-16, work-problems AFK iter 26)

**The O→KE seam survives both sibling fixes that shipped since capture.** Two adjacent fixes have landed since P345 was captured (2026-05-31); neither touches this seam:

- **P228 (closed, `@windyroad/itil@0.49.4`)** wired the *downstream* K→V seam: `enumerate-postrelease-kv-candidates` (helper lib + `run-enumerate-postrelease-kv-candidates.sh` + ADR-080 bin shim) fires at work-problems Step 6.5 post-release. It acts **only on `.known-error/` tickets carrying `## Fix Released`** — it has nothing to act on while a fixed ticket is still `.open/`. This is exactly P345's own framing ("the ADR-022 K→V auto-detection has nothing to act on because the O→KE transition never fires for fix-titled commits"), now confirmed against the shipped implementation.
- **P314 / RFC-005 Phase 2 (`@windyroad/itil@0.50.0`)** wired the fix-time **RFC-trace** gate (`check-fix-rfc-trace.sh` predicate + manage-problem propose-fix gate + work-problems auto-create). It parses the propose-fix step, not commit titles, and gates *RFC presence*, not *lifecycle transition*. Orthogonal axis.

**The only existing O→KE auto-transition is body-documented, not commit-triggered.** `review-problems` Step 2 item 10 (SKILL.md line 53) auto-fires Open → Known Error **when root cause AND a workaround are documented in the ticket body** — it does NOT scan `fix(<pkg>): P<NNN>` commit titles. Verified: no hook or script under `packages/itil/hooks` or `packages/itil/scripts` matches a fix-titled-commit-vs-ticket-status detector (grep clean). So a `fix(<pkg>): P<NNN>` commit that lands code without the agent also editing the ticket body leaves the ticket Open until the ~24h review-problems cadence (and only if root-cause+workaround later get documented). The seam is genuinely unfilled.

**Load-bearing semantic finding — O→KE is NOT mechanically inferable from a fix-titled commit the way K→V is.** P228's K→V auto-fire is safe because "a release shipped" is an *observable fact*. O→KE is different: Known Error *asserts* "root cause known + workaround documented". A `fix(...): P<NNN>` commit does not establish that root cause was analysed — only that code claiming to fix the ticket landed. Auto-firing O→KE (candidate b) or hard-blocking the commit until a paired transition (candidate c) would therefore either assert Known-Error semantics without the root-cause evidence, or force the agent to fabricate it under commit pressure. This tilts the surface selection toward an **advisory** that surfaces the drift ("fix-titled commit for P<NNN> landed but P<NNN> is still Open — transition it or document why not") over an auto-fire or a hard gate. This is a genuine ≥2-option architecture decision (advisory vs auto-fire vs hard-gate × new-hook vs extend-existing), of the same load-bearing class P228 deferred to user ratification — so it is **queued, not built** this iter (ADR-074 substance-confirm; born-proposed, no ADR ratifies a surface).

**Re-rate guidance for next `/wr-itil:review-problems`** (placeholder left intact per Investigation Task #1's defer-to-review-problems contract; not applied here): the residual has narrowed since capture. Impact is internal/dev-tooling only (RISK-POLICY Impact 1–2 — the problem-ticket corpus, no published-package degradation; the original Impact 3 overstated it). Likelihood is reduced by ≥2 independent controls now in place — review-problems item 10 (~24h cadence), P228 K→V post-release self-heal, and the improved manual O→KE discipline visible across this session's iters (P172/P174/P179/P180/P251/P319 all transitioned O→KE in-iter). Suggested residual: Impact 2 × Likelihood 2 = 4 (**Low**), down from the Medium-labelled placeholder. Residual harm is bounded (self-healing on cadence), not durable orphaning.

## Symptoms

A `fix(<pkg>): P<NNN> ...` commit lands fix code, but the named ticket stays in `.open/` (or `.known-error/`) — no paired `git mv` + Status edit + README refresh in the same commit grain. The ticket then ages across the release that ships the fix, across CI verification, and across N intervening commits, until a later session (or the review-problems cadence) manually closes the lifecycle gap. P334 is the captured witness (evidence chain in Description).

## Workaround

In active use: (1) `review-problems` Step 2 item 10 auto-transitions O→KE once root cause + workaround are documented (~24h cadence); (2) P228's post-release K→V callback catches up `.known-error/` tickets stranded by earlier releases; (3) manual in-iter transition discipline (this session's iters demonstrate it). None *prevents* the drift at commit time — they *catch up* later, leaving a lag window.

## Impact Assessment

- **Who is affected**: maintainers/agents reading the backlog (stale Open status misrepresents lifecycle state); adopters of `@windyroad/itil` running the same lifecycle.
- **Frequency**: residual-low — the catch-up controls above fire on cadence; durable orphaning now requires a fix-titled commit landed outside work-problems AND no later body documentation.
- **Severity**: Minor — internal/dev-tooling hygiene; no published-package or installer effect (RISK-POLICY Impact 1–2). Self-healing on cadence.
- **Analytics**: P334 witness chain (Description); narrowed by P228/P314 shipping since capture.

## Root Cause Analysis

**Confirmed root cause**: there is no surface that maps the `fix(<pkg>): P<NNN>` commit-title signal to a lifecycle transition (or even an advisory). The sole O→KE auto-transition (`review-problems` Step 2 item 10) keys off *body-documented* root-cause+workaround, not commit titles; the K→V auto-fire (P228) keys off `## Fix Released` in already-`.known-error/` tickets. Fix-titled commits fall through the gap between these two surfaces.

### Candidate Fix Surfaces (surface selection QUEUED — substance-confirm-before-build, ADR-074)

Per the same load-bearing-decision discipline P228 applied (surface selection deferred to user ratification before SKILL/hook prose is authored), the surface below is **not built this iter**. The semantic finding above narrows the recommendation but does not authorise an unratified build under AFK.

1. **(a) Post-commit advisory hook (RECOMMENDED by the semantic finding)** — a PostToolUse:Bash hook mirroring `itil-rfc-trailer-advisory.sh`: parse `fix(<pkg>): P<NNN>` commit titles in the just-run `git commit`, look up each named ticket's on-disk state dir, and emit a stderr advisory when the ticket is still `.open/` with no paired transition in the same commit. Advisory-only (never blocks), consistent with ADR-040 declarative-first + ADR-013 Rule 6 fail-open. Pros: respects the semantic finding (surfaces drift without asserting Known-Error semantics or fabricating root cause under commit pressure); copy-and-retarget of an existing precedent; AFK-safe. Cons: advisory can be ignored; needs a per-commit title parse.
2. **(b) Extend P228's release-time belt-and-braces** — add an Open-ticket scan to `enumerate-postrelease-kv-candidates` (or a sibling enumerator) that fires O→KE for Open tickets named in release-drained `fix(...): P<NNN>` commits. **Weakened by the semantic finding**: O→KE asserts root-cause-known, which a fix-titled commit does not establish — mechanically auto-firing it risks a semantically empty Known Error. Distinct fix surface from P228's K→V (the two seams are NOT unifiable into one mechanical rule — K→V is observable-fact, O→KE is a knowledge assertion).
3. **(c) Hard commit gate requiring a paired transition** — PreToolUse:Bash gate that blocks a `fix(...): P<NNN>` commit unless it also `git mv`s the ticket. **Weakened by the semantic finding** (same reason as b) plus ADR-040 (prefer advisory over hard block) and the risk of forcing fabricated root-cause under commit pressure.
4. **(d) Co-locate with the P314 fix-time RFC-trace gate** (newly surfaced this iter) — the propose-fix gate (`check-fix-rfc-trace.sh` + manage-problem/work-problems wiring) already fires at the propose-fix step and already parses the fix context. A sibling predicate there could remind/require the lifecycle transition pre-commit. Pros: reuses an existing fire point; pre-commit timing. Cons: only fires inside manage-problem/work-problems (misses direct `fix(...)` commits outside those skills — exactly the residual class); couples two concerns on one gate.

**Reconcile against P234's `itil-fictional-defer-detect.sh`**: a *sibling* hook (not an extension) is the right shape if (a) is chosen — P234's hook keys off retro-prose defer-rationale within a ±5-line window on `docs/retros/*.md` writes; P345's signal is a commit-title vs ticket-state mismatch on a Bash `git commit`. Different matcher (Bash vs Write|Edit), different surface, different signal. The per-surface-config copy-and-retarget *pattern* transfers; the hook itself should not be overloaded.

### Investigation Tasks

- [ ] Re-rate Priority and Effort at next /wr-itil:review-problems (re-rate guidance recorded under Investigation Findings: Impact 2 × Likelihood 2 = 4 Low; placeholder left intact per defer-to-review-problems contract)
- [x] Investigate root cause — confirmed (2026-06-16): no commit-title→lifecycle surface exists; gap survives P228 (K→V only) + P314 (RFC-trace only); review-problems item 10 is body-documented not commit-triggered
- [ ] Create reproduction test — defer to build (rides the ratified surface)
- [x] Reconcile scope with P228 belt-and-braces direction (sibling K→V seam); decide unified-vs-separate fix surface — **separate** surface confirmed (O→KE = knowledge assertion ≠ K→V observable-fact; not unifiable into one mechanical rule)
- [x] Confirm whether P234's `itil-fictional-defer-detect.sh` advisory hook should be extended to cover this O→KE seam or whether a sibling hook is correct — **sibling** (different matcher/surface/signal; pattern transfers, hook should not be overloaded)
- [ ] **QUEUED for user ratification (ADR-074)**: pick the fix surface — (a) advisory hook [recommended by semantic finding] / (b) release-time O→KE auto-fire / (c) hard commit gate / (d) co-locate with P314 fix-RFC-trace gate. Then build under the ratified surface.

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)
- **Composes with**: P228 (sibling K→V surface), P206 (sibling changeset-discipline surface), P234 (closed; defer-with-rationalization umbrella)

## Related

- P334 (`docs/problems/closed/334-...`) — concrete witness of the pattern (this iter's evidence chain).
- P228 (`docs/problems/closed/228-...`) — sibling K→V class, **now CLOSED/shipped** (`@windyroad/itil@0.49.4`); confirmed to NOT cover the O→KE seam (acts only on `.known-error/` tickets). The belt-and-braces design did NOT unify both seams (semantic finding: K→V observable-fact ≠ O→KE knowledge-assertion).
- P206 (`docs/problems/known-error/206-...`) — sibling changeset-discipline class.
- P234 (`docs/problems/closed/234-...`) — umbrella defer-with-rationalization class.
- P335 (`docs/problems/open/335-...`) — inverse class: AFK iter over-claim in ITERATION_SUMMARY.
- ADR-014 single-commit grain.
- ADR-022 K→V at release time.
- `docs/retros/2026-05-30-work-problems-wrap-dispositions.md` — session 8 wrap, P228 belt-and-braces direction.
- Captured via /wr-itil:capture-problem on 2026-05-31 (work-problems AFK iter 1 retro).

## Change Log

- **2026-05-31**: Captured (work-problems AFK iter 1 retro). Placeholder Priority/Effort; fix-strategy candidates (a)/(b)/(c) deferred to investigation.
- **2026-06-16** (work-problems AFK iter 26): Investigation pass + **Open → Known Error**. Root cause confirmed — no `fix(<pkg>): P<NNN>` commit-title → lifecycle surface exists; the gap survives both fixes that shipped since capture (P228 K→V `@windyroad/itil@0.49.4` acts only on `.known-error/`; P314 RFC-trace `0.50.0` gates RFC presence not lifecycle); review-problems item 10 keys off body-documented root-cause+workaround, not commit titles. Load-bearing semantic finding recorded: O→KE asserts root-cause-known (a knowledge claim) and is NOT mechanically inferable from a fix-titled commit the way K→V (an observable release fact) is — this tilts the surface toward advisory (a) and confirms a *separate* (non-unified) fix surface from P228, and a *sibling* (not extended) hook from P234. Surface selection (a/b/c + newly-surfaced d) **QUEUED for user ratification** (ADR-074 substance-confirm; born-proposed, not built under AFK). Re-rate guidance recorded (Impact 2 × Likelihood 2 = 4 Low) but placeholder left intact per the ticket's defer-to-review-problems contract. O→KE justified by review-problems item-10 criteria now met (root cause confirmed + workaround documented). Recovery: `/wr-itil:transition-problem 345 open`.
