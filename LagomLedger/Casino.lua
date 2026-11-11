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

function LL:CasinoSettlementKey(settlement)
    return settlement.id .. "|" .. settlement.winner .. "|" .. settlement.loser .. "|" .. settlement.amount
end

function LL:GetCasinoDebts()
    if not self.db then return {} end
    local finishedAt, debts = {}, {}
    for _, result in ipairs(self.db.casinoHistory or {}) do finishedAt[result.id] = result.finishedAt or 0 end
    for _, settlements in pairs(self.db.casinoSettlements or {}) do
        for _, settlement in pairs(settlements) do
            if self:NamesMatch(settlement.loser, self:PlayerName()) and (settlement.amount or 0) > 0 and not settlement.paidAt then
                table.insert(debts, settlement)
            end
        end
    end
    table.sort(debts, function(left, right)
        local leftTime, rightTime = finishedAt[left.id] or 0, finishedAt[right.id] or 0
        if leftTime == rightTime then return self:CasinoSettlementKey(left) < self:CasinoSettlementKey(right) end
        return leftTime < rightTime
    end)
    return debts
end

function LL:GetNextCasinoDebt()
    local debts = self:GetCasinoDebts()
    return debts[1], #debts
end

function LL:PrepareCasinoDebtMail()
    local debt, debtCount = self:GetNextCasinoDebt()
    if not debt then self:Print("You have no outstanding casino debts."); return false end
    if GetMoney and GetMoney() < debt.amount * 10000 then
        self:Print("You need " .. debt.amount .. " gold in your bags to pay this casino debt.")
        return false
    end
    local mailFrame, recipient, subject, mailMoney = _G.SendMailFrame, _G.SendMailNameEditBox, _G.SendMailSubjectEditBox, _G.SendMailMoney
    if not (mailFrame and mailFrame:IsShown() and recipient and subject and mailMoney and mailMoney.SetAmount) then
        self:Print("Open a mailbox, then select Prepare mail to pay this casino debt.")
        return false
    end
    local filled = pcall(function()
        recipient:SetText(debt.winner)
        subject:SetText("Lagom Ledger casino debt")
        mailMoney:SetAmount(debt.amount * 10000)
    end)
    if not filled then self:Print("Lagom Ledger could not fill the Blizzard mail form."); return false end
    self.preparedCasinoDebtKey = self:CasinoSettlementKey(debt)
    self:Print("Prepared " .. debt.amount .. " gold for " .. debt.winner .. ". Review it and use Blizzard's Send button; then select Mark paid here.")
    self:RefreshUI()
    return true
end

function LL:ApplyCasinoDebtPayment(payment)
    if not payment.id or not payment.winner or not payment.loser or not payment.amount or not payment.paidBy or not self:NamesMatch(payment.loser, payment.paidBy) then return end
    local settlements = self.db.casinoSettlements[payment.id]
    local settlement = settlements and settlements[self:CasinoSettlementKey(payment)]
    if not settlement or settlement.paidAt then return end
    settlement.paidAt, settlement.paidBy = payment.paidAt or time(), payment.paidBy
    self:RefreshUI()
end

function LL:MarkPreparedCasinoDebtPaid()
    local key = self.preparedCasinoDebtKey
    if not key then self:Print("Prepare a casino-debt mail before marking it paid."); return false end
    for _, debt in ipairs(self:GetCasinoDebts()) do
        if self:CasinoSettlementKey(debt) == key then
            local payment = { id = debt.id, winner = debt.winner, loser = debt.loser, amount = debt.amount, paidBy = self:PlayerName(), paidAt = time() }
            self.preparedCasinoDebtKey = nil
            self:ApplyCasinoDebtPayment(payment)
            self:Broadcast("CASINO_GAME_DEBT_PAID", payment)
            self:Print("Marked " .. debt.amount .. " gold to " .. debt.winner .. " as paid.")
            return true
        end
    end
    self.preparedCasinoDebtKey = nil
    self:Print("That casino debt is no longer outstanding.")
    self:RefreshUI()
    return false
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
