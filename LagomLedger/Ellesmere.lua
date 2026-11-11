local _, LL = ...

function LL:HasEllesmereUI()
    return type(EllesmereUI) == "table" and type(EllesmereUI.RegisterPlugin) == "function" and type(EllesmereUI.OpenPlugin) == "function"
end

function LL:IsEllesmereMinimapActive()
    if not C_AddOns or not C_AddOns.IsAddOnLoaded then return false end
    local _, loaded = C_AddOns.IsAddOnLoaded("EllesmereUIMinimap")
    return loaded == true
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
