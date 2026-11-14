# Graph Report - wow addon  (2026-11-14)

## Corpus Check
- 13 files · ~33,815 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 6 file(s) not represented in the graph (top: (none) 4, .toml 2)

## Summary
- 281 nodes · 658 edges · 16 communities (13 shown, 3 thin omitted)
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `6dff4310`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- ReferenceCompatibility.lua
- release
- CasinoGames.lua
- UI.lua
- Core.lua
- Casino.lua
- Balance.lua
- delete-merged-branch.yml
- now
- Ellesmere.lua
- LL:Broadcast
- LL:ResolveProfessionIdentity
- LL:OnVersionMessage

## God Nodes (most connected - your core abstractions)
1. `now()` - 24 edges
2. `LL:OnComm()` - 24 edges
3. `LL:PlayerName()` - 18 edges
4. `LL:Broadcast()` - 15 edges
5. `LL:OnEvent()` - 15 edges
6. `LL:Print()` - 11 edges
7. `LL:ResolveProfessionIdentity()` - 10 edges
8. `LL:RefreshLocalProfile()` - 10 edges
9. `LL:SendLegacyBounty()` - 10 edges
10. `LL:GetGroupCasinoGame()` - 10 edges

## Surprising Connections (you probably didn't know these)
- `LL:AddBounty()` --calls--> `now()`  [EXTRACTED]
  LagomLedger/Core.lua → LagomLedger/Core.lua  _Bridges community 9 → community 13_
- `LL:ApplyBountyDebtPayment()` --calls--> `now()`  [EXTRACTED]
  LagomLedger/Core.lua → LagomLedger/Core.lua  _Bridges community 9 → community 15_
- `LL:ReceiveProfessionChunk()` --calls--> `now()`  [EXTRACTED]
  LagomLedger/Core.lua → LagomLedger/Core.lua  _Bridges community 9 → community 14_
- `LL:Serialize()` --calls--> `now()`  [EXTRACTED]
  LagomLedger/Core.lua → LagomLedger/Core.lua  _Bridges community 9 → community 4_
- `LL:OnVersionMessage()` --calls--> `LL:PlayerIdentityKey()`  [EXTRACTED]
  LagomLedger/Core.lua → LagomLedger/Core.lua  _Bridges community 4 → community 15_

## Import Cycles
- None detected.

## Communities (16 total, 3 thin omitted)

### Community 0 - "ReferenceCompatibility.lua"
Cohesion: 0.09
Nodes (39): clean(), fold(), isSecret(), lifetimeDeaths(), lifetimeKills(), LL:AddBounty(), LL:AlertReferenceBounty(), LL:CheckReferenceKills() (+31 more)

### Community 1 - "release"
Cohesion: 0.07
Nodes (31): GH_API_TOKEN, jobs, release, validate, name, on, pull_request, push (+23 more)

### Community 2 - "CasinoGames.lua"
Cohesion: 0.22
Nodes (27): LL:AllGroupRollsReceived(), LL:ApplyCasinoGameResult(), LL:ApplyCasinoSettlement(), LL:CloseCasinoGame(), LL:FindGroupPlayer(), LL:FinishCasinoGame(), LL:GetCasinoGameMode(), LL:GetGroupCasinoGame() (+19 more)

### Community 3 - "UI.lua"
Cohesion: 0.18
Nodes (19): ago(), LL:BuildBalanceUI(), LL:BuildCasinoUI(), LL:BuildMinimapButton(), LL:BuildUI(), LL:RefreshBalanceUI(), LL:RefreshUI(), LL:ResetBoardSize() (+11 more)

### Community 4 - "Core.lua"
Cohesion: 0.17
Nodes (18): LL:AnnouncePvpKill(), LL:Decode(), LL:EnsureDatabase(), LL:Escape(), LL:GetDeathRecapKiller(), LL:GetGuildName(), LL:InitializeGuildDatabase(), LL:MergeDuplicatePlayers() (+10 more)

### Community 5 - "Casino.lua"
Cohesion: 0.21
Nodes (17): LL:ApplyCasinoDebtPayment(), LL:BroadcastCasinoStat(), LL:CasinoSettlementKey(), LL:DebtKey(), LL:GetCasinoDebts(), LL:GetCasinoStats(), LL:GetNextCasinoDebt(), LL:HandleRollMessage() (+9 more)

### Community 6 - "Balance.lua"
Cohesion: 0.31
Nodes (10): LL:BalanceTransactionKey(), LL:EnsureWeeklyStats(), LL:GetBalanceGraph(), LL:GetBalanceSummary(), LL:GetBalanceTransactions(), LL:GetDailyResetStart(), LL:GetWeeklyResetStart(), LL:MarkBalanceTransactionPaid() (+2 more)

### Community 8 - "delete-merged-branch.yml"
Cohesion: 0.11
Nodes (17): if, runs-on, steps, BRANCH, GITHUB_TOKEN, jobs, delete-branch, name (+9 more)

### Community 9 - "now"
Cohesion: 0.30
Nodes (15): LL:AnnounceLevelUp(), LL:CancelProfessionScan(), LL:EnsureLocalLife(), LL:EnsurePlayer(), LL:GetProfessions(), LL:NotePvpCombat(), LL:OnEvent(), LL:PlayerName() (+7 more)

### Community 10 - "Ellesmere.lua"
Cohesion: 0.39
Nodes (7): AddButton(), AddText(), LL:HasEllesmereUI(), LL:IsAtrocityMinimapActive(), LL:OpenEllesmereSettings(), LL:RegisterEllesmerePlugin(), LL:UseAtrocityMinimapButton()

### Community 13 - "LL:Broadcast"
Cohesion: 0.23
Nodes (13): LL:AddBounty(), LL:AnnouncePvpDeath(), LL:BountyTargetMatches(), LL:Broadcast(), LL:CompleteBountiesForTarget(), LL:CompleteBounty(), LL:CompleteSelectedBounties(), LL:IsLagomMember() (+5 more)

### Community 14 - "LL:ResolveProfessionIdentity"
Cohesion: 0.23
Nodes (17): LL:FullPlayerIdentityKey(), LL:GetGuildKey(), LL:MergeProfessionCatalogAliases(), LL:ProfessionIdentityMatches(), LL:ReceiveProfessionChunk(), LL:ReceiveProfessionMaterialsChunk(), LL:RefreshProfessionIdentityIndex(), LL:ReplayProfessionCatalogs() (+9 more)

### Community 15 - "LL:OnVersionMessage"
Cohesion: 0.31
Nodes (13): LL:ApplyBountyDebtPayment(), LL:ApplyBountySettlement(), LL:CheckSavedRelease(), LL:CompareRelease(), LL:CreateBountySettlement(), LL:GuildIdentityMatches(), LL:IsNewerRelease(), LL:IsOlderRelease() (+5 more)

## Knowledge Gaps
- **3 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Should `ReferenceCompatibility.lua` be split into smaller, more focused modules?**
  _Cohesion score 0.09433962264150944 - nodes in this community are weakly interconnected._
- **Should `release` be split into smaller, more focused modules?**
  _Cohesion score 0.07258064516129033 - nodes in this community are weakly interconnected._
- **Should `delete-merged-branch.yml` be split into smaller, more focused modules?**
  _Cohesion score 0.1111111111111111 - nodes in this community are weakly interconnected._