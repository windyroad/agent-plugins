#!/usr/bin/env bats

# P065 / ADR-036 / ADR-037 Confirmation: scaffold-intake's templates and
# SKILL.md must not leak absolute paths, host-specific identifiers, or
# secrets that would compromise downstream adopters who scaffold from
# them.
#
# Sentinel test: per ADR-037 "Source review", every skill that emits
# user-substituted content ships a `<skill>-secrets-absent.bats` to
# catch hardcoded environment leakage at PR time.

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../../../.." && pwd)"
  TEMPLATE_DIR="$REPO_ROOT/packages/itil/skills/scaffold-intake/templates"
  SKILL_MD="$REPO_ROOT/packages/itil/skills/scaffold-intake/SKILL.md"
}

# --- Templates: no absolute paths from the author's environment ---

@test "secrets-absent: templates contain no /Users/ or /home/ absolute paths" {
  run grep -rE '/Users/[a-zA-Z0-9_-]+/' "$TEMPLATE_DIR/"
  [ "$status" -ne 0 ]
  run grep -rE '/home/[a-zA-Z0-9_-]+/' "$TEMPLATE_DIR/"
  [ "$status" -ne 0 ]
}

@test "secrets-absent: templates contain no Windows-style absolute paths" {
  run grep -rE '[A-Z]:\\Users\\' "$TEMPLATE_DIR/"
  [ "$status" -ne 0 ]
}

# --- Templates: no obvious credential shapes ---

@test "secrets-absent: templates contain no credential-shaped tokens (AKIA, ghp_, sk_, github_pat_)" {
  run grep -rE 'AKIA[0-9A-Z]{16}|ghp_[A-Za-z0-9]{36}|github_pat_[A-Za-z0-9_]{80,}|sk_(live|test)_[A-Za-z0-9]{24,}' "$TEMPLATE_DIR/"
  [ "$status" -ne 0 ]
}

@test "secrets-absent: templates contain no aws_access or aws_secret keys in plain text" {
  run grep -rEi 'aws_access_key_id|aws_secret_access_key' "$TEMPLATE_DIR/"
  [ "$status" -ne 0 ]
}

# --- Templates: name-of-this-repo must be substituted, not hardcoded ---

@test "secrets-absent: templates do not hardcode 'windyroad/agent-plugins' (must use {{project_url}}/{{project_name}} substitution)" {
  # The author repo is windyroad/agent-plugins; downstream-scaffolded
  # files must use the per-project substitution token, not the literal
  # author repo. Otherwise downstream adopters get our SECURITY.md
  # advisory URL pointing to OUR security advisories, which is wrong.
  #
  # Allow it ONLY in commentary lines that explain "templated from this
  # repo's intake".
  run grep -rl 'windyroad/agent-plugins' "$TEMPLATE_DIR/"
  if [ "$status" -eq 0 ]; then
    # Anything found must be inside a comment explicitly framing it as
    # an example. Fail otherwise.
    while read -r f; do
      run grep -nE 'windyroad/agent-plugins' "$f"
      while read -r line; do
        line_no="${line%%:*}"
        line_text="${line#*:}"
        # Allow only if line begins with a comment marker (#) AND mentions example/seed.
        if echo "$line_text" | grep -qE '^[[:space:]]*#' && echo "$line_text" | grep -qiE 'example|seed|template|reference'; then
          continue
        fi
        echo "hardcoded windyroad/agent-plugins reference at $f:$line_no"
        echo "   $line_text"
        return 1
      done <<< "$output"
    done < <(grep -rl 'windyroad/agent-plugins' "$TEMPLATE_DIR/")
  fi
}

# --- SKILL.md: no transcript-leak shapes ---

@test "secrets-absent: SKILL.md contains no /Users/ or /home/ absolute paths" {
  run grep -E '/Users/[a-zA-Z0-9_-]+/' "$SKILL_MD"
  [ "$status" -ne 0 ]
  run grep -E '/home/[a-zA-Z0-9_-]+/' "$SKILL_MD"
  [ "$status" -ne 0 ]
}

@test "secrets-absent: SKILL.md contains no credential-shaped tokens" {
  run grep -E 'AKIA[0-9A-Z]{16}|ghp_[A-Za-z0-9]{36}|github_pat_[A-Za-z0-9_]{80,}' "$SKILL_MD"
  [ "$status" -ne 0 ]
}
