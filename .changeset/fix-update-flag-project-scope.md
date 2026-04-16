---
"@windyroad/agent-plugins": patch
"@windyroad/architect": patch
"@windyroad/c4": patch
"@windyroad/connect": patch
"@windyroad/itil": patch
"@windyroad/jtbd": patch
"@windyroad/retrospective": patch
"@windyroad/risk-scorer": patch
"@windyroad/style-guide": patch
"@windyroad/tdd": patch
"@windyroad/voice-tone": patch
"@windyroad/wardley": patch
---

Fix `--update` flag failing with "Plugin not found" (P025). The `updatePlugin` command was missing the `@windyroad` marketplace suffix and `--scope project`, causing all `npx @windyroad/<pkg> --update` invocations to fail. The correct command is now used: `claude plugin update "<name>@windyroad" --scope project`.
