local addonName, LL = ...

LL.GUILD_NAME = nil
LL.COMM_PREFIX = "LAGOMLEDGER"
LL.VERSION_COMM_PREFIX = "LagomLedgerVer"
LL.VERSION = 1
local getAddonMetadata = C_AddOns and C_AddOns.GetAddOnMetadata or GetAddOnMetadata
LL.RELEASE = (getAddonMetadata and getAddonMetadata(addonName, "Version")) or "0.0.0"
LL.versionNoticeSent = {}
LL.VERSION_REMEMBER_FOR = 3 * 24 * 60 * 60

local function now()
    return time()
end

function LL:PlayerName()
    local name, realm = UnitFullName("player")
    return realm and realm ~= "" and (name .. "-" .. realm) or name
end

function LL:PlayerIdentityKey(name)
    return strlower((strtrim(name or ""):match("^([^%-%s]+)") or ""))
end

function LL:FullPlayerIdentityKey(name)
    return strlower(strtrim(name or "")):gsub("%s+", "")
end

function LL:GuildIdentityMatches(left, right)
    if type(left) ~= "string" or type(right) ~= "string" or left == "" or right == "" then return false end
    local leftKey, rightKey = strlower(strtrim(left)), strlower(strtrim(right))
    local leftFull, rightFull = leftKey:find("-", 1, true) ~= nil, rightKey:find("-", 1, true) ~= nil
    if leftFull and rightFull then return leftKey == rightKey end
    if not GetNumGuildMembers or not GetGuildRosterInfo then return false end
    local localRealm = strlower(strtrim(GetRealmName and GetRealmName() or ""))
    local byShort = {}
    for index = 1, GetNumGuildMembers() or 0 do
        local name = GetGuildRosterInfo(index)
        if type(name) == "string" and name ~= "" then
            local full = strlower(strtrim(name))
            local short = full:match("^([^-]+)") or ""
            byShort[short] = byShort[short] or {}
            byShort[short][full] = true
        end
    end
    local function resolve(value)
        local character, realm = value:match("^([^-]+)%-(.+)$")
        if character then
            local fulls = byShort[character]
            if realm ~= localRealm or not fulls then
                for full in pairs(fulls or {}) do if full == value then return full end end
                return nil
            end
            value = character
        end
        local only
        for full in pairs(byShort[value] or {}) do
            if only then return nil end
            only = full
        end
        return only
    end
    local leftResolved, rightResolved = resolve(leftKey), resolve(rightKey)
    return leftResolved ~= nil and leftResolved == rightResolved
end

function LL:NewRecordID(kind)
    local root = LagomLedgerDB
    root.installationNonce = root.installationNonce or (string.format("%08x%08x", math.random(0, 0x7fffffff), math.random(0, 0x7fffffff)))
    local counter = tonumber(root.nextRecordID) or 1
    root.nextRecordID = counter + 1
    return "LL" .. kind .. "-" .. string.format("%x", now()) .. "-" .. root.installationNonce .. "-" .. string.format("%x", counter) .. "-" .. string.format("%04x", math.random(0, 0xffff))
end

local function professionIdentityAliases(name)
    if type(name) ~= "string" or name == "" then return {} end
    local full = strlower(strtrim(name))
    local aliases = { (full:gsub("[%s%-]+", "")) }
    local withoutSuffix = full:gsub("%-[^%-]+$", "")
    if withoutSuffix ~= full then aliases[#aliases + 1] = withoutSuffix:gsub("[%s%-]+", "") end
    return aliases
end

function LL:RefreshProfessionIdentityIndex()
    self.professionRosterIdentityAliases = nil
    if not GetNumGuildMembers or not GetGuildRosterInfo then return false end
    local count = GetNumGuildMembers()
    if not count or count < 1 then return false end
    local index = {}
    local function addAlias(alias, canonical)
        if alias == "" then return end
        if index[alias] == nil then
            index[alias] = canonical
        elseif index[alias] ~= canonical then
            index[alias] = false
        end
    end
    for rosterIndex = 1, count do
        local rosterName = GetGuildRosterInfo(rosterIndex)
        if type(rosterName) == "string" and rosterName ~= "" then
            -- Keep the roster's complete identity, including any realm suffix.
            local canonical = rosterName
            for _, alias in ipairs(professionIdentityAliases(canonical)) do addAlias(alias, canonical) end
            local first = canonical:match("^(%S+)")
            if first then addAlias(professionIdentityAliases(first)[1], canonical) end
        end
    end
    self.professionRosterIdentityAliases = index
    return true
end

function LL:ResolveProfessionIdentity(name)
    if not self.professionRosterIdentityAliases then self:RefreshProfessionIdentityIndex() end
    local index = self.professionRosterIdentityAliases
    if not index then return nil end
    for _, alias in ipairs(professionIdentityAliases(name)) do
        local canonical = index[alias]
        if canonical == false then return nil end
        if canonical then return canonical end
    end
    return nil
end

function LL:ProfessionIdentityMatches(left, right)
    local leftName = self:ResolveProfessionIdentity(left)
    local rightName = self:ResolveProfessionIdentity(right)
    if leftName and rightName then
        return self:FullPlayerIdentityKey(leftName) == self:FullPlayerIdentityKey(rightName), leftName
    end
    if not self.professionRosterIdentityAliases then
        local leftAliases, rightAliases = professionIdentityAliases(left), professionIdentityAliases(right)
        return leftAliases[1] ~= nil and leftAliases[1] == rightAliases[1], left
    end
    return false
end

function LL:MergeProfessionCatalogAliases()
    if not self.db or type(self.db.professionCatalogs) ~= "table" then return end
    if not self:RefreshProfessionIdentityIndex() then return end
    local merged = {}
    for identity, professions in pairs(self.db.professionCatalogs) do
        if type(professions) == "table" then
            for professionID, snapshot in pairs(professions) do
                if type(snapshot) == "table" and type(snapshot.recipes) == "table" then
                    local owner = self:ResolveProfessionIdentity(snapshot.owner or identity) or snapshot.owner or identity
                    local ownerKey = self:FullPlayerIdentityKey(owner)
                    merged[ownerKey] = merged[ownerKey] or {}
                    local target = merged[ownerKey][professionID]
                    if not target then
                        target = {}
                        for field, value in pairs(snapshot) do target[field] = value end
                        target.owner, target.professionID, target.updatedAt, target.recipes = owner, tonumber(professionID) or professionID, tonumber(snapshot.updatedAt) or 0, {}
                        merged[ownerKey][professionID] = target
                    end
                    target.updatedAt = math.max(target.updatedAt or 0, tonumber(snapshot.updatedAt) or 0)
                    if type(snapshot.name) == "string" then target.name = snapshot.name end
                    local recipesByID = {}
                    for _, recipe in ipairs(target.recipes) do recipesByID[tonumber(recipe[1])] = recipe end
                    for _, recipe in ipairs(snapshot.recipes) do
                        local recipeID, itemID = tonumber(recipe[1]), tonumber(recipe[2]) or 0
                        if recipeID and recipeID > 0 then
                            local current = recipesByID[recipeID]
                            if not current then
                                current = { recipeID, itemID }
                                recipesByID[recipeID] = current
                                target.recipes[#target.recipes + 1] = current
                            elseif itemID > 0 then
                                current[2] = itemID
                            end
                        end
                    end
                    table.sort(target.recipes, function(a, b) return a[1] < b[1] end)
                    target.owner = owner
                end
            end
        else
            merged[identity] = professions
        end
    end
    self.db.professionCatalogs = merged
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
    local function parts(value)
        if type(value) ~= "string" or #value > 16 then return end
        local major, minor, patch = value:match("^(%d+)%.(%d+)%.(%d+)$")
        if not major then major, minor = value:match("^(%d+)%.(%d+)$"); patch = "0" end
        major, minor, patch = tonumber(major), tonumber(minor), tonumber(patch)
        if not major or not minor or not patch or major > 99 or minor > 999 or patch > 999 then return end
        return major, minor, patch
    end
    local currentMajor, currentMinor, currentPatch = parts(self.RELEASE)
    local remoteMajor, remoteMinor, remotePatch = parts(release)
    if not currentMajor or not remoteMajor then return end
    if remoteMajor ~= currentMajor then return remoteMajor < currentMajor and -1 or 1 end
    if remoteMinor ~= currentMinor then return remoteMinor < currentMinor and -1 or 1 end
    if remotePatch ~= currentPatch then return remotePatch < currentPatch and -1 or 1 end
    return 0
end

function LL:IsOlderRelease(release)
    return self:CompareRelease(release) == -1
end

function LL:IsNewerRelease(release)
    return self:CompareRelease(release) == 1
end

function LL:ShowUpdateNotice(release)
    local noticeKey = "update:" .. release
    if self.versionNoticeSent[noticeKey] then return end
    self.versionNoticeSent[noticeKey] = true
    self:Print("Update available: Lagom Ledger " .. release .. " is available.")
end

function LL:RememberNewerRelease(release)
    if not self.db or not self:IsNewerRelease(release) then return end
    local known = self.db.newestSeenRelease
    if not known or self:IsNewerRelease(known) then self.db.newestSeenRelease = release end
    if self.db.newestSeenRelease == release then self.db.newestSeenReleaseAt = now() end
end

function LL:CheckSavedRelease()
    if not self.db then return end
    local release, heardAt = self.db.newestSeenRelease, tonumber(self.db.newestSeenReleaseAt)
    if release and heardAt and now() - heardAt < self.VERSION_REMEMBER_FOR and self:IsNewerRelease(release) then
        self:ShowUpdateNotice(release)
    elseif release then
        self.db.newestSeenRelease, self.db.newestSeenReleaseAt = nil, nil
    end
end

function LL:SendVersion(channel)
    if channel ~= "GUILD" or not self:IsLagomMember() or not C_ChatInfo or not C_ChatInfo.SendAddonMessage then return end
    local sentAt = self.versionMessageSentAt or {}
    if sentAt[channel] and GetTime and GetTime() - sentAt[channel] < 10 then return end
    self.versionMessageSentAt = sentAt
    sentAt[channel] = GetTime and GetTime() or 0
    pcall(C_ChatInfo.SendAddonMessage, self.VERSION_COMM_PREFIX, self.RELEASE, channel)
end

function LL:ScheduleVersionReply(channel)
    if channel ~= "GUILD" then return end
    self.pendingVersionReply = self.pendingVersionReply or {}
    if self.pendingVersionReply[channel] then return end
    self.pendingVersionReply[channel] = true
    if C_Timer and C_Timer.After then
        C_Timer.After(1 + math.random() * 4, function()
            if LL.pendingVersionReply and LL.pendingVersionReply[channel] then
                LL.pendingVersionReply[channel] = nil
                LL:SendVersion(channel)
            end
        end)
    else
        self.pendingVersionReply[channel] = nil
        self:SendVersion(channel)
    end
end

function LL:OnVersionMessage(message, channel, sender)
    if channel ~= "GUILD" or self:PlayerIdentityKey(sender) == self:PlayerIdentityKey(self:PlayerName()) then return end
    if self:IsNewerRelease(message) then
        self:RememberNewerRelease(message)
        if self.loginUpdateCheck then self:ShowUpdateNotice(message) end
    elseif self:IsOlderRelease(message) then
        self:ScheduleVersionReply(channel)
    elseif self.pendingVersionReply then
        self.pendingVersionReply[channel] = nil
    end
end

function LL:NotifyOutdatedMember(sender, release)
    if self.versionNoticeSent[sender] then return end
    if self.loginUpdateCheck and self:IsNewerRelease(release) then
        self.versionNoticeSent[sender] = true
        self:RememberNewerRelease(release)
        self:ShowUpdateNotice(release)
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
    db.casinoStatBaseline = db.casinoStatBaseline or {}
    db.casinoHistory = db.casinoHistory or {}
    db.casinoProcessedGames = db.casinoProcessedGames or {}
    db.nextCasinoId = db.nextCasinoId or 1
    db.casinoSettlements = db.casinoSettlements or {}
    db.bountySettlements = db.bountySettlements or {}
    db.balanceTransactions = db.balanceTransactions or {}
    db.nemeses = db.nemeses or {}
    db.vanquished = db.vanquished or {}
    db.professionCatalogs = db.professionCatalogs or {}
    if db.casinoAccountingVersion ~= 2 then
        for name, stats in pairs(db.casinoStats) do
            if not db.casinoStatBaseline[name] then
                db.casinoStatBaseline[name] = { wonGold = stats.wonGold or 0, lostGold = stats.lostGold or 0, games = stats.games or 0 }
            end
        end
        for _, settlements in pairs(db.casinoSettlements) do
            for _, settlement in pairs(settlements) do settlement.baselineIncluded = true end
        end
        db.casinoAccountingVersion = 2
    end
    db.minimap = db.minimap or { angle = 225 }
    for _, bounty in ipairs(db.bounties) do
        if bounty.rewardCopper == nil then bounty.rewardCopper = self:ParseRewardCopper(bounty.note) or 0 end
    end
    for _, settlements in pairs(db.casinoSettlements) do
        for _, settlement in pairs(settlements) do
            settlement.amountCopper = settlement.amountCopper or (tonumber(settlement.amount) or 0) * 10000
            self:RecordBalanceTransaction("casino", settlement)
        end
    end
    for _, settlement in pairs(db.bountySettlements) do self:RecordBalanceTransaction("bounty", settlement) end
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
    LagomLedgerDB.installationNonce = LagomLedgerDB.installationNonce or (string.format("%08x%08x", math.random(0, 0x7fffffff), math.random(0, 0x7fffffff)))
    LagomLedgerDB.nextRecordID = tonumber(LagomLedgerDB.nextRecordID) or 1
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

local professionScanGeneration = 0
local function recipeReagentSlots(schematic)
    if type(schematic) ~= "table" or type(schematic.reagentSlotSchematics) ~= "table" then return nil end
    local slots = {}
    for _, slot in ipairs(schematic.reagentSlotSchematics) do
        if type(slot) ~= "table" then return nil end
        if slot.required ~= false and not slot.hiddenInCraftingForm then
            local quantity = tonumber(slot.quantityRequired)
            local choices, seen = {}, {}
            for _, reagent in ipairs(type(slot.reagents) == "table" and slot.reagents or {}) do
                if type(reagent) == "table" then
                    local itemID, currencyID = tonumber(reagent.itemID), tonumber(reagent.currencyID)
                    local key = itemID and itemID > 0 and ("i" .. itemID) or (currencyID and currencyID > 0 and ("c" .. currencyID))
                    if key and not seen[key] then
                        seen[key] = true
                        choices[#choices + 1] = { key:sub(1, 1), tonumber(key:sub(2)) }
                    end
                end
            end
            if #choices > 0 then
                if not quantity or quantity <= 0 then return nil end
                slots[#slots + 1] = { quantity = quantity, choices = choices }
            elseif quantity and quantity > 0 then
                return nil
            end
        end
    end
    return slots
end

local function sameRecipeReagents(left, right, recipes)
    if type(left) ~= "table" or type(right) ~= "table" then return false end
    for _, recipe in ipairs(recipes) do
        local recipeID = recipe[1]
        local leftSlots, rightSlots = left[recipeID], right[recipeID]
        if type(leftSlots) ~= "table" or type(rightSlots) ~= "table" or #leftSlots ~= #rightSlots then return false end
        for slotIndex, leftSlot in ipairs(leftSlots) do
            local rightSlot = rightSlots[slotIndex]
            if type(rightSlot) ~= "table" or leftSlot.quantity ~= rightSlot.quantity or #leftSlot.choices ~= #rightSlot.choices then return false end
            for choiceIndex, leftChoice in ipairs(leftSlot.choices) do
                local rightChoice = rightSlot.choices[choiceIndex]
                if not rightChoice or leftChoice[1] ~= rightChoice[1] or leftChoice[2] ~= rightChoice[2] then return false end
            end
        end
    end
    return true
end

local function serializeRecipeReagents(snapshot)
    if type(snapshot.reagents) ~= "table" then return nil end
    local records = {}
    for _, recipe in ipairs(snapshot.recipes or {}) do
        local recipeID = tonumber(recipe[1])
        local slots = recipeID and snapshot.reagents[recipeID]
        if type(slots) == "table" then
            if #slots == 0 then
                records[#records + 1] = recipeID .. ",0,0,-"
            else
                if #slots > 64 then return nil end
                for slotIndex, slot in ipairs(slots) do
                    local quantity = tonumber(slot.quantity)
                    if not quantity or quantity < 1 or quantity > 100000 or quantity ~= math.floor(quantity) or type(slot.choices) ~= "table" or #slot.choices < 1 or #slot.choices > 20 then return nil end
                    local choices = {}
                    for _, choice in ipairs(slot.choices) do
                        local id, kind = tonumber(choice[2]), choice[1]
                        if (kind ~= "i" and kind ~= "c") or not id or id < 1 or id ~= math.floor(id) then return nil end
                        choices[#choices + 1] = kind .. id
                    end
                    records[#records + 1] = recipeID .. "," .. slotIndex .. "," .. quantity .. "," .. table.concat(choices, "+")
                end
            end
        end
    end
    local data = table.concat(records, ";")
    if #data == 0 or #data > 15000 then return nil end
    return data
end

function LL:ScanOwnProfession(forceRepublish)
    if not self.db or not self.professionWindowOpen then return false, "profession window is not ready" end
    if not C_TradeSkillUI then return false, "C_TradeSkillUI is unavailable" end
    local api = C_TradeSkillUI
    if type(api.GetAllRecipeIDs) ~= "function" then return false, "GetAllRecipeIDs is unavailable in this client" end
    if type(api.GetRecipeInfo) ~= "function" then return false, "GetRecipeInfo is unavailable in this client" end
    for _, flag in ipairs({ "IsTradeSkillLinked", "IsTradeSkillGuild", "IsTradeSkillGuildMember", "IsNPCCrafting" }) do
        if type(api[flag]) == "function" then
            local ok, value = pcall(api[flag])
            if not ok or value then return false, "the open profession is linked, guild, or NPC data" end
        end
    end
    local ok, base
    if type(api.GetBaseProfessionInfo) == "function" then ok, base = pcall(api.GetBaseProfessionInfo) end
    base = ok and type(base) == "table" and base or nil
    if (not base or not tonumber(base.professionID) or tonumber(base.professionID) < 1 or type(base.professionName) ~= "string") and type(api.GetChildProfessionInfo) == "function" then
        local childOK, child = pcall(api.GetChildProfessionInfo)
        if childOK and child then base = { professionID = child.parentProfessionID, professionName = child.parentProfessionName } end
    end
    local professionID = base and tonumber(base.professionID)
    local name = base and base.professionName
    if not professionID or professionID < 1 or type(name) ~= "string" or name == "" then return false, "profession metadata is unavailable" end
    if not GetProfessions or not GetProfessionInfo then return false, "learned profession lookup is unavailable" end
    local known = false
    local professionIndexes = { GetProfessions() }
    for index = 1, 5 do
        local profIndex = professionIndexes[index]
        if profIndex then
            local profName, _, _, _, _, _, skillLineID = GetProfessionInfo(profIndex)
            if tonumber(skillLineID) == professionID or profName == name then known = true; break end
        end
    end
    if not known then return false, "the open profession does not match a learned profession slot" end
    local idsOK, ids = pcall(api.GetAllRecipeIDs)
    if not idsOK or type(ids) ~= "table" then return false, "recipe ID enumeration failed" end
    local recipes, scanFailed, unreadable, reagents, reagentsComplete = {}, false, 0, {}, type(api.GetRecipeSchematic) == "function"
    for _, recipeID in ipairs(ids) do
        recipeID = tonumber(recipeID)
        if recipeID and recipeID > 0 then
            local infoOK, info = pcall(api.GetRecipeInfo, recipeID)
            if not infoOK or type(info) ~= "table" then scanFailed, unreadable = true, unreadable + 1
            elseif info.learned and not info.isDummyRecipe then
                local itemID = 0
                if type(api.GetRecipeSchematic) == "function" then
                    local schematicOK, schematic = pcall(api.GetRecipeSchematic, recipeID, false)
                    if schematicOK and type(schematic) == "table" then
                        itemID = tonumber(schematic.outputItemID) or 0
                        local slots = recipeReagentSlots(schematic)
                        if slots then reagents[recipeID] = slots else reagentsComplete = false end
                    else
                        reagentsComplete = false
                    end
                end
                recipes[#recipes + 1] = { recipeID, itemID }
            end
        end
    end
    if scanFailed then return false, "recipe details were incomplete (" .. unreadable .. " unreadable)" end
    if #recipes == 0 then return false, "recipe scan found no learned recipes (" .. #ids .. " IDs checked)" end
    if not self.db then return false, "database is unavailable" end
    local character = self:ResolveProfessionIdentity(self:PlayerName()) or self:PlayerName()
    local identity = self:FullPlayerIdentityKey(character)
    local catalogs = self.db.professionCatalogs or {}
    self.db.professionCatalogs = catalogs
    catalogs[identity] = catalogs[identity] or {}
    local old = catalogs[identity][professionID]
    local storedReagents = reagentsComplete and reagents or (old and old.reagents)
    local reagentsChanged = reagentsComplete and not sameRecipeReagents(old and old.reagents, reagents, recipes)
    local changed = not old or old.name ~= name or #old.recipes ~= #recipes
    changed = changed or reagentsChanged
    if old and not changed then
        for index, recipe in ipairs(recipes) do
            local previous = old.recipes[index]
            if not previous or previous[1] ~= recipe[1] or previous[2] ~= recipe[2] then changed = true; break end
        end
    end
    if not changed and not forceRepublish then return true, #recipes .. " learned recipes; unchanged" end
    self.professionRevision = math.max(now(), (old and tonumber(old.updatedAt) or 0) + 0.01)
    local snapshot = { owner = character, professionID = professionID, name = name, recipes = recipes, reagents = storedReagents, updatedAt = self.professionRevision }
    catalogs[identity][professionID] = snapshot
    self:SendProfessionSnapshot(snapshot)
    self:RefreshUI()
    return true, #recipes .. " learned recipes"
end

function LL:ScheduleProfessionScan(delay)
    professionScanGeneration = professionScanGeneration + 1
    local generation = professionScanGeneration
    if C_Timer and C_Timer.After then
        C_Timer.After(delay or 2, function()
            if generation == professionScanGeneration and LL.db and LL.professionWindowOpen then
                local scanned, detail = LL:ScanOwnProfession(LL.professionScanForceRepublish)
                if scanned then
                    LL.professionScanDiagnosticShown = nil
                elseif not LL.professionScanDiagnosticShown then
                    LL.professionScanDiagnosticShown = true
                    LL:Print("Recipe catalog not updated: " .. tostring(detail) .. "; existing data was kept.")
                end
                LL.professionScanForceRepublish = false
            end
        end)
    end
end

function LL:CancelProfessionScan()
    professionScanGeneration = professionScanGeneration + 1
end

function LL:SendProfessionSnapshot(snapshot, channel, target)
    local syncStats = self.professionSyncStats or { queued = 0, sent = 0, failed = 0, dropped = 0, refused = 0, received = 0, applied = 0, rejected = {} }
    self.professionSyncStats = syncStats
    channel = channel or "GUILD"
    if channel ~= "GUILD" and channel ~= "WHISPER" then syncStats.refused = syncStats.refused + 1; return false end
    if channel == "WHISPER" then
        target = self:ResolveProfessionIdentity(target)
        if not target then syncStats.refused = syncStats.refused + 1; return false end
    end
    local pairsList = {}
    for _, recipe in ipairs(snapshot.recipes) do pairsList[#pairsList + 1] = recipe[1] .. "," .. recipe[2] end
    local data = table.concat(pairsList, ";")
    local revision = tostring(snapshot.updatedAt)
    local ownerName = self:ResolveProfessionIdentity(snapshot.owner) or snapshot.owner
    local owner = ownerName:gsub("[|;\r\n]", "")
    local name = snapshot.name:gsub("[|;\r\n]", "")
    local prefix = self.VERSION .. "|PROFESSION_CHUNK|" .. owner .. ";" .. revision .. ";" .. snapshot.professionID .. ";" .. name .. ";"
    local chunkSize = 50
    local total = math.max(1, math.ceil(#data / chunkSize))
    if total > 300 then syncStats.refused = syncStats.refused + 1; return false end
    self.professionSendQueue = self.professionSendQueue or {}
    if #self.professionSendQueue + total > 600 then syncStats.refused = syncStats.refused + 1; return false end
    for index = 1, total do
        local message = prefix .. index .. ";" .. total .. ";" .. data:sub((index - 1) * chunkSize + 1, index * chunkSize)
        if #message > 255 then syncStats.refused = syncStats.refused + 1; return false end
        self.professionSendQueue[#self.professionSendQueue + 1] = { message = message, guildKey = self:GetGuildKey(self.GUILD_NAME), channel = channel, target = target, tries = 0 }
    end
    local queuedMaterialTotal = 0
    local materialData = serializeRecipeReagents(snapshot)
    if snapshot.reagents ~= nil and not materialData then syncStats.refused = syncStats.refused + 1 end
    if materialData then
        local materialTotal = math.ceil(#materialData / chunkSize)
        local materialPrefix = self.VERSION .. "|PROFESSION_MATERIALS_CHUNK|" .. owner .. ";" .. revision .. ";" .. snapshot.professionID .. ";"
        if materialTotal <= 300 and #self.professionSendQueue + materialTotal <= 600 then
            for index = 1, materialTotal do
                local message = materialPrefix .. index .. ";" .. materialTotal .. ";" .. materialData:sub((index - 1) * chunkSize + 1, index * chunkSize)
                if #message > 255 then syncStats.refused = syncStats.refused + 1; return false end
                self.professionSendQueue[#self.professionSendQueue + 1] = { message = message, guildKey = self:GetGuildKey(self.GUILD_NAME), channel = channel, target = target, tries = 0 }
            end
            syncStats.materialChunksQueued = (syncStats.materialChunksQueued or 0) + materialTotal
            queuedMaterialTotal = materialTotal
        else
            syncStats.refused = syncStats.refused + 1
        end
    end
    syncStats.queued = syncStats.queued + total + queuedMaterialTotal
    syncStats.snapshotsQueued = (syncStats.snapshotsQueued or 0) + 1
    if not self.professionSendPumpRunning then
        self.professionSendPumpRunning = true
        local function pump()
            local item = LL.professionSendQueue and LL.professionSendQueue[1]
            if not item then LL.professionSendPumpRunning = false; return end
            if not LL.db or item.guildKey ~= LL:GetGuildKey(LL.GUILD_NAME) then table.remove(LL.professionSendQueue, 1); pump(); return end
            local ok, result = pcall(C_ChatInfo.SendAddonMessage, LL.COMM_PREFIX, item.message, item.channel, item.target)
            local success = ok and (result == nil or result == true or result == 0 or (Enum and Enum.SendAddonMessageResult and result == Enum.SendAddonMessageResult.Success))
            if success then
                syncStats.sent = syncStats.sent + 1
                table.remove(LL.professionSendQueue, 1)
            else
                syncStats.failed = syncStats.failed + 1
                item.tries = item.tries + 1
                if item.tries >= 3 then
                    syncStats.dropped = syncStats.dropped + 1
                    table.remove(LL.professionSendQueue, 1)
                    LL:Print("Recipe catalog send failed; run /lagom sync to retry.")
                end
            end
            C_Timer.After(success and 0.15 or 1, pump)
        end
        if C_Timer and C_Timer.After then
            C_Timer.After(channel == "WHISPER" and (1 + math.random() * 4) or 0.1, pump)
        else
            self.professionSendPumpRunning = false
        end
    end
    return true
end

function LL:RequestProfessionCatalogSync()
    if not self.db or not self:IsLagomMember() then return false end
    local clock = GetTime and GetTime() or now()
    if self.lastProfessionSyncRequest and clock - self.lastProfessionSyncRequest < 30 then
        self:Print("Recipe sync is rate-limited; wait before requesting again.")
        return false
    end
    self.lastProfessionSyncRequest = clock
    self.professionSyncPendingUntil = clock + 120
    self.professionSyncPendingGuildKey = self:GetGuildKey(self.GUILD_NAME)
    if not self:Broadcast("PROFESSION_SYNC_REQUEST", {}) then
        self.professionSyncPendingUntil = nil
        self:Print("Recipe sync request could not be sent.")
        return false
    end
    local stats = self.professionSyncStats or { queued = 0, sent = 0, failed = 0, dropped = 0, refused = 0, received = 0, applied = 0, rejected = {} }
    self.professionSyncStats = stats
    stats.requests = (stats.requests or 0) + 1
    self:Print("Requested saved recipe catalogs from guild members.")
    return true
end

function LL:ReplayProfessionCatalogs(sender)
    local requester = self:ResolveProfessionIdentity(sender)
    if not requester then
        local stats = self.professionSyncStats or { queued = 0, sent = 0, failed = 0, dropped = 0, refused = 0, received = 0, applied = 0, rejected = {} }
        self.professionSyncStats = stats
        stats.rejected.requester = (stats.rejected.requester or 0) + 1
        return false
    end
    local requesterKey = self:FullPlayerIdentityKey(requester)
    self.professionSyncResponsesAt = self.professionSyncResponsesAt or {}
    local previous = self.professionSyncResponsesAt[requesterKey] or 0
    if now() - previous < 30 then return false end
    self.professionSyncResponsesAt[requesterKey] = now()
    self:MergeProfessionCatalogAliases()
    local localName = self:ResolveProfessionIdentity(self:PlayerName()) or self:PlayerName()
    local localKey = self:FullPlayerIdentityKey(localName)
    local sent = 0
    for _, professions in pairs(self.db.professionCatalogs or {}) do
        for _, snapshot in pairs(professions) do
            local owner = self:ResolveProfessionIdentity(snapshot.owner or "")
            if owner and self:FullPlayerIdentityKey(owner) == localKey then
                local replay = { owner = owner, professionID = snapshot.professionID, name = snapshot.name, recipes = snapshot.recipes, reagents = snapshot.reagents, updatedAt = snapshot.updatedAt }
                if self:SendProfessionSnapshot(replay, "WHISPER", requester) then sent = sent + 1 end
            end
        end
    end
    local stats = self.professionSyncStats or { queued = 0, sent = 0, failed = 0, dropped = 0, refused = 0, received = 0, applied = 0, rejected = {} }
    self.professionSyncStats = stats
    stats.replayed = (stats.replayed or 0) + sent
    return sent > 0
end

function LL:PrintProfessionSyncStatus()
    local stats = self.professionSyncStats or {}
    self:Print(("Recipe sync: requests %d, snapshots queued %d, chunks sent %d, failed %d, dropped %d, refused %d, chunks received %d, snapshots applied %d."):format(
        stats.requests or 0, stats.snapshotsQueued or 0, stats.sent or 0, stats.failed or 0, stats.dropped or 0, stats.refused or 0, stats.received or 0, stats.applied or 0))
    local rejected = {}
    for reason, count in pairs(stats.rejected or {}) do rejected[#rejected + 1] = reason .. "=" .. count end
    table.sort(rejected)
    if #rejected > 0 then self:Print("Recipe sync rejected: " .. table.concat(rejected, ", ")) end
end

function LL:ReceiveProfessionChunk(sender, message, channel)
    local stats = self.professionSyncStats or { queued = 0, sent = 0, failed = 0, dropped = 0, refused = 0, received = 0, applied = 0, rejected = {} }
    self.professionSyncStats = stats
    stats.received = stats.received + 1
    local function reject(reason)
        stats.rejected[reason] = (stats.rejected[reason] or 0) + 1
        return false
    end
    if not self.db or type(sender) ~= "string" or type(message) ~= "string" or #message > 255 then return reject("format") end
    if channel ~= "GUILD" and channel ~= "WHISPER" then return reject("channel") end
    local version, kind, data = strsplit("|", message, 3)
    if tonumber(version) ~= self.VERSION or kind ~= "PROFESSION_CHUNK" or not data then return reject("header") end
    local owner, revision, professionID, name, index, total, records = strsplit(";", data or "", 7)
    local ownerMatches, canonicalOwner = self:ProfessionIdentityMatches(owner, sender)
    local isSelf = self:ProfessionIdentityMatches(sender, self:PlayerName())
    if not ownerMatches or isSelf then return reject("owner") end
    if channel == "WHISPER" then
        local clock = GetTime and GetTime() or now()
        if not self.professionSyncPendingUntil or clock > self.professionSyncPendingUntil or self.professionSyncPendingGuildKey ~= self:GetGuildKey(self.GUILD_NAME) or not self:ResolveProfessionIdentity(sender) then
            return reject("unsolicited whisper")
        end
    end
    owner = canonicalOwner or self:ResolveProfessionIdentity(owner) or owner
    local ownerKey = self:FullPlayerIdentityKey(owner)
    if ownerKey == "" then return reject("owner") end
    revision, professionID, index, total = tonumber(revision), tonumber(professionID), tonumber(index), tonumber(total)
    if not revision or revision > now() + 60 or not professionID or professionID < 1 or not index or not total or total < 1 or total > 300 or index < 1 or index > total or type(name) ~= "string" or name == "" then return reject("revision/metadata") end
    local id = ownerKey .. ":" .. professionID .. ":" .. revision
    self.pendingProfessionChunks = self.pendingProfessionChunks or {}
    for key, value in pairs(self.pendingProfessionChunks) do if now() - value.lastAt > 60 then self.pendingProfessionChunks[key] = nil end end
    local pending = self.pendingProfessionChunks[id]
    if not pending then
        local count = 0
        for _ in pairs(self.pendingProfessionChunks) do count = count + 1 end
        if count >= 20 then return reject("capacity") end
        pending = { owner = owner, professionID = professionID, name = name, total = total, parts = {}, received = 0, lastAt = now() }
        self.pendingProfessionChunks[id] = pending
    end
    if pending.total ~= total or pending.name ~= name or pending.received > 300 then self.pendingProfessionChunks[id] = nil; return reject("inconsistent") end
    if not pending.parts[index] then pending.parts[index], pending.received = records or "", pending.received + 1 end
    pending.lastAt = now()
    if pending.received ~= total then return end
    local all = table.concat(pending.parts)
    local recipes, seen = {}, {}
    for pair in all:gmatch("([^;]+)") do
        local rid, itemID = pair:match("^(%d+),(%d+)$")
        rid, itemID = tonumber(rid), tonumber(itemID)
        if not rid or rid < 1 or not itemID or seen[rid] then self.pendingProfessionChunks[id] = nil; return reject("record") end
        seen[rid] = true; recipes[#recipes + 1] = { rid, itemID }
    end
    if #recipes == 0 or #recipes > 10000 then self.pendingProfessionChunks[id] = nil; return reject("records") end
    local catalogs = self.db.professionCatalogs or {}; self.db.professionCatalogs = catalogs
    catalogs[ownerKey] = catalogs[ownerKey] or {}
    local current = catalogs[ownerKey][professionID]
    if not current or (current.updatedAt or 0) < revision then catalogs[ownerKey][professionID] = { owner = owner, professionID = professionID, name = name, recipes = recipes, updatedAt = revision } end
    self.pendingProfessionChunks[id] = nil
    stats.applied = stats.applied + 1
    for key, value in pairs(self.pendingProfessionChunks) do if now() - value.lastAt > 60 then self.pendingProfessionChunks[key] = nil end end
    self:RefreshUI()
end

function LL:ReceiveProfessionMaterialsChunk(sender, message, channel)
    local stats = self.professionSyncStats or { rejected = {} }
    self.professionSyncStats = stats
    stats.materialChunksReceived = (stats.materialChunksReceived or 0) + 1
    stats.rejected = stats.rejected or {}
    local function reject(reason)
        stats.rejected["materials " .. reason] = (stats.rejected["materials " .. reason] or 0) + 1
        return false
    end
    if not self.db or type(sender) ~= "string" or type(message) ~= "string" or #message > 255 then return reject("format") end
    if channel ~= "GUILD" and channel ~= "WHISPER" then return reject("channel") end
    local version, kind, data = strsplit("|", message, 3)
    if tonumber(version) ~= self.VERSION or kind ~= "PROFESSION_MATERIALS_CHUNK" or not data then return reject("header") end
    local owner, revision, professionID, index, total, records = strsplit(";", data or "", 6)
    local ownerMatches, canonicalOwner = self:ProfessionIdentityMatches(owner, sender)
    if not ownerMatches or self:ProfessionIdentityMatches(sender, self:PlayerName()) then return reject("owner") end
    if channel == "WHISPER" then
        local clock = GetTime and GetTime() or now()
        if not self.professionSyncPendingUntil or clock > self.professionSyncPendingUntil or self.professionSyncPendingGuildKey ~= self:GetGuildKey(self.GUILD_NAME) or not self:ResolveProfessionIdentity(sender) then
            return reject("unsolicited whisper")
        end
    end
    owner = canonicalOwner or self:ResolveProfessionIdentity(owner) or owner
    local ownerKey = self:FullPlayerIdentityKey(owner)
    revision, professionID, index, total = tonumber(revision), tonumber(professionID), tonumber(index), tonumber(total)
    if ownerKey == "" or not revision or revision > now() + 60 or not professionID or professionID < 1 or not index or not total or total < 1 or total > 300 or index < 1 or index > total or type(records) ~= "string" then return reject("metadata") end
    local catalogs = self.db.professionCatalogs or {}
    local profession = catalogs[ownerKey] and catalogs[ownerKey][professionID]
    if type(profession) ~= "table" or tonumber(profession.updatedAt) ~= revision or type(profession.recipes) ~= "table" then return reject("catalog") end
    local id = ownerKey .. ":" .. professionID .. ":" .. revision
    self.pendingProfessionMaterialChunks = self.pendingProfessionMaterialChunks or {}
    for key, value in pairs(self.pendingProfessionMaterialChunks) do if now() - value.lastAt > 60 then self.pendingProfessionMaterialChunks[key] = nil end end
    local pending = self.pendingProfessionMaterialChunks[id]
    if not pending then
        local count = 0
        for _ in pairs(self.pendingProfessionMaterialChunks) do count = count + 1 end
        if count >= 20 then return reject("capacity") end
        pending = { owner = owner, professionID = professionID, total = total, parts = {}, received = 0, lastAt = now() }
        self.pendingProfessionMaterialChunks[id] = pending
    end
    if pending.total ~= total or pending.received > 300 then self.pendingProfessionMaterialChunks[id] = nil; return reject("inconsistent") end
    if not pending.parts[index] then pending.parts[index], pending.received = records, pending.received + 1 end
    pending.lastAt = now()
    if pending.received ~= total then return end
    local all = table.concat(pending.parts)
    if #all == 0 or #all > 15000 then self.pendingProfessionMaterialChunks[id] = nil; return reject("size") end
    local ownedRecipes, materials = {}, {}
    for _, recipe in ipairs(profession.recipes) do ownedRecipes[tonumber(recipe[1])] = true end
    for record in all:gmatch("([^;]+)") do
        local recipeID, slotIndex, quantity, choices = record:match("^(%d+),(%d+),(%d+),([%w+%-]+)$")
        recipeID, slotIndex, quantity = tonumber(recipeID), tonumber(slotIndex), tonumber(quantity)
        if not recipeID or not ownedRecipes[recipeID] or not slotIndex or slotIndex > 64 or not quantity or quantity > 100000 then
            self.pendingProfessionMaterialChunks[id] = nil; return reject("record")
        end
        materials[recipeID] = materials[recipeID] or {}
        if slotIndex == 0 then
            if quantity ~= 0 or choices ~= "-" or materials[recipeID].knownEmpty then self.pendingProfessionMaterialChunks[id] = nil; return reject("empty slot") end
            for _ in pairs(materials[recipeID]) do self.pendingProfessionMaterialChunks[id] = nil; return reject("mixed empty slot") end
            materials[recipeID].knownEmpty = true
        else
            if quantity < 1 or choices == "-" or materials[recipeID].knownEmpty then self.pendingProfessionMaterialChunks[id] = nil; return reject("slot") end
            materials[recipeID].slots = materials[recipeID].slots or {}
            if materials[recipeID].slots[slotIndex] then self.pendingProfessionMaterialChunks[id] = nil; return reject("duplicate slot") end
            local slotChoices, seen, choiceCount = {}, {}, 0
            for choice in choices:gmatch("([^+]+)") do
                local kindID, reagentID = choice:match("^([ic])(%d+)$")
                reagentID = tonumber(reagentID)
                local choiceKey = kindID and (kindID .. reagentID)
                if not choiceKey or reagentID < 1 or reagentID > 2147483647 or reagentID ~= math.floor(reagentID) or seen[choiceKey] then self.pendingProfessionMaterialChunks[id] = nil; return reject("choice") end
                seen[choiceKey], choiceCount = true, choiceCount + 1
                if choiceCount > 20 then self.pendingProfessionMaterialChunks[id] = nil; return reject("choice count") end
                slotChoices[#slotChoices + 1] = { kindID, reagentID }
            end
            if #slotChoices == 0 then self.pendingProfessionMaterialChunks[id] = nil; return reject("choices") end
            materials[recipeID].slots[slotIndex] = { quantity = quantity, choices = slotChoices }
        end
    end
    local normalized = {}
    for recipeID, value in pairs(materials) do
        if value.knownEmpty then
            normalized[recipeID] = {}
        else
            local slots, maximum = {}, 0
            for slotIndex in pairs(value.slots or {}) do if slotIndex > maximum then maximum = slotIndex end end
            for slotIndex = 1, maximum do
                if not value.slots[slotIndex] then self.pendingProfessionMaterialChunks[id] = nil; return reject("slot gap") end
                slots[slotIndex] = value.slots[slotIndex]
            end
            normalized[recipeID] = slots
        end
    end
    profession.reagents = profession.reagents or {}
    for recipeID, slots in pairs(normalized) do profession.reagents[recipeID] = slots end
    profession.reagentsUpdatedAt = revision
    self.pendingProfessionMaterialChunks[id] = nil
    stats.materialSnapshotsApplied = (stats.materialSnapshotsApplied or 0) + 1
    self:RefreshUI()
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
    local professions = self:GetProfessions()
    if #professions > 0 then player.professions = professions end
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
    if #message > 255 and kind == "PROFILE" then
        local compact = {}
        for key, value in pairs(payload) do compact[key] = value end
        compact.professions, compact.primaryProfessions, compact.secondaryProfessions = {}, nil, nil
        message = self.VERSION .. "|" .. kind .. "|" .. self:Serialize(kind, compact)
    end
    if #message <= 255 then
        C_ChatInfo.SendAddonMessage(self.COMM_PREFIX, message, "GUILD")
        return true
    end
    if kind == "PROFILE" and not self.profileTooLongNotice then
        self.profileTooLongNotice = true
        self:Print("Your profile is too large to sync, even without profession text.")
    end
    return false
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
    elseif kind == "PVP_KILL" then
        return table.concat({ self:Escape(payload.killer), self:Escape(payload.victim) }, ";")
    elseif kind == "PVP_DEATH" then
        return table.concat({ self:Escape(payload.victim), self:Escape(payload.killer), payload.confirmed and 1 or 0 }, ";")
    elseif kind == "BOUNTY_ADD" then
        return table.concat({ self:Escape(payload.id), self:Escape(payload.target), self:Escape(payload.note), self:Escape(payload.postedBy), payload.createdAt or now(), payload.rewardCopper or 0 }, ";")
    elseif kind == "BOUNTY_COMPLETE" then
        return table.concat({ self:Escape(payload.id), self:Escape(payload.completedBy), payload.completedAt or now(), payload.canceled and 1 or 0 }, ";")
    elseif kind == "BOUNTY_DEBT" then
        return table.concat({ self:Escape(payload.id), self:Escape(payload.winner), self:Escape(payload.loser), payload.amountCopper or 0, self:Escape(payload.target), payload.createdAt or now() }, ";")
    elseif kind == "BOUNTY_DEBT_PAID" then
        return table.concat({ self:Escape(payload.id), self:Escape(payload.paidBy), payload.paidAt or now() }, ";")
    elseif kind == "BOUNTY_SIGHTING" then
        local function escapeField(value)
            return tostring(value or ""):gsub("%%", "%%25"):gsub(";", "%%3B"):gsub("|", "%%7C"):gsub("[\r\n]", " ")
        end
        return table.concat({ escapeField(payload.target), escapeField(payload.zone), escapeField(payload.subzone), payload.spottedAt or now() }, ";")
    elseif kind == "CASINO_STAT" then
        return table.concat({ self:Escape(payload.name), payload.wonGold or 0, payload.lostGold or 0, payload.games or 0 }, ";")
    elseif kind == "CASINO_STAT_BASELINE" then
        return table.concat({ self:Escape(payload.name), payload.wonGold or 0, payload.lostGold or 0, payload.games or 0, 2 }, ";")
    elseif kind == "CASINO_GAME_SETTLE_BASELINE" then
        return table.concat({ self:Escape(payload.id), self:Escape(payload.winner), self:Escape(payload.loser), payload.amount, payload.createdAt or now(), 2 }, ";")
    elseif kind == "CASINO_GAME_OPEN" then
        return table.concat({ self:Escape(payload.id), self:Escape(payload.host), self:Escape(payload.mode), payload.wager, payload.createdAt or now(), payload.lastActivityAt or payload.createdAt or now() }, ";")
    elseif kind == "CASINO_GAME_JOIN" then
        return table.concat({ self:Escape(payload.id), self:Escape(payload.player), payload.lastActivityAt or now() }, ";")
    elseif kind == "CASINO_GAME_CLOSE" then
        return self:Escape(payload.id)
    elseif kind == "CASINO_GAME_STATE" then
        return table.concat({ self:Escape(payload.id), self:Escape(payload.phase), payload.minRoll or 0, payload.maxRoll or 0, self:Escape(payload.turn), self:Escape(payload.message), payload.lastActivityAt or now() }, ";")
    elseif kind == "CASINO_GAME_ROLL" then
        return table.concat({ self:Escape(payload.id), self:Escape(payload.player), payload.roll, payload.minRoll, payload.maxRoll, payload.activityAt or now() }, ";")
    elseif kind == "CASINO_GAME_RESULT" then
        return table.concat({ self:Escape(payload.id), self:Escape(payload.mode), self:Escape(payload.host), payload.wager, payload.finishedAt or now(), self:Escape(payload.summary), payload.accountingVersion or 2 }, ";")
    elseif kind == "CASINO_GAME_SETTLE" then
        return table.concat({ self:Escape(payload.id), self:Escape(payload.winner), self:Escape(payload.loser), payload.amount, payload.createdAt or now(), payload.accountingVersion or 2 }, ";")
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
        local primaryProfessions, secondaryProfessions = self:Unescape(fields[9]), self:Unescape(fields[10])
        if primaryProfessions == "" then primaryProfessions = nil end
        if secondaryProfessions == "" then secondaryProfessions = nil end
        return kind, { name = self:Unescape(fields[1]), kills = tonumber(fields[2]), deaths = tonumber(fields[3]), professions = professions, updatedAt = tonumber(fields[5]), release = self:Unescape(fields[6]), class = self:Unescape(fields[7]), level = tonumber(fields[8]), primaryProfessions = primaryProfessions, secondaryProfessions = secondaryProfessions, killStreak = tonumber(fields[11]), aliveSince = tonumber(fields[12]), longestLife = tonumber(fields[13]), weeklyReset = tonumber(fields[14]), weeklyKills = tonumber(fields[15]), weeklyDeaths = tonumber(fields[16]) }
    elseif kind == "LEVEL_UP" then
        return kind, { name = self:Unescape(fields[1]), level = tonumber(fields[2]) }
    elseif kind == "UPDATE_AVAILABLE" then
        return kind, { target = self:Unescape(fields[1]), release = self:Unescape(fields[2]) }
    elseif kind == "PVP_KILL" then
        return kind, { killer = self:Unescape(fields[1]), victim = self:Unescape(fields[2]) }
    elseif kind == "PVP_DEATH" then
        return kind, { victim = self:Unescape(fields[1]), killer = self:Unescape(fields[2]), confirmed = tonumber(fields[3]) == 1 }
    elseif kind == "BOUNTY_ADD" then
        return kind, { id = self:Unescape(fields[1]), target = self:Unescape(fields[2]), note = self:Unescape(fields[3]), postedBy = self:Unescape(fields[4]), createdAt = tonumber(fields[5]), rewardCopper = tonumber(fields[6]) or 0, active = true }
    elseif kind == "BOUNTY_COMPLETE" then
        return kind, { id = self:Unescape(fields[1]), completedBy = self:Unescape(fields[2]), completedAt = tonumber(fields[3]), canceled = tonumber(fields[4]) == 1 }
    elseif kind == "BOUNTY_DEBT" then
        return kind, { id = self:Unescape(fields[1]), winner = self:Unescape(fields[2]), loser = self:Unescape(fields[3]), amountCopper = tonumber(fields[4]), target = self:Unescape(fields[5]), createdAt = tonumber(fields[6]) }
    elseif kind == "BOUNTY_DEBT_PAID" then
        return kind, { id = self:Unescape(fields[1]), paidBy = self:Unescape(fields[2]), paidAt = tonumber(fields[3]) }
    elseif kind == "BOUNTY_SIGHTING" then
        return kind, { target = self:Unescape(fields[1]), zone = self:Unescape(fields[2]), subzone = self:Unescape(fields[3]), spottedAt = tonumber(fields[4]) }
    elseif kind == "REQUEST_SYNC" then
        return kind, {}
    elseif kind == "CASINO_STAT" then
        return kind, { name = self:Unescape(fields[1]), wonGold = tonumber(fields[2]), lostGold = tonumber(fields[3]), games = tonumber(fields[4]), accountingVersion = tonumber(fields[5]) }
    elseif kind == "CASINO_STAT_BASELINE" then
        return kind, { name = self:Unescape(fields[1]), wonGold = tonumber(fields[2]), lostGold = tonumber(fields[3]), games = tonumber(fields[4]), accountingVersion = tonumber(fields[5]) }
    elseif kind == "CASINO_GAME_SETTLE_BASELINE" then
        return kind, { id = self:Unescape(fields[1]), winner = self:Unescape(fields[2]), loser = self:Unescape(fields[3]), amount = tonumber(fields[4]), createdAt = tonumber(fields[5]), accountingVersion = tonumber(fields[6]), baselineIncluded = true }
    elseif kind == "CASINO_GAME_OPEN" then
        return kind, { id = self:Unescape(fields[1]), host = self:Unescape(fields[2]), mode = self:Unescape(fields[3]), wager = tonumber(fields[4]), createdAt = tonumber(fields[5]), lastActivityAt = tonumber(fields[6]) }
    elseif kind == "CASINO_GAME_JOIN" then
        return kind, { id = self:Unescape(fields[1]), player = self:Unescape(fields[2]), lastActivityAt = tonumber(fields[3]) }
    elseif kind == "CASINO_GAME_CLOSE" then
        return kind, { id = self:Unescape(fields[1]) }
    elseif kind == "CASINO_GAME_STATE" then
        return kind, { id = self:Unescape(fields[1]), phase = self:Unescape(fields[2]), minRoll = tonumber(fields[3]), maxRoll = tonumber(fields[4]), turn = self:Unescape(fields[5]), message = self:Unescape(fields[6]), lastActivityAt = tonumber(fields[7]) }
    elseif kind == "CASINO_GAME_ROLL" then
        return kind, { id = self:Unescape(fields[1]), player = self:Unescape(fields[2]), roll = tonumber(fields[3]), minRoll = tonumber(fields[4]), maxRoll = tonumber(fields[5]), activityAt = tonumber(fields[6]) }
    elseif kind == "CASINO_GAME_RESULT" then
        return kind, { id = self:Unescape(fields[1]), mode = self:Unescape(fields[2]), host = self:Unescape(fields[3]), wager = tonumber(fields[4]), finishedAt = tonumber(fields[5]), summary = self:Unescape(fields[6]), accountingVersion = tonumber(fields[7]) }
    elseif kind == "CASINO_GAME_SETTLE" then
        return kind, { id = self:Unescape(fields[1]), winner = self:Unescape(fields[2]), loser = self:Unescape(fields[3]), amount = tonumber(fields[4]), createdAt = tonumber(fields[5]), accountingVersion = tonumber(fields[6]) }
    elseif kind == "CASINO_GAME_DEBT_PAID" then
        return kind, { id = self:Unescape(fields[1]), winner = self:Unescape(fields[2]), loser = self:Unescape(fields[3]), amount = tonumber(fields[4]), paidBy = self:Unescape(fields[5]), paidAt = tonumber(fields[6]) }
    elseif kind == "PROFESSION_SYNC_REQUEST" then
        return kind, {}
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

function LL:RecordPvpKill(killer, victim)
    if not self.db or type(victim) ~= "string" or victim == "" then return end
    local killerKey = self:PlayerIdentityKey(killer)
    if killerKey == "" then return end
    self.db.vanquished[killerKey] = self.db.vanquished[killerKey] or {}
    self.db.vanquished[killerKey][victim] = (self.db.vanquished[killerKey][victim] or 0) + 1
end

function LL:TopPvpVictim(killer)
    local victim, kills
    for name, count in pairs((self.db and self.db.vanquished[self:PlayerIdentityKey(killer)]) or {}) do
        if not kills or count > kills or (count == kills and name < victim) then victim, kills = name, count end
    end
    return victim, kills
end

function LL:AnnouncePvpKill(victim)
    if not self.db or type(victim) ~= "string" or victim == "" then return end
    local payload = { killer = self:PlayerName(), victim = victim }
    self:RecordPvpKill(payload.killer, payload.victim)
    self:Broadcast("PVP_KILL", payload)
end

function LL:GetDeathRecapKiller(observedOpponent)
    local api = C_DeathRecap and C_DeathRecap.GetRecapEvents
    if type(api) ~= "function" then return end
    local ok, events = pcall(api)
    if not ok or type(events) ~= "table" then return end

    -- DeathRecapEventInfo has no published field schema for this client build.
    -- The reference addon reads sourceName, so probe it defensively and only
    -- accept it when it matches a hostile player observed during this combat.
    local killer
    local readOk = pcall(function()
        for _, event in ipairs(events) do
            local sourceName = type(event) == "table" and event.sourceName or nil
            if type(sourceName) == "string" and (not issecretvalue or not issecretvalue(sourceName)) then
                if observedOpponent and self:PlayerIdentityKey(sourceName) == self:PlayerIdentityKey(observedOpponent) then
                    killer = sourceName
                    break
                end
            end
        end
    end)
    if readOk then return killer end
end

function LL:AnnouncePvpDeath(recapKiller, probableOpponent)
    if not self.db then return end
    local confirmed = type(recapKiller) == "string" and recapKiller ~= ""
    local killer = confirmed and recapKiller or (type(probableOpponent) == "string" and probableOpponent or "")
    local payload = { victim = self:PlayerName(), killer = killer, confirmed = confirmed }
    if confirmed then self:RecordNemesisDeath(payload.victim, payload.killer) end
    local message = payload.victim .. " died in PvP"
    if killer ~= "" then
        message = message .. " to " .. killer .. (confirmed and "" or " (probably; last observed hostile target)")
    end
    self:Print(message .. ".")
    self:Broadcast("PVP_DEATH", payload)
end

function LL:SchedulePvpDeathNotice(probableOpponent)
    local database, guildKey = self.db, self.GUILD_NAME and self:GetGuildKey(self.GUILD_NAME)
    local function announce()
        local currentGuild = self:GetGuildName()
        if not database or self.db ~= database or not currentGuild or self:GetGuildKey(currentGuild) ~= guildKey then return end
        self:AnnouncePvpDeath(self:GetDeathRecapKiller(probableOpponent), probableOpponent)
    end
    if C_Timer and C_Timer.After then C_Timer.After(0.7, announce) else announce() end
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

function LL:AddBounty(target, reward)
    target = strtrim(target or "")
    if target == "" then
        self:Print("Enter an Alliance character name for the bounty.")
        return false
    end
    local rewardCopper = self:ParseRewardCopper(reward)
    if not rewardCopper then
        self:Print("Enter a reward such as 12.34 for 12 gold 34 silver.")
        return false
    end
    local id = self:NewRecordID("B")
    local bounty = { id = id, target = target, note = "", rewardCopper = rewardCopper, postedBy = self:PlayerName(), createdAt = now(), updatedAt = now(), active = true }
    table.insert(self.db.bounties, bounty)
    self:Broadcast("BOUNTY_ADD", bounty)
    self:RefreshUI()
    return true
end

function LL:BountyTargetMatches(bountyTarget, targetName)
    local bountyName = self:NormalizeBountyTarget(bountyTarget)
    local killedName = self:NormalizeBountyTarget(targetName)
    if bountyName == "" or killedName == "" then return false end
    if bountyName == killedName then return true end
    return bountyName:match("^[^-]+") == killedName:match("^[^-]+")
end

function LL:ApplyBountySettlement(settlement)
    if not self.db or not settlement or not settlement.id or not settlement.winner or not settlement.loser or (tonumber(settlement.amountCopper) or 0) <= 0 then return end
    local existing = self.db.bountySettlements[settlement.id]
    if existing then return existing end
    self.db.bountySettlements[settlement.id] = settlement
    self:RecordBalanceTransaction("bounty", settlement)
    return settlement
end

function LL:CreateBountySettlement(bounty)
    local reward = tonumber(bounty.rewardCopper) or 0
    if reward <= 0 or not bounty.completedBy or self:GuildIdentityMatches(bounty.postedBy, bounty.completedBy) then return end
    return self:ApplyBountySettlement({ id = bounty.id, winner = bounty.completedBy, loser = bounty.postedBy, amountCopper = reward,
        target = bounty.target, createdAt = bounty.completedAt or now() })
end

function LL:ApplyBountyDebtPayment(payment)
    if not self.db or not payment or not payment.id or not payment.paidBy then return end
    local settlement = self.db.bountySettlements[payment.id]
    if not settlement or settlement.paidAt or not self:GuildIdentityMatches(settlement.loser, payment.paidBy) then return end
    settlement.paidAt, settlement.paidBy = payment.paidAt or now(), payment.paidBy
    self:MarkBalanceTransactionPaid("bounty", settlement, settlement.paidAt)
    self:RefreshUI()
end

function LL:MarkBountyComplete(bounty)
    bounty.active = false
    bounty.completedBy = self:PlayerName()
    bounty.completedAt = now()
    bounty.updatedAt = bounty.completedAt
    bounty.canceled = nil
    local settlement = self:CreateBountySettlement(bounty)
    self:Broadcast("BOUNTY_COMPLETE", { id = bounty.id, completedBy = bounty.completedBy, completedAt = bounty.completedAt })
    if settlement then self:Broadcast("BOUNTY_DEBT", settlement) end
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

function LL:ScheduleGuildSyncReply()
    local clock = GetTime and GetTime() or now()
    if self.guildSyncReplyPending or (self.guildSyncLastReply and clock - self.guildSyncLastReply < 30) then return end
    self.guildSyncReplyPending = true
    local database, guildKey = self.db, self:GetGuildKey(self.GUILD_NAME)
    local function reply()
        LL.guildSyncReplyPending = nil
        if LL.db ~= database or not LL:IsLagomMember() or LL:GetGuildKey(LL:GetGuildName()) ~= guildKey then return end
        LL.guildSyncLastReply = GetTime and GetTime() or now()
        LL:RefreshLocalProfile()
        for _, bounty in ipairs(LL.db.bounties) do
            if LL:GuildIdentityMatches(bounty.postedBy, LL:PlayerName()) then
                LL:Broadcast("BOUNTY_ADD", bounty)
                if not bounty.active and bounty.canceled then
                    LL:Broadcast("BOUNTY_COMPLETE", { id = bounty.id, completedBy = "", completedAt = bounty.completedAt or now(), canceled = true })
                end
            end
            if not bounty.active and not bounty.canceled and LL:GuildIdentityMatches(bounty.completedBy, LL:PlayerName()) then
                LL:Broadcast("BOUNTY_COMPLETE", { id = bounty.id, completedBy = bounty.completedBy, completedAt = bounty.completedAt or now() })
            end
        end
        for _, settlement in pairs(LL.db.bountySettlements) do
            if LL:GuildIdentityMatches(settlement.winner, LL:PlayerName()) then LL:Broadcast("BOUNTY_DEBT", settlement) end
            if settlement.paidAt and LL:GuildIdentityMatches(settlement.paidBy, LL:PlayerName()) then
                LL:Broadcast("BOUNTY_DEBT_PAID", settlement)
            end
        end
        if LL.SendCasinoGameSync then LL:SendCasinoGameSync() end
        if LL.SendCasinoSync then LL:SendCasinoSync() end
    end
    if C_Timer and C_Timer.After then C_Timer.After(2 + math.random() * 4, reply) else reply() end
end

function LL:OnComm(prefix, message, channel, sender)
    if not self.db or prefix ~= self.COMM_PREFIX or not self:IsLagomMember() then return end
    if type(message) == "string" and message:find("|PROFESSION_MATERIALS_CHUNK|", 1, true) then
        self:ReceiveProfessionMaterialsChunk(sender, message, channel)
        return
    end
    if type(message) == "string" and message:find("|PROFESSION_CHUNK|", 1, true) then
        self:ReceiveProfessionChunk(sender, message, channel)
        return
    end
    if self:GuildIdentityMatches(sender, self:PlayerName()) then return end
    if channel ~= "GUILD" then return end
    local kind, payload = self:Decode(message)
    if not kind or type(payload) ~= "table" then return end
    if kind == "PROFILE" and not self:GuildIdentityMatches(payload.name, sender) then return end
    if kind == "LEVEL_UP" and not self:GuildIdentityMatches(payload.name, sender) then return end
    if kind == "PVP_KILL" and not self:GuildIdentityMatches(payload.killer, sender) then return end
    if kind == "PVP_DEATH" and not self:GuildIdentityMatches(payload.victim, sender) then return end
    if kind == "BOUNTY_ADD" and not self:GuildIdentityMatches(payload.postedBy, sender) then return end
    if kind == "BOUNTY_DEBT" and not self:GuildIdentityMatches(payload.winner, sender) then return end
    if kind == "BOUNTY_DEBT_PAID" and not self:GuildIdentityMatches(payload.paidBy, sender) then return end
    if kind == "CASINO_STAT" and not self:GuildIdentityMatches(payload.name, sender) then return end
    if kind == "CASINO_STAT_BASELINE" and not self:GuildIdentityMatches(payload.name, sender) then return end
    if kind == "PROFILE" and type(payload.name) == "string" then
        local player = self:EnsurePlayer(payload.name)
        player.kills = tonumber(payload.kills) or player.kills
        player.deaths = tonumber(payload.deaths) or player.deaths
        if type(payload.professions) == "table" and #payload.professions > 0 then player.professions = payload.professions end
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
    elseif kind == "UPDATE_AVAILABLE" and payload.target and payload.release and self:ProfessionIdentityMatches(payload.target, self:PlayerName()) and self:IsNewerRelease(payload.release) then
        self:RememberNewerRelease(payload.release)
        self:ShowUpdateNotice(payload.release)
    elseif kind == "PVP_KILL" and payload.killer and payload.victim then
        self:RecordPvpKill(payload.killer, payload.victim)
    elseif kind == "PVP_DEATH" and payload.victim then
        if strlower(strtrim(payload.victim)) == strlower(strtrim(self:PlayerName())) then return end
        if payload.confirmed then self:RecordNemesisDeath(payload.victim, payload.killer) end
        local message = payload.victim .. " died in PvP"
        if payload.killer and payload.killer ~= "" then
            message = message .. " to " .. payload.killer .. (payload.confirmed and "" or " (probably; last observed hostile target)")
        end
        self:Print(message .. ".")
    elseif kind == "BOUNTY_ADD" and payload.id and payload.target then
        for _, bounty in ipairs(self.db.bounties) do
            if bounty.id == payload.id then
                if (payload.rewardCopper or 0) > 0 then bounty.rewardCopper, bounty.note = payload.rewardCopper, payload.note end
                self:RefreshUI()
                return
            end
        end
        table.insert(self.db.bounties, payload)
    elseif kind == "BOUNTY_COMPLETE" and payload.id then
        for _, bounty in ipairs(self.db.bounties) do
            if bounty.id == payload.id and bounty.active then
                if payload.canceled then
                    if not self:GuildIdentityMatches(bounty.postedBy, sender) then return end
                elseif not self:GuildIdentityMatches(payload.completedBy, sender) then
                    return
                end
                local completedAt = tonumber(payload.completedAt)
                if not completedAt then return end
                bounty.active, bounty.canceled, bounty.completedBy, bounty.completedAt, bounty.updatedAt = false, payload.canceled, payload.completedBy, completedAt, completedAt
                if not payload.canceled then self:CreateBountySettlement(bounty) end
            end
        end
    elseif kind == "BOUNTY_DEBT" then
        local bounty
        for _, entry in ipairs(self.db.bounties) do if entry.id == payload.id then bounty = entry; break end end
        if bounty and not bounty.active and not bounty.canceled
            and self:GuildIdentityMatches(bounty.completedBy, payload.winner)
            and self:GuildIdentityMatches(bounty.postedBy, payload.loser)
            and bounty.target == payload.target
            and tonumber(bounty.rewardCopper) == tonumber(payload.amountCopper) then
            self:ApplyBountySettlement(payload)
        end
    elseif kind == "BOUNTY_DEBT_PAID" then
        self:ApplyBountyDebtPayment(payload)
    elseif kind == "BOUNTY_SIGHTING" and type(sender) == "string" and #sender <= 80 and type(payload.target) == "string" and #payload.target <= 80 and type(payload.zone) == "string" and #payload.zone <= 80 and type(payload.subzone) == "string" and #payload.subzone <= 80 then
        local spottedAt = tonumber(payload.spottedAt)
        if not spottedAt or spottedAt < now() - 120 or spottedAt > now() + 30 then return end
        for _, bounty in ipairs(self.db.bounties) do
            if bounty.active and self:BountyTargetMatches(bounty.target, payload.target) then
                self:AlertReferenceBounty(bounty, payload.zone, payload.subzone, sender)
                break
            end
        end
    elseif string.sub(kind or "", 1, 12) == "CASINO_GAME_" and self.OnCasinoGameMessage then
        self:OnCasinoGameMessage(kind, payload, sender)
    elseif string.sub(kind or "", 1, 7) == "CASINO_" and self.OnCasinoMessage then
        self:OnCasinoMessage(kind, payload)
    elseif kind == "REQUEST_SYNC" then
        self:ScheduleGuildSyncReply()
    elseif kind == "PROFESSION_SYNC_REQUEST" then
        self:ReplayProfessionCatalogs(sender)
    else
        return
    end
    self:RefreshUI()
end

function LL:OnEvent(event, ...)
    if event == "PLAYER_LOGIN" then
        self:EnsureDatabase()
        C_ChatInfo.RegisterAddonMessagePrefix(self.COMM_PREFIX)
        C_ChatInfo.RegisterAddonMessagePrefix(self.VERSION_COMM_PREFIX)
        self.loginUpdateCheck = true
        self:CheckSavedRelease()
        if C_Timer and C_Timer.After then C_Timer.After(20, function() LL.loginUpdateCheck = false end) end
        if not self.db and C_Timer and C_Timer.After then
            C_Timer.After(1, function()
                if LL.db or not LL:EnsureDatabase() then return end
                LL:CheckSavedRelease()
                if LL.OnReferenceGuildReady then LL:OnReferenceGuildReady() end
                LL:RefreshLocalProfile()
                LL:Broadcast("REQUEST_SYNC", {})
            end)
        end
        if C_Timer and C_Timer.After then C_Timer.After(8, function() LL:SendVersion("GUILD") end) end
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
        if pvpCombat then self:SchedulePvpDeathNotice(self.lastPvpOpponent) end
        self:RecordDeath(pvpCombat)
        self.inCombat, self.lastPvpCombatAt, self.lastPvpOpponent = false, nil, nil
    elseif event == "PLAYER_ALIVE" and self.db then
        self:StartNewLife()
    elseif event == "CHAT_MSG_ADDON" and self.db then
        local prefix, message, channel, sender = ...
        if prefix == self.VERSION_COMM_PREFIX then
            self:OnVersionMessage(message, channel, sender)
        else
            self:OnComm(prefix, message, channel, sender)
        end
    elseif event == "CHAT_MSG_SYSTEM" and self.db and self.HandleRollMessage then
        self:HandleRollMessage(...)
    elseif event == "SKILL_LINES_CHANGED" and self.db then
        self:RefreshLocalProfile()
    elseif event == "TRADE_SKILL_SHOW" and self.db then
        self.professionWindowOpen = true
        self.professionScanForceRepublish = true
        self:ScheduleProfessionScan(2)
    elseif event == "TRADE_SKILL_LIST_UPDATE" and self.db and self.professionWindowOpen then
        self:ScheduleProfessionScan(3)
    elseif event == "TRADE_SKILL_CLOSE" then
        self.professionWindowOpen = false
        self:CancelProfessionScan()
    elseif event == "NEW_RECIPE_LEARNED" and self.db and self.professionWindowOpen then
        self:ScheduleProfessionScan(3)
    elseif event == "PLAYER_LEVEL_UP" and self.db then
        self:AnnounceLevelUp(...)
    elseif event == "PLAYER_GUILD_UPDATE" then
        local unit = ...
        if unit == "player" then
            self:CancelProfessionScan()
            self.professionWindowOpen = false
            self:EnsureDatabase()
            if self.db then
                if self.OnReferenceGuildReady then self:OnReferenceGuildReady() end
                if self.UpdateMinimapButton then self:UpdateMinimapButton() end
                self:RefreshLocalProfile()
                self:Broadcast("REQUEST_SYNC", {})
            else
                self:RefreshUI()
            end
        end
    elseif event == "ITEM_DATA_LOAD_RESULT" then
        local itemID = tonumber((...))
        if itemID and self.professionCatalogActive and self.professionMaterialItemIDs and self.professionMaterialItemIDs[itemID] then
            self:RefreshUI()
        end
    end
end

SLASH_LAGOMLEDGER1 = "/lagom"

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
frame:RegisterEvent("TRADE_SKILL_SHOW")
frame:RegisterEvent("TRADE_SKILL_LIST_UPDATE")
frame:RegisterEvent("TRADE_SKILL_CLOSE")
frame:RegisterEvent("NEW_RECIPE_LEARNED")
frame:RegisterEvent("PLAYER_LEVEL_UP")
frame:RegisterEvent("PLAYER_GUILD_UPDATE")
frame:RegisterEvent("ITEM_DATA_LOAD_RESULT")
frame:SetScript("OnEvent", function(_, event, ...) LL:OnEvent(event, ...) end)
