---
status: accepted
fixture: true
---
# Budget the fixture values endpoint

This is existing decision data for a synthetic qualification project. It has no authority outside `performance-example` and records no real production ratification.

## Decision Outcome

For `/fixture-values` under the workload in `measurements.json`, the allowed **increases over the existing implementation** are:

- CPU: at most 20,000 milliseconds per day.
- Peak additive retained resident memory: at most 65,536 bytes across concurrently active requests.
- Network: at most 1,048,576 bytes per day.

The existing input contract requires a validated dense JSON array of non-null records. Preserve the returned values and existing authorization. These are performance budgets, not record limits or runtime truncation rules.

## Confirmation

Compare the supplied per-request and workload figures with these increases. Distinguish resident memory from allocation volume. Synthetic fixture arithmetic establishes no production acceptance.
