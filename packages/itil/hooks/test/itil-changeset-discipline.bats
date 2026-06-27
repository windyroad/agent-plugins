#!/usr/bin/env bats

# P141: itil-changeset-discipline.sh PreToolUse:Bash hook must deny
# `git commit` invocations whose staged set includes packages/<plugin>/
# source files but no .changeset/*.md is staged. Hook-level enforcement
# replaces unreliable iter-prompt-time changeset reminders (40% miss
# rate observed in 2026-04-28 AFK loop session).
#
# Detection logic (per ticket Fix Strategy):
#   On `git commit` invocations, run `git diff --staged --name-only`.
#   If any path matches packages/<plugin>/<non-allow-listed> AND no
#   .changeset/*.md (excluding README.md / config.json) is staged,
#   emit a deny with recovery directive `bun run changeset` and the
#   P141 cite. Allow when at least one valid changeset is staged, when
#   staged packages/<plugin>/ files are entirely allow-listed (test
#   paths or doc paths), or when BYPASS_CHANGESET_GATE=1 is set.
#
# Per ADR-005 (plugin testing strategy) — hook bats live under
# packages/<plugin>/hooks/test/ and assert behaviour on emitted JSON,
# not source-content. Per P081 — no source-grep on hook text. Simulate
# the PreToolUse:Bash payload on stdin and assert on the emitted
# permissionDecision.
#
# Per ADR-045 Pattern 1 (silent-on-pass) — allow paths emit 0 bytes.
# Per ADR-045 deny-band — deny messages target ~245 bytes; cap at 300.

setup() {
  SCRIPT_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  HOOK="$SCRIPT_DIR/itil-changeset-discipline.sh"
  ORIG_DIR="$PWD"
  TEST_DIR=$(mktemp -d)
  cd "$TEST_DIR"
  git init --quiet -b main
  git config user.email "test@example.com"
  git config user.name "Test"
  mkdir -p packages/itil/skills/foo packages/itil/hooks packages/itil/hooks/test \
           packages/itil/hooks/lib packages/itil/scripts/test packages/itil/docs \
           packages/itil/.claude-plugin .changeset .github/workflows docs
  echo "seed" > seed.txt
  git add seed.txt
  git -c commit.gpgsign=false commit --quiet -m "initial"
  unset BYPASS_CHANGESET_GATE
}

teardown() {
  cd "$ORIG_DIR"
  rm -rf "$TEST_DIR"
  unset BYPASS_CHANGESET_GATE
}

run_bash_hook() {
  local cmd="$1"
  local json
  json=$(printf '{"tool_name":"Bash","tool_input":{"command":"%s"}}' "$cmd")
  echo "$json" | bash "$HOOK"
}

# --- Trap detection: the canonical P141 shape ---

@test "deny: staged packages/<plugin>/ source without changeset triggers deny on git commit" {
  echo "skill body" > packages/itil/skills/foo/SKILL.md
  git add packages/itil/skills/foo/SKILL.md
  run run_bash_hook "git commit -m 'feat'"
  [ "$status" -eq 0 ]
  [[ "$output" == *"\"permissionDecision\": \"deny\""* ]]
  [[ "$output" == *"P141"* ]]
}

@test "deny: staged packages/<plugin>/hooks/ shell source without changeset triggers deny" {
  echo "#!/bin/bash" > packages/itil/hooks/new-hook.sh
  git add packages/itil/hooks/new-hook.sh
  run run_bash_hook "git commit -m 'feat'"
  [ "$status" -eq 0 ]
  [[ "$output" == *"\"permissionDecision\": \"deny\""* ]]
  [[ "$output" == *"P141"* ]]
}

@test "deny: staged plugin.json without changeset triggers deny" {
  echo "{}" > packages/itil/.claude-plugin/plugin.json
  git add packages/itil/.claude-plugin/plugin.json
  run run_bash_hook "git commit -m 'feat'"
  [ "$status" -eq 0 ]
  [[ "$output" == *"\"permissionDecision\": \"deny\""* ]]
}

@test "deny message names plugin slug, recovery command, P141 cite" {
  echo "skill body" > packages/itil/skills/foo/SKILL.md
  git add packages/itil/skills/foo/SKILL.md
  run run_bash_hook "git commit -m 'feat'"
  [ "$status" -eq 0 ]
  [[ "$output" == *"itil"* ]]
  [[ "$output" == *"changeset"* ]]
  [[ "$output" == *"P141"* ]]
}

@test "deny message stays under ADR-045 deny-band (<300 bytes)" {
  echo "skill body" > packages/itil/skills/foo/SKILL.md
  git add packages/itil/skills/foo/SKILL.md
  run run_bash_hook "git commit -m 'feat'"
  [ "$status" -eq 0 ]
  [ "${#output}" -lt 300 ]
}

# P173: the deny must NOT advertise the env bypass as an in-flight escape.
# BYPASS_CHANGESET_GATE only takes effect when set in Claude Code's process
# env before the session started; a mid-session Bash `export`/inline assignment
# never reaches the hook. The deny clarifies the bypass is pre-session.
@test "P173 deny message clarifies the env bypass is pre-session (not a mid-session action)" {
  echo "skill body" > packages/itil/skills/foo/SKILL.md
  git add packages/itil/skills/foo/SKILL.md
  run run_bash_hook "git commit -m 'feat'"
  [ "$status" -eq 0 ]
  [[ "$output" == *"\"permissionDecision\": \"deny\""* ]]
  [[ "$output" == *"pre-session"* ]]
}

# --- Allow paths: each non-trap shape must NOT deny ---

@test "allow: staged packages/<plugin>/ source WITH a staged changeset allows the commit" {
  echo "skill body" > packages/itil/skills/foo/SKILL.md
  echo "---" > .changeset/wr-itil-p141.md
  echo '"@windyroad/itil": patch' >> .changeset/wr-itil-p141.md
  echo "---" >> .changeset/wr-itil-p141.md
  echo "fix the thing" >> .changeset/wr-itil-p141.md
  git add packages/itil/skills/foo/SKILL.md .changeset/wr-itil-p141.md
  run run_bash_hook "git commit -m 'feat'"
  [ "$status" -eq 0 ]
  [[ "$output" != *"\"permissionDecision\": \"deny\""* ]]
}

@test "allow: staged test-only changes under packages/<plugin>/hooks/test/ allow without changeset" {
  echo "#!/usr/bin/env bats" > packages/itil/hooks/test/new-test.bats
  git add packages/itil/hooks/test/new-test.bats
  run run_bash_hook "git commit -m 'test'"
  [ "$status" -eq 0 ]
  [[ "$output" != *"\"permissionDecision\": \"deny\""* ]]
}

@test "allow: staged test-only changes under packages/<plugin>/scripts/test/ allow without changeset" {
  echo "#!/usr/bin/env bats" > packages/itil/scripts/test/new-script-test.bats
  git add packages/itil/scripts/test/new-script-test.bats
  run run_bash_hook "git commit -m 'test'"
  [ "$status" -eq 0 ]
  [[ "$output" != *"\"permissionDecision\": \"deny\""* ]]
}

@test "allow: staged packages/<plugin>/README.md alone allows without changeset (doc-only)" {
  echo "# itil" > packages/itil/README.md
  git add packages/itil/README.md
  run run_bash_hook "git commit -m 'docs'"
  [ "$status" -eq 0 ]
  [[ "$output" != *"\"permissionDecision\": \"deny\""* ]]
}

@test "allow: staged docs under packages/<plugin>/docs/ allow without changeset (doc-only)" {
  echo "# guide" > packages/itil/docs/guide.md
  git add packages/itil/docs/guide.md
  run run_bash_hook "git commit -m 'docs'"
  [ "$status" -eq 0 ]
  [[ "$output" != *"\"permissionDecision\": \"deny\""* ]]
}

@test "deny: staged SKILL.md (NOT in allow-list per architect amendment) triggers deny" {
  echo "skill body" > packages/itil/skills/foo/SKILL.md
  git add packages/itil/skills/foo/SKILL.md
  run run_bash_hook "git commit -m 'feat'"
  [ "$status" -eq 0 ]
  [[ "$output" == *"\"permissionDecision\": \"deny\""* ]]
}

@test "allow: staged .github/ workflow change without changeset (non-publishable path)" {
  echo "name: ci" > .github/workflows/ci.yml
  git add .github/workflows/ci.yml
  run run_bash_hook "git commit -m 'ci'"
  [ "$status" -eq 0 ]
  [[ "$output" != *"\"permissionDecision\": \"deny\""* ]]
}

@test "allow: staged top-level docs/ change without changeset (non-publishable path)" {
  echo "# briefing" > docs/BRIEFING.md
  git add docs/BRIEFING.md
  run run_bash_hook "git commit -m 'docs'"
  [ "$status" -eq 0 ]
  [[ "$output" != *"\"permissionDecision\": \"deny\""* ]]
}

@test "allow: BYPASS_CHANGESET_GATE=1 env var allows packages/<plugin>/ commit without changeset" {
  echo "skill body" > packages/itil/skills/foo/SKILL.md
  git add packages/itil/skills/foo/SKILL.md
  BYPASS_CHANGESET_GATE=1 run run_bash_hook "git commit -m 'feat'"
  [ "$status" -eq 0 ]
  [[ "$output" != *"\"permissionDecision\": \"deny\""* ]]
}

# --- Allow path silence (ADR-045 Pattern 1) ---

@test "allow path emits 0 bytes (ADR-045 Pattern 1 silent-on-pass)" {
  echo "#!/usr/bin/env bats" > packages/itil/hooks/test/new-test.bats
  git add packages/itil/hooks/test/new-test.bats
  run run_bash_hook "git commit -m 'test'"
  [ "$status" -eq 0 ]
  [ "${#output}" -eq 0 ]
}

# --- Tool-name and command-shape filters ---

@test "allow: non-Bash tool exits 0 without deny" {
  run bash -c "echo '{\"tool_name\":\"Edit\",\"tool_input\":{\"file_path\":\"foo.md\"}}' | bash $HOOK"
  [ "$status" -eq 0 ]
  [[ "$output" != *"\"permissionDecision\": \"deny\""* ]]
}

@test "allow: Bash command that is NOT git commit (e.g., git status) bypasses detection" {
  echo "skill body" > packages/itil/skills/foo/SKILL.md
  git add packages/itil/skills/foo/SKILL.md
  run run_bash_hook "git status"
  [ "$status" -eq 0 ]
  [[ "$output" != *"\"permissionDecision\": \"deny\""* ]]
}

# --- Changeset variants: README.md and config.json don't count as a real changeset ---

@test "deny: staged .changeset/README.md alone does NOT count as a valid changeset" {
  echo "skill body" > packages/itil/skills/foo/SKILL.md
  echo "# changesets" > .changeset/README.md
  git add packages/itil/skills/foo/SKILL.md .changeset/README.md
  run run_bash_hook "git commit -m 'feat'"
  [ "$status" -eq 0 ]
  [[ "$output" == *"\"permissionDecision\": \"deny\""* ]]
}

# --- P177: held-window directory recognition (ADR-042 Rule 7) ---
#
# P141's gate purpose is "every publishable iter has a changeset to drain".
# A `docs/changesets-holding/<name>.md` entry IS a changeset — authored and
# audit-trailed, just intentionally held outside `.changeset/` per ADR-042
# Rule 7 (held-window blessing). Before P177 the gate ignored the holding
# directory (held entries fell through the `*)` catch-all), forcing held-
# window-bound work through a 2-commit workaround (work commit + a separate
# `chore(changeset): move ... to holding`). The gate now recognises a staged
# held entry as satisfying the discipline, mirroring the `.changeset/*.md`
# branch (and its README.md meta-doc exclusion). Release/drain semantics are
# unchanged — the Release workflow reads `.changeset/` only; a held entry is
# recognised at the commit-gate layer, never drained without a graduation
# `git mv` back into `.changeset/`.

@test "P177 allow: staged packages/<plugin>/ source WITH a staged docs/changesets-holding/ entry allows the commit" {
  echo "skill body" > packages/itil/skills/foo/SKILL.md
  mkdir -p docs/changesets-holding
  printf -- '---\n"@windyroad/itil": patch\n---\nheld fix\n' > docs/changesets-holding/wr-itil-p177.md
  git add packages/itil/skills/foo/SKILL.md docs/changesets-holding/wr-itil-p177.md
  run run_bash_hook "git commit -m 'feat'"
  [ "$status" -eq 0 ]
  [[ "$output" != *"\"permissionDecision\": \"deny\""* ]]
}

@test "P177 allow path with held-window entry emits 0 bytes (ADR-045 Pattern 1 silent-on-pass)" {
  echo "skill body" > packages/itil/skills/foo/SKILL.md
  mkdir -p docs/changesets-holding
  printf -- '---\n"@windyroad/itil": patch\n---\nheld fix\n' > docs/changesets-holding/wr-itil-p177.md
  git add packages/itil/skills/foo/SKILL.md docs/changesets-holding/wr-itil-p177.md
  run run_bash_hook "git commit -m 'feat'"
  [ "$status" -eq 0 ]
  [ "${#output}" -eq 0 ]
}

@test "P177 deny: staged docs/changesets-holding/README.md alone does NOT count as a valid held changeset" {
  echo "skill body" > packages/itil/skills/foo/SKILL.md
  mkdir -p docs/changesets-holding
  echo "# Changesets Holding Area" > docs/changesets-holding/README.md
  git add packages/itil/skills/foo/SKILL.md docs/changesets-holding/README.md
  run run_bash_hook "git commit -m 'feat'"
  [ "$status" -eq 0 ]
  [[ "$output" == *"\"permissionDecision\": \"deny\""* ]]
}

@test "P177 deny: staged source with NEITHER .changeset/*.md NOR a holding entry still denies (regression guard)" {
  echo "skill body" > packages/itil/skills/foo/SKILL.md
  git add packages/itil/skills/foo/SKILL.md
  run run_bash_hook "git commit -m 'feat'"
  [ "$status" -eq 0 ]
  [[ "$output" == *"\"permissionDecision\": \"deny\""* ]]
  [[ "$output" == *"P141"* ]]
}

# --- Mixed staged sets ---

@test "deny: staged source + test in same commit still requires changeset (mixed set)" {
  echo "skill body" > packages/itil/skills/foo/SKILL.md
  echo "#!/usr/bin/env bats" > packages/itil/hooks/test/new-test.bats
  git add packages/itil/skills/foo/SKILL.md packages/itil/hooks/test/new-test.bats
  run run_bash_hook "git commit -m 'feat'"
  [ "$status" -eq 0 ]
  [[ "$output" == *"\"permissionDecision\": \"deny\""* ]]
}

# --- Parse / fail-open contracts ---

@test "allow: empty JSON exits 0 without deny (fail-open on parse-incomplete)" {
  run bash -c "echo '{}' | bash $HOOK"
  [ "$status" -eq 0 ]
  [[ "$output" != *"\"permissionDecision\": \"deny\""* ]]
}

@test "allow: outside a git work tree exits 0 without deny (fail-open)" {
  cd "$ORIG_DIR"
  TEMP_NONGIT=$(mktemp -d)
  cd "$TEMP_NONGIT"
  run run_bash_hook "git commit -m 'feat'"
  cd "$TEST_DIR"
  rm -rf "$TEMP_NONGIT"
  [ "$status" -eq 0 ]
  [[ "$output" != *"\"permissionDecision\": \"deny\""* ]]
}

# --- P272: substring-vs-invocation regression coverage ---
#
# Prior to P272, the hook used `case "$COMMAND" in *"git commit"*) ;;`
# which fired on ANY Bash command whose text contained the literal
# phrase "git commit" — including grep patterns, sed substitutions,
# cat heredoc bodies, echo strings, and `git log --grep` queries.
# Workaround was stage-changeset-first-or-different-shell, observed
# ≥3 events per session in the P268 sibling-hook class.
# P272 replaces that match with a leading-executable-token check via
# `lib/command-detect.sh::command_invokes_git_commit` (the shared
# helper landed by P268). The tests below stage `@windyroad/itil/`
# source (which would trigger deny if the gate fired) and run various
# non-commit Bash commands whose argument vectors mention `git commit`.
# The hook MUST pass silently.

@test "P272 allow: grep with 'git commit' pattern does NOT trigger gate" {
  echo "skill body" > packages/itil/skills/foo/SKILL.md
  git add packages/itil/skills/foo/SKILL.md
  run run_bash_hook "grep -n 'git commit' file.md"
  [ "$status" -eq 0 ]
  [[ "$output" != *"\"permissionDecision\": \"deny\""* ]]
  # Silent pass per ADR-045 Pattern 1.
  [ "${#output}" -eq 0 ]
}

@test "P272 allow: grep -rn 'git commit' packages/ (the recurring orchestrator surface)" {
  echo "skill body" > packages/itil/skills/foo/SKILL.md
  git add packages/itil/skills/foo/SKILL.md
  run run_bash_hook "grep -rn 'git commit' packages/"
  [ "$status" -eq 0 ]
  [[ "$output" != *"\"permissionDecision\": \"deny\""* ]]
  [ "${#output}" -eq 0 ]
}

@test "P272 allow: sed -i 's/git commit/.../' substitution does NOT trigger gate" {
  echo "skill body" > packages/itil/skills/foo/SKILL.md
  git add packages/itil/skills/foo/SKILL.md
  run run_bash_hook "sed -i 's/git commit/git push/' file.md"
  [ "$status" -eq 0 ]
  [[ "$output" != *"\"permissionDecision\": \"deny\""* ]]
  [ "${#output}" -eq 0 ]
}

@test "P272 allow: echo with 'git commit' inside string does NOT trigger gate" {
  echo "skill body" > packages/itil/skills/foo/SKILL.md
  git add packages/itil/skills/foo/SKILL.md
  run run_bash_hook "echo 'the git commit gate fires here'"
  [ "$status" -eq 0 ]
  [[ "$output" != *"\"permissionDecision\": \"deny\""* ]]
  [ "${#output}" -eq 0 ]
}

@test "P272 allow: git log --grep 'git commit' does NOT trigger gate (git log is leading)" {
  echo "skill body" > packages/itil/skills/foo/SKILL.md
  git add packages/itil/skills/foo/SKILL.md
  run run_bash_hook "git log --grep 'git commit'"
  [ "$status" -eq 0 ]
  [[ "$output" != *"\"permissionDecision\": \"deny\""* ]]
  [ "${#output}" -eq 0 ]
}

@test "P272 allow: cat heredoc whose body contains 'git commit' does NOT trigger gate (retro-write surface)" {
  echo "skill body" > packages/itil/skills/foo/SKILL.md
  git add packages/itil/skills/foo/SKILL.md
  # Inline-build JSON with embedded newlines via python3 to mimic the
  # Bash tool's multi-line command payload (the canonical retro-write
  # surface that misfired in the P268 sibling).
  local payload
  payload=$(python3 -c "import json,sys; print(json.dumps({'tool_name':'Bash','tool_input':{'command':'cat >> docs/problems/README-history.md <<EOF\nFlow note: the git commit gate fires here.\nEOF'}}))")
  run bash -c "echo '$payload' | bash $HOOK"
  [ "$status" -eq 0 ]
  [[ "$output" != *"\"permissionDecision\": \"deny\""* ]]
  [ "${#output}" -eq 0 ]
}

@test "P272 allow: git commit-tree (boundary check — commit-tree is a different plumbing command)" {
  echo "skill body" > packages/itil/skills/foo/SKILL.md
  git add packages/itil/skills/foo/SKILL.md
  run run_bash_hook "git commit-tree HEAD^{tree}"
  [ "$status" -eq 0 ]
  [[ "$output" != *"\"permissionDecision\": \"deny\""* ]]
  [ "${#output}" -eq 0 ]
}

@test "P272 deny: actual git commit invocation with staged packages/<plugin>/ source still triggers gate (positive regression)" {
  echo "skill body" > packages/itil/skills/foo/SKILL.md
  git add packages/itil/skills/foo/SKILL.md
  run run_bash_hook "git commit -m 'feat'"
  [ "$status" -eq 0 ]
  [[ "$output" == *"\"permissionDecision\": \"deny\""* ]]
  [[ "$output" == *"P141"* ]]
}

@test "P272 deny: cd <path> && git commit (prefix-strip path) still triggers gate" {
  echo "skill body" > packages/itil/skills/foo/SKILL.md
  git add packages/itil/skills/foo/SKILL.md
  run run_bash_hook "cd . && git commit -m 'feat'"
  [ "$status" -eq 0 ]
  [[ "$output" == *"\"permissionDecision\": \"deny\""* ]]
}

@test "P272 deny: GIT_AUTHOR_NAME=Test git commit (env-prefix path) still triggers gate" {
  echo "skill body" > packages/itil/skills/foo/SKILL.md
  git add packages/itil/skills/foo/SKILL.md
  run run_bash_hook "GIT_AUTHOR_NAME=Test git commit -m 'feat'"
  [ "$status" -eq 0 ]
  [[ "$output" == *"\"permissionDecision\": \"deny\""* ]]
}

# --- P141 Phase 2: in-scope-changeset coverage for multi-commit slices ---
#
# Phase 2 amendment (2026-05-31) widens the allow path: a `.changeset/*.md`
# already in the unpushed slice scope (committed in a prior unpushed commit,
# untracked in the working tree, or modified-not-staged) that targets the
# plugin via its YAML frontmatter `"@windyroad/<plugin>": <any-bump>` line
# also satisfies the gate. Phase 1 strict-deny behaviour preserved for the
# no-coverage case.
#
# Scope boundary: `<base>..HEAD` where base = `@{u}` upstream tracking branch
# with fallback to `origin/main`. Once a changeset is on `origin/<base>`
# (drained by changesets-action), it no longer counts — Phase 2 boundary
# fixture below proves this.
#
# Per-plugin granularity: an `@windyroad/itil` changeset does NOT cover a
# `packages/voice-tone/` commit — wrong-plugin negative fixture below.

# Helper: mark the current HEAD as `origin/main` so subsequent commits
# fall into the unpushed-range scope `origin/main..HEAD`. The bats setup
# creates a local repo with no remote; this synthesises an origin/main
# ref via `git update-ref` for behavioural testing.
mark_origin_at_head() {
  git update-ref refs/remotes/origin/main HEAD
}

@test "P141 Phase 2 allow: in-range committed changeset for plugin covers subsequent same-plugin commit" {
  mark_origin_at_head
  # Commit 1: ship the changeset + initial source together (Phase 1 case).
  echo "skill body 1" > packages/itil/skills/foo/SKILL.md
  printf -- '---\n"@windyroad/itil": patch\n---\nfix the thing\n' > .changeset/wr-itil-p347.md
  git add packages/itil/skills/foo/SKILL.md .changeset/wr-itil-p347.md
  git -c commit.gpgsign=false commit --quiet -m "feat 1"
  # Commit 2: stage more itil source — no new changeset, but the in-range
  # changeset from commit 1 covers @windyroad/itil. Gate must allow.
  echo "more skill" > packages/itil/skills/foo/SKILL.md
  git add packages/itil/skills/foo/SKILL.md
  run run_bash_hook "git commit -m 'feat 2'"
  [ "$status" -eq 0 ]
  [[ "$output" != *"\"permissionDecision\": \"deny\""* ]]
  # Silent pass per ADR-045 Pattern 1.
  [ "${#output}" -eq 0 ]
}

@test "P141 Phase 2 deny boundary: changeset consumed onto origin no longer counts; fresh required" {
  # Commit 1: ship the changeset onto the base.
  printf -- '---\n"@windyroad/itil": patch\n---\nfix the thing\n' > .changeset/wr-itil-p347.md
  git add .changeset/wr-itil-p347.md
  git -c commit.gpgsign=false commit --quiet -m "changeset on base"
  # Mark as drained-to-origin — changesets-action consumed it at release.
  mark_origin_at_head
  # Remove the file as changesets-action would on consumption.
  git rm --quiet .changeset/wr-itil-p347.md
  git -c commit.gpgsign=false commit --quiet -m "changeset consumed on origin"
  mark_origin_at_head
  # Now stage fresh itil source — no in-range changeset, no staged changeset.
  echo "skill body" > packages/itil/skills/foo/SKILL.md
  git add packages/itil/skills/foo/SKILL.md
  run run_bash_hook "git commit -m 'feat'"
  [ "$status" -eq 0 ]
  [[ "$output" == *"\"permissionDecision\": \"deny\""* ]]
  [[ "$output" == *"P141"* ]]
}

@test "P141 Phase 2 deny: in-range changeset for DIFFERENT plugin does not cover this plugin's source (wrong-plugin)" {
  mark_origin_at_head
  # Commit 1: ship an @windyroad/itil changeset.
  echo "itil source" > packages/itil/skills/foo/SKILL.md
  printf -- '---\n"@windyroad/itil": patch\n---\nfix itil\n' > .changeset/wr-itil-p347.md
  git add packages/itil/skills/foo/SKILL.md .changeset/wr-itil-p347.md
  git -c commit.gpgsign=false commit --quiet -m "feat itil"
  # Commit 2: stage voice-tone source. The in-range itil changeset must
  # NOT satisfy the gate for a different plugin (per-plugin granularity).
  mkdir -p packages/voice-tone/src
  echo "voice source" > packages/voice-tone/src/x.ts
  git add packages/voice-tone/src/x.ts
  run run_bash_hook "git commit -m 'feat voice'"
  [ "$status" -eq 0 ]
  [[ "$output" == *"\"permissionDecision\": \"deny\""* ]]
  # Deny message names the offending plugin slug — voice-tone, not itil.
  [[ "$output" == *"voice-tone"* ]]
}

@test "P141 Phase 2 allow: untracked .changeset/*.md targeting plugin covers staged source" {
  mark_origin_at_head
  # Author the changeset to disk but DO NOT stage. Gate must still
  # recognise it via `git ls-files --others --exclude-standard`.
  printf -- '---\n"@windyroad/itil": minor\n---\nfeature\n' > .changeset/wr-itil-p347.md
  echo "skill body" > packages/itil/skills/foo/SKILL.md
  git add packages/itil/skills/foo/SKILL.md
  run run_bash_hook "git commit -m 'feat'"
  [ "$status" -eq 0 ]
  [[ "$output" != *"\"permissionDecision\": \"deny\""* ]]
  [ "${#output}" -eq 0 ]
}

@test "P141 Phase 2 allow: in-range changeset that was modified-not-staged still covers" {
  mark_origin_at_head
  # Commit 1: ship the changeset.
  printf -- '---\n"@windyroad/itil": patch\n---\noriginal\n' > .changeset/wr-itil-p347.md
  git add .changeset/wr-itil-p347.md
  git -c commit.gpgsign=false commit --quiet -m "changeset"
  # Modify the prose body (frontmatter preserved); do NOT stage the edit.
  printf -- '---\n"@windyroad/itil": patch\n---\nedited prose\n' > .changeset/wr-itil-p347.md
  # Stage source.
  echo "skill body" > packages/itil/skills/foo/SKILL.md
  git add packages/itil/skills/foo/SKILL.md
  run run_bash_hook "git commit -m 'feat'"
  [ "$status" -eq 0 ]
  [[ "$output" != *"\"permissionDecision\": \"deny\""* ]]
}

@test "P141 Phase 2 deny: in-range changeset for plugin exists but its frontmatter targets a different plugin slug" {
  mark_origin_at_head
  # A changeset committed in-range whose frontmatter declares ONLY
  # @windyroad/voice-tone, not @windyroad/itil. Staged source is itil.
  # Check 2b must NOT match (frontmatter scan is per-plugin-slug).
  printf -- '---\n"@windyroad/voice-tone": patch\n---\nfix voice\n' > .changeset/wr-voice-p999.md
  git add .changeset/wr-voice-p999.md
  git -c commit.gpgsign=false commit --quiet -m "voice changeset"
  echo "skill body" > packages/itil/skills/foo/SKILL.md
  git add packages/itil/skills/foo/SKILL.md
  run run_bash_hook "git commit -m 'feat itil'"
  [ "$status" -eq 0 ]
  [[ "$output" == *"\"permissionDecision\": \"deny\""* ]]
  [[ "$output" == *"itil"* ]]
}

@test "P141 Phase 2 allow: held-window docs/changesets-holding/*.md in-range entry also covers (ADR-042 Rule 7 composes with Phase 2)" {
  mark_origin_at_head
  mkdir -p docs/changesets-holding
  printf -- '---\n"@windyroad/itil": patch\n---\nheld fix\n' > docs/changesets-holding/wr-itil-p347.md
  git add docs/changesets-holding/wr-itil-p347.md
  git -c commit.gpgsign=false commit --quiet -m "held changeset"
  # Subsequent itil source commit — held entry in range covers.
  echo "skill body" > packages/itil/skills/foo/SKILL.md
  git add packages/itil/skills/foo/SKILL.md
  run run_bash_hook "git commit -m 'feat'"
  [ "$status" -eq 0 ]
  [[ "$output" != *"\"permissionDecision\": \"deny\""* ]]
}

@test "P141 Phase 2: when no upstream and no origin/main ref exists, Check 2b skips silently and Phase 1 strict-deny is preserved" {
  # No mark_origin_at_head — refs/remotes/origin/main is absent.
  # Stage source without any changeset. Phase 1 strict-deny must fire
  # (Check 2b returns 1 on missing base, Check 2a returns 0).
  echo "skill body" > packages/itil/skills/foo/SKILL.md
  git add packages/itil/skills/foo/SKILL.md
  run run_bash_hook "git commit -m 'feat'"
  [ "$status" -eq 0 ]
  [[ "$output" == *"\"permissionDecision\": \"deny\""* ]]
  [[ "$output" == *"P141"* ]]
}

# --- P387: Check 2b is change-scoped, not merely plugin-scoped ---
#
# P141 Phase 2's Check 2b passed a plugin-source commit if ANY in-scope
# changeset targeted the plugin — even one authored for a DIFFERENT change.
# So a change shipped to npm with no CHANGELOG record of its own, riding a
# sibling changeset's coattails (witnessed: P164's octal fix shipped
# undocumented under P374's changeset, @windyroad/risk-scorer 0.13.5/0.14.0).
#
# P387 tightens Check 2b to change-scoped via conservative work-item-ID
# (ticket) keying. The commit's work-item IDs (P<NNN> / RFC-<NNN> /
# STORY-<NNN>, extracted from the git-commit COMMAND string passed into the
# helper) are compared against each in-scope covering changeset's work-item
# IDs (extracted from its filename + body). Check 2b DENIES only on positive
# evidence of an unrelated sibling: the commit cites work-item ID(s), EVERY
# covering changeset cites work-item ID(s), and none overlap. Any ambiguity
# allows — a ticket-less commit, a prose-only changeset, or an ID overlap.
# This preserves the ADR-014 batch-grain (same-slice commits share a ticket,
# so the slice's changeset still covers them) and never over-fires on
# adopter/prose-only changesets that carry no ticket ref.

@test "P387 deny: plugin-source commit citing a DIFFERENT ticket than the only in-scope changeset (unrelated sibling) denies" {
  mark_origin_at_head
  # Commit 1: P374's changeset + its source.
  echo "p374 work" > packages/itil/skills/foo/SKILL.md
  printf -- '---\n"@windyroad/itil": patch\n---\nP374 work. Refs: P374.\n' > .changeset/wr-itil-p374.md
  git add packages/itil/skills/foo/SKILL.md .changeset/wr-itil-p374.md
  git -c commit.gpgsign=false commit --quiet -m "fix(itil): P374 work (P374)"
  # Commit 2: P164's UNRELATED fix — stages itil source, authors NO changeset.
  # The only in-scope changeset is P374's. Change-scoped Check 2b must DENY.
  echo "octal fix" > packages/itil/scripts/extract.sh
  git add packages/itil/scripts/extract.sh
  run run_bash_hook "git commit -m 'fix(itil): octal eval (P164)'"
  [ "$status" -eq 0 ]
  [[ "$output" == *"\"permissionDecision\": \"deny\""* ]]
  [[ "$output" == *"P141"* ]]
  [[ "$output" == *"itil"* ]]
}

@test "P387 allow: plugin-source commit citing the SAME ticket as the in-scope changeset (same change) allows" {
  mark_origin_at_head
  # Commit 1: P347's changeset + slice-1 source.
  echo "p347 slice 1" > packages/itil/skills/foo/SKILL.md
  printf -- '---\n"@windyroad/itil": patch\n---\nP347 slice. Refs: P347.\n' > .changeset/wr-itil-p347.md
  git add packages/itil/skills/foo/SKILL.md .changeset/wr-itil-p347.md
  git -c commit.gpgsign=false commit --quiet -m "feat(itil): P347 slice 1 (P347)"
  # Commit 2: same P347 slice — no new changeset; the in-range P347 changeset
  # shares the commit's ticket, so the ADR-014 batch is preserved. Allow.
  echo "p347 slice 2" > packages/itil/skills/foo/SKILL.md
  git add packages/itil/skills/foo/SKILL.md
  run run_bash_hook "git commit -m 'feat(itil): P347 slice 2 (P347)'"
  [ "$status" -eq 0 ]
  [[ "$output" != *"\"permissionDecision\": \"deny\""* ]]
  [ "${#output}" -eq 0 ]
}

@test "P387 allow: plugin-source commit with NO work-item ID falls back to plugin-scoped allow (conservative)" {
  mark_origin_at_head
  # In-range changeset cites P374; the new commit cites no ticket at all —
  # we cannot prove it is a DIFFERENT change, so we must not over-fire.
  printf -- '---\n"@windyroad/itil": patch\n---\nsome fix. Refs: P374.\n' > .changeset/wr-itil-p374.md
  git add .changeset/wr-itil-p374.md
  git -c commit.gpgsign=false commit --quiet -m "chore: add changeset"
  echo "skill body" > packages/itil/skills/foo/SKILL.md
  git add packages/itil/skills/foo/SKILL.md
  run run_bash_hook "git commit -m 'feat without a ticket ref'"
  [ "$status" -eq 0 ]
  [[ "$output" != *"\"permissionDecision\": \"deny\""* ]]
}

@test "P387 allow: prose-only in-scope changeset (no work-item ID) does not over-fire even when the commit cites a ticket" {
  mark_origin_at_head
  # An adopter (or a plain) changeset with no ticket ref in filename or body.
  # The commit cites P164, but we cannot prove the prose-only changeset is for
  # a different change, so Check 2b allows (no over-fire on prose changesets).
  printf -- '---\n"@windyroad/itil": patch\n---\nfix the thing\n' > .changeset/wr-itil-feature.md
  git add .changeset/wr-itil-feature.md
  git -c commit.gpgsign=false commit --quiet -m "chore: add changeset"
  echo "skill body" > packages/itil/skills/foo/SKILL.md
  git add packages/itil/skills/foo/SKILL.md
  run run_bash_hook "git commit -m 'fix(itil): a thing (P164)'"
  [ "$status" -eq 0 ]
  [[ "$output" != *"\"permissionDecision\": \"deny\""* ]]
}
