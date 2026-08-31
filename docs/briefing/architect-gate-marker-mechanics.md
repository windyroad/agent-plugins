# Architect Gate Marker Mechanics

How the `wr-architect:agent` completion reaches the shared marker writer and which verdict shapes carry authority. The P099 Tier 3 budget rotation split this file out of [`agent-hook-gate-quirks.md`](./agent-hook-gate-quirks.md) on 2026-07-26.

Sibling files: [`agent-hook-gate-quirks.md`](./agent-hook-gate-quirks.md) (other gate quirks), [`hooks-and-gates.md`](./hooks-and-gates.md) (gate inventory), [`agent-interaction-patterns.md`](./agent-interaction-patterns.md) (broader interaction discipline).

## What You Need to Know

- **An architect review unlocks edits only through a supported, caller-bound completion path and one unambiguous canonical verdict.** The shared marker writer accepts exactly one `**Architecture Review: PASS**` or `## Architecture Review: PASS` line. ISSUES FOUND, repeated or conflicting canonical verdicts, malformed headings, quoted examples, and narrative approval create no review, hash, or plan markers. The generated Codex completion transport records the parent session, checkout, reviewer role, and target at spawn time, then forwards the completed reviewer output to the shared marker writer under that parent context; unmatched targets, non-architect targets, and stale target reuse fail closed. Close the same fresh reviewer once through the native completion path. Never replay a verdict, guess a session id, or create marker evidence manually. P468 source commit `a02e8d0d` carries the parser repair; installed sessions may retain the bold-only matcher until maintainers release and refresh the package and users restart their sessions. <!-- signal-score: 4 | last-classified: 2026-08-31 | first-written: 2026-05-11 -->
