# Reference Lagom integration requirements

- Project/repository: `Lagom Ledger`
- Updated: 2026-11-11
- Implementation matrix: [matrix.md](matrix.md)
- Original request: User supplied `C:/Users/wilhe/Downloads/Lagom_1/Lagom/` and asked for its interface and all of its functionality in Lagom Ledger, while retaining existing functionality and cross compatibility.
- Goal: Players running either **Lagom** 1.0.2 or **Lagom Ledger** can share guild-board data; Ledger users retain casino, minimap, EllesmereUI and existing commands.
- Scope boundary: World of Warcraft Forever only. The reference addon has no casino, so casino data remains a Ledger-only feature.

## Requirements

| ID | Required behavior or constraint | Origin and source | Priority | Targets | Observable acceptance criteria | State |
| --- | --- | --- | --- | --- | --- | --- |
| REQ-RI-001 | Recreate the reference addon's main board: Kills, Deaths, Bounties and Professions tabs, its table layout, scroll behavior and draggable framed window. | User request; `Lagom/UI.lua`. | Required | forever | `/lagom kills`, `/lagom deaths`, `/lagom bounties` and `/lagom professions` open the matching board views. | active |
| REQ-RI-002 | Preserve Lagom Ledger features: casino, minimap button, EllesmereUI integration, update notices, manual bounty completion and existing saved data. | User request; existing Ledger files. | Required | forever | Existing `/lagom casino`, `/lagom settings`, minimap actions and `LagomLedgerDB` continue to work. | active |
| REQ-RI-003 | Make Ledger compatible with reference guild messages and behavior: stats, bounties, hello/snapshot handling, tracked honorable kills, all deaths, bounty target alert and automatic bounty completion after a verified kill credit. | User request; `Lagom/Core.lua`. | Required | forever | A Ledger client exchanges `LagomGuild` `S`, `B`, `H` and `D` messages with a reference client without a duplicate data store. | active |
| REQ-RI-004 | Retain Ledger's `LAGOMLEDGER` protocol so existing Ledger installs continue to communicate and casino functionality is unaffected. | User request; existing `Core.lua`, `Casino*.lua`. | Required | forever | Native profiles, bounties and casino messages still use `LAGOMLEDGER`; reference messages only add interoperability. | active |
| REQ-RI-005 | Do not register blocked combat-log events or fabricate killer/zone data. | Previous failure; Forever limitation. | Required | forever | No `COMBAT_LOG_EVENT_UNFILTERED` registration exists; auto-claim relies on the reference's target/death observation plus honorable-kill count. | active |

## Target and API evidence

| Target | Intended client/build/interface | Source commit and evidence | Related REQ IDs | Loading/access/runtime uncertainty |
| --- | --- | --- | --- | --- |
| forever | 1.60.1.70790 / 16001 | Bundled source commit `eac30af597e5aaa43a60f6675ef5fdcea100375f`; `PLAYER_DEAD` is declared in `DeathInfoDocumentation.lua:128`. | REQ-RI-003, REQ-RI-005 | Events and stat APIs still require in-game validation; no combat-log event is used. |

## UI and accepted design

- Mock-up choice and source: existing accepted design — supplied `Lagom/UI.lua`.
- Accepted design: classic 600×470 framed board, yellow title, four native tabs, compact bounty entry and tabular rows.
- Relevant REQ IDs: REQ-RI-001, REQ-RI-002.
- Layout, assets and states to preserve: reference `Lagom/UI.lua`; Ledger-only casino entry is an additive action.

## Options-menu integration and localization

- Options discovery: no new configurable behavior; existing EllesmereUI entry remains.
- Settings lifecycle: existing account-wide `LagomLedgerDB` remains; no new saved preference is required.
- Locale architecture: existing English visible text remains; no new locale catalog is introduced by this adaptation.

## Controller interaction assessment

| UI element or control group | Role | Controller path and visible cues | Target evidence / gaps | Acceptance |
| --- | --- | --- | --- | --- |
| Main board tabs, buttons and edit fields | interactive | Preserves native button/edit widgets; focus/navigation behavior is client-owned. | Not tested with a controller in Forever. | Pending real-client test. |
| Table rows, labels and footer | passive | No focus stop required. | Not applicable. | Static review. |

## Testing preference

- Route and source: pending user choice between Witchcraft in-game and UIForever simulator.
- Remaining real-client checks: legacy-message exchange with a reference-addon user, automatic kill/bounty claim, casino regression and controller navigation.

## Decisions and scope changes

| ID / date | Source | Decision or change | Affected REQ IDs | Consequence |
| --- | --- | --- | --- | --- |
| DEC-RI-001 / 2026-11-11 | User request | Adapt the reference protocol in Ledger rather than requiring players to install both addons. | REQ-RI-003, REQ-RI-004 | One Ledger data model remains authoritative locally; adapters translate at the guild-message boundary. |
| DEC-RI-002 / 2026-11-11 | User request | Keep Ledger-only casino and integrations. | REQ-RI-002, REQ-RI-004 | The board gains a casino entry; casino messages remain Ledger-only. |

## Completion criteria

All active requirements are implemented, static checks pass, both protocol prefixes are registered, and the required in-game acceptance checks are recorded as passed or explicitly pending.

