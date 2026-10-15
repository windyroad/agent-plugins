# Public documentation site delivery

## Confirmed objective

By end of Sunday 18 October 2026, Australia/Sydney, publish a public Windy Road
Agent Plugins docs website where users can find, understand, install and use the
plugins and skills, including outcome-led planning. Provide search, clear
navigation, iPhone-friendly reading and shareable page links comparable to Em
See Pea's docs, accurate Claude Code/Codex guidance and repository-maintained
updates. Completion means deployed reading, search, navigation and
installation-guide journeys verified on mobile and desktop.

The user explicitly confirmed this playback before executable planning.

## Current plan: P2

### Now

One coherent buildable foundation in an independent clone. Capture P558,
RFC-107 and STORY-107 on the existing ratified STORY-MAP-008, the proposed
static-docs decision and necessary guide scope. Then establish a private
website/ workspace outside packages/* with selected public sources, initial
reading/installation pages, build and behavioral checks. Integrate tested safe
commits with the standard exact-head CI watcher. This foundation is not public
completion and is not an npm plugin release.

Expected scope is medium; uncertainty remains in provider configuration,
canonical Markdown rendering and browser accessibility. One story carries the
whole outcome; independently safe foundation commits need not create extra
stories. Means remain negotiable within the confirmed objective.

Required named controls:

- website/public-sources.json explicitly lists curated website pages and exact
  selected package README/canonical skill inputs. No recursive repository docs import.
- website/test/public-content.test.mjs exercises source allowlisting, rejected
  paths/symlinks, forbidden-source sentinel fixtures and built HTML/assets/search
  exclusions. Independently review the exact generated public artifact before activation.
- website/test/site.test.mjs exercises built base-path routes, deep links,
  assets, search, keyboard, mobile 320/390 and desktop 1280, themes and no-JavaScript reading.
- website/test/workflow.test.mjs checks website isolation from plugin publication,
  deployment dependencies and job-level permissions. The Pages path must contain no npm publish.
- Preserve source version/maturity evidence and truthful per-runtime guidance.
- Fresh checkout/pipeline evidence and concrete action-risk review before commit,
  push and activation. No forecast control is claimed as passed evidence.

Delivered foundation means build/tests and exact trunk pipeline pass while
unqualified public deployment remains disabled.

### Next

Provisionally complete plugin/skill references and accurate runtime guidance;
verify actual artifact accessibility, mobile/search journeys and disclosure
boundary. Record hosting separately, enable the least-permission Pages workflow
only after checks/reviews and green trunk, deploy the approved artifact and
verify live public URLs, search and mobile/desktop journeys. Replan from actual
findings and obtain all three assessments before dependent revised work.

### Later

Only improvements justified by demonstrated reuse. No custom backend, account,
analytics, custom domain or speculative tooling is part of this objective.
Drop unnecessary work once the confirmed result is verified.

## Assessment

P1 risk review identified unnamed public-content and deployment checks, with
projected release risk 9/25 above appetite 5. No implementation followed that
failed plan. P2 names the source/artifact/workflow/browser controls above.
Architecture approves the P2 governance slice in fresh clone 5ee86a3a; JTBD
review passes against confirmed developer jobs 003/007. Plan-risk and projected
release-risk each pass at 4/25, with forecast controls not execution evidence.
Architecture/source/action reviews remain required for each concrete slice.

The installed accessibility lead could not execute because its pinned model is
unavailable. An independent fallback provided requirements only; no implemented
accessibility pass or full conformance claim exists. Browser testing remains
required. Style review approves Starlight defaults and narrow guide extension.
Voice review corrected the row to describe reading docs on phones, not running
plugins on phones; site guide scope must precede site copy.

## Evidence and learning

- Independent clone: /Users/tomhoward/Projects/agent-plugins-docs-20261015.
- Baseline 5ee86a3a matches origin/main; exact CI 38685350159 and Release
  38685350128 succeeded. No pending/queued changeset at baseline.
- GitHub Pages GET returned 404; no existing site observed. Repository actor has
  admin permission. Public deployment is within the confirmed objective, subject
  to actual qualification and action assessment.
- Website belongs outside packages/* because plugin CI/publishing loops assume
  those directories contain installable plugins. Private:true alone is insufficient.
- Root README contains superseded prose; it will not be copied wholesale.
- ADR-139 remains proposed/unconfirmed. Production use and explicit final human
  ratification are required before acceptance; this plan writes no oversight marker.
