---
"@windyroad/tdd": patch
---

Fix TDD gate to recognise Cucumber `.feature` files as tests (closes P013).

- `tdd_classify_file()`: adds `*.feature` to test classification — writing a `.feature` file now transitions TDD state from IDLE to RED, enabling BDD/Cucumber projects to participate in the Red-Green-Refactor cycle without fake `*.test.js` wrappers
- `tdd_find_test_for_impl()`: adds Cucumber pair-detection — step definition files in `step_definitions/` directories associate with the matching `.feature` file in the parent directory (e.g. `features/step_definitions/checkout.steps.js` → `features/checkout.feature`)
