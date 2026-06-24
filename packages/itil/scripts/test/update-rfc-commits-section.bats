#!/usr/bin/env bats

# P378/RFC-030 Piece 1 (ADR-085): update-rfc-commits-section.sh renders the RFC
# `## Commits` section as a derived view from `git log --grep "Refs: RFC-NNN"`.
# Behavioural — exercises the renderer against a throwaway git repo.

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../../.." && pwd)"
  HELPER="$REPO_ROOT/packages/itil/scripts/update-rfc-commits-section.sh"
  DIR="$(mktemp -d)"
  cd "$DIR"
  git init -q
  git config user.email t@e.x; git config user.name t
  mkdir -p docs/rfcs
  cat > docs/rfcs/RFC-201-thing.proposed.md <<'EOF'
# RFC-201: thing

## Commits

(placeholder)

## Related

x
EOF
  git add -A && git commit -qm "chore: seed"
}
teardown() { cd /; rm -rf "$DIR"; }

@test "renders commits carrying the Refs: RFC-NNN trailer, newest first" {
  echo a > a; git add a; git commit -qm "$(printf 'feat: a\n\nRefs: RFC-201')"
  echo b > b; git add b; git commit -qm "$(printf 'fix: b\n\nRefs: RFC-201')"
  run bash "$HELPER" docs/rfcs/RFC-201-thing.proposed.md
  [ "$status" -eq 0 ]
  run sed -n '/## Commits/,/## Related/p' docs/rfcs/RFC-201-thing.proposed.md
  [[ "$output" == *"fix: b"* ]]
  [[ "$output" == *"feat: a"* ]]
  # newest first: fix: b appears before feat: a
  [[ "$output" == *"fix: b"*"feat: a"* ]]
  # placeholder body is gone
  [[ "$output" != *"(placeholder)"* ]]
}

@test "does NOT include commits without the trailer" {
  echo a > a; git add a; git commit -qm "$(printf 'feat: tagged\n\nRefs: RFC-201')"
  echo b > b; git add b; git commit -qm "chore: untagged"
  run bash "$HELPER" docs/rfcs/RFC-201-thing.proposed.md
  run sed -n '/## Commits/,/## Related/p' docs/rfcs/RFC-201-thing.proposed.md
  [[ "$output" == *"feat: tagged"* ]]
  [[ "$output" != *"chore: untagged"* ]]
}

@test "no trailer-bearing commits → renders a self-describing placeholder, not a false claim" {
  run bash "$HELPER" docs/rfcs/RFC-201-thing.proposed.md
  [ "$status" -eq 0 ]
  run sed -n '/## Commits/,/## Related/p' docs/rfcs/RFC-201-thing.proposed.md
  [[ "$output" == *"rendered from"* ]] && [[ "$output" == *"git log"* ]]
  [[ "$output" != *"maintained automatically"* ]]
}

@test "idempotent — second render is a byte-stable no-op" {
  echo a > a; git add a; git commit -qm "$(printf 'feat: a\n\nRefs: RFC-201')"
  bash "$HELPER" docs/rfcs/RFC-201-thing.proposed.md
  h1=$(shasum docs/rfcs/RFC-201-thing.proposed.md | cut -d' ' -f1)
  bash "$HELPER" docs/rfcs/RFC-201-thing.proposed.md
  h2=$(shasum docs/rfcs/RFC-201-thing.proposed.md | cut -d' ' -f1)
  [ "$h1" = "$h2" ]
}

@test "preserves sections after ## Commits (## Related survives)" {
  echo a > a; git add a; git commit -qm "$(printf 'feat: a\n\nRefs: RFC-201')"
  bash "$HELPER" docs/rfcs/RFC-201-thing.proposed.md
  run grep -c "## Related" docs/rfcs/RFC-201-thing.proposed.md
  [ "$output" -eq 1 ]
  run grep -c "^x$" docs/rfcs/RFC-201-thing.proposed.md
  [ "$output" -eq 1 ]
}
