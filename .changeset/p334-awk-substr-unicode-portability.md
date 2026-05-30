---
"@windyroad/architect": patch
---

P334: `generate-decisions-compendium.sh` now uses ASCII `...` instead of Unicode `…` (U+2026) for truncation markers. BSD awk on macOS counts `substr()` length in bytes; GNU awk on Linux counts in characters. The 3-byte UTF-8 ellipsis made macOS regenerations truncate ~2 chars shorter than Linux, causing the committed compendium to drift from on-machine regenerations and failing CI test `committed compendium matches generator output (CI drift gate)`. Sibling: P328 (broader BSD-vs-GNU UTF-8 class — sidesteps the LC_ALL coupling rather than requiring callers to set it).
