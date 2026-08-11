---
"@windyroad/risk-scorer": patch
---

Bind Codex pipeline risk markers to the explicitly assessed Git checkout. The completion bridge now rejects missing or invalid assessment roots, validates the declared path as the repository top level, writes the marker from that checkout, and removes the local path from persisted reports.
