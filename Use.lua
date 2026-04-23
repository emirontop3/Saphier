--[[
    Sapphire UI Library – Full Demo Script
    This script shows how to use all library features.
    Replace the library loadstring with your own (or paste the library code here).
--]]

-- 1. Load the library
local lib = loadstring(game:HttpGet("https://raw.githubusercontent.com/emirontop3/Saphier/refs/heads/main/deepseek_lua_20260423_06e21c.lua"))()

-- 2. Create the main window
local Window = lib:CreateWindow({
    Name = "Sapphire Demo Hub",
    ConfigFolder = "SapphireDemo",
    SaveConfig = true,               -- enables flag saving
    IntroEnabled = true,             -- opening animation
    IntroText = "Sapphire UI",
    IntroIcon = "rbxassetid://8834748103",
    ShowIcon = false,                -- set to true to show an icon in the title bar
    Icon = "rbxassetid://4483362458",
    HidePremium = false
})

-- 3. Create tabs
local MainTab = Window:CreateTab("Main", "rbxassetid://3944703587")
local SettingsTab = Window:CreateTab("Settings", "rbxassetid://4483362458")

-- 4. Create sections inside the first tab
local CombatSection = MainTab:CreateSection("Combat")
local MiscSection = MainTab:CreateSection("Misc")

-- 5. Add elements to CombatSection

-- Button
CombatSection:CreateButton({
    Name = "Kill Nearest Enemy",
    Callback = function()
        print("Button pressed!")
        -- your kill logic here
    end
})

-- Toggle
local autoAttackToggle = CombatSection:CreateToggle({
    Name = "Auto Attack",
    Default = false,
    Color = Color3.fromRGB(9, 99, 195),  -- optional custom color
    Flag = "autoAttackFlag",
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
    Color = Color3.fromRGB(9, 149, 98),
    Flag = "attackRangeSlider",
    Save = true,
    Callback = function(value)
        print("Attack Range set to:", value)
    end
})

-- Dropdown
local weaponDropdown = CombatSection:CreateDropdown({
    Name = "Weapon",
    Options = {"Sword", "Gun", "Fist", "Magic Wand"},
    Default = "Sword",
    Flag = "weaponDropdown",
    Save = true,
    Callback = function(selected)
        print("Weapon selected:", selected)
    end
})

-- Refresh dropdown options later (if needed)
-- weaponDropdown:Refresh({"Bow", "Spear", "Axe"})

-- Color Picker
CombatSection:CreateColorPicker({
    Name = "ESP Color",
    Default = Color3.fromRGB(255, 0, 0),
    Flag = "espColor",
    Save = true,
    Callback = function(color)
        print("New ESP Color:", color)
    end
})

-- Keybind
CombatSection:CreateKeybind({
    Name = "Fly Key",
    Default = Enum.KeyCode.F,
    Hold = true,  -- true = hold to activate, false = press to toggle
    Flag = "flyKeybind",
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
    Name = "Custom Message",
    Default = "",
    Placeholder = "Type here...",
    TextDisappear = false,
    Callback = function(text)
        print("Textbox input:", text)
    end
})

-- 6. Elements in MiscSection

-- Label (simple)
MiscSection:CreateLabel("This is a simple label")

-- Label with icon + custom background color
MiscSection:CreateLabel("Warning Label", "rbxassetid://4483362458", Color3.fromRGB(255, 159, 49))

-- Paragraph (title + multiline content)
MiscSection:CreateParagraph("Instructions", "Welcome to Sapphire UI! Use the tabs and elements to control your script. Mobile users can hide the UI and tap the 'Show UI' button to bring it back.")

-- Divider (horizontal line)
MiscSection:CreateDivider()

-- 7. Settings tab
local ThemeSection = SettingsTab:CreateSection("Appearance")
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
    Name = "Set Default Theme",
    Callback = function()
        Window:SetTheme("Default")
    end
})

-- 8. Notifications examples
lib:Notify({Title = "Welcome", Content = "Sapphire UI loaded successfully!", Duration = 5, Image = "rbxassetid://4384403532"})

-- 9. Initialize config saving (load saved flags)
lib:Init()   -- this automatically calls LoadConfig if SaveConfig = true

-- 10. Additional note about mobile
if UserInputService.TouchEnabled then
    lib:Notify({Title = "Mobile Detected", Content = "Touch controls are fully supported. Hide the UI and tap 'Show UI' to reopen.", Duration = 7})
end

print("Sapphire UI Demo ready!")
