---
"@windyroad/itil": patch
---

Pass project-scoped governance plugins to AFK iteration subprocesses via `--plugin-dir`. The `/wr-itil:work-problems` orchestrator dispatches each iteration to a headless `claude -p` subprocess, but headless sessions activate only user-scoped plugins — project-scoped plugins stay inactive because their activation is trust-gated and headless skips the trust prompt. In projects that enable the windyroad plugins at project scope (the common adopter setup), iteration subprocesses had no architect / JTBD / risk-scorer / voice-tone agents or gate hooks, so they committed work ungated and could not run the on-exit retrospective.

Step 5 now resolves each governance plugin's installed directory and passes it to the subprocess with `--plugin-dir`, restoring the full governance surface inside every iteration. The resolver derives each plugin's directory from its `bin/` entry on `PATH` and selects the highest installed version, so it works in adopter installs as well as the source repository; `--setting-sources user,project` alone does not fix this, because it does not lift the trust gate. Plugins that are not installed are skipped, and the dispatch is unchanged when no governance plugins are present.
