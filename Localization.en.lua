-- Clique Localization
-- Minimal strings for the 1.12.1 port

Clique = Clique or {}
local CC = Clique

CC.L = {
    -- General
    ["ADDON_NAME"] = "Clique",
    ["LOADED"] = "loaded. Use /clique for options.",
    ["BINDING_NOT_DEFINED"] = "Binding not defined",
    ["CUSTOM_SCRIPT"] = "Custom Script",
    ["DEFAULT_FRIENDLY"] = "Default Friendly",
    ["DEFAULT_HOSTILE"] = "Default Hostile",
    
    -- Errors
    ["ERROR_SCRIPT"] = "There was an error compiling your script: %s",
    ["NO_UNIT_FRAME"] = "Could not determine unit for frame \"%s\"",
    ["BINDING_EXISTS"] = "That combination is already bound. Delete the old one first.",
    ["PASSIVE_SKILL"] = "You can't bind a passive skill.",
    ["AUTO_SELF_CAST"] = "Clique will not work properly with AutoSelfCast enabled. Please disable it.",
    
    -- UI
    ["OK"] = "OK",
    ["CANCEL"] = "Cancel",
    ["SAVE"] = "Save",
    ["DELETE"] = "Delete",
    ["EDIT"] = "Edit",
    ["NEW"] = "New",
    ["MAX"] = "Max",
    ["HELP"] = "Help",
    ["NAME"] = "Name:",
    ["CLICK_SET"] = "Click Set:",
    ["BINDING"] = "Binding",
    ["ACTION"] = "Action",
    
    -- Options
    ["OPTIONS_TITLE"] = "Clique Configuration",
    ["OPTIONS_TAB_BINDINGS"] = "Bindings",
    ["OPTIONS_TAB_SETTINGS"] = "Settings",
    ["SETTINGS_DOWNCLICK"] = "Trigger bindings on mouse down (requires reload)",
    ["SETTINGS_FASTOOC"] = "Disable OOC clicks when party members enter combat",
    
    -- Tutorial
    ["TUTORIAL_MAIN"] = "Using Clique is simple. Find a spell in your spellbook and click it while holding any modifier keys (Alt, Ctrl, Shift) and any mouse button. This will add a binding to the list.",
    ["TUTORIAL_SELECTED"] = "You have selected a binding. You can edit it, delete it, or set it to always cast the max rank.",
    ["TUTORIAL_EDIT"] = "You are editing a binding. You can re-bind it by clicking the button above, or edit the custom Lua code.",
}
