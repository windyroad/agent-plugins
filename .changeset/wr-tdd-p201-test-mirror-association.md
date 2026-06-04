---
"@windyroad/tdd": patch
---

`tdd_find_test_for_impl()` now recognises the `test/`-mirror layout — the default Vitest layout and a common Jest setup — alongside the existing same-directory, `__tests__/`-adjacent, parent `__tests__/`, and Cucumber step-definitions shapes. Adopter projects whose existing test layout mirrors `src/` under a sibling `test/` tree (e.g. `src/foo.js` ↔ `test/foo.test.js`, recursive for nested `src/a/b/foo.js` ↔ `test/a/b/foo.test.js`, and workspace `packages/<pkg>/src/foo.js` ↔ `packages/<pkg>/test/foo.test.js`) can now pass the TDD gate via their existing test files instead of bypassing the gate or restructuring their layout. The mapping replaces the last `src` path segment with `test`, so it works at any nesting depth and across monorepo workspaces. Closes P201.
