---
"@windyroad/risk-scorer": patch
---

P374: project-neutral risk-register README phrasing in `extract-risks-from-reports.sh`

The bootstrap helper emitted "for the Windy Road Agent Plugins suite." into the adopter-generated `docs/risks/README.md`, leaking the publishing suite's brand into adopter-controlled prose (overwritten on every `bootstrap-catalog` run, so a maintainer correction never survived). The heredoc now reads "for this project." — project-neutral, no substitution code, correct in both source-monorepo and adopter contexts. A behavioural test asserts the brand substring is absent from the emitted README. Class: published-artefacts-reference-repo-internal-text (sibling of P151/P153/P219/P317).
