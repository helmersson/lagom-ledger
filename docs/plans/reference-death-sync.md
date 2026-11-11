# Reference death synchronization task note

- Project: `Lagom Ledger`
- Updated: 2026-11-11
- Target: World of Warcraft Forever, interface `16001`
- Scope: resume and verify the death behavior requested from the supplied reference addon.

## Requirement and result

| ID | Requirement | Implementation | Acceptance status |
| --- | --- | --- | --- |
| REQ-DS-001 | Mirror the reference addon's death behavior for addon users. | `PLAYER_DEAD` calls `LL:RecordDeath()`, which increments the local profile's `deaths` count and broadcasts a `PROFILE` update over the guild addon channel. | Implemented; static checks passed. |
| REQ-DS-002 | Do not use the forbidden combat-log registration or provide an invented killer/zone message. | No `COMBAT_LOG_EVENT_UNFILTERED`, `DEATH_NOTICE`, killer or zone logic is registered. | Implemented; static check passed. |

The supplied reference handles `PLAYER_DEAD` by incrementing `c.deaths` and calling `SendStats()` when active. It contains no death-chat-message feature. The matching Lagom Ledger behavior is therefore a death counter and addon-channel profile synchronization only.

## Target evidence

The bundled Forever source inventory resolves to commit `eac30af597e5aaa43a60f6675ef5fdcea100375f`, version `1.60.1.70790`, interface `16001`. Its generated declaration lists `PLAYER_DEAD` as a synchronous `C_DeathInfo` event at `DeathInfoDocumentation.lua:128`. Source declaration confirms the event name only; in-game delivery still requires a WoW Forever test.

## Validation

| ID | Check | Result |
| --- | --- | --- |
| V-DS-001 | Search `Core.lua` for all `RecordDeath` callers and event registrations. | Passed: automatic caller is `PLAYER_DEAD`; `/lagom death` remains the explicit manual correction command. |
| V-DS-002 | Search for blocked or removed death-notice paths. | Passed: no `COMBAT_LOG_EVENT_UNFILTERED`, `DEATH_NOTICE`, killer or zone notifier remains. |
| V-DS-003 | Whitespace validation with `git diff --no-index --check`. | Passed: no whitespace errors reported. |
| V-DS-004 | Runtime test in WoW Forever. | Not run: requires a character death, `/reload`, and a second guild member with the addon to observe synchronization. |

## Scope and remaining check

No UI, options, localization, controller, or saved-variable schema changes are needed for this event-only correction. The existing UI remains unchanged. Install the release, run `/reload`, die once, and confirm that the local death total rises by one and reaches a second addon user in **OG Lagom**.

