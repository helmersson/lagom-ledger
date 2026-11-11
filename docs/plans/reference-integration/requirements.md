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
| REQ-RI-006 | Detect the character's current guild at login and keep each guild's data separate. | User request; `Core.lua`. | Required | forever | `LL.GUILD_NAME` reflects the active guild; leaderboards, bounties, casino data and minimap positions are read from that guild's saved-data partition, including after a guild change. Equivalent player names using a space or hyphen realm separator are merged. | active |
| REQ-RI-007 | Reskin the guild board, casino and balance sheet to match the supplied ForeverDungeonJournal visual language without changing their behavior. | User request; `D:/Blizzard/World of Warcraft/_forever_/Interface/AddOns/ForeverDungeonJournal/`. | Required | forever | One resizable window uses the dark journal shell, warm gold accents, framed panels and compact navigation/cards; its Casino and Balance sheet tabs retain their separate information and payment actions. Expressway is used when an active EllesmereUI or atrocityEssentials installation provides it; otherwise Friz Quadrata remains the fallback. | active |
| REQ-RI-008 | Make the Ledger minimap button compatible with EllesmereUIMinimap's standard collection, grouping and movement behavior. | User request; `EUI_Minimap_Buttons.lua`. | Required | forever | With EllesmereUIMinimap active, the named Ledger button can be collected and moved by EUI without Ledger resetting its anchor or handling its standalone drag. | active |
| REQ-RI-009 | Show current honorable-kill streaks and current/longest life duration in the PvP views. | User request. | Required | forever | A confirmed honorable kill increments the local streak; an observed PvP death resets it; profile synchronization shows streak, current life and longest completed life for Ledger users. Kills and Deaths also show a centered top-three strip with class portraits and gold/silver/bronze crowns, plus All time and Weekly toggles. Weekly scores reset at the native WoW server weekly reset. | active |
| REQ-RI-010 | Keep the resizable board within the current screen, scale navigation buttons with its width, provide a size reset, and notify old clients about updates during login synchronization. | User report; UI screenshot. | Required | forever | The window cannot exceed the current UI size, `/lagom reset` and **Reset size** restore it, navigation labels remain inside their buttons, and a v1.7.2+ client receives one local update notice from the internal guild version prefix during or after login. | active |
| REQ-RI-011 | Let a casino loser prepare and record a payment for the next outstanding casino debt through the Blizzard mail form. | User request. | Required | forever | At an open mailbox, **Prepare mail** fills the owed winner, subject and gold; the user sends it through Blizzard's button and explicitly selects **Mark paid**. Paid state synchronizes between Ledger users. | active |

## Target and API evidence

| Target | Intended client/build/interface | Source commit and evidence | Related REQ IDs | Loading/access/runtime uncertainty |
| --- | --- | --- | --- | --- |
| forever | 1.60.1.70790 / 16001 | Bundled source commit `eac30af597e5aaa43a60f6675ef5fdcea100375f`; `PLAYER_DEAD` is declared in `DeathInfoDocumentation.lua:128`, `PLAYER_ALIVE` in `DeathInfoDocumentation.lua:122`, `PLAYER_REGEN_DISABLED` in `UnitDocumentation.lua:3884`, `UnitCanAttack` in `UnitDocumentation.lua:762`, `PLAYER_GUILD_UPDATE` in `GuildInfoDocumentation.lua:649`, and `C_AddOns.IsAddOnLoaded` in `AddOnsDocumentation.lua:321`. | REQ-RI-003, REQ-RI-005, REQ-RI-006, REQ-RI-008, REQ-RI-009 | PvP-death context is best-effort because no reliable attacker/victim event is used. |
| forever | 1.60.1.70790 / 16001 | `C_SecureTransfer.SendMail` is restricted in `SecureTransferDocumentation.lua:90`; the native mail edit boxes are only used from the player's click while a mailbox is open. | REQ-RI-011 | The native money widget's `SetAmount` behavior must be confirmed in the Forever client. |

## UI and accepted design

- Mock-up choice and source: **implement directly**, selected by the user; visual reference supplied in `ForeverDungeonJournal`.
- Accepted design: dark 780px-wide journal shell, warm gold accents, framed header/sidebar/content panels, vertical icon navigation and compact alternating rows. Kills and Deaths add a centered top-three class-portrait strip. A lower-right grip resizes the window within screen bounds; the sidebar and navigation buttons grow to a capped proportion of width, while **Reset size** restores the default. The Casino tab uses a game-control panel, two leaderboard panels and a history panel; Balance sheet contains the shared transaction view and payment controls. Scope buttons are individually anchored to avoid overlap. Expressway is applied from active EllesmereUI or atrocityEssentials media, with Friz Quadrata as fallback.
- Relevant REQ IDs: REQ-RI-001, REQ-RI-002, REQ-RI-007.
- Layout, assets and states to preserve: existing board tabs, kill streak and life-duration columns, bounty entry/actions, casino controls, top-10 lists and five-game history; use only built-in game textures, not reference-addon media.

## Options-menu integration and localization

- Options discovery: no new configurable behavior; existing EllesmereUI entry remains.
- Settings lifecycle: account-wide `LagomLedgerDB` is partitioned by the current guild name and realm; legacy v1.6.0 data migrates to the guild active during the first updated login.
- Locale architecture: existing English visible text remains; no new locale catalog is introduced by this adaptation.

## Controller interaction assessment

| UI element or control group | Role | Controller path and visible cues | Target evidence / gaps | Acceptance |
| --- | --- | --- | --- | --- |
| Board navigation, bounty actions, resize grip, reset action, casino controls and Balance sheet scope/payment controls | interactive | Native buttons and edit boxes retain mouse/keyboard operation; vertical navigation makes the active record, Casino or Balance sheet tab visible; scope buttons use separate anchors; the lower-right grip supports mouse resizing and **Reset size** restores the default. | Controller focus, activation, resizing, reset, scrolling and text entry are not tested with a controller in Forever. | Pending real-client test. |
| Minimap button | interactive | Left-click opens the board and right-click opens the casino. EllesmereUI manages grouping and Shift-drag when its minimap module is active. | Controller reachability and activation are not tested with a controller in Forever. | Pending real-client test. |
| Table rows, labels and footer | passive | No focus stop required. | Not applicable. | Static review. |

## Testing preference

- Route and source: pending user choice between Witchcraft in-game and UIForever simulator.
- Remaining real-client checks: legacy-message exchange with a reference-addon user, automatic kill/bounty claim, casino regression and controller navigation.

## Decisions and scope changes

| ID / date | Source | Decision or change | Affected REQ IDs | Consequence |
| --- | --- | --- | --- | --- |
| DEC-RI-001 / 2026-11-11 | User request | Adapt the reference protocol in Ledger rather than requiring players to install both addons. | REQ-RI-003, REQ-RI-004 | One Ledger data model remains authoritative locally; adapters translate at the guild-message boundary. |
| DEC-RI-002 / 2026-11-11 | User request | Keep Ledger-only casino and integrations. | REQ-RI-002, REQ-RI-004 | The board gains a casino entry; casino messages remain Ledger-only. |
| DEC-RI-003 / 2026-11-11 | User request | Replace the fixed OG Lagom gate with the current player guild and partition SavedVariables by guild name and realm. | REQ-RI-006 | The first updated login migrates the prior single database into its current guild partition. |
| DEC-RI-004 / 2026-11-11 | User request | Implement the ForeverDungeonJournal-inspired visual redesign directly, retaining Ledger behavior and using built-in art only. | REQ-RI-007 | Board and casino share one dark journal visual language without copying the reference addon's code or media. |
| DEC-RI-005 / 2026-11-11 | User request | Let EllesmereUIMinimap collect the existing named Ledger button rather than adding a second integration or using EUI private globals. | REQ-RI-008 | Ledger preserves its standalone placement only when the EUI minimap module is inactive. |
| DEC-RI-006 / 2026-11-11 | User request | Move casino controls into the main Ledger window as the Casino navigation tab. | REQ-RI-002, REQ-RI-007 | `/lagom casino` and minimap right-click select the tab rather than opening a separate window. |
| DEC-RI-007 / 2026-11-11 | User request | Make the shared Ledger window resizable and resize the board table and casino result panels with it. | REQ-RI-007 | The lower-right mouse grip controls sizing; fixed controls retain a usable minimum size. |
| DEC-RI-008 / 2026-11-11 | User request | Derive streaks from the honorable-kill total, and reset only after locally observed PvP combat followed by death. | REQ-RI-009 | No combat-log or fabricated killer data is used; deaths without a recent hostile-player target do not reset the streak. |
| DEC-RI-009 / 2026-11-11 | User report | Bound the window to current screen dimensions and use a dedicated internal version prefix plus profile synchronization to make update notices visible locally at login. | REQ-RI-010 | v1.7.2+ clients exchange validated versions through `LagomLedgerVer`; compatible older Ledger versions retain the profile-sync fallback. No whispers are sent. |

## Completion criteria

All active requirements are implemented, static checks pass, both protocol prefixes are registered, and the required in-game acceptance checks are recorded as passed or explicitly pending.
