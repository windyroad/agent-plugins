---
"@windyroad/itil": patch
---

P206: work-problems Step 5 iteration-prompt-body now EXPLICITLY requires
AFK iter subprocesses to author a `.changeset/*.md` alongside any fix
commit that ships shippable code (anything under
`packages/<plugin>/{src,bin,hooks,skills,scripts,lib,agents}` excluding
test paths). Doc-only and test-only changes that ship no behaviour MAY
omit the changeset.

Composes defence-in-depth with hook P141
(`itil-changeset-discipline.sh`) which enforces the same rule at
`git commit` time. The prompt-time constraint is load-bearing because
plugin-hook execution depends on the marketplace cache carrying the
current hook version — a fresh-cache adopter without P141 still gets
the constraint via the prompt.

Inbound-reported by downstream consumer **bbstats** as their P195
(`**Origin**: inbound-reported (bbstats#195)` per ADR-076 sort tier).

Also adds `test/work-problems-step-5-iter-changeset-required.bats`
(structural-permitted per ADR-052 with tdd-review justification comment)
asserting the SKILL.md carries the changeset-required clause, doc/test
exemption, P141 cite, P206 cite, and bbstats#195 inbound-source cite.

JTBD: JTBD-006 (Progress the Backlog While I'm Away) — load-bearing;
JTBD-007 (Keep Plugins Current Across Projects) — closure depends on
fixes actually shipping to npm.
