# Glossary

Terms used in Lagom Ledger. The addon targets World of Warcraft Forever.

| Term | Meaning |
| --- | --- |
| **Guild database** | Saved data partition selected for the character's current guild and realm. It contains that guild's profiles, bounties and casino records. |
| **Profile** | A member's synchronized Ledger record: name, level, PvP counts, life data and professions. |
| **Profession catalog** | A guild-shared list of recipes learned by members, searchable by recipe or crafted item, with required materials and guild crafters shown for a selected recipe when available. |
| **Addon message** | A message sent over WoW's addon communication channel. Ledger uses guild broadcasts and private addon whispers for manual recipe recovery; these are not ordinary chat messages. |
| **Reference Lagom** | The separately supplied Lagom addon. Ledger translates its `LagomGuild` messages into Ledger's existing records. |
| **Bounty** | A guild-posted request to hunt an Alliance character with a gold and silver reward. Imported legacy bounties may lack a reward. |
| **Settlement** | A recorded casino result or completed bounty debt between two members. |
| **Balance sheet** | Ledger's history of casino and bounty settlements, including recorded payments. |
| **Casino balance** | A member's recorded casino winnings and losses only; bounty settlements are excluded. |
| **Nemesis** | A hostile player recorded as the most frequent confirmed PvP killer of a member. An uncertain last-target hint may appear in a death notice but does not count as confirmed attribution. |
| **Weekly leaderboard** | Kill and death totals since the server's latest weekly reset. |
