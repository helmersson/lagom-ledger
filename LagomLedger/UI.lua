local _, LL = ...

local function makeButton(parent, text, width, height)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetSize(width, height)
    button:SetText(text)
    return button
end

local colors = {
    background = { 0.035, 0.045, 0.065, 0.98 },
    surface = { 0.065, 0.080, 0.110, 0.98 },
    hover = { 0.095, 0.115, 0.150, 0.98 },
    border = { 0.155, 0.195, 0.260, 1 },
    accent = { 0.180, 0.690, 0.950, 1 },
    text = { 0.880, 0.920, 0.970, 1 },
    muted = { 0.510, 0.610, 0.710, 1 },
}

local function makeSurface(parent)
    local surface = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    surface:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
    surface:SetBackdropColor(unpack(colors.surface))
    surface:SetBackdropBorderColor(unpack(colors.border))
    return surface
end

local function makeActionButton(parent, text, width, callback)
    local button = makeSurface(parent)
    button:SetSize(width, 28)
    local label = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    label:SetPoint("CENTER")
    label:SetText(text)
    label:SetTextColor(unpack(colors.text))
    button:SetScript("OnClick", callback)
    button:SetScript("OnEnter", function(self)
        self:SetBackdropColor(unpack(colors.hover))
        self:SetBackdropBorderColor(unpack(colors.accent))
    end)
    button:SetScript("OnLeave", function(self)
        self:SetBackdropColor(unpack(colors.surface))
        self:SetBackdropBorderColor(unpack(colors.border))
    end)
    return button
end

local function makeNavigationButton(parent, text)
    local button = makeSurface(parent)
    button:SetSize(140, 34)
    button.label = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    button.label:SetPoint("LEFT", 12, 0)
    button.label:SetText(text)
    function button:SetActive(active)
        self.active = active
        self:SetBackdropColor(unpack(active and colors.hover or colors.surface))
        self:SetBackdropBorderColor(unpack(active and colors.accent or colors.border))
        self.label:SetTextColor(unpack(active and colors.text or colors.muted))
    end
    button:SetScript("OnEnter", function(self)
        if not self.active then
            self:SetBackdropColor(unpack(colors.hover))
            self.label:SetTextColor(unpack(colors.text))
        end
    end)
    button:SetScript("OnLeave", function(self)
        if not self.active then
            self:SetBackdropColor(unpack(colors.surface))
            self.label:SetTextColor(unpack(colors.muted))
        end
    end)
    return button
end

local function makeInput(parent, width)
    local input = CreateFrame("EditBox", nil, parent, "BackdropTemplate")
    input:SetSize(width, 28)
    input:SetAutoFocus(false)
    input:SetFontObject(GameFontHighlightSmall)
    input:SetTextColor(unpack(colors.text))
    input:SetTextInsets(9, 9, 0, 0)
    input:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
    input:SetBackdropColor(0.025, 0.035, 0.050, 1)
    input:SetBackdropBorderColor(unpack(colors.border))
    input:SetScript("OnEditFocusGained", function(self) self:SetBackdropBorderColor(unpack(colors.accent)) end)
    input:SetScript("OnEditFocusLost", function(self) self:SetBackdropBorderColor(unpack(colors.border)) end)
    return input
end

local function makePageHeading(parent, title, subtitle)
    local heading = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    heading:SetPoint("TOPLEFT", 18, -18)
    heading:SetText(title)
    heading:SetTextColor(unpack(colors.text))
    local subheading = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    subheading:SetPoint("TOPLEFT", heading, "BOTTOMLEFT", 0, -5)
    subheading:SetText(subtitle)
    subheading:SetTextColor(unpack(colors.muted))
end

local function makeList(parent)
    local card = makeSurface(parent)
    local list = CreateFrame("ScrollingMessageFrame", nil, card)
    list:SetPoint("TOPLEFT", 14, -14)
    list:SetPoint("BOTTOMRIGHT", -14, 14)
    list:SetFontObject(GameFontHighlightSmall)
    list:SetJustifyH("LEFT")
    list:SetFading(false)
    return card, list
end

function LL:BuildUI()
    if self.frame then return end
    local frame = CreateFrame("Frame", "LagomLedgerFrame", UIParent, "BackdropTemplate")
    frame:SetSize(805, 560)
    frame:SetPoint("CENTER")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:SetFrameStrata("DIALOG")
    frame:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
    frame:SetBackdropColor(unpack(colors.background))
    frame:SetBackdropBorderColor(unpack(colors.border))
    frame:Hide()
    self.frame = frame

    local header = makeSurface(frame)
    header:SetPoint("TOPLEFT", 10, -10)
    header:SetPoint("TOPRIGHT", -10, -10)
    header:SetHeight(60)
    header:SetBackdropColor(0.050, 0.065, 0.090, 1)
    local accent = header:CreateTexture(nil, "ARTWORK")
    accent:SetTexture("Interface\\Buttons\\WHITE8x8")
    accent:SetVertexColor(unpack(colors.accent))
    accent:SetPoint("TOPLEFT", 16, -16)
    accent:SetSize(4, 28)

    local title = header:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    title:SetPoint("TOPLEFT", 32, -14)
    title:SetText("Lagom Ledger")
    title:SetTextColor(unpack(colors.text))
    local subtitle = header:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -4)
    subtitle:SetText("OG Lagom • guild-only shared data")
    subtitle:SetTextColor(unpack(colors.muted))

    local close = makeActionButton(header, "Close", 60, function() frame:Hide() end)
    close:SetPoint("RIGHT", header, "RIGHT", -12, 0)
    local settings = makeActionButton(header, "EUI", 50, function() LL:OpenEllesmereSettings() end)
    settings:SetPoint("RIGHT", close, "LEFT", -6, 0)
    local casino = makeActionButton(header, "Casino", 70, function() LL:ToggleCasino() end)
    casino:SetPoint("RIGHT", settings, "LEFT", -6, 0)
    local sync = makeActionButton(header, "Sync", 60, function() LL:RefreshLocalProfile() end)
    sync:SetPoint("RIGHT", casino, "LEFT", -6, 0)

    local sidebar = makeSurface(frame)
    sidebar:SetPoint("TOPLEFT", 10, -80)
    sidebar:SetPoint("BOTTOMLEFT", 10, 10)
    sidebar:SetWidth(156)
    local navigation = sidebar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    navigation:SetPoint("TOPLEFT", 10, -14)
    navigation:SetText("NAVIGATION")
    navigation:SetTextColor(unpack(colors.muted))
    local guildLabel = sidebar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    guildLabel:SetPoint("BOTTOMLEFT", 10, 14)
    guildLabel:SetText("OG LAGOM")
    guildLabel:SetTextColor(unpack(colors.accent))

    local content = makeSurface(frame)
    content:SetPoint("TOPLEFT", 176, -80)
    content:SetPoint("BOTTOMRIGHT", -10, 10)
    content:SetBackdropColor(0.045, 0.060, 0.085, 1)

    local leaderboardPage = CreateFrame("Frame", nil, content)
    leaderboardPage:SetAllPoints()
    local professionsPage = CreateFrame("Frame", nil, content)
    professionsPage:SetAllPoints()
    local bountyPage = CreateFrame("Frame", nil, content)
    bountyPage:SetAllPoints()
    self.leaderboardPage = leaderboardPage
    self.professionsPage = professionsPage
    self.bountyPage = bountyPage

    local leaderboardTab = makeNavigationButton(sidebar, "PvP Leaderboard")
    leaderboardTab:SetPoint("TOPLEFT", 8, -42)
    local professionsTab = makeNavigationButton(sidebar, "Professions")
    professionsTab:SetPoint("TOPLEFT", leaderboardTab, "BOTTOMLEFT", 0, -6)
    local bountyTab = makeNavigationButton(sidebar, "Bounty Board")
    bountyTab:SetPoint("TOPLEFT", professionsTab, "BOTTOMLEFT", 0, -6)
    self.leaderboardTab = leaderboardTab
    self.professionsTab = professionsTab
    self.bountyTab = bountyTab

    makePageHeading(leaderboardPage, "PvP Leaderboard", "Alliance kills and deaths across the guild")
    self.leaderboardSummary = leaderboardPage:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    self.leaderboardSummary:SetPoint("TOPRIGHT", -18, -25)
    self.leaderboardSummary:SetTextColor(unpack(colors.muted))
    local leaderboardHeader = leaderboardPage:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    leaderboardHeader:SetPoint("TOPLEFT", 22, -78)
    leaderboardHeader:SetText("RANK     MEMBER                              KILLS     DEATHS")
    leaderboardHeader:SetTextColor(unpack(colors.accent))
    local leaderboardCard, leaderboardList = makeList(leaderboardPage)
    leaderboardCard:SetPoint("TOPLEFT", 16, -102)
    leaderboardCard:SetPoint("BOTTOMRIGHT", -16, 16)
    self.leaderboardText = leaderboardList

    makePageHeading(professionsPage, "Professions", "Known professions shared by guild members")
    self.professionSummary = professionsPage:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    self.professionSummary:SetPoint("TOPRIGHT", -18, -25)
    self.professionSummary:SetTextColor(unpack(colors.muted))
    local professionHeader = professionsPage:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    professionHeader:SetPoint("TOPLEFT", 22, -78)
    professionHeader:SetText("MEMBER                                      PROFESSIONS")
    professionHeader:SetTextColor(unpack(colors.accent))
    local professionsCard, professionsList = makeList(professionsPage)
    professionsCard:SetPoint("TOPLEFT", 16, -102)
    professionsCard:SetPoint("BOTTOMRIGHT", -16, 16)
    self.professionText = professionsList

    makePageHeading(bountyPage, "Bounty Board", "Post and complete Alliance bounties")
    local postPanel = makeSurface(bountyPage)
    postPanel:SetPoint("TOPLEFT", 16, -76)
    postPanel:SetPoint("TOPRIGHT", -16, -76)
    postPanel:SetHeight(108)
    local postLabel = postPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    postLabel:SetPoint("TOPLEFT", 14, -12)
    postLabel:SetText("POST A NEW BOUNTY")
    postLabel:SetTextColor(unpack(colors.accent))
    local targetLabel = postPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    targetLabel:SetPoint("TOPLEFT", 14, -37)
    targetLabel:SetText("Alliance character")
    targetLabel:SetTextColor(unpack(colors.muted))
    local target = makeInput(postPanel, 170)
    target:SetPoint("TOPLEFT", 14, -55)
    self.bountyTarget = target
    local noteLabel = postPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    noteLabel:SetPoint("TOPLEFT", targetLabel, "TOPRIGHT", 14, 0)
    noteLabel:SetText("Reason or reward (optional)")
    noteLabel:SetTextColor(unpack(colors.muted))
    local note = makeInput(postPanel, 228)
    note:SetPoint("LEFT", target, "RIGHT", 10, 0)
    self.bountyNote = note
    local post = makeActionButton(postPanel, "Post bounty", 100, function()
        if LL:AddBounty(target:GetText(), note:GetText()) then target:SetText(""); note:SetText("") end
    end)
    post:SetPoint("LEFT", note, "RIGHT", 10, 0)

    local activeLabel = bountyPage:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    activeLabel:SetPoint("TOPLEFT", 18, -198)
    activeLabel:SetText("ACTIVE BOUNTIES")
    activeLabel:SetTextColor(unpack(colors.accent))
    self.bountySummary = bountyPage:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    self.bountySummary:SetPoint("TOPRIGHT", -18, -198)
    self.bountySummary:SetTextColor(unpack(colors.muted))
    local bountyCard, bountyList = makeList(bountyPage)
    bountyCard:SetPoint("TOPLEFT", 16, -220)
    bountyCard:SetPoint("BOTTOMRIGHT", -16, 58)
    self.bountyText = bountyList

    local completeSelected = makeActionButton(bountyPage, "Complete selected target", 176, function() LL:CompleteSelectedBounties() end)
    completeSelected:SetPoint("BOTTOMLEFT", 16, 16)
    local completeId = makeInput(bountyPage, 180)
    completeId:SetPoint("LEFT", completeSelected, "RIGHT", 12, 0)
    self.completeBountyId = completeId
    local completeIdLabel = bountyPage:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    completeIdLabel:SetPoint("BOTTOMLEFT", completeId, "TOPLEFT", 0, 4)
    completeIdLabel:SetText("Bounty ID")
    completeIdLabel:SetTextColor(unpack(colors.muted))
    local completeById = makeActionButton(bountyPage, "Complete", 82, function()
        if LL:CompleteBounty(completeId:GetText()) then completeId:SetText("") end
    end)
    completeById:SetPoint("LEFT", completeId, "RIGHT", 10, 0)

    leaderboardTab:SetScript("OnClick", function() LL:SetBoardPage("leaderboard") end)
    professionsTab:SetScript("OnClick", function() LL:SetBoardPage("professions") end)
    bountyTab:SetScript("OnClick", function() LL:SetBoardPage("bounty") end)
    self:SetBoardPage(self.selectedBoardPage or "leaderboard")
end

function LL:SetBoardPage(page)
    if not self.frame then return end
    self.selectedBoardPage = page == "bounty" and "bounty" or (page == "professions" and "professions" or "leaderboard")
    if self.selectedBoardPage == "leaderboard" then self.leaderboardPage:Show() else self.leaderboardPage:Hide() end
    if self.selectedBoardPage == "professions" then self.professionsPage:Show() else self.professionsPage:Hide() end
    if self.selectedBoardPage == "bounty" then self.bountyPage:Show() else self.bountyPage:Hide() end
    self.leaderboardTab:SetActive(self.selectedBoardPage == "leaderboard")
    self.professionsTab:SetActive(self.selectedBoardPage == "professions")
    self.bountyTab:SetActive(self.selectedBoardPage == "bounty")
    self:RefreshUI()
end

function LL:RefreshUI()
    if not self.frame or not self.db then return end
    local players = {}
    for name, player in pairs(self.db.players) do table.insert(players, { name = name, data = player }) end
    table.sort(players, function(a, b) return a.data.kills > b.data.kills or (a.data.kills == b.data.kills and a.data.deaths < b.data.deaths) end)
    self.leaderboardText:Clear()
    self.leaderboardSummary:SetText(#players .. " guild members recorded")
    if #players == 0 then self.leaderboardText:AddMessage("No guild profiles have been shared yet.") end
    for index, entry in ipairs(players) do
        self.leaderboardText:AddMessage(string.format("|cff7dd3fc%-4d|r %-30s |cff93c5fd%5d|r     |cfffda4af%5d|r", index, entry.name, entry.data.kills or 0, entry.data.deaths or 0))
    end

    local professionEntries = {}
    for _, entry in ipairs(players) do table.insert(professionEntries, entry) end
    table.sort(professionEntries, function(a, b) return a.name < b.name end)
    self.professionText:Clear()
    self.professionSummary:SetText(#professionEntries .. " guild profiles")
    if #professionEntries == 0 then self.professionText:AddMessage("No guild profiles have been shared yet.") end
    for _, entry in ipairs(professionEntries) do
        local professions = entry.data.professions or {}
        local text = #professions > 0 and table.concat(professions, ", ") or "Not shared"
        self.professionText:AddMessage(string.format("|cffffffff%-38s|r |cff94a3b8%s|r", entry.name, text))
    end

    self.bountyText:Clear()
    local active = 0
    for _, bounty in ipairs(self.db.bounties) do
        if bounty.active then
            active = active + 1
            self.bountyText:AddMessage(string.format("|cff7dd3fc[%s]|r |cffffffff%s|r  |cff94a3b8posted by %s%s|r", bounty.id, bounty.target, bounty.postedBy, bounty.note ~= "" and (" • " .. bounty.note) or ""))
        end
    end
    self.bountySummary:SetText(active .. (active == 1 and " active bounty" or " active bounties"))
    if active == 0 then self.bountyText:AddMessage("No active bounties. Add the first Alliance target above.") end
    if self.RefreshCasinoUI then self:RefreshCasinoUI() end
end

function LL:ToggleUI()
    if not self:IsLagomMember() then self:Print("This addon is restricted to the OG Lagom guild."); return end
    self:BuildUI()
    if self.frame:IsShown() then self.frame:Hide() else self:RefreshUI(); self.frame:Show() end
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
    button:SetBackdropColor(unpack(colors.surface))
    button:SetBackdropBorderColor(unpack(colors.accent))
    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetTexture("Interface\\Icons\\INV_Misc_Note_01")
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
    button:SetScript("OnClick", function(_, mouseButton)
        if mouseButton == "RightButton" then LL:ToggleCasino() else LL:ToggleUI() end
    end)
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
    if not self:IsLagomMember() then self:Print("This addon is restricted to the OG Lagom guild."); return end
    self:BuildCasinoUI()
    if self.casinoFrame:IsShown() then self.casinoFrame:Hide() else self:RefreshCasinoUI(); self.casinoFrame:Show() end
end

