---
"@windyroad/itil": minor
---

P347 / ADR-079: Evidence-based relevance-close pass — Phase 2 (4 more evidence shapes + Phase 1 false-positive fixes + structured caveat + KEEP-WITH-NOTE).

`packages/itil/scripts/evaluate-relevance.sh` (Phase 1 driver of `/wr-itil:review-problems` Step 4.6) extends from one evidence shape to five, grounded in the 14-fixture labeled close-on-evidence set from the 2026-05-31 foreground relevance-scan. Phase 1's "file-no-longer-exists" shape covered 0 of 14 actual closes — necessary but not sufficient.

**User direction (verbatim, 2026-05-31)**: *"Amend the ADR and the implementation"* — pins Phase 2 substance per ADR-074 build-upon guard.

**Five evidence shapes (ADR-079 Phase 1 + Phase 2)**:

- Shape 1 — `file-no-longer-exists` (Phase 1, preserved verbatim).
- Shape 2 — `ADR-shipped-confirmed`: ticket body cites `ADR-NNN`; the ADR file exists AND its frontmatter has `human-oversight: confirmed`. 8 of 14 closes.
- Shape 3 — `named-skill-or-feature-exists`: ticket body references a SKILL.md / hook / agent / slash-command surface that exists in git. 6 of 14 closes.
- Shape 4 — `self-marker-in-body`: line-anchored regex against `Close to (Verifying|Closed)` / `DONE 2026-` / `## Fix Released` heading / `fix shipped session` / `awaiting K→V`. Anchored to line-start per architect advisory A2 to prevent mid-prose false-positives. Explicit in P289; contributory in P033.
- Shape 5 — `driver-child-ticket-closed`: `## Related` section cites a `P<NNN>` that lives in `docs/problems/closed/`. Suppressed when the child names an unbuilt SKILL/agent (architect advisory A1 — future work, not stale).

**Phase 1 false-positive fixes** (the iter-4 smoke-test 60% false-positive rate is structurally addressed):

- P180 — state-suffix detection: per-state subdirs (`open|known-error|verifying|closed|parked` for problems; `investigating|mitigating|restored` for incidents) AND `.<state>.md` suffix variants. If a state-suffix variant exists → `KEEP-WITH-NOTE`, not CLOSE-CANDIDATE.
- P244 — sibling-file detection: dir-glob the parent dir for files with similar slug-prefix (first 2 dash-tokens). Catches "work shipped under a different filename in the same dir" → `KEEP-WITH-NOTE`.
- P251 — rename detection via `git log --follow --diff-filter=AD --name-only`. If the file was renamed → `KEEP-WITH-NOTE` citing the new name.

**Output extension** — two new verdict shapes ride alongside the Phase 1 `CLOSE-CANDIDATE` / `KEEP` / `SKIP`:

- `CLOSE-CANDIDATE-WITH-CAVEAT <basename> — shapes: <comma-list> — caveat: <short-tag>: <one-line> — cites: ...` per architect condition C2 (structured field the SKILL Step 4.6b template can splice as a separate **Caveat** entry, preserving ADR-026 uncertainty leg structurally). Caveat fires when at least one shape matches AND the body has any unticked checkboxes (multi-phase mixed-progress umbrellas). Tag enumeration starts with `multi-phase-mixed-progress`.
- `KEEP-WITH-NOTE <basename> — <note>: <evidence>` for the Phase 1 false-positive class + the A1 future-work disambiguation.

Multi-shape matches emit cumulatively per ADR-026 (corroborating evidence is stronger than first-match-wins): `CLOSE-CANDIDATE <basename> — shapes: ADR-shipped-confirmed,self-marker-in-body — <per-shape cites>`.

**Behavioural second-source**: `packages/itil/scripts/test/evaluate-relevance.bats` extends 18 → 33 fixtures (15 new). New coverage:
- Shape 2 positive + ADR-not-confirmed negative.
- Shape 3 SKILL.md + slash-command resolution.
- Shape 4 positives (`Close to Verifying`, `## Fix Released`, `DONE 2026-`) + mid-prose negative (architect A2).
- Shape 5 closed-driver positive + child-has-independent-open-work negative (architect A1).
- Phase 1 false-positive fixes: state-suffix variant + sibling-file slug-prefix.
- `CLOSE-CANDIDATE-WITH-CAVEAT` structured format (architect C2).
- KEEP fixture for P303/P326-class recent observations.
- Cumulative multi-shape match.

33/33 GREEN. Real-backlog smoke test 2026-05-31 against today's labeled fixtures: P012 → CLOSE-CANDIDATE-WITH-CAVEAT (shapes 2 + 5 + multi-phase-mixed-progress caveat); P136 → KEEP-WITH-NOTE (sibling-file class — body cites a slug-drifted ADR path that resolves to the actual sibling). Conservative behaviour preserved; mechanical-stage carve-out (P132 / ADR-044 cat 4) preserved.

**Bug fix during implementation**: bash `printf "%03d" "034"` interprets leading-zero input as octal (= decimal 28). Shape 5 P-ref attribution had a silent misroute (P034 cited the wrong file). Fixed by stripping leading zeros before printf — captured inline as `n_clean` normalisation. Worth a sibling problem ticket if it surfaces again in the broader script ecosystem.

Composes with: ADR-079 Phase 2 amendment (this changeset's design driver), ADR-022 lifecycle extension (already shipped in Phase 1; Phase 2 broadens the cited-shape list at `/wr-itil:manage-problem` SKILL.md line 59), ADR-026 grounding (cumulative shape cite + structured caveat field), ADR-049 PATH shim (no shim change — shape detection rides the existing `wr-itil-evaluate-relevance` body), ADR-052 behavioural bats default, ADR-014 commit grain (3 commits: ADR amendment / script+bats+changeset / SKILL amendments), ADR-066 born-`proposed` without `human-oversight: confirmed` (orchestrator drains Phase 1 + 2 together later), ADR-074 substance-confirm-before-build (user direction pins Phase 2 substance), ADR-013 Rule 5 + ADR-044 cat 4 (AFK silent-proceed preserved — file existence + frontmatter inspection + line-anchored grep are empirical).

Closes P347 Phase 2.
