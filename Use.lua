local lib = loadstring(game:HttpGet("https://raw.githubusercontent.com/emirontop3/Saphier/refs/heads/main/Source.lua"))()

local Window = lib:CreateWindow({
    Name = "My Hub",
    SaveConfig = false
})

local Tab = Window:CreateTab("Main", "rbxassetid://3944703587")
local Section = Tab:CreateSection("Settings")

-- ✅ Correct
local toggle = Section:CreateToggle({
    Name = "Enabled",
    Default = false,
    Callback = function(v)
        print("Toggle:", v)
    end
})

-- ❌ This would cause the error:
-- Section:CreateToggle("Enabled")   -- string, not a table
