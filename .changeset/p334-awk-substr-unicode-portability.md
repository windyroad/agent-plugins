---
"@windyroad/architect": patch
---

P334: `generate-decisions-compendium.sh` is now byte-portable across BSD awk (macOS) and GNU awk (Linux). Two layered changes: (1) ASCII `...` instead of Unicode `…` (U+2026) for truncation markers, and (2) `export LC_ALL=C` at script top so both awks operate on raw bytes consistently (BSD already does by default; GNU under any UTF-8 locale was counting characters). Without (2), ADR bodies containing em-dashes / smart quotes still drifted because `length()` and `substr()` diverged at the truncation threshold. The committed compendium now matches on-machine regenerations on both platforms. CI test `committed compendium matches generator output (CI drift gate)` closes. Sibling: P328 (broader BSD-vs-GNU UTF-8 class — sidesteps the LC_ALL coupling at the caller layer by setting it script-internally).
