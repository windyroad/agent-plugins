---
status: accepted
human-oversight: confirmed
---

# Load client projections from current state and declared direct inputs

## Context

A projection builds its view by processing events. Higher-order projections
consume other projections' published output feeds. Clients need one loading
model across projection orders.

## Decision Outcome

The same projection definition runs on server and browser. The client GETs its
complete current state with paired positions in its declared direct-input
feeds, then processes those input events to keep the projection current.

A direct input may be another producer's public output feed. The client does
not recursively retrieve that producer's private inputs.

## Example

A private sanitizing producer publishes public record events. A downstream
category-count projection consumes them. Server and browser run the same count
definition. GET restores count state and positions in the public record feeds;
the browser processes those feeds without running the private sanitizer.

## Confirmation

Initial state and subsequent input events yield equivalent server and browser
views for first-order and higher-order projections, including newly matching
inputs. Access to outputs grants no access to private upstream inputs.
