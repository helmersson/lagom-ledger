# Glossary

Terms used in Lagom Ledger. The addon targets World of Warcraft Forever.

| Term | Meaning |
| --- | --- |
| **Guild database** | Saved data partition selected for the character's current guild and realm. It contains that guild's profiles, bounties and casino records. |
| **Profile** | A member's synchronized Ledger record: name, level, PvP counts, life data and professions. |
| **Addon message** | A message sent over WoW's addon communication channel. Ledger uses this for guild synchronization; it does not appear as ordinary guild chat. |
| **Reference Lagom** | The separately supplied Lagom addon. Ledger translates its `LagomGuild` messages into Ledger's existing records. |
| **Bounty** | A guild-posted request to hunt an Alliance character, optionally carrying a gold and silver reward. |
| **Settlement** | A recorded casino result or completed bounty debt between two members. |
| **Balance sheet** | Ledger's history of casino and bounty settlements, including recorded payments. |
| **Casino balance** | A member's recorded casino winnings and losses only; bounty settlements are excluded. |
| **Nemesis** | The most-recorded hostile PvP target for a member, based on the addon observations available in WoW Forever. |
| **Weekly leaderboard** | Kill and death totals since the server's latest weekly reset. |
