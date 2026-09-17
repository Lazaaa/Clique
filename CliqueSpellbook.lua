-- Clique Spellbook Integration
-- Adds a tab to the spellbook, allows binding spells by clicking them
-- Emberveil (1.12.1) compatible

Clique = Clique or {}
local CC = Clique
local L = CC.L or {}

-- =====================================================
--  STATE
-- =====================================================

CC.spellbookTab = nil
CC.spellOverlays = {}
CC.currentClickSet = "default"

local TAB_ICON = "Interface\\Icons\\INV_Misc_QuestionMark"

-- =====================================================
--  SPELLBOOK TAB
--  A small tab attached to the spellbook that toggles the
--  Clique configuration frame.
-- =====================================================

function CC:CreateSpellbookTab()
    if CC.spellbookTab then return end
    if not SpellBookFrame then return end

    local tab = CreateFrame("CheckButton", "CliqueSpellbookTab", SpellBookFrame, "SpellBookSkillLineTabTemplate")
    tab:SetNormalTexture(TAB_ICON)
    tab:SetScript("OnClick", function()
        CC:ToggleOptions()
    end)
    tab:SetScript("OnShow", function()
        -- Position below the last spellbook tab
        local num = GetNumSpellTabs()
        local lastTab = _G["SpellBookSkillLineTab" .. num]
        tab:ClearAllPoints()
        if lastTab then
            tab:SetPoint("TOPLEFT", lastTab, "BOTTOMLEFT", 0, -4)
        else
            tab:SetPoint("TOPLEFT", SpellBookFrame, "TOPLEFT", 5, -30)
        end
    end)
    tab:SetScript("OnEnter", function()
        GameTooltip:SetOwner(tab, "ANCHOR_RIGHT")
        GameTooltip:SetText("Clique", 1, 1, 1)
        GameTooltip:AddLine("Click to open/close the Clique configuration.", 1, 1, 1, 1)
        GameTooltip:Show()
    end)
    tab:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    CC.spellbookTab = tab
end

-- =====================================================
--  SPELLBOOK OVERLAY BUTTONS
--  These are transparent frames on top of each SpellButton.
--  They capture clicks when the Clique config is open.
-- =====================================================

function CC:CreateSpellOverlays()
    if not SpellBookFrame then return end
    if CC.spellOverlays[1] then return end

    -- Determine the parent frame of SpellButton1
    local parent = SpellButton1 and SpellButton1:GetParent() or SpellBookFrame

    for i = 1, 12 do
        local spellButton = _G["SpellButton" .. i]
        if spellButton then
            local overlay = CreateFrame("Button", "CliqueSpellOverlay" .. i, parent)
            overlay:SetID(i)
            overlay:SetAllPoints(spellButton)
            overlay:SetFrameLevel(spellButton:GetFrameLevel() + 5)
            overlay:RegisterForClicks("LeftButtonUp", "RightButtonUp", "MiddleButtonUp")
            overlay:Hide()

            overlay:SetScript("OnClick", function()
                CC:OnSpellbookClick(this, arg1)
            end)

            overlay:SetScript("OnEnter", function()
                -- Reposition tooltip using the underlying spell button
                local sb = _G["SpellButton" .. this:GetID()]
                if sb and SpellButton_OnEnter then
                    SpellButton_OnEnter(sb)
                end
            end)

            overlay:SetScript("OnLeave", function()
                GameTooltip:Hide()
            end)

            CC.spellOverlays[i] = overlay
        end
    end
end

function CC:UpdateOverlays()
    local showOverlays = CC.optionsFrame and CC.optionsFrame:IsShown()
    for _, overlay in ipairs(CC.spellOverlays) do
        if showOverlays then
            overlay:Show()
        else
            overlay:Hide()
        end
    end
end

-- =====================================================
--  SPELLBOOK CLICK HANDLER
--  Called when the user clicks a spell in the spellbook
--  while the Clique config is open.
-- =====================================================

function CC:OnSpellbookClick(overlay, mouseButton)
    if not CC.optionsFrame or not CC.optionsFrame:IsShown() then
        return
    end

    local buttonId = overlay:GetID()
    local tab = SpellBookFrame.selectedTab or 1
    local _, _, offset, numSpells = GetSpellTabInfo(tab)
    local spellIndex = offset + buttonId

    local name, rank = GetSpellName(spellIndex, BOOKTYPE_SPELL)
    local texture = GetSpellTexture(spellIndex, BOOKTYPE_SPELL)

    if not name then return end

    -- Don't bind passive skills
    if rank and string.find(rank, "Passive") then
        DEFAULT_CHAT_FRAME:AddMessage("|cffff0000Clique:|r " .. (L["PASSIVE_SKILL"] or "Can't bind passive skills."))
        return
    end

    local modifiers = CC:GetModifiers()
    local clickSet = CC.currentClickSet or "default"

    -- Check for conflict
    local key = CC:GetBindingKey(mouseButton, modifiers)
    if CC.bindings[clickSet] and CC.bindings[clickSet][key] then
        local existing = CC.bindings[clickSet][key]
        if existing.type == "spell" and existing.spell == name then
            -- Same binding, ignore
            return
        end
        DEFAULT_CHAT_FRAME:AddMessage("|cffff0000Clique:|r " .. (L["BINDING_EXISTS"] or "That combination is already bound. Delete the old one first."))
        return
    end

    -- Add the binding
    CC:AddBinding(clickSet, mouseButton, modifiers, {
        type = "spell",
        spell = name,
        rank = rank,
        texture = texture,
        button = mouseButton,
        modifiers = modifiers,
    })

    DEFAULT_CHAT_FRAME:AddMessage(string.format("|cff00ff00Clique:|r Bound %s%s to '%s'",
        CC:GetBindingText({ button = mouseButton, modifiers = modifiers }),
        " " .. (CC:GetModifierText(modifiers)),
        name))

    CC:UpdateBindingList()
end

-- =====================================================
--  MODIFIER TEXT HELPER
-- =====================================================

function CC:GetModifierText(modifiers)
    local alt = (mod(modifiers, 2) >= 1) and "Alt+" or ""
    local ctrl = (math.floor(mod(modifiers, 4) / 2) >= 1) and "Ctrl+" or ""
    local shift = (math.floor(modifiers / 4) >= 1) and "Shift+" or ""
    return alt .. ctrl .. shift
end

-- =====================================================
--  HOOKS FOR SPELLBOOK SHOW/HIDE
-- =====================================================

local hookFrame = CreateFrame("Frame")
hookFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
hookFrame:RegisterEvent("SPELLS_CHANGED")

hookFrame:SetScript("OnEvent", function()
    if event == "PLAYER_ENTERING_WORLD" then
        CC:CreateSpellbookTab()
        CC:CreateSpellOverlays()
    elseif event == "SPELLS_CHANGED" then
        -- Reposition tab in case new tabs were learned
        if CC.spellbookTab and CC.spellbookTab:IsShown() then
            local num = GetNumSpellTabs()
            local lastTab = _G["SpellBookSkillLineTab" .. num]
            if lastTab then
                CC.spellbookTab:ClearAllPoints()
                CC.spellbookTab:SetPoint("TOPLEFT", lastTab, "BOTTOMLEFT", 0, -4)
            end
        end
    end
end)

-- Hook the SpellBookFrame to update overlays when it's shown
if SpellBookFrame then
    local origShow = SpellBookFrame:GetScript("OnShow")
    SpellBookFrame:SetScript("OnShow", function()
        if origShow then origShow() end
        CC:UpdateOverlays()
        -- Reposition the tab
        if CC.spellbookTab then
            local num = GetNumSpellTabs()
            local lastTab = _G["SpellBookSkillLineTab" .. num]
            CC.spellbookTab:ClearAllPoints()
            if lastTab then
                CC.spellbookTab:SetPoint("TOPLEFT", lastTab, "BOTTOMLEFT", 0, -4)
            else
                CC.spellbookTab:SetPoint("TOPLEFT", SpellBookFrame, "TOPLEFT", 5, -30)
            end
        end
    end)
end
