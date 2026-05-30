---
"@windyroad/risk-scorer": patch
---

P171: `packages/risk-scorer/scripts/drain-register-queue.sh` no longer gates on `docs/risks/TEMPLATE.md` existence. The 2026-05-04 wipe direction (commit `8edaf7b`) removed `TEMPLATE.md` from canonical `docs/risks/`; commit `9b52610` re-canonicalised R-file suffix to `.active.md`. The drain script's pre-wipe `TEMPLATE_FILE` gate, vestigial `TEMPLATE_FILE` argument to the python body, and python-side `'TEMPLATE.md'` dir-skip literal are all removed — the script now drains successfully against canonical (post-wipe) state. Test-fixture `setup()` no longer synthesises a fixture-local `TEMPLATE.md`; a new behavioural test asserts the drain works against canonical state with no `TEMPLATE.md` present. Closes P171.
