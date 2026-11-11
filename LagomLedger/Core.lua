local addonName, LL = ...

LL.ADDON_NAME = addonName
LL.GUILD_NAME = nil
LL.COMM_PREFIX = "LAGOMLEDGER"
LL.VERSION = 1
LL.RELEASE = "1.7.1"
LL.versionNoticeSent = {}

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

function LL:PlayerName()
    local name, realm = UnitFullName("player")
    return realm and realm ~= "" and (name .. "-" .. realm) or name
end

function LL:PlayerIdentityKey(name)
    return strlower((strtrim(name or ""):match("^([^%-%s]+)") or ""))
end

function LL:MergePlayerRecords(primary, duplicate)
    local primaryUpdated, duplicateUpdated = tonumber(primary.updatedAt) or 0, tonumber(duplicate.updatedAt) or 0
    primary.kills = math.max(tonumber(primary.kills) or 0, tonumber(duplicate.kills) or 0)
    primary.deaths = math.max(tonumber(primary.deaths) or 0, tonumber(duplicate.deaths) or 0)
    primary.level = math.max(tonumber(primary.level) or 0, tonumber(duplicate.level) or 0)
    primary.killStreak = tonumber(primary.killStreak) or 0
    primary.longestLife = math.max(tonumber(primary.longestLife) or 0, tonumber(duplicate.longestLife) or 0)
    primary.lifeTracked = primary.lifeTracked or duplicate.lifeTracked
    if duplicateUpdated > primaryUpdated then
        primary.killStreak = tonumber(duplicate.killStreak) or primary.killStreak
        primary.aliveSince = tonumber(duplicate.aliveSince)
    end
    primary.updatedAt = math.max(primaryUpdated, duplicateUpdated)
    if primary.lastHonorableKills ~= nil or duplicate.lastHonorableKills ~= nil then
        primary.lastHonorableKills = math.max(tonumber(primary.lastHonorableKills) or 0, tonumber(duplicate.lastHonorableKills) or 0)
    end
    local primaryWeeklyReset, duplicateWeeklyReset = tonumber(primary.weeklyReset) or 0, tonumber(duplicate.weeklyReset) or 0
    if duplicateWeeklyReset > primaryWeeklyReset then
        primary.weeklyReset, primary.weeklyKills, primary.weeklyDeaths = duplicateWeeklyReset, duplicate.weeklyKills, duplicate.weeklyDeaths
    elseif duplicateWeeklyReset == primaryWeeklyReset then
        primary.weeklyKills = math.max(tonumber(primary.weeklyKills) or 0, tonumber(duplicate.weeklyKills) or 0)
        primary.weeklyDeaths = math.max(tonumber(primary.weeklyDeaths) or 0, tonumber(duplicate.weeklyDeaths) or 0)
    end
    if (primary.class or "") == "" then primary.class = duplicate.class or "" end
    if (primary.primaryProfessions or "") == "" then primary.primaryProfessions = duplicate.primaryProfessions or "" end
    if (primary.secondaryProfessions or "") == "" then primary.secondaryProfessions = duplicate.secondaryProfessions or "" end
    if type(primary.professions) ~= "table" or #primary.professions == 0 then primary.professions = duplicate.professions or {} end
end

function LL:MergeDuplicatePlayers()
    local names, known, localName = {}, {}, self:PlayerName()
    for name in pairs(self.db.players) do table.insert(names, name) end
    table.sort(names)
    for _, name in ipairs(names) do
        local identity = self:PlayerIdentityKey(name)
        local existingName = known[identity]
        if existingName then
            if name == localName then
                self:MergePlayerRecords(self.db.players[name], self.db.players[existingName])
                self.db.players[existingName], known[identity] = nil, name
            else
                self:MergePlayerRecords(self.db.players[existingName], self.db.players[name])
                self.db.players[name] = nil
            end
        else
            known[identity] = name
        end
    end
end

function LL:GetGuildName()
    local guildName = GetGuildInfo and GetGuildInfo("player")
    if type(guildName) == "string" and guildName ~= "" then return guildName end
end

function LL:GetGuildKey(guildName)
    local realmName = GetRealmName and GetRealmName() or ""
    return guildName .. "@" .. realmName
end

function LL:IsLagomMember()
    return self:GetGuildName() ~= nil
end

function LL:Print(message)
    DEFAULT_CHAT_FRAME:AddMessage("|cffc69b6dLagom Ledger:|r " .. message)
end

function LL:CompareRelease(release)
    if not release or release == "" then return -1 end
    local function parts(value)
        local major, minor, patch = value:match("^(%d+)%.(%d+)%.?(%d*)$")
        return tonumber(major) or 0, tonumber(minor) or 0, tonumber(patch) or 0
    end
    local currentMajor, currentMinor, currentPatch = parts(self.RELEASE)
    local remoteMajor, remoteMinor, remotePatch = parts(release)
    if remoteMajor ~= currentMajor then return remoteMajor < currentMajor and -1 or 1 end
    if remoteMinor ~= currentMinor then return remoteMinor < currentMinor and -1 or 1 end
    if remotePatch ~= currentPatch then return remotePatch < currentPatch and -1 or 1 end
    return 0
end

function LL:IsOlderRelease(release)
    return self:CompareRelease(release) < 0
end

function LL:IsNewerRelease(release)
    return self:CompareRelease(release) > 0
end

function LL:NotifyOutdatedMember(sender, release)
    if self.versionNoticeSent[sender] then return end
    if self.loginUpdateCheck and self:IsNewerRelease(release) then
        self.versionNoticeSent[sender] = true
        self.versionNoticeSent["update:" .. release] = true
        self:Print("Update available: " .. sender .. " uses Lagom Ledger " .. release .. "; you use " .. self.RELEASE .. ".")
        return
    end
    if not release or release == "" or not self:IsOlderRelease(release) then return end
    self.versionNoticeSent[sender] = true
    self:Broadcast("UPDATE_AVAILABLE", { target = sender, release = self.RELEASE })
end

function LL:InitializeGuildDatabase(db)
    db.players = db.players or {}
    db.bounties = db.bounties or {}
    db.nextBountyId = db.nextBountyId or 1
    db.casinoStats = db.casinoStats or {}
    db.casinoHistory = db.casinoHistory or {}
    db.casinoProcessedGames = db.casinoProcessedGames or {}
    db.nextCasinoId = db.nextCasinoId or 1
    db.casinoSettlements = db.casinoSettlements or {}
    db.nemeses = db.nemeses or {}
    db.minimap = db.minimap or { angle = 225 }
end

function LL:EnsureDatabase()
    local guildName = self:GetGuildName()
    if not guildName then
        self.GUILD_NAME = nil
        self.db = nil
        return false
    end
    local guildKey = self:GetGuildKey(guildName)
    LagomLedgerDB = LagomLedgerDB or {}
    if not LagomLedgerDB.guilds then
        local legacy = LagomLedgerDB
        LagomLedgerDB = { schemaVersion = 2, guilds = { [guildKey] = legacy } }
    end
    LagomLedgerDB.schemaVersion = 2
    LagomLedgerDB.guilds[guildKey] = LagomLedgerDB.guilds[guildKey] or {}
    self.GUILD_NAME = guildName
    self.db = LagomLedgerDB.guilds[guildKey]
    self:InitializeGuildDatabase(self.db)
    self:MergeDuplicatePlayers()
    self:EnsurePlayer(self:PlayerName())
    return true
end

function LL:EnsurePlayer(name)
    local identity = self:PlayerIdentityKey(name)
    local playerName = name
    for storedName in pairs(self.db.players) do
        if self:PlayerIdentityKey(storedName) == identity then
            playerName = storedName
            break
        end
    end
    local player = self.db.players[playerName]
    if not player then
        player = { kills = 0, deaths = 0, killStreak = 0, longestLife = 0, professions = {}, class = "", level = 0, primaryProfessions = "", secondaryProfessions = "", updatedAt = now() }
        self.db.players[playerName] = player
    end
    player.killStreak = tonumber(player.killStreak) or 0
    player.longestLife = tonumber(player.longestLife) or 0
    self:EnsureWeeklyStats(player)
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

function LL:ProfilePayload(player)
    return {
        name = self:PlayerName(), kills = player.kills, deaths = player.deaths, killStreak = player.killStreak,
        aliveSince = player.aliveSince, longestLife = player.longestLife, professions = player.professions,
        updatedAt = player.updatedAt, release = self.RELEASE, class = player.class, level = player.level,
        primaryProfessions = player.primaryProfessions, secondaryProfessions = player.secondaryProfessions,
        weeklyReset = player.weeklyReset, weeklyKills = player.weeklyKills, weeklyDeaths = player.weeklyDeaths,
    }
end

function LL:EnsureLocalLife(player)
    player.lifeTracked = true
    if not player.aliveSince and not UnitIsDeadOrGhost("player") then player.aliveSince = now() end
end

function LL:RefreshLocalProfile()
    if not self.db then return end
    local player = self:EnsurePlayer(self:PlayerName())
    self:EnsureLocalLife(player)
    player.professions = self:GetProfessions()
    player.updatedAt = now()
    self:Broadcast("PROFILE", self:ProfilePayload(player))
    self:RefreshUI()
end

function LL:AnnounceLevelUp(level)
    if not self.db then return end
    local player = self:EnsurePlayer(self:PlayerName())
    player.level = tonumber(level) or UnitLevel("player") or player.level or 0
    player.updatedAt = now()
    local payload = { name = self:PlayerName(), level = player.level }
    self:Print(payload.name .. " reached level " .. payload.level .. "!")
    self:Broadcast("LEVEL_UP", payload)
    self:RefreshLocalProfile()
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
        return table.concat({ self:Escape(payload.name), payload.kills or 0, payload.deaths or 0, table.concat(professions, ","), payload.updatedAt or now(), self:Escape(payload.release), self:Escape(payload.class), payload.level or 0, self:Escape(payload.primaryProfessions), self:Escape(payload.secondaryProfessions), payload.killStreak or 0, payload.aliveSince or 0, payload.longestLife or 0, payload.weeklyReset or 0, payload.weeklyKills or 0, payload.weeklyDeaths or 0 }, ";")
    elseif kind == "LEVEL_UP" then
        return table.concat({ self:Escape(payload.name), payload.level or 0 }, ";")
    elseif kind == "UPDATE_AVAILABLE" then
        return table.concat({ self:Escape(payload.target), self:Escape(payload.release) }, ";")
    elseif kind == "PVP_DEATH" then
        return table.concat({ self:Escape(payload.victim), self:Escape(payload.killer) }, ";")
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
    elseif kind == "CASINO_GAME_DEBT_PAID" then
        return table.concat({ self:Escape(payload.id), self:Escape(payload.winner), self:Escape(payload.loser), payload.amount, self:Escape(payload.paidBy), payload.paidAt or now() }, ";")
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
        return kind, { name = self:Unescape(fields[1]), kills = tonumber(fields[2]), deaths = tonumber(fields[3]), professions = professions, updatedAt = tonumber(fields[5]), release = self:Unescape(fields[6]), class = self:Unescape(fields[7]), level = tonumber(fields[8]), primaryProfessions = self:Unescape(fields[9]), secondaryProfessions = self:Unescape(fields[10]), killStreak = tonumber(fields[11]), aliveSince = tonumber(fields[12]), longestLife = tonumber(fields[13]), weeklyReset = tonumber(fields[14]), weeklyKills = tonumber(fields[15]), weeklyDeaths = tonumber(fields[16]) }
    elseif kind == "LEVEL_UP" then
        return kind, { name = self:Unescape(fields[1]), level = tonumber(fields[2]) }
    elseif kind == "UPDATE_AVAILABLE" then
        return kind, { target = self:Unescape(fields[1]), release = self:Unescape(fields[2]) }
    elseif kind == "PVP_DEATH" then
        return kind, { victim = self:Unescape(fields[1]), killer = self:Unescape(fields[2]) }
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
    elseif kind == "CASINO_GAME_DEBT_PAID" then
        return kind, { id = self:Unescape(fields[1]), winner = self:Unescape(fields[2]), loser = self:Unescape(fields[3]), amount = tonumber(fields[4]), paidBy = self:Unescape(fields[5]), paidAt = tonumber(fields[6]) }
    end
end

function LL:RecordDeath(pvpCombat)
    if not self.db then return end
    local player = self:EnsurePlayer(self:PlayerName())
    local diedAt, aliveSince = now(), tonumber(player.aliveSince)
    if aliveSince and aliveSince <= diedAt then player.longestLife = math.max(player.longestLife or 0, diedAt - aliveSince) end
    player.deaths = player.deaths + 1
    player.weeklyDeaths = (player.weeklyDeaths or 0) + 1
    player.aliveSince = nil
    player.lifeTracked = true
    if pvpCombat then player.killStreak = 0 end
    player.updatedAt = diedAt
    self:Broadcast("PROFILE", self:ProfilePayload(player))
    self:RefreshUI()
end

function LL:RecordNemesisDeath(victim, killer)
    if not self.db or type(killer) ~= "string" or killer == "" then return end
    local victimKey = self:PlayerIdentityKey(victim)
    if victimKey == "" then return end
    self.db.nemeses[victimKey] = self.db.nemeses[victimKey] or {}
    self.db.nemeses[victimKey][killer] = (self.db.nemeses[victimKey][killer] or 0) + 1
end

function LL:TopNemesis(victim)
    local nemesis, kills
    for killer, count in pairs((self.db and self.db.nemeses[self:PlayerIdentityKey(victim)]) or {}) do
        if not kills or count > kills or (count == kills and killer < nemesis) then nemesis, kills = killer, count end
    end
    return nemesis, kills
end

function LL:TopGuildNemesis()
    local totals, nemesis, kills = {}, nil, nil
    for _, victimKills in pairs((self.db and self.db.nemeses) or {}) do
        for killer, count in pairs(victimKills) do totals[killer] = (totals[killer] or 0) + count end
    end
    for killer, count in pairs(totals) do
        if not kills or count > kills or (count == kills and killer < nemesis) then nemesis, kills = killer, count end
    end
    return nemesis, kills
end

function LL:AnnouncePvpDeath(lastOpponent)
    if not self.db then return end
    local payload = { victim = self:PlayerName(), killer = lastOpponent or "" }
    self:RecordNemesisDeath(payload.victim, payload.killer)
    local message = payload.victim .. " died in PvP"
    if payload.killer ~= "" then message = message .. " to " .. payload.killer .. " (last observed hostile target)" end
    self:Print(message .. ".")
    self:Broadcast("PVP_DEATH", payload)
end

function LL:StartNewLife()
    if not self.db then return end
    local player = self:EnsurePlayer(self:PlayerName())
    if player.aliveSince then return end
    player.aliveSince, player.updatedAt, player.lifeTracked = now(), now(), true
    self:Broadcast("PROFILE", self:ProfilePayload(player))
    self:RefreshUI()
end

function LL:NotePvpCombat()
    if self.inCombat and UnitExists("target") and UnitIsPlayer("target") and UnitCanAttack("player", "target") then
        self.lastPvpCombatAt = now()
        local opponent = UnitName("target")
        -- shortcut: a local target is the only killer hint Forever exposes; replace it if a supported killer event becomes available.
        if type(opponent) == "string" and (not issecretvalue or not issecretvalue(opponent)) then self.lastPvpOpponent = opponent end
    end
end

function LL:WasRecentPvpCombat()
    return self.lastPvpCombatAt and now() - self.lastPvpCombatAt <= 45
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
        player.killStreak = tonumber(payload.killStreak) or player.killStreak
        player.longestLife = tonumber(payload.longestLife) or player.longestLife
        if payload.weeklyReset == self:GetWeeklyResetStart() then
            player.weeklyReset = payload.weeklyReset
            player.weeklyKills = tonumber(payload.weeklyKills) or 0
            player.weeklyDeaths = tonumber(payload.weeklyDeaths) or 0
        else
            self:EnsureWeeklyStats(player)
        end
        if payload.aliveSince ~= nil then
            player.aliveSince = payload.aliveSince > 0 and payload.aliveSince or nil
            player.lifeTracked = true
        end
        self:NotifyOutdatedMember(sender, payload.release)
    elseif kind == "LEVEL_UP" and payload.name and payload.level then
        local player = self:EnsurePlayer(payload.name)
        player.level = payload.level
        self:Print(payload.name .. " reached level " .. payload.level .. "!")
    elseif kind == "UPDATE_AVAILABLE" and payload.target and payload.release and self:PlayerIdentityKey(payload.target) == self:PlayerIdentityKey(self:PlayerName()) and self:IsNewerRelease(payload.release) then
        local noticeKey = "update:" .. payload.release
        if not self.versionNoticeSent[noticeKey] then
            self.versionNoticeSent[noticeKey] = true
            self:Print("Update available: Lagom Ledger " .. payload.release .. " is available.")
        end
    elseif kind == "PVP_DEATH" and payload.victim then
        self:RecordNemesisDeath(payload.victim, payload.killer)
        local message = payload.victim .. " died in PvP"
        if payload.killer and payload.killer ~= "" then message = message .. " to " .. payload.killer .. " (last observed hostile target)" end
        self:Print(message .. ".")
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
        self.loginUpdateCheck = true
        if C_Timer and C_Timer.After then C_Timer.After(20, function() LL.loginUpdateCheck = false end) end
        self.inCombat = UnitAffectingCombat and UnitAffectingCombat("player") or false
        self:NotePvpCombat()
        if self.RegisterEllesmerePlugin then self:RegisterEllesmerePlugin() end
        if self.BuildMinimapButton then self:BuildMinimapButton() end
        self:RefreshLocalProfile()
        self:Broadcast("REQUEST_SYNC", {})
    elseif event == "PLAYER_REGEN_DISABLED" and self.db then
        self.inCombat = true
        self:NotePvpCombat()
    elseif event == "PLAYER_REGEN_ENABLED" and self.db then
        self.inCombat = false
    elseif event == "PLAYER_TARGET_CHANGED" and self.db then
        self:NotePvpCombat()
    elseif event == "PLAYER_DEAD" and self.db then
        local pvpCombat = self:WasRecentPvpCombat()
        if pvpCombat then self:AnnouncePvpDeath(self.lastPvpOpponent) end
        self:RecordDeath(pvpCombat)
        self.inCombat, self.lastPvpCombatAt, self.lastPvpOpponent = false, nil, nil
    elseif event == "PLAYER_ALIVE" and self.db then
        self:StartNewLife()
    elseif event == "CHAT_MSG_ADDON" and self.db then
        self:OnComm(...)
    elseif event == "CHAT_MSG_SYSTEM" and self.db and self.HandleRollMessage then
        self:HandleRollMessage(...)
    elseif event == "SKILL_LINES_CHANGED" and self.db then
        self:RefreshLocalProfile()
    elseif event == "PLAYER_LEVEL_UP" and self.db then
        self:AnnounceLevelUp(...)
    elseif event == "PLAYER_GUILD_UPDATE" then
        local unit = ...
        if unit == "player" then
            self:EnsureDatabase()
            if self.db then
                if self.UpdateMinimapButton then self:UpdateMinimapButton() end
                self:RefreshLocalProfile()
                self:Broadcast("REQUEST_SYNC", {})
            else
                self:RefreshUI()
            end
        end
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
    elseif command == "reset" then
        LL:ResetBoardSize()
    elseif command == "settings" and LL.OpenEllesmereSettings then
        LL:OpenEllesmereSettings()
    elseif command == "sync" then
        LL:RefreshLocalProfile()
    elseif command == "help" then
        LL:Print("/lagom opens the board; /lagom casino opens the casino; /lagom reset restores the window size.")
    else
        LL:ToggleUI()
    end
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("PLAYER_DEAD")
frame:RegisterEvent("PLAYER_ALIVE")
frame:RegisterEvent("PLAYER_REGEN_DISABLED")
frame:RegisterEvent("PLAYER_REGEN_ENABLED")
frame:RegisterEvent("PLAYER_TARGET_CHANGED")
frame:RegisterEvent("CHAT_MSG_ADDON")
frame:RegisterEvent("CHAT_MSG_SYSTEM")
frame:RegisterEvent("SKILL_LINES_CHANGED")
frame:RegisterEvent("PLAYER_LEVEL_UP")
frame:RegisterEvent("PLAYER_GUILD_UPDATE")
frame:SetScript("OnEvent", function(_, event, ...) LL:OnEvent(event, ...) end)
