# Jobs To Be Done — Windy Road Agent Plugins

> Last reviewed: 2026-04-14
> The wr-jtbd:agent reads this file to review changes against user jobs.

## Personas

### Solo Developer

Uses AI coding agents (Claude Code) for personal or small-team projects. Moves fast, ships often. May be working across multiple repos simultaneously.

- **Cares about**: Speed, not breaking things, shipping with confidence
- **Frustrated by**: Agents that skip steps, silent config corruption, having to manually police AI output
- **Typical setup**: Installs 2-3 plugins (e.g., architect + tdd + risk-scorer) on a single project

### Tech Lead / Consultant

Responsible for code quality and governance across teams or client engagements. Installs plugins for their team or recommends them to clients. Represents Windy Road Technology's brand when recommending the suite.

- **Cares about**: Consistent standards, brand reputation, auditability of AI-assisted work
- **Frustrated by**: Agents that bypass reviews, no way to enforce architecture decisions automatically
- **Typical setup**: Installs the full suite, configures policy files, uses retrospectives and problem management

### Plugin Developer / Contributor

Builds new plugins or contributes to the suite. Needs to understand conventions, test hooks, and release safely. May be Tom or a future contributor.

- **Cares about**: Clear patterns, fast feedback loops, not breaking existing plugins
- **Frustrated by**: Undocumented conventions, slow test-fix-release cycles
- **Typical setup**: Works in the monorepo with `--plugin-dir`, runs BATS tests, uses changesets

## Jobs

### Job 1: Enforce governance without slowing down

**Statement**: Help solo developers and tech leads enforce architecture reviews, risk scoring, and TDD automatically — so they get the safety of manual reviews without the overhead.

**Type**: Functional | **Priority**: Must-have

**Job stories**:
- When I'm using an AI agent to write code, I want architecture decisions to be reviewed automatically, so I can catch structural mistakes before they ship.
- When I'm about to push a change, I want the pipeline risk to be scored automatically, so I can decide whether to split the release or add risk-reducing measures.

**Desired outcomes**:
- Every edit to a project file is reviewed against relevant policy before it lands
- No manual step is needed to trigger reviews — they happen on every edit
- Reviews complete in under 60 seconds so they don't break flow

**Current solutions**: Manual code review, PR review checklists, hoping the agent follows CLAUDE.md instructions

### Job 2: Ship AI-assisted code with confidence

**Statement**: Help tech leads trust that AI-written code meets their standards before it reaches production.

**Type**: Emotional | **Priority**: Must-have

**Job stories**:
- When I delegate coding to an AI agent, I want to know it followed TDD, so I can trust the code is tested.
- When a junior developer uses AI agents on a client project, I want governance enforced automatically, so I don't have to review every AI interaction.

**Desired outcomes**:
- Every commit has been through architecture review, risk scoring, and TDD enforcement
- The agent cannot bypass governance — hooks block edits until reviews pass
- Audit trail exists (markers, scores, review records) showing governance was followed

**Current solutions**: Pair programming with the AI, manual review of every diff, restricting agent permissions

### Job 3: Compose only the guardrails I need

**Statement**: Help developers install just the plugins relevant to their project without carrying unnecessary overhead.

**Type**: Functional | **Priority**: Important

**Job stories**:
- When I only need architecture and TDD enforcement, I want to install just those two plugins, so my session isn't cluttered with voice-tone and style-guide hooks that don't apply.
- When I discover a new plugin in the suite, I want to add it to my existing setup without reinstalling everything.

**Desired outcomes**:
- Each plugin is independently installable via `npx @windyroad/<name>`
- Installing a subset does not degrade the experience for installed plugins
- The meta-installer supports selective install via `--plugin` flag

**Current solutions**: Install everything and ignore irrelevant hooks, or don't install at all

### Job 4: Connect agents across repos to collaborate

**Statement**: Help developers coordinate parallel AI sessions working on related repos without idle polling or manual copy-paste.

**Type**: Functional | **Priority**: Nice-to-have

**Job stories**:
- When Session A discovers a bug in a dependency from another repo, I want it to notify Session B automatically, so Session B can act on it without me switching terminals.
- When multiple agents are working on related repos, I want them to share context via a channel, so they can collaborate like a team.

**Desired outcomes**:
- Messages arrive with zero idle token cost (no polling)
- Sessions can direct messages to specific agents via @session-name
- Human participants can weigh in on the same channel

**Current solutions**: Copy-paste between terminals, manually restarting sessions with new instructions

### Job 5: Extend the suite with new plugins

**Statement**: Help contributors add new governance plugins that follow established conventions and release safely.

**Type**: Functional | **Priority**: Important

**Job stories**:
- When I'm building a new plugin, I want to follow a clear template, so I don't have to reverse-engineer conventions from existing code.
- When I'm ready to release a plugin, I want the CI pipeline to validate my package structure, so I know it will install correctly for users.

**Desired outcomes**:
- Every plugin follows the same structure (package.json, plugin.json, hooks.json, install.mjs, BATS tests)
- CI validates required files, package fields, installer dry-runs, and hook tests
- Changesets handle versioning; the pipeline handles publishing
- ADRs document structural decisions so contributors understand the "why"

**Current solutions**: Copy an existing plugin and modify it, read ADRs and BRIEFING.md
