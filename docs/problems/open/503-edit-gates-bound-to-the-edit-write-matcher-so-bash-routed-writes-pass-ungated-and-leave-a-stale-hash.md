# Problem 503: Edit gates are bound to the Edit|Write matcher, so Bash-routed writes pass ungated and leave a stale hash

**Status**: Open
**Reported**: 2026-08-20
**Priority**: 16 (High) — Impact: 4 × Likelihood: 4 — derived at capture. Impact 4: the load-bearing governance control is simply absent on one of the two ordinary write paths, so unreviewed edits enter the governed record, and the same gap corrupts the drift hash so honest writes are later denied for a cause the agent cannot attribute. Ships to adopters in five plugins. Likelihood 4: 187 occurrences in one transcript sweep, 166 of them in a single month, and it is the *default* write path in bypass-permissions sessions.
**Origin**: inbound-reported (#412) — stamped 2026-08-21 review from the upstream poll; upstream filing `wr-architect: edit gate binds to the Edit/Write tool, so Bash-routed edits of governed files bypass it`
**Effort**: M — derived at capture. The architect half is four lines (see below). The sibling plugins need matcher registration plus a Bash-command write-target parser, which is the real cost: deciding which file a `cat >` / `sed -i` / heredoc touches is not a one-line grep. Sized above P458's S because that fix was an exclusion line inside already-invoked scripts.
**WSJF**: 8 — (16 × 1.0) / 2 (added 2026-08-21 review)
**JTBD**: JTBD-001
**Persona**: developer

## Description

Every edit gate is bound to the tool name as a proxy for "a file changed". `packages/architect/hooks/architect-dispatch.sh` routes `pre-tool` to `architect-enforce-edit.sh` only under `case Edit|Write` (line 63); `packages/jtbd`, `voice-tone`, `style-guide` and `tdd` register their `*-enforce-edit.sh` on `"matcher": "Edit|Write"` directly in `hooks.json`.

A file write routed through the Bash tool fires none of them. A `cat > docs/decisions/050-….md <<'EOF'`, a `sed -i`, or a `python3 - <<'PY'` that rewrites an ADR body passes ungated.

The second half is the same root cause pointed the other way. `architect-dispatch.sh post-tool` routes `architect-refresh-hash.sh` and `architect-compendium-update-entry.sh` under the same `case Edit|Write` (line 84), so a Bash-routed edit also leaves the stored `docs/decisions/` substance hash stale against the changed corpus. The next ordinary Edit-tool call is then denied with "Decision drift detected" — for drift the agent cannot attribute to anything it did through a gated path.

A 2026-08-20 sweep of ~4,200 Claude Code transcripts found **187** Bash-routed writes into `docs/decisions/`, `docs/jtbd/` and `docs/story-maps/`, 166 of them in August 2026 — including whole ADRs created by `cat >` and amendments appended with `cat >>`. One `addressr` session (`5a2dfa08`, 2026-07-30) logged 141 such edits, took the spurious block on its next Edit, and recorded:

> Any bulk edit routed through Bash bypasses it. It only blocked me when I subsequently used the Edit tool. The same `Edit|Write` scoping applies to the PostToolUse hooks, so those silently did not fire either.

**Aggravating factor.** Sessions running in bypass-permissions mode are instructed by the harness to prefer `sed`, heredocs and short shell scripts over the Edit and Write tools. The ungated path is the default path in exactly the sessions that do the most unattended writing.

## Symptoms

- An ADR, JTBD file or story map is created or amended with no architect / JTBD / voice-tone / style-guide review and no gate denial.
- `docs/decisions/README.md` is stale against ADR bodies (the compendium hook never fired).
- A later, ordinary Edit is denied with "Decision drift detected" naming a corpus change the agent has no record of making through a gated path.

## Workaround

Route every write to a governed path through the Edit or Write tool. Nothing enforces this; it is a discipline, and it is contradicted by the bypass-permissions harness guidance.

## Impact Assessment

- **Who is affected**: every consumer of the five plugins, this repo and adopters alike. Worst in AFK and bypass-permissions sessions.
- **Frequency**: 187 observed occurrences across ~4,200 transcripts, 166 in August 2026 alone.
- **Severity**: two failure directions from one cause — ungoverned writes entering the record (control absent), and honest writes denied for invisible drift (control misfiring). The first is the serious one: the gate reports nothing, so its absence is indistinguishable from a pass.
- **Analytics**: 2026-08-20 transcript sweep of `~/.claude/projects` and `~/.codex/sessions`.

## Root Cause Analysis

### Preliminary Hypothesis

`Edit|Write` is a proxy for "a file changed", and Bash breaks the proxy. A gate bound to the intent (a write to a governed path) rather than to the tool that performs it would close both directions at once. The cost sits in the Bash branch: the hook receives a command string, not a file path, so the write target must be parsed or conservatively over-matched.

**Grounding note from hang-off arbitration:** the architect plugin **already** registers `Bash` at the `hooks.json` level (`"matcher": "Bash|Edit|Write|ExitPlanMode"`, line 12). For that plugin the gap is purely the inner `case` statement in `architect-dispatch.sh` — and the two halves of the fix sit four lines apart, at lines 63 (pre-tool gating) and 84 (post-tool refresh). The architect-side fix is therefore materially cheaper than the sibling plugins', which need matcher registration as well.

### Investigation Tasks

- [ ] Decide the detection shape for a Bash write: parse redirection and known in-place editors (`>`, `>>`, `tee`, `sed -i`, heredoc targets, `python -c`/`node -e` file opens), or conservatively deny any Bash command whose text names a governed path — and pick which errs safe
- [ ] Weigh gating vs. advising on the Bash path: a false-positive deny on a read-only `grep docs/decisions/…` is a new friction class, so the false-positive rate drives whether this is `deny` or `ask`/warn
- [ ] Extend the PostToolUse side symmetrically — a Bash-routed edit must refresh the architect hash and the compendium, or the ungated-write fix alone leaves the stale-hash half open
- [ ] Land the architect half first (the inner `case` at lines 63 and 84); it needs no matcher change and validates the shape before the four sibling plugins pay for it
- [ ] Raise with the harness owners that bypass-permissions guidance steers writes onto the ungated path
- [ ] Create a reproduction test: a `cat >` into `docs/decisions/` must be denied without a marker, and must refresh the hash with one

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)
- **Composes with**: P458, P353, P096, P469

## Related

(captured via `/wr-itil:capture-problem`; hang-off arbitration returned PROCEED_NEW)

- **P458** (`docs/problems/verifying/458-edit-gates-fire-on-git-internal-plumbing-paths.md`) — same five-hook family, **opposite failure direction and a different fix locus**. P458 is over-fire: the gate correctly intercepts a Write and then wrongly denies it because `.git/` was absent from the exclusion list; its released fix is an exclusion line *inside* the enforce-edit scripts. This is under-fire: the gate is never reached, because the dispatcher's `case` never selects the Bash branch, so the fix lands in the matcher/dispatch layer above the exclusion checks. Shared surface, not shared cause. The next `/wr-itil:review-problems` cluster pass should consider whether an edit-gate-correctness umbrella over P458 + this ticket is worth standing up.
- **P353** (`docs/problems/verifying/353-hash-marker-brittleness-class-external-comms-gate-highest-friction-surface-umbrella.md`) — shares only the symptom "spurious denial from a stale hash". P353's class cause is marker-key *derivation* (closed 2026-06-06 by `_substance_hash_path` + `_atomic_mark_with_hash`). Here the hash is correct for what it saw; `architect-refresh-hash.sh` simply never ran. Folding a matcher-scope cause into a Verification-Pending umbrella whose class fix is declared closed would reopen and dilute it — the same reasoning P469 already recorded against this candidate.
- **P096** (`docs/problems/verifying/096-pretooluse-posttooluse-hook-injection-volume-unaudited.md`) — its matcher inventory is descriptive context only. P096 concerns stdout bytes injected on pass vs deny; this ticket concerns which tool calls the matchers *select*, which P096's audit takes as given. Cross-reference, not a parent.
- **P469** (`docs/problems/open/469-style-guide-and-voice-tone-reviewers-spawn-without-bash-so-cannot-write-verdict-markers.md`) — points at Bash from the opposite side: Bash *absent* from a reviewer agent's `tools:` frontmatter so it cannot write its verdict file. Here the main agent *uses* Bash for file writes and thereby escapes the matcher. Different actor, different artefact, different fix locus.
- **P402** (reopened) and **P502** — the other two live marker-integrity failures surfaced by the same 2026-08-20 transcript sweep.


## Stories

| ID | Title | Status |
|----|-------|--------|
| STORY-082 | STORY-082: Gate Bash writes without blocking read-only commands | draft |
