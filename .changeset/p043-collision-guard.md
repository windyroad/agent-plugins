---
"@windyroad/itil": patch
"@windyroad/architect": patch
---

ticket-creators: next-ID collision guard against origin (P043)

Adds the next-ID collision guard from ADR-019 confirmation criterion 2 to
both ticket-creator skills:

- `manage-problem` step 3 (Assign the next ID): now computes max of
  local-max and `git ls-tree origin/<base>` max, then increments. Catches
  collisions between local work and parallel sessions before the ticket
  file is written.
- `create-adr` step 3 (Determine sequence number): same mechanism applied
  to `docs/decisions/`.

Both skills cite ADR-019 and log renumber decisions in the user-facing
report. Sibling fix to P040 (work-problems Step 0 preflight, shipped in
@windyroad/itil@0.4.2): preflight catches divergence at loop start; this
ticket catches collisions at ticket-creation time as a defence in depth.

Adds bats tests (3 assertions per skill) verifying ADR-019 references and
the collision-guard pattern.

Closes P043 pending user verification.
