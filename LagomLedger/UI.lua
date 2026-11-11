local _, LL = ...

local W, H, ROWS, ROW_H = 600, 470, 15, 22
local FONT = "Fonts\\FRIZQT__.TTF"
local board, currentTab, offset, tabButtons, rows, entry, footer, refreshBoard

local function makeButton(parent, label, width, height)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetSize(width, height)
    button:SetText(label)
    return button
end

local function text(parent, size, red, green, blue)
    local label = parent:CreateFontString(nil, "OVERLAY")
    label:SetFont(FONT, size, "")
    label:SetShadowColor(0, 0, 0, 1)
    label:SetShadowOffset(1, -1)
    label:SetTextColor(red or 1, green or 1, blue or 1)
    label:SetJustifyH("LEFT")
    label:SetWordWrap(false)
    return label
end

local function coloredName(name, class)
    local color = class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
    return color and color.colorStr and "|c" .. color.colorStr .. name .. "|r" or name
end

local function formatProfessions(value)
    local output = {}
    for name, rank in (value or ""):gmatch("([^,:]+):(%d+)") do
        table.insert(output, name .. " |cffaaaaaa" .. rank .. "|r")
    end
    return #output > 0 and table.concat(output, ", ") or "|cff666666-|r"
end

local function ago(timestamp)
    local elapsed = (GetServerTime and GetServerTime() or time()) - (timestamp or 0)
    if elapsed < 3600 then return math.max(1, math.floor(elapsed / 60)) .. "m" end
    if elapsed < 86400 then return math.floor(elapsed / 3600) .. "h" end
    return math.floor(elapsed / 86400) .. "d"
end

local function numberText(value)
    return BreakUpLargeNumbers and BreakUpLargeNumbers(value) or tostring(value)
end

function LL:BuildUI()
    if board then self.frame = board; return end
    board = CreateFrame("Frame", "LagomLedgerFrame", UIParent, "BackdropTemplate")
    board:SetSize(W, H)
    board:SetPoint("CENTER")
    board:SetFrameStrata("HIGH")
    board:SetClampedToScreen(true)
    board:SetMovable(true)
    board:EnableMouse(true)
    board:EnableMouseWheel(true)
    board:RegisterForDrag("LeftButton")
    board:SetScript("OnDragStart", board.StartMoving)
    board:SetScript("OnDragStop", board.StopMovingOrSizing)
    board:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", edgeSize = 28, insets = { left = 8, right = 8, top = 8, bottom = 8 } })
    board:SetBackdropColor(0.06, 0.05, 0.05, 0.96)
    board:Hide()
    table.insert(UISpecialFrames, "LagomLedgerFrame")
    self.frame = board

    local title = text(board, 18, 1, 0.82, 0.2)
    title:SetPoint("TOPLEFT", 20, -16)
    title:SetText("Lagom Ledger")
    local subtitle = text(board, 11, 0.7, 0.7, 0.7)
    subtitle:SetPoint("LEFT", title, "RIGHT", 10, -1)
    subtitle:SetText("OG Lagom guild board")
    self.boardSubtitle = subtitle
    local close = CreateFrame("Button", nil, board, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -4, -4)
    local casino = makeButton(board, "Casino", 66, 22)
    casino:SetPoint("RIGHT", close, "LEFT", -3, -1)
    casino:SetScript("OnClick", function() LL:ToggleCasino() end)

    local tabs = { "Kills", "Deaths", "Bounties", "Professions" }
    currentTab, offset, tabButtons = 1, 0, {}
    for index, name in ipairs(tabs) do
        local button = makeButton(board, name, 110, 24)
        button:SetPoint("TOPLEFT", 18 + (index - 1) * 114, -44)
        button:SetScript("OnClick", function() currentTab, offset = index, 0; refreshBoard() end)
        tabButtons[index] = button
    end

    entry = CreateFrame("Frame", nil, board)
    entry:SetPoint("TOPLEFT", 18, -76)
    entry:SetSize(W - 36, 26)
    local nameLabel = text(entry, 11, 0.8, 0.8, 0.8)
    nameLabel:SetPoint("LEFT", 0, 0)
    nameLabel:SetText("Player")
    local nameBox = CreateFrame("EditBox", nil, entry, "InputBoxTemplate")
    nameBox:SetSize(110, 20)
    nameBox:SetPoint("LEFT", 46, 0)
    nameBox:SetAutoFocus(false)
    nameBox:SetMaxLetters(40)
    local noteLabel = text(entry, 11, 0.8, 0.8, 0.8)
    noteLabel:SetPoint("LEFT", 166, 0)
    noteLabel:SetText("Why")
    local noteBox = CreateFrame("EditBox", nil, entry, "InputBoxTemplate")
    noteBox:SetSize(190, 20)
    noteBox:SetPoint("LEFT", 196, 0)
    noteBox:SetAutoFocus(false)
    noteBox:SetMaxLetters(60)
    local function postBounty()
        if LL:PostBounty(nameBox:GetText(), noteBox:GetText()) then nameBox:SetText(""); noteBox:SetText("") end
        nameBox:ClearFocus()
        noteBox:ClearFocus()
    end
    nameBox:SetScript("OnEnterPressed", postBounty)
    noteBox:SetScript("OnEnterPressed", postBounty)
    nameBox:SetScript("OnEscapePressed", nameBox.ClearFocus)
    noteBox:SetScript("OnEscapePressed", noteBox.ClearFocus)
    local post = makeButton(entry, "Post", 70, 22)
    post:SetPoint("LEFT", 394, 0)
    post:SetScript("OnClick", postBounty)
    local target = makeButton(entry, "Use target", 96, 22)
    target:SetPoint("LEFT", 468, 0)
    target:SetScript("OnClick", function()
        if UnitExists("target") and UnitIsPlayer("target") and UnitIsEnemy("player", "target") then
            local name = UnitName("target")
            if type(name) == "string" and not (issecretvalue and issecretvalue(name)) then nameBox:SetText(name); return end
        end
        LL:Print("Target an enemy player first.")
    end)

    local columns, header, headerY = 5, {}, -108
    for column = 1, columns do header[column] = text(board, 11, 1, 0.82, 0.2) end
    local line = board:CreateTexture(nil, "ARTWORK")
    line:SetColorTexture(1, 0.82, 0.2, 0.4)
    line:SetHeight(1)
    line:SetPoint("TOPLEFT", 18, headerY - 16)
    line:SetPoint("TOPRIGHT", -18, headerY - 16)
    rows = {}
    for index = 1, ROWS do
        local row = CreateFrame("Frame", nil, board)
        row:SetSize(W - 36, ROW_H)
        row:SetPoint("TOPLEFT", 18, headerY - 20 - (index - 1) * ROW_H)
        if index % 2 == 0 then
            local stripe = row:CreateTexture(nil, "BACKGROUND")
            stripe:SetAllPoints()
            stripe:SetColorTexture(1, 1, 1, 0.04)
        end
        row.cells = {}
        for column = 1, columns do row.cells[column] = text(row, 12) end
        row.action = makeButton(row, "", 70, 18)
        row.action:SetPoint("RIGHT", 0, 0)
        row.action:Hide()
        rows[index] = row
    end
    footer = text(board, 11, 0.6, 0.6, 0.6)
    footer:SetPoint("BOTTOMLEFT", 20, 16)
    local completeTarget = makeButton(board, "Complete target", 120, 22)
    completeTarget:SetPoint("BOTTOMRIGHT", -20, 12)
    completeTarget:SetScript("OnClick", function() LL:CompleteSelectedBounties() end)

    local function layout(definitions)
        for column = 1, columns do
            local definition = definitions[column]
            header[column]:SetShown(definition ~= nil)
            if definition then
                header[column]:ClearAllPoints()
                header[column]:SetPoint("TOPLEFT", 18 + definition[2], headerY)
                header[column]:SetText(definition[1])
            end
            for rowIndex = 1, ROWS do
                local cell = rows[rowIndex].cells[column]
                cell:SetShown(definition ~= nil)
                if definition then
                    cell:ClearAllPoints()
                    cell:SetPoint("LEFT", definition[2], 0)
                    cell:SetWidth(definition[3])
                end
            end
        end
    end

    local function buildRows()
        local data, tab = {}, tabs[currentTab]
        if tab == "Kills" or tab == "Deaths" then
            local key, members = tab == "Kills" and "kills" or "deaths", LL:Members()
            table.sort(members, function(left, right)
                if left[key] ~= right[key] then return left[key] > right[key] end
                return left.name < right.name
            end)
            layout({ { "#", 0, 30 }, { "Name", 36, 200 }, { "Level", 250, 50 }, { tab == "Kills" and "Alliance players killed" or "Deaths", 320, 220 } })
            for index, member in ipairs(members) do
                data[index] = { cells = { index, coloredName(member.name, member.class), member.level > 0 and member.level or "", numberText(member[key]) } }
            end
            footer:SetText(tab == "Kills" and "Counts honorable kills of enemy players." or "Counts every death, whatever the cause.")
        elseif tab == "Bounties" then
            layout({ { "Wanted", 0, 120 }, { "Posted by", 126, 96 }, { "Why", 228, 190 }, { "Status", 424, 76 } })
            for index, bounty in ipairs(LL:Bounties()) do
                local status = bounty.active and ("|cffff5555Open|r " .. ago(bounty.createdAt)) or (bounty.canceled and "|cff888888Removed|r" or "|cff55ff55" .. (bounty.completedBy or "?") .. "|r")
                local action = bounty.active and { id = bounty.id, remove = LL:LegacyNamesMatch(bounty.postedBy, LL:PlayerName()) } or nil
                data[index] = { cells = { bounty.active and ("|cffff5555" .. bounty.target .. "|r") or ("|cff888888" .. bounty.target .. "|r"), bounty.postedBy, bounty.note or "", status }, action = action }
            end
            footer:SetText("Bounties can be claimed automatically after a verified honorable kill, or completed manually.")
        else
            local members = LL:Members()
            table.sort(members, function(left, right) return left.name < right.name end)
            layout({ { "Name", 0, 130 }, { "Level", 136, 40 }, { "Professions", 184, 220 }, { "Secondary", 410, 154 } })
            for index, member in ipairs(members) do
                local primary = member.primaryProfessions ~= "" and formatProfessions(member.primaryProfessions) or table.concat(member.professions, ", ")
                data[index] = { cells = { coloredName(member.name, member.class), member.level > 0 and member.level or "", primary ~= "" and primary or "|cff666666-|r", formatProfessions(member.secondaryProfessions) } }
            end
            footer:SetText("Each character's professions and skill, as last reported by their addon.")
        end
        return data
    end

    refreshBoard = function()
        if not board:IsShown() or not LL.db then return end
        for index, button in ipairs(tabButtons) do if index == currentTab then button:LockHighlight() else button:UnlockHighlight() end end
        entry:SetShown(tabs[currentTab] == "Bounties")
        completeTarget:SetShown(tabs[currentTab] == "Bounties")
        subtitle:SetText(LL:IsLagomMember() and "Guild board" or "|cffff5555Only for members of " .. LL.GUILD_NAME .. "|r")
        local data, maxOffset = buildRows(), 0
        maxOffset = math.max(0, #data - ROWS)
        if offset > maxOffset then offset = maxOffset end
        for index = 1, ROWS do
            local row, item = rows[index], data[index + offset]
            row:SetShown(item ~= nil)
            if item then
                for column = 1, columns do row.cells[column]:SetText(item.cells[column] ~= nil and tostring(item.cells[column]) or "") end
                row.action:SetShown(item.action ~= nil)
                if item.action then
                    row.action:SetText(item.action.remove and "Remove" or "Complete")
                    local action = item.action
                    row.action:SetScript("OnClick", function() if action.remove then LL:RemoveBounty(action.id) else LL:CompleteBounty(action.id) end end)
                end
            end
        end
        if #data == 0 then
            rows[1]:Show()
            rows[1].action:Hide()
            for column = 1, columns do rows[1].cells[column]:SetText("") end
            rows[1].cells[1]:SetWidth(W - 40)
            rows[1].cells[1]:SetText(tabs[currentTab] == "Bounties" and "|cff888888No bounties yet. Post one above.|r" or "|cff888888Nothing to show yet.|r")
        end
    end
    board:SetScript("OnShow", refreshBoard)
    board:SetScript("OnMouseWheel", function(_, delta) offset = math.max(0, offset - delta * 3); refreshBoard() end)
end

function LL:SetBoardPage(page)
    local tabs = { leaderboard = 1, kills = 1, deaths = 2, bounty = 3, bounties = 3, professions = 4, profs = 4 }
    currentTab, offset = tabs[strlower(page or "")] or 1, 0
    self.selectedBoardPage = page
    self:RefreshUI()
end

function LL:RefreshUI()
    if refreshBoard then refreshBoard() end
    if self.RefreshCasinoUI then self:RefreshCasinoUI() end
end

function LL:ToggleUI(tab)
    if not self:IsLagomMember() then self:Print("This addon is restricted to the OG Lagom guild."); return end
    self:BuildUI()
    if tab then self:SetBoardPage(tab) end
    if board:IsShown() and not tab then board:Hide() else board:Show(); self:RefreshUI() end
end

function LagomLedger_OnAddonCompartmentClick()
    LL:ToggleUI()
end

function LL:UpdateMinimapButton()
    if not self.minimapButton or not self.db then return end
    local angle = math.rad(self.db.minimap.angle or 225)
    self.minimapButton:ClearAllPoints()
    self.minimapButton:SetPoint("CENTER", Minimap, "CENTER", math.cos(angle) * 82, math.sin(angle) * 82)
end

function LL:BuildMinimapButton()
    if self.minimapButton or not self.db then return end
    local button = CreateFrame("Button", "LagomLedgerMinimapButton", Minimap, "BackdropTemplate")
    button:SetSize(32, 32)
    button:SetFrameStrata("MEDIUM")
    button:SetFrameLevel(8)
    button:SetMovable(true)
    button:RegisterForDrag("LeftButton")
    button:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 2 })
    button:SetBackdropColor(0.06, 0.05, 0.05, 0.96)
    button:SetBackdropBorderColor(1, 0.82, 0.2, 1)
    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetTexture("Interface\\Icons\\Achievement_PVP_H_01")
    icon:SetPoint("TOPLEFT", 3, -3)
    icon:SetPoint("BOTTOMRIGHT", -3, 3)
    button:SetScript("OnDragStart", function(self) self:StartMoving() end)
    button:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local minimapX, minimapY = Minimap:GetCenter()
        local buttonX, buttonY = self:GetCenter()
        if minimapX and minimapY and buttonX and buttonY then
            LL.db.minimap.angle = math.deg(math.atan2(buttonY - minimapY, buttonX - minimapX))
            LL:UpdateMinimapButton()
        end
    end)
    button:SetScript("OnClick", function(_, mouseButton) if mouseButton == "RightButton" then LL:ToggleCasino() else LL:ToggleUI() end end)
    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine("Lagom Ledger")
        GameTooltip:AddLine("Left-click: open guild board", 0.70, 0.82, 0.95)
        GameTooltip:AddLine("Right-click: open casino", 0.70, 0.82, 0.95)
        GameTooltip:AddLine("Drag: move minimap button", 0.55, 0.65, 0.75)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function() GameTooltip:Hide() end)
    self.minimapButton = button
    self:UpdateMinimapButton()
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
    local function updateMode()
        local selected = LL.CASINO_GAME_MODES[LL.casinoModeIndex]
        mode:SetText("Mode: " .. selected.label)
        LL.casinoModeDescription:SetText(selected.description)
    end
    mode:SetScript("OnClick", function() LL.casinoModeIndex = LL.casinoModeIndex % #LL.CASINO_GAME_MODES + 1; updateMode() end)
    local host = makeButton(frame, "Open lobby", 100, 24)
    host:SetPoint("LEFT", mode, "RIGHT", 10, 0)
    host:SetScript("OnClick", function() LL:OpenCasinoGame(LL.CASINO_GAME_MODES[LL.casinoModeIndex].key, wager:GetNumber()) end)
    local join = makeButton(frame, "Join", 70, 24)
    join:SetPoint("LEFT", host, "RIGHT", 10, 0)
    join:SetScript("OnClick", function() LL:JoinCasinoGame() end)
    self.casinoGameJoin = join
    local begin = makeButton(frame, "Start", 70, 24)
    begin:SetPoint("LEFT", join, "RIGHT", 10, 0)
    begin:SetScript("OnClick", function() LL:StartCasinoGame() end)
    self.casinoGameStart = begin
    local roll = makeButton(frame, "Roll", 70, 24)
    roll:SetPoint("LEFT", begin, "RIGHT", 10, 0)
    roll:SetScript("OnClick", function() LL:RollCasinoGame() end)
    self.casinoGameRoll = roll
    local cancel = makeButton(frame, "Close", 70, 24)
    cancel:SetPoint("LEFT", roll, "RIGHT", 10, 0)
    cancel:SetScript("OnClick", function() LL:CloseCasinoGame() end)
    self.casinoGameClose = cancel
    local description = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    description:SetPoint("TOPLEFT", 28, -178)
    description:SetPoint("TOPRIGHT", -28, -178)
    description:SetJustifyH("LEFT")
    self.casinoModeDescription = description
    updateMode()
    local state = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    state:SetPoint("TOPLEFT", 28, -200)
    state:SetPoint("TOPRIGHT", -28, -200)
    state:SetJustifyH("LEFT")
    self.casinoGroupState = state
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
    local function fill(target, field)
        local sorted = {}
        for _, entry in ipairs(entries) do table.insert(sorted, entry) end
        table.sort(sorted, function(left, right) return (left.stats[field] or 0) > (right.stats[field] or 0) end)
        target:Clear()
        local count = 0
        for _, entry in ipairs(sorted) do
            if entry.stats[field] > 0 then
                count = count + 1
                target:AddMessage(string.format("%2d. %-28s %d gold", count, entry.name, entry.stats[field]))
                if count == 10 then break end
            end
        end
        if count == 0 then target:AddMessage("No completed casino games yet.") end
    end
    fill(self.casinoWinners, "wonGold")
    fill(self.casinoLosers, "lostGold")
    self.casinoHistoryText:Clear()
    if #self.db.casinoHistory == 0 then
        self.casinoHistoryText:AddMessage("No completed casino games yet.")
    else
        for _, result in ipairs(self.db.casinoHistory) do
            self.casinoHistoryText:AddMessage(result.summary and (result.mode .. ": " .. result.summary) or string.format("%s beat %s — %d gold", result.winner, result.loser, result.wager))
        end
    end
    local game = self:GetGroupCasinoGame()
    self.casinoGameJoin:SetEnabled(game and game.status == "lobby" and not game.playerSet[self:PlayerName()])
    self.casinoGameStart:SetEnabled(game and game.status == "lobby" and self:IsGroupCasinoHost(game))
    self.casinoGameRoll:SetEnabled(game and game.status == "running" and self:FindGroupPlayer(game, self:PlayerName()) ~= nil)
    self.casinoGameClose:SetEnabled(game and self:IsGroupCasinoHost(game))
    if game then
        local mode = self:GetCasinoGameMode(game.mode)
        self.casinoGroupState:SetText((mode and mode.label or game.mode) .. " — " .. #game.players .. " player(s). " .. (game.message or (game.status == "lobby" and "Lobby is open." or "Game in progress.")))
    else
        self.casinoGroupState:SetText("No guild game is open.")
    end
end

function LL:ToggleCasino()
    if not self:IsLagomMember() then self:Print("This addon is restricted to the OG Lagom guild."); return end
    self:BuildCasinoUI()
    if self.casinoFrame:IsShown() then self.casinoFrame:Hide() else self:RefreshCasinoUI(); self.casinoFrame:Show() end
end

