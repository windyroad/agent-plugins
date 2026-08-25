# Problem 524: External adopter handles are public across the committed ticket corpus

**Status**: Open
**Reported**: 2026-08-25
**Priority**: 12 (High) — Impact: 3 (Moderate — RISK-POLICY.md classes client/project names committed to a public repo as Moderate, with remediation at git-history rewrite) × Likelihood: 4 (Likely — the state is already realised and public; the exposure grows with each capture that reuses a reporter's handle)
**Origin**: internal
**Effort**: M
**WSJF**: 6 — (12 × 1.0) / 2
**JTBD**: JTBD-001
**Persona**: developer

## Description

Two external project handles appear verbatim across the committed ticket corpus in this public repo: one at 31 occurrences across 11 files, a second at 3. They disclose adopter relationships and, in several cases, those parties' internal ticket numbers.

The redaction convention already exists and is used elsewhere in the same index — `docs/problems/README.md` carries four sibling inbound tickets redacted to `adopter-repo P<NNN>` (P368 `adopter-repo P212`, P512 `adopter-repo P151`, P513 `adopter-repo P111`, P514 `adopter-repo P042`). It was simply not applied to these.

The `docs/problems/*.md` Edit/Write path has **zero runtime controls** for this class: the external-comms gate covers outbound prose (gh issue/PR bodies, changesets, advisories) and does not cover ticket capture. So the convention is carried entirely by whoever is writing the ticket, and it fails silently when they do not think of it. It failed on 2026-08-25 during a capture in this very repo — caught only by the risk scorer at commit time, after the same inconsistency had been flagged earlier the same day and read.

## Symptoms

- `grep -rc '<adopter-handle>' docs/problems/` returns 31 across 11 files; a second handle returns 3.
- Sibling tickets in the same index use `adopter-repo P<NNN>` for the identical relationship.
- Nothing blocks or warns when a new capture writes an un-redacted handle.

## Workaround

Redact manually at capture time, matching the `adopter-repo P<NNN>` form used by the four sibling tickets. Relies entirely on the author remembering.

## Impact Assessment

- **Who is affected**: the named adopters, whose relationship with this project and whose internal ticket numbers are public; the project's own stated confidentiality posture, which the corpus contradicts.
- **Frequency**: the existing exposure is continuous; new exposure arrives with each inbound capture that reuses a handle.
- **Severity**: Moderate per RISK-POLICY.md § Impact Level 3. Note the remediation asymmetry — new occurrences are a cheap edit, but existing ones are already public and the sanctioned remediation is a git-history rewrite, which is itself high-risk on a public repo with open PRs.

## Root Cause Analysis

The convention is prose-only and unenforced on a surface the external-comms gate deliberately does not cover. ADR-076 defines Origin as `inbound-reported (#NN)` for this repo's own issue numbers and `internal` — it does not sanction an external repository handle, so the un-redacted form was never sanctioned, merely unblocked.

The standing-risk register has surfaced this class three separate times — R025, R041 and R073 — and scored it **zero** times. All three remain `Status: Active (auto-scaffolded — pending review)` with the ADR-026 ungrounded-output sentinel in every scoring field. An uncurated register entry cannot supply a baseline, so each recurrence is re-derived from policy by whichever scorer happens to catch it.

### Investigation Tasks

- [ ] Decide the remediation boundary for already-public occurrences: redact-forward only, or history rewrite. Weigh that a rewrite on a public repo with open PRs is itself a high-risk operation, and that the handles are already disclosed
- [ ] Redact the going-forward corpus to the `adopter-repo P<NNN>` convention, in its own commit, separate from any capture
- [ ] Add a control on the `docs/problems/*.md` write path — the surface currently has none. Decide between a capture-time check and extending an existing gate
- [ ] Curate R025, R041 and R073, or merge them into one scored entry — three unscored entries for one class is the reason it keeps being re-derived
- [ ] Fix the stranded article at P521's Description ("from the an adopter repo"), left by the 2026-08-25 redaction

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)
- **Composes with**: P521 (captured the same day; its own redaction is the precedent shape)

## Related

- **R025**, **R041**, **R073** — three standing-risk entries naming this class, all auto-scaffolded, none scored.
- **ADR-076** — defines the Origin field; sanctions `inbound-reported (#NN)` and `internal`, not external handles.
- **ADR-028** — the external-comms gate whose coverage stops short of this surface.
- **RISK-POLICY.md** § Confidential Information, § Impact Level 3.
