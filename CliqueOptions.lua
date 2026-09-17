-- Clique Options Panel for 1.12.1
-- Simple binding editor

Clique = Clique or {}
local CC = Clique
local L = CC.L or {}

local optionsFrame = nil

function CC:ToggleOptions()
    if not optionsFrame then
        self:CreateOptionsPanel()
    end
    
    if optionsFrame:IsShown() then
        optionsFrame:Hide()
    else
        optionsFrame:Show()
    end
end

function CC:CreateOptionsPanel()
    local f = CreateFrame("Frame", "CliqueOptionsFrame", UIParent)
    f:SetWidth(400)
    f:SetHeight(500)
    f:SetPoint("CENTER")
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
    f:Hide()
    
    -- Title
    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -10)
    title:SetText(L["OPTIONS_TITLE"] or "Clique Configuration")
    
    -- Close button
    local closeBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    closeBtn:SetWidth(80)
    closeBtn:SetHeight(24)
    closeBtn:SetPoint("BOTTOM", 0, 10)
    closeBtn:SetText(L["OK"] or "OK")
    closeBtn:SetScript("OnClick", function()
        f:Hide()
    end)
    
    optionsFrame = f
end
