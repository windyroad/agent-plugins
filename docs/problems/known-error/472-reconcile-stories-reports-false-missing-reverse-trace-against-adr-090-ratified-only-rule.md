# Problem 472: reconcile-stories reports permanent false MISSING_REVERSE_TRACE drift against ADR-090's ratified-stories-only rule

**Status**: Known Error
**Reported**: 2026-07-26
**Priority**: 8 (Medium) — Impact: 2 × Likelihood: 4 — derived at capture from the description per Step 4a. Impact 2: dev-tooling signal degraded and an agent that trusts it can be pushed into an ADR-090 violation; no shipped-package or adopter harm. Likelihood 4: fires on every AFK vehicle-authoring iteration from the moment the vehicle is authored until its story is ratified, and was observed on two consecutive iterations the same day.
**Origin**: internal
**Effort**: M — re-rated 2026-09-19 at the Open → Known Error transition (P047). Capture assumed one predicate in one script. The architect review added two surfaces the fix cannot land without: the `update-rfc-references-section.sh` write path (which would otherwise regenerate the forbidden row into the now-unwatched section) and a `story_declared_maps` accessor on the shared lib so the no-map bucket is not a second enumeration of what the lib already parses. Six files including two bats suites and a changeset. Divisor 2. Original capture rationale retained: S — derived at capture per Step 4a. One predicate in one script plus behavioural bats over two cases; grounded on the scope-shape of P312 (`reconcile-rfcs` spurious MISSING_REVERSE_TRACE from missing subdir traversal — same detector family, same symptom, single-predicate fix). P312 carries no `Actual Effort:` field, so per ADR-026 this citation grounds the scope shape, not a measured duration. WSJF = (8 × 1.0) / 1 = 8.0.
**WSJF**: 8 — (8 × 2.0) / 2, Known Error status multiplier 2.0 per P498, Effort M divisor 2 (re-rated 2026-09-19 at transition; was (8 × 1.0) / 1 = 8.0 at the 2026-08-21 review — unchanged value, changed inputs)
**JTBD**: JTBD-006
**Persona**: developer

## Description

`wr-itil-reconcile-stories docs/stories` reports `MISSING_REVERSE_TRACE STORY-053 in RFC-057 ## Stories` and `MISSING_REVERSE_TRACE STORY-052 in RFC-056 ## Stories`. Both are false.

ADR-090 forbids exactly the reverse trace the reconciler demands: an RFC may reference only ratified (`human-oversight: confirmed`) stories, and a story captured under AFK is born `human-oversight: unconfirmed`. RFC-056 and RFC-057 therefore both deliberately carry `stories: []` plus a narrative `## Stories` section stating why, and the architect explicitly confirmed that shape as correct during the P434 iteration (2026-07-26), citing RFC-056 as the precedent RFC-057 should mirror.

So the reconciler and ADR-090 disagree. The detector will report drift on every AFK-authored fix vehicle from the moment it is authored until its story is ratified — which is precisely the window the AFK ratification hold is designed to sit in, so the false positive is not an edge case but the normal state of every held vehicle.

Consequence: the reconciler's output cannot be used as a clean/dirty signal for the story tier during any AFK vehicle-authoring iteration. An agent that trusts it will either wire a reverse trace ADR-090 forbids — the real harm, since that makes an RFC reference an unratified story — or learn to discount reconciler output wholesale, which is the softer harm but costs the detector its value everywhere else.

## Symptoms

- `wr-itil-reconcile-stories docs/stories` emits `MISSING_REVERSE_TRACE STORY-<NNN> in RFC-<NNN> ## Stories` for a draft story whose RFC correctly carries `stories: []` per ADR-090. Observed 2026-07-26 for STORY-052/RFC-056 (the P433 vehicle) and STORY-053/RFC-057 (the P434 vehicle).
- The finding does not clear by any correct action: satisfying it violates ADR-090, and leaving it means the detector never reports clean while a vehicle is held.

## Workaround

Read the `MISSING_REVERSE_TRACE ... in RFC-<NNN> ## Stories` lines as advisory-only and check the named story's `human-oversight` field before acting: `unconfirmed` means the finding is false and must NOT be actioned. The reconciler's other finding classes (`STALE` rankings rows, `MISSING_REVERSE_TRACE ... in P<NNN>`, `... in JTBD-<NNN>`) are unaffected and remain trustworthy — this affects only the RFC-directed reverse-trace class.

## Impact Assessment

- **Who is affected**: developer running `/wr-itil:reconcile-stories` or the reconciliation preflight during any AFK vehicle-authoring iteration.
- **Frequency**: every AFK-authored fix vehicle, for the whole interval between authoring and story ratification.
- **Severity**: Medium (8) — degrades a governance detector into an unreliable signal and pushes toward an ADR-090 violation if trusted; dev-tooling only, no shipped-package harm.
- **Analytics**: 2026-07-26 — 2 of 2 fix vehicles authored that day reported the false finding (P433's and P434's).

## Root Cause Analysis

**Root cause (confirmed 2026-09-19).** `reverse_trace_pass` in
`packages/itil/scripts/reconcile-stories.sh` demands a `## Stories` row on the
parent for *every* parent a story's frontmatter claims, with no predicate on the
story. On the `rfcs` leg that demand contradicts ADR-090 as amended by ADR-103:
an RFC may reference only *approved* stories, and under ADR-103 a story is
approved exactly when every story map it names is ratified. So for an unapproved
story the row's **absence is correct**, and the detector reports correct work as
drift. The finding cannot be cleared by any compliant action, which is what makes
it permanent rather than merely noisy.

### Investigation Tasks

- [x] Confirm the reverse-trace predicate in the reconcile-stories script expects every story's ID in its linked RFC's `## Stories` section regardless of the story's ratification. **Confirmed** — the rfcs leg carries no predicate at all.
- [x] Gate the predicate on ADR-090. **Note — the original wording of this task ("suppress the finding for a story whose `human-oversight` is `unconfirmed`") predates ADR-103 (2026-08-07) and must NOT be implemented literally.** ADR-103 removed the story-level oversight marker; `lib/story-oversight.sh::story_is_approved` is the one ratification predicate, and reading a leftover story-level marker would revive the second approval surface ADR-103 deleted.
- [x] Behavioural coverage against fixture trees asserting emitted lines.
- [x] Check whether the sibling `wr-itil-reconcile-rfcs` detector carries the same ungated expectation in the other direction. **It does not** — its reverse trace is RFC ↔ problem (`## RFCs` on a problem ticket), and no ratification rule governs that pair. The failure class is absent there.

### Findings recorded, deliberately NOT fixed in this pass

1. **`update-rfc-references-section.sh` disagrees with its own contract.** Its header and ADR-060 line 288 both say `## Stories` is a *forward* trace projecting the RFC's own `stories:` array. The implementation instead reverse-indexes `docs/stories/*/STORY-*.md` on each story's `rfcs:` field. Fixing the divergence by projecting `stories:` was considered and rejected for this pass: a corpus audit found 8 of 23 approved (story → markdown-RFC) claims are present in the RFC's `## Stories` but absent from its `stories:` frontmatter, so the projection would drop those 8 rows and the reconciler would then report MISSING_REVERSE_TRACE on them with no mechanical repair — P472 re-created in the other direction. Gating the helper's population on `story_is_approved` closes the write path without the corpus churn.
2. **10 unapproved stories are already listed in RFC `stories:` frontmatter arrays** — a live ADR-090 / ADR-103 violation in the corpus. Not an open enforcement hole: `check-rfc-stories-ratified.sh` gates that class through the same predicate. It is a corpus-repair job, not a detector defect.
3. **First-match binding at `pfile="${matches[0]:-}"`** (reconcile-stories.sh) picks one file when an RFC id resolves to more than one markdown file. Owned by in-progress STORY-078. Worth inheriting alongside it: under ADR-103 the `[ -z "$pfile" ]` test is the branch that routes to the release-row leg, so a stale or duplicate `RFC-NNN-*.md` match does not merely read the wrong file — it **silently suppresses the row leg entirely**.

## Fix Strategy

Narrow the rfcs leg of `reverse_trace_pass` to the population ADR-090 actually
covers, and close the write path that would otherwise re-create the forbidden
row behind the newly-quiet detector.

1. `packages/itil/scripts/reconcile-stories.sh` — source `lib/story-oversight.sh`
   (BASH_SOURCE-relative, the P317 adopter-safe form). On the `rfcs` leg only,
   and only after the ADR-103 release-row branch has already returned (that leg
   stays ungated — ADR-095 compels the card onto the map at capture and ADR-103
   took cards out of the fingerprint basis), classify the story into three
   buckets: approved → check as today; names a map that is not ratified → skip,
   counted as `unratified`; names no map at all → skip, counted separately as
   `no-map`, because that is an ADR-095 corpus defect and must not hide behind an
   ADR-090 explanation. Memoise map ratification per run.
2. Emit one line to **stderr** naming the population checked and each skip
   bucket, so a reader of an exit-0 clean result can tell "checked and clean"
   from "skipped because out of scope". stdout stays drift-lines-only; exit
   codes 0/1/2 unchanged, since `/wr-itil:reconcile-stories` Step 1 redirects
   stdout to a file and parses it line by line.
3. `packages/itil/lib/story-oversight.sh` — add a `story_declared_maps`
   accessor returning the ids a story declares in both the inline and block
   frontmatter forms, so the bucket split, the map resolution and the memo keys
   all derive from the lib's one parse rather than a second copy of it.
4. `packages/itil/scripts/update-rfc-references-section.sh` — gate the `Stories`
   population on the same `story_is_approved` predicate. Without this the
   prescribed repair for a legitimate MISSING_REVERSE_TRACE regenerates the whole
   section from a reverse index and sweeps every unapproved sibling back in,
   turning a loud false positive into a silent true negative.
5. `packages/itil/skills/reconcile-stories/SKILL.md` — document the narrowed
   population and the stderr line; state that the remedy for an unapproved story
   is to ratify its MAP (ADR-103), never to hand-add the row.

**Reproduction test**: `packages/itil/scripts/test/reconcile-stories.bats` —
a fixture tree carrying an unapproved story whose markdown RFC's `## Stories`
omits it. RED before the change (exit 1 with `MISSING_REVERSE_TRACE`), GREEN
after (exit 0). Paired with the inverse case — an approved story missing from
its RFC's `## Stories` must still report — so the narrowing cannot be satisfied
by silencing the class.

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)
- **Composes with**: P463 (relevance-close evaluator over-fires on a bare citation read as fix-evidence), P461 (downstream evidence-scan over-firing without version-gating), P434 (capture writes unverified claims as fact). All four are the same class — a detector treating something that is not evidence as evidence — and P434's own ADR-100 records the general shape.

## Related

- **ADR-090** — the ratified-stories-only rule the detector contradicts; the authority that makes these findings false rather than merely noisy.
- **P312** (`docs/problems/closed/312-reconcile-rfcs-spurious-missing-reverse-trace-no-subdir-traversal.md`) — closest prior: the same `MISSING_REVERSE_TRACE` symptom on the sibling `reconcile-rfcs` detector, root-caused to missing subdir traversal. **Different root cause** (traversal vs an ungated predicate) so not a duplicate, but a reviewer should confirm that reading before treating this as new.
- **P417** (`docs/problems/known-error/417-stories-readme-rankings-done-never-reconciled.md`) — adjacent: the same script's rankings/Done render never being reconciled. Distinct concern (the render vs the reverse-trace predicate), but the two share a fix surface and a reviewer may prefer to fold this in as a second phase there.
- Captured via `/wr-itil:capture-problem` during the `/wr-retrospective:run-retro` Step 2b pipeline-instability scan of the P434 iteration (2026-07-26).
- **Hang-off-check not dispatched**: the Step 2b mechanical pre-filter surfaced **7** candidates sharing ≥1 signal (ADR-090 / RFC-056 / RFC-057 / STORY-052 / STORY-053 / `docs/stories`), above the ≤5 latency cap, so the fresh-context arbiter was skipped per the SKILL's candidate-cap short-circuit. The two candidates worth a human read are named above (P312, P417); re-evaluate the absorb-vs-sibling call at the next `/wr-itil:review-problems`.


## Stories

| ID | Title | Status |
|----|-------|--------|
| STORY-099 | STORY-099: A clean reconciler result means the tier really is clean | accepted |
