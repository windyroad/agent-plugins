---
status: proposed
date: 2026-10-17
human-oversight: unconfirmed
decision-makers: [Tom Howard]
consulted: [wr-architect:agent, wr-jtbd:agent, wr-risk-scorer:plan]
informed: []
supersedes: [ADR-075]
reassessment-date: 2027-01-17
---

# Claude quota exhaustion leaves evaluations unavailable

## Context and Problem Statement

The Claude evaluation job can exhaust its subscription quota after its initial
availability probe succeeds. CI run 39008611611 initially retained 32 successful
governance evaluations and two provider errors, then failed before planning
evaluations ran. Its subsequent attempt detected quota exhaustion at the initial
probe and skipped evaluations with a warning. These attempts establish different
availability states; neither supplies the missing evaluation evidence.

The user requested that Claude tests be disabled when the quota is exceeded.
ADR-075 currently permits an initial quota skip but makes later evaluation
failures blocking. That timing distinction makes the same provider outage stop
delivery depending on when it occurs. A narrow successor proposal is needed to
change that distinction without weakening ordinary failure handling.

## Decision Drivers

- Subscription exhaustion must not consume further Claude calls in the job.
- Unavailable evaluations must remain distinguishable from passing evaluations.
- Partial results must remain available for inspection.
- Semantic failures and unrelated provider or harness failures must still block.
- A later job with available quota must run its normally selected evaluations.

## Considered Options

1. Treat recognized pure Claude quota exhaustion at any point as unavailable
   evaluation coverage, stop further Claude calls and warn.
2. Keep ADR-075's timing distinction: skip initial exhaustion but block on every
   later evaluation failure, including pure quota exhaustion.

## Decision Outcome

Chosen option: **recognized pure Claude quota exhaustion leaves evaluations
unavailable regardless of when it occurs in the job**. Stop further Claude calls
for that job, retain partial results and report the unavailable coverage through
an explicit warning. Give skipped evaluations no model-test pass credit.

Only an actual unsuccessful Claude invocation whose diagnostic consists solely
of a recognized quota response qualifies. Assertion failures, mixed diagnostics,
authentication, transport, parsing, harness and unrecognized failures remain
blocking. Quota exhaustion in one concurrent invocation cannot excuse another
failure. The unavailable state is job-local; an available future job runs its
selected evaluations normally.

This supersedes only ADR-075's treatment of quota exhaustion after the initial
probe. Its other harness, provider, authentication, scope, cadence and ordinary
failure decisions remain applicable. ADR-075's historical record remains intact
while this proposal awaits production evidence and human ratification.

This proposal may guide the authorized implementation. It claims neither final
human ratification nor successful production operation of the new behavior.

## Consequences

### Good

- Delivery can continue through a recognized subscription outage with an honest
  record of missing coverage.
- Further Claude calls stop after exhaustion is recognized.
- Partial evidence and blocking failures remain visible.

### Neutral

- Green CI may contain an explicit unavailable evaluation warning; it does not
  mean that the selected Claude evaluations passed.

### Bad

- A quota-exhausted job cannot provide all selected model-evaluation evidence.
- Classification must be conservative to avoid hiding ordinary failures.
- A changed quota diagnostic may block until its meaning is established.

## Confirmation

- [ ] Production CI demonstrates that pure late quota exhaustion stops further
  Claude calls, retains partial results and warns without claiming pass credit.
- [ ] Actual qualification demonstrates that mixed, assertion, authentication,
  transport, parsing and unrecognized failures remain blocking.
- [ ] A subsequent available job runs its normally selected evaluations.
- [ ] Human review ratifies the final decision after reviewing actual evidence.

These criteria are unclaimed at capture. Existing early-probe skips do not prove
the proposed late-exhaustion behavior.

## Pros and Cons of the Options

### Unavailable coverage at any point

- Uses the actual failure cause rather than probe timing to determine behavior.
- Preserves progress without inventing model evidence.
- Requires careful separation of pure exhaustion from concurrent other failures.

### Keep the timing distinction

- Preserves the current failure boundary without a new classifier boundary.
- Blocks delivery on recognized quota exhaustion after a successful probe,
  contrary to the user's requested behavior.

## Reassessment Criteria

Reassess after a diagnostic change, evidence of an incorrect skip, or repeated
missing coverage that prevents meaningful qualification. Review by 2027-01-17.
