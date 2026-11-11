local addonName, LL = ...

LL.ADDON_NAME = addonName
LL.GUILD_NAME = "OG Lagom"
LL.COMM_PREFIX = "LAGOMLEDGER"
LL.VERSION = 1
LL.RELEASE = "1.6.0"
LL.versionNoticeSent = {}

local function now()
    return time()
end

function LL:PlayerName()
    local name, realm = UnitFullName("player")
    return realm and realm ~= "" and (name .. "-" .. realm) or name
end

function LL:IsLagomMember()
    local guildName = GetGuildInfo("player")
    return type(guildName) == "string" and string.lower(guildName) == string.lower(self.GUILD_NAME)
end

function LL:Print(message)
    DEFAULT_CHAT_FRAME:AddMessage("|cffc69b6dLagom Ledger:|r " .. message)
end

function LL:IsOlderRelease(release)
    if not release or release == "" then return true end
    local function parts(value)
        local major, minor, patch = value:match("^(%d+)%.(%d+)%.?(%d*)$")
        return tonumber(major) or 0, tonumber(minor) or 0, tonumber(patch) or 0
    end
    local currentMajor, currentMinor, currentPatch = parts(self.RELEASE)
    local remoteMajor, remoteMinor, remotePatch = parts(release)
    if remoteMajor ~= currentMajor then return remoteMajor < currentMajor end
    if remoteMinor ~= currentMinor then return remoteMinor < currentMinor end
    return remotePatch < currentPatch
end

function LL:NotifyOutdatedMember(sender, release)
    if self.versionNoticeSent[sender] or not self:IsOlderRelease(release) then return end
    self.versionNoticeSent[sender] = true
    if SendChatMessage then
        SendChatMessage("Lagom Ledger " .. self.RELEASE .. " is available. Please update your addon.", "WHISPER", nil, sender)
    end
end

function LL:EnsureDatabase()
    LagomLedgerDB = LagomLedgerDB or {}
    LagomLedgerDB.players = LagomLedgerDB.players or {}
    LagomLedgerDB.bounties = LagomLedgerDB.bounties or {}
    LagomLedgerDB.nextBountyId = LagomLedgerDB.nextBountyId or 1
    LagomLedgerDB.casinoStats = LagomLedgerDB.casinoStats or {}
    LagomLedgerDB.casinoHistory = LagomLedgerDB.casinoHistory or {}
    LagomLedgerDB.casinoProcessedGames = LagomLedgerDB.casinoProcessedGames or {}
    LagomLedgerDB.nextCasinoId = LagomLedgerDB.nextCasinoId or 1
    LagomLedgerDB.casinoGroupGame = LagomLedgerDB.casinoGroupGame or nil
    LagomLedgerDB.casinoSettlements = LagomLedgerDB.casinoSettlements or {}
    LagomLedgerDB.minimap = LagomLedgerDB.minimap or { angle = 225 }
    self.db = LagomLedgerDB
    self:EnsurePlayer(self:PlayerName())
end

function LL:EnsurePlayer(name)
    local player = self.db.players[name]
    if not player then
        player = { kills = 0, deaths = 0, professions = {}, class = "", level = 0, primaryProfessions = "", secondaryProfessions = "", updatedAt = now() }
        self.db.players[name] = player
    end
    return player
end

function LL:GetProfessions()
    local names, seen = {}, {}
    if GetProfessions and GetProfessionInfo then
        local professionIndexes = { GetProfessions() }
        for index = 1, 5 do
            local professionIndex = professionIndexes[index]
            if professionIndex then
                local name = GetProfessionInfo(professionIndex)
                if name and not seen[name] then
                    seen[name] = true
                    table.insert(names, name)
                end
            end
        end
    end
    table.sort(names)
    return names
end

function LL:RefreshLocalProfile()
    if not self.db then return end
    local player = self:EnsurePlayer(self:PlayerName())
    player.professions = self:GetProfessions()
    player.updatedAt = now()
    self:Broadcast("PROFILE", {
        name = self:PlayerName(),
        kills = player.kills,
        deaths = player.deaths,
        professions = player.professions,
        updatedAt = player.updatedAt,
        release = self.RELEASE,
        class = player.class,
        level = player.level,
        primaryProfessions = player.primaryProfessions,
        secondaryProfessions = player.secondaryProfessions,
    })
    self:RefreshUI()
end

function LL:Broadcast(kind, payload)
    if not self:IsLagomMember() or not C_ChatInfo then return end
    local message = self.VERSION .. "|" .. kind .. "|" .. self:Serialize(kind, payload)
    if #message <= 255 then
        C_ChatInfo.SendAddonMessage(self.COMM_PREFIX, message, "GUILD")
    end
end

function LL:Escape(value)
    return ((tostring(value or ""):gsub("[^%w%-%._ ]", function(character)
        return string.format("%%%02X", string.byte(character))
    end)))
end

function LL:Unescape(value)
    return ((value or ""):gsub("%%(%x%x)", function(hex) return string.char(tonumber(hex, 16)) end))
end

function LL:Serialize(kind, payload)
    if kind == "PROFILE" then
        local professions = {}
        for _, profession in ipairs(payload.professions or {}) do table.insert(professions, self:Escape(profession)) end
        return table.concat({ self:Escape(payload.name), payload.kills or 0, payload.deaths or 0, table.concat(professions, ","), payload.updatedAt or now(), self:Escape(payload.release), self:Escape(payload.class), payload.level or 0, self:Escape(payload.primaryProfessions), self:Escape(payload.secondaryProfessions) }, ";")
    elseif kind == "BOUNTY_ADD" then
        return table.concat({ self:Escape(payload.id), self:Escape(payload.target), self:Escape(payload.note), self:Escape(payload.postedBy), payload.createdAt or now() }, ";")
    elseif kind == "BOUNTY_COMPLETE" then
        return table.concat({ self:Escape(payload.id), self:Escape(payload.completedBy), payload.completedAt or now(), payload.canceled and 1 or 0 }, ";")
    elseif kind == "CASINO_STAT" then
        return table.concat({ self:Escape(payload.name), payload.wonGold or 0, payload.lostGold or 0, payload.games or 0 }, ";")
    elseif kind == "CASINO_GAME_OPEN" then
        return table.concat({ self:Escape(payload.id), self:Escape(payload.host), self:Escape(payload.mode), payload.wager, payload.createdAt or now() }, ";")
    elseif kind == "CASINO_GAME_JOIN" then
        return table.concat({ self:Escape(payload.id), self:Escape(payload.player) }, ";")
    elseif kind == "CASINO_GAME_CLOSE" then
        return self:Escape(payload.id)
    elseif kind == "CASINO_GAME_STATE" then
        return table.concat({ self:Escape(payload.id), self:Escape(payload.phase), payload.minRoll or 0, payload.maxRoll or 0, self:Escape(payload.turn), self:Escape(payload.message) }, ";")
    elseif kind == "CASINO_GAME_ROLL" then
        return table.concat({ self:Escape(payload.id), self:Escape(payload.player), payload.roll, payload.minRoll, payload.maxRoll }, ";")
    elseif kind == "CASINO_GAME_RESULT" then
        return table.concat({ self:Escape(payload.id), self:Escape(payload.mode), self:Escape(payload.host), payload.wager, payload.finishedAt or now(), self:Escape(payload.summary) }, ";")
    elseif kind == "CASINO_GAME_SETTLE" then
        return table.concat({ self:Escape(payload.id), self:Escape(payload.winner), self:Escape(payload.loser), payload.amount }, ";")
    end
    return ""
end

function LL:Decode(message)
    local version, kind, data = strsplit("|", message, 3)
    if tonumber(version) ~= self.VERSION or not kind or data == nil then return end
    local fields = { strsplit(";", data) }
    if kind == "PROFILE" then
        local professions = {}
        for profession in string.gmatch(fields[4] or "", "[^,]+") do table.insert(professions, self:Unescape(profession)) end
        return kind, { name = self:Unescape(fields[1]), kills = tonumber(fields[2]), deaths = tonumber(fields[3]), professions = professions, updatedAt = tonumber(fields[5]), release = self:Unescape(fields[6]), class = self:Unescape(fields[7]), level = tonumber(fields[8]), primaryProfessions = self:Unescape(fields[9]), secondaryProfessions = self:Unescape(fields[10]) }
    elseif kind == "BOUNTY_ADD" then
        return kind, { id = self:Unescape(fields[1]), target = self:Unescape(fields[2]), note = self:Unescape(fields[3]), postedBy = self:Unescape(fields[4]), createdAt = tonumber(fields[5]), active = true }
    elseif kind == "BOUNTY_COMPLETE" then
        return kind, { id = self:Unescape(fields[1]), completedBy = self:Unescape(fields[2]), completedAt = tonumber(fields[3]), canceled = tonumber(fields[4]) == 1 }
    elseif kind == "REQUEST_SYNC" then
        return kind, {}
    elseif kind == "CASINO_STAT" then
        return kind, { name = self:Unescape(fields[1]), wonGold = tonumber(fields[2]), lostGold = tonumber(fields[3]), games = tonumber(fields[4]) }
    elseif kind == "CASINO_GAME_OPEN" then
        return kind, { id = self:Unescape(fields[1]), host = self:Unescape(fields[2]), mode = self:Unescape(fields[3]), wager = tonumber(fields[4]), createdAt = tonumber(fields[5]) }
    elseif kind == "CASINO_GAME_JOIN" then
        return kind, { id = self:Unescape(fields[1]), player = self:Unescape(fields[2]) }
    elseif kind == "CASINO_GAME_CLOSE" then
        return kind, { id = self:Unescape(fields[1]) }
    elseif kind == "CASINO_GAME_STATE" then
        return kind, { id = self:Unescape(fields[1]), phase = self:Unescape(fields[2]), minRoll = tonumber(fields[3]), maxRoll = tonumber(fields[4]), turn = self:Unescape(fields[5]), message = self:Unescape(fields[6]) }
    elseif kind == "CASINO_GAME_ROLL" then
        return kind, { id = self:Unescape(fields[1]), player = self:Unescape(fields[2]), roll = tonumber(fields[3]), minRoll = tonumber(fields[4]), maxRoll = tonumber(fields[5]) }
    elseif kind == "CASINO_GAME_RESULT" then
        return kind, { id = self:Unescape(fields[1]), mode = self:Unescape(fields[2]), host = self:Unescape(fields[3]), wager = tonumber(fields[4]), finishedAt = tonumber(fields[5]), summary = self:Unescape(fields[6]) }
    elseif kind == "CASINO_GAME_SETTLE" then
        return kind, { id = self:Unescape(fields[1]), winner = self:Unescape(fields[2]), loser = self:Unescape(fields[3]), amount = tonumber(fields[4]) }
    end
end

function LL:RecordDeath()
    if not self.db then return end
    local player = self:EnsurePlayer(self:PlayerName())
    player.deaths = player.deaths + 1
    player.updatedAt = now()
    self:Broadcast("PROFILE", { name = self:PlayerName(), kills = player.kills, deaths = player.deaths, professions = player.professions, updatedAt = player.updatedAt, release = self.RELEASE, class = player.class, level = player.level, primaryProfessions = player.primaryProfessions, secondaryProfessions = player.secondaryProfessions })
    self:RefreshUI()
end

function LL:AddBounty(target, note)
    target = strtrim(target or "")
    if target == "" then
        self:Print("Enter an Alliance character name for the bounty.")
        return false
    end
    local id = self:PlayerName() .. "-" .. self.db.nextBountyId
    self.db.nextBountyId = self.db.nextBountyId + 1
    local bounty = { id = id, target = target, note = strtrim(note or ""), postedBy = self:PlayerName(), createdAt = now(), updatedAt = now(), active = true }
    table.insert(self.db.bounties, bounty)
    self:Broadcast("BOUNTY_ADD", bounty)
    self:RefreshUI()
    return true
end

function LL:NormalizeBountyTarget(name)
    return strlower(strtrim(name or "")):gsub("%s", "")
end

function LL:BountyTargetMatches(bountyTarget, targetName)
    local bountyName = self:NormalizeBountyTarget(bountyTarget)
    local killedName = self:NormalizeBountyTarget(targetName)
    if bountyName == "" or killedName == "" then return false end
    if bountyName == killedName then return true end
    return bountyName:match("^[^-]+") == killedName:match("^[^-]+")
end

function LL:MarkBountyComplete(bounty)
    bounty.active = false
    bounty.completedBy = self:PlayerName()
    bounty.completedAt = now()
    bounty.updatedAt = bounty.completedAt
    bounty.canceled = nil
    self:Broadcast("BOUNTY_COMPLETE", { id = bounty.id, completedBy = bounty.completedBy, completedAt = bounty.completedAt })
end

function LL:CompleteBounty(id)
    id = strtrim(id or "")
    for _, bounty in ipairs(self.db.bounties) do
        if bounty.id == id and bounty.active then
            self:MarkBountyComplete(bounty)
            self:RefreshUI()
            self:Print("Completed bounty for " .. bounty.target .. ".")
            return true
        end
    end
    self:Print("No active bounty found with that ID.")
    return false
end

function LL:CompleteBountiesForTarget(targetName)
    local completed = 0
    for _, bounty in ipairs(self.db.bounties) do
        if bounty.active and self:BountyTargetMatches(bounty.target, targetName) then
            self:MarkBountyComplete(bounty)
            completed = completed + 1
        end
    end
    if completed > 0 then self:RefreshUI() end
    return completed
end

function LL:CompleteSelectedBounties()
    local name = UnitName("target")
    if not name then
        self:Print("Select the completed bounty target first.")
        return false
    end
    local completed = self:CompleteBountiesForTarget(name)
    if completed == 0 then
        self:Print("No active bounty matches " .. name .. ".")
        return false
    end
    self:Print("Completed " .. completed .. " matching " .. (completed == 1 and "bounty." or "bounties."))
    return true
end

function LL:OnComm(prefix, message, channel, sender)
    if not self.db or prefix ~= self.COMM_PREFIX or channel ~= "GUILD" or not self:IsLagomMember() or sender == self:PlayerName() then return end
    local kind, payload = self:Decode(message)
    if kind == "PROFILE" and type(payload.name) == "string" then
        local player = self:EnsurePlayer(payload.name)
        player.kills = tonumber(payload.kills) or player.kills
        player.deaths = tonumber(payload.deaths) or player.deaths
        player.professions = type(payload.professions) == "table" and payload.professions or player.professions
        player.updatedAt = tonumber(payload.updatedAt) or now()
        player.class = type(payload.class) == "string" and payload.class or player.class
        player.level = tonumber(payload.level) or player.level
        player.primaryProfessions = type(payload.primaryProfessions) == "string" and payload.primaryProfessions or player.primaryProfessions
        player.secondaryProfessions = type(payload.secondaryProfessions) == "string" and payload.secondaryProfessions or player.secondaryProfessions
        self:NotifyOutdatedMember(sender, payload.release)
    elseif kind == "BOUNTY_ADD" and payload.id and payload.target then
        for _, bounty in ipairs(self.db.bounties) do if bounty.id == payload.id then return end end
        table.insert(self.db.bounties, payload)
    elseif kind == "BOUNTY_COMPLETE" and payload.id then
        for _, bounty in ipairs(self.db.bounties) do
            if bounty.id == payload.id then bounty.active = false; bounty.canceled = payload.canceled; bounty.completedBy = payload.completedBy; bounty.completedAt = payload.completedAt; bounty.updatedAt = payload.completedAt end
        end
    elseif string.sub(kind or "", 1, 12) == "CASINO_GAME_" and self.OnCasinoGameMessage then
        self:OnCasinoGameMessage(kind, payload)
    elseif string.sub(kind or "", 1, 7) == "CASINO_" and self.OnCasinoMessage then
        self:OnCasinoMessage(kind, payload)
    elseif kind == "REQUEST_SYNC" then
        self:RefreshLocalProfile()
        for _, bounty in ipairs(self.db.bounties) do
            if bounty.active then self:Broadcast("BOUNTY_ADD", bounty) end
        end
        if self.SendCasinoSync then self:SendCasinoSync() end
        if self.SendCasinoGameSync then self:SendCasinoGameSync() end
    else
        return
    end
    self:RefreshUI()
end

function LL:OnEvent(event, ...)
    if event == "PLAYER_LOGIN" then
        self:EnsureDatabase()
        C_ChatInfo.RegisterAddonMessagePrefix(self.COMM_PREFIX)
        if self.RegisterEllesmerePlugin then self:RegisterEllesmerePlugin() end
        if self.BuildMinimapButton then self:BuildMinimapButton() end
        self:RefreshLocalProfile()
        self:Broadcast("REQUEST_SYNC", {})
    elseif event == "PLAYER_DEAD" and self.db then
        self:RecordDeath()
    elseif event == "CHAT_MSG_ADDON" and self.db then
        self:OnComm(...)
    elseif event == "CHAT_MSG_SYSTEM" and self.db and self.HandleRollMessage then
        self:HandleRollMessage(...)
    elseif event == "SKILL_LINES_CHANGED" and self.db then
        self:RefreshLocalProfile()
    end
end

SLASH_LAGOMLEDGER1 = "/lagom"
SlashCmdList.LAGOMLEDGER = function(input)
    local command, argument = input:match("^(%S*)%s*(.-)$")
    command = command:lower()
    if command == "death" then
        LL:RecordDeath()
    elseif command == "complete" then
        LL:CompleteBounty(argument)
    elseif command == "casino" then
        LL:ToggleCasino()
    elseif command == "settings" and LL.OpenEllesmereSettings then
        LL:OpenEllesmereSettings()
    elseif command == "sync" then
        LL:RefreshLocalProfile()
    elseif command == "help" then
        LL:Print("/lagom opens the board; /lagom casino opens the casino; /lagom settings opens EllesmereUI settings.")
    else
        LL:ToggleUI()
    end
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("PLAYER_DEAD")
frame:RegisterEvent("CHAT_MSG_ADDON")
frame:RegisterEvent("CHAT_MSG_SYSTEM")
frame:RegisterEvent("SKILL_LINES_CHANGED")
frame:SetScript("OnEvent", function(_, event, ...) LL:OnEvent(event, ...) end)

