---
name: update-guide
description: Create or update the project's docs/JOBS_TO_BE_DONE.md by examining existing features and asking the user about user jobs, personas, and desired outcomes.
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion
---

# Jobs To Be Done Document Generator

Create or update `docs/JOBS_TO_BE_DONE.md` tailored to this project's users and their goals. The jtbd-lead agent reads this file to review UI changes against user jobs.

## What belongs in docs/JOBS_TO_BE_DONE.md

- **User personas**: Who uses this product and what characterises them
- **Jobs**: What users are trying to accomplish (functional, emotional, social)
- **Job stories**: "When [situation], I want to [motivation], so I can [expected outcome]"
- **Desired outcomes**: Measurable results users want from each job
- **Current solutions**: How users currently accomplish these jobs (competitors, workarounds)
- **Last reviewed date**: When the document was last reviewed or updated

## Steps

### 1. Discover project context

Examine the project to understand what it does and who uses it.

**Find the product definition** by scanning for:
- README.md and documentation
- Landing page or marketing content
- Product discovery documents (PRODUCT_DISCOVERY.md, personas, user research)
- Route/page structure (reveals user workflows)
- Feature flags or configuration (reveals capabilities)

**Discover user workflows**:
- Map the main user-facing pages/screens and their purpose
- Identify the core user journey (what do users do from start to finish?)
- Look for onboarding flows, dashboards, settings, or admin areas
- Check for different user roles (admin, member, viewer, etc.)

**Discover existing JTBD artefacts**:
- User stories in issues or project boards
- Persona documents
- User research notes or interview transcripts
- Analytics configuration (what events are tracked?)

### 2. Check for existing document

If `docs/JOBS_TO_BE_DONE.md` already exists, read it. Identify:
- Whether jobs still match the current feature set
- Whether personas still reflect the actual user base
- Whether the last reviewed date is stale (> 2 weeks)

### 3. Draft the JTBD document

Based on project discovery, draft sections covering:

**Personas** (2-4):
For each persona, describe: who they are, what characterises them, what they care about, and what frustrates them. Ground these in the actual product, not generic archetypes.

**Jobs** (3-8):
For each job:
- A job statement: "Help [persona] [accomplish goal] when [situation]"
- Whether it's functional, emotional, or social
- Priority (must-have, important, nice-to-have)

**Job Stories** (1-2 per job):
"When [situation], I want to [motivation], so I can [expected outcome]"

**Desired Outcomes** (per job):
What does success look like? How would the user measure it?

**Current Solutions**:
How do users currently accomplish these jobs without (or with competitors to) this product?

### 4. Confirm with the user

You MUST use the AskUserQuestion tool to collect user confirmation.

Present:
1. The drafted personas and ask if they're accurate
2. The jobs identified and ask if they cover the core value proposition
3. The job stories and ask if the situations and motivations ring true
4. Whether any user segments or jobs are missing

### 5. Write docs/JOBS_TO_BE_DONE.md

Write the document including:
- A header with "Last reviewed" date (today's date)
- All sections from step 3, refined based on user feedback from step 4
- A note that the wr-jtbd:agent reads this file to review UI changes against user jobs

If updating rather than creating:
- Preserve existing content the user hasn't asked to change
- Show the user a diff of what changed
- Update the "Last reviewed" date

$ARGUMENTS
