--[[
    Aurora UI Library – Usage Example
    This script demonstrates all core features of Aurora UI Library.
    Copy the library code from the previous message, or load it via loadstring.
--]]

-- 1. Load the library
local AuroraLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/emirontop3/Saphier/refs/heads/main/Src"))()

--[[
	Aurora UI Library – Full Demo Script
	This script assumes the AuroraLib module is already loaded into the environment.
	If not, load it first (e.g., via loadstring(game:HttpGet(...))())
--]]

-- 1. Create the main window
local Window = AuroraLib:CreateWindow({
	Name = "Aurora Demo Hub",
	ConfigFolder = "AuroraDemo",
	SaveConfig = true,               -- enables flag saving
	IntroEnabled = true,             -- opening animation
	IntroText = "Aurora UI",
	IntroIcon = "rbxassetid://8834748103",
	Icon = "rbxassetid://4483362458", -- optional, only works if ShowIcon is true (default false)
	Theme = "Default",
	HidePremium = false
})

-- 2. Create tabs
local MainTab = Window:CreateTab("Main", "rbxassetid://3944703587")
local SettingsTab = Window:CreateTab("Settings", "rbxassetid://4483362458")

-- 3. Create sections inside the first tab
local CombatSection = MainTab:CreateSection("Combat")
local MiscSection = MainTab:CreateSection("Misc")

-- 4. Add elements to CombatSection

-- Button
CombatSection:CreateButton({
	Name = "Kill Nearest Enemy",
	Callback = function()
		print("Button pressed – kill logic goes here")
		AuroraLib:Notify({
			Title = "Action",
			Content = "Kill command executed.",
			Duration = 3
		})
	end
})

-- Toggle with flag and saving
local autoAttackToggle = CombatSection:CreateToggle({
	Name = "Auto Attack",
	Default = false,
	Callback = function(value)
		print("Auto Attack:", value)
	end,
	Flag = "autoAttackFlag",
	Save = true
})

-- Slider with suffix
CombatSection:CreateSlider({
	Name = "Attack Range",
	Min = 5,
	Max = 50,
	Increment = 1,
	Default = 10,
	Suffix = "studs",
	Callback = function(value)
		print("Attack Range set to:", value)
	end,
	Flag = "attackRangeSlider",
	Save = true
})

-- Dropdown with options
local weaponDropdown = CombatSection:CreateDropdown({
	Name = "Weapon",
	Options = {"Sword", "Gun", "Fist", "Magic Wand"},
	Default = "Sword",
	Callback = function(selected)
		print("Weapon selected:", selected)
	end,
	Flag = "weaponDropdown",
	Save = true
})

-- Refresh dropdown later (e.g., when new weapons are added)
-- weaponDropdown:Refresh({"Bow", "Spear", "Axe"})

-- Keybind (hold to activate)
CombatSection:CreateKeybind({
	Name = "Fly Key",
	Default = "F",
	Hold = true,  -- hold to activate, release to deactivate
	Callback = function(state)
		if state then
			print("Fly ON")
		else
			print("Fly OFF")
		end
	end,
	Flag = "flyKeybind",
	Save = true
})

-- Textbox
CombatSection:CreateTextbox({
	Name = "Custom Message",
	Default = "",
	Placeholder = "Type a message...",
	TextDisappear = false,
	Callback = function(text)
		print("Textbox input:", text)
	end
})

-- 5. Elements in MiscSection

-- Label
MiscSection:CreateLabel("This is a simple label")

-- Label with custom background color (warning style)
MiscSection:CreateLabel("Warning Label", Color3.fromRGB(255, 159, 49))

-- Paragraph (title + multiline content)
MiscSection:CreateParagraph("Instructions", "Welcome to Aurora UI! Use the tabs and elements to control your script. Mobile users can tap the close button or use the minimize button.")

-- Divider (horizontal line)
MiscSection:CreateDivider()

-- Colorpicker (note: not implemented in this version, but can be added)
-- MiscSection:CreateColorPicker({...})

-- 6. Settings tab
local ThemeSection = SettingsTab:CreateSection("Appearance")

-- Changing theme (requires exposing a SetTheme method – see note below)
ThemeSection:CreateButton({
	Name = "Set Light Theme (if supported)",
	Callback = function()
		-- Uncomment if you add Window:SetTheme to the library
		-- Window:SetTheme("Light")
		AuroraLib:Notify({
			Title = "Theme",
			Content = "Theme switching not yet implemented in this example. Add SetTheme method to Window to enable.",
			Duration = 5
		})
	end
})

ThemeSection:CreateButton({
	Name = "Reset to Default",
	Callback = function()
		-- Window:SetTheme("Default")
		print("Reset theme placeholder")
	end
})

-- 7. Notifications examples
AuroraLib:Notify({
	Title = "Welcome",
	Content = "Aurora UI loaded successfully!",
	Duration = 5,
	Icon = "rbxassetid://4384403532"
})

-- 8. Initialize config saving (load saved flags)
-- This would be called in the library's Init method if implemented. Here we manually trigger loading.
if AuroraLib.SaveCfg then
	local savedData = AuroraLib.LoadCfg and AuroraLib.LoadCfg("exampleConfig")
	if savedData then
		for flag, value in pairs(savedData) do
			if AuroraLib.Flags[flag] then
				AuroraLib.Flags[flag]:Set(value)
			end
		end
	end
end

-- 9. Additional note about mobile
if UserInputService.TouchEnabled then
	AuroraLib:Notify({
		Title = "Mobile Detected",
		Content = "Touch controls are fully supported. Use the minimize or close buttons to hide the UI.",
		Duration = 7
	})
end

print("Aurora UI Demo ready!")
-- 8. Notifications
lib:Notify({Title = "Welcome", Content = "Aurora UI loaded successfully!", Duration = 5})
lib:Notify({Title = "Info", Content = "Press RightShift to hide/show the interface.", Duration = 6})

-- 9. Initialize config loading (load saved flags)
lib:Init()   -- this calls LoadConfig automatically if SaveConfig = true

print("Aurora UI Demo is ready!")
