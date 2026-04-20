# Getting Help

Where to go depends on what you need:

## Usage questions, configuration help, pattern advice

[GitHub Discussions](https://github.com/windyroad/agent-plugins/discussions). Discussions stay searchable for the next person who hits the same question.

Before posting, search existing discussions and the per-plugin README files under `packages/*/README.md`.

## Report a problem

[Open an issue](https://github.com/windyroad/agent-plugins/issues/new/choose) using the **Report a problem** template. You do not need to pre-classify it as a bug or feature -- this project practises ITIL problem management, and triage decides whether the root cause is a defect, a missing capability, a documentation gap, or something else. Describe what you observed and let triage decide the category.

Include:

- A description of what is happening and what you expected
- Observable symptoms (errors, hook output, transcripts, screenshots -- redact secrets)
- Any workaround you tried, even if it did not help
- Affected plugin and version (`claude plugin list`)
- Claude Code version (`claude --version`) and operating system
- Minimal reproduction steps or evidence

The template prompts for these. Issues without the template fields are slower to triage.

## Security vulnerabilities

**Do not open a public issue.** Use [GitHub Security Advisories](https://github.com/windyroad/agent-plugins/security/advisories/new) for private disclosure. See [SECURITY.md](SECURITY.md) for the disclosure timeline and what's in scope.

## Per-plugin documentation

Each plugin has its own README under `packages/<name>/README.md`. Start there for plugin-specific behaviour.

## Commercial support

This is an open-source project from [Windy Road Technology](https://windyroad.com.au). Reach out via the website for commercial engagement, training, or paid support.
