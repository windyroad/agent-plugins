# Reviewer Spawn Failures — Deaths, and PASSes That Do Not Land

The two ways a governance reviewer costs you a round without telling you why: the spawn dies
server-side, or it returns a genuine PASS that never reaches the gate. Split out of
[`afk-vehicle-authoring-gates.md`](./afk-vehicle-authoring-gates.md) on 2026-07-26 per the P099
Tier 3 budget rotation — which paths carry extra write gates and how a reviewer spawn fails are
different questions, and only the first is needed while planning a write order.

## What You Need to Know

- **The cognitive-accessibility reviewer ADR-124 mandates is tool-less: hand it a file path and it refuses, costing a whole spawn.** `wr-architect:cog-a11y` has no Read, no Bash, no filesystem access of any kind, so a prompt naming `/path/to/adr.md` gives it nothing to review. It says so rather than guessing — *"A path is not a document to me"* — and explicitly declines to return a PASS it has no basis for, which is the right call and still a lost round. Paste the document's full text inline, front matter and all. Witnessed 2026-09-19 capturing ADR-130: the architect and jobs reviewers were dispatched by path and both read the file themselves, so the asymmetry is easy to miss when they are spawned side by side. Budget the paste, not a path, on every ADR that will be ratified — ADR-124 puts this review ahead of every ratification, so the friction is on the common path, not a corner. P546. <!-- signal-score: 2 | last-classified: 2026-09-19 | first-written: 2026-09-19 -->

- **A real Codex reviewer PASS is not authority to manufacture the missing parent-session marker.** A native collaboration runtime may expose `spawn_agent`, `wait_agent`, and `interrupt_agent` without the completed-agent close operation that the installed compatibility hook expects. In that shape, a reviewer can return the canonical PASS and write its subordinate verdict while the next governed edit still denies because no parent-session review marker exists. Fail closed: do not replay the verdict, invoke the hook with crafted JSON, touch marker files, delete hook state, replace configuration, or substitute a different orchestrator. Preserve the reviewed diff and report the unavailable handoff as the blocker. P514 recovery, 2026-08-31. <!-- signal-score: 1 | last-classified: 2026-09-19 | first-written: 2026-08-31 -->
