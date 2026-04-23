local lib = loadstring(game:HttpGet("https://raw.githubusercontent.com/emirontop3/Saphier/refs/heads/main/deepseek_lua_20260423_06e21c.lua"))()

-- Window with config saving and mobile support
local Window = lib:CreateWindow({
    Name = "Sapphire Demo",
    ConfigFolder = "SapphireDemo",
    SaveConfig = true,
    IntroEnabled = true,
    IntroText = "Sapphire UI",
    IntroIcon = "rbxassetid://8834748103",
    ShowIcon = false,
    Icon = "rbxassetid://4483362458",
    HidePremium = false
})

-- Tabs
local MainTab = Window:CreateTab("Main", "rbxassetid://3944703587")
local SettingsTab = Window:CreateTab("Settings", "rbxassetid://4483362458")

-- Sections
local CombatSection = MainTab:CreateSection("Combat")
local MiscSection = MainTab:CreateSection("Miscellaneous")

-- === COMBAT SECTION ===

CombatSection:CreateButton({
    Name = "Kill Nearest Enemy",
    Callback = function()
        print("Button clicked!")
    end
})

CombatSection:CreateToggle({
    Name = "Auto Attack",
    Default = false,
    Flag = "autoAttack",
    Save = true,
    Color = Color3.fromRGB(9,99,195),
    Callback = function(v) print("Auto Attack:", v) end
})

CombatSection:CreateSlider({
    Name = "Attack Range",
    Min = 5, Max = 50, Default = 10,
    Suffix = "studs",
    Flag = "attackRange",
    Save = true,
    Callback = function(v) print("Range:", v) end
})

local weaponDropdown = CombatSection:CreateDropdown({
    Name = "Weapon",
    Options = {"Sword", "Gun", "Fist"},
    Default = "Sword",
    Flag = "weapon",
    Save = true,
    Callback = function(opt) print("Weapon:", opt) end
})

-- Refresh dropdown later if needed
-- weaponDropdown:Refresh({"Bow", "Spear", "Axe"})

CombatSection:CreateColorPicker({
    Name = "ESP Color",
    Default = Color3.fromRGB(255,0,0),
    Flag = "espColor",
    Save = true,
    Callback = function(c) print("Color:", c) end
})

CombatSection:CreateKeybind({
    Name = "Fly Key",
    Default = Enum.KeyCode.F,
    Hold = true,
    Flag = "flyKey",
    Save = true,
    Callback = function(state) if state then print("Fly ON") else print("Fly OFF") end end
})

CombatSection:CreateTextbox({
    Name = "Custom Message",
    Default = "",
    Placeholder = "Type here...",
    TextDisappear = false,
    Callback = function(t) print("Textbox:", t) end
})

-- === MISCELLANEOUS SECTION ===

MiscSection:CreateLabel("This is a label")
MiscSection:CreateLabel("Warning", "rbxassetid://4483362458", Color3.fromRGB(255,159,49))
MiscSection:CreateParagraph("Instructions", "Use the elements to control your script. Mobile users can tap the 'Show UI' button after hiding.")
MiscSection:CreateDivider()

-- === SETTINGS TAB ===

local ThemeSection = SettingsTab:CreateSection("Themes")
ThemeSection:CreateButton({Name = "Default Theme", Callback = function() Window:SetTheme("Default") end})
ThemeSection:CreateButton({Name = "Light Theme", Callback = function() Window:SetTheme("Light") end})
ThemeSection:CreateButton({Name = "Ocean Theme", Callback = function() Window:SetTheme("Ocean") end})
ThemeSection:CreateButton({Name = "Midnight Theme", Callback = function() Window:SetTheme("Midnight") end})

-- Notifications
lib:Notify({Title = "Welcome", Content = "Sapphire UI loaded!", Duration = 5})
lib:Notify({Title = "Mobile", Content = IS_MOBILE and "Touch controls active." or "Desktop mode.", Duration = 4})

-- Initialize config loading
lib:Init()
