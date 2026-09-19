# Problem 435: wr-risk-scorer gates hardcoded to home-repo shape — push-gate over-fires on non-npm repos, external-comms under-fires on static-site/deck content

**Status**: Known Error
**Reported**: 2026-07-06
**Priority**: 9 (Medium) — Impact: 3 × Likelihood: 3
**Origin**: inbound-reported (#235, #253)
**Effort**: M. WSJF = (9 × 2.0) / 2 = 9.0.
**WSJF**: 9.0 — (9 × 2.0) / 2 (Known Error multiplier applied 2026-09-19; Effort held at M)
**JTBD**: JTBD-101
**Persona**: plugin-developer

## Description

Two faces of one class — `wr-risk-scorer` gate scope is hardcoded to the home-repo (`windyroad/windyroad`) shape:
- **Over-fire (#235)**: `git-push-gate.sh` blocks bare `git push` telling the user to run `npm run push:watch`, which doesn't exist outside the home repo; the deny message cites pipeline/changeset/Netlify concepts absent in adopter repos — a gate with no path through it.
- **Under-fire (#253)**: `external-comms` scopes "external-facing prose" to gh issue/PR/advisory + npm + `.changeset/*.md`, missing static-site / deck content (`**/pages/**/*.astro`, `**/content/**/*.md(x)`), so factual claims shipped to a public site/deck go ungated (a credential overstatement shipped across ~8 commits).

## Symptoms

- Adopter without a pipeline: bare `git push` blocked with no actionable path.
- Adopter shipping a public site/deck: factual-claim edits never reach the external-comms gate.

## Workaround

Over-fire: push with an explicit remote and branch (`git push origin my-branch`). The gate already permits that shape as long as the branch is not `master`, `main`, `publish`, or `changeset-release/*`; only the bare form and the protected-branch forms reach the deny. Pushing an adopter's own default branch still has no path through.

Under-fire: run `/wr-risk-scorer:assess-external-comms` by hand before editing site or deck content. Nothing prompts for it, so this holds only while someone remembers.

## Impact Assessment

- **Who is affected**: adopters whose repo shape differs from the home repo (most).
- **Frequency**: push-gate every push; external-comms every site/deck edit.
- **Severity**: Medium — over-fire blocks a common action; under-fire leaks factual-claim risk.

## Root Cause Analysis

Confirmed 2026-09-19 by reading both hook sources.

Neither gate asks the repository what shape it is. Each carries a constant that happened to be true of the repository the gate was written in, and treats that constant as a property of every repository it will ever run in.

**Over-fire.** `packages/risk-scorer/hooks/git-push-gate.sh` matches bare `git push` and, unless the command names an explicit non-protected branch, denies with prose naming `npm run push:watch`. That script name is never looked up — it is a literal in the deny string. In a repository without it, every clause of the remedy is false: there is no `push:watch` to run, no pipeline to watch, no release PR, no test deploy, and no `publish` or `changeset-release/*` branch for the closing warning to be about. The reader is told to run a command that does not exist, and the only way to work out what the gate actually wanted is to open the hook.

The same file already demonstrates the correct shape two branches further down: the `gh pr merge` handler reads `package.json` and branches on whether a `release:watch` script is really there. That check is the pattern the push branch is missing, sitting in the same script.

**Under-fire.** `packages/shared/hooks/external-comms-gate.sh` (canonical; synced into risk-scorer and voice-tone) routes its `Write|Edit` surface through a single `case` that recognises `.changeset/*.md` and falls through to `exit 0` on everything else. `.changeset/*.md` is this monorepo's outbound authoring surface. It is not an adopter's. A repository whose outbound surface is a static site or a slide deck writes that content through `Write`/`Edit` to paths the case has never heard of, so the gate silently permits, and both the leak pre-filter and the prose review are skipped on the one content class most certain to be read by strangers. The reported case shipped a credential overstatement across roughly eight commits without a gate ever firing.

The two halves are the same defect read from opposite ends. A gate that decides relevance from home-repo signals fires where those signals are absent and stays quiet where an equivalent surface exists under a different name.

### Investigation Tasks

- [x] Confirm the push-gate deny names `push:watch` as an unconditional literal, never a lookup — `git-push-gate.sh`, bare-`git push` branch.
- [x] Confirm the same file already reads `package.json` for `release:watch` on the `gh pr merge` branch, so the shape-detection pattern exists in-script.
- [x] Confirm the external-comms `Write|Edit` case recognises only `.changeset/*.md` and exits 0 on every other path.
- [ ] Land the shape detection and the surface extension together — blocked, see Fix Strategy.

## Fix Strategy

Both halves resolve by making each gate read the repository instead of assuming it. The fix is the RFC-062 release row on STORY-MAP-008 ("A block names a remedy this repository can run"), activity D ("Hit one of its rules").

- **Shape detection.** One helper in `packages/risk-scorer/hooks/lib/risk-gate.sh` answering whether the invoking checkout defines a given npm script, read from that checkout's own `package.json` under the CWD `_enter_hook_cwd` already establishes. No path relative to this repository, so it resolves correctly in an adopter tree (ADR-049). The `gh pr merge` branch's inline duplicate of the same check collapses into it.
- **Over-fire.** The bare-push branch consults that helper before denying. Its posture is an open question — see below.
- **Under-fire.** The canonical external-comms gate gains a `site-content` surface alongside `changeset-author`, matched on the conventional static-site and deck layouts (`*/pages/*.astro`, `*/content/*.md(x)`, `*/slides/*.md(x)`, `*/_posts/*.md(x)`) with an adopter override so a repository that files its content elsewhere can say so. ADR-028's own out-of-scope clause pre-authorises adding surfaces to the canonical hook, so this half needs no new decision. Edit the canonical and re-run `scripts/sync-external-comms-gate.sh` (ADR-017).

**Release vehicle**: a `.changeset/*.md` bumping `@windyroad/risk-scorer` and `@windyroad/voice-tone` — the gate behaviour changes for every adopter of either.

### Blocked on

Architect review 2026-09-19 returned ISSUES FOUND. Three of the four block the implementing commit; the fourth is a trap to avoid when it unblocks.

1. **The bare-push narrowing's posture is an unrecorded choice with no pinned option.** Permitting silently is not the only shape, and is the one with the widest blast radius: the deny branch also covers `git push <remote> main`, and the `push:watch` branch is where `check_ci_status` and `check_risk_gate` run, so a silent permit leaves an adopter without a `push:watch` script with no push-side gate at all — in precisely the repositories this ticket exists to fix. The alternatives are to deny while naming the condition that must become true (which is what STORY-056's third acceptance criterion already asks for, and what the ratified `gh pr merge` sibling already does), or to detect the shape and permit only where the repository demonstrably has no pipeline and the target is not a protected branch. This needs a human decision before anything lands.

2. **STORY-056 is `draft`.** Its acceptance criteria are the over-fire fix. Under ADR-096 nothing is built from a draft story; it needs `draft -> accepted` via `/wr-itil:manage-story` first. Cheap rather than hard — under ADR-103 the approval surface is the map, and STORY-MAP-008 already carries confirmed oversight.

3. **The under-fire half has no story and no card.** The RFC-062 row carries STORY-056 (over-fire) and STORY-084 (`gh pr merge`, delivered), and STORY-056's own notes disclaim the other face. A second card on that row needs drawing, which ADR-103 permits without re-ratifying the map.

4. **The `site-content` surface will reproduce the P010 marker-key class unless handled.** `lib/external-comms-key.sh` strips YAML frontmatter for `changeset-author` and no other surface. Astro, MDX, Jekyll posts and deck markdown all routinely carry frontmatter, so the gate (hashing the whole `content`) and the mark hook (hashing the reviewed body) would key differently and the PASS marker would land where the gate never looks — a permanent deny after a passing review, the same failure recorded as P010 / P198 / #149. Either extend the strip to `site-content` or make the deny's wrapping instruction surface-specific, and cover it with a gate-key/mark-key round-trip test over a frontmatter-bearing fixture.

## Dependencies

- **Composes with**: P208 (CI-status check on push — assumes home-repo push:watch), P276 (external-comms over-fires on PASS-class edits — the opposite direction).

## Related

- Inbound issues #235 (over-fire), #253 (under-fire). Kept as one ticket: same root class (gate scope hardcoded to home-repo shape).

## Story Maps

| ID | Title | Status |
|----|-------|--------|
| STORY-MAP-008 | STORY-MAP-008: Have a plugin behave like a guest in my repository | draft |


## Stories

| ID | Title | Status |
|----|-------|--------|
| STORY-056 | STORY-056: Clear a block with a command my repository actually has | draft |
| STORY-084 | STORY-084: Land an ordinary pull request without running a release | accepted |
