# Lagom Ledger

**Lagom Ledger** is a guild addon for *World of Warcraft Forever*. It gives the **OG lagom** guild a shared PvP leaderboard and a bounty board for Alliance players.

Only guild members who have the addon installed can open the interface or receive its synchronized data.

When [EllesmereUI](https://github.com/EllesmereGaming/EllesmereUI) is installed, Lagom Ledger registers an **OG lagom** section in its settings panel. This integration uses EllesmereUI's supported plugin API and does not change EllesmereUI's own files.

## Installation

1. Download or clone this project.
2. Copy the `LagomLedger` folder into the WoW Forever addon directory:

   ```text
   World of Warcraft\_forever_\Interface\AddOns\LagomLedger
   ```

3. Restart the game or run `/reload`.
4. Confirm that **Lagom Ledger** is enabled in the game's AddOns list.
5. Type `/lagom` in chat to open the board.

> The addon is restricted to a guild whose exact name is `OG lagom`. If the guild is renamed, change `LL.GUILD_NAME` in `LagomLedger/Core.lua`.

## Features

### PvP leaderboard

The leaderboard displays each addon user's:

- recorded Alliance kills
- recorded deaths
- known professions

Members are ranked by Alliance kills, then by fewer deaths when kills are tied.

### Bounty board

Enter an Alliance character name and an optional reason or reward. Online OG lagom members with the addon receive the bounty through guild addon messages. When a user logs in, the addon automatically requests the active bounty list.

### Synchronization

The addon sends data only through the guild addon channel. It uses no external servers, accounts, or databases. Profiles synchronize on login, when professions change, and when **Sync my profile** is selected.

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
| `/lagom kill Name-Realm` | Record an Alliance kill when the target can no longer be selected. |
| `/lagom death` | Manually add a death. |
| `/lagom complete ID` | Mark an active bounty as completed. Copy its ID from the board. |
| `/lagom casino` | Open the casino window. |
| `/lagom settings` | Open the Lagom Ledger section in EllesmereUI, when EllesmereUI is installed. |
| `/lagom sync` | Send your profile and professions to other addon users in the guild. |
| `/lagom help` | Show a short command list in chat. |

## Recording a kill

1. Select an Alliance player.
2. Open `/lagom`.
3. Select **Record selected Alliance kill**.

The button checks that your selected target is Alliance before recording the kill. If the target is no longer available, use `/lagom kill Name-Realm` instead.

## Playing a casino game

1. Open `/lagom casino`.
2. Enter a whole-number wager in gold, choose **Classic**, **Death Roll** or **Elimination**, then select **Open lobby**.
3. Other guild members with Lagom Ledger select **Join**. The host selects **Start** after the player requirement is met.
4. Use the game window's **Roll** button, or type the displayed native `/roll 1–maximum` command manually when it is your turn or the round requires your roll.
5. Complete the recorded gold settlements by trading with the winner manually.

Every entrant must have at least the wager available in their bags before they can host or join a game. The host can select **Close** to cancel an unfinished game.

## Important limitations

WoW Forever currently does not send ordinary combat-log events to addons. Lagom Ledger therefore **cannot automatically verify or count PvP kills**. Alliance kills must be recorded using the button or command above.

The addon automatically records the local character's `PLAYER_DEAD` event. This also includes deaths outside PvP. Use `/lagom death` only for additions or corrections, so that a death is not recorded twice.

Guild addon messages are not a secure anti-cheat system. Treat the leaderboard as a shared guild honor board, not as authoritative statistics from the game server.

## Development

- Target client: *World of Warcraft Forever*
- Addon interface: `16001`
- Main code: `LagomLedger/Core.lua`
- Interface: `LagomLedger/UI.lua`

After making changes, run `/reload`, open `/lagom`, and test synchronization with at least one other guild member who also has the addon installed.

