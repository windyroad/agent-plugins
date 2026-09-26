#!/usr/bin/env bats

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../.." && pwd)"
  export TMPDIR="$BATS_TEST_TMPDIR/tmp"
  mkdir -p "$TMPDIR" "$BATS_TEST_TMPDIR/packs"
}

pack_plugin() {
  local package="$1" version tarball extracted
  version="$(jq -r .version "$REPO_ROOT/packages/$package/package.json")"
  npm pack "$REPO_ROOT/packages/$package" --pack-destination "$BATS_TEST_TMPDIR/packs" >/dev/null
  tarball="$BATS_TEST_TMPDIR/packs/windyroad-$package-$version.tgz"
  extracted="$BATS_TEST_TMPDIR/$package"
  mkdir -p "$extracted"
  tar -xzf "$tarball" -C "$extracted"
  printf '%s\n' "$extracted/package"
}

gate_key() {
  local draft="$1" surface="$2"
  printf '%s\n%s' "$draft" "$surface" | shasum -a 256 | cut -d' ' -f1
}

derive_from_package() {
  local root="$1" prompt="$2"
  bash -c 'source "$1/hooks/lib/external-comms-key.sh"; derive_external_comms_key_from_prompt "$2"' _ "$root" "$prompt"
}

send_mark_event() {
  local hook="$1" session="$2" subagent="$3" prompt="$4" output="$5"
  python3 -c '
import json, sys
print(json.dumps({
  "tool_name": "Agent",
  "session_id": sys.argv[1],
  "tool_input": {"subagent_type": sys.argv[2], "prompt": sys.argv[3]},
  "tool_response": {"content": [{"type": "text", "text": sys.argv[4]}]},
}))
' "$session" "$subagent" "$prompt" "$output" | bash "$hook"
}

@test "packed risk and voice helpers select the caller pair and fail closed on malformed envelopes" {
  local package root draft prompt expected actual malformed

  for package in risk-scorer voice-tone; do
    root="$(pack_plugin "$package")"

    draft="the caller's reviewed changeset body"
    prompt=$'Reviewer documentation mentions <draft>...</draft>.\nSURFACE: changeset-author\n<draft>\n'"$draft"$'\n</draft>'
    expected="$(gate_key "$draft" changeset-author)"
    actual="$(derive_from_package "$root" "$prompt")"
    [ "$actual" = "$expected" ]

    draft=$'first line\nSURFACE: npm-publish\nquoted prose, not a new envelope\nlast line'
    prompt=$'SURFACE: gh-pr-comment\n<draft>\n'"$draft"$'\n</draft>'
    expected="$(gate_key "$draft" gh-pr-comment)"
    actual="$(derive_from_package "$root" "$prompt")"
    [ "$actual" = "$expected" ]

    malformed=$'SURFACE: changeset-author\nReview this exact body.\n<draft>\nbody\n</draft>'
    [ -z "$(derive_from_package "$root" "$malformed")" ]
  done
}

@test "packed risk and voice mark hooks trigger only for their reviewed caller prompt" {
  local package root hook subagent verdict marker_prefix session draft prompt key rdir unrelated_session

  for package in risk-scorer voice-tone; do
    root="$(pack_plugin "$package")"
    case "$package" in
      risk-scorer)
        hook="$root/hooks/risk-score-mark.sh"
        subagent="wr-risk-scorer:external-comms"
        verdict="EXTERNAL_COMMS_RISK_VERDICT: PASS"
        marker_prefix="external-comms-risk-reviewed"
        ;;
      voice-tone)
        hook="$root/hooks/external-comms-mark-reviewed.sh"
        subagent="wr-voice-tone:external-comms"
        verdict="EXTERNAL_COMMS_VOICE_TONE_VERDICT: PASS"
        marker_prefix="external-comms-voice-tone-reviewed"
        ;;
    esac

    session="packaged-external-comms-$package-$$"
    draft="the packaged $package caller body"
    prompt=$'The reviewer receives text wrapped in <draft>...</draft> markers.\nSURFACE: changeset-author\n<draft>\n'"$draft"$'\n</draft>'
    key="$(gate_key "$draft" changeset-author)"
    rdir="$TMPDIR/claude-risk-$session"
    send_mark_event "$hook" "$session" "$subagent" "$prompt" "$verdict"
    [ -f "$rdir/$marker_prefix-$key" ]

    unrelated_session="$session-unrelated"
    send_mark_event "$hook" "$unrelated_session" "wr-architect:agent" "$prompt" "$verdict"
    [ ! -e "$TMPDIR/claude-risk-$unrelated_session/$marker_prefix-$key" ]
  done
}
