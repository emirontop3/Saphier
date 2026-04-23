local lib = loadstring(game:HttpGet("https://raw.githubusercontent.com/emirontop3/Saphier/refs/heads/main/Main/Src/RealSrc/Okthislast/REALSRC/Src.lua"))()

local Window = lib:CreateWindow({
    Name = "Example Hub",
    ConfigFolder = "ExampleHub",
    SaveConfig = true
})

local Tab = Window:CreateTab("Main", "rbxassetid://3944703587")
local Section = Tab:CreateSection("Features")

Section:CreateToggle({
    Name = "Auto Attack",
    Default = false,
    Flag = "autoAttack",
    Save = true,
    Callback = function(v) print("Auto Attack:", v) end
})

Section:CreateSlider({
    Name = "Speed",
    Min = 10, Max = 50, Default = 25,
    Flag = "speedSlider",
    Save = true,
    Callback = function(v) game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = v end
})

Section:CreateButton({
    Name = "Teleport",
    Callback = function()
        game.Players.LocalPlayer.Character:MoveTo(Vector3.new(0,0,0))
    end
})

lib:Notify({Title = "Ready", Content = "Script loaded!"})
lib:Init()
