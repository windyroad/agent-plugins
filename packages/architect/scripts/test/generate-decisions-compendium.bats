#!/usr/bin/env bats

# ADR-077: generate-decisions-compendium.sh emits a derived `README.md` index
# of every ADR's chosen option, confirmation criteria, and relationships.
# Behavioural — exercises the script against fixture trees and against the
# live committed state, asserts on its exit codes and stdout/file output.
#
# Confirmation item (g): CI drift-detection bats — defence-in-depth in case
# the `architect-compendium-refresh-discipline.sh` PreToolUse hook fails
# open or is bypassed.

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../../.." && pwd)"
  SCRIPT="$REPO_ROOT/packages/architect/scripts/generate-decisions-compendium.sh"
  DIR="$(mktemp -d)"
  mkdir -p "$DIR/docs/decisions"
}

teardown() {
  rm -rf "$DIR"
}

# mk_adr <filename> <status> <title> [extra-frontmatter-lines...]
# Writes a minimal MADR-shaped ADR with frontmatter + title + the three
# sections the generator extracts: Decision Outcome, Confirmation, Related.
mk_adr() {
  local name="$1" status="$2" title="$3"
  shift 3
  {
    echo "---"
    echo "status: \"$status\""
    echo "date: 2026-05-30"
    for line in "$@"; do echo "$line"; done
    echo "---"
    echo ""
    echo "# $title"
    echo ""
    echo "## Decision Outcome"
    echo ""
    echo "Chosen option: **\"$title implementation\"**, because reasons."
    echo ""
    echo "## Confirmation"
    echo ""
    echo "- [ ] (a) First confirmation item for $title."
    echo "- [ ] (b) Second confirmation item for $title."
    echo ""
    echo "## Related"
    echo ""
    echo "- Relates to [ADR-001](001-foo.proposed.md)"
  } > "$DIR/docs/decisions/$name"
}

# --- ADR-077 (g) drift-detection contract on the live committed state -------

@test "committed compendium matches generator output (CI drift gate)" {
  # RETIRED per ADR-078 (Option 9) / RFC-014 Story C (test 2145). Under
  # architect-on-edit authoring the committed docs/decisions/README.md is
  # LLM-authored and intentionally no longer byte-matches programmatic
  # generator output, so this idempotency/drift assertion no longer holds.
  # Replacement enforcement: the architect-readme-pairing-check.sh pre-commit
  # hook (Story B) asserts body↔README pairing at commit time. Removed entirely
  # with the generator script after the backstop window (ADR-078 reassessment
  # 2026-08-30).
  skip "test 2145 retired per ADR-078 Option 9 — compendium is architect-authored, not generator-derived (RFC-014 Story C; pairing enforced by architect-readme-pairing-check.sh)"
  cd "$REPO_ROOT"
  run bash "$SCRIPT" --check docs/decisions
  [ "$status" -eq 0 ]
}

# --- Idempotency (ADR-077 (b) re-asserted) ----------------------------------

@test "generator is idempotent — two runs produce byte-identical output" {
  mk_adr "010-alpha.proposed.md" "proposed" "Alpha"
  mk_adr "011-beta.accepted.md" "accepted" "Beta"
  run bash "$SCRIPT" "$DIR/docs/decisions"
  [ "$status" -eq 0 ]
  cp "$DIR/docs/decisions/README.md" "$DIR/first.md"
  run bash "$SCRIPT" "$DIR/docs/decisions"
  [ "$status" -eq 0 ]
  run cmp -s "$DIR/first.md" "$DIR/docs/decisions/README.md"
  [ "$status" -eq 0 ]
}

@test "generator preserves UTF-8 at byte truncation boundaries and rejects invalid source without clobbering output" {
  local prefix out before mode
  prefix="$(printf '%109s' '' | tr ' ' x)"
  {
    echo "---"
    echo 'status: "accepted"'
    echo "date: 2026-05-30"
    echo "---"
    echo ""
    echo "# Boundary"
    echo ""
    echo "## Decision Outcome"
    echo ""
    echo 'Chosen option: **"Boundary implementation"**, because reasons.'
    echo ""
    echo "## Confirmation"
    echo ""
    printf '%s\n' "- [ ] ${prefix}—tail"
    echo ""
    echo "## Related"
    echo ""
    echo "- Relates to ADR-001"
  } > "$DIR/docs/decisions/010-boundary.accepted.md"
  mk_adr "011-history.rejected.md" "rejected" "History"

  run bash "$SCRIPT" "$DIR/docs/decisions"
  [ "$status" -eq 0 ]
  out="$DIR/docs/decisions/README.md"
  run iconv -f UTF-8 -t UTF-8 "$out"
  [ "$status" -eq 0 ]
  [ "$(grep -c '^## In-force decisions$' "$out")" -eq 1 ]
  [ "$(grep -c '^## Historical decisions$' "$out")" -eq 1 ]
  run grep -F $'\357\277\275' "$out"
  [ "$status" -eq 1 ]
  if ! mode=$(stat -f '%Lp' "$out" 2>/dev/null); then
    mode=$(stat -c '%a' "$out")
  fi
  [ "$mode" = "644" ]

  before="$DIR/README.before"
  cp "$out" "$before"
  printf '\377' >> "$DIR/docs/decisions/010-boundary.accepted.md"
  run bash "$SCRIPT" "$DIR/docs/decisions"
  [ "$status" -ne 0 ]
  [[ "$output" == *"invalid UTF-8 in authoritative ADR"* ]]
  run cmp -s "$before" "$out"
  [ "$status" -eq 0 ]
}

@test "generator preserves multiline chosen outcomes with balanced Markdown when truncated" {
  local out chosen_156 chosen_158 markers
  {
    echo "---"
    echo 'status: "proposed"'
    echo "date: 2026-08-22"
    echo "---"
    echo ""
    echo "# Cancellation boundary"
    echo ""
    echo "## Decision Outcome"
    echo ""
    echo "Chosen: **read the boundary from Stripe in the request that confirms the"
    echo "cancellation, and carry no boundary on a pending one.**"
    echo ""
    echo "## Confirmation"
    echo ""
    echo "- [ ] Preserve the boundary."
    echo ""
    echo "## Related"
    echo ""
    echo "- Relates to ADR-001"
  } > "$DIR/docs/decisions/156-cancellation-boundary.proposed.md"
  {
    echo "---"
    echo 'status: "proposed"'
    echo "date: 2026-08-22"
    echo "---"
    echo ""
    echo "# Checkout expiry access state"
    echo ""
    echo "## Decision Outcome"
    echo ""
    echo "Chosen option: **two access states, a signed Checkout-expired transition and a"
    echo "bounded reconciliation backstop**, because it keeps Stripe authoritative while"
    echo "making the local model describe only where the answer lives and adds **an"
    echo "intentionally long emphasized consequence that crosses the summary boundary without losing structural Markdown meaning.**"
    echo ""
    echo "## Confirmation"
    echo ""
    echo "- [ ] Preserve the access state."
    echo ""
    echo "## Related"
    echo ""
    echo "- Relates to ADR-001"
  } > "$DIR/docs/decisions/158-checkout-expiry.proposed.md"

  run bash "$SCRIPT" "$DIR/docs/decisions"
  [ "$status" -eq 0 ]
  out="$DIR/docs/decisions/README.md"
  chosen_156=$(grep -A2 '^### ADR-156 ' "$out" | grep '^\*\*Chosen:\*\*')
  chosen_158=$(grep -A2 '^### ADR-158 ' "$out" | grep '^\*\*Chosen:\*\*')
  [[ "$chosen_156" == *"cancellation, and carry no boundary on a pending one.**"* ]]
  [[ "$chosen_158" == *"bounded reconciliation backstop**"* ]]
  [[ "$chosen_158" == *"**..." ]]
  markers=$(awk '{ n += gsub(/\*\*/, "") } END { print n }' <<< "$chosen_156")
  [ $((markers % 2)) -eq 0 ]
  markers=$(awk '{ n += gsub(/\*\*/, "") } END { print n }' <<< "$chosen_158")
  [ $((markers % 2)) -eq 0 ]
}

# --- Drift detection on fixture (mutated ADR body) --------------------------

@test "--check exits 1 when an ADR body is mutated after generation" {
  mk_adr "010-alpha.proposed.md" "proposed" "Alpha"
  bash "$SCRIPT" "$DIR/docs/decisions" >/dev/null 2>&1
  # Mutate the Decision Outcome — committed compendium now stale.
  sed -i.bak 's/Alpha implementation/Alpha REVISED outcome/' \
    "$DIR/docs/decisions/010-alpha.proposed.md"
  rm "$DIR/docs/decisions/010-alpha.proposed.md.bak"
  run bash "$SCRIPT" --check "$DIR/docs/decisions"
  [ "$status" -eq 1 ]
  # The stderr advice should name the regen command for mechanical recovery.
  [[ "$output" == *"wr-architect-generate-decisions-compendium"* ]]
}

@test "--check exits 1 when compendium is missing entirely" {
  mk_adr "010-alpha.proposed.md" "proposed" "Alpha"
  run bash "$SCRIPT" --check "$DIR/docs/decisions"
  [ "$status" -eq 1 ]
  [[ "$output" == *"MISSING"* || "$output" == *"missing"* || "$output" == *"does not exist"* ]]
}

@test "--check exits 0 on a freshly-generated set (in sync)" {
  mk_adr "010-alpha.proposed.md" "proposed" "Alpha"
  mk_adr "011-beta.accepted.md" "accepted" "Beta"
  bash "$SCRIPT" "$DIR/docs/decisions" >/dev/null 2>&1
  run bash "$SCRIPT" --check "$DIR/docs/decisions"
  [ "$status" -eq 0 ]
}

# --- Section split (ADR-077 amendment 2026-05-30 two-section format) --------

@test "compendium splits in-force (proposed+accepted) from historical (superseded+rejected+deprecated)" {
  mk_adr "010-alpha.proposed.md"    "proposed"   "Alpha In-Force"
  mk_adr "011-beta.accepted.md"     "accepted"   "Beta In-Force"
  mk_adr "012-gamma.superseded.md"  "superseded" "Gamma Historical"
  mk_adr "013-delta.rejected.md"    "rejected"   "Delta Historical"
  mk_adr "014-eps.deprecated.md"    "deprecated" "Eps Historical"
  bash "$SCRIPT" "$DIR/docs/decisions" >/dev/null 2>&1
  local out="$DIR/docs/decisions/README.md"
  grep -q '^## In-force decisions$' "$out"
  grep -q '^## Historical decisions$' "$out"
  # In-force section appears before historical section.
  local in_force_line historical_line
  in_force_line=$(grep -n '^## In-force decisions$' "$out" | cut -d: -f1)
  historical_line=$(grep -n '^## Historical decisions$' "$out" | cut -d: -f1)
  [ "$in_force_line" -lt "$historical_line" ]
  # Header tally reflects the partition.
  grep -q '^\*\*Total ADRs:\*\* 5 (2 in-force, 3 historical)$' "$out"
}

@test "superseded filename overrides immutable accepted frontmatter" {
  mk_adr "015-old.superseded.md" "accepted" "Old Historical"
  bash "$SCRIPT" "$DIR/docs/decisions" >/dev/null 2>&1
  local out="$DIR/docs/decisions/README.md" hist line
  hist=$(grep -n '^## Historical decisions' "$out" | cut -d: -f1)
  line=$(grep -n '^### ADR-015 ' "$out" | cut -d: -f1)
  [ "$line" -gt "$hist" ]
  grep -A1 '^### ADR-015 ' "$out" | grep -q '^\*\*Status:\*\* superseded'
}

@test "compendium omits historical section when there are no historical ADRs" {
  mk_adr "010-alpha.proposed.md" "proposed" "Alpha"
  bash "$SCRIPT" "$DIR/docs/decisions" >/dev/null 2>&1
  local out="$DIR/docs/decisions/README.md"
  grep -q '^## In-force decisions$' "$out"
  ! grep -q '^## Historical decisions$' "$out"
  grep -q '^\*\*Total ADRs:\*\* 1 (1 in-force, 0 historical)$' "$out"
}

# --- Output deterministic (no timestamp / no date in header) ----------------

@test "header carries no timestamp or date — output stays idempotent across days" {
  mk_adr "010-alpha.proposed.md" "proposed" "Alpha"
  bash "$SCRIPT" "$DIR/docs/decisions" >/dev/null 2>&1
  local out="$DIR/docs/decisions/README.md"
  # The README.md never embeds a YYYY-MM-DD or HH:MM stamp at the top —
  # idempotency would break otherwise (drift bats would flag day-by-day
  # churn instead of substance drift).
  ! head -10 "$out" | grep -qE '20[0-9]{2}-[0-9]{2}-[0-9]{2}'
  ! head -10 "$out" | grep -qE '[0-9]{2}:[0-9]{2}'
}

# --- Per-ADR entry shape ----------------------------------------------------

@test "each ADR emits ID + Title + Status + Chosen + Confirmation + Related" {
  mk_adr "042-test.accepted.md" "accepted" "Test Entry"
  bash "$SCRIPT" "$DIR/docs/decisions" >/dev/null 2>&1
  local out="$DIR/docs/decisions/README.md"
  grep -q '^### ADR-042 — Test Entry$' "$out"
  grep -q '^\*\*Status:\*\* accepted' "$out"
  grep -q '^\*\*Chosen:\*\* Chosen option: ' "$out"
  grep -q '^\*\*Confirmation:\*\* ' "$out"
  # Related extraction collapses to ADR-NNN ID list.
  grep -q '^\*\*Related:\*\* ADR-001$' "$out"
}

@test "generator preserves every confirmation item and typed relationship" {
  local adr="$DIR/docs/decisions/042-metadata.accepted.md" out item
  {
    echo "---"
    echo 'status: "accepted"'
    echo "date: 2026-08-22"
    echo "supersedes: [014-original-decision]"
    echo "superseded-by: 999-future-decision"
    echo "amends:"
    echo "  - 024-first-amendment"
    echo "  - 031-second-amendment"
    echo "supplements:"
    echo "  - 040-first-decision"
    echo "  - 054-second-decision"
    echo "  - 060-third-decision"
    echo "  - 061-fourth-decision"
    echo "  - 085-fifth-decision"
    echo "  - 154-sixth-decision"
    echo "---"
    echo ""
    echo "# Metadata"
    echo ""
    echo "## Decision Outcome"
    echo ""
    echo 'Chosen option: **"Preserve metadata"**, because every item matters.'
    echo ""
    echo "## Confirmation"
    echo ""
    for item in one two three four five six seven eight nine; do
      echo "- [ ] Confirmation $item."
    done
    echo ""
    echo "## Related"
    echo ""
    echo "- Relates to ADR-001"
  } > "$adr"

  run bash "$SCRIPT" "$DIR/docs/decisions"
  [ "$status" -eq 0 ]
  out="$DIR/docs/decisions/README.md"
  for item in one two three four five six seven eight nine; do
    grep -q "Confirmation $item\." "$out"
  done
  grep -q '^\*\*Status:\*\* accepted | \*\*Supersedes:\*\* \[014-original-decision\]$' "$out"
  grep -q '^\*\*Superseded-by:\*\* 999-future-decision$' "$out"
  grep -q '^\*\*Amends:\*\* \[024-first-amendment, 031-second-amendment\]$' "$out"
  grep -q '^\*\*Supplements:\*\* \[040-first-decision, 054-second-decision, 060-third-decision, 061-fourth-decision, 085-fifth-decision, 154-sixth-decision\]$' "$out"
  grep -q '^\*\*Related:\*\* ADR-001$' "$out"
}

# --- Error handling ---------------------------------------------------------

@test "missing decisions dir exits 2 with a clear error" {
  run bash "$SCRIPT" "$DIR/docs/nonexistent"
  [ "$status" -eq 2 ]
  [[ "$output" == *"not found"* || "$output" == *"does not exist"* ]]
}

@test "README.md is excluded from the ADR set (never recurses into itself)" {
  # If README.md were treated as an ADR, the compendium would grow on every
  # run — idempotency would break catastrophically.
  mk_adr "010-alpha.proposed.md" "proposed" "Alpha"
  bash "$SCRIPT" "$DIR/docs/decisions" >/dev/null 2>&1
  cp "$DIR/docs/decisions/README.md" "$DIR/first.md"
  bash "$SCRIPT" "$DIR/docs/decisions" >/dev/null 2>&1
  run cmp -s "$DIR/first.md" "$DIR/docs/decisions/README.md"
  [ "$status" -eq 0 ]
  # The "Total ADRs:" tally must still be 1, not 2.
  grep -q '^\*\*Total ADRs:\*\* 1 ' "$DIR/docs/decisions/README.md"
}

# --- Oversight marker projection (ADR-077 (i) authoritative-state) ----------

@test "human-oversight: confirmed surfaces as an Oversight badge" {
  mk_adr "010-conf.proposed.md" "proposed" "Confirmed Entry" \
    "human-oversight: confirmed" \
    "oversight-date: 2026-05-30"
  bash "$SCRIPT" "$DIR/docs/decisions" >/dev/null 2>&1
  grep -q '^\*\*Status:\*\* proposed | \*\*Oversight:\*\* confirmed' \
    "$DIR/docs/decisions/README.md"
}

@test "rejected-pending-supersede surfaces with the supersede ticket in the badge (P316 amendment)" {
  mk_adr "010-rej.proposed.md" "proposed" "Rejected Entry" \
    "human-oversight: rejected-pending-supersede" \
    "supersede-ticket: P297"
  bash "$SCRIPT" "$DIR/docs/decisions" >/dev/null 2>&1
  grep -q 'Oversight:\*\* rejected-pending-supersede (P297)' \
    "$DIR/docs/decisions/README.md"
}
