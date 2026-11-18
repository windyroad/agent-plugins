# R1: Start a public recent-record view and follow its outputs

## Outcome and current gap

Authorized consumers read current state or published outputs at canonical
resource URLs. Supported consumers use that interface consistently and
superseded transport is removed. This outcome and ASAP timing are confirmed.

The ordinary public recent-record output feed is delivered. Current JSON is
presentation-paged: default 25, maximum 100 rows, with response-size bounds.
The recent projection retains 1,024 rows. A public output request replays the
guarded producer and retains one 16-publication page. Its output cursor is
not the current JSON revision or the existing private input position.

The mounted browser currently restores recent-record state and follows private
inputs. Its session lifetime, authority withdrawal, temporary-read handling and
refresh commands must survive later migration. A finite search also loads state.

## Result and value

An authorized HTTP reader obtains complete current public rows and an ordinary
output continuation from the same producer point. Following it applies later
changes without private input guards, observations or raw working state.

This API capability is needed to move the existing browser pages away from
private state/input transport. Deliver it first to establish a supported
rollback floor. This increment does not switch the browser.

## Implementation

1. Add `view=recent-set` at the existing canonical query URL. Return all retained
   public rows, refresh/coverage facts and an output continuation captured with
   those rows. Preserve existing JSON paging. The layout is not resource identity.
2. Reuse the producer fold and public mapper. Capture its public prefix
   synchronously with rows; reuse ordinary output cursors. Empty state invents
   no event. Do not reinterpret private guards or JSON revisions as output progress.
3. Support warm continuation with the existing guarded reader lifecycle and a
   bounded cache retaining the latest 16-publication page and public positions.
   Recheck authority before return. Historical pages retain finite replay.
   No durable output journal, second calculation, framework or background service.
4. Preserve reset, cancellation, disposal, authority errors, publication order,
   corrections/removals/evictions, refresh facts and combined retention.
5. Extend normal HTTP and hosted qualification for current/output agreement,
   append/correction, empty initialization and paired continuation without gaps
   or duplicates. Verify idle warm continuation does not replay all history.
   Retain existing applicable performance and authority checks.
6. Follow the existing test-to-production compatibility, rollback and acceptance
   workflow. Remove replaced implementation-only experiments.

## Acceptance and sequence

Authorized HTTP reads return the complete public recent set and its continuation.
Later corrections, removals and refresh facts apply without private-input exposure.
Existing JSON and browser journeys remain supported. No browser switch occurs now.

Next, provisionally migrate the mounted views and finite search to this delivered
contract, removing superseded browser calculation and transport. Reassess from
delivery evidence. Other resource families and final legacy cleanup remain later.
