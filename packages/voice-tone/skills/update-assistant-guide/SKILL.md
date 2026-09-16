---
name: wr-voice-tone:update-assistant-guide
description: Create or update docs/ASSISTANT-VOICE-AND-TONE.md for project-specific assistant response voice, tone, and plain-language guidance.
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion
---

# Assistant Voice and Tone Guide Generator

Create or update `docs/ASSISTANT-VOICE-AND-TONE.md`. This guide governs the assistant's ordinary responses in this project when the file exists.

This is separate from `docs/VOICE-AND-TONE.md`, which governs project-authored copy and external communications.

## Contract

- File existence is the only opt-in switch.
- The guide body is prose. Do not add profiles, enabled flags, enforcement settings, deterministic rule tables, or a standards registry.
- Formal standards such as ISO 24495-1:2023 or ASD-STE100 may be named or described in prose, but the feature claims alignment, not certification.
- Creative voices should be described as traits and response qualities. Do not promise literal impersonation of a living person.
- When the user's direction is explicit, write the guide immediately. Do not add another confirmation or consent gate.
- Preserve unrelated existing prose. Replace or remove conflicting guidance only after confirming that exact change with the user.
- Never delete the guide unless the user explicitly asks to opt out.

## Workflow

Inspect the current project conventions and any existing `docs/ASSISTANT-VOICE-AND-TONE.md`. Draft concise prose that tells the assistant how responses should read, including any standards or creative traits the user asked for.

Before writing a new guide or materially changing an existing one, use `AskUserQuestion` to confirm the proposed direction when the user's intent is not already explicit.

Write or update the file with:

- a short title;
- the response voice and tone guidance;
- any named standards or creative traits expressed as prose;
- a short note that this is assistant-response guidance and does not certify conformance to external standards.

If updating, report the meaningful changes after writing.

$ARGUMENTS
