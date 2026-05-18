---
"@windyroad/itil": patch
"@windyroad/retrospective": patch
---

P273 + P274 + P275 (batched P268 sibling-hook sweep — three hooks
across two packages, one commit per ADR-014 batch grain): three
PreToolUse/PostToolUse Bash hooks no longer false-positive deny or
emit advisory on Bash commands that merely MENTION the literal phrase
`git commit` in their argument vectors or heredoc bodies.

Replaces the case-statement substring match
`case "$COMMAND" in *"git commit"*) ;;` at each hook's command-shape
filter with delegation to the shared helper
`command_invokes_git_commit` introduced by P268 — same fix shape as
P272 applied to the remaining sibling enforcement-layer hooks.

Hooks fixed:

- **P273** — `packages/itil/hooks/p057-staging-trap-detect.sh` (P057
  staging-trap enforcement, deny-class).
- **P274** — `packages/itil/hooks/itil-rfc-trailer-advisory.sh` (RFC-
  trailer drift advisory, advisory-class).
- **P275** — `packages/retrospective/hooks/retrospective-readme-jtbd-currency.sh`
  (JTBD-currency README drift enforcement, deny-class — first
  cross-package consumer of the shared helper).

To enable the cross-package P275 fix, the helper is promoted to
canonical `packages/shared/hooks/lib/command-detect.sh` per ADR-017
(matching the existing `session-marker.sh` / `leak-detect.sh` /
`external-comms-key.sh` precedent under `packages/shared/hooks/lib/`).
A new sync script `scripts/sync-command-detect.sh` mirrors
`scripts/sync-session-marker.sh` (consumers: `itil`, `retrospective`)
and a CI step `npm run check:command-detect` fails the build on
divergence. Per-package copies live at
`packages/itil/hooks/lib/command-detect.sh` and
`packages/retrospective/hooks/lib/command-detect.sh`. Behavioural
bats fixture at `packages/shared/test/sync-command-detect.bats`
covers the three ADR-017 § Confirmation cases (canonical exists,
all-copies-match, divergence + missing detected by --check).

Coverage: 8-9 behavioural bats fixtures appended to each of the three
hook test files, mirroring the P268 regression suite — grep / sed /
echo / cat-heredoc / `git log --grep` false-positive allow paths,
`git commit-tree` boundary allow, plus positive-regression cases
(env-var-prefixed, cd-prefixed, leading-whitespace `git commit` still
trigger the gate).

Closes the P268 sibling-hook sweep — all four siblings (P268 / P272 /
P273 / P274 / P275) now consume the shared helper. Future
PreToolUse:Bash hooks gating `git commit` should source the helper
from `packages/<plugin>/hooks/lib/command-detect.sh` from inception.
