local _, LL = ...

local W, H, ROWS, ROW_H = 780, 630, 15, 22
local CONTENT_W = 568
local FONT = "Fonts\\FRIZQT__.TTF"
local board, currentTab, offset, tabButtons, rows, entry, footer, refreshBoard, layoutBoard, constrainBoard, leaderboardScope

local JOURNAL = {
    frame = { 0.035, 0.028, 0.020, 0.98 }, panel = { 0.095, 0.067, 0.035, 0.96 },
    header = { 0.19, 0.115, 0.042, 0.98 }, row = { 0.11, 0.075, 0.035, 0.90 },
    selected = { 0.32, 0.18, 0.055, 0.98 }, border = { 0.58, 0.39, 0.13, 1 },
    title = { 1.00, 0.82, 0.30 }, text = { 0.93, 0.86, 0.70 }, muted = { 0.70, 0.62, 0.48 },
}

local function setBackdrop(frame, background, border, edgeSize, inset)
    frame:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = true, tileSize = 16,
        edgeSize = edgeSize or 12, insets = { left = inset or 3, right = inset or 3, top = inset or 3, bottom = inset or 3 } })
    frame:SetBackdropColor(unpack(background))
    frame:SetBackdropBorderColor(unpack(border or JOURNAL.border))
end

local function makePanel(parent, background)
    local panel = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    setBackdrop(panel, background or JOURNAL.panel)
    return panel
end

local function makeButton(parent, label, width, height)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetSize(width, height)
    button:SetText(label)
    return button
end

local function makeNavigationButton(parent, label, iconPath)
    local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
    button:SetSize(132, 38)
    setBackdrop(button, JOURNAL.row, JOURNAL.border, 9, 2)
    button.icon = button:CreateTexture(nil, "ARTWORK")
    button.icon:SetTexture(iconPath)
    button.icon:SetSize(22, 22)
    button.icon:SetPoint("LEFT", 9, 0)
    button.label = button:CreateFontString(nil, "OVERLAY")
    button.label:SetFont(FONT, 12, "")
    button.label:SetPoint("LEFT", button.icon, "RIGHT", 8, 0)
    button.label:SetPoint("RIGHT", -7, 0)
    button.label:SetJustifyH("LEFT")
    button.label:SetText(label)
    button:SetScript("OnEnter", function(self) if not self.selected then self:SetBackdropColor(0.18, 0.11, 0.045, 0.98) end end)
    button:SetScript("OnLeave", function(self) if not self.selected then self:SetBackdropColor(unpack(JOURNAL.row)) end end)
    return button
end

local function styleNavigationButton(button, selected)
    button.selected = selected
    if selected then
        button:SetBackdropColor(unpack(JOURNAL.selected)); button:SetBackdropBorderColor(unpack(JOURNAL.title)); button.label:SetTextColor(unpack(JOURNAL.title))
    else
        button:SetBackdropColor(unpack(JOURNAL.row)); button:SetBackdropBorderColor(unpack(JOURNAL.border)); button.label:SetTextColor(unpack(JOURNAL.text))
    end
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
    for name, rank in (value or ""):gmatch("([^,:]+):(%d+)") do table.insert(output, name .. " |cffaaaaaa" .. rank .. "|r") end
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

local function duration(seconds)
    seconds = math.floor(tonumber(seconds) or 0)
    if seconds <= 0 then return "-" end
    if seconds < 60 then return seconds .. "s" end
    local days, hours = math.floor(seconds / 86400), math.floor(seconds % 86400 / 3600)
    local minutes = math.floor(seconds % 3600 / 60)
    if days > 0 then return days .. "d " .. hours .. "h" end
    if hours > 0 then return hours .. "h " .. minutes .. "m" end
    return minutes .. "m"
end

function LL:BuildUI()
    if board then self.frame = board; return end
    board = CreateFrame("Frame", "LagomLedgerFrame", UIParent, "BackdropTemplate")
    board:SetSize(W, H)
    board:SetPoint("CENTER")
    board:SetFrameStrata("HIGH")
    board:SetClampedToScreen(true)
    board:SetMovable(true)
    board:SetResizable(true)
    local adjustingSize = false
    constrainBoard = function()
        if adjustingSize then return end
        local maxWidth = math.max(W, math.floor((UIParent:GetWidth() or W) - 40))
        local maxHeight = math.max(H, math.floor((UIParent:GetHeight() or H) - 40))
        if board.SetResizeBounds then
            board:SetResizeBounds(W, 560, maxWidth, maxHeight)
        else
            board:SetMinResize(W, 560)
            if board.SetMaxResize then board:SetMaxResize(maxWidth, maxHeight) end
        end
        if board:GetWidth() > maxWidth or board:GetHeight() > maxHeight then
            adjustingSize = true
            board:SetSize(math.min(board:GetWidth(), maxWidth), math.min(board:GetHeight(), maxHeight))
            adjustingSize = false
        end
    end
    constrainBoard()
    board:EnableMouse(true)
    board:EnableMouseWheel(true)
    board:RegisterForDrag("LeftButton")
    board:SetScript("OnDragStart", board.StartMoving)
    board:SetScript("OnDragStop", board.StopMovingOrSizing)
    setBackdrop(board, JOURNAL.frame, JOURNAL.border, 16, 5)
    board:Hide()
    table.insert(UISpecialFrames, "LagomLedgerFrame")
    self.frame = board

    local art = board:CreateTexture(nil, "BACKGROUND")
    art:SetTexture("Interface\\QuestFrame\\QuestBG")
    art:SetPoint("TOPLEFT", 12, -76)
    art:SetPoint("BOTTOMRIGHT", -12, 12)
    art:SetAlpha(0.08)
    local header = makePanel(board, JOURNAL.header)
    header:SetPoint("TOPLEFT", 10, -10)
    header:SetPoint("TOPRIGHT", -10, -10)
    header:SetHeight(62)
    local title = text(header, 20, unpack(JOURNAL.title))
    title:SetPoint("TOPLEFT", 18, -13)
    title:SetText("LAGOM LEDGER")
    local subtitle = text(header, 11, unpack(JOURNAL.muted))
    subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 1, -3)
    subtitle:SetText("Guild journal")
    self.boardSubtitle = subtitle
    local close = CreateFrame("Button", nil, header, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", 0, 0)
    close:SetScript("OnClick", function() board:Hide() end)
    local resetSize = makeButton(header, "Reset size", 82, 22)
    resetSize:SetPoint("RIGHT", close, "LEFT", -8, -6)
    resetSize:SetScript("OnClick", function() LL:ResetBoardSize() end)
    local resize = CreateFrame("Button", nil, board)
    resize:SetSize(18, 18)
    resize:SetPoint("BOTTOMRIGHT", -8, 8)
    resize:SetFrameLevel(board:GetFrameLevel() + 10)
    resize:EnableMouse(true)
    local resizeTexture = resize:CreateTexture(nil, "ARTWORK")
    resizeTexture:SetAllPoints()
    resizeTexture:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    resize:SetScript("OnMouseDown", function(_, mouseButton)
        if mouseButton == "LeftButton" then board:StartSizing("BOTTOMRIGHT") end
    end)
    resize:SetScript("OnMouseUp", function(_, mouseButton)
        if mouseButton == "LeftButton" then board:StopMovingOrSizing(); constrainBoard(); layoutBoard(); refreshBoard() end
    end)
    resize:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine("Drag to resize", 0.70, 0.82, 0.95)
        GameTooltip:Show()
    end)
    resize:SetScript("OnLeave", function() GameTooltip:Hide() end)
    local navigation = makePanel(board)
    navigation:SetPoint("TOPLEFT", 10, -84)
    navigation:SetPoint("BOTTOMLEFT", 10, 10)
    navigation:SetWidth(150)
    local navigationTitle = text(navigation, 10, unpack(JOURNAL.muted))
    navigationTitle:SetPoint("TOPLEFT", 12, -12)
    navigationTitle:SetText("GUILD RECORDS")
    local content = makePanel(board)
    content:SetPoint("TOPLEFT", navigation, "TOPRIGHT", 10, 0)
    content:SetPoint("BOTTOMRIGHT", board, "BOTTOMRIGHT", -10, 10)
    self.content = content
    local recordsContent = CreateFrame("Frame", nil, content)
    recordsContent:SetAllPoints()
    self.recordsContent = recordsContent

    local tabs = { "Kills", "Deaths", "Bounties", "Professions", "Casino" }
    local tabIcons = { "Interface\\Icons\\Achievement_PVP_H_01", "Interface\\Icons\\Spell_Shadow_SoulLeech", "Interface\\Icons\\INV_Misc_Note_01", "Interface\\Icons\\INV_Misc_Book_09", "Interface\\Icons\\INV_Misc_Coin_01" }
    currentTab, offset, tabButtons = 1, 0, {}
    for index, name in ipairs(tabs) do
        local button = makeNavigationButton(navigation, name, tabIcons[index])
        button:SetPoint("TOPLEFT", 9, -34 - (index - 1) * 44)
        button:SetScript("OnClick", function()
            if name == "Casino" then LL:BuildCasinoUI() end
            currentTab, offset = index, 0
            refreshBoard()
        end)
        tabButtons[index] = button
    end
    layoutBoard = function()
        local navigationWidth = math.max(150, math.min(220, math.floor(board:GetWidth() * 0.18)))
        navigation:SetWidth(navigationWidth)
        content:ClearAllPoints()
        content:SetPoint("TOPLEFT", navigation, "TOPRIGHT", 10, 0)
        content:SetPoint("BOTTOMRIGHT", board, "BOTTOMRIGHT", -10, 10)
        for index, button in ipairs(tabButtons) do
            button:ClearAllPoints()
            button:SetPoint("TOPLEFT", navigation, "TOPLEFT", 9, -34 - (index - 1) * 44)
            button:SetPoint("TOPRIGHT", navigation, "TOPRIGHT", -9, -34 - (index - 1) * 44)
        end
    end

    entry = CreateFrame("Frame", nil, recordsContent)
    entry:SetPoint("TOPLEFT", 16, -16)
    entry:SetPoint("TOPRIGHT", -16, -16)
    entry:SetHeight(26)
    local nameLabel = text(entry, 11, unpack(JOURNAL.muted))
    nameLabel:SetPoint("LEFT", 0, 0)
    nameLabel:SetText("Player")
    local nameBox = CreateFrame("EditBox", nil, entry, "InputBoxTemplate")
    nameBox:SetSize(112, 20)
    nameBox:SetPoint("LEFT", 45, 0)
    nameBox:SetAutoFocus(false)
    nameBox:SetMaxLetters(40)
    local noteLabel = text(entry, 11, unpack(JOURNAL.muted))
    noteLabel:SetPoint("LEFT", 166, 0)
    noteLabel:SetText("Why")
    local noteBox = CreateFrame("EditBox", nil, entry, "InputBoxTemplate")
    noteBox:SetSize(180, 20)
    noteBox:SetPoint("LEFT", 198, 0)
    noteBox:SetAutoFocus(false)
    noteBox:SetMaxLetters(60)
    local function postBounty()
        if LL:PostBounty(nameBox:GetText(), noteBox:GetText()) then nameBox:SetText(""); noteBox:SetText("") end
        nameBox:ClearFocus(); noteBox:ClearFocus()
    end
    nameBox:SetScript("OnEnterPressed", postBounty)
    noteBox:SetScript("OnEnterPressed", postBounty)
    nameBox:SetScript("OnEscapePressed", nameBox.ClearFocus)
    noteBox:SetScript("OnEscapePressed", noteBox.ClearFocus)
    local post = makeButton(entry, "Post", 58, 22)
    post:SetPoint("LEFT", 384, 0)
    post:SetScript("OnClick", postBounty)
    local target = makeButton(entry, "Use target", 92, 22)
    target:SetPoint("LEFT", 447, 0)
    target:SetScript("OnClick", function()
        if UnitExists("target") and UnitIsPlayer("target") and UnitIsEnemy("player", "target") then
            local name = UnitName("target")
            if type(name) == "string" and not (issecretvalue and issecretvalue(name)) then nameBox:SetText(name); return end
        end
        LL:Print("Target an enemy player first.")
    end)

    local columns, columnHeaders, headerY, rowHeight = 6, {}, -55, ROW_H
    for column = 1, columns do columnHeaders[column] = text(recordsContent, 11, unpack(JOURNAL.title)) end
    local line = recordsContent:CreateTexture(nil, "ARTWORK")
    line:SetColorTexture(unpack(JOURNAL.border))
    line:SetHeight(1)
    line:SetPoint("TOPLEFT", 16, headerY - 16)
    line:SetPoint("TOPRIGHT", -16, headerY - 16)
    rows = {}
    for index = 1, ROWS do
        local row = CreateFrame("Frame", nil, recordsContent)
        row:SetSize(CONTENT_W, rowHeight)
        row:SetPoint("TOPLEFT", 16, headerY - 20 - (index - 1) * rowHeight)
        row.background = row:CreateTexture(nil, "BACKGROUND")
        row.background:SetAllPoints()
        row.background:SetColorTexture(unpack(index % 2 == 0 and JOURNAL.row or JOURNAL.panel))
        row.cells = {}
        for column = 1, columns do row.cells[column] = text(row, 12, unpack(JOURNAL.text)) end
        row.action = makeButton(row, "", 66, 18)
        row.action:SetPoint("RIGHT", -2, 0)
        row.action:Hide()
        rows[index] = row
    end
    footer = text(recordsContent, 11, unpack(JOURNAL.muted))
    footer:SetPoint("BOTTOMLEFT", 16, 16)
    footer:SetPoint("RIGHT", -145, 16)
    local completeTarget = makeButton(recordsContent, "Complete target", 124, 22)
    completeTarget:SetPoint("BOTTOMRIGHT", -16, 11)
    completeTarget:SetScript("OnClick", function() LL:CompleteSelectedBounties() end)

    local topThree = CreateFrame("Frame", nil, recordsContent)
    topThree:SetSize(474, 76)
    topThree:SetPoint("TOP", recordsContent, "TOP", 0, -8)
    local topThreeTitle = text(topThree, 10, unpack(JOURNAL.title))
    topThreeTitle:SetPoint("TOP", 0, -1)
    local allTimeToggle = makeButton(topThree, "All time", 68, 18)
    allTimeToggle:SetPoint("TOPRIGHT", -74, -1)
    local weeklyToggle = makeButton(topThree, "Weekly", 62, 18)
    weeklyToggle:SetPoint("TOPRIGHT", 0, -1)
    leaderboardScope = leaderboardScope or "all"
    allTimeToggle:SetScript("OnClick", function() leaderboardScope, offset = "all", 0; refreshBoard() end)
    weeklyToggle:SetScript("OnClick", function() leaderboardScope, offset = "weekly", 0; refreshBoard() end)
    local topCards = {}
    for rank = 1, 3 do
        local card = makePanel(topThree, JOURNAL.row)
        card:SetSize(150, 54)
        if rank == 1 then card:SetPoint("TOP", topThree, "TOP", 0, -20)
        elseif rank == 2 then card:SetPoint("TOPRIGHT", topCards[1], "TOPLEFT", -12, 0)
        else card:SetPoint("TOPLEFT", topCards[1], "TOPRIGHT", 12, 0) end
        card.crown = card:CreateTexture(nil, "OVERLAY")
        card.crown:SetTexture("Interface\\GroupFrame\\UI-Group-LeaderIcon")
        card.crown:SetSize(18, 18)
        card.crown:SetPoint("TOP", 0, -2)
        card.rank = text(card, 10, unpack(JOURNAL.title))
        card.rank:SetPoint("LEFT", card.crown, "RIGHT", 2, -1)
        card.icon = card:CreateTexture(nil, "ARTWORK")
        card.icon:SetSize(22, 22)
        card.icon:SetPoint("TOPLEFT", 7, -5)
        card.name = text(card, 11, unpack(JOURNAL.text))
        card.name:SetPoint("TOPLEFT", 5, -30)
        card.name:SetPoint("TOPRIGHT", -5, -30)
        card.name:SetJustifyH("CENTER")
        card.value = text(card, 10, unpack(JOURNAL.muted))
        card.value:SetPoint("TOPLEFT", 5, -42)
        card.value:SetPoint("TOPRIGHT", -5, -42)
        card.value:SetJustifyH("CENTER")
        topCards[rank] = card
    end
    topThree:Hide()

    local function setTableHeaderY(value)
        if headerY == value then return end
        headerY = value
        line:ClearAllPoints()
        line:SetPoint("TOPLEFT", 16, headerY - 16)
        line:SetPoint("TOPRIGHT", -16, headerY - 16)
        for index = 1, ROWS do
            rows[index]:ClearAllPoints()
            rows[index]:SetPoint("TOPLEFT", 16, headerY - 20 - (index - 1) * rowHeight)
        end
    end

    local function setRowHeight(value)
        if rowHeight == value then return end
        rowHeight = value
        for index = 1, ROWS do
            rows[index]:SetHeight(rowHeight)
            rows[index]:ClearAllPoints()
            rows[index]:SetPoint("TOPLEFT", 16, headerY - 20 - (index - 1) * rowHeight)
        end
    end

    local podiumColors = { { 1.00, 0.82, 0.24 }, { 0.78, 0.80, 0.84 }, { 0.76, 0.45, 0.20 } }
    local function showTopThree(key, label, members)
        topThreeTitle:SetText("TOP 3 — " .. label:upper())
        allTimeToggle:SetEnabled(leaderboardScope ~= "all")
        weeklyToggle:SetEnabled(leaderboardScope ~= "weekly")
        for rank, card in ipairs(topCards) do
            local member = members[rank]
            card:SetShown(member ~= nil)
            if member then
                local coordinates = CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[member.class]
                card.rank:SetText("#" .. rank)
                card.crown:SetVertexColor(unpack(podiumColors[rank]))
                card.name:SetText(coloredName(LL:ShortName(member.name), member.class))
                card.value:SetText(numberText(member[key]) .. " " .. label:lower())
                if coordinates then
                    card.icon:SetTexture("Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes")
                    card.icon:SetTexCoord(unpack(coordinates))
                else
                    card.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
                    card.icon:SetTexCoord(0, 1, 0, 1)
                end
            end
        end
        topThree:Show()
        setTableHeaderY(-110)
    end

    local function layout(definitions)
        local rowWidth = math.max(CONTENT_W, recordsContent:GetWidth() - 32)
        local scale = rowWidth / CONTENT_W
        for column = 1, columns do
            local definition = definitions[column]
            local wrapText = tabs[currentTab] == "Professions" and (column == 3 or column == 4)
            columnHeaders[column]:SetShown(definition ~= nil)
            if definition then
                columnHeaders[column]:ClearAllPoints()
                columnHeaders[column]:SetPoint("TOPLEFT", 16 + math.floor(definition[2] * scale + 0.5), headerY)
                columnHeaders[column]:SetText(definition[1])
            end
            for rowIndex = 1, ROWS do
                local cell = rows[rowIndex].cells[column]
                cell:SetShown(definition ~= nil)
                cell:SetWordWrap(wrapText)
                if definition then
                    cell:ClearAllPoints()
                    if wrapText then
                        cell:SetPoint("TOPLEFT", math.floor(definition[2] * scale + 0.5), -4)
                    else
                        cell:SetPoint("LEFT", math.floor(definition[2] * scale + 0.5), 0)
                    end
                    cell:SetWidth(math.floor(definition[3] * scale + 0.5))
                end
                rows[rowIndex]:SetWidth(rowWidth)
            end
        end
    end

    local function buildRows()
        local data, tab = {}, tabs[currentTab]
        if tab == "Kills" or tab == "Deaths" then
            setRowHeight(ROW_H)
            local allTimeKey = tab == "Kills" and "kills" or "deaths"
            local key = leaderboardScope == "weekly" and (tab == "Kills" and "weeklyKills" or "weeklyDeaths") or allTimeKey
            local label = (leaderboardScope == "weekly" and "Weekly " or "All time ") .. allTimeKey
            local scoreHeader = leaderboardScope == "weekly" and "Week" or (tab == "Kills" and "Kills" or "Deaths")
            local members = LL:Members()
            table.sort(members, function(left, right) if left[key] ~= right[key] then return left[key] > right[key] end return left.name < right.name end)
            showTopThree(key, label, members)
            if tab == "Kills" then
                layout({ { "#", 0, 26 }, { "Name", 32, 156 }, { "Level", 194, 40 }, { scoreHeader, 240, 150 }, { "Streak", 396, 94 } })
                for index, member in ipairs(members) do data[index] = { cells = { index, coloredName(member.name, member.class), member.level > 0 and member.level or "", numberText(member[key]), numberText(member.killStreak) } } end
                footer:SetText(leaderboardScope == "weekly" and "Counts honorable kills since the server's weekly reset." or "Counts lifetime honorable kills. Streak resets after an observed PvP death.")
            else
                layout({ { "#", 0, 26 }, { "Name", 32, 128 }, { "Level", 166, 40 }, { scoreHeader, 212, 65 }, { "Alive", 283, 105 }, { "Longest life", 394, 110 } })
                for index, member in ipairs(members) do
                    local aliveFor = member.aliveSince and math.max(0, time() - member.aliveSince) or nil
                    local currentLife = member.lifeTracked and (aliveFor and duration(aliveFor) or "Dead") or "-"
                    local longestLife = member.lifeTracked and duration(member.longestLife) or "-"
                    data[index] = { cells = { index, coloredName(member.name, member.class), member.level > 0 and member.level or "", numberText(member[key]), currentLife, longestLife } }
                end
                footer:SetText(leaderboardScope == "weekly" and "Tracks deaths since the server's weekly reset." or "Tracks every death. Life duration is shown when the member has reported this version.")
            end
        elseif tab == "Bounties" then
            setRowHeight(ROW_H)
            topThree:Hide()
            setTableHeaderY(-55)
            layout({ { "Wanted", 0, 104 }, { "Posted by", 110, 98 }, { "Why", 214, 205 }, { "Status", 425, 70 } })
            for index, bounty in ipairs(LL:Bounties()) do
                local status = bounty.active and ("|cffff5555Open|r " .. ago(bounty.createdAt)) or (bounty.canceled and "|cff888888Removed|r" or "|cff55ff55" .. (bounty.completedBy or "?") .. "|r")
                local action = bounty.active and { id = bounty.id, remove = LL:LegacyNamesMatch(bounty.postedBy, LL:PlayerName()) } or nil
                data[index] = { cells = { bounty.active and ("|cffff5555" .. bounty.target .. "|r") or ("|cff888888" .. bounty.target .. "|r"), bounty.postedBy, bounty.note or "", status }, action = action }
            end
            footer:SetText("Bounties can be claimed automatically after a verified honorable kill, or completed manually.")
        else
            setRowHeight(50)
            topThree:Hide()
            setTableHeaderY(-55)
            local members = LL:Members()
            table.sort(members, function(left, right) return left.name < right.name end)
            layout({ { "Name", 0, 120 }, { "Level", 126, 40 }, { "Professions", 172, 190 }, { "Secondary", 368, 122 } })
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
        for index, button in ipairs(tabButtons) do styleNavigationButton(button, index == currentTab) end
        local isCasino = tabs[currentTab] == "Casino"
        recordsContent:SetShown(not isCasino)
        if LL.casinoFrame then LL.casinoFrame:SetShown(isCasino) end
        local guildName = LL:GetGuildName()
        subtitle:SetText(isCasino and "Guild casino" or (guildName and (guildName .. " guild journal") or "|cffff5555Join a guild to use this board.|r"))
        if isCasino then
            LL:RefreshCasinoUI()
            return
        end
        entry:SetShown(tabs[currentTab] == "Bounties")
        completeTarget:SetShown(tabs[currentTab] == "Bounties")
        local data = buildRows()
        local visibleRows = math.max(1, math.min(ROWS, math.floor((recordsContent:GetHeight() + headerY - 54) / rowHeight)))
        local maxOffset = math.max(0, #data - visibleRows)
        if offset > maxOffset then offset = maxOffset end
        for index = 1, ROWS do
            local row, item = rows[index], data[index + offset]
            row:SetShown(index <= visibleRows and item ~= nil)
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
            rows[1]:Show(); rows[1].action:Hide()
            for column = 1, columns do rows[1].cells[column]:SetText("") end
            rows[1].cells[1]:SetWidth(math.max(CONTENT_W, recordsContent:GetWidth() - 32) - 40)
            rows[1].cells[1]:SetText(tabs[currentTab] == "Bounties" and "|cff888888No bounties yet. Post one above.|r" or "|cff888888Nothing to show yet.|r")
        end
    end
    layoutBoard()
    board:SetScript("OnShow", function()
        constrainBoard()
        layoutBoard()
        refreshBoard()
    end)
    board:SetScript("OnMouseWheel", function(_, delta) offset = math.max(0, offset - delta * 3); refreshBoard() end)
    board:SetScript("OnSizeChanged", function()
        constrainBoard()
        layoutBoard()
        refreshBoard()
    end)
end

function LL:ResetBoardSize()
    self:BuildUI()
    board:ClearAllPoints()
    board:SetSize(W, H)
    board:SetPoint("CENTER")
    constrainBoard()
    layoutBoard()
    self:RefreshUI()
end

function LL:SetBoardPage(page)
    local tabs = { leaderboard = 1, kills = 1, deaths = 2, bounty = 3, bounties = 3, professions = 4, profs = 4, casino = 5 }
    currentTab, offset = tabs[strlower(page or "")] or 1, 0
    if currentTab == 5 then self:BuildCasinoUI() end
    self.selectedBoardPage = page
    self:RefreshUI()
end

function LL:RefreshUI()
    if refreshBoard then refreshBoard() end
    if self.RefreshCasinoUI then self:RefreshCasinoUI() end
end

function LL:ToggleUI(tab)
    if not self:IsLagomMember() then self:Print("Join a guild to use Lagom Ledger."); return end
    self:BuildUI()
    if tab then self:SetBoardPage(tab) end
    if board:IsShown() and not tab then board:Hide() else board:Show(); self:RefreshUI() end
end

function LagomLedger_OnAddonCompartmentClick() LL:ToggleUI() end

function LL:UpdateMinimapButton(force)
    if not self.minimapButton or not self.db then return end
    if not force and self:IsEllesmereMinimapActive() then return end
    local angle = math.rad(self.db.minimap.angle or 225)
    self.minimapButton:ClearAllPoints()
    self.minimapButton:SetPoint("CENTER", Minimap, "CENTER", math.cos(angle) * 82, math.sin(angle) * 82)
end

function LL:BuildMinimapButton()
    if self.minimapButton or not self.db then return end
    local button = CreateFrame("Button", "LagomLedgerMinimapButton", Minimap, "BackdropTemplate")
    button:SetSize(32, 32); button:SetFrameStrata("MEDIUM"); button:SetFrameLevel(8); button:SetMovable(true); button:RegisterForDrag("LeftButton")
    button:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 2 })
    button:SetBackdropColor(unpack(JOURNAL.frame)); button:SetBackdropBorderColor(unpack(JOURNAL.title))
    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetTexture("Interface\\Icons\\Achievement_PVP_H_01"); icon:SetPoint("TOPLEFT", 3, -3); icon:SetPoint("BOTTOMRIGHT", -3, 3)
    button:SetScript("OnDragStart", function(self)
        if not LL:IsEllesmereMinimapActive() then self:StartMoving() end
    end)
    button:SetScript("OnDragStop", function(self)
        if LL:IsEllesmereMinimapActive() then return end
        self:StopMovingOrSizing()
        local minimapX, minimapY = Minimap:GetCenter()
        local buttonX, buttonY = self:GetCenter()
        if minimapX and minimapY and buttonX and buttonY then LL.db.minimap.angle = math.deg(math.atan2(buttonY - minimapY, buttonX - minimapX)); LL:UpdateMinimapButton() end
    end)
    button:SetScript("OnClick", function(_, mouseButton) if mouseButton == "RightButton" then LL:ToggleCasino() else LL:ToggleUI() end end)
    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT"); GameTooltip:AddLine("Lagom Ledger")
        GameTooltip:AddLine("Left-click: open guild board", 0.70, 0.82, 0.95); GameTooltip:AddLine("Right-click: open casino tab", 0.70, 0.82, 0.95)
        if LL:IsEllesmereMinimapActive() then
            GameTooltip:AddLine("Shift-drag: move in EllesmereUI", 0.55, 0.65, 0.75)
        else
            GameTooltip:AddLine("Drag: move minimap button", 0.55, 0.65, 0.75)
        end
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function() GameTooltip:Hide() end)
    self.minimapButton = button
    self:UpdateMinimapButton(true)
end

function LL:BuildCasinoUI()
    if self.casinoFrame or not self.content then return end
    local frame = CreateFrame("Frame", nil, self.content)
    frame:SetAllPoints()
    frame:Hide()
    self.casinoFrame = frame

    local gamePanel = makePanel(frame)
    gamePanel:SetPoint("TOPLEFT", 0, 0); gamePanel:SetPoint("TOPRIGHT", 0, 0); gamePanel:SetHeight(188)
    local gameTitle = text(gamePanel, 12, unpack(JOURNAL.title))
    gameTitle:SetPoint("TOPLEFT", 16, -13); gameTitle:SetText("GUILD GAME — CLASSIC, DEATH ROLL OR ELIMINATION")
    local balance = text(gamePanel, 11, unpack(JOURNAL.muted))
    balance:SetPoint("TOPRIGHT", -16, -13); balance:SetJustifyH("RIGHT"); self.casinoBalance = balance
    local wager = CreateFrame("EditBox", nil, gamePanel, "InputBoxTemplate")
    wager:SetPoint("TOPLEFT", 18, -48); wager:SetSize(116, 24); wager:SetAutoFocus(false); wager:SetNumeric(true); wager:SetTextInsets(6, 6, 0, 0)
    self.casinoWager = wager
    local wagerLabel = text(gamePanel, 10, unpack(JOURNAL.muted))
    wagerLabel:SetPoint("BOTTOMLEFT", wager, "TOPLEFT", 0, 3); wagerLabel:SetText("Wager (gold)")
    local mode = makeButton(gamePanel, "", 136, 24)
    mode:SetPoint("LEFT", wager, "RIGHT", 10, 0)
    self.casinoModeIndex = self.casinoModeIndex or 1
    local function updateMode()
        local selected = LL.CASINO_GAME_MODES[LL.casinoModeIndex]
        mode:SetText("Mode: " .. selected.label); LL.casinoModeDescription:SetText(selected.description)
    end
    mode:SetScript("OnClick", function() LL.casinoModeIndex = LL.casinoModeIndex % #LL.CASINO_GAME_MODES + 1; updateMode() end)
    local host = makeButton(gamePanel, "Open lobby", 96, 24)
    host:SetPoint("LEFT", mode, "RIGHT", 8, 0); host:SetScript("OnClick", function() LL:OpenCasinoGame(LL.CASINO_GAME_MODES[LL.casinoModeIndex].key, wager:GetNumber()) end)
    local join = makeButton(gamePanel, "Join", 64, 24)
    join:SetPoint("TOPLEFT", 18, -78); join:SetScript("OnClick", function() LL:JoinCasinoGame() end); self.casinoGameJoin = join
    local begin = makeButton(gamePanel, "Start", 64, 24)
    begin:SetPoint("LEFT", join, "RIGHT", 8, 0); begin:SetScript("OnClick", function() LL:StartCasinoGame() end); self.casinoGameStart = begin
    local roll = makeButton(gamePanel, "Roll", 64, 24)
    roll:SetPoint("LEFT", begin, "RIGHT", 8, 0); roll:SetScript("OnClick", function() LL:RollCasinoGame() end); self.casinoGameRoll = roll
    local cancel = makeButton(gamePanel, "Close", 64, 24)
    cancel:SetPoint("LEFT", roll, "RIGHT", 8, 0); cancel:SetScript("OnClick", function() LL:CloseCasinoGame() end); self.casinoGameClose = cancel
    local prepareDebt = makeButton(gamePanel, "Prepare mail", 92, 24)
    prepareDebt:SetPoint("LEFT", cancel, "RIGHT", 8, 0); prepareDebt:SetScript("OnClick", function() LL:PrepareCasinoDebtMail() end); self.casinoDebtPrepare = prepareDebt
    local markDebtPaid = makeButton(gamePanel, "Mark paid", 82, 24)
    markDebtPaid:SetPoint("LEFT", prepareDebt, "RIGHT", 8, 0); markDebtPaid:SetScript("OnClick", function() LL:MarkPreparedCasinoDebtPaid() end); self.casinoDebtMarkPaid = markDebtPaid
    local description = text(gamePanel, 11, unpack(JOURNAL.text))
    description:SetPoint("TOPLEFT", 18, -111); description:SetPoint("TOPRIGHT", -18, -111); description:SetJustifyH("LEFT"); description:SetWordWrap(true)
    self.casinoModeDescription = description
    updateMode()
    local state = text(gamePanel, 11, unpack(JOURNAL.muted))
    state:SetPoint("TOPLEFT", 18, -138); state:SetPoint("TOPRIGHT", -18, -138); state:SetJustifyH("LEFT"); self.casinoGroupState = state
    local debtState = text(gamePanel, 11, unpack(JOURNAL.muted))
    debtState:SetPoint("TOPLEFT", 18, -163); debtState:SetPoint("TOPRIGHT", -18, -163); debtState:SetJustifyH("LEFT"); self.casinoDebtState = debtState

    local historyPanel = makePanel(frame)
    historyPanel:SetPoint("BOTTOMLEFT", 0, 0); historyPanel:SetPoint("BOTTOMRIGHT", 0, 0); historyPanel:SetHeight(140)
    local historyTitle = text(historyPanel, 12, unpack(JOURNAL.title))
    historyTitle:SetPoint("TOPLEFT", 14, -12); historyTitle:SetText("LAST 5 GAMES")
    local history = CreateFrame("ScrollingMessageFrame", nil, historyPanel)
    history:SetPoint("TOPLEFT", 16, -37); history:SetPoint("BOTTOMRIGHT", -16, 14); history:SetFontObject(GameFontHighlightSmall); history:SetJustifyH("LEFT"); history:SetFading(false); self.casinoHistoryText = history
    local results = CreateFrame("Frame", nil, frame)
    results:SetPoint("TOPLEFT", 0, -200)
    results:SetPoint("TOPRIGHT", 0, -200)
    results:SetPoint("BOTTOMLEFT", historyPanel, "TOPLEFT", 0, 12)
    results:SetPoint("BOTTOMRIGHT", historyPanel, "TOPRIGHT", 0, 12)
    local winnersPanel = makePanel(results)
    winnersPanel:SetPoint("TOPLEFT", 0, 0); winnersPanel:SetPoint("BOTTOMRIGHT", results, "BOTTOM", -6, 0)
    local winnersTitle = text(winnersPanel, 12, unpack(JOURNAL.title))
    winnersTitle:SetPoint("TOPLEFT", 14, -12); winnersTitle:SetText("TOP 10 — MOST GOLD WON")
    local winners = CreateFrame("ScrollingMessageFrame", nil, winnersPanel)
    winners:SetPoint("TOPLEFT", 16, -37); winners:SetPoint("BOTTOMRIGHT", -16, 14); winners:SetFontObject(GameFontHighlightSmall); winners:SetJustifyH("LEFT"); winners:SetFading(false); self.casinoWinners = winners
    local losersPanel = makePanel(results)
    losersPanel:SetPoint("TOPLEFT", results, "TOP", 6, 0); losersPanel:SetPoint("BOTTOMRIGHT", 0, 0)
    local losersTitle = text(losersPanel, 12, unpack(JOURNAL.title))
    losersTitle:SetPoint("TOPLEFT", 14, -12); losersTitle:SetText("TOP 10 — MOST GOLD LOST")
    local losers = CreateFrame("ScrollingMessageFrame", nil, losersPanel)
    losers:SetPoint("TOPLEFT", 16, -37); losers:SetPoint("BOTTOMRIGHT", -16, 14); losers:SetFontObject(GameFontHighlightSmall); losers:SetJustifyH("LEFT"); losers:SetFading(false); self.casinoLosers = losers
end

function LL:RefreshCasinoUI()
    if not self.casinoFrame then return end
    local ownStats = self.db.casinoStats[self:PlayerName()] or { wonGold = 0, lostGold = 0 }
    local net = (ownStats.wonGold or 0) - (ownStats.lostGold or 0)
    local netColor = net >= 0 and "|cff55dd55" or "|cffff5555"
    self.casinoBalance:SetText("YOUR BALANCE  Won: " .. (ownStats.wonGold or 0) .. "  Lost: " .. (ownStats.lostGold or 0) .. "  Net: " .. netColor .. (net > 0 and "+" or "") .. net .. "|r")
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
                count = count + 1; target:AddMessage(string.format("%2d. %-28s %d gold", count, entry.name, entry.stats[field]))
                if count == 10 then break end
            end
        end
        if count == 0 then target:AddMessage("No completed casino games yet.") end
    end
    fill(self.casinoWinners, "wonGold"); fill(self.casinoLosers, "lostGold")
    self.casinoHistoryText:Clear()
    if #self.db.casinoHistory == 0 then
        self.casinoHistoryText:AddMessage("No completed casino games yet.")
    else
        for _, result in ipairs(self.db.casinoHistory) do self.casinoHistoryText:AddMessage(result.summary and (result.mode .. ": " .. result.summary) or string.format("%s beat %s — %d gold", result.winner, result.loser, result.wager)) end
    end
    local game = self:GetGroupCasinoGame()
    self.casinoGameJoin:SetEnabled(game and game.status == "lobby" and not game.playerSet[self:PlayerName()])
    self.casinoGameStart:SetEnabled(game and game.status == "lobby" and self:IsGroupCasinoHost(game))
    self.casinoGameRoll:SetEnabled(game and game.status == "running" and self:FindGroupPlayer(game, self:PlayerName()) ~= nil)
    self.casinoGameClose:SetEnabled(game and self:IsGroupCasinoHost(game))
    local debt, debtCount = self:GetNextCasinoDebt()
    self.casinoDebtPrepare:SetEnabled(debt ~= nil)
    self.casinoDebtMarkPaid:SetEnabled(self.preparedCasinoDebtKey ~= nil)
    if debt then
        self.casinoDebtState:SetText("Outstanding debt: " .. debt.amount .. " gold to " .. debt.winner .. (debtCount > 1 and " (" .. debtCount .. " total)" or ""))
    else
        self.casinoDebtState:SetText("No outstanding casino debts.")
    end
    if game then
        local mode = self:GetCasinoGameMode(game.mode)
        self.casinoGroupState:SetText((mode and mode.label or game.mode) .. " — " .. #game.players .. " player(s). " .. (game.message or (game.status == "lobby" and "Lobby is open." or "Game in progress.")))
    else
        self.casinoGroupState:SetText("No guild game is open.")
    end
end

function LL:ToggleCasino()
    if not self:IsLagomMember() then self:Print("Join a guild to use Lagom Ledger."); return end
    self:BuildUI()
    self:BuildCasinoUI()
    self:SetBoardPage("casino")
    board:Show()
    self:RefreshUI()
end
