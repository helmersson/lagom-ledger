# Lagom Ledger

**Lagom Ledger** is a guild addon for *World of Warcraft Forever*. It gives each guild shared PvP leaderboards, a learned-recipe catalog, an Alliance bounty board, casino games and a balance sheet.

It is compatible with the supplied **Lagom** addon (v1.0.2): players can use either addon and share guild-board profiles and bounties. Lagom Ledger remains the single addon to install when casino, the minimap button and EllesmereUI integration are wanted.

Only guild members who have the addon installed can open the interface or receive its synchronized data.

When [EllesmereUI](https://github.com/EllesmereGaming/EllesmereUI) is installed, Lagom Ledger registers a section in its settings panel. This integration uses EllesmereUI's supported plugin API and does not change EllesmereUI's own files. With EllesmereUIMinimap enabled, its standard minimap-button collector manages the Ledger button; use EllesmereUI's grouping controls and Shift-drag instead of Ledger's standalone drag. When AtrocityEssentials' Minimap module is active, Ledger registers the same actions through LibDBIcon so its addon-button flyout or row manages the Ledger button.

## Installation

1. Download the latest `LagomLedger.zip` from the project's GitHub Releases page.
2. Copy the `LagomLedger` folder into the WoW Forever addon directory:

   ```text
   World of Warcraft\_forever_\Interface\AddOns\LagomLedger
   ```

3. Restart the game or run `/reload`.
4. Confirm that **Lagom Ledger** is enabled in the game's AddOns list.
5. Type `/lagom` in chat to open the board.

> At login, `LL.GUILD_NAME` is set from the character's current guild. Saved data is partitioned by guild name and realm, so guilds do not share leaderboards, bounties, casino results or minimap positions. Existing v1.6.0 data is migrated to the guild used on the first login after updating.

## Features

### PvP leaderboard

The leaderboard displays each addon user's:

- recorded Alliance kills
- current honorable-kill streak
- most-recorded PvP kill target (**Nemesis**) on the Kills tab
- recorded deaths, current life duration and longest completed life

The **Kills** and **Deaths** tabs each add a centered top-three strip with the members' recorded class portraits.

Both PvP tabs include an **All time / Weekly** toggle. Weekly kills and deaths reset at the WoW server's weekly reset (Wednesday maintenance on this realm) and begin tracking when a member first uses this addon version.

The board follows the Lagom layout: dedicated **Kills**, **Deaths**, **Bounties**, **Professions**, **Casino**, and **Balance sheet** tabs, a draggable framed window and mouse-wheel scrolling. Kills are updated from the character's honorable-kill lifetime counter; deaths use the client's total-death statistic and the local death event.

The **Professions** tab has a profession list, searchable recipe list and a panel showing who can craft a selected recipe. When available, recipe details also show the required materials for one craft: each row gives the required quantity, and alternative items are separated by **or**. Optional and hidden materials are omitted. Item IDs may appear temporarily while item names load. First Aid, Mining, Skinning, Herbalism and Fishing are intentionally omitted. Recipe catalogs include only learned recipes that guild members have shared.

Lagom Ledger also keeps its draggable minimap button: left-click opens the guild board and right-click opens the **Casino** tab. The casino shares the guild-board window and is also available from its navigation tab and `/lagom casino`. Drag the lower-right corner of the main window to resize it; the guild table, navigation buttons and casino leaderboard panels expand with the available space. The window is bounded by the current screen; select **Reset size** or run `/lagom reset` to restore the default size and centered position.

### Bounty board

Enter an Alliance character name and a required **reward** as `gold.silver`, for example `12.34` for 12 gold and 34 silver. Online members of the current guild with the addon receive the bounty through guild addon messages. When a user logs in, the addon automatically requests the active bounty list.

The board keeps manual completion: select a target and choose **Complete target**, or choose **Complete** on an active bounty row. The poster can choose **Remove**. When a bounty is claimed, its poster receives a matching outstanding debt to the claimant in **Balance sheet**, ready to prepare as a Blizzard mail. When an active bounty target appears on a visible enemy nameplate, addon users receive an internal guild-addon notice with the target's zone and subzone. This only works while the client exposes the player on a nameplate; hidden, distant, or otherwise unavailable players cannot be detected. Sightings are rate-limited. When the addon sees a bounty target dead shortly after a new honorable-kill credit, it automatically completes matching bounties.

### Synchronization

The addon uses hidden WoW addon messages and no external servers, accounts, or databases. Profiles synchronize on login and when `/lagom sync` is used. Learned recipes and available material data are captured when a member opens their own profession; material data is sent separately from the recipe catalog. `/lagom sync` can request already-saved recipe and material data from online guild members. The request uses the guild addon channel and catalog replies use private addon `WHISPER` messages; neither appears as normal chat. There is no login or periodic profession-data backfill. If a catalog was saved before material sharing was available, its owner must open that profession with the updated addon; recipients can then run `/lagom sync` while the owner is online. If the client cannot enumerate recipes, the owner gets a local scan diagnostic and existing catalog data is kept. When a member levels up, addon users receive a local `Name reached level X!` notification; nothing is sent to normal guild chat.

Lagom Ledger retains its own `LAGOMLEDGER` protocol for profiles, bounties, professions and casino games. It imports the reference addon's `LagomGuild` `S`, `B` and `H` messages into the same guild-specific `LagomLedgerDB` profiles and bounties. Ledger sends `D` as a snapshot-complete marker for the reference addon; it does not import incoming `D` messages. Casino messages are Ledger-only because the reference addon has no casino feature.

### Guild casino

The casino window runs guild games through the game's `/roll` system. It includes:

- **Classic** — everyone rolls `1–wager`; the highest roll wins the difference between the highest and lowest roll from the lowest roller. Ties are re-rolled by the tied players.
- **Death Roll** — exactly two players take turns rolling `1–current maximum`; a roll of `1` loses the wager.
- **Elimination** — three or more players roll `1–wager` each round; the lowest player is eliminated. The final two use Death Roll rules and the winner receives one wager from every other entrant.
- separate top-10 lists for the most gold won and lost
- a personal balance showing recorded gold won, lost and net result
- a history of the five latest completed games

The host opens a lobby, guild members with the addon join it, and the host starts the selected game. The casino balance is casino-only; bounty rewards do not change its won/lost lists.

Casino totals retain each updated client's saved pre-upgrade totals as a baseline and count new versioned settlements once by settlement ID. To avoid double-counting ambiguous old cumulative snapshots and settlement replays, updated clients ignore unversioned casino-stat and settlement messages from older addon versions. For consistent totals, all guild members need the updated addon; existing local totals are preserved during migration.

### Balance sheet

**Balance sheet** records the current character's casino settlements and claimed bounty rewards. It shows gold won, gold lost and net change through the addon, plus a twelve-bar net-gold graph and a transaction list. Choose **Daily**, **Weekly**, or **Lifetime**: daily begins at midnight server time, weekly begins at the server's weekly reset, and lifetime retains every recorded transaction.

Outstanding casino and bounty debts are paid from this tab. At a mailbox, select **Prepare mail** to fill in the recipient, subject and exact gold/silver amount, use Blizzard's **Send** button, then select **Mark paid**. Lagom Ledger never sends mail automatically.

### Update notices

At login, v1.7.2 and later announce their release on the internal `LagomLedgerVer` guild-addon prefix. A newer release gives the receiving client one local chat notice and is remembered for three days, so it is shown again after a later login. Older Ledger installations still receive the existing profile-sync notice when compatible; very old Lagom installs cannot understand the new version prefix. Update notices do not use normal chat; profession recovery uses hidden addon whispers as described above.

## Commands

| Command | Action |
| --- | --- |
| `/lagom` | Open or close Lagom Ledger. |
| `/lagom kills`, `/lagom deaths`, `/lagom bounties`, `/lagom professions` | Open a specific reference-style guild-board tab. |
| `/lagom bounty Name 12.34` | Post a bounty with a 12 gold, 34 silver reward. |
| `/lagom death` | Manually add a death. |
| `/lagom complete ID` | Mark an active bounty as completed. Copy its ID from the board. |
| `/lagom casino` | Open the Casino tab. |
| `/lagom balance` | Open the Balance sheet tab. |
| `/lagom reset` | Restore the main window's default size and centered position. |
| `/lagom settings` | Open the Lagom Ledger section in EllesmereUI, when EllesmereUI is installed. |
| `/lagom sync` | Send your profile and request saved profession catalogs from online addon users in the guild. |
| `/lagom debug` | Show the guild, lifetime-stat, and local profession-sync counters. |
| `/lagom help` | Show a short command list in chat. |
| `/lagomledger` | Alias for Lagom Ledger when the reference addon also claims `/lagom`. |

## Playing a casino game

1. Open `/lagom casino`.
2. Enter a whole-number wager in gold, choose **Classic**, **Death Roll** or **Elimination**, then select **Open lobby**.
3. Other guild members with Lagom Ledger select **Join**. The host selects **Start** after the player requirement is met.
4. Use the game window's **Roll** button, or type the displayed native `/roll 1–maximum` command manually when it is your turn or the round requires your roll.
5. Open **Balance sheet** at a mailbox to settle the next casino or bounty debt: select **Prepare mail**, review and use Blizzard's **Send** button, then select **Mark paid** so the next outstanding debt is shown.

Every entrant must have at least the wager available in their bags before they can host or join a game. The host can select **Close** to cancel an unfinished game.

## Important limitations

WoW Forever does not expose every ordinary combat-log event to addons. Lagom Ledger reads the client-reported honorable-kill total, but it cannot reliably identify the player killed, the killer, or the zone of a kill. Bounty sightings are separate: they use visible enemy nameplates and report the current zone and subzone when a listed target is seen. Automatic bounty completion is a **best-effort** match: a tracked enemy bounty target must be observed dead shortly after a new honorable-kill credit. Use the manual bounty actions when that evidence is unavailable.

Following the reference addon behavior, `PLAYER_DEAD` increases the local character's death total and synchronizes the updated profile to guild members with the addon. This includes deaths outside PvP. The addon records the current life from the last observed death or resurrection and preserves the longest completed life. An honorable-kill streak increases from the client's lifetime honorable-kill counter and resets only after a best-effort observed PvP death: the local client must have recently entered combat while targeting a hostile player. On such a death, addon users receive an internal PvP-death notice. A target inferred only from recent combat may appear as uncertain in that notice, but only confirmed Death Recap attribution contributes to the nemesis leaderboard. Honorable-kill credits may record an observed hostile target on the Kills page. WoW Forever does not expose a reliable victim/killer API, so named killers and victims are not always verified attribution, and unobserved PvP deaths cannot safely reset a streak. Use `/lagom death` only for additions or corrections, so that a death is not recorded twice.

Guild addon messages are not a secure anti-cheat system. Treat the leaderboard as a shared guild honor board, not as authoritative statistics from the game server.
