--[[
    Aurora UI Library – Usage Example
    This script demonstrates all core features of Aurora UI Library.
    Copy the library code from the previous message, or load it via loadstring.
--]]

-- 1. Load the library
local lib = loadstring(game:HttpGet("YOUR_RAW_URL_HERE"))()

-- 2. Create the main window
local Window = lib:CreateWindow({
    Name = "Aurora Hub",
    ConfigFolder = "AuroraHub",
    SaveConfig = true,               -- enable flag saving
    IntroEnabled = true,             -- show intro animation
    IntroText = "Aurora UI",
    KeySystem = false                -- set to true if using key system
})

-- 3. Create tabs
local MainTab = Window:CreateTab("Main", "home")          -- name, icon (Material icon name)
local SettingsTab = Window:CreateTab("Settings", "settings")

-- 4. Create sections
local CombatSection = MainTab:CreateSection("Combat")
local MiscSection = MainTab:CreateSection("Miscellaneous")

-- 5. Add elements to CombatSection

-- Button
CombatSection:CreateButton({
    Name = "Kill Nearest Enemy",
    Callback = function()
        print("Button pressed!") -- your logic here
    end
})

-- Toggle with flag saving
local autoAttack = CombatSection:CreateToggle({
    Name = "Auto Attack",
    Default = false,
    Flag = "autoAttack",       -- unique flag name for saving
    Save = true,
    Callback = function(value)
        print("Auto Attack:", value)
    end
})

-- Slider
CombatSection:CreateSlider({
    Name = "Attack Range",
    Min = 5,
    Max = 50,
    Increment = 1,
    Default = 10,
    Suffix = "studs",
    Flag = "attackRange",
    Save = true,
    Callback = function(value)
        print("Range:", value)
    end
})

-- Dropdown (multi-option)
local weaponChoice = CombatSection:CreateDropdown({
    Name = "Weapon",
    Options = {"Sword", "Gun", "Fist"},
    Default = "Sword",
    MultipleOptions = false,      -- true for multiple selection
    Flag = "weapon",
    Save = true,
    Callback = function(option)
        print("Selected:", option)
    end
})
-- Refresh dropdown options later (if needed)
-- weaponChoice:Refresh({"Bow", "Spear", "Axe"})

-- Color Picker
CombatSection:CreateColorPicker({
    Name = "ESP Color",
    Default = Color3.fromRGB(255, 0, 0),
    Flag = "espColor",
    Save = true,
    Callback = function(color)
        print("Color:", color)
    end
})

-- Keybind
CombatSection:CreateKeybind({
    Name = "Fly Key",
    Default = Enum.KeyCode.F,
    Hold = true,                  -- true: hold to activate; false: toggle
    Flag = "flyKey",
    Save = true,
    Callback = function(state)
        if state then
            print("Fly ON")
        else
            print("Fly OFF")
        end
    end
})

-- Textbox
CombatSection:CreateTextbox({
    Name = "Message Sender",
    Default = "",
    Placeholder = "Type here...",
    Callback = function(text)
        print("Typed:", text)
    end
})

-- 6. Elements in Miscellaneous Section

-- Labels
MiscSection:CreateLabel("Section below shows a warning:")
MiscSection:CreateLabel("⚠️ Warning: Use at your own risk")

-- Paragraph
MiscSection:CreateParagraph("Instructions", "Use the elements to control the script. You can hide the UI and press RightShift to show it again.")

-- Divider
MiscSection:CreateDivider()

-- 7. Settings tab with theme switching
local ThemeSection = SettingsTab:CreateSection("Themes")
ThemeSection:CreateButton({
    Name = "Set Default Theme",
    Callback = function()
        Window:SetTheme("Default")
    end
})
ThemeSection:CreateButton({
    Name = "Set Light Theme",
    Callback = function()
        Window:SetTheme("Light")
    end
})
ThemeSection:CreateButton({
    Name = "Set Ocean Theme",
    Callback = function()
        Window:SetTheme("Ocean")
    end
})
ThemeSection:CreateButton({
    Name = "Set Midnight Theme",
    Callback = function()
        Window:SetTheme("Midnight")
    end
})

-- 8. Notifications
lib:Notify({Title = "Welcome", Content = "Aurora UI loaded successfully!", Duration = 5})
lib:Notify({Title = "Info", Content = "Press RightShift to hide/show the interface.", Duration = 6})

-- 9. Initialize config loading (load saved flags)
lib:Init()   -- this calls LoadConfig automatically if SaveConfig = true

print("Aurora UI Demo is ready!")
