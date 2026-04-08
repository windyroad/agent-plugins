---
name: wr:voice-tone
description: Create or update the project's docs/VOICE-AND-TONE.md by examining existing content and asking the user about brand voice, audience, and tone preferences.
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion
---

# Voice and Tone Guide Generator

Create or update `docs/VOICE-AND-TONE.md` tailored to this project's brand, audience, and content. The voice-and-tone-lead agent reads this file to review user-facing copy.

## What belongs in docs/VOICE-AND-TONE.md

- **Brand voice**: The personality and character of the product's communication
- **Audience**: Who the product speaks to and their expectations
- **Tone spectrum**: How tone shifts across contexts (error messages vs success vs onboarding)
- **Do/Don't examples**: Concrete before/after examples drawn from the actual project
- **Terminology**: Preferred terms and terms to avoid
- **Last reviewed date**: When the guide was last reviewed or updated

## Steps

### 1. Discover project context

Examine the project to understand what it does, who uses it, and what voice it currently has.

**Find existing content** by scanning for:
- User-facing copy in UI files (.tsx, .jsx, .html, .vue, .svelte, .ejs, .hbs)
- README.md and documentation
- Error messages and validation text
- Marketing or landing page content
- Existing brand guidelines or tone documentation

**Identify the audience**:
- Is this a developer tool, consumer product, enterprise SaaS, documentation site?
- Who are the primary users? Technical or non-technical?
- What is the relationship between the product and its users (formal, casual, peer)?

**Sample existing voice**:
- Read 5-10 representative UI strings or content blocks
- Note patterns: formal vs casual, technical vs plain, terse vs verbose
- Identify inconsistencies that the guide should resolve

### 2. Check for existing guide

If `docs/VOICE-AND-TONE.md` already exists, read it. Identify:
- Whether the voice description still matches the current product direction
- Whether examples reference features or copy that no longer exists
- Whether the last reviewed date is stale (> 2 weeks)

### 3. Draft the voice and tone guide

Based on project discovery, draft sections covering:

**Brand Voice** (3-5 adjectives with explanations):
Example: "Confident but not arrogant. We know our product well but respect the user's expertise."

**Audience**:
Who we're speaking to and what they care about.

**Tone Spectrum**:
How tone adapts to context. Include at least:
- Success/confirmation messages
- Error/warning messages
- Onboarding/help text
- Empty states
- Technical documentation

**Do/Don't Examples**:
At least 5 concrete pairs drawn from the actual project's content patterns. Show the wrong way and the right way, with brief explanations.

**Terminology**:
- Preferred terms (and what they replace)
- Terms to avoid (and why)

### 4. Confirm with the user

You MUST use the AskUserQuestion tool to collect user confirmation. Do not proceed to step 5 until you have answers.

Present:
1. The drafted brand voice adjectives and ask if they match the intended personality
2. The audience description and ask if it's accurate
3. The do/don't examples and ask if the direction feels right
4. Whether any specific tone requirements are missing (e.g., accessibility language, inclusive language, regulatory constraints)

### 5. Write docs/VOICE-AND-TONE.md

Write the guide including:
- A header with "Last reviewed" date (today's date)
- All sections from step 3, refined based on user feedback from step 4
- A note that the wr-voice-tone:agent reads this file to review user-facing copy

If updating rather than creating:
- Preserve existing guidance the user hasn't asked to change
- Show the user a diff of what changed
- Update the "Last reviewed" date

$ARGUMENTS
