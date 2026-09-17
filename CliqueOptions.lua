-- Clique Options Panel for 1.12.1
-- Shows bindings, allows deletion and click-set switching

Clique = Clique or {}
local CC = Clique
local L = CC.L or {}

local optionsFrame = nil
local bindingRows = {}
local ROWS = 12

local CLICK_SETS = { "default", "friendly", "hostile", "ooc", "global" }

-- =====================================================
--  TOGGLE
-- =====================================================

function CC:ToggleOptions()
    if not optionsFrame then
        self:CreateOptionsPanel()
    end

    if optionsFrame:IsShown() then
        optionsFrame:Hide()
        CC:UpdateOverlays()
    else
        optionsFrame:Show()
        CC:UpdateOverlays()
        CC:UpdateBindingList()
    end
end

-- =====================================================
--  CREATE OPTIONS PANEL
-- =====================================================

function CC:CreateOptionsPanel()
    if optionsFrame then return end

    local f = CreateFrame("Frame", "CliqueOptionsFrame", UIParent)
    f:SetWidth(420)
    f:SetHeight(520)
    f:SetPoint("CENTER", UIParent, "CENTER", 250, 0)
    f:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", function() this:StartMoving() end)
    f:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)
    f:SetFrameStrata("DIALOG")
    f:Hide()

    -- Title
    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -12)
    title:SetText(L["OPTIONS_TITLE"] or "Clique Configuration")

    -- Click set label + dropdown
    local setLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    setLabel:SetPoint("TOPLEFT", f, "TOPLEFT", 20, -45)
    setLabel:SetText(L["CLICK_SET"] or "Click Set:")

    local setButton = CreateFrame("Button", "CliqueSetDropdown", f, "UIPanelButtonTemplate")
    setButton:SetWidth(140)
    setButton:SetHeight(22)
    setButton:SetPoint("LEFT", setLabel, "RIGHT", 6, 0)
    setButton:SetText(CC.currentClickSet or "default")
    setButton:SetScript("OnClick", function()
        local idx = 1
        for i, s in ipairs(CLICK_SETS) do
            if s == CC.currentClickSet then idx = i break end
        end
        idx = idx + 1
        if idx > #CLICK_SETS then idx = 1 end
        CC.currentClickSet = CLICK_SETS[idx]
        setButton:SetText(CC.currentClickSet)
        CC:UpdateBindingList()
    end)

    -- Column headers
    local colIcon = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    colIcon:SetPoint("TOPLEFT", f, "TOPLEFT", 22, -80)
    colIcon:SetText("")

    local colAction = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    colAction:SetPoint("TOPLEFT", f, "TOPLEFT", 60, -80)
    colAction:SetText(L["ACTION"] or "Action")

    local colBind = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    colBind:SetPoint("TOPRIGHT", f, "TOPRIGHT", -90, -80)
    colBind:SetText(L["BINDING"] or "Binding")

    -- Binding rows (simple list, no scrolling)
    for i = 1, ROWS do
        local row = CreateFrame("Button", "CliqueBindingRow" .. i, f)
        row:SetWidth(380)
        row:SetHeight(28)
        if i == 1 then
            row:SetPoint("TOPLEFT", f, "TOPLEFT", 15, -95)
        else
            row:SetPoint("TOPLEFT", bindingRows[i - 1], "BOTTOMLEFT", 0, -2)
        end

        -- Highlight
        local hl = row:CreateTexture(nil, "HIGHLIGHT")
        hl:SetAllPoints()
        hl:SetTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
        hl:SetBlendMode("ADD")

        -- Icon
        row.icon = row:CreateTexture(nil, "ARTWORK")
        row.icon:SetWidth(22)
        row.icon:SetHeight(22)
        row.icon:SetPoint("LEFT", 4, 0)
        row.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

        -- Action text
        row.action = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        row.action:SetPoint("LEFT", row.icon, "RIGHT", 6, 0)
        row.action:SetWidth(180)
        row.action:SetJustifyH("LEFT")

        -- Binding text
        row.bind = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        row.bind:SetPoint("RIGHT", row, "RIGHT", -6, 0)
        row.bind:SetWidth(130)
        row.bind:SetJustifyH("RIGHT")

        row:SetScript("OnClick", function()
            if this.binding then
                CC:DeleteBindingByKey(this.binding.originalKey, CC.currentClickSet)
                CC:UpdateBindingList()
            end
        end)

        row:SetScript("OnEnter", function()
            if this.binding then
                GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
                GameTooltip:SetText("Left-click to delete", 1, 1, 1)
                GameTooltip:Show()
            end
        end)

        row:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)

        bindingRows[i] = row
        row:Hide()
    end

    -- Info label
    local info = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    info:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 15, 40)
    info:SetWidth(390)
    info:SetJustifyH("LEFT")
    info:SetText("Open your spellbook and click a spell to bind it. Current click-set: see dropdown above.")

    -- Close button
    local closeBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    closeBtn:SetWidth(80)
    closeBtn:SetHeight(24)
    closeBtn:SetPoint("BOTTOM", 0, 10)
    closeBtn:SetText(L["OK"] or "OK")
    closeBtn:SetScript("OnClick", function()
        f:Hide()
        CC:UpdateOverlays()
    end)

    optionsFrame = f
    CC.optionsFrame = f
end

-- =====================================================
--  UPDATE BINDING LIST
-- =====================================================

function CC:UpdateBindingList()
    if not optionsFrame or not optionsFrame:IsShown() then return end

    local set = CC.currentClickSet or "default"
    local bindings = CC.bindings[set] or {}

    -- Sort the keys for consistent display
    local keys = {}
    for k in pairs(bindings) do
        table.insert(keys, k)
    end
    table.sort(keys)

    -- Clear rows
    for i = 1, ROWS do
        bindingRows[i]:Hide()
        bindingRows[i].binding = nil
    end

    -- Fill rows
    for i, key in ipairs(keys) do
        if i > ROWS then break end
        local binding = bindings[key]
        local row = bindingRows[i]

        row.icon:SetTexture(binding.texture or "Interface\\Icons\\INV_Misc_QuestionMark")
        row.action:SetText(binding.spell or binding.macrotext or binding.type or "?")
        row.bind:SetText(CC:GetBindingKeyDisplay(binding))

        binding.originalKey = key
        row.binding = binding
        row:Show()
    end
end

-- =====================================================
--  HELPERS
-- =====================================================

function CC:GetBindingKeyDisplay(binding)
    if not binding then return "" end
    local button = binding.button or "LeftButton"
    local modifiers = binding.modifiers or 0
    return CC:GetModifierText(modifiers) .. button
end

function CC:DeleteBindingByKey(key, clickSet)
    if not clickSet then clickSet = CC.currentClickSet or "default" end
    if CC.bindings[clickSet] then
        CC.bindings[clickSet][key] = nil
        CC:SaveBindings()
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00Clique:|r Binding removed.")
    end
end
