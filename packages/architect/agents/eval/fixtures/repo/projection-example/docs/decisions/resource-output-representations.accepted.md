---
status: accepted
human-oversight: confirmed
---

# Negotiate published outputs at the canonical resource URL

## Decision Outcome

At a resource's canonical URL, GET selects either current JSON or published
outputs using the shared output-events media type. Headerless JSON stays
compatible. Use the ordinary event-feed protocol, ordering, continuation and
reset behavior. Reuse the producer calculation and public mapper rather than
implementing a second calculation in the output adapter.

## Consequences

Outputs can feed sinks and downstream projections without exposing private
producer inputs. Representation selection grants no additional authority.
This decision selects addressing and representations, not a client loading
algorithm, projection definition or computation placement.
