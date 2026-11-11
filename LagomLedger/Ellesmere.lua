local _, LL = ...

function LL:HasEllesmereUI()
    return type(EllesmereUI) == "table" and type(EllesmereUI.RegisterPlugin) == "function" and type(EllesmereUI.OpenPlugin) == "function"
end

function LL:IsEllesmereMinimapActive()
    if not C_AddOns or not C_AddOns.IsAddOnLoaded then return false end
    local _, loaded = C_AddOns.IsAddOnLoaded("EllesmereUIMinimap")
    return loaded == true
end

function LL:IsAtrocityMinimapActive()
    if not C_AddOns or not C_AddOns.IsAddOnLoaded then return false end
    local _, loaded = C_AddOns.IsAddOnLoaded("atrocityEssentials")
    if not loaded or not atrocityEssentials or not atrocityEssentials.GetModule then return false end
    local minimap = atrocityEssentials:GetModule("Minimap", true)
    return minimap and minimap.active == true
end

function LL:UseAtrocityMinimapButton()
    if not self.db or not self:IsAtrocityMinimapActive() or not LibStub then return false end
    local dbIcon = LibStub("LibDBIcon-1.0", true)
    if not dbIcon then return false end
    self.db.minimap.atrocity = self.db.minimap.atrocity or { hide = false }
    if self.atrocityMinimapDB == self.db.minimap.atrocity and dbIcon:IsRegistered("LagomLedger") then return true end
    self.atrocityMinimapData = self.atrocityMinimapData or {
        type = "launcher",
        icon = "Interface\\Icons\\Achievement_PVP_H_01",
        OnClick = function(_, mouseButton)
            if mouseButton == "RightButton" then LL:ToggleCasino() else LL:ToggleUI() end
        end,
        OnTooltipShow = function(tooltip)
            tooltip:AddLine("Lagom Ledger")
            tooltip:AddLine("Left-click: open guild board", 0.70, 0.82, 0.95)
            tooltip:AddLine("Right-click: open casino tab", 0.70, 0.82, 0.95)
        end,
    }
    if not dbIcon:IsRegistered("LagomLedger") then
        local ok = pcall(dbIcon.Register, dbIcon, "LagomLedger", self.atrocityMinimapData, self.db.minimap.atrocity)
        if not ok then return false end
    else
        dbIcon:Refresh("LagomLedger", self.db.minimap.atrocity)
    end
    self.atrocityMinimapDB = self.db.minimap.atrocity
    return true
end

local function AddText(parent, text, y)
    local line = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    line:SetPoint("TOPLEFT", 24, y)
    line:SetPoint("TOPRIGHT", -24, y)
    line:SetJustifyH("LEFT")
    line:SetJustifyV("TOP")
    line:SetText(text)
    return line, 32
end

local function AddButton(parent, text, y, callback)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetSize(170, 24)
    button:SetPoint("TOPLEFT", 24, y)
    button:SetText(text)
    button:SetScript("OnClick", callback)
    return button, 32
end

function LL:RegisterEllesmerePlugin()
    if self.euiRegistered or not self:HasEllesmereUI() then return false end
    local EUI = EllesmereUI
    local registered = EUI.RegisterPlugin("LagomLedger", {
        label = "Lagom Ledger",
        modules = {
            {
                key = "Board",
                title = "Guild Board",
                description = "Open the Lagom Ledger guild PvP leaderboard and bounty board.",
                pages = { "Overview" },
                buildPage = function(_, parent, y)
                    if EUI.IsSearchPrebuild and EUI.IsSearchPrebuild() then return math.abs(y) + 96 end
                    local _, height = EUI.Widgets:SectionHeader(parent, "LAGOM LEDGER", y)
                    y = y - height
                    _, height = AddText(parent, "Guild-only PvP scores, professions and Alliance bounties. The board only shares data with members of your current guild who have this addon installed.", y)
                    y = y - height
                    _, height = AddButton(parent, "Open guild board", y, function() LL:ToggleUI() end)
                    return math.abs(y) + height
                end,
            },
            {
                key = "Casino",
                title = "Casino",
                description = "Open the guild /roll casino and view the gold leaderboards.",
                pages = { "Overview" },
                buildPage = function(_, parent, y)
                    if EUI.IsSearchPrebuild and EUI.IsSearchPrebuild() then return math.abs(y) + 96 end
                    local _, height = EUI.Widgets:SectionHeader(parent, "GUILD CASINO", y)
                    y = y - height
                    _, height = AddText(parent, "Host or join Classic, Death Roll and Elimination games. Lagom Ledger records results only; players must trade gold manually.", y)
                    y = y - height
                    _, height = AddButton(parent, "Open casino", y, function() LL:ToggleCasino() end)
                    return math.abs(y) + height
                end,
            },
        },
    })
    self.euiRegistered = registered == true
    return self.euiRegistered
end

function LL:OpenEllesmereSettings()
    if self:HasEllesmereUI() then
        self:RegisterEllesmerePlugin()
        if EllesmereUI.OpenPlugin("LagomLedger", "Board") then return end
    end
    self:ToggleUI()
end
