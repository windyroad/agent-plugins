---
"@windyroad/itil": patch
---

Drop the `--label` flag from `/wr-itil:report-upstream` SKILL.md Step 5 example (P207).

The example previously passed `--label "${MATCHED_TEMPLATE_LABEL_IF_ANY}"` to `gh issue create`. That call hard-fails with `could not add label: '<name>' not found` when the upstream repo has not pre-created the matching label name in its repo settings — the default for new upstream repos and any repo whose maintainer hasn't synchronised labels with the template's `labels:` frontmatter. The flag is also redundant when the matched issue template carries `labels:` in its YAML frontmatter (GitHub auto-applies those labels on submit).

The Step 5 example now omits `--label` and a one-line note records the rationale and points at the template's `labels:` frontmatter as the authoritative source of labels. Step 5's structured-default (template-less) path explicitly notes that labels are omitted — triage routing stays with the upstream maintainer's existing configuration.

No code/script change; documentation-fidelity fix to the canonical SKILL example.
