local _, LL = ...

LL.CASINO_GAME_MODES = {
    { key = "Classic", label = "Classic", minPlayers = 2, description = "Highest roll wins the difference between the highest and lowest rolls." },
    { key = "DeathRoll", label = "Death Roll", minPlayers = 2, maxPlayers = 2, description = "Take turns rolling 1 to the last roll. Rolling 1 loses." },
    { key = "Elimination", label = "Elimination", minPlayers = 3, description = "Lowest roll is eliminated each round; the last two play Death Roll." },
}

function LL:GetCasinoGameMode(key)
    for _, mode in ipairs(self.CASINO_GAME_MODES) do if mode.key == key then return mode end end
end

function LL:GetGroupCasinoGame()
    return self.db.casinoGroupGame
end

function LL:IsGroupCasinoHost(game)
    return game and self:NamesMatch(game.host, self:PlayerName())
end

function LL:FindGroupPlayer(game, name)
    for _, player in ipairs(game.players or {}) do
        if self:NamesMatch(player, name) then return player end
    end
end

function LL:GroupPlayerSet(game, names)
    local set = {}
    for _, name in ipairs(names or game.players) do set[name] = true end
    return set
end

function LL:GroupAlivePlayers(game)
    local players = {}
    for _, name in ipairs(game.players) do if game.alive[name] then table.insert(players, name) end end
    return players
end

function LL:OpenCasinoGame(modeKey, wager)
    local mode = self:GetCasinoGameMode(modeKey)
    wager = tonumber(wager)
    if not mode or not wager or wager < 1 or wager > self.CASINO_MAX_WAGER or wager ~= math.floor(wager) then
        self:Print("Choose a mode and a whole-number wager between 1 and " .. self.CASINO_MAX_WAGER .. " gold.")
        return false
    end
    if self.db.casinoGroupGame then
        self:Print("A guild casino game is already open. Join it, or wait for the host to finish it.")
        return false
    end
    if not self:HasGoldForCasino(wager) then return false end
    local id = self:PlayerName() .. "-game-" .. self.db.nextCasinoId
    self.db.nextCasinoId = self.db.nextCasinoId + 1
    local game = { id = id, host = self:PlayerName(), mode = mode.key, wager = wager, createdAt = time(), status = "lobby", players = { self:PlayerName() }, playerSet = { [self:PlayerName()] = true } }
    self.db.casinoGroupGame = game
    self:Broadcast("CASINO_GAME_OPEN", game)
    self:Print(mode.label .. " lobby opened for " .. wager .. " gold. Guild members with the addon can join from /lagom casino.")
    self:RefreshUI()
    return true
end

function LL:JoinCasinoGame()
    local game = self:GetGroupCasinoGame()
    if not game or game.status ~= "lobby" then self:Print("There is no open guild casino lobby."); return false end
    local mode = self:GetCasinoGameMode(game.mode)
    if game.playerSet[self:PlayerName()] then self:Print("You are already in this casino game."); return false end
    if mode.maxPlayers and #game.players >= mode.maxPlayers then self:Print("This mode already has its maximum number of players."); return false end
    if not self:HasGoldForCasino(game.wager) then return false end
    table.insert(game.players, self:PlayerName())
    game.playerSet[self:PlayerName()] = true
    self:Broadcast("CASINO_GAME_JOIN", { id = game.id, player = self:PlayerName() })
    self:RefreshUI()
    return true
end

function LL:CloseCasinoGame()
    local game = self:GetGroupCasinoGame()
    if not game or not self:IsGroupCasinoHost(game) then self:Print("Only the host can close the current casino game."); return false end
    self.db.casinoGroupGame = nil
    self:Broadcast("CASINO_GAME_CLOSE", { id = game.id })
    self:RefreshUI()
    return true
end

function LL:SetCasinoGameState(game, phase, minRoll, maxRoll, turn, message)
    game.status, game.phase = "running", phase
    game.minRoll, game.maxRoll, game.turn, game.message = minRoll or 0, maxRoll or 0, turn or "", message or ""
    self:Broadcast("CASINO_GAME_STATE", { id = game.id, phase = game.phase, minRoll = game.minRoll, maxRoll = game.maxRoll, turn = game.turn, message = game.message })
    self:RefreshUI()
end

function LL:StartCasinoGame()
    local game = self:GetGroupCasinoGame()
    if not game or not self:IsGroupCasinoHost(game) or game.status ~= "lobby" then self:Print("Only the host can start an open casino lobby."); return false end
    local mode = self:GetCasinoGameMode(game.mode)
    if #game.players < mode.minPlayers then self:Print("This mode needs at least " .. mode.minPlayers .. " players."); return false end
    if mode.maxPlayers and #game.players ~= mode.maxPlayers then self:Print("This mode needs exactly " .. mode.maxPlayers .. " players."); return false end
    if mode.key == "Classic" then
        self:StartGroupRollRound(game, "classic", 1, game.wager, self:GroupPlayerSet(game), "Everyone roll now.")
    elseif mode.key == "DeathRoll" then
        game.deathMax, game.turnIndex = game.wager, 1
        self:SetCasinoGameState(game, "deathroll", 1, game.deathMax, game.players[1], game.players[1] .. " rolls first.")
    elseif mode.key == "Elimination" then
        game.alive, game.eliminated, game.round = self:GroupPlayerSet(game), {}, 0
        self:StartEliminationRound(game)
    end
    return true
end

function LL:StartGroupRollRound(game, phase, minRoll, maxRoll, pending, message)
    game.rolls, game.pending, game.tie = {}, pending, nil
    self:SetCasinoGameState(game, phase, minRoll, maxRoll, "", message)
end

function LL:GetGroupExtremes(game, wantHigh)
    local value, names
    for name in pairs(game.pending) do
        local roll = game.rolls[name]
        if roll then
            if not value or (wantHigh and roll > value) or (not wantHigh and roll < value) then value, names = roll, { name }
            elseif roll == value then table.insert(names, name) end
        end
    end
    return value, names or {}
end

function LL:AllGroupRollsReceived(game)
    for name in pairs(game.pending or {}) do if not game.rolls[name] then return false end end
    return true
end

function LL:StartClassicTie(game, kind, names)
    game.tie = { kind = kind, names = names }
    self:StartGroupRollRound(game, game.phase, 1, game.maxRoll, self:GroupPlayerSet(game, names), "Tie for " .. kind .. " roll — only tied players roll again.")
    game.tie = { kind = kind, names = names }
end

function LL:ResolveClassicGame(game)
    local highValue, highNames = self:GetGroupExtremes(game, true)
    local lowValue, lowNames = self:GetGroupExtremes(game, false)
    if not game.tie and highValue == lowValue then
        self:FinishCasinoGame(game, "Everyone rolled " .. highValue .. ". No gold changes hands.", {})
        return
    end
    if game.tie then
        local chosenNames = game.tie.kind == "high" and highNames or lowNames
        if #chosenNames > 1 then self:StartClassicTie(game, game.tie.kind, chosenNames); return end
        if game.tie.kind == "high" then game.classicWinner = chosenNames[1] else game.classicLoser = chosenNames[1] end
        game.tie = nil
        if not game.classicWinner then self:StartClassicTie(game, "high", game.originalHighNames); return end
        if not game.classicLoser then self:StartClassicTie(game, "low", game.originalLowNames); return end
    else
        game.originalHighNames, game.originalLowNames, game.originalHighValue, game.originalLowValue = highNames, lowNames, highValue, lowValue
        if #highNames > 1 then self:StartClassicTie(game, "high", highNames); return end
        game.classicWinner = highNames[1]
        if #lowNames > 1 then self:StartClassicTie(game, "low", lowNames); return end
        game.classicLoser = lowNames[1]
    end
    local amount = math.max(0, game.originalHighValue - game.originalLowValue)
    self:FinishCasinoGame(game, "Highest roll: " .. game.classicWinner .. ".", { { winner = game.classicWinner, loser = game.classicLoser, amount = amount } })
end

function LL:StartEliminationRound(game)
    game.round = game.round + 1
    self:StartGroupRollRound(game, "elimination", 1, game.wager, self:GroupPlayerSet(game, self:GroupAlivePlayers(game)), "Elimination round " .. game.round .. ": lowest roll is out.")
end

function LL:ResolveEliminationRound(game)
    local _, lowest = self:GetGroupExtremes(game, false)
    if #lowest > 1 then self:StartGroupRollRound(game, "elimination", 1, game.wager, self:GroupPlayerSet(game, lowest), "Tie for lowest — tied players roll again."); return end
    local loser = lowest[1]
    game.alive[loser] = nil
    table.insert(game.eliminated, loser)
    local alive = self:GroupAlivePlayers(game)
    if #alive == 2 then
        game.finalists, game.deathMax, game.turnIndex = alive, game.wager, 1
        game.rolls = {}
        self:SetCasinoGameState(game, "elimination-final", 1, game.deathMax, alive[1], alive[1] .. " starts the final Death Roll.")
    else
        self:StartEliminationRound(game)
    end
end

function LL:FinishCasinoGame(game, summary, debts)
    local result = { id = game.id, mode = game.mode, host = game.host, wager = game.wager, finishedAt = time(), summary = summary }
    self:ApplyCasinoGameResult(result)
    self:Broadcast("CASINO_GAME_RESULT", result)
    for _, debt in ipairs(debts or {}) do
        local settlement = { id = game.id, winner = debt.winner, loser = debt.loser, amount = debt.amount }
        self:ApplyCasinoSettlement(settlement)
        self:Broadcast("CASINO_GAME_SETTLE", settlement)
    end
end

function LL:ApplyCasinoGameResult(result)
    if not result.id or self.db.casinoProcessedGames[result.id] then return end
    self.db.casinoProcessedGames[result.id] = true
    self.db.casinoGroupGame = nil
    table.insert(self.db.casinoHistory, 1, result)
    while #self.db.casinoHistory > 5 do table.remove(self.db.casinoHistory) end
    self:Print(result.summary)
    self:RefreshUI()
end

function LL:ApplyCasinoSettlement(settlement)
    if not settlement.id or not settlement.winner or not settlement.loser or not settlement.amount then return end
    local key = self:CasinoSettlementKey(settlement)
    self.db.casinoSettlements[settlement.id] = self.db.casinoSettlements[settlement.id] or {}
    if self.db.casinoSettlements[settlement.id][key] then return end
    self.db.casinoSettlements[settlement.id][key] = settlement
    local winner, loser = self:GetCasinoStats(settlement.winner), self:GetCasinoStats(settlement.loser)
    winner.wonGold, winner.games = winner.wonGold + settlement.amount, winner.games + 1
    loser.lostGold, loser.games = loser.lostGold + settlement.amount, loser.games + 1
    self:RefreshUI()
end

function LL:RollCasinoGame()
    local game = self:GetGroupCasinoGame()
    if not game or game.status ~= "running" or game.minRoll < 1 or game.maxRoll < game.minRoll then self:Print("This casino game is not ready for a roll."); return false end
    if not self:FindGroupPlayer(game, self:PlayerName()) then self:Print("Join the casino game before rolling."); return false end
    if game.turn ~= "" and not self:NamesMatch(game.turn, self:PlayerName()) then self:Print("It is " .. game.turn .. "'s turn to roll."); return false end
    if game.pending and not game.pending[self:PlayerName()] then self:Print("You are not expected to roll in this round."); return false end
    RandomRoll(game.minRoll, game.maxRoll)
    return true
end

function LL:ProcessCasinoGameRoll(game, payload)
    local player = self:FindGroupPlayer(game, payload.player)
    if not player or game.status ~= "running" or payload.minRoll ~= game.minRoll or payload.maxRoll ~= game.maxRoll or payload.roll < game.minRoll or payload.roll > game.maxRoll then return end
    if game.turn ~= "" and not self:NamesMatch(game.turn, player) then return end
    if game.pending and not game.pending[player] then return end
    if game.rolls and game.rolls[player] then return end
    game.rolls = game.rolls or {}; game.rolls[player] = payload.roll
    if game.phase == "deathroll" or game.phase == "elimination-final" then
        if payload.roll == 1 then
            local players = game.phase == "deathroll" and game.players or game.finalists
            local winner = players[3 - game.turnIndex]
            local debts = {}
            if game.phase == "elimination-final" then for _, name in ipairs(game.players) do if name ~= winner then table.insert(debts, { winner = winner, loser = name, amount = game.wager }) end end else table.insert(debts, { winner = winner, loser = player, amount = game.wager }) end
            self:FinishCasinoGame(game, player .. " rolled 1. " .. winner .. " wins!", debts)
        else
            game.deathMax = payload.roll
            game.rolls = {}
            game.turnIndex = 3 - game.turnIndex
            local players = game.phase == "deathroll" and game.players or game.finalists
            self:SetCasinoGameState(game, game.phase, 1, game.deathMax, players[game.turnIndex], players[game.turnIndex] .. " rolls next.")
        end
    elseif self:AllGroupRollsReceived(game) then
        if game.phase == "classic" then self:ResolveClassicGame(game)
        elseif game.phase == "elimination" then self:ResolveEliminationRound(game) end
    end
end

function LL:HandleCasinoGameRoll(player, roll, low, high)
    local game = self:GetGroupCasinoGame()
    if not game or game.status ~= "running" or low ~= game.minRoll or high ~= game.maxRoll or not self:FindGroupPlayer(game, player) then return end
    local payload = { id = game.id, player = player, roll = roll, minRoll = low, maxRoll = high }
    if self:IsGroupCasinoHost(game) then self:ProcessCasinoGameRoll(game, payload) end
    self:Broadcast("CASINO_GAME_ROLL", payload)
end

function LL:OnCasinoGameMessage(kind, payload)
    if kind == "CASINO_GAME_RESULT" then
        self:ApplyCasinoGameResult(payload)
        self:RefreshUI()
        return
    elseif kind == "CASINO_GAME_SETTLE" then
        self:ApplyCasinoSettlement(payload)
        self:RefreshUI()
        return
    elseif kind == "CASINO_GAME_DEBT_PAID" then
        self:ApplyCasinoDebtPayment(payload)
        self:RefreshUI()
        return
    end
    local game = self:GetGroupCasinoGame()
    if kind == "CASINO_GAME_OPEN" then
        if not game then self.db.casinoGroupGame = { id = payload.id, host = payload.host, mode = payload.mode, wager = payload.wager, createdAt = payload.createdAt, status = "lobby", players = { payload.host }, playerSet = { [payload.host] = true } } end
    elseif kind == "CASINO_GAME_CLOSE" then
        if game and game.id == payload.id then self.db.casinoGroupGame = nil end
    elseif not game or game.id ~= payload.id then return
    elseif kind == "CASINO_GAME_JOIN" and game.status == "lobby" then
        if not self:FindGroupPlayer(game, payload.player) then table.insert(game.players, payload.player); game.playerSet[payload.player] = true end
    elseif kind == "CASINO_GAME_STATE" then
        game.status, game.phase, game.minRoll, game.maxRoll, game.turn, game.message = "running", payload.phase, payload.minRoll, payload.maxRoll, payload.turn, payload.message
    elseif kind == "CASINO_GAME_ROLL" and self:IsGroupCasinoHost(game) then
        self:ProcessCasinoGameRoll(game, payload)
    end
    self:RefreshUI()
end

function LL:SendCasinoGameSync()
    local game = self:GetGroupCasinoGame()
    if game and self:IsGroupCasinoHost(game) then
        self:Broadcast("CASINO_GAME_OPEN", game)
        for index = 2, #game.players do self:Broadcast("CASINO_GAME_JOIN", { id = game.id, player = game.players[index] }) end
        if game.status == "running" then self:Broadcast("CASINO_GAME_STATE", game) end
    end
    for _, result in ipairs(self.db.casinoHistory) do
        if result.mode and result.summary then
            self:Broadcast("CASINO_GAME_RESULT", result)
            for _, settlement in pairs(self.db.casinoSettlements[result.id] or {}) do
                self:Broadcast("CASINO_GAME_SETTLE", settlement)
                if settlement.paidAt then self:Broadcast("CASINO_GAME_DEBT_PAID", settlement) end
            end
        end
    end
end
