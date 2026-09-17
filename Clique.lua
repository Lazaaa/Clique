-- Clique 1.12.1 (Emberveil) rewrite
-- Click-casting interface for vanilla WoW
-- Based on the original Clique by Cladhaire

Clique = Clique or {}
local CC = Clique
local L = CC.L or {}

-- =====================================================
--  SAVED VARIABLES
-- =====================================================

CliqueDB = CliqueDB or {}
CliqueDB.bindings = CliqueDB.bindings or {}
CliqueDB.settings = CliqueDB.settings or {
    downclick = false,
    fastooc = false,
}

-- =====================================================
--  BIT OPERATIONS (Lua 5.1 - no bit library)
-- =====================================================

local function band(a, b)
    local result = 0
    local bitval = 1
    while a > 0 and b > 0 do
        if a % 2 == 1 and b % 2 == 1 then
            result = result + bitval
        end
        bitval = bitval * 2
        a = math.floor(a / 2)
        b = math.floor(b / 2)
    end
    return result
end

local function bor(a, b)
    local result = 0
    local bitval = 1
    while a > 0 or b > 0 do
        if a % 2 == 1 or b % 2 == 1 then
            result = result + bitval
        end
        bitval = bitval * 2
        a = math.floor(a / 2)
        b = math.floor(b / 2)
    end
    return result
end

CC.band = band
CC.bor = bor

-- =====================================================
--  UNIT FRAME REGISTRATION
-- =====================================================

-- List of frames to register for click-casting
local UNIT_FRAMES = {
    { name = "PlayerFrame", unit = "player" },
    { name = "TargetFrame", unit = "target" },
    { name = "PetFrame", unit = "pet" },
    { name = "FocusFrame", unit = "focus" },
    { name = "TargetFrameToT", unit = "targettarget" },
    { name = "FocusFrameToT", unit = "focustarget" },
    { name = "PartyMemberFrame1", unit = "party1" },
    { name = "PartyMemberFrame2", unit = "party2" },
    { name = "PartyMemberFrame3", unit = "party3" },
    { name = "PartyMemberFrame4", unit = "party4" },
    { name = "PartyMemberFrame1PetFrame", unit = "partypet1" },
    { name = "PartyMemberFrame2PetFrame", unit = "partypet2" },
    { name = "PartyMemberFrame3PetFrame", unit = "partypet3" },
    { name = "PartyMemberFrame4PetFrame", unit = "partypet4" },
}

-- Raid frames (raid1-40)
for i = 1, 40 do
    table.insert(UNIT_FRAMES, { name = "RaidGroup" .. i .. "Button", unit = "raid" .. i })
end

-- =====================================================
--  FRAME REGISTRATION
-- =====================================================

function CC:RegisterFrame(frameName, unit)
    local frame = _G[frameName]
    if not frame then return end

    -- Store the original OnClick
    if not frame.cliqueOriginalOnClick then
        frame.cliqueOriginalOnClick = frame:GetScript("OnClick")
    end

    -- Store the unit on the frame
    frame.cliqueUnit = unit

    -- Register for clicks
    frame:RegisterForClicks("LeftButtonUp", "RightButtonUp", "MiddleButtonUp")

    -- Set up the click handler
    frame:SetScript("OnClick", function()
        CC:OnClick(this, arg1)
    end)

    CC.frames[frame] = true
    CC.unitFrames[unit] = frame
end

function CC:RegisterAllFrames()
    for _, entry in ipairs(UNIT_FRAMES) do
        self:RegisterFrame(entry.name, entry.unit)
    end
end

-- =====================================================
--  BINDING MANAGEMENT
-- =====================================================

-- Get the binding key from button and modifiers
function CC:GetBindingKey(button, modifiers)
    return string.format("%s%d", button or "LeftButton", modifiers or 0)
end

-- Get the current modifier keys as a number
function CC:GetModifiers()
    local alt = IsAltKeyDown() and 1 or 0
    local ctrl = IsControlKeyDown() and 2 or 0
    local shift = IsShiftKeyDown() and 4 or 0
    return alt + ctrl + shift
end

-- Get the appropriate click set for a unit
function CC:GetClickSet(unit)
    local set = "default"
    
    -- Check hostile first
    if UnitCanAttack("player", unit) then
        if self.bindings["hostile"] and next(self.bindings["hostile"]) then
            set = "hostile"
        end
    else
        if self.bindings["friendly"] and next(self.bindings["friendly"]) then
            set = "friendly"
        end
    end
    
    -- Check OOC
    if self.bindings["ooc"] and next(self.bindings["ooc"]) and not UnitAffectingCombat("player") then
        set = "ooc"
    end
    
    return set
end

-- Get the binding for a click
function CC:GetBinding(unit, button, modifiers)
    local set = self:GetClickSet(unit)
    local key = self:GetBindingKey(button, modifiers)
    
    -- Try the specific set
    if self.bindings[set] and self.bindings[set][key] then
        return self.bindings[set][key]
    end
    
    -- Fall back to default
    if self.bindings["default"] and self.bindings["default"][key] then
        return self.bindings["default"][key]
    end
    
    return nil
end

-- =====================================================
--  CLICK HANDLER
-- =====================================================

function CC:OnClick(frame, button)
    if not button then return end

    local unit = frame.cliqueUnit
    if not unit or not UnitExists(unit) then return end

    -- If we have a cursor item, handle that first
    if CursorHasItem() then
        if button == "LeftButton" then
            if unit == "player" then
                AutoEquipCursorItem()
            else
                DropItemOnUnit(unit)
            end
        else
            PutItemInBackpack()
        end
        return
    end

    -- If we're targeting a spell, handle that
    if SpellIsTargeting() then
        if button == "LeftButton" then
            SpellTargetUnit(unit)
        elseif button == "RightButton" then
            SpellStopTargeting()
        end
        return
    end

    -- Get the binding
    local modifiers = self:GetModifiers()
    local binding = self:GetBinding(unit, button, modifiers)

    if binding then
        self:ExecuteBinding(binding, unit)
        return
    end

    -- Fall back to the original OnClick
    if frame.cliqueOriginalOnClick then
        frame.cliqueOriginalOnClick()
    else
        -- Default behavior: target the unit on left click
        if button == "LeftButton" then
            TargetUnit(unit)
        end
    end
end

-- =====================================================
--  BINDING EXECUTION
-- =====================================================

function CC:ExecuteBinding(binding, unit)
    if not binding then return end

    local btype = binding.type

    if btype == "spell" then
        self:CastSpell(binding.spell, unit)
    elseif btype == "macro" then
        self:RunMacro(binding.macrotext, unit)
    elseif btype == "target" then
        TargetUnit(unit)
    elseif btype == "menu" then
        self:ShowUnitMenu(unit)
    end
end

function CC:CastSpell(spell, unit)
    if not spell or not unit then return end
    if not UnitExists(unit) then return end

    -- Store the current target
    local hadTarget = UnitExists("target")

    -- If we're targeting a friendly unit and need to cast on a different friendly unit,
    -- clear the target first
    if UnitExists("target") and not UnitCanAttack("player", "target") and not UnitIsUnit(unit, "target") then
        ClearTarget()
    end

    -- Cast the spell
    CastSpellByName(spell)

    -- If the spell needs a target, target the unit
    if SpellIsTargeting() then
        SpellTargetUnit(unit)
    end

    -- Restore the target if we cleared it
    if hadTarget then
        TargetLastTarget()
    end
end

function CC:RunMacro(macrotext, unit)
    if not macrotext then return end
    RunMacroText(macrotext)
end

function CC:ShowUnitMenu(unit)
    if not unit then return end
    
    -- Determine the frame for this unit
    local frameName
    if unit == "player" then
        frameName = "PlayerFrame"
    elseif unit == "target" then
        frameName = "TargetFrame"
    elseif unit == "pet" then
        frameName = "PetFrame"
    elseif string.find(unit, "party") then
        local num = string.match(unit, "(%d+)$")
        frameName = "PartyMemberFrame" .. num
    elseif string.find(unit, "raid") then
        local num = string.match(unit, "(%d+)$")
        frameName = "RaidGroup" .. num .. "Button"
    end
    
    local frame = _G[frameName]
    if not frame then return end
    
    -- Get the dropdown
    local dropdownName = frameName .. "DropDown"
    local dropdown = _G[dropdownName]
    if dropdown then
        ToggleDropDownMenu(1, nil, dropdown, "cursor")
    end
end

-- =====================================================
--  BINDING MANAGEMENT FUNCTIONS
-- =====================================================

function CC:AddBinding(clickSet, button, modifiers, binding)
    if not self.bindings[clickSet] then
        self.bindings[clickSet] = {}
    end
    
    local key = self:GetBindingKey(button, modifiers)
    self.bindings[clickSet][key] = binding
    self:SaveBindings()
end

function CC:DeleteBinding(clickSet, button, modifiers)
    if not self.bindings[clickSet] then return end
    
    local key = self:GetBindingKey(button, modifiers)
    self.bindings[clickSet][key] = nil
    self:SaveBindings()
end

function CC:SaveBindings()
    CliqueDB.bindings = self.bindings
end

function CC:LoadBindings()
    self.bindings = CliqueDB.bindings or {}
end

-- =====================================================
--  INITIALIZATION
-- =====================================================

function CC:Initialize()
    self:LoadBindings()
    self:RegisterAllFrames()
end

-- Event handling
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")

eventFrame:SetScript("OnEvent", function()
    if event == "PLAYER_ENTERING_WORLD" then
        CC:Initialize()
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00" .. (L["ADDON_NAME"] or "Clique") .. "|r " .. (L["LOADED"] or "loaded. Use /clique for options."))
    elseif event == "PLAYER_REGEN_ENABLED" then
        CC:RegisterAllFrames()
    end
end)

-- Slash command
SLASH_CLIQUE1 = "/clique"
SlashCmdList["CLIQUE"] = function(msg)
    if msg == "debug" then
        for set, bindings in pairs(CC.bindings) do
            DEFAULT_CHAT_FRAME:AddMessage("Set: " .. set)
            for key, binding in pairs(bindings) do
                DEFAULT_CHAT_FRAME:AddMessage("  " .. key .. " -> " .. (binding.spell or binding.macrotext or binding.type))
            end
        end
    else
        if CC.ToggleOptions then
            CC:ToggleOptions()
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00Clique|r loaded. Use /clique debug for debugging.")
        end
    end
end
