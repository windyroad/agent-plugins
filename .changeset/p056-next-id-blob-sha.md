---
"@windyroad/itil": patch
"@windyroad/architect": patch
---

Fix the next-ID origin-max lookup in `manage-problem` Step 3 and `create-adr` Step 3 (P056). The prior bash pipeline ran `git ls-tree origin/main <path>/ | grep -oE '[0-9]{3}'` — default `git ls-tree` output includes the 40-char blob SHA, whose hex run can contain three consecutive decimal digits that the regex falsely matches (observed `origin_max=997` on 2026-04-20 opening P055). The fix adds `--name-only` to drop mode/type/SHA columns and pipes through `sed` to strip the path prefix, so the anchored `grep -oE '^[0-9]+'` only picks up real filename IDs. ADR-019's next-ID invariant and P043's collision guard both presume this pipeline is sound; this change restores the invariant. Two new bats doc-lint tests (8 assertions) guard the contract.
