local _, LL = ...

local function now()
    return time()
end

function LL:GetWeeklyResetStart()
    local reset = C_DateAndTime and C_DateAndTime.GetWeeklyResetStartTime and C_DateAndTime.GetWeeklyResetStartTime()
    if type(reset) == "number" then return reset end
    local serverTime = GetServerTime and GetServerTime() or now()
    return math.floor(serverTime / 604800) * 604800
end

function LL:EnsureWeeklyStats(player)
    local reset = self:GetWeeklyResetStart()
    if tonumber(player.weeklyReset) ~= reset then
        player.weeklyReset, player.weeklyKills, player.weeklyDeaths = reset, 0, 0
    else
        player.weeklyKills = tonumber(player.weeklyKills) or 0
        player.weeklyDeaths = tonumber(player.weeklyDeaths) or 0
    end
end

function LL:ParseRewardCopper(value)
    local reward = strtrim(tostring(value or "")):gsub(",", ".")
    local gold, fraction = reward:match("^(%d+)%.(%d%d?)$")
    if not gold then gold = reward:match("^(%d+)$") end
    if not gold then return end
    local silver = fraction and tonumber(fraction) * (#fraction == 1 and 10 or 1) or 0
    local copper = tonumber(gold) * 10000 + silver * 100
    return copper > 0 and copper or nil
end

function LL:FormatMoney(copper)
    copper = math.max(0, math.floor(tonumber(copper) or 0))
    local gold, silver = math.floor(copper / 10000), math.floor(copper % 10000 / 100)
    return gold .. "g " .. silver .. "s"
end

function LL:GetDailyResetStart()
    return math.floor((GetServerTime and GetServerTime() or now()) / 86400) * 86400
end

function LL:BalanceTransactionKey(kind, settlement)
    return table.concat({ kind or "", settlement.id or "", settlement.winner or "", settlement.loser or "", tonumber(settlement.amountCopper) or 0 }, "|")
end

function LL:RecordBalanceTransaction(kind, settlement)
    if not self.db or not settlement or not settlement.id or not settlement.winner or not settlement.loser then return end
    local amount = tonumber(settlement.amountCopper) or 0
    if amount <= 0 then return end
    local key = self:BalanceTransactionKey(kind, settlement)
    for _, transaction in ipairs(self.db.balanceTransactions) do
        if transaction.key == key then return transaction end
    end
    local transaction = { key = key, kind = kind, sourceId = settlement.id, winner = settlement.winner, loser = settlement.loser,
        amountCopper = amount, target = settlement.target, at = settlement.createdAt or settlement.finishedAt or now(), paidAt = settlement.paidAt }
    table.insert(self.db.balanceTransactions, transaction)
    return transaction
end

function LL:MarkBalanceTransactionPaid(kind, settlement, paidAt)
    local key = self:BalanceTransactionKey(kind, settlement)
    for _, transaction in ipairs((self.db and self.db.balanceTransactions) or {}) do
        if transaction.key == key then transaction.paidAt = paidAt or now(); return end
    end
end

function LL:GetBalanceTransactions(scope, name)
    local start = scope == "daily" and self:GetDailyResetStart() or (scope == "weekly" and self:GetWeeklyResetStart() or 0)
    local identity, transactions = self:PlayerIdentityKey(name or self:PlayerName()), {}
    for _, transaction in ipairs((self.db and self.db.balanceTransactions) or {}) do
        local at = tonumber(transaction.at) or 0
        if at >= start then
            local delta = self:PlayerIdentityKey(transaction.winner) == identity and transaction.amountCopper or
                (self:PlayerIdentityKey(transaction.loser) == identity and -transaction.amountCopper or nil)
            if delta then table.insert(transactions, { transaction = transaction, delta = delta }) end
        end
    end
    table.sort(transactions, function(left, right) return (left.transaction.at or 0) > (right.transaction.at or 0) end)
    return transactions, start
end

function LL:GetBalanceSummary(scope, name)
    local won, lost, transactions = 0, 0, self:GetBalanceTransactions(scope, name)
    for _, entry in ipairs(transactions) do
        if entry.delta > 0 then won = won + entry.delta else lost = lost - entry.delta end
    end
    return won, lost, won - lost, transactions
end

function LL:GetBalanceGraph(scope, name)
    local transactions, start = self:GetBalanceTransactions(scope, name)
    local current = GetServerTime and GetServerTime() or now()
    if scope == "lifetime" and #transactions > 0 then start = transactions[#transactions].transaction.at or current end
    local span = math.max(1, current - start + 1)
    local values = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 }
    for _, entry in ipairs(transactions) do
        local index = math.min(12, math.max(1, math.floor(((entry.transaction.at or current) - start) / span * 12) + 1))
        values[index] = values[index] + entry.delta
    end
    return values
end
