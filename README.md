# Lagom Ledger

**Lagom Ledger** is a guild addon for *World of Warcraft Forever*. It gives each guild a shared PvP leaderboard and a bounty board for Alliance players.

It is compatible with the supplied **Lagom** addon (v1.0.2): players can use either addon and share guild-board profiles and bounties. Lagom Ledger remains the single addon to install when casino, the minimap button and EllesmereUI integration are wanted.

Only guild members who have the addon installed can open the interface or receive its synchronized data.

When [EllesmereUI](https://github.com/EllesmereGaming/EllesmereUI) is installed, Lagom Ledger registers a section in its settings panel. This integration uses EllesmereUI's supported plugin API and does not change EllesmereUI's own files. With EllesmereUIMinimap enabled, its standard minimap-button collector manages the Ledger button; use EllesmereUI's grouping controls and Shift-drag instead of Ledger's standalone drag. When AtrocityEssentials' Minimap module is active, Ledger registers the same actions through LibDBIcon so its addon-button flyout or row manages the Ledger button.

## Installation

1. Download or clone this project.
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
- recorded deaths, current life duration and longest completed life
- known professions

The **Kills** and **Deaths** tabs each add a centered top-three strip with the members' recorded class portraits.

Both PvP tabs include an **All time / Weekly** toggle. Weekly kills and deaths reset at the WoW server's weekly reset (Wednesday maintenance on this realm) and begin tracking when a member first uses this addon version.

The board follows the Lagom layout: dedicated **Kills**, **Deaths**, **Bounties**, and **Professions** tabs, a draggable framed window and mouse-wheel scrolling. Kills are updated from the character's honorable-kill lifetime counter; deaths use the client's total-death statistic and the local death event.

Lagom Ledger also keeps its draggable minimap button: left-click opens the guild board and right-click opens the **Casino** tab. The casino shares the guild-board window and is also available from its navigation tab and `/lagom casino`. Drag the lower-right corner of the main window to resize it; the guild table, navigation buttons and casino leaderboard panels expand with the available space. The window is bounded by the current screen; select **Reset size** or run `/lagom reset` to restore the default size and centered position.

### Bounty board

Enter an Alliance character name and an optional reason or reward. Online members of the current guild with the addon receive the bounty through guild addon messages. When a user logs in, the addon automatically requests the active bounty list.

The board keeps manual completion: select a target and choose **Complete target**, or choose **Complete** on an active bounty row. The poster can choose **Remove**. When the addon sees a bounty target dead shortly after a new honorable-kill credit, it automatically completes matching bounties and announces nearby bounty targets once per minute.

### Synchronization

The addon sends data only through the guild addon channel. It uses no external servers, accounts, or databases. Profiles synchronize on login, when professions change and when **Sync my profile** is selected. When a member levels up, addon users receive a local `Name reached level X!` notification; nothing is sent to normal guild chat.

Lagom Ledger retains its own `LAGOMLEDGER` protocol for profiles, bounties and casino games. It also translates the reference addon's `LagomGuild` `S`, `B`, `H`, and `D` messages into the same guild-specific `LagomLedgerDB` profiles and bounties. Casino messages are Ledger-only because the reference addon has no casino feature.

### Guild casino

The casino window runs guild games through the game's `/roll` system. It includes:

- **Classic** — everyone rolls `1–wager`; the highest roll wins the difference between the highest and lowest roll from the lowest roller. Ties are re-rolled by the tied players.
- **Death Roll** — exactly two players take turns rolling `1–current maximum`; a roll of `1` loses the wager.
- **Elimination** — three or more players roll `1–wager` each round; the lowest player is eliminated. The final two use Death Roll rules and the winner receives one wager from every other entrant.
- separate top-10 lists for the most gold won and lost
- a personal balance showing recorded gold won, lost and net result
- a history of the five latest completed games

The host opens a lobby, guild members with the addon join it, and the host starts the selected game. A loser can settle an outstanding debt at a mailbox: select **Prepare mail** to fill in the recipient, subject and gold, use Blizzard's **Send** button, then select **Mark paid**. Lagom Ledger never sends mail automatically.

### Update notices

At login, a member's profile includes the addon release number. During the initial synchronization window, a client with an older release displays a local chat message when it sees a newer release. Starting with v1.7.1, newer clients also send an internal `UPDATE_AVAILABLE` guild-addon message addressed to a detected older Ledger client; this message is understood by Ledger v1.7.1 and later. No normal chat whispers are sent. Legacy Lagom installs do not support this message and therefore do not receive update notices. Notices are sent at most once per member for each session.

## Commands

| Command | Action |
| --- | --- |
| `/lagom` | Open or close Lagom Ledger. |
| `/lagom kills`, `/lagom deaths`, `/lagom bounties`, `/lagom professions` | Open a specific reference-style guild-board tab. |
| `/lagom bounty Name reason` | Post a bounty from chat. |
| `/lagom death` | Manually add a death. |
| `/lagom complete ID` | Mark an active bounty as completed. Copy its ID from the board. |
| `/lagom casino` | Open the Casino tab. |
| `/lagom reset` | Restore the main window's default size and centered position. |
| `/lagom settings` | Open the Lagom Ledger section in EllesmereUI, when EllesmereUI is installed. |
| `/lagom sync` | Send your profile and professions to other addon users in the guild. |
| `/lagom debug` | Show the guild and lifetime-stat information reported by the client. |
| `/lagom help` | Show a short command list in chat. |
| `/lagomledger` | Alias for Lagom Ledger when the reference addon also claims `/lagom`. |

## Playing a casino game

1. Open `/lagom casino`.
2. Enter a whole-number wager in gold, choose **Classic**, **Death Roll** or **Elimination**, then select **Open lobby**.
3. Other guild members with Lagom Ledger select **Join**. The host selects **Start** after the player requirement is met.
4. Use the game window's **Roll** button, or type the displayed native `/roll 1–maximum` command manually when it is your turn or the round requires your roll.
5. At a mailbox, select **Prepare mail** to fill in the next debt, review it and use Blizzard's **Send** button. Then select **Mark paid** in Lagom Ledger so the next outstanding debt is shown.

Every entrant must have at least the wager available in their bags before they can host or join a game. The host can select **Close** to cancel an unfinished game.

## Important limitations

WoW Forever does not expose every ordinary combat-log event to addons. Lagom Ledger reads the client-reported honorable-kill total, but it cannot identify the player killed, the killer, or the zone. Automatic bounty completion is therefore a **best-effort** match: a tracked enemy bounty target must be observed dead shortly after a new honorable-kill credit. Use the manual bounty actions when that evidence is unavailable.

Following the reference addon behavior, `PLAYER_DEAD` increases the local character's death total and synchronizes the updated profile to guild members with the addon. This includes deaths outside PvP. The addon records the current life from the last observed death or resurrection and preserves the longest completed life. An honorable-kill streak increases from the client's lifetime honorable-kill counter and resets only after a best-effort observed PvP death: the local client must have recently entered combat while targeting a hostile player. On such a death, addon users receive an internal PvP-death notice and the last observed hostile target is counted as that member's nemesis; the Deaths page also aggregates those records into a guild nemesis. WoW Forever does not expose a reliable victim/killer API, so the named killer is a hint rather than verified attribution, and unobserved PvP deaths cannot safely reset a streak. Use `/lagom death` only for additions or corrections, so that a death is not recorded twice.

Guild addon messages are not a secure anti-cheat system. Treat the leaderboard as a shared guild honor board, not as authoritative statistics from the game server.

## Development

- Target client: *World of Warcraft Forever*
- Addon interface: `16001`
- Main code: `LagomLedger/Core.lua`
- Lagom compatibility: `LagomLedger/ReferenceCompatibility.lua`
- Interface: `LagomLedger/UI.lua`

After making changes, run `/reload`, open `/lagom`, and test synchronization with at least one other guild member who also has the addon installed.

## Releases

GitHub Actions validates every pull request and push to `main`. Pushing an annotated tag named `v<version>` runs [BigWigsMods/packager](https://github.com/BigWigsMods/packager), verifies that the tag matches `## Version` in `LagomLedger/LagomLedger.toc`, packages the Forever addon, and creates a GitHub Release with the ZIP file. The package contains only the installable `LagomLedger` folder.

For example, after changing both release version fields to `1.7.0`:

```text
git tag -a v1.7.0 -m "Lagom Ledger 1.7.0"
git push origin v1.7.0
```

No personal access token is required for GitHub Releases; the workflow uses its scoped `GITHUB_TOKEN`. See [the release-pipeline note](docs/plans/release-pipeline.md) for the full behavior.
