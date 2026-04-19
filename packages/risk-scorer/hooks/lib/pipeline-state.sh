#!/bin/bash
# Standalone script: Gathers pipeline state and outputs structured text to stdout.
# Usage: pipeline-state.sh [--uncommitted] [--unpushed] [--unreleased] [--stale] [--all] [--hash-inputs]
# No network calls (no gh commands). Local git operations only.

set -euo pipefail

# Source shared helpers for _doc_exclusions
_PIPELINE_STATE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$_PIPELINE_STATE_DIR/gate-helpers.sh"

# --- Parse flags ---
SHOW_UNCOMMITTED=false
SHOW_UNPUSHED=false
SHOW_UNRELEASED=false
SHOW_STALE=false
SHOW_HASH_INPUTS=false

for arg in "$@"; do
    case "$arg" in
        --uncommitted) SHOW_UNCOMMITTED=true ;;
        --unpushed)    SHOW_UNPUSHED=true ;;
        --unreleased)  SHOW_UNRELEASED=true ;;
        --stale)       SHOW_STALE=true ;;
        --hash-inputs) SHOW_HASH_INPUTS=true ;;
        --all)
            SHOW_UNCOMMITTED=true
            SHOW_UNPUSHED=true
            SHOW_UNRELEASED=true
            SHOW_STALE=true
            ;;
    esac
done

# --- Fast hash inputs mode: output only metadata for drift detection hash ---
# Tree-based hash — stable across BOTH commit and push operations (P054).
# Captures the conceptual "HEAD + index + working tree" state by asking git
# to build a tree object that reflects what a commit of the current state
# would contain. This makes the hash invariant over:
#   - git commit (content moves from index to HEAD; tree SHA is identical)
#   - git push  (HEAD is unchanged locally; tree SHA is identical)
# The previous approach hashed `git diff origin/main --stat`, which shrinks
# to empty after a push advances origin/main, producing spurious drift
# denials on npm run release:watch even though the commits being released
# were the same ones already scored.
if [ "$SHOW_HASH_INPUTS" = true ]; then
    # Exclude docs/governance paths — they cannot affect the running application.
    EXCL=$(_doc_exclusions)
    # git stash create writes a commit object (tree + parents) representing
    # index + working tree, without touching HEAD, the index, or any refs.
    # Returns empty when there is nothing to stash (clean tree).
    STASH_COMMIT=$(git stash create 2>/dev/null || true)
    if [ -n "$STASH_COMMIT" ]; then
        CONCEPTUAL_TREE=$(git rev-parse "${STASH_COMMIT}^{tree}" 2>/dev/null || echo "")
    else
        CONCEPTUAL_TREE=$(git rev-parse HEAD^{tree} 2>/dev/null || echo "")
    fi
    if [ -n "$CONCEPTUAL_TREE" ]; then
        # Diff against the empty tree to enumerate every file in the
        # conceptual tree with its blob SHA (shown as "added"). git diff
        # supports `:!` pathspec exclusions where `git ls-tree` does not,
        # so this is the path that honours the doc exclusions above.
        # Same-content trees produce identical output regardless of which
        # ref points at them, which is what gives push stability.
        # 4b825dc642cb6eb9a060e54bf8d69288fbee4904 is git's well-known empty-tree SHA.
        eval "git diff --raw 4b825dc642cb6eb9a060e54bf8d69288fbee4904 $CONCEPTUAL_TREE -- $EXCL" 2>/dev/null || true
    fi
    # Changeset count (affects release/changeset risk — tracked separately
    # because .changeset/ is in the doc-exclusions list and therefore not
    # reflected in the tree listing above).
    if [ -d ".changeset" ]; then
        find .changeset -name '*.md' -not -name 'README.md' 2>/dev/null | wc -l | tr -d ' '
    fi
    exit 0
fi

# --- Noise filter: lockfiles, binary assets, OS junk ---
NOISE='(package-lock\.json|yarn\.lock|pnpm-lock\.yaml|bun\.lockb|Gemfile\.lock|Pipfile\.lock|poetry\.lock|composer\.lock|Cargo\.lock|go\.sum|shrinkwrap\.json|\.DS_Store|node_modules|\.png$|\.svg$|\.jpg$|\.jpeg$|\.gif$|\.ico$|\.woff2?$|\.ttf$|\.eot$)'

# --- File categorisation ---
categorise_files() {
    python3 -c "
import sys
cats = {
    'hooks': [], 'config': [], 'ci': [], 'ui': [], 'styles': [],
    'content': [], 'generated': [], 'skills': [], 'docs': [],
    'tests': [], 'lib': [], 'agents': [], 'other': []
}
for line in sys.stdin:
    f = line.strip()
    if not f:
        continue
    if '.claude/hooks/' in f:
        cats['hooks'].append(f)
    elif '.claude/agents/' in f:
        cats['agents'].append(f)
    elif '.claude/skills/' in f:
        cats['skills'].append(f)
    elif '.claude/' in f or f.endswith(('.json', '.toml', '.yml', '.yaml', '.mjs', '.cjs')) and '/' not in f:
        cats['config'].append(f)
    elif '.github/' in f:
        cats['ci'].append(f)
    elif f.endswith(('.tsx', '.jsx', '.html', '.vue', '.svelte')):
        cats['ui'].append(f)
    elif f.endswith(('.scss', '.css', '.less')):
        cats['styles'].append(f)
    elif f.endswith(('.md', '.mdx')):
        if 'generated' in f or 'architecture' in f:
            cats['generated'].append(f)
        elif 'articles/' in f or 'content/' in f or 'posts/' in f:
            cats['content'].append(f)
        else:
            cats['docs'].append(f)
    elif 'generated/' in f:
        cats['generated'].append(f)
    elif f.endswith(('.test.ts', '.test.tsx', '.spec.ts', '.spec.tsx')):
        cats['tests'].append(f)
    elif f.endswith(('.ts', '.js')):
        cats['lib'].append(f)
    else:
        cats['other'].append(f)
out = []
for cat, files in cats.items():
    if files:
        out.append(f'  {cat}: {len(files)} file(s)')
if out:
    print('\n'.join(out))
" 2>/dev/null || echo "  (could not categorise)"
}

# --- Section: Uncommitted changes ---
if [ "$SHOW_UNCOMMITTED" = true ]; then
    DIFF_STAT=$(git diff HEAD --stat -- . \
        ':(exclude)package-lock.json' ':(exclude)yarn.lock' \
        ':(exclude)pnpm-lock.yaml' ':(exclude)bun.lockb' \
        ':(exclude)Gemfile.lock' ':(exclude)Pipfile.lock' \
        ':(exclude)poetry.lock' ':(exclude)composer.lock' \
        ':(exclude)Cargo.lock' ':(exclude)go.sum' \
        ':(exclude)shrinkwrap.json' 2>/dev/null || echo "")
    DIFF_NAMES=$(git diff HEAD --name-only 2>/dev/null | grep -vE "$NOISE" || echo "")
    UNTRACKED=$(git ls-files --others --exclude-standard 2>/dev/null | grep -vE "$NOISE" || true)

    echo "=== UNCOMMITTED CHANGES ==="
    if [ -n "$DIFF_STAT" ]; then
        echo "Tracked changes (git diff HEAD --stat):"
        echo "$DIFF_STAT"
        echo ""
        # Include actual diff content for risk assessment
        DIFF_CONTENT=$(git diff HEAD -- . \
            ':(exclude)package-lock.json' ':(exclude)yarn.lock' \
            ':(exclude)pnpm-lock.yaml' ':(exclude)bun.lockb' \
            ':(exclude)Gemfile.lock' ':(exclude)Pipfile.lock' \
            ':(exclude)poetry.lock' ':(exclude)composer.lock' \
            ':(exclude)Cargo.lock' ':(exclude)go.sum' \
            ':(exclude)shrinkwrap.json' 2>/dev/null || echo "")
        if [ -n "$DIFF_CONTENT" ]; then
            echo "Diff content:"
            echo "$DIFF_CONTENT"
            echo ""
        fi
    fi
    if [ -n "$UNTRACKED" ]; then
        UNTRACKED_COUNT=$(echo "$UNTRACKED" | wc -l | tr -d ' ')
        echo "Untracked files (${UNTRACKED_COUNT}):"
        echo "$UNTRACKED"
        echo ""
    fi
    if [ -z "$DIFF_NAMES" ] && [ -z "$UNTRACKED" ]; then
        echo "No uncommitted changes."
        echo ""
    else
        ALL_FILES=""
        if [ -n "$DIFF_NAMES" ]; then
            ALL_FILES="$DIFF_NAMES"
        fi
        if [ -n "$UNTRACKED" ]; then
            if [ -n "$ALL_FILES" ]; then
                ALL_FILES="${ALL_FILES}"$'\n'"${UNTRACKED}"
            else
                ALL_FILES="$UNTRACKED"
            fi
        fi
        echo "Categories:"
        echo "$ALL_FILES" | categorise_files
        echo ""
    fi
fi

# --- Detect default remote branch ---
DEFAULT_BRANCH=""
if git rev-parse --verify origin/main >/dev/null 2>&1; then
    DEFAULT_BRANCH="origin/main"
elif git rev-parse --verify origin/master >/dev/null 2>&1; then
    DEFAULT_BRANCH="origin/master"
fi

# --- Section: Unpushed changes ---
if [ "$SHOW_UNPUSHED" = true ]; then
    echo "=== UNPUSHED CHANGES ==="

    if [ -n "$DEFAULT_BRANCH" ]; then
        UNPUSHED_LOG=$(git log --oneline $DEFAULT_BRANCH..HEAD 2>/dev/null || echo "")
        UNPUSHED_STAT=$(git diff --stat $DEFAULT_BRANCH..HEAD -- . \
            ':(exclude)package-lock.json' ':(exclude)yarn.lock' \
            ':(exclude)pnpm-lock.yaml' ':(exclude)bun.lockb' \
            ':(exclude)Gemfile.lock' ':(exclude)Pipfile.lock' \
            ':(exclude)poetry.lock' ':(exclude)composer.lock' \
            ':(exclude)Cargo.lock' ':(exclude)go.sum' \
            ':(exclude)shrinkwrap.json' 2>/dev/null || echo "")
        UNPUSHED_NAMES=$(git diff --name-only $DEFAULT_BRANCH..HEAD 2>/dev/null | grep -vE "$NOISE" || echo "")
        UNPUSHED_COUNT=$(git rev-list --count $DEFAULT_BRANCH..HEAD 2>/dev/null || echo "0")

        if [ "$UNPUSHED_COUNT" -eq 0 ]; then
            echo "No unpushed commits."
        else
            echo "Unpushed commits (${UNPUSHED_COUNT}):"
            echo "$UNPUSHED_LOG"
            echo ""
            if [ -n "$UNPUSHED_STAT" ]; then
                echo "Accumulated unpushed diff:"
                echo "$UNPUSHED_STAT"
                echo ""
                UNPUSHED_DIFF=$(git diff $DEFAULT_BRANCH..HEAD -- . \
                    ':(exclude)package-lock.json' ':(exclude)yarn.lock' \
                    ':(exclude)pnpm-lock.yaml' ':(exclude)bun.lockb' \
                    ':(exclude)Gemfile.lock' ':(exclude)Pipfile.lock' \
                    ':(exclude)poetry.lock' ':(exclude)composer.lock' \
                    ':(exclude)Cargo.lock' ':(exclude)go.sum' \
                    ':(exclude)shrinkwrap.json' 2>/dev/null || echo "")
                if [ -n "$UNPUSHED_DIFF" ]; then
                    echo "Unpushed diff content:"
                    echo "$UNPUSHED_DIFF"
                    echo ""
                fi
            fi
            if [ -n "$UNPUSHED_NAMES" ]; then
                echo "Unpushed categories:"
                echo "$UNPUSHED_NAMES" | categorise_files
            fi
        fi
    else
        echo "No remote tracking branch (origin/main and origin/master not found)."
    fi
    echo ""
fi

# --- Section: Unreleased changes ---
if [ "$SHOW_UNRELEASED" = true ]; then
    echo "=== UNRELEASED CHANGES ==="

    # Count pending changesets
    CHANGESET_COUNT=0
    if [ -d ".changeset" ]; then
        CHANGESET_COUNT=$(find .changeset -name '*.md' -not -name 'README.md' 2>/dev/null | wc -l | tr -d ' ')
    fi

    # Check if origin/publish exists
    if git rev-parse --verify origin/publish >/dev/null 2>&1; then
        UNRELEASED_STAT=$(git diff --stat origin/publish..$DEFAULT_BRANCH -- . \
            ':(exclude)package-lock.json' ':(exclude)yarn.lock' \
            ':(exclude)pnpm-lock.yaml' ':(exclude)bun.lockb' \
            ':(exclude)Gemfile.lock' ':(exclude)Pipfile.lock' \
            ':(exclude)poetry.lock' ':(exclude)composer.lock' \
            ':(exclude)Cargo.lock' ':(exclude)go.sum' \
            ':(exclude)shrinkwrap.json' 2>/dev/null || echo "")
        UNRELEASED_NAMES=$(git diff --name-only origin/publish..$DEFAULT_BRANCH 2>/dev/null | grep -vE "$NOISE" || echo "")

        if [ -z "$UNRELEASED_STAT" ] && [ "$CHANGESET_COUNT" -eq 0 ]; then
            echo "No unreleased changes."
        else
            if [ "$CHANGESET_COUNT" -gt 0 ]; then
                echo "Pending changesets: ${CHANGESET_COUNT}"
            fi
            if [ -n "$UNRELEASED_STAT" ]; then
                echo "Accumulated unreleased diff (origin/publish..$DEFAULT_BRANCH):"
                echo "$UNRELEASED_STAT"
                echo ""
                UNRELEASED_DIFF=$(git diff origin/publish..$DEFAULT_BRANCH -- . \
                    ':(exclude)package-lock.json' ':(exclude)yarn.lock' \
                    ':(exclude)pnpm-lock.yaml' ':(exclude)bun.lockb' \
                    ':(exclude)Gemfile.lock' ':(exclude)Pipfile.lock' \
                    ':(exclude)poetry.lock' ':(exclude)composer.lock' \
                    ':(exclude)Cargo.lock' ':(exclude)go.sum' \
                    ':(exclude)shrinkwrap.json' 2>/dev/null || echo "")
                if [ -n "$UNRELEASED_DIFF" ]; then
                    echo "Unreleased diff content:"
                    echo "$UNRELEASED_DIFF"
                    echo ""
                fi
            fi
            if [ -n "$UNRELEASED_NAMES" ]; then
                echo "Unreleased categories:"
                echo "$UNRELEASED_NAMES" | categorise_files
            fi
        fi
    else
        echo "No publish branch (origin/publish not found)."
        if [ "$CHANGESET_COUNT" -gt 0 ]; then
            echo "Pending changesets: ${CHANGESET_COUNT}"
        fi
    fi
    echo ""
fi

# --- Section: Stale files ---
if [ "$SHOW_STALE" = true ]; then
    echo "=== STALE FILES ==="

    STALE_FILES=$(git diff --name-only HEAD 2>/dev/null | python3 -c "
import sys, os, time
threshold = time.time() - 86400
stale = []
for line in sys.stdin:
    f = line.strip()
    if not f or not os.path.isfile(f):
        continue
    try:
        if os.path.getmtime(f) < threshold:
            stale.append(f)
    except OSError:
        pass
if stale:
    print('\n'.join(stale))
" 2>/dev/null || echo "")

    if [ -n "$STALE_FILES" ]; then
        STALE_COUNT=$(echo "$STALE_FILES" | wc -l | tr -d ' ')
        echo "Modified files uncommitted for over 24h (${STALE_COUNT}):"
        echo "$STALE_FILES"
    else
        echo "No stale files."
    fi
    echo ""
fi
