#!/bin/bash
# P141: shared changeset-discipline detection helper.
#
# `detect_changeset_required` returns 0 (no change required — allow) /
# 1 (changeset required but not staged — caller should deny). On 1, the
# offending plugin slug is echoed on stdout so callers can name it in
# deny messages without re-parsing diff output.
#
# Trap shape (P141):
#   `/wr-itil:work-problems` AFK iter subprocesses receive prompt-time
#   guidance to author a `.changeset/*.md` whenever they ship a
#   `packages/<plugin>/` change. Under context pressure (heavy SKILL.md
#   + ticket body + architect/JTBD prompt content) the reminder is
#   sometimes dropped — observed at 40% miss rate across 5 publishable
#   iters in the 2026-04-28 evidence session. Hook-level detection at
#   `git commit` time replaces the unreliable prompt-time signal.
#
# Detection logic:
#   - `git diff --staged --name-only` enumerates staged paths.
#   - Categorise each path:
#       * `.changeset/<name>.md` (excluding `README.md`) — counts as
#         a valid changeset.
#       * `packages/<slug>/...` — examined further:
#           - allow-list: `test/*`, `hooks/test/*`, `scripts/test/*`
#             (test code; no publishable behaviour change).
#           - allow-list: `README.md`.
#           - allow-list: `docs/<anything>.md` (per architect verdict
#             2026-05-02 — `*.md` under `docs/` only; SKILL.md is the
#             publishable contract per ADR-037 framing and is NOT in
#             the allow-list).
#           - otherwise: publishable source — record the slug.
#       * any other path: ignored (non-publishable surface — `.github/`,
#         root config, top-level `docs/`, etc.).
#   - If any path is publishable source:
#       * **Check 2a (Phase 1)**: a `.changeset/*.md` (or held-window
#         `docs/changesets-holding/*.md` per P177) staged → allow.
#       * **Check 2b (Phase 2)**: an in-scope `.changeset/*.md` (or
#         held-window entry) targeting the plugin via YAML frontmatter
#         `"@windyroad/<slug>": <any-bump>` → allow. Scope =
#         in-unpushed-range additions (`<base>..HEAD`) + untracked
#         working-tree files + modified-not-staged working-tree files.
#         Base = `@{u}` (current branch upstream) with fallback to
#         `origin/main`. Once consumed onto origin (drained by
#         changesets-action), the changeset is gone and a fresh one
#         is required.
#       * Neither check satisfied → return 1 + echo the slug.
#
# Phase 2 rationale (P141 2026-05-31): AFK orchestrator iters that
# ship a multi-commit slice for one plugin (e.g. P346 Phase 3 across
# 4 commits, 2 of which touched `packages/itil/`) should not author N
# redundant changesets for one logical bump. changesets-action
# collapses bump-class at version-package time, so per-commit
# changesets render N CHANGELOG bullets for one release entry. Phase
# 2's Check 2b lets the author write the changeset on the FIRST
# commit; subsequent same-plugin commits naturally allow because the
# changeset is already in the unpushed-range scope.
#
# Bypass:
#   - `BYPASS_CHANGESET_GATE=1` env var → return 0 (allow). For
#     legitimate non-publishable commits (e.g. CI-only changes
#     bundled with a small source tweak the agent has decided not
#     to release). Audit-traceable via shell history.
#
# Fail-open contract:
#   - Outside a git working tree, or when `git diff` fails for any
#     reason (parse error, broken index, permissions), return 0
#     (allow). Mirrors `lib/staging-detect.sh`'s exit-0 fallback —
#     a hook that fails-closed on hostile environments would block
#     legitimate commits in non-git contexts (e.g. agent-driven
#     scripts that happen to mention `git commit` in unrelated
#     contexts).
#
# Cost: one `git diff` invocation per check (~10ms on this repo's
# working tree). Per-invocation deterministic — runs on every
# `git commit` invocation rather than relying on per-tool-call
# session state tracking. Mirrors the P125 `staging-detect.sh`
# precedent (architect-approved no-marker design).
#
# References:
#   ADR-005  — plugin testing strategy (hook bats live under
#              `hooks/test/` per P081 behavioural-test discipline).
#   ADR-013 Rule 1 — deny redirects with mechanical recovery (the deny
#              text names the plugin slug + the literal `bun run
#              changeset` command + the BYPASS env var override).
#   ADR-014  — governance skills commit their own work (this hook
#              ensures iter commits stay self-contained per
#              ADR-014 single-commit grain).
#   ADR-018  — inter-iteration release cadence (this hook strengthens
#              the cadence by ensuring every publishable iter has a
#              changeset to drain at release time).
#   ADR-038  — progressive disclosure / deny-message terseness.
#   ADR-045  — hook injection budget (Pattern 1 silent-on-pass; deny
#              band ≤300 bytes for this hook).
#   P073     — sibling changeset author-time gate (different surface:
#              Write/Edit on `.changeset/*.md`). Composes-with as
#              defence-in-depth.
#   P125     — sibling staging-trap helper (same enforcement-layer
#              shape — per-invocation deterministic, no markers).
#   P141     — this helper.

# P141 Phase 2 helper — does any `.changeset/*.md` (or held entry under
# `docs/changesets-holding/*.md`) ALREADY in scope target the plugin
# slug via its YAML frontmatter `"@windyroad/<slug>": <bump>` line?
#
# Scope = files reachable from HEAD but not from `origin/<base>`,
# plus untracked working-tree changesets, plus modified-not-staged
# changesets. Once a changeset is on `origin/<base>` (drained by
# changesets-action at release time), it no longer counts — Check 2b
# requires a fresh changeset for the next slice.
#
# Per-plugin granularity (NOT per-bump-class — changesets-action
# collapses bump-class at version-package time when multiple
# changesets for the same plugin merge; the published bump-class is
# the maximum across the merged set).
#
# Base resolution: prefer the current branch's upstream (`@{u}`),
# fall back to `origin/main`. If neither resolves (e.g. fresh
# repo with no remotes), Check 2b returns 1 (no in-range scope to
# inspect) — Phase 1 strict-deny behaviour is preserved.
#
# Returns: 0 (≥1 in-scope changeset targets the plugin → paths echoed on
#            stdout, newline-separated, for the caller's change-scope check)
#          1 (no covering changeset found → caller falls through)
_changeset_in_scope_covers_plugin() {
  local slug="$1"
  local base
  local candidates path found=""

  base=$(git rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null) \
    || base="origin/main"
  git rev-parse --verify --quiet "$base" >/dev/null 2>&1 || return 1

  # Enumerate candidate changeset files:
  #   1. In-range additions: changesets added in unpushed commits
  #      (`<base>..HEAD`). A changeset later deleted in the same
  #      range is filtered by the on-disk existence check below.
  #   2. Untracked: changesets in the working tree not yet tracked
  #      by git (author wrote but did not stage).
  #   3. Modified-not-staged: changesets edited since their last
  #      commit but not yet re-staged.
  # Excludes `*/README.md` meta-docs (mirrors the staged-path branch).
  candidates=$(
    {
      git log --diff-filter=A --name-only --pretty=format: "${base}..HEAD" \
        -- '.changeset/*.md' 'docs/changesets-holding/*.md' 2>/dev/null
      git ls-files --others --exclude-standard \
        -- '.changeset/*.md' 'docs/changesets-holding/*.md' 2>/dev/null
      git diff --name-only \
        -- '.changeset/*.md' 'docs/changesets-holding/*.md' 2>/dev/null
    } | grep -v '/README\.md$' | sort -u
  )

  [ -n "$candidates" ] || return 1

  while IFS= read -r path; do
    [ -n "$path" ] || continue
    [ -f "$path" ] || continue
    # Extract YAML frontmatter (lines between the first two `---`
    # markers) and match the canonical `"@windyroad/<slug>":` line.
    # awk scoping prevents false positives from prose body mentions.
    if awk '/^---[[:space:]]*$/ { c++; if (c == 1) next; if (c == 2) exit } c == 1 { print }' "$path" 2>/dev/null \
        | grep -qE "^\"@windyroad/${slug}\":[[:space:]]"; then
      found="${found}${path}
"
    fi
  done <<EOF
$candidates
EOF

  [ -n "$found" ] || return 1
  printf '%s' "$found"
  return 0
}

# P387 helper — echo the space-separated, upper-cased, de-duplicated set of
# work-item IDs found in the text passed as $1. Work-item identity = problem
# ticket (`P<NNN>`), RFC (`RFC-<NNN>`), or story (`STORY-<NNN>`). ADR refs are
# deliberately excluded — an ADR is cross-cutting context cited in passing, not
# the identity of the change a changeset documents.
#
# Used to compare a committing change's ticket reference(s) (from the
# git-commit COMMAND string) against an in-scope changeset's reference(s)
# (filename + body). Matching is inclusive and case-insensitive: extracting a
# spurious extra ID only widens the overlap (the allow direction) and can never
# manufacture a false deny, which keeps Check 2b conservative.
_work_item_ids() {
  printf '%s' "$1" \
    | grep -oiE '\b(P[0-9]+|RFC-[0-9]+|STORY-[0-9]+)\b' 2>/dev/null \
    | tr '[:lower:]' '[:upper:]' \
    | sort -u \
    | tr '\n' ' '
}

# Detect whether the current staged set requires a changeset that is
# not satisfied by either staged Check 2a or in-scope Check 2b.
#
# $1 (optional) — the git-commit COMMAND string (or commit message). Its
#   work-item ID(s) are matched against in-scope changesets for the P387
#   change-scoped Check 2b. Empty / omitted → Check 2b falls back to the
#   pre-P387 plugin-scoped behaviour (any covering changeset allows), which
#   is the conservative choice when no commit context is available.
#
# Echoes the offending plugin slug on stdout when detected.
#
# Returns:
#   0 — no change required, BYPASS env set, fail-open, or an in-scope
#       changeset covers the plugin AND is change-scoped to it (Check 2b)
#   1 — change required + no covering (or only unrelated-sibling) changeset
#       (caller should deny)
detect_changeset_required() {
  local commit_msg="${1:-}"
  # Bypass via env var — single most-common legitimate escape.
  if [ "${BYPASS_CHANGESET_GATE:-}" = "1" ]; then
    return 0
  fi

  # Fail-open if not inside a git working tree.
  git rev-parse --is-inside-work-tree >/dev/null 2>&1 || return 0

  local staged
  staged=$(git diff --staged --name-only 2>/dev/null) || return 0

  # No staged paths — nothing to gate.
  [ -n "$staged" ] || return 0

  local has_changeset=0
  local plugin_source_slug=""
  local path rest slug subpath

  while IFS= read -r path; do
    [ -n "$path" ] || continue

    case "$path" in
      .changeset/README.md)
        # README in changeset dir is meta-doc, not a real changeset.
        ;;
      .changeset/*.md)
        has_changeset=1
        ;;
      docs/changesets-holding/README.md)
        # README in the holding dir is meta-doc, not a real changeset
        # (mirrors the .changeset/README.md exclusion above).
        ;;
      docs/changesets-holding/*.md)
        # P177: a held-window changeset entry IS a changeset — authored
        # and audit-trailed, just intentionally held outside `.changeset/`
        # per ADR-042 Rule 7 (held-window blessing). Recognising it here
        # gives the gate a held-window-awareness branch so held-window-
        # bound work commits no longer need a separate move-to-holding
        # chore commit. Release/drain semantics are unchanged — the
        # Release workflow reads `.changeset/` only; a held entry is never
        # drained without a graduation `git mv` back into `.changeset/`.
        has_changeset=1
        ;;
      packages/*)
        rest="${path#packages/}"
        slug="${rest%%/*}"
        # When the path has no further segments (e.g. `packages/foo`),
        # ${rest#*/} returns rest unchanged — defensive subpath fallback.
        if [ "$rest" = "$slug" ]; then
          subpath="$rest"
        else
          subpath="${rest#*/}"
        fi

        # Allow-list: test paths.
        case "$subpath" in
          test/*|hooks/test/*|scripts/test/*) continue ;;
        esac

        # Allow-list: package README.
        case "$subpath" in
          README.md) continue ;;
        esac

        # Allow-list: *.md under docs/ (any nesting depth).
        case "$subpath" in
          docs/*)
            case "$subpath" in
              *.md) continue ;;
            esac
            ;;
        esac

        # Anything else under packages/<slug>/ is publishable source.
        plugin_source_slug="$slug"
        ;;
      *)
        # Non-packages/ path: always allow.
        ;;
    esac
  done <<EOF
$staged
EOF

  # No publishable plugin source staged → allow.
  [ -n "$plugin_source_slug" ] || return 0

  # Check 2a — staged changeset satisfies (Phase 1 behaviour).
  if [ "$has_changeset" -eq 1 ]; then
    return 0
  fi

  # Check 2b (P141 Phase 2 + P387 change-scoped) — an in-scope changeset
  # targeting the plugin satisfies, but only when it is change-scoped to
  # THIS commit. Scope = unpushed-range commits + untracked + modified-
  # not-staged working-tree files. Once consumed onto origin, the changeset
  # is gone and a fresh one is required.
  local covering
  if covering=$(_changeset_in_scope_covers_plugin "$plugin_source_slug"); then
    # P387: tighten plugin-scoped → change-scoped. A plugin can carry a
    # changeset for an unrelated change; before P387 that wrongly covered
    # THIS commit, shipping it to npm with no CHANGELOG record of its own
    # (witnessed: P164's fix rode P374's changeset). Deny only on positive
    # evidence the covering changeset(s) belong to a DIFFERENT change: the
    # commit cites work-item ID(s), EVERY covering changeset cites work-item
    # ID(s), and none overlap. Any ambiguity allows — a ticket-less commit,
    # a prose-only changeset, or an ID overlap — so the ADR-014 batch-grain
    # (same-slice commits share a ticket) and prose-only / adopter changesets
    # are never over-fired.
    local commit_ids cs_path cs_ids id has_idless=0 overlap=0
    commit_ids=$(_work_item_ids "$commit_msg")

    # Commit cites no work-item ID → cannot change-scope; allow (pre-P387).
    [ -n "$commit_ids" ] || return 0

    while IFS= read -r cs_path; do
      [ -n "$cs_path" ] || continue
      cs_ids=$(_work_item_ids "${cs_path}
$(cat "$cs_path" 2>/dev/null)")
      if [ -z "$cs_ids" ]; then
        has_idless=1
        continue
      fi
      for id in $commit_ids; do
        case " $cs_ids " in
          *" $id "*) overlap=1; break ;;
        esac
      done
      [ "$overlap" -eq 1 ] && break
    done <<EOF
$covering
EOF

    # Overlapping ID (same change) or a prose-only covering changeset
    # (cannot prove it is for a different change) → allow.
    if [ "$overlap" -eq 1 ] || [ "$has_idless" -eq 1 ]; then
      return 0
    fi
    # Else: every covering changeset cites work-item ID(s), none matching
    # the commit → unrelated-sibling signature → fall through to deny.
  fi

  printf '%s\n' "$plugin_source_slug"
  return 1
}
