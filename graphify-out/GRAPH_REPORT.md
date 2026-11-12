# Graph Report - wow addon  (2026-11-12)

## Corpus Check
- 13 files · ~24,299 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 6 file(s) not represented in the graph (top: (none) 4, .toml 2)

## Summary
- 243 nodes · 561 edges · 11 communities (8 shown, 3 thin omitted)
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `123107ec`
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
- Ellesmere.lua

## God Nodes (most connected - your core abstractions)
1. `LL:OnComm()` - 21 edges
2. `now()` - 17 edges
3. `LL:PlayerName()` - 14 edges
4. `LL:Broadcast()` - 14 edges
5. `LL:OnEvent()` - 13 edges
6. `LL:PlayerIdentityKey()` - 12 edges
7. `LL:RefreshLocalProfile()` - 11 edges
8. `LL:SendLegacyBounty()` - 10 edges
9. `LL:BuildUI()` - 10 edges
10. `LL:OnVersionMessage()` - 9 edges

## Surprising Connections (you probably didn't know these)
- None detected - all connections are within the same source files.

## Import Cycles
- None detected.

## Communities (11 total, 3 thin omitted)

### Community 0 - "ReferenceCompatibility.lua"
Cohesion: 0.09
Nodes (40): clean(), fold(), isSecret(), lifetimeDeaths(), lifetimeKills(), LL:AddBounty(), LL:AlertReferenceBounty(), LL:CheckReferenceKills() (+32 more)

### Community 1 - "release"
Cohesion: 0.07
Nodes (31): GH_API_TOKEN, jobs, release, validate, name, on, pull_request, push (+23 more)

### Community 2 - "CasinoGames.lua"
Cohesion: 0.21
Nodes (26): LL:AllGroupRollsReceived(), LL:ApplyCasinoGameResult(), LL:ApplyCasinoSettlement(), LL:CloseCasinoGame(), LL:FindGroupPlayer(), LL:FinishCasinoGame(), LL:GetCasinoGameMode(), LL:GetGroupCasinoGame() (+18 more)

### Community 3 - "UI.lua"
Cohesion: 0.17
Nodes (20): ago(), LL:BuildBalanceUI(), LL:BuildCasinoUI(), LL:BuildMinimapButton(), LL:BuildUI(), LL:RefreshBalanceUI(), LL:RefreshCasinoUI(), LL:RefreshUI() (+12 more)

### Community 4 - "Core.lua"
Cohesion: 0.11
Nodes (56): LL:AddBounty(), LL:AnnounceLevelUp(), LL:AnnouncePvpDeath(), LL:AnnouncePvpKill(), LL:ApplyBountyDebtPayment(), LL:ApplyBountySettlement(), LL:BountyTargetMatches(), LL:Broadcast() (+48 more)

### Community 5 - "Casino.lua"
Cohesion: 0.22
Nodes (16): LL:ApplyCasinoDebtPayment(), LL:BroadcastCasinoStat(), LL:CasinoSettlementKey(), LL:DebtKey(), LL:GetCasinoDebts(), LL:GetCasinoStats(), LL:GetNextCasinoDebt(), LL:HandleRollMessage() (+8 more)

### Community 6 - "Balance.lua"
Cohesion: 0.31
Nodes (10): LL:BalanceTransactionKey(), LL:EnsureWeeklyStats(), LL:GetBalanceGraph(), LL:GetBalanceSummary(), LL:GetBalanceTransactions(), LL:GetDailyResetStart(), LL:GetWeeklyResetStart(), LL:MarkBalanceTransactionPaid() (+2 more)

### Community 10 - "Ellesmere.lua"
Cohesion: 0.39
Nodes (7): AddButton(), AddText(), LL:HasEllesmereUI(), LL:IsAtrocityMinimapActive(), LL:OpenEllesmereSettings(), LL:RegisterEllesmerePlugin(), LL:UseAtrocityMinimapButton()

## Knowledge Gaps
- **3 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Should `ReferenceCompatibility.lua` be split into smaller, more focused modules?**
  _Cohesion score 0.09224318658280922 - nodes in this community are weakly interconnected._
- **Should `release` be split into smaller, more focused modules?**
  _Cohesion score 0.07258064516129033 - nodes in this community are weakly interconnected._
- **Should `Core.lua` be split into smaller, more focused modules?**
  _Cohesion score 0.11312764670296431 - nodes in this community are weakly interconnected._