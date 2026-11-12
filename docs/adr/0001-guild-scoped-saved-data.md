# ADR-0001: Keep saved data separate by guild

- Status: Accepted
- Date: 2026-11-12

## Context

Ledger can be used by characters in different guilds. A single shared board database would expose one guild's member records, bounties and casino history to another guild using the same installation/account.

## Decision

At login, Ledger selects a SavedVariables partition keyed by the current guild name and realm. Guild profiles, bounties, casino data, settlements and minimap settings live in that partition. Existing unpartitioned data is migrated to the guild active on the first updated login.

## Consequences

- Each guild has an independent Ledger dataset on that account.
- Characters outside a guild do not load a guild dataset.
- The initial migration associates legacy records with the guild active during that login; it cannot infer which guild originally owned historical entries.
- Guild addon messages remain the transport for online synchronization; there is no external server.
