local _, LL = ...

local function makeButton(parent, text, width, height)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetSize(width, height)
    button:SetText(text)
    return button
end

function LL:BuildUI()
    if self.frame then return end
    local frame = CreateFrame("Frame", "LagomLedgerFrame", UIParent, "BackdropTemplate")
    frame:SetSize(680, 510)
    frame:SetPoint("CENTER")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:SetFrameStrata("DIALOG")
    frame:SetBackdrop({ bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background", edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", tile = true, tileSize = 32, edgeSize = 32, insets = { left = 11, right = 11, top = 11, bottom = 11 } })
    frame:Hide()
    self.frame = frame

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    title:SetPoint("TOP", 0, -22)
    title:SetText("Lagom Ledger")
    local subtitle = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    subtitle:SetPoint("TOP", title, "BOTTOM", 0, -5)
    subtitle:SetText("Guild-only data shared by OG lagom members using this addon")

    local close = makeButton(frame, "Close", 70, 22)
    close:SetPoint("TOPRIGHT", -18, -18)
    close:SetScript("OnClick", function() frame:Hide() end)

    local kill = makeButton(frame, "Record selected Alliance kill", 210, 24)
    kill:SetPoint("TOPLEFT", 24, -65)
    kill:SetScript("OnClick", function()
        local name = UnitName("target")
        local faction = UnitFactionGroup("target")
        if name and faction == "Alliance" then LL:RecordKill(name) else LL:Print("Select an Alliance player first.") end
    end)
    local sync = makeButton(frame, "Sync my profile", 130, 24)
    sync:SetPoint("LEFT", kill, "RIGHT", 8, 0)
    sync:SetScript("OnClick", function() LL:RefreshLocalProfile() end)
    local casino = makeButton(frame, "Open casino", 100, 24)
    casino:SetPoint("LEFT", sync, "RIGHT", 8, 0)
    casino:SetScript("OnClick", function() LL:ToggleCasino() end)
    local settings = makeButton(frame, "EUI settings", 110, 24)
    settings:SetPoint("LEFT", casino, "RIGHT", 8, 0)
    settings:SetScript("OnClick", function() LL:OpenEllesmereSettings() end)

    local board = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    board:SetPoint("TOPLEFT", 28, -105)
    board:SetText("PVP LEADERBOARD")
    local list = CreateFrame("ScrollingMessageFrame", nil, frame)
    list:SetPoint("TOPLEFT", 28, -130)
    list:SetSize(625, 155)
    list:SetFontObject(GameFontHighlightSmall)
    list:SetJustifyH("LEFT")
    list:SetFading(false)
    self.leaderboardText = list

    local bountyTitle = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    bountyTitle:SetPoint("TOPLEFT", 28, -300)
    bountyTitle:SetText("BOUNTY BOARD")
    local target = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
    target:SetPoint("TOPLEFT", 28, -325)
    target:SetSize(180, 24)
    target:SetAutoFocus(false)
    target:SetTextInsets(6, 6, 0, 0)
    self.bountyTarget = target
    local targetLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    targetLabel:SetPoint("BOTTOMLEFT", target, "TOPLEFT", 0, 3)
    targetLabel:SetText("Alliance character")
    local note = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
    note:SetPoint("LEFT", target, "RIGHT", 10, 0)
    note:SetSize(260, 24)
    note:SetAutoFocus(false)
    note:SetTextInsets(6, 6, 0, 0)
    self.bountyNote = note
    local noteLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    noteLabel:SetPoint("BOTTOMLEFT", note, "TOPLEFT", 0, 3)
    noteLabel:SetText("Reason / reward (optional)")
    local post = makeButton(frame, "Post bounty", 100, 24)
    post:SetPoint("LEFT", note, "RIGHT", 10, 0)
    post:SetScript("OnClick", function()
        if LL:AddBounty(target:GetText(), note:GetText()) then target:SetText(""); note:SetText("") end
    end)
    local bounties = CreateFrame("ScrollingMessageFrame", nil, frame)
    bounties:SetPoint("TOPLEFT", 28, -360)
    bounties:SetSize(625, 118)
    bounties:SetFontObject(GameFontHighlightSmall)
    bounties:SetJustifyH("LEFT")
    bounties:SetFading(false)
    self.bountyText = bounties
end

function LL:RefreshUI()
    if not self.frame then return end
    local players = {}
    for name, player in pairs(self.db.players) do table.insert(players, { name = name, data = player }) end
    table.sort(players, function(a, b) return a.data.kills > b.data.kills or (a.data.kills == b.data.kills and a.data.deaths < b.data.deaths) end)
    self.leaderboardText:Clear()
    self.leaderboardText:AddMessage("#   Member                                  Alliance kills    Deaths    Professions")
    for index, entry in ipairs(players) do
        local professions = #entry.data.professions > 0 and table.concat(entry.data.professions, ", ") or "Not shared"
        self.leaderboardText:AddMessage(string.format("%-2d  %-36s %5d             %5d    %s", index, entry.name, entry.data.kills or 0, entry.data.deaths or 0, professions))
    end
    self.bountyText:Clear()
    local active = 0
    for _, bounty in ipairs(self.db.bounties) do
        if bounty.active then
            active = active + 1
            self.bountyText:AddMessage(string.format("[%s] %s — posted by %s%s", bounty.id, bounty.target, bounty.postedBy, bounty.note ~= "" and (" | " .. bounty.note) or ""))
        end
    end
    if active == 0 then self.bountyText:AddMessage("No active bounties. Add the first Alliance target above.") end
    if self.RefreshCasinoUI then self:RefreshCasinoUI() end
end

function LL:ToggleUI()
    if not self:IsLagomMember() then self:Print("This addon is restricted to the OG lagom guild."); return end
    self:BuildUI()
    if self.frame:IsShown() then self.frame:Hide() else self:RefreshUI(); self.frame:Show() end
end

function LL:BuildCasinoUI()
    if self.casinoFrame then return end
    local frame = CreateFrame("Frame", "LagomLedgerCasinoFrame", UIParent, "BackdropTemplate")
    frame:SetSize(720, 615)
    frame:SetPoint("CENTER", 40, 20)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:SetFrameStrata("DIALOG")
    frame:SetBackdrop({ bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background", edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", tile = true, tileSize = 32, edgeSize = 32, insets = { left = 11, right = 11, top = 11, bottom = 11 } })
    frame:Hide()
    self.casinoFrame = frame

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    title:SetPoint("TOP", 0, -22)
    title:SetText("Lagom Ledger Casino")
    local rules = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    rules:SetPoint("TOP", title, "BOTTOM", 0, -5)
    rules:SetText("Guild games use /roll. Gold is traded manually after the result.")
    local close = makeButton(frame, "Close", 70, 22)
    close:SetPoint("TOPRIGHT", -18, -18)
    close:SetScript("OnClick", function() frame:Hide() end)

    local wager = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
    wager:SetPoint("TOPLEFT", 28, -82)
    wager:SetSize(130, 24)
    wager:SetAutoFocus(false)
    wager:SetNumeric(true)
    wager:SetTextInsets(6, 6, 0, 0)
    self.casinoWager = wager
    local wagerLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    wagerLabel:SetPoint("BOTTOMLEFT", wager, "TOPLEFT", 0, 3)
    wagerLabel:SetText("Wager (gold)")
    local gameTitle = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    gameTitle:SetPoint("TOPLEFT", 28, -122)
    gameTitle:SetText("GUILD GAME — CLASSIC, DEATH ROLL OR ELIMINATION")
    local mode = makeButton(frame, "", 145, 24)
    mode:SetPoint("TOPLEFT", 28, -147)
    self.casinoModeIndex = self.casinoModeIndex or 1
    self.casinoModeButton = mode
    local function UpdateModeButton()
        local selected = LL.CASINO_GAME_MODES[LL.casinoModeIndex]
        mode:SetText("Mode: " .. selected.label)
        LL.casinoModeDescription:SetText(selected.description)
    end
    mode:SetScript("OnClick", function()
        LL.casinoModeIndex = LL.casinoModeIndex % #LL.CASINO_GAME_MODES + 1
        UpdateModeButton()
    end)
    local host = makeButton(frame, "Open lobby", 100, 24)
    host:SetPoint("LEFT", mode, "RIGHT", 10, 0)
    host:SetScript("OnClick", function()
        local selected = LL.CASINO_GAME_MODES[LL.casinoModeIndex]
        LL:OpenCasinoGame(selected.key, wager:GetNumber())
    end)
    local join = makeButton(frame, "Join", 70, 24)
    join:SetPoint("LEFT", host, "RIGHT", 10, 0)
    join:SetScript("OnClick", function() LL:JoinCasinoGame() end)
    self.casinoGameJoin = join
    local begin = makeButton(frame, "Start", 70, 24)
    begin:SetPoint("LEFT", join, "RIGHT", 10, 0)
    begin:SetScript("OnClick", function() LL:StartCasinoGame() end)
    self.casinoGameStart = begin
    local gameRoll = makeButton(frame, "Roll", 70, 24)
    gameRoll:SetPoint("LEFT", begin, "RIGHT", 10, 0)
    gameRoll:SetScript("OnClick", function() LL:RollCasinoGame() end)
    self.casinoGameRoll = gameRoll
    local cancel = makeButton(frame, "Close", 70, 24)
    cancel:SetPoint("LEFT", gameRoll, "RIGHT", 10, 0)
    cancel:SetScript("OnClick", function() LL:CloseCasinoGame() end)
    self.casinoGameClose = cancel
    local gameDescription = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    gameDescription:SetPoint("TOPLEFT", 28, -178)
    gameDescription:SetPoint("TOPRIGHT", -28, -178)
    gameDescription:SetJustifyH("LEFT")
    self.casinoModeDescription = gameDescription
    UpdateModeButton()
    local groupState = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    groupState:SetPoint("TOPLEFT", 28, -200)
    groupState:SetPoint("TOPRIGHT", -28, -200)
    groupState:SetJustifyH("LEFT")
    self.casinoGroupState = groupState

    local winnersTitle = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    winnersTitle:SetPoint("TOPLEFT", 28, -237)
    winnersTitle:SetText("TOP 10 — MOST GOLD WON")
    local winners = CreateFrame("ScrollingMessageFrame", nil, frame)
    winners:SetPoint("TOPLEFT", 28, -261)
    winners:SetSize(305, 165)
    winners:SetFontObject(GameFontHighlightSmall)
    winners:SetJustifyH("LEFT")
    winners:SetFading(false)
    self.casinoWinners = winners

    local losersTitle = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    losersTitle:SetPoint("TOPLEFT", 382, -237)
    losersTitle:SetText("TOP 10 — MOST GOLD LOST")
    local losers = CreateFrame("ScrollingMessageFrame", nil, frame)
    losers:SetPoint("TOPLEFT", 382, -261)
    losers:SetSize(305, 165)
    losers:SetFontObject(GameFontHighlightSmall)
    losers:SetJustifyH("LEFT")
    losers:SetFading(false)
    self.casinoLosers = losers

    local historyTitle = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    historyTitle:SetPoint("TOPLEFT", 28, -444)
    historyTitle:SetText("LAST 5 GAMES")
    local history = CreateFrame("ScrollingMessageFrame", nil, frame)
    history:SetPoint("TOPLEFT", 28, -467)
    history:SetSize(660, 95)
    history:SetFontObject(GameFontHighlightSmall)
    history:SetJustifyH("LEFT")
    history:SetFading(false)
    self.casinoHistoryText = history
end

function LL:RefreshCasinoUI()
    if not self.casinoFrame then return end
    local entries = {}
    for name, stats in pairs(self.db.casinoStats) do table.insert(entries, { name = name, stats = stats }) end
    local function FillList(target, field, emptyText)
        local sorted = {}
        for _, entry in ipairs(entries) do table.insert(sorted, entry) end
        table.sort(sorted, function(a, b) return (a.stats[field] or 0) > (b.stats[field] or 0) end)
        target:Clear()
        local count = 0
        for _, entry in ipairs(sorted) do
            if entry.stats[field] > 0 then
                count = count + 1
                target:AddMessage(string.format("%2d. %-28s %d gold", count, entry.name, entry.stats[field]))
                if count == 10 then break end
            end
        end
        if count == 0 then target:AddMessage(emptyText) end
    end
    FillList(self.casinoWinners, "wonGold", "No completed casino games yet.")
    FillList(self.casinoLosers, "lostGold", "No completed casino games yet.")
    self.casinoHistoryText:Clear()
    if #self.db.casinoHistory == 0 then
        self.casinoHistoryText:AddMessage("No completed casino games yet.")
    else
        for _, result in ipairs(self.db.casinoHistory) do
            if result.summary then
                self.casinoHistoryText:AddMessage(result.mode .. ": " .. result.summary)
            else
                self.casinoHistoryText:AddMessage(string.format("%s beat %s — %d gold (%d-%d)", result.winner, result.loser, result.wager, result.hostRoll or 0, result.challengerRoll or 0))
            end
        end
    end
    local groupGame = self:GetGroupCasinoGame()
    self.casinoGameJoin:SetEnabled(groupGame and groupGame.status == "lobby" and not groupGame.playerSet[self:PlayerName()])
    self.casinoGameStart:SetEnabled(groupGame and groupGame.status == "lobby" and self:IsGroupCasinoHost(groupGame))
    self.casinoGameRoll:SetEnabled(groupGame and groupGame.status == "running" and self:FindGroupPlayer(groupGame, self:PlayerName()) ~= nil)
    self.casinoGameClose:SetEnabled(groupGame and self:IsGroupCasinoHost(groupGame))
    if groupGame then
        local mode = self:GetCasinoGameMode(groupGame.mode)
        self.casinoGroupState:SetText((mode and mode.label or groupGame.mode) .. " — " .. #groupGame.players .. " player(s). " .. (groupGame.message or (groupGame.status == "lobby" and "Lobby is open." or "Game in progress.")))
    else
        self.casinoGroupState:SetText("No guild game is open.")
    end
end

function LL:ToggleCasino()
    if not self:IsLagomMember() then self:Print("This addon is restricted to the OG lagom guild."); return end
    self:BuildCasinoUI()
    if self.casinoFrame:IsShown() then self.casinoFrame:Hide() else self:RefreshCasinoUI(); self.casinoFrame:Show() end
end

