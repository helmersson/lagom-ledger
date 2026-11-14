# Changelog

## 1.7.3 - Release candidate

- Added required recipe materials, quantities and alternatives to Professions, with guild sharing alongside saved recipe catalogs.
- Prevented casino settlement replay double-counting, expired inactive game lobbies, and validated guild message senders; updated clients preserve existing totals but ignore ambiguous unversioned casino stats/settlements from older versions.
- Added collision-resistant bounty/game IDs, coalesced guild sync replies, and a compact profile fallback for oversized messages.
- Fixed profession synchronization identity matching for names with realm suffixes and guild members who share a first name.
- Prevented stale reference-addon bounty updates from restoring a completion timestamp on open or cancelled bounties.
- Avoided duplicate casino UI refreshes and guarded the main board while guild data is unavailable.
- Updated the user guide, addon metadata, integration notes and release workflow documentation to match current behavior.

## 1.7.2 - Release candidate

- Added a dedicated internal guild-addon version check after login, with delayed replies to avoid guild-message spam.
- Remembered a detected newer release for three days and retained profile-sync notices for compatible older Ledger installs.

## 1.7.0 - Release candidate

- Added centered top-three class portraits with gold, silver and bronze crowns to the Kills and Deaths leaderboards.
- Added All time and Weekly views for the Kills and Deaths leaderboards; weekly scores reset with the WoW server's weekly reset.
- Kept leaderboard table columns aligned while resizing the guild-journal window.
- Added a casino balance for recorded gold won, lost and net result.
- Added settlement through Blizzard Mail: prepare the next casino debt at a mailbox and explicitly mark it paid after sending.
- Added responsive window sizing, update notices at login, EllesmereUI minimap support, kill streaks and life-duration tracking.

## Release notes

Lagom Ledger 1.7.0 targets World of Warcraft Forever (`Interface: 16001`). The release package contains only the `LagomLedger` addon folder. Casino mail is always sent through the player's Blizzard Mail confirmation; the addon does not send mail automatically.
