local lib = loadstring(game:HttpGet("https://raw.githubusercontent.com/emirontop3/Saphier/refs/heads/main/Source.lua"))()


local Window = lib:CreateWindow({
    Name = "Test",
    SaveConfig = false
})

local Tab = Window:CreateTab("Main", "rbxassetid://3944703587")
local Section = Tab:CreateSection("Settings")

local toggle = Section:CreateToggle({
    Name = "Enabled",
    Default = true,
    Callback = function(v) print("Toggle:", v) end
})
