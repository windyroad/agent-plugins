---
"@windyroad/itil": patch
---

Internal hardening, no behaviour change.

The two functions that compute a story's oversight fingerprint each carried their own verbatim copy of the filter defining what the fingerprint ignores. That duplication is why the previous release's fix had to be applied twice, and why a third copy could have been missed. There is now one definition.

Fingerprints are unchanged, and that is measured rather than expected. Every stored value in this repo's corpus was computed before and after the refactor and compared, with zero differences across all 71. The two functions are additionally asserted byte-identical against a frozen copy of the previous implementation, over the shapes most likely to expose a difference: no final newline, several trailing blank lines, CRLF line endings, an empty file. So nothing already ratified moved here, and if you upgrade, your own stored fingerprints keep matching.

The one-time audit that found the previous defect is now a lint that runs with the test suite, so a body line duplicating a field the fingerprint ignores now fails the suite rather than waiting to be noticed. Two shapes escape it, both deliberate: a story-map card whose link embeds the story's lifecycle directory, and a mirror written with leading whitespace or inside a list item.
