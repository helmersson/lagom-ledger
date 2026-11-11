# Changelog

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
