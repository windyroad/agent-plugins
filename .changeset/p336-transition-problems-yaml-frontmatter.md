---
"@windyroad/itil": patch
---

P336: `packages/itil/skills/transition-problems/SKILL.md` frontmatter `description:` value is now wrapped in double quotes. Previously the unquoted scalar contained the phrase `Singular sibling: `/wr-itil:transition-problem`` which YAML parsed as a mapping-key boundary at column 796, causing `claude plugin validate packages/itil` to fail with `YAML Parse error: Unexpected token`. The wrap preserves the prose verbatim and substitutes the inner colon with an em-dash so the description renders cleanly in both raw and parsed form. Closes P336; unblocks P263 Phase 1's CI gate from firing on the in-tree itil package.
