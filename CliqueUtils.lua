-- Clique Utilities
-- Helper functions for the 1.12.1 port

Clique = Clique or {}
local CC = Clique

-- Clear a table without table.setn
function CC:ClearTable(tbl)
    if not tbl then tbl = {} end
    for k in pairs(tbl) do tbl[k] = nil end
    return tbl
end

-- Convert a binding key to a human-readable string
function CC:GetBindingText(binding)
    if not binding then return "" end
    
    local alt = (band(binding.modifiers, 1) > 0) and "Alt+" or ""
    local ctrl = (band(binding.modifiers, 2) > 0) and "Ctrl+" or ""
    local shift = (band(binding.modifiers, 4) > 0) and "Shift+" or ""
    
    return string.format("%s%s%s%s", alt, ctrl, shift, binding.button or "LeftButton")
end

-- Get a binding's action text
function CC:GetBindingActionText(binding)
    if not binding then return "" end
    
    if binding.type == "spell" then
        return binding.spell or "?"
    elseif binding.type == "macro" then
        return binding.macrotext or "?"
    elseif binding.type == "target" then
        return "Target"
    elseif binding.type == "menu" then
        return "Menu"
    else
        return binding.type or "?"
    end
end

-- Check if a spell is a passive skill
function CC:IsPassiveSpell(spell)
    -- In 1.12.1, passive spells have no mana cost and no cast time
    -- This is a simplified check
    return false
end
