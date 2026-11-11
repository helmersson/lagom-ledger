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

## Validation evidence

| ID | REQ IDs / slice | Target | Mode | Procedure and expected result | Status |
| --- | --- | --- | --- | --- | --- |
| V-RI-001 | IMP-RI-001 | forever | static | Search all event registrations; no forbidden combat-log event is present. | Passed: `ReferenceCompatibility.Contract.Tests.ps1` asserts no forbidden event and the compatibility adapter registers only reference events. |
| V-RI-002 | IMP-RI-001 | forever | static | Inspect `LagomGuild` parsing/serialization against the supplied `Lagom/Core.lua`. | Passed: static contract verifies the `LagomGuild` prefix and exact `S`/`B` field formats; adapter implements `H` and `D`. |
| V-RI-003 | IMP-RI-001 | forever | in-game | Ledger and reference clients exchange stats and bounties. | not run |
| V-RI-004 | IMP-RI-002 | forever | static | Verify four tabs and retained Ledger entry points. | Passed: static contract verifies four board tabs, casino and minimap entry points. |
| V-RI-005 | IMP-RI-002 | forever | in-game | Open each tab, scroll, post/remove/complete a bounty, open casino and use minimap button. | not run |
| V-RI-006 | IMP-RI-003 | forever | static | TOC/file order/version and whitespace check. | Passed: PowerShell contract test and `git diff --no-index --check` completed without errors. |

## Resume checkpoint

- Repository / branch: local repository has no commits; remote is `helmersson/lagom-ledger` `main`.
- Working tree: untracked project files in this local initialization; remote contains v1.5.3.
- Current slice: all implementation slices are complete; in-game acceptance remains.
- Next executable action: install v1.6.0 in WoW Forever and run V-RI-003 and V-RI-005 with one player using the supplied reference addon.
- Open questions / blockers: choose Witchcraft in-game or UIForever simulator; legacy exchange requires a second client with the reference addon.
- Read next: `requirements.md`, `README.md`, `tests/ReferenceCompatibility.Contract.Tests.ps1`, then `ReferenceCompatibility.lua`.

