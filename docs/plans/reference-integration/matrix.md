# Reference Lagom integration matrix

- Requirements: [requirements.md](requirements.md)
- Integration owner: Codex
- Updated: 2026-11-11

## Implementation coverage

| Row | REQ IDs | Target(s) | Slice / observable result | Dependencies / order | Owner | Implementation files | Status | Validation IDs / remaining work |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| IMP-RI-001 | REQ-RI-003, REQ-RI-004, REQ-RI-005 | forever | Add the reference protocol and behavior through one Ledger compatibility adapter. | Core loaded first | Codex | `ReferenceCompatibility.lua`, `Core.lua`, `.toc` | implemented | V-RI-001 and V-RI-002 passed; V-RI-003 needs a game client. |
| IMP-RI-002 | REQ-RI-001, REQ-RI-002 | forever | Replace the board view with the reference layout while keeping Ledger actions. | IMP-RI-001 data helpers | Codex | `UI.lua` | implemented | V-RI-004 passed; V-RI-005 needs a game client. |
| IMP-RI-003 | REQ-RI-001 to REQ-RI-005 | forever | Update release notes and reconcile validation. | IMP-RI-001, IMP-RI-002 | Codex | `README.md`, plan files, `.toc`, `tests/ReferenceCompatibility.Contract.Tests.ps1` | implemented | V-RI-006 passed. |
| IMP-RI-004 | REQ-RI-006 | forever | Select the current guild at login, partition SavedVariables per guild and migrate the previous single database. | Core loaded before compatibility adapter | Codex | `Core.lua`, `UI.lua`, `Ellesmere.lua`, `.toc`, `README.md`, plan files, `tests/ReferenceCompatibility.Contract.Tests.ps1` | implemented | V-RI-007 static validation; V-RI-008 needs a game client. |
| IMP-RI-005 | REQ-RI-007 | forever | Reskin the board, place casino and Balance sheet in shared-window navigation, use Expressway from active UI integrations with a Friz fallback, and resize table/results layouts with the journal window. | Existing UI behavior | Codex | `UI.lua`, plan files, `tests/ReferenceCompatibility.Contract.Tests.ps1` | implemented | V-RI-009 static validation; V-RI-010 needs a game client. |
| IMP-RI-006 | REQ-RI-008 | forever | Hand the existing named minimap button to EllesmereUIMinimap whenever its module is active, while retaining standalone placement otherwise. | Existing minimap button and EUI module | Codex | `Ellesmere.lua`, `UI.lua`, `.toc`, `README.md`, plan files, `tests/ReferenceCompatibility.Contract.Tests.ps1` | implemented | V-RI-011 static validation; V-RI-012 needs a game client. |
| IMP-RI-007 | REQ-RI-009 | forever | Synchronize streak, life and weekly-score fields; update them from honorable kills/deaths; and show them with a centered crowned top-three class-portrait strip plus All time/Weekly toggles in the PvP tables. | Core profile, native weekly reset and reference kill counter | Codex | `Core.lua`, `ReferenceCompatibility.lua`, `UI.lua`, `README.md`, plan files, `tests/ReferenceCompatibility.Contract.Tests.ps1` | implemented | V-RI-013 static validation; V-RI-014 needs a game client. |
| IMP-RI-008 | REQ-RI-010 | forever | Bound and reset the board size, make navigation width responsive, and exchange login-time version notices on a dedicated internal guild prefix. | Existing board and profile synchronization | Codex | `Core.lua`, `ReferenceCompatibility.lua`, `UI.lua`, `README.md`, plan files, `tests/ReferenceCompatibility.Contract.Tests.ps1` | implemented | V-RI-015 static validation; V-RI-016 needs a game client. |
| IMP-RI-009 | REQ-RI-011 | forever | Prepare the next casino-debt payment in Blizzard Mail, require explicit paid confirmation and synchronize that confirmation. | Existing casino settlement protocol | Codex | `Casino.lua`, `CasinoGames.lua`, `Core.lua`, `UI.lua`, `README.md`, plan files, `tests/ReferenceCompatibility.Contract.Tests.ps1` | implemented | V-RI-017 static validation; V-RI-018 needs a game client. |

## Validation evidence

| ID | REQ IDs / slice | Target | Mode | Procedure and expected result | Status |
| --- | --- | --- | --- | --- | --- |
| V-RI-001 | IMP-RI-001 | forever | static | Search all event registrations; no forbidden combat-log event is present. | Passed: `ReferenceCompatibility.Contract.Tests.ps1` asserts no forbidden event and the compatibility adapter registers only reference events. |
| V-RI-002 | IMP-RI-001 | forever | static | Inspect `LagomGuild` parsing/serialization against the supplied `Lagom/Core.lua`. | Passed: static contract verifies the `LagomGuild` prefix and exact `S`/`B` field formats; adapter implements `H` and `D`. |
| V-RI-003 | IMP-RI-001 | forever | in-game | Ledger and reference clients exchange stats and bounties. | not run |
| V-RI-004 | IMP-RI-002 | forever | static | Verify four tabs and retained Ledger entry points. | Passed: static contract verifies four board tabs, casino and minimap entry points. |
| V-RI-005 | IMP-RI-002 | forever | in-game | Open each tab, scroll, post/remove/complete a bounty, open casino and use minimap button. | not run |
| V-RI-006 | IMP-RI-003 | forever | static | TOC/file order/version and whitespace check. | Passed: PowerShell contract test and `git diff --no-index --check` completed without errors. |
| V-RI-007 | IMP-RI-004 | forever | static | Assert the dynamic guild lookup, per-guild database selection, legacy migration, player-name deduplication and guild-change event registration. | Passed: `tests/ReferenceCompatibility.Contract.Tests.ps1`. |
| V-RI-008 | IMP-RI-004 | forever | in-game | Log into two guilds on the same account and verify that the board and casino show independent saved data after `/reload`. | not run |
| V-RI-009 | IMP-RI-005 | forever | static | Verify journal theme, non-overlapping Balance sheet scope buttons, Expressway fallback, attached Casino/Balance sheet content, responsive table/results panels and resize behavior remain in the UI module. | Passed: `tests/ReferenceCompatibility.Contract.Tests.ps1` and changed-file whitespace check. |
| V-RI-010 | IMP-RI-005 | forever | in-game | Open every board page and the Casino tab; check visible hierarchy, resizing, drag behavior, bounty controls, casino controls, scrolling and controller reachability. | not run |
| V-RI-011 | IMP-RI-006 | forever | static | Verify the EUI minimap module dependency, active-module detection, EUI-specific drag guidance and initial-only placement. | Passed: `tests/ReferenceCompatibility.Contract.Tests.ps1` and changed-file whitespace check. |
| V-RI-012 | IMP-RI-006 | forever | in-game | With EllesmereUIMinimap enabled, confirm the Ledger button is collected, opens both Ledger windows and can be Shift-dragged without resetting after `/reload`. | not run |
| V-RI-013 | IMP-RI-007 | forever | static | Verify profile serialization, native weekly reset, confirmed-kill increment, observed-PvP-death reset, life lifecycle, member data, crowned top-three class portraits, All time/Weekly toggles and table columns. | Passed: `tests/ReferenceCompatibility.Contract.Tests.ps1` and changed-file whitespace check. |
| V-RI-014 | IMP-RI-007 | forever | in-game | With two Ledger users, earn an honorable kill, die after targeting a hostile player, resurrect, and confirm synchronized streak/current life/longest life values. | not run |
| V-RI-015 | IMP-RI-008 | forever | static | Verify screen-bounded resizing, responsive navigation, reset entry points, version-prefix registration, delayed guild announcement and local update-notice logic. | Passed after the current change by `tests/ReferenceCompatibility.Contract.Tests.ps1` and changed-file whitespace check. |
| V-RI-016 | IMP-RI-008 | forever | in-game | Resize beyond the screen edge, use **Reset size** and `/lagom reset`, then log in a v1.7.1 client while a v1.7.2 client is online and confirm the profile-sync fallback; repeat with two v1.7.2 clients to confirm the dedicated prefix notice. | not run |
| V-RI-017 | IMP-RI-009 | forever | static | Verify debt discovery, protected-mail avoidance, payment serialization and casino-tab controls. | Passed: `tests/ReferenceCompatibility.Contract.Tests.ps1`. |
| V-RI-018 | IMP-RI-009 | forever | in-game | Lose a game, open a mailbox, prepare the next debt, verify recipient/subject/gold, send through Blizzard Mail, mark it paid and confirm another Ledger client receives the update. | not run |

## Resume checkpoint

- Repository / branch: local repository has no commits; remote is `helmersson/lagom-ledger` `main`.
- Working tree: untracked project files in this local initialization; remote `main` contains v1.6.0.
- Current slice: all implementation slices are complete; in-game acceptance remains.
- Next executable action: install v1.6.0 in WoW Forever and run V-RI-003 and V-RI-005 with one player using the supplied reference addon.
- Open questions / blockers: choose Witchcraft in-game or UIForever simulator; legacy exchange requires a second client with the reference addon.
- Read next: `requirements.md`, `README.md`, `tests/ReferenceCompatibility.Contract.Tests.ps1`, then `ReferenceCompatibility.lua`.
