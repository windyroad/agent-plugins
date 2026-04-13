---
name: wr-architect:create-adr
description: Create a new Architecture Decision Record (MADR 4.0) in docs/decisions/. Examines existing decisions, asks about the problem and options, and writes a properly formatted ADR.
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion
---

# Architecture Decision Record Generator

Create a new ADR in `docs/decisions/` following MADR 4.0 format. The wr-architect:agent reviews these files to enforce architectural compliance.

## Steps

### 1. Discover existing decisions

Scan for existing ADRs:
- Glob `docs/decisions/*.md` (skip `README.md`)
- Note the highest numbered decision to determine the next sequence number
- Read any decisions related to the topic being discussed (if the user has mentioned a topic)
- If `docs/decisions/` does not exist, create it

### 2. Gather context from the user

You MUST use the AskUserQuestion tool to collect the decision context. Do not proceed to step 3 until you have answers.

Ask the user:

1. **What is the decision about?** A brief title and the problem being solved.
2. **What options were considered?** At least 2 alternatives (including "do nothing" if applicable). For each option, ask for key pros and cons.
3. **What was chosen and why?** The selected option and the primary reason.
4. **Who are the decision-makers?** Who made or is making this decision.
5. **Any consequences to note?** Known good, neutral, or bad outcomes.

If the user has already provided this context in the conversation (e.g., as arguments), use what they've given and only ask about what's missing.

### 3. Determine sequence number and filename

- Next number = highest existing decision number + 1 (or 001 if none exist)
- Filename: `NNN-decision-title-in-kebab-case.proposed.md`
- Pad the number to 3 digits (001, 002, ... 010, 011, etc.)

### 4. Write the ADR

Write the file to `docs/decisions/` with this structure:

```markdown
---
status: "proposed"
date: YYYY-MM-DD
decision-makers: [from user input]
consulted: [from user input, or empty list]
informed: [from user input, or empty list]
reassessment-date: YYYY-MM-DD  # 3 months from today
---

# Title

## Context and Problem Statement

[What problem does this solve? Why is a decision needed now?]

## Decision Drivers

- [Key factors influencing the decision]

## Considered Options

1. **Option A** - Brief description
2. **Option B** - Brief description

## Decision Outcome

Chosen option: **"Option X"**, because [primary justification].

## Consequences

### Good

- [Positive outcomes]

### Neutral

- [Trade-offs that are neither clearly good nor bad]

### Bad

- [Negative outcomes or risks accepted]

## Confirmation

[How to verify implementation compliance. Concrete, testable criteria.]

## Pros and Cons of the Options

### Option A

- Good: [advantage]
- Bad: [disadvantage]

### Option B

- Good: [advantage]
- Bad: [disadvantage]

## Reassessment Criteria

[When should this decision be revisited? What conditions would trigger a review?]
```

Use today's date for the `date` field. Set `reassessment-date` to 3 months from today unless the user specifies otherwise.

### 5. Confirm with the user

Present the written ADR and use AskUserQuestion to ask:
1. Does the problem statement accurately capture the situation?
2. Are the pros/cons fair and complete?
3. Are the confirmation criteria testable?
4. Should anyone else be listed as consulted or informed?

Apply any feedback by editing the file.

### 6. Handle supersession (if applicable)

If the user mentions this decision replaces an existing one:
1. Add `supersedes: [NNN-old-decision-title]` to the new decision's frontmatter
2. Rename the old decision file from `.accepted.md` (or `.proposed.md`) to `.superseded.md`
3. Update the old decision's frontmatter status to `superseded`
4. Add a "Superseded by" section to the old decision referencing the new one

$ARGUMENTS
