#!/bin/bash
# Voice & Tone - UserPromptSubmit hook
# Detects VOICE-AND-TONE.md in the project and injects delegation instruction.
# If the file doesn't exist, instructs Claude to create it via the agent.

if [ -f "docs/VOICE-AND-TONE.md" ]; then
  cat <<'HOOK_OUTPUT'
INSTRUCTION: MANDATORY VOICE & TONE CHECK. YOU MUST FOLLOW THIS.
DETECTED: docs/VOICE-AND-TONE.md exists in this project.

This is a NON-OPTIONAL instruction. You MUST use the voice-and-tone-lead agent
before editing any user-facing copy in HTML, JSX, template, or component files.
This is proactive. Do not wait for the user to ask.

REQUIRED ACTIONS:
1. Use the Agent tool to delegate to wr-voice-tone:agent
   (subagent_type: "wr-voice-tone:agent")
2. The voice-and-tone-lead will review proposed copy against docs/VOICE-AND-TONE.md
3. Do NOT write or edit copy without voice-and-tone-lead review FIRST
4. Do NOT skip this step even if you think you can handle it yourself

SCOPE: User-facing files (.html, .jsx, .tsx, .vue, .svelte, .ejs, .hbs).
Does NOT apply to: .css files, .ts/.js backend files, config files.
HOOK_OUTPUT
else
  # Check if this is a web project (has UI files)
  if ls src/**/*.tsx src/**/*.jsx src/**/*.html 2>/dev/null | head -1 | grep -q .; then
    cat <<'HOOK_OUTPUT'
NOTE: This project has UI files but no docs/VOICE-AND-TONE.md.
If the user's task involves editing user-facing copy, the edit will be blocked
until a voice and tone guide exists. Run /wr-voice-tone:update-guide to generate one.
HOOK_OUTPUT
  fi
fi
