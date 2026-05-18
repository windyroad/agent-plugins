#!/usr/bin/env bash
# packages/retrospective/scripts/check-plugin-maturity-drift.sh
#
# Phase 3b (P087 / P238) plugin-maturity drift advisory.
#
# Compares each plugin's rendered README.md maturity badge against the
# canonical `plugin.json` `maturity:` field and emits an NDJSON-shaped
# drift signal per plugin to stdout. Sibling to ADR-051's
# `check-readme-jtbd-currency.sh` — same detector pattern, different
# anchor (maturity rollup vs JTBD citation), different failure mode
# (render-vs-canonical drift vs citation drift).
#
# Drift hint vocabulary:
#
#   missing-badge        — plugin.json carries `maturity:` but the README
#                          has no `*Maturity: ...*` prose-woven badge
#   stale-band           — README badge band mismatches canonical record
#   orphan-badge         — README has badge but plugin.json has no
#                          `maturity:` field (renderer ran ahead of
#                          populate; or populate was reverted)
#   anti-pattern-section — README has a standalone `## Maturity` heading
#                          (ADR-063 §"README badge rendering format"
#                          rejects the section shape)
#   anti-pattern-url     — README has a shields.io URL or inline SVG
#                          (ADR-063 §F5 rejects external-dependency
#                          rendering)
#
# Output format (one line per package, alphabetical):
#   README package=<name> badge_band=<band|none> record_band=<band|none>
#     drift_hints=<csv>
# Plus a trailing TOTAL line:
#   TOTAL packages=<N> drift_instances=<K>
#
# Exit code is always 0 — advisory only per ADR-013 Rule 6 / ADR-040
# declarative-first / ADR-051 Phase 1 precedent. Drift count is emitted
# as data on stdout; downstream consumers (run-retro Step 2b wiring,
# release-pre-flight habit, Phase 4 escalation per ADR-051 Phase 2
# criterion) decide whether to act.
#
# Usage:
#   check-plugin-maturity-drift.sh [<packages-dir>]
#
# Default:
#   <packages-dir> = ./packages
#
# Exit codes:
#   0 = always (advisory only — count is signal, not failure)
#   2 = parse error (packages-dir missing or unreadable)
#
# @problem P238 (Phase 3b — drift detector)
# @problem P087 (parent — no maturity signal on plugin features)
# @problem P152 (sibling drift-detector pattern — JTBD-currency)
# @adr ADR-063 (Plugin maturity presentation layer — Phase 3b contract)
# @adr ADR-051 (Sibling drift-detector pattern)
# @adr ADR-013 Rule 6 (non-interactive fail-safe — advisory exit 0)
# @adr ADR-040 (Declarative-first / advisory-then-escalate)
# @adr ADR-049 (Shim grammar — `wr-retrospective-check-plugin-maturity-drift`)
# @adr ADR-052 (Behavioural tests default)
# @jtbd JTBD-302 (Trust That the README Describes the Plugin I Just Installed)
# @jtbd JTBD-007 (Keep Plugins Current Across Projects — maturity-band-currency
#   as third currency dimension alongside code + JTBD-content)
# @jtbd JTBD-101 (Extend the Suite — clear patterns include stability signal)

set -uo pipefail

PACKAGES_DIR="${1:-packages}"

# ── Pre-checks ──────────────────────────────────────────────────────────────

if [ ! -d "$PACKAGES_DIR" ]; then
  echo "check-plugin-maturity-drift: packages dir not found: $PACKAGES_DIR" >&2
  exit 2
fi

# ── Python body ─────────────────────────────────────────────────────────────

export CPMD_PACKAGES_DIR="$PACKAGES_DIR"

python3 - <<'PYEOF'
import json, os, re, sys
from pathlib import Path

packages_dir = Path(os.environ["CPMD_PACKAGES_DIR"]).resolve()

if not packages_dir.is_dir():
    print(f"check-plugin-maturity-drift: packages dir not found: {packages_dir}", file=sys.stderr)
    sys.exit(2)

# Badge prose-woven pattern: `*Maturity: <Band>...*` per ADR-063
# §"README badge rendering format". Captures the band token as the
# first word after `Maturity:`.
BADGE_RE = re.compile(r"\*Maturity:\s+([A-Za-z]+)[^*]*\*")
ANTI_SECTION_RE = re.compile(r"(?m)^#{1,3}\s+Maturity\s*$")
ANTI_URL_RE = re.compile(r"shields\.io|img\.shields", re.IGNORECASE)


def extract_badge_band(readme_text):
    """Returns the band token from a `*Maturity: <Band>...*` span, or
    None when no such span is present.
    """
    m = BADGE_RE.search(readme_text)
    if m:
        return m.group(1)
    return None


def append_hint(current, hint):
    if not current:
        return hint
    parts = current.split(",")
    if hint in parts:
        return current
    return current + "," + hint


def evaluate_plugin(pkg_dir):
    """Returns (line_dict, hint_count) for one plugin, or None when the
    plugin should be silently skipped (no README).
    """
    plugin_json_path = pkg_dir / ".claude-plugin" / "plugin.json"
    readme_path = pkg_dir / "README.md"
    if not readme_path.is_file():
        return None
    try:
        plugin_doc = json.loads(plugin_json_path.read_text(encoding="utf-8"))
    except Exception:
        plugin_doc = {}
    if not isinstance(plugin_doc, dict):
        plugin_doc = {}

    record_band = None
    maturity = plugin_doc.get("maturity")
    if isinstance(maturity, dict):
        record_band = maturity.get("band")

    readme_text = readme_path.read_text(encoding="utf-8")
    badge_band = extract_badge_band(readme_text)

    hints = ""

    if record_band and not badge_band:
        hints = append_hint(hints, "missing-badge")
    elif badge_band and not record_band:
        hints = append_hint(hints, "orphan-badge")
    elif record_band and badge_band and record_band != badge_band:
        hints = append_hint(hints, "stale-band")

    if ANTI_SECTION_RE.search(readme_text):
        hints = append_hint(hints, "anti-pattern-section")
    if ANTI_URL_RE.search(readme_text):
        hints = append_hint(hints, "anti-pattern-url")

    line = {
        "package": pkg_dir.name,
        "badge_band": badge_band or "none",
        "record_band": record_band or "none",
        "drift_hints": hints,
    }
    return (line, 1 if hints else 0)


# ── Walk packages/ ─────────────────────────────────────────────────────────

plugin_dirs = sorted(
    [d for d in packages_dir.iterdir()
     if d.is_dir() and (d / ".claude-plugin" / "plugin.json").is_file()
     or (d.is_dir() and (d / "README.md").is_file())]
)

total_packages = 0
total_drift_instances = 0

for pkg_dir in plugin_dirs:
    result = evaluate_plugin(pkg_dir)
    if result is None:
        continue
    line, drift = result
    total_packages += 1
    total_drift_instances += drift
    print(
        f"README package={line['package']} "
        f"badge_band={line['badge_band']} "
        f"record_band={line['record_band']} "
        f"drift_hints={line['drift_hints']}"
    )

if total_packages > 0:
    print(f"TOTAL packages={total_packages} drift_instances={total_drift_instances}")

PYEOF

exit 0
