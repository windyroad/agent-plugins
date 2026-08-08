---
"@windyroad/itil": minor
---

`/wr-itil:report-upstream` now prefers opening a pull request over filing an issue, whenever the upstream accepts pull requests. Filing an issue remains the documented fallback.

The predicate is whether the upstream accepts contributions, not whether you have write access to it. Fork-and-pull-request is the ordinary path, so the preference works for the third-party dependencies you do not own — which is most of them.

It falls back to filing an issue when the upstream does not accept contributions, when the fix needs a design decision that is the maintainers' to make, when the ticket is security-classified (the private disclosure path is checked first and is unchanged), or when there is no defensible fix in hand. That last one is decided quietly: the skill never asks the person reporting a problem to produce a patch. The issue body is drafted first and the pull request is an upgrade of it, so a failed attempt still files the report rather than losing it.

On the pull-request branch the body defers to the upstream's own `PULL_REQUEST_TEMPLATE.md` when there is one, and otherwise uses a short rationale-plus-cross-reference shape instead of the problem-report shape, which a diff already answers.

Under AFK the pull-request branch degrades to the issue branch and queues the drafted pull request for your return. No unattended session pushes code into someone else's repository.

Reports record a `pull request` disclosure path, and the skills that read it follow: `/wr-itil:check-upstream-responses` polls with `gh pr view`, and `/wr-itil:update-upstream` comments with `gh pr comment` and never closes a pull request — a merged one closes itself, and closing an unmerged one withdraws work you offered. Tickets filed before this change carry no disclosure path and are read as issues, exactly as before, with no extra API calls.

The pull request's prose goes through the same external-comms and voice-tone review as an issue body. Its diff does not — nothing here scores a diff against an upstream's conventions. Read it yourself before you open one.
