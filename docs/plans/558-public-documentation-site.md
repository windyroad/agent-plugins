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

## Current plan: P3.1

### Now

Publish and verify the qualified documentation site through GitHub Pages.
P2 foundation commit 01c32d870cffb25536abb075f89a775488254a26 is pushed and watched
by exact CI 38745981110; its Documentation website job passed. Prepare and
test at most this one isolated safe slice while its watcher runs. Provider
configuration, commit, push and activation wait for the complete P2 pipeline
to succeed. If it fails, stash all P3 work, including untracked files, under a
named recoverable stash and switch to the CI repair.

Record GitHub Pages hosting as a separate proposed/unconfirmed ADR. Add one
CI-success deployment workflow and a tested source-identity guard. The build
uses read-only access, checks out the exact successful same-repository main
push, rebuilds and requalifies the artifact. The dependent deployment job has
only Pages/OIDC write access plus contents read for its freshness check, with
no checkout, npm command, executable artifact input or shared cache.

Require the triggering CI head, workflow GITHUB_SHA and current main to agree.
Reject failed CI, PRs, foreign repositories, other branches and stale heads.
Check current main again immediately before deploying. Upload only website/dist
after its tests; deploy that same run's artifact. Serialize deployments without
cancelling an active deployment. Keep source SHA, triggering CI and deployment
identity as separate receipts.

After qualification and fresh action-risk assessment, configure workflow-based
Pages and the main-only github-pages environment, then read back both before
pushing the workflow. This deterministic bootstrap publishes no artifact until
the guarded workflow runs. Inspect actual workflow permissions and outcomes,
then verify external public reading, search, navigation, deep links and
installation guides on mobile and desktop, including WebKit phone emulation.
Only add the repository's public site link after that URL works. Document source
maintenance and rollback through a source revert, green CI and verified deployment.

This is one independently deliverable public reading journey. Scope is medium;
provider bootstrap and live browser behavior remain uncertain until observed.
Means remain negotiable and existing STORY-107 carries the outcome. No npm
plugin release, custom domain, account or analytics is part of this increment.

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
- website/scripts/check-deployment.mjs and website/test/deployment.test.mjs
  exercise the actual guard CLI across successful and rejected event identities.
- .github/workflows/website.yml isolates build and deployment, and
  website/test/workflow.test.mjs inspects its configuration. Configuration tests
  alone do not prove effective permissions; inspect the actual Actions run too.

Delivered means exact trunk CI, the guarded deployment and the actual public
journeys pass, with accurate provenance and a working maintenance route.

### Next

Resolve any verified remaining gap, then record terminal story/problem/plan
evidence through governed integration. Replan from live findings rather than
inventing more functionality. No further product increment is needed if the
confirmed completion evidence is met.

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

P3 architecture review required explicit workflow SHA equality because
deploy-pages identifies the build by GITHUB_SHA, and deterministic provider
bootstrap before the workflow is pushed. Both are included above. Refined P3
and scheduling-only P3.1 pass independent architecture and JTBD recommendation
reviews. Risk forecasts own risk 3/25 and projected release 4/25, within appetite
5. P3.1 permits only one local preparation slice while the P2 watcher runs,
following AGENTS; all provider and integration effects remain gated on success.
Concrete source and action reviews remain separate requirements.

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

### Foundation qualification checkpoint

Governance commit 57461f56118de2631057dc20e267e87a3e72c742 passed exact CI
38739098720 and Release 38739098386. The private foundation now builds 80 docs
pages plus 404 from 13 selected packages and 62 skills. Local qualification:

- Eight source/artifact/configuration tests and four browser journey tests pass.
  All routes, base-path links and assets resolve. Key pages pass reflow checks at
  320, 390 and 1280 pixels in both themes; search, keyboard, no-JavaScript reading
  and WebKit iPhone 13 emulation pass. Physical iPhone and screen-reader speech
  have not been tested.
- The Node 20 root suite passes all 4,396 cases. Node 20 npm ci exits zero with
  lifecycle allow-scripts warnings; this does not prove native lifecycle scripts
  ran. Existing better-sqlite3 version is unchanged. Exact new-head CI remains
  required after push.
- Independent artifact review found no private source text, audit content or
  canaries, including decompressed search assets. Positive and negative browser
  search prove the generated index works and excludes the synthetic canary.
- Actual mobile failures drove built-in command wrapping and a narrow default
  Search wrapper for polite result-status announcements. Cached Markdown needed
  a forced Astro rebuild to apply wrapping. One desktop axe shortcut warning is
  independently classified as a symbolic-key-hint false positive, with an exact
  target exception and runtime label/shortcut assertions, not a global rule skip.
- Applied JTBD review corrected missing per-skill maturity and misleading internal
  helper invocation guidance. Recognized bands come from selected README tables;
  helpers now link to their public workflows.
- The installed architecture role injected a superseded ratification blocker.
  Source and installed role files both contain current rules permitting proposed
  implementation; an independent architecture substitute reviewed under those
  actual rules. The original role's conflicting verdict is not recorded as PASS.
  The accessibility lead's pinned model cannot execute; independent browser
  review substitutes for that capability, without claiming full conformance.

Public deployment remains disabled. This checkpoint records local qualification,
not completion of the user outcome or permission to skip exact-head CI.

### Publication preparation checkpoint

P3.1 local preparation passes the build, 23 unit/artifact/configuration/guard
tests and four browser tests. The new guard's 14 CLI scenarios are behavioral;
parsed workflow tests retain their configuration-only limit. Applied independent
architecture and JTBD reviews pass the actual workflow, guard, hosting proposal
and maintenance guide. At this preparation checkpoint, provider settings and the
public deployment are unchanged and complete P2 CI is pending. No local
preparation result is counted as the public outcome.
