# Architecture review findings

Review scope: recently changed addon code and the Core, reference-compatibility, balance and UI modules. This is an architecture exploration, not an implementation plan.

## Candidates

1. **Deepen reference compatibility synchronization** — `ReferenceCompatibility.lua` owns message translation and game observations, while callbacks and guild database readiness are coordinated with `Core.lua`. The recent nil-database failure shows the startup ordering is part of this interface. A narrower synchronization interface could own readiness, parsing, merge and outgoing snapshot behavior, improving locality and allowing tests to drive the real seam. Recommendation: **Strong**.
2. **Deepen balance settlement rules** — The first split is complete: `Balance.lua` owns reward amount conversion, daily and weekly reset windows, transaction identity and recording, paid-state updates, and balance summaries/graph data. Casino and bounty modules still create and settle their own domain records before calling the shared balance methods. A future pass could check whether settlement invariants remain duplicated across those callers. Recommendation: **Worth exploring**.
3. **Deepen guild data initialization and switching** — `Core.lua` selects the guild database, performs legacy migration, repairs saved data and informs UI/sync callers. Delayed guild data can leave callers out of order. A single initialization interface could concentrate retries and transitions, while preserving the guild-scoped data decision in ADR-0001. Recommendation: **Worth exploring**.

## Current friction

- `Core.lua` currently coordinates events, profile synchronization, combat tracking, version messages, guild storage and shared serialization.
- `ReferenceCompatibility.lua` adds cross-addon behavior by wrapping Core functions and registering its own event frame.
- `Balance.lua` owns the shared balance transaction ledger and summary calculations; casino and bounty settlement lifecycle remains in their existing modules.
- Casino totals can still be counted twice when an aggregate stat snapshot arrives before a previously unknown settlement for that same total. Fixing this safely needs a migration/reconciliation design for legacy aggregate-only peers; changing message order alone would not cover delayed or repeated messages.
- These candidates are observations for discussion. No module interfaces are proposed yet.

## Top recommendation

Explore **Deepen reference compatibility synchronization** first: it is a recently changed integration path and the startup failure revealed cross-module ordering that is difficult to test through the current event-driven interface.
