-- Compatibility bridge for the supplied Lagom addon. It reuses Lagom Ledger's
-- saved data and native protocol while translating the older LagomGuild traffic.
local _, LL = ...

LL.LEGACY_COMM_PREFIX = "LagomGuild"

local function now()
    return GetServerTime and GetServerTime() or time()
end

local function isSecret(value)
    return issecretvalue ~= nil and issecretvalue(value)
end

local function shortName(name)
    return type(name) == "string" and (name:match("^([^%-%s]+)") or name) or ""
end

local function fold(value)
    value = strlower(value or "")
    return value:gsub("\195([\128-\150\152-\158])", function(character)
        return "\195" .. string.char(character:byte() + 32)
    end)
end

local function clean(value, maxBytes)
    value = strtrim((value or ""):gsub("[;|\n\r]", " "))
    if #value > maxBytes then
        value = value:sub(1, maxBytes):gsub("[\192-\255][\128-\191]*$", "")
    end
    return value
end

function LL:LegacyNamesMatch(left, right)
    return fold(shortName(left)) == fold(shortName(right))
end

function LL:NormalizeBountyTarget(name)
    return ((fold(strtrim(name or "")):gsub("%s", "")))
end

function LL:LegacyPlayerKey(name)
    for storedName in pairs(self.db.players) do
        if self:LegacyNamesMatch(storedName, name) then return storedName end
    end
    return shortName(name)
end

function LL:LegacyGuildNames()
    local names = {}
    local function add(name)
        if type(name) == "string" and name ~= "" and not isSecret(name) then table.insert(names, name) end
    end
    if GetGuildInfo then
        local ok, name = pcall(GetGuildInfo, "player")
        if ok then add(name) end
    end
    if C_Club and C_Club.GetGuildClubId and C_Club.GetClubInfo then
        local ok, id = pcall(C_Club.GetGuildClubId)
        if ok and id then
            local found, info = pcall(C_Club.GetClubInfo, id)
            if found and type(info) == "table" then add(info.name) end
        end
    end
    return names
end

local originalIsLagomMember = LL.IsLagomMember
function LL:IsLagomMember()
    if originalIsLagomMember(self) then return true end
    for _, guildName in ipairs(self:LegacyGuildNames()) do
        if fold(guildName) == fold(self.GUILD_NAME) then return true end
    end
    return false
end

local function lifetimeKills()
    if not GetPVPLifetimeStats then return nil end
    local ok, kills = pcall(GetPVPLifetimeStats)
    if ok and type(kills) == "number" and not isSecret(kills) then return kills end
end

local function lifetimeDeaths()
    if not GetStatistic then return nil end
    local ok, deaths = pcall(GetStatistic, 60)
    if ok and not isSecret(deaths) then return tonumber(deaths) end
end

function LL:CollectLegacyProfessions()
    local primary, secondary = {}, {}
    local function add(destination, name, rank)
        if type(name) == "string" and name ~= "" then
            table.insert(destination, clean(name:gsub("[,:]", ""), 30) .. ":" .. (tonumber(rank) or 0))
        end
    end
    if GetProfessions and GetProfessionInfo then
        local professions = { GetProfessions() }
        for index = 1, 5 do
            if professions[index] then
                local ok, name, _, rank = pcall(GetProfessionInfo, professions[index])
                if ok then add(index <= 2 and primary or secondary, name, rank) end
            end
        end
    end
    return table.concat(primary, ","), table.concat(secondary, ",")
end

function LL:CollectReferenceProfile()
    if not self.db then return end
    local player = self:EnsurePlayer(self:PlayerName())
    local _, class = UnitClass("player")
    local primary, secondary = self:CollectLegacyProfessions()
    player.class = class or player.class or ""
    player.level = UnitLevel("player") or player.level or 0
    player.primaryProfessions = primary
    player.secondaryProfessions = secondary
    local kills, deaths = lifetimeKills(), lifetimeDeaths()
    if kills then player.kills = math.max(player.kills or 0, kills) end
    if deaths then player.deaths = math.max(player.deaths or 0, deaths) end
    return player
end

function LL:QueueLegacyMessage(key, message)
    if not self:IsLagomMember() then return end
    self.legacyOutKeys = self.legacyOutKeys or {}
    self.legacyOutMessages = self.legacyOutMessages or {}
    if not self.legacyOutMessages[key] then table.insert(self.legacyOutKeys, key) end
    self.legacyOutMessages[key] = message
end

function LL:PumpLegacyMessages()
    if not self:IsLagomMember() or not C_ChatInfo or not self.legacyOutKeys or #self.legacyOutKeys == 0 then return end
    local key = self.legacyOutKeys[1]
    local ok, result = pcall(C_ChatInfo.SendAddonMessage, self.LEGACY_COMM_PREFIX, self.legacyOutMessages[key], "GUILD")
    if ok and result ~= false and (type(result) ~= "number" or result == 0) then
        table.remove(self.legacyOutKeys, 1)
        self.legacyOutMessages[key] = nil
    end
end

function LL:SendLegacyStats()
    local player = self:CollectReferenceProfile()
    if not player then return end
    self:QueueLegacyMessage("S", ("S;%s;%d;%d;%d;%s;%s"):format(
        clean(player.class, 30), tonumber(player.level) or 0, tonumber(player.kills) or 0,
        tonumber(player.deaths) or 0, clean(player.primaryProfessions, 120), clean(player.secondaryProfessions, 120)))
end

function LL:LegacyBountyStatus(bounty)
    if bounty.canceled then return "X" end
    return bounty.active and "O" or "C"
end

function LL:SendLegacyBounty(bounty)
    if not bounty or not bounty.id then return end
    local updatedAt = bounty.updatedAt or bounty.completedAt or bounty.createdAt or now()
    self:QueueLegacyMessage("B:" .. bounty.id, ("B;%s;%s;%s;%d;%s;%s;%d;%s"):format(
        clean(bounty.id, 70), clean(bounty.target, 40), clean(shortName(bounty.postedBy), 40),
        tonumber(bounty.createdAt) or now(), self:LegacyBountyStatus(bounty),
        clean(shortName(bounty.completedBy), 40), tonumber(updatedAt) or now(), clean(bounty.note, 90)))
end

function LL:SendLegacySnapshot()
    self:SendLegacyStats()
    for _, bounty in ipairs(self.db.bounties) do self:SendLegacyBounty(bounty) end
    self:QueueLegacyMessage("D", "D")
end

local originalRefreshLocalProfile = LL.RefreshLocalProfile
function LL:RefreshLocalProfile()
    self:CollectReferenceProfile()
    originalRefreshLocalProfile(self)
    self:SendLegacyStats()
end

local originalRecordDeath = LL.RecordDeath
function LL:RecordDeath(pvpCombat)
    originalRecordDeath(self, pvpCombat)
    self:CollectReferenceProfile()
    self:SendLegacyStats()
end

local originalAddBounty = LL.AddBounty
function LL:AddBounty(target, note)
    local added = originalAddBounty(self, target, note)
    if added then
        local bounty = self.db.bounties[#self.db.bounties]
        bounty.updatedAt = now()
        self:SendLegacyBounty(bounty)
        self:Print("Bounty posted on " .. bounty.target .. ".")
    end
    return added
end

local originalMarkBountyComplete = LL.MarkBountyComplete
function LL:MarkBountyComplete(bounty)
    originalMarkBountyComplete(self, bounty)
    bounty.updatedAt = bounty.completedAt or now()
    bounty.canceled = nil
    self:SendLegacyBounty(bounty)
end

function LL:RemoveBounty(id)
    for _, bounty in ipairs(self.db.bounties) do
        if bounty.id == id and bounty.active and self:LegacyNamesMatch(bounty.postedBy, self:PlayerName()) then
            bounty.active, bounty.canceled, bounty.completedBy = false, true, nil
            bounty.completedAt, bounty.updatedAt = now(), now()
            self:Broadcast("BOUNTY_COMPLETE", { id = bounty.id, completedBy = "", completedAt = bounty.completedAt, canceled = true })
            self:SendLegacyBounty(bounty)
            self:RefreshUI()
            return true
        end
    end
    return false
end

function LL:Members()
    local members = {}
    for name, player in pairs(self.db.players) do
        self:EnsureWeeklyStats(player)
        table.insert(members, { name = name, class = player.class or "", level = player.level or 0, kills = player.kills or 0,
            deaths = player.deaths or 0, killStreak = player.killStreak or 0, aliveSince = player.aliveSince, longestLife = player.longestLife or 0, lifeTracked = player.lifeTracked,
            weeklyKills = player.weeklyKills or 0, weeklyDeaths = player.weeklyDeaths or 0,
            primaryProfessions = player.primaryProfessions or "", secondaryProfessions = player.secondaryProfessions or "",
            professions = player.professions or {} })
    end
    return members
end

function LL:Bounties()
    local bounties = {}
    for _, bounty in ipairs(self.db.bounties) do
        if not bounty.canceled then table.insert(bounties, bounty) end
    end
    table.sort(bounties, function(left, right)
        if left.active ~= right.active then return left.active end
        return (left.updatedAt or left.createdAt or 0) > (right.updatedAt or right.createdAt or 0)
    end)
    return bounties
end

function LL:PostBounty(target, note)
    return self:AddBounty(target, note)
end

function LL:MergeLegacyBounty(data)
    local incomingUpdated = math.min(tonumber(data.updatedAt) or now(), now() + 300)
    for _, bounty in ipairs(self.db.bounties) do
        if bounty.id == data.id then
            if (bounty.updatedAt or bounty.createdAt or 0) >= incomingUpdated then return end
            bounty.target, bounty.postedBy, bounty.createdAt = data.target, data.postedBy, data.createdAt
            bounty.note, bounty.updatedAt, bounty.canceled = data.note, incomingUpdated, data.status == "X"
            bounty.active = data.status == "O"
            bounty.completedBy = data.status == "C" and data.completedBy or nil
            bounty.completedAt = bounty.active and nil or incomingUpdated
            self:RefreshUI()
            return
        end
    end
    table.insert(self.db.bounties, {
        id = data.id, target = data.target, postedBy = data.postedBy, createdAt = data.createdAt,
        note = data.note, updatedAt = incomingUpdated, active = data.status == "O",
        canceled = data.status == "X", completedBy = data.status == "C" and data.completedBy or nil,
        completedAt = data.status == "O" and nil or incomingUpdated,
    })
    if now() - incomingUpdated < 120 then
        if data.status == "O" then
            self:Print(("%s posted a bounty on |cffff5555%s|r%s"):format(data.postedBy, data.target, data.note ~= "" and (": " .. data.note) or "."))
        elseif data.status == "C" then
            self:Print(("%s claimed the bounty on |cffff5555%s|r!"):format(data.completedBy or "?", data.target))
        end
    end
    self:RefreshUI()
end

function LL:ReceiveLegacyMessage(message, sender)
    if type(message) ~= "string" or isSecret(message) or isSecret(sender) then return end
    local senderName = shortName(Ambiguate and Ambiguate(sender, "short") or sender)
    if senderName == "" or self:LegacyNamesMatch(senderName, self:PlayerName()) then return end
    local kind, a, b, c, d, e, f, g, h = strsplit(";", message)
    if kind == "S" then
        local player = self:EnsurePlayer(self:LegacyPlayerKey(senderName))
        player.class, player.level = a or "", tonumber(b) or 0
        player.kills, player.deaths = tonumber(c) or 0, tonumber(d) or 0
        player.primaryProfessions, player.secondaryProfessions = e or "", f or ""
        player.professions, player.updatedAt = {}, now()
        for profession in (player.primaryProfessions .. "," .. player.secondaryProfessions):gmatch("([^,:]+):%d+") do
            table.insert(player.professions, profession)
        end
        self:RefreshUI()
    elseif kind == "B" then
        local created, updated = tonumber(d), tonumber(g)
        if a and a ~= "" and b and b ~= "" and created and updated and (e == "O" or e == "C" or e == "X") then
            self:MergeLegacyBounty({ id = a, target = b, postedBy = c or "?", createdAt = created, status = e,
                completedBy = f ~= "" and f or nil, updatedAt = updated, note = h or "" })
        end
    elseif kind == "H" then
        local delay = 1 + math.random() * 4
        if C_Timer and C_Timer.After then C_Timer.After(delay, function() LL:SendLegacySnapshot() end) else self:SendLegacySnapshot() end
    end
end

function LL:PruneReferenceBounties()
    local cutoff = now()
    for index = #self.db.bounties, 1, -1 do
        local bounty = self.db.bounties[index]
        local age = cutoff - (bounty.updatedAt or bounty.completedAt or bounty.createdAt or 0)
        if (bounty.canceled and age > 7 * 86400) or age > 30 * 86400 then table.remove(self.db.bounties, index) end
    end
end

function LL:PruneReferenceMembers()
    if not self:IsLagomMember() or not GetNumGuildMembers or not GetGuildRosterInfo then return end
    local total = GetNumGuildMembers()
    if not total or total == 0 then return end
    local roster = {}
    for index = 1, total do
        local name = GetGuildRosterInfo(index)
        if name then roster[fold(shortName(name))] = true end
    end
    if not roster[fold(shortName(self:PlayerName()))] then return end
    for name in pairs(self.db.players) do
        if not roster[fold(shortName(name))] then self.db.players[name] = nil end
    end
end

function LL:OpenReferenceBountyFor(name)
    for _, bounty in ipairs(self.db.bounties) do
        if bounty.active and self:BountyTargetMatches(bounty.target, name) then return bounty end
    end
end

function LL:AlertReferenceBounty(bounty)
    local key, timestamp = fold(bounty.target), GetTime()
    self.referenceBountyAlerts = self.referenceBountyAlerts or {}
    if self.referenceBountyAlerts[key] and timestamp - self.referenceBountyAlerts[key] < 60 then return end
    self.referenceBountyAlerts[key] = timestamp
    local text = ("Bounty target nearby: %s (posted by %s)"):format(bounty.target, bounty.postedBy)
    if UIErrorsFrame and UIErrorsFrame.AddMessage then UIErrorsFrame:AddMessage(text, 1, 0.3, 0.3) end
    self:Print("|cffff5555" .. text .. "|r")
    if PlaySound and SOUNDKIT and SOUNDKIT.RAID_WARNING then pcall(PlaySound, SOUNDKIT.RAID_WARNING) end
end

function LL:TryReferenceBountyCompletion()
    if not self.referenceKillCredit or GetTime() - self.referenceKillCredit > 12 then return end
    for _, bounty in ipairs(self.db.bounties) do
        local seenAt = self.referenceRecentDeaths and self.referenceRecentDeaths[fold(shortName(bounty.target))]
        if bounty.active and seenAt and math.abs(seenAt - self.referenceKillCredit) < 12 then
            self:MarkBountyComplete(bounty)
            self:Print(("You claimed the bounty on |cffff5555%s|r, posted by %s!"):format(bounty.target, bounty.postedBy))
            if PlaySound and SOUNDKIT and SOUNDKIT.UI_70_ARTIFACT_FORGE_TRAIT_FIRSTTRAIT then
                pcall(PlaySound, SOUNDKIT.UI_70_ARTIFACT_FORGE_TRAIT_FIRSTTRAIT)
            end
        end
    end
end

function LL:ScanReferenceUnit(unit)
    if not self:IsLagomMember() or not UnitExists(unit) or not UnitIsPlayer(unit) or not UnitIsEnemy("player", unit) then return end
    local name = UnitName(unit)
    if type(name) ~= "string" or isSecret(name) then return end
    if UnitIsDeadOrGhost(unit) then
        self.referenceRecentDeaths = self.referenceRecentDeaths or {}
        self.referenceRecentDeaths[fold(shortName(name))] = GetTime()
        if unit == "target" or unit == "mouseover" then self:RecordObservedPvpKill(name) end
        self:TryReferenceBountyCompletion()
    else
        local bounty = self:OpenReferenceBountyFor(name)
        if bounty then self:AlertReferenceBounty(bounty) end
    end
end

function LL:RecordObservedPvpKill(name)
    if not self.referenceKillCredit or GetTime() - self.referenceKillCredit > 12 or self.referenceKillVictimAt == self.referenceKillCredit then return end
    -- shortcut: one observed target per honorable-kill credit; use a combat-log killer API if Forever exposes one.
    self.referenceKillVictimAt = self.referenceKillCredit
    self:AnnouncePvpKill(name)
end

function LL:RecordReferenceKillCredit()
    self.referenceKillCredit = GetTime()
    pcall(self.ScanReferenceUnit, self, "target")
    pcall(self.ScanReferenceUnit, self, "mouseover")
    self:TryReferenceBountyCompletion()
    if C_Timer and C_Timer.After then
        C_Timer.After(1.5, function()
            pcall(LL.ScanReferenceUnit, LL, "target")
            LL:TryReferenceBountyCompletion()
        end)
    end
end

function LL:CheckReferenceKills()
    if not self.db then return end
    local kills = lifetimeKills()
    if not kills then return end
    local player = self:EnsurePlayer(self:PlayerName())
    if player.lastHonorableKills and kills > player.lastHonorableKills then
        local gainedKills = kills - player.lastHonorableKills
        player.killStreak = (player.killStreak or 0) + gainedKills
        player.kills = math.max(player.kills or 0, kills)
        player.weeklyKills = (player.weeklyKills or 0) + gainedKills
        player.lastHonorableKills = kills
        self:RecordReferenceKillCredit()
        self:RefreshLocalProfile()
    else
        player.lastHonorableKills = kills
    end
end

function LL:DebugReference()
    local guilds = self:LegacyGuildNames()
    self:Print("Guilds reported: " .. (#guilds > 0 and table.concat(guilds, ", ") or "none"))
    self:Print("Addon active: " .. tostring(self:IsLagomMember()))
    self:Print("Honorable kills: " .. tostring(lifetimeKills()))
    self:Print("Total deaths: " .. tostring(lifetimeDeaths()))
end

local frame = CreateFrame("Frame")
local handlers = {}

function handlers.PLAYER_LOGIN()
    if C_ChatInfo then C_ChatInfo.RegisterAddonMessagePrefix(LL.LEGACY_COMM_PREFIX) end
    LL:PruneReferenceBounties()
    LL:CollectReferenceProfile()
    LL:QueueLegacyMessage("H", "H")
    LL:CheckReferenceKills()
    if not LL.legacyTicker and C_Timer and C_Timer.NewTicker then
        LL.legacyTicker = C_Timer.NewTicker(1.1, function() LL:PumpLegacyMessages() end)
    end
    if not LL.referenceKillTicker and C_Timer and C_Timer.NewTicker then
        LL.referenceKillTicker = C_Timer.NewTicker(5, function() LL:CheckReferenceKills() end)
    end
end

function handlers.PLAYER_ENTERING_WORLD()
    LL:CheckReferenceKills()
    if C_Timer and C_Timer.After then
        for _, delay in ipairs({ 3, 10, 30 }) do
            C_Timer.After(delay, function()
                LL:CheckReferenceKills()
                LL:RefreshLocalProfile()
            end)
        end
    end
    if C_GuildInfo and C_GuildInfo.GuildRoster then pcall(C_GuildInfo.GuildRoster) end
end

function handlers.PLAYER_GUILD_UPDATE(unit)
    if unit ~= "player" then return end
    LL.legacyOutKeys, LL.legacyOutMessages = nil, nil
    LL.referenceRecentDeaths, LL.referenceKillCredit, LL.referenceKillVictimAt = nil, nil, nil
    LL:RefreshLocalProfile()
end

function handlers.GUILD_ROSTER_UPDATE()
    LL:PruneReferenceMembers()
end

function handlers.CHAT_MSG_ADDON(prefix, message, channel, sender)
    if prefix == LL.LEGACY_COMM_PREFIX and channel == "GUILD" and LL:IsLagomMember() then LL:ReceiveLegacyMessage(message, sender) end
end

function handlers.PLAYER_PVP_KILLS_CHANGED()
    LL:CheckReferenceKills()
end

function handlers.PLAYER_TARGET_CHANGED()
    pcall(LL.ScanReferenceUnit, LL, "target")
end

function handlers.UPDATE_MOUSEOVER_UNIT()
    pcall(LL.ScanReferenceUnit, LL, "mouseover")
end

function handlers.NAME_PLATE_UNIT_ADDED(unit)
    pcall(LL.ScanReferenceUnit, LL, unit)
end

function handlers.UNIT_HEALTH(unit)
    if unit == "target" or unit == "focus" or (type(unit) == "string" and unit:sub(1, 9) == "nameplate") then
        pcall(LL.ScanReferenceUnit, LL, unit)
    end
end

function handlers.PLAYER_LEVEL_UP()
    if C_Timer and C_Timer.After then C_Timer.After(1, function() LL:RefreshLocalProfile() end) else LL:RefreshLocalProfile() end
end

for _, event in ipairs({ "PLAYER_LOGIN", "PLAYER_ENTERING_WORLD", "PLAYER_GUILD_UPDATE", "GUILD_ROSTER_UPDATE", "CHAT_MSG_ADDON",
    "PLAYER_PVP_KILLS_CHANGED", "PLAYER_TARGET_CHANGED", "UPDATE_MOUSEOVER_UNIT", "NAME_PLATE_UNIT_ADDED", "UNIT_HEALTH", "PLAYER_LEVEL_UP" }) do
    pcall(frame.RegisterEvent, frame, event)
end
frame:SetScript("OnEvent", function(_, event, ...)
    local handler = handlers[event]
    if handler then handler(...) end
end)

SLASH_LAGOMLEDGER2 = "/lagomledger"
SlashCmdList.LAGOMLEDGER = function(input)
    local command, argument = (input or ""):match("^(%S*)%s*(.-)$")
    command = command:lower()
    if command == "kills" then
        LL:ToggleUI("Kills")
    elseif command == "deaths" then
        LL:ToggleUI("Deaths")
    elseif command == "bounties" then
        LL:ToggleUI("Bounties")
    elseif command == "professions" or command == "profs" then
        LL:ToggleUI("Professions")
    elseif command == "bounty" then
        local name, note = argument:match("^(%S+)%s*(.-)$")
        if name then LL:PostBounty(name, note) else LL:Print("Type /lagom bounty Name reason") end
    elseif command == "debug" then
        LL:DebugReference()
    elseif command == "death" then
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
        LL:SendLegacySnapshot()
    elseif command == "help" then
        LL:Print("/lagom kills | deaths | bounties | professions | casino | reset | settings | sync | debug")
    else
        LL:ToggleUI()
    end
end
