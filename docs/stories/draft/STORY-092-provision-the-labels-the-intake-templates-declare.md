---
status: draft
story-id: provision-the-labels-the-intake-templates-declare
reported: 2026-09-19
decision-makers: [Tom Howard]
problems: [P436]
jtbd: [JTBD-301, JTBD-101]
rfcs: [RFC-096]
story-maps: [STORY-MAP-004]
estimated-effort: S
---

# STORY-092: Provision the labels the intake templates declare

**Reported**: 2026-09-19
**Problems**: P436
**JTBD**: JTBD-301 — secondary: JTBD-101
**RFCs**: RFC-096
**Story Maps**: STORY-MAP-004
**Estimated effort**: S — one shipped script, one PATH shim, one scaffold step, one behavioural suite.

## User value (required, INVEST Valuable)

In order to have filing a problem actually work the first time — so that the labels the
issue template promises are real rather than declared into a void — as someone reporting a
problem against a project that adopted this suite, I want the intake scaffolding to create
the labels it declares, so `gh issue create --label problem` succeeds instead of hard-failing
and the web form stops silently dropping the labels that route my report.

## Acceptance criteria (accepted-gate, INVEST Testable)

- [ ] A shipped script provisions every label declared by the issue templates in the repo it
  is run against. It resolves nothing from a source-repo-relative path and assumes no
  directory that exists only in this monorepo — an adopter runs it in their own checkout.
- [ ] The parse is anchored: a column-0 `labels:` key in the top-level mapping of the FIRST
  YAML document of each template. A multi-document file, a commented-out block, or a nested
  `body:` occurrence must not bind. On an unparseable or ambiguous shape the script fails
  loudly naming the file path — it never silently takes the first match. Each parsed token
  becomes a label created in someone's repository, so a wrong bind is a wrong write.
- [ ] Both declaration forms parse: the flow form `labels: ["problem", "needs-triage"]` that
  the shipped template uses today, and the block form (`labels:` followed by `- name` lines).
- [ ] Creation is create-only and convergent. An existing label is reported "already present
  — skipped" and left untouched: its colour, its description, and its meaning are the
  adopter's. Re-running the script produces no change. `gh label create --force` must NOT be
  used bare — it updates an existing label, and with no colour supplied it re-randomises the
  adopter's colour on every run, which is a destructive re-run rather than a no-op.
- [ ] Labels this project creates carry a pinned colour and description rather than a
  gh-chosen random colour. The values already applied to `windyroad/agent-plugins` are the
  reference: `problem` / `b60205` / "Structured problem report filed through the intake
  template", and `needs-triage` / `fbca04` / "Awaiting maintainer triage".
- [ ] Failure is legible, never silent. A missing `gh` binary, an unauthenticated `gh`, and a
  create rejected for want of label-write scope each emit their own explicit message naming
  what to do next, and the direct invocation exits non-zero.
- [ ] A label-provisioning failure never costs the adopter their intake files. Invoked as a
  scaffold sub-step, a failure reports loudly and names the follow-up command verbatim, and
  the scaffold's marker step and its commit still proceed. Label-write permission is routinely
  absent on forks and on org-restricted repos, so this is the common adopter case. Only the
  direct invocation hard-fails.
- [ ] A dry-run mode prints what would be created without contacting GitHub.
- [ ] The script is reachable by name through the generated PATH shim, not by path, and the
  shim is produced by the shim-sync script rather than hand-authored.
- [ ] A behavioural suite stubs `gh` on `PATH` and asserts on what the script actually invokes
  and returns: both declaration forms parsed, an existing label skipped rather than updated,
  a re-run producing no change, each failure mode exiting non-zero with its own message, and
  a repo with no issue templates exiting 0 having done nothing.
- [ ] The scaffold skill's new step states its rule self-contained, without source-repository
  identifiers in the published prose. Structured `@adr` / `@problem` annotations in the
  script header are fine; the runtime prose carries none.
- [ ] The scaffold skill's prose verdict — what it does when `gh` is absent or unauthenticated
  — is covered by a case in that skill's existing promptfoo config, or the reason for not
  covering it is recorded. A bats suite cannot assert a prose verdict.
- [ ] A `.changeset/*.md` bumps the owning plugin, authored in the same commit as the code.

## Driving problem trace (required — I7 invariant)

- **P436** — the shipped issue template declares `labels: ["problem", "needs-triage"]`, and
  neither label existed in `windyroad/agent-plugins`. The web form silently drops an undeclared
  label; `gh issue create --label problem` hard-fails outright. Every adopter who scaffolds
  intake inherits the same gap in their own repository. Arrived as inbound report #170.

## JTBD trace (accepted-gate — I8 invariant)

Serves JTBD-301 (report a problem without pre-classifying it), whose desired outcome names
this mechanism literally: submitted reports receive a predictable acknowledgement — labelled
`problem` and `needs-triage`, routed into the maintainers' problem-management queue. That
outcome is unserved today in this repo and in every downstream adopter. Two of its persona
constraints bind: the reporter has low context on repo internals and cannot diagnose a `gh`
auth-scope failure, which is why failure must name its own next step; and the reporter may be
filing through an AI agent rather than directly, which is precisely the `gh --label` path that
hard-fails today.

Serves JTBD-101 (extend the suite with new plugins) on the producer side — the shipped script,
the generated PATH shim, the behavioural suite and the changeset all follow the structure every
plugin in the suite already uses.

## Implementation notes

**Implementation is queued pending a ratified decision.** The scaffold skill's recorded scope
is local file writes; it records no network write, no third-party-service mutation, and no
external-binary dependency. Creating labels mutates the adopter's GitHub repository settings,
which is a side-effect class that scope never authorised — and the same record explicitly
rejected auto-writing into a previously-empty `.github/` unattended as too aggressive. So the
consent question must be settled and ratified before this story is implemented:

- **A — provision automatically** under the same consent as the file writes; one prompt covers
  local files and labels.
- **B — separate opt-in**: default off behind a dedicated flag; otherwise report the gap.
  Local scaffolding stays network-free by default.
- **C — surface, never mutate**: emit the exact `gh label create` commands plus the gap report
  and let the adopter run them. Removes the gh-absent and unauthenticated branches entirely.
- **D — remove the cause**: drop the label declaration from the template so declaration and
  reality agree. Contradicts JTBD-301's ratified outcome, which names the two labels.

The reviewed lean is B or C. Whichever lands, the acceptance criteria above hold: they are
written about how labels are created and how failure is reported, not about who consents.

If the chosen option adds a prompt branch, the skill's AFK fail-safe audit table gains a row
for it.

## Related

- RFC-096 (the fix vehicle), STORY-MAP-004 (the map), P436 (the driving problem), inbound #170.
- The half already shipped: `problem` and `needs-triage` now exist in `windyroad/agent-plugins`
  with pinned colour and description. This story is the downstream half — every adopter's repo.
