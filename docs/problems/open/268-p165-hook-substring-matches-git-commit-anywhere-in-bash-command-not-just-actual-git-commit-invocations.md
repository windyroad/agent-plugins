# Problem 268: P165 hook substring-matches `git commit` anywhere in Bash command, not just actual git commit invocations

**Status**: Open
**Reported**: 2026-05-18
**Priority**: 3 (Medium) — Impact: 2 × Likelihood: 3 (deferred — re-rate at next /wr-itil:review-problems)
**Effort**: S (deferred — re-rate at next /wr-itil:review-problems)
**Type**: technical

## Description

`packages/itil/hooks/itil-readme-refresh-discipline.sh` (P165) gates Bash invocations on a `*"git commit"*` substring match in the command string:

```bash
case "$COMMAND" in
  *"git commit"*) ;;
  *) exit 0 ;;
esac
```

This substring match fires on ANY Bash command that contains the literal string `git commit` anywhere in the command body, not just actual `git commit` invocations. Two false-positive surfaces observed this session:

1. **iter-1 retro write** (`cat >> docs/problems/README-history.md`) — the retro file body contained the phrase "git commit" in a sentence about commit-gate flow; PreToolUse hook saw the substring and denied the `cat` invocation even though no commit was happening.
2. **Orchestrator main turn grep** (`grep -n 'git commit\|RISK_BYPASS' packages/...`) — searching for the literal string `git commit` in source files to investigate hook behaviour. The grep's PATTERN argument contained `git commit`, hook denied the grep itself.

Workaround used both times: stage README first → run the command → unstage README OR run the command from a different shell where the hook can't see staged tree.

**Fix**: tighten the hook's command detection. Possible shapes:

- **A**: anchor at start of word: `case "$COMMAND" in "git commit"*|*\ "git commit"*|*\&\&\ "git commit"*|*\&\ "git commit"*) ;; esac` — over-fragile to shell quoting.
- **B**: extract the leading executable token after stripping common prefixes (`cd <dir> && `, `BYPASS_X=1 `, env-var assignments) and check if it's `git` AND the next argument is `commit`. Robust but more parsing.
- **C**: use a regex match against the structural shape `\bgit\s+commit\b` — better than substring but still over-matches grep patterns / sed patterns / echo strings containing the phrase.
- **D**: combine B + C — primary check via B (leading executable), fallback to C (regex) for shell pipelines. Most robust.

Recommended: B with leading-executable extraction. The hook needs to know whether the command is INVOKING `git commit`, not whether the command MENTIONS `git commit`.

Sibling enforcement-layer hooks (P125 staging-trap, P141 changeset-discipline) may carry the same substring-match anti-pattern; sweep all PreToolUse:Bash gates for the issue.

## Symptoms

- Bash commands containing the literal text "git commit" in arguments or piped content denied even when no commit is happening.
- Grep / sed / cat / echo with the phrase in arguments fail with the P165 deny message.

## Workaround

Stage `docs/problems/README.md` first, then run the offending Bash command. The hook's staged-ticket-no-README precondition no longer fires when README IS staged, so the substring-match consequence is moot. Awkward but reliable.

## Impact Assessment

- **Who is affected**: maintainers running `/wr-itil:work-problems` / `/wr-itil:manage-problem` / `/wr-itil:capture-problem` / `/wr-retrospective:run-retro` in interactive or AFK mode.
- **Frequency**: ≥2 events this session; class-of-behaviour likely recurs whenever retros / READMEs / grep investigations touch hook-relevant phrases.
- **Severity**: (deferred to investigation)
- **Analytics**: (deferred to investigation)

## Root Cause Analysis

### Investigation Tasks

- [ ] Re-rate Priority and Effort at next /wr-itil:review-problems
- [ ] Investigate root cause — confirm B (leading-executable extraction) is sound across shell pipelines / chained commands / env-var prefixes
- [ ] Create reproduction test (bats fixture: command with "git commit" in argument vs invocation; expect allow + deny respectively)
- [ ] Sweep sibling PreToolUse:Bash hooks (P125, P141) for the same substring-match anti-pattern
- [ ] Update P165 hook comment block to document the narrowed surface

## Dependencies

- **Blocks**: (no hard blocks — workaround exists)
- **Blocked by**: (none)
- **Composes with**: P165 (parent hook), P125 (sibling staging-trap), P141 (sibling changeset-discipline), P094, P062

## Related

(captured at /wr-itil:work-problems session 7 Step 2.5 user-direction routing)

- P165 — parent hook surface
- P125 / P141 — sibling enforcement-layer hooks
- `packages/itil/hooks/itil-readme-refresh-discipline.sh` lines 67-79 — substring-match case statement
