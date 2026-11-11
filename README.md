# Lagom Ledger

**Lagom Ledger** is a guild addon for *World of Warcraft Forever*. It gives the **OG Lagom** guild a shared PvP leaderboard and a bounty board for Alliance players.

It is compatible with the supplied **Lagom** addon (v1.0.2): players can use either addon and share guild-board profiles and bounties. Lagom Ledger remains the single addon to install when casino, the minimap button and EllesmereUI integration are wanted.

Only guild members who have the addon installed can open the interface or receive its synchronized data.

When [EllesmereUI](https://github.com/EllesmereGaming/EllesmereUI) is installed, Lagom Ledger registers an **OG Lagom** section in its settings panel. This integration uses EllesmereUI's supported plugin API and does not change EllesmereUI's own files.

## Installation

1. Download or clone this project.
2. Copy the `LagomLedger` folder into the WoW Forever addon directory:

   ```text
   World of Warcraft\_forever_\Interface\AddOns\LagomLedger
   ```

3. Restart the game or run `/reload`.
4. Confirm that **Lagom Ledger** is enabled in the game's AddOns list.
5. Type `/lagom` in chat to open the board.

> The addon is restricted to the `OG Lagom` guild. Guild-name comparison ignores capitalization, but a guild rename still requires changing `LL.GUILD_NAME` in `LagomLedger/Core.lua`.

## Features

### PvP leaderboard

The leaderboard displays each addon user's:

- recorded Alliance kills
- recorded deaths
- known professions

The board follows the Lagom layout: dedicated **Kills**, **Deaths**, **Bounties**, and **Professions** tabs, a draggable framed window and mouse-wheel scrolling. Kills are updated from the character's honorable-kill lifetime counter; deaths use the client's total-death statistic and the local death event.

Lagom Ledger also keeps its draggable minimap button: left-click opens the guild board and right-click opens the casino. The casino remains available from the board's **Casino** button and `/lagom casino`.

### Bounty board

Enter an Alliance character name and an optional reason or reward. Online OG Lagom members with the addon receive the bounty through guild addon messages. When a user logs in, the addon automatically requests the active bounty list.

The board keeps manual completion: select a target and choose **Complete target**, or choose **Complete** on an active bounty row. The poster can choose **Remove**. When the addon sees a bounty target dead shortly after a new honorable-kill credit, it automatically completes matching bounties and announces nearby bounty targets once per minute.

### Synchronization

The addon sends data only through the guild addon channel. It uses no external servers, accounts, or databases. Profiles synchronize on login, when professions change and when **Sync my profile** is selected.

Lagom Ledger retains its own `LAGOMLEDGER` protocol for profiles, bounties and casino games. It also translates the reference addon's `LagomGuild` `S`, `B`, `H`, and `D` messages into the same `LagomLedgerDB` profiles and bounties. Casino messages are Ledger-only because the reference addon has no casino feature.

### Guild casino

The casino window runs guild games through the game's `/roll` system. It includes:

- **Classic** — everyone rolls `1–wager`; the highest roll wins the difference between the highest and lowest roll from the lowest roller. Ties are re-rolled by the tied players.
- **Death Roll** — exactly two players take turns rolling `1–current maximum`; a roll of `1` loses the wager.
- **Elimination** — three or more players roll `1–wager` each round; the lowest player is eliminated. The final two use Death Roll rules and the winner receives one wager from every other entrant.
- separate top-10 lists for the most gold won and lost
- a history of the five latest completed games

The host opens a lobby, guild members with the addon join it, and the host starts the selected game. Lagom Ledger records the outcome only. It cannot move gold between characters, so players must complete every settlement through a normal in-game trade.

### Update notices

At login, a member's profile includes the addon release number. When an online guild member has a newer release, an older client receives one whisper asking that player to update. The notice is sent at most once per player for each session.

## Commands

| Command | Action |
| --- | --- |
| `/lagom` | Open or close Lagom Ledger. |
| `/lagom kills`, `/lagom deaths`, `/lagom bounties`, `/lagom professions` | Open a specific reference-style guild-board tab. |
| `/lagom bounty Name reason` | Post a bounty from chat. |
| `/lagom death` | Manually add a death. |
| `/lagom complete ID` | Mark an active bounty as completed. Copy its ID from the board. |
| `/lagom casino` | Open the casino window. |
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
5. Complete the recorded gold settlements by trading with the winner manually.

Every entrant must have at least the wager available in their bags before they can host or join a game. The host can select **Close** to cancel an unfinished game.

## Important limitations

WoW Forever does not expose every ordinary combat-log event to addons. Lagom Ledger reads the client-reported honorable-kill total, but it cannot identify the player killed, the killer, or the zone. Automatic bounty completion is therefore a **best-effort** match: a tracked enemy bounty target must be observed dead shortly after a new honorable-kill credit. Use the manual bounty actions when that evidence is unavailable.

Following the reference addon behavior, `PLAYER_DEAD` increases the local character's death total and synchronizes the updated profile to guild members with the addon. This includes deaths outside PvP. It does not send a separate death-chat message, because WoW Forever does not expose a reliable killer API. Use `/lagom death` only for additions or corrections, so that a death is not recorded twice.

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

For example, after changing both release version fields to `1.6.1`:

```text
git tag -a v1.6.1 -m "Lagom Ledger 1.6.1"
git push origin v1.6.1
```

No personal access token is required for GitHub Releases; the workflow uses its scoped `GITHUB_TOKEN`. See [the release-pipeline note](docs/plans/release-pipeline.md) for the full behavior.

