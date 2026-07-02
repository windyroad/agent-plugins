---
status: proposed
rfc-id: external-comms-gate-read-write-discrimination-gh-api
reported: 2026-07-03
human-oversight: unconfirmed
decision-makers: [Tom Howard]
problems: [P405]
adrs: []
jtbd: []
stories: []
---

# RFC-039: External-comms gate discriminates read-only `gh api` polls from body-bearing draft writes

**Status**: proposed
**Reported**: 2026-07-03
**Problems**: P405
**ADRs**: (none)
**JTBD**: (none)

## Summary

The external-comms gate (`packages/shared/hooks/external-comms-gate.sh`, synced to the risk-scorer and voice-tone consumer copies per ADR-017) detected the `gh-api-security-advisories` and `gh-api-comments` surfaces with a substring match (`gh api .*security-advisories` / `gh api .*/comments`) that did not distinguish a read from a write. Read-only `gh api` polls — notably `/wr-itil:review-problems` Step 4.5c's `gh api repos/O/R/security-advisories --jq ...` discovery poll — were denied as if they were outbound advisory-draft prose, silently blacking out one of three upstream discovery channels every review pass. This RFC narrows those two `gh api` surfaces to writes only.

## Driving problem trace

- **P405** (External-comms gate false-positives on `gh api` security-advisories read path): the gate's surface-detection regex fires on any `gh api ... security-advisories` string, including the read-only `--jq` discovery poll, producing a `BLOCKED (external-comms gate)` deny on a call that carries no outbound prose. Root cause: the substring match keys on the endpoint, not the invocation's read/write semantics.

## Scope

`gh api` defaults to an HTTP GET (a read). It only carries an outbound prose body — the artefact this gate exists to review — when a request-body flag is supplied: `-f` / `--field`, `-F` / `--raw-field`, or `--input` (any of these flips `gh api`'s default method to POST). The chosen approach adds a single shell predicate, `_gh_api_has_body`, to the canonical hook and gates the two ambiguous `gh api` surfaces (`security-advisories` + `comments`) ONLY when a body flag is present; a read-only invocation (no body flag) falls through to `exit 0` at surface-detection time and is never gated.

Every other surface the gate covers (`gh issue`/`gh pr` `create`/`comment`/`edit`, `npm publish`, `changeset-author`, `git-commit-message`) is inherently a write and stays gated unconditionally — the narrowing is scoped strictly to the two `gh api` branches, which are the only surfaces where the same command shape can be either a read or a write.

Skipping a read at surface-detection time also skips the downstream leak pre-filter, which is correct: a GET has no `DRAFT` body to scan. When a body flag IS present, the surface is set and the full leak pre-filter + per-evaluator marker gate run unchanged, so the write path (e.g. `gh api ... --method POST -f summary=...`) keeps its guardrail. This is a bug-fix within ADR-028's existing contract (which already scopes these surfaces as outbound *prose* / *advisory drafts*), not a new gate policy — no new ADR is required (architect verdict on P405, 2026-07-03).

## Tasks

- [x] Add the `_gh_api_has_body` predicate to the canonical `packages/shared/hooks/external-comms-gate.sh` (matches `-f`/`--field`, `-F`/`--raw-field`, `--input`).
- [x] Gate `gh-api-security-advisories` and `gh-api-comments` surfaces only when `_gh_api_has_body` is true; `exit 0` (skip) on read-only invocations.
- [x] Re-run `scripts/sync-external-comms-gate.sh` to propagate byte-identically to the risk-scorer and voice-tone consumer copies; verify with `--check`.
- [x] Add behavioural bats to each consumer test (`packages/risk-scorer/hooks/test/external-comms-gate.bats` + `packages/voice-tone/hooks/test/external-comms-gate.bats` — test files are NOT synced): read-only `--jq` poll and bare read PASS (exit 0, empty output); `comments` read PASS; body-flag write still DENIES.
- [x] Changeset naming the bumping plugins.

## Commits

(maintained automatically — populated by the commit-message RFC trailer hook per ADR-060 Phase 1 item 12)

## Related

- **P405** — driving problem ticket.
- **ADR-028** — external-comms gate contract (surfaces scoped as outbound prose / advisory drafts).
- **ADR-017** — shared-code sync pattern (canonical hook + `scripts/sync-external-comms-gate.sh`).
- **JTBD-006** — Progress the Backlog While I'm Away (the fix restores the upstream inbound-discovery channel that Step 4.5c feeds).
- **P402**, **P395** — sibling external-comms gate defects (same hook family, different failure modes).

## RFCs

(captured via /wr-itil:capture-rfc; expand at next /wr-itil:manage-rfc invocation)
