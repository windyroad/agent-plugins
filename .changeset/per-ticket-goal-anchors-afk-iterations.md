---
"@windyroad/itil": minor
---

Anchor each AFK iteration with a goal scoped to its own ticket

`/wr-itil:work-problems` now dispatches each iteration as `/wr-itil:work-problem <NNN>` — the singular skill, pinned to the ticket the loop already selected. Both skills had long documented that relationship; the implementation had drifted to hand-rolling a prompt instead, so the dispatch now matches the contract.

Each dispatch carries a goal scoped to that one ticket, so an external evaluator — not the working agent — judges whether the ticket reached a real end state. Previously only the outer loop was anchored and each iteration graded its own homework.

The goal condition is deliberately satisfied by the summary block an iteration already prints. An iteration held open past its final commit by an unmet goal looks exactly like a hung one to the idle-timeout watchdog, which would kill it and lose the run's metadata. Quota exhaustion is deliberately excluded from the condition: it surfaces as a non-zero exit with no summary at all, so it stays on the exit-code path where it can actually be observed.

Also in this release:

- The singular skill skips its ranking-freshness check when it is invoked against a pinned ticket **and** the dispatch declares the run unattended. That refresh was firing an unanswerable verification prompt into an absent-user subprocess and committing a ranking rewrite inside a per-ticket unit of work. The interactive pinned path is unchanged — a present user can answer that prompt, and it is the only self-firing verification cadence that path has.
- The loop-anchor step's placement rule is narrowed: a backlog-drain-scoped goal still belongs only on the orchestrator, while a per-ticket goal belongs on the iteration. One rule, two carriers — declared in the dispatch prompt on Claude Code, set natively on Codex.
- The evaluator's own token usage is now extracted and reported as its own line. The cost allowlist is closed, so without this the evaluator's spend would have been billed and never counted.
- A drift check asserts that every copy-paste `/goal` block embeds the canonical condition verbatim, wired into CI. It caught a live divergence: the headless launch one-liner had silently lost two clauses from the canonical text, which is repaired here.
- Corrected stale claims that iterations are dispatched via the Agent tool, and scoped the "an agent cannot set its own goal" statements to the Claude Code surface, where that is true.
