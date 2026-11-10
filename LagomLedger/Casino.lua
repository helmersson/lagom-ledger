local _, LL = ...

LL.CASINO_MAX_WAGER = 2000000000

function LL:ShortName(name)
    return (name or ""):match("^([^%-]+)") or ""
end

function LL:NamesMatch(left, right)
    return self:ShortName(left):lower() == self:ShortName(right):lower()
end

function LL:GetCasinoStats(name)
    local stats = self.db.casinoStats[name]
    if not stats then
        stats = { wonGold = 0, lostGold = 0, games = 0 }
        self.db.casinoStats[name] = stats
    end
    return stats
end

function LL:HasGoldForCasino(wager)
    if GetMoney and GetMoney() < wager * 10000 then
        self:Print("You need " .. wager .. " gold in your bags before joining this wager.")
        return false
    end
    return true
end

function LL:BroadcastCasinoStat(name)
    local stats = self:GetCasinoStats(name)
    self:Broadcast("CASINO_STAT", { name = name, wonGold = stats.wonGold, lostGold = stats.lostGold, games = stats.games })
end

function LL:ReceiveCasinoStat(payload)
    if not payload.name then return end
    local stats = self:GetCasinoStats(payload.name)
    stats.wonGold = math.max(stats.wonGold, payload.wonGold or 0)
    stats.lostGold = math.max(stats.lostGold, payload.lostGold or 0)
    stats.games = math.max(stats.games, payload.games or 0)
    self:RefreshUI()
end

function LL:SendCasinoSync()
    for name in pairs(self.db.casinoStats) do self:BroadcastCasinoStat(name) end
end

function LL:OnCasinoMessage(kind, payload)
    if kind == "CASINO_STAT" then self:ReceiveCasinoStat(payload) end
end

function LL:ParseRandomRoll(message)
    if not RANDOM_ROLL_RESULT then return end
    local pattern = RANDOM_ROLL_RESULT:gsub("([%^%$%(%)%.%[%]%*%+%-%?])", "%%%1")
    pattern = pattern:gsub("%%s", "(.+)")
    pattern = pattern:gsub("%%d", "(%%d+)")
    return message:match("^" .. pattern .. "$")
end

function LL:HandleRollMessage(message)
    local player, roll, low, high = self:ParseRandomRoll(message)
    roll, low, high = tonumber(roll), tonumber(low), tonumber(high)
    if not player or not roll or low ~= 1 or not high then return end
    if self.HandleCasinoGameRoll then self:HandleCasinoGameRoll(player, roll, low, high) end
end

