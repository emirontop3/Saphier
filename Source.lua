--[[
    Sapphire UI Library v2 – Robust Version
    Handles bad input gracefully; logs warnings instead of crashing.
    Usage:
    local lib = loadstring(game:HttpGet("URL"))()
    local Window = lib:CreateWindow({...})
    local tab = Window:CreateTab("Tab", icon)
    local section = tab:CreateSection("Section")
    section:CreateToggle({Name = "Toggle", ...})
--]]

local SapphireLib = {}
SapphireLib.__index = SapphireLib

-- Services
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- Icons fallback
local Icons = {}
pcall(function()
    Icons = HttpService:JSONDecode(game:HttpGetAsync("https://raw.githubusercontent.com/evoincorp/lucideblox/master/src/modules/util/icons.json")).icons
end)

local function getIcon(name)
    if Icons[name] then return Icons[name] end
    return nil
end

local function packColor(c)
    return {R = c.R * 255, G = c.G * 255, B = c.B * 255}
end
local function unpackColor(t)
    return Color3.fromRGB(t.R, t.G, t.B)
end
local function round(num, inc)
    local r = math.floor(num/inc + math.sign(num)*0.5) * inc
    if r < 0 then r = r + inc end
    return r
end

-- Default theme
SapphireLib.Themes = {
    Default = {
        Main = Color3.fromRGB(25,25,25),
        Second = Color3.fromRGB(32,32,32),
        Stroke = Color3.fromRGB(60,60,60),
        Text = Color3.fromRGB(240,240,240),
        TextDark = Color3.fromRGB(150,150,150),
        Divider = Color3.fromRGB(60,60,60),
    }
}
SapphireLib.SelectedTheme = "Default"
SapphireLib.Flags = {}
SapphireLib.Connections = {}
SapphireLib.Folder = nil
SapphireLib.SaveCfg = false

-- ScreenGui
local Gui = Instance.new("ScreenGui"); Gui.Name = "SapphireUI"
if syn then syn.protect_gui(Gui); Gui.Parent = CoreGui else Gui.Parent = gethui() or CoreGui end
if gethui then for _,v in ipairs(gethui():GetChildren()) do if v.Name == Gui.Name and v ~= Gui then v:Destroy() end end
else for _,v in ipairs(CoreGui:GetChildren()) do if v.Name == Gui.Name and v ~= Gui then v:Destroy() end end end

local NotificationHolder = Instance.new("Frame")
NotificationHolder.Name = "NotifHolder"
NotificationHolder.Position = UDim2.new(1,-25,1,-25)
NotificationHolder.Size = UDim2.new(0,300,1,-25)
NotificationHolder.AnchorPoint = Vector2.new(1,1)
NotificationHolder.BackgroundTransparency = 1
NotificationHolder.Parent = Gui

local function addConnection(sig, fn)
    if not Gui or not Gui.Parent then return end
    local con = sig:Connect(fn)
    table.insert(SapphireLib.Connections, con)
    return con
end
Gui.Destroying:Connect(function()
    for _,c in ipairs(SapphireLib.Connections) do c:Disconnect() end
    SapphireLib.Connections = {}
end)

-- Safe callback runner
local function safeCallback(fn, ...)
    local ok, err = pcall(fn, ...)
    if not ok then warn("Sapphire Library – Callback error: " .. tostring(err)) end
end

-- Validate element config
local function checkConfig(c, elementType)
    if type(c) ~= "table" then
        warn("Sapphire Library – " .. elementType .. " expects a table config, got " .. type(c))
        return false
    end
    if not c.Name then
        c.Name = "Unnamed"
        warn("Sapphire Library – " .. elementType .. " missing Name, using 'Unnamed'")
    end
    return true
end

-- Notification
function SapphireLib:Notify(config)
    spawn(function()
        local notif = Instance.new("Frame")
        notif.Name = "Notif"
        notif.BackgroundColor3 = Color3.fromRGB(25,25,25)
        notif.BorderSizePixel = 0
        notif.Size = UDim2.new(1,0,0,0)
        notif.AutomaticSize = Enum.AutomaticSize.Y
        notif.ClipsDescendants = true
        Instance.new("UICorner",notif).CornerRadius = UDim.new(0,8)
        local stroke = Instance.new("UIStroke",notif)
        stroke.Color = Color3.fromRGB(93,93,93); stroke.Thickness = 1.2
        local icon = Instance.new("ImageLabel",notif)
        icon.Size = UDim2.new(0,20,0,20); icon.Position = UDim2.new(0,12,0,12)
        icon.BackgroundTransparency = 1; icon.ImageColor3 = Color3.fromRGB(240,240,240)
        if config.Image then icon.Image = getIcon(config.Image) or config.Image else icon.Image = "rbxassetid://4384403532" end
        local title = Instance.new("TextLabel",notif)
        title.Size = UDim2.new(1,-42,0,18); title.Position = UDim2.new(0,42,0,12); title.BackgroundTransparency = 1
        title.Font = Enum.Font.GothamBold; title.TextColor3 = Color3.fromRGB(240,240,240); title.TextSize = 15; title.TextXAlignment = Enum.TextXAlignment.Left
        title.Text = config.Title or "Notification"
        local content = Instance.new("TextLabel",notif)
        content.Size = UDim2.new(1,-24,0,0); content.Position = UDim2.new(0,12,0,36); content.BackgroundTransparency = 1
        content.Font = Enum.Font.GothamSemibold; content.TextColor3 = Color3.fromRGB(200,200,200); content.TextSize = 14
        content.TextXAlignment = Enum.TextXAlignment.Left; content.TextWrapped = true; content.AutomaticSize = Enum.AutomaticSize.Y
        content.Text = config.Content or ""
        notif.Parent = NotificationHolder
        TweenService:Create(notif,TweenInfo.new(0.5,Enum.EasingStyle.Quint),{Size = UDim2.new(1,-30,0, content.TextBounds.Y+50)}):Play()
        wait(0.1)
        TweenService:Create(notif,TweenInfo.new(0.5,Enum.EasingStyle.Quint),{BackgroundColor3 = Color3.fromRGB(35,35,35)}):Play()
        wait((config.Duration or 5)-1.2)
        TweenService:Create(icon,TweenInfo.new(0.4,Enum.EasingStyle.Quint),{ImageTransparency = 1}):Play()
        TweenService:Create(content,TweenInfo.new(0.4,Enum.EasingStyle.Quint),{TextTransparency = 1}):Play()
        TweenService:Create(title,TweenInfo.new(0.4,Enum.EasingStyle.Quint),{TextTransparency = 0.5}):Play()
        TweenService:Create(stroke,TweenInfo.new(0.4,Enum.EasingStyle.Quint),{Transparency = 0.8}):Play()
        wait(0.1)
        TweenService:Create(notif,TweenInfo.new(0.6,Enum.EasingStyle.Quint),{BackgroundTransparency = 0.5, Size = UDim2.new(1,-30,0,0)}):Play()
        wait(0.6)
        TweenService:Create(notif,TweenInfo.new(0.5,Enum.EasingStyle.Quint),{Size = UDim2.new(1,-70,0,0)}):Play()
        wait(0.6)
        notif:Destroy()
    end)
end

-- Config load/save
function SapphireLib:LoadConfig()
    if not SapphireLib.SaveCfg or not isfolder or not isfile or not readfile then return end
    pcall(function()
        local path = SapphireLib.Folder .. "/" .. game.GameId .. ".json"
        if isfile(path) then
            local data = HttpService:JSONDecode(readfile(path))
            for name, val in pairs(data) do
                if SapphireLib.Flags[name] then
                    spawn(function()
                        local flag = SapphireLib.Flags[name]
                        if flag.Type == "Colorpicker" then
                            flag:Set(unpackColor(val))
                        else
                            flag:Set(val)
                        end
                    end)
                end
            end
            SapphireLib:Notify({Title = "Config", Content = "Loaded saved configuration.", Duration = 4})
        end
    end)
end
function SapphireLib:SaveConfig()
    if not SapphireLib.SaveCfg or not isfolder or not writefile then return end
    local data = {}
    for name, flag in pairs(SapphireLib.Flags) do
        if flag.Save then
            if flag.Type == "Colorpicker" then data[name] = packColor(flag.Value) else data[name] = flag.Value end
        end
    end
    local path = SapphireLib.Folder .. "/" .. game.GameId .. ".json"
    pcall(function()
        if not isfolder(SapphireLib.Folder) then makefolder(SapphireLib.Folder) end
        writefile(path, HttpService:JSONEncode(data))
    end)
end

-- Window creation
function SapphireLib:CreateWindow(config)
    config = config or {}
    local WindowName = config.Name or "Sapphire UI"
    SapphireLib.Folder = config.ConfigFolder or WindowName
    SapphireLib.SaveCfg = config.SaveConfig or false
    if SapphireLib.SaveCfg and not isfolder(SapphireLib.Folder) then makefolder(SapphireLib.Folder) end

    local Main = Instance.new("Frame")
    Main.Name = "Main"; Main.Parent = Gui
    Main.BackgroundColor3 = SapphireLib.Themes.Default.Main
    Main.Position = UDim2.new(0.5,-307,0.5,-172); Main.Size = UDim2.new(0,615,0,344); Main.ClipsDescendants = true
    Instance.new("UICorner",Main).CornerRadius = UDim.new(0,10)

    local MainShadow = Instance.new("ImageLabel",Main)
    MainShadow.BackgroundTransparency = 1; MainShadow.Image = "rbxassetid://3523728077"
    MainShadow.AnchorPoint = Vector2.new(0.5,0.5); MainShadow.Position = UDim2.new(0.5,0,0.5,0)
    MainShadow.Size = UDim2.new(1,80,1,320); MainShadow.ImageColor3 = Color3.fromRGB(33,33,33); MainShadow.ImageTransparency = 0.7

    -- Topbar
    local TopBar = Instance.new("Frame",Main); TopBar.Size = UDim2.new(1,0,0,50); TopBar.BackgroundTransparency = 1
    local dragFrame = Instance.new("Frame",TopBar); dragFrame.Size = UDim2.new(1,0,0,50); dragFrame.BackgroundTransparency = 1
    local windowTitle = Instance.new("TextLabel",TopBar)
    windowTitle.Size = UDim2.new(1,-90,2,0); windowTitle.Position = UDim2.new(0,25,0,-24)
    windowTitle.Font = Enum.Font.GothamBlack; windowTitle.TextColor3 = SapphireLib.Themes.Default.Text; windowTitle.TextSize = 20; windowTitle.BackgroundTransparency = 1
    windowTitle.Text = WindowName
    if config.ShowIcon then
        windowTitle.Position = UDim2.new(0,50,0,-24)
        local icon = Instance.new("ImageLabel",TopBar); icon.Size = UDim2.new(0,20,0,20); icon.Position = UDim2.new(0,25,0,15)
        icon.BackgroundTransparency = 1; icon.Image = getIcon(config.Icon) or config.Icon or "rbxassetid://8834748103"
    end
    local topBarLine = Instance.new("Frame",TopBar); topBarLine.Size = UDim2.new(1,0,0,1); topBarLine.Position = UDim2.new(0,0,1,-1)
    topBarLine.BackgroundColor3 = SapphireLib.Themes.Default.Stroke; topBarLine.BorderSizePixel = 0

    -- Minimize/Close buttons
    local btnFrame = Instance.new("Frame",TopBar)
    btnFrame.BackgroundColor3 = SapphireLib.Themes.Default.Second; btnFrame.Size = UDim2.new(0,70,0,30); btnFrame.Position = UDim2.new(1,-90,0,10)
    Instance.new("UICorner",btnFrame).CornerRadius = UDim.new(0,7)
    Instance.new("UIStroke",btnFrame).Color = SapphireLib.Themes.Default.Stroke
    local btnDiv = Instance.new("Frame",btnFrame); btnDiv.Size = UDim2.new(0,1,1,0); btnDiv.Position = UDim2.new(0.5,0,0,0); btnDiv.BackgroundColor3 = SapphireLib.Themes.Default.Stroke
    local closeBtn = Instance.new("TextButton",btnFrame); closeBtn.Size = UDim2.new(0.5,0,1,0); closeBtn.BackgroundTransparency = 1; closeBtn.Text = ""
    local closeIco = Instance.new("ImageLabel",closeBtn); closeIco.Size = UDim2.new(0,18,0,18); closeIco.Position = UDim2.new(0,9,0,6); closeIco.BackgroundTransparency = 1
    closeIco.Image = "rbxassetid://7072725342"; closeIco.ImageColor3 = SapphireLib.Themes.Default.Text
    local minBtn = Instance.new("TextButton",btnFrame); minBtn.Size = UDim2.new(0.5,0,1,0); minBtn.Position = UDim2.new(0.5,0,0,0); minBtn.BackgroundTransparency = 1; minBtn.Text = ""
    local minIco = Instance.new("ImageLabel",minBtn); minIco.Size = UDim2.new(0,18,0,18); minIco.Position = UDim2.new(0,9,0,6); minIco.BackgroundTransparency = 1
    minIco.Image = "rbxassetid://7072719338"; minIco.ImageColor3 = SapphireLib.Themes.Default.Text

    -- Side panel
    local SidePanel = Instance.new("Frame",Main)
    SidePanel.Name = "SidePanel"; SidePanel.Size = UDim2.new(0,150,1,-50); SidePanel.Position = UDim2.new(0,0,0,50)
    SidePanel.BackgroundColor3 = SapphireLib.Themes.Default.Second; Instance.new("UICorner",SidePanel).CornerRadius = UDim.new(0,10)
    local p1 = Instance.new("Frame",SidePanel); p1.BackgroundColor3 = SidePanel.BackgroundColor3; p1.Size = UDim2.new(1,0,0,10); p1.Position = UDim2.new(0,0,0,0)
    local p2 = Instance.new("Frame",SidePanel); p2.BackgroundColor3 = SidePanel.BackgroundColor3; p2.Size = UDim2.new(0,10,1,0); p2.Position = UDim2.new(1,-10,0,0)
    local sideStroke = Instance.new("Frame",SidePanel); sideStroke.Size = UDim2.new(0,1,1,0); sideStroke.Position = UDim2.new(1,-1,0,0); sideStroke.BackgroundColor3 = SapphireLib.Themes.Default.Stroke

    local TabList = Instance.new("ScrollingFrame",SidePanel)
    TabList.Name = "TabList"; TabList.Size = UDim2.new(1,0,1,-50); TabList.BackgroundTransparency = 1
    TabList.ScrollBarThickness = 4; TabList.ScrollBarImageColor3 = SapphireLib.Themes.Default.Divider; TabList.CanvasSize = UDim2.new(0,0,0,0)
    Instance.new("UIListLayout",TabList).Padding = UDim.new(0,8)
    Instance.new("UIPadding",TabList).PaddingTop = UDim.new(0,8)

    local userSection = Instance.new("Frame",SidePanel)
    userSection.Size = UDim2.new(1,0,0,50); userSection.Position = UDim2.new(0,0,1,-50); userSection.BackgroundTransparency = 1
    local us = Instance.new("Frame",userSection); us.Size = UDim2.new(1,0,0,1); us.BackgroundColor3 = SapphireLib.Themes.Default.Stroke
    local avatarF = Instance.new("Frame",userSection); avatarF.AnchorPoint = Vector2.new(0,0.5); avatarF.Size = UDim2.new(0,32,0,32); avatarF.Position = UDim2.new(0,10,0.5,0); avatarF.BackgroundTransparency = 1
    local avatarIm = Instance.new("ImageLabel",avatarF); avatarIm.Size = UDim2.new(1,0,1,0); avatarIm.BackgroundTransparency = 1
    avatarIm.Image = "https://www.roblox.com/headshot-thumbnail/image?userId=".. LocalPlayer.UserId .."&width=420&height=420&format=png"
    Instance.new("UICorner",avatarF).CornerRadius = UDim.new(1,0); Instance.new("UIStroke",avatarF).Color = SapphireLib.Themes.Default.Stroke
    local avCov = Instance.new("ImageLabel",avatarF); avCov.Size = UDim2.new(1,0,1,0); avCov.BackgroundTransparency = 1; avCov.Image = "rbxassetid://4031889928"; avCov.ImageColor3 = SapphireLib.Themes.Default.Second
    local userName = Instance.new("TextLabel",userSection); userName.Size = UDim2.new(1,-60,0,13); userName.Position = config.HidePremium and UDim2.new(0,50,0,19) or UDim2.new(0,50,0,12)
    userName.Font = Enum.Font.GothamBold; userName.TextColor3 = SapphireLib.Themes.Default.Text; userName.TextSize = 13; userName.BackgroundTransparency = 1; userName.Text = LocalPlayer.DisplayName
    local userTag = Instance.new("TextLabel",userSection); userTag.Size = UDim2.new(1,-60,0,12); userTag.Position = UDim2.new(0,50,1,-25)
    userTag.Font = Enum.Font.GothamSemibold; userTag.TextColor3 = SapphireLib.Themes.Default.TextDark; userTag.TextSize = 12; userTag.BackgroundTransparency = 1; userTag.Text = ""
    if config.HidePremium then userTag.Visible = false end

    -- Elements container (main one with padding)
    local ElementsContainer = Instance.new("ScrollingFrame",Main)
    ElementsContainer.Name = "ElementsContainer"
    ElementsContainer.Size = UDim2.new(1,-150,1,-50); ElementsContainer.Position = UDim2.new(0,150,0,50)
    ElementsContainer.BackgroundTransparency = 1; ElementsContainer.ScrollBarThickness = 5
    ElementsContainer.ScrollBarImageColor3 = SapphireLib.Themes.Default.Divider; ElementsContainer.CanvasSize = UDim2.new(0,0,0,0)
    Instance.new("UIListLayout",ElementsContainer).Padding = UDim.new(0,6)
    local ep = Instance.new("UIPadding",ElementsContainer)
    ep.PaddingTop = UDim.new(0,15); ep.PaddingBottom = UDim.new(0,10); ep.PaddingLeft = UDim.new(0,10); ep.PaddingRight = UDim.new(0,15)

    -- Dragging
    local dragging, dragInput, mousePos, framePos
    dragFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true; mousePos = input.Position; framePos = Main.Position
            input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end)
        end
    end)
    dragFrame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then dragInput = input end
    end)
    addConnection(UserInputService.InputChanged, function(input)
        if input == dragInput and dragging then
            local delta = input.Position - mousePos
            TweenService:Create(Main, TweenInfo.new(0.45,Enum.EasingStyle.Quint,Enum.EasingDirection.Out), {
                Position = UDim2.new(framePos.X.Scale, framePos.X.Offset + delta.X, framePos.Y.Scale, framePos.Y.Offset + delta.Y)
            }):Play()
        end
    end)

    -- Minimize/Close functionality
    local minimized, hidden = false, false
    minBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        if minimized then
            minIco.Image = "rbxassetid://7072720870"
            Main.Size = UDim2.new(0, windowTitle.TextBounds.X + 140, 0, 50); Main.ClipsDescendants = true
            SidePanel.Visible = false; topBarLine.Visible = false
        else
            minIco.Image = "rbxassetid://7072719338"
            Main.Size = UDim2.new(0,615,0,344); wait(0.1); Main.ClipsDescendants = false
            SidePanel.Visible = true; topBarLine.Visible = true
        end
    end)
    closeBtn.MouseButton1Click:Connect(function()
        Main.Visible = false; hidden = true
        SapphireLib:Notify({Title = "Hidden", Content = "Press RightShift to toggle UI.", Duration = 5})
    end)
    addConnection(UserInputService.InputBegan, function(input)
        if input.KeyCode == Enum.KeyCode.RightShift and hidden then Main.Visible = true; hidden = false end
    end)

    -- Intro
    if config.IntroEnabled ~= false then
        Main.Visible = false
        local logo = Instance.new("ImageLabel",Gui); logo.AnchorPoint = Vector2.new(0.5,0.5); logo.Position = UDim2.new(0.5,0,0.4,0); logo.Size = UDim2.new(0,28,0,28)
        logo.BackgroundTransparency = 1; logo.Image = getIcon(config.IntroIcon) or config.IntroIcon or ""; logo.ImageTransparency = 1
        local intro = Instance.new("TextLabel",Gui); intro.AnchorPoint = Vector2.new(0.5,0.5); intro.Position = UDim2.new(0.5,19,0.5,0); intro.Size = UDim2.new(1,0,1,0); intro.BackgroundTransparency = 1
        intro.Font = Enum.Font.GothamBold; intro.TextColor3 = Color3.fromRGB(255,255,255); intro.TextSize = 14; intro.TextXAlignment = Enum.TextXAlignment.Center; intro.TextTransparency = 1
        intro.Text = config.IntroText or "Sapphire UI"
        TweenService:Create(logo, TweenInfo.new(0.3,Enum.EasingStyle.Quad), {ImageTransparency = 0, Position = UDim2.new(0.5,0,0.5,0)}):Play(); wait(0.8)
        TweenService:Create(logo, TweenInfo.new(0.3,Enum.EasingStyle.Quad), {Position = UDim2.new(0.5, -(intro.TextBounds.X/2),0.5,0)}):Play(); wait(0.3)
        TweenService:Create(intro, TweenInfo.new(0.3,Enum.EasingStyle.Quad), {TextTransparency = 0}):Play(); wait(2)
        TweenService:Create(intro, TweenInfo.new(0.3,Enum.EasingStyle.Quad), {TextTransparency = 1}):Play()
        Main.Visible = true; logo:Destroy(); intro:Destroy()
    end

    -- Tab system
    local firstTab = true
    local currentTab = nil
    local function selectTab(btn, container)
        if currentTab == container then return end
        currentTab = container
        for _, b in ipairs(TabList:GetChildren()) do
            if b:IsA("TextButton") then
                TweenService:Create(b.Ico, TweenInfo.new(0.25,Enum.EasingStyle.Quint), {ImageTransparency = 0.4}):Play()
                TweenService:Create(b.Title, TweenInfo.new(0.25,Enum.EasingStyle.Quint), {TextTransparency = 0.4}):Play()
                b.Title.Font = Enum.Font.GothamSemibold
            end
        end
        for _, c in ipairs(Main:GetChildren()) do
            if c.Name == "ElementsContainer" and c ~= container then c.Visible = false end
        end
        if container then container.Visible = true end
        if btn then
            TweenService:Create(btn.Ico, TweenInfo.new(0.25,Enum.EasingStyle.Quint), {ImageTransparency = 0}):Play()
            TweenService:Create(btn.Title, TweenInfo.new(0.25,Enum.EasingStyle.Quint), {TextTransparency = 0}):Play()
            btn.Title.Font = Enum.Font.GothamBlack
        end
    end

    local Window = {}
    function Window:CreateTab(name, iconID)
        local btn = Instance.new("TextButton",TabList)
        btn.Name = name; btn.Size = UDim2.new(1,0,0,30); btn.BackgroundTransparency = 1; btn.Text = ""
        local ico = Instance.new("ImageLabel",btn); ico.Name = "Ico"; ico.AnchorPoint = Vector2.new(0,0.5); ico.Size = UDim2.new(0,18,0,18); ico.Position = UDim2.new(0,10,0.5,0)
        ico.BackgroundTransparency = 1; ico.Image = getIcon(iconID) or iconID or ""; ico.ImageTransparency = 0.4; ico.ImageColor3 = SapphireLib.Themes.Default.Text
        local tit = Instance.new("TextLabel",btn); tit.Name = "Title"; tit.Size = UDim2.new(1,-35,1,0); tit.Position = UDim2.new(0,35,0,0)
        tit.BackgroundTransparency = 1; tit.Font = Enum.Font.GothamSemibold; tit.TextColor3 = SapphireLib.Themes.Default.Text; tit.TextSize = 14; tit.TextTransparency = 0.4; tit.TextXAlignment = Enum.TextXAlignment.Left; tit.Text = name

        local tabContainer = Instance.new("ScrollingFrame",Main)
        tabContainer.Name = name .. "_container"; tabContainer.Size = UDim2.new(1,-150,1,-50); tabContainer.Position = UDim2.new(0,150,0,50)
        tabContainer.BackgroundTransparency = 1; tabContainer.ScrollBarThickness = 5; tabContainer.ScrollBarImageColor3 = SapphireLib.Themes.Default.Divider
        tabContainer.CanvasSize = UDim2.new(0,0,0,0); tabContainer.Visible = false
        Instance.new("UIListLayout",tabContainer).Padding = UDim.new(0,6)
        local tp = Instance.new("UIPadding",tabContainer)
        tp.PaddingTop = UDim.new(0,15); tp.PaddingBottom = UDim.new(0,10); tp.PaddingLeft = UDim.new(0,10); tp.PaddingRight = UDim.new(0,15)

        btn.MouseButton1Click:Connect(function() selectTab(btn, tabContainer) end)
        if firstTab then firstTab = false; selectTab(btn, tabContainer) end

        local function elementBase(elemType, confName)
            local frame = Instance.new("Frame")
            frame.Name = confName; frame.Size = UDim2.new(1,0,0,38); frame.BackgroundColor3 = SapphireLib.Themes.Default.Second; frame.BorderSizePixel = 0
            Instance.new("UICorner",frame).CornerRadius = UDim.new(0,5)
            Instance.new("UIStroke",frame).Color = SapphireLib.Themes.Default.Stroke
            local txt = Instance.new("TextLabel",frame)
            txt.Size = UDim2.new(1,-12,1,0); txt.Position = UDim2.new(0,12,0,0); txt.BackgroundTransparency = 1
            txt.Font = Enum.Font.GothamBold; txt.TextColor3 = SapphireLib.Themes.Default.Text; txt.TextSize = 15; txt.TextXAlignment = Enum.TextXAlignment.Left
            txt.Text = confName
            return frame, txt
        end

        -- Element factories with anti‑bug
        local Tab = {}
        function Tab:CreateSection(name)
            local sf = Instance.new("Frame", tabContainer)
            sf.Size = UDim2.new(1,0,0,30); sf.BackgroundTransparency = 1
            local st = Instance.new("TextLabel",sf); st.Size = UDim2.new(1,-12,0,16); st.Position = UDim2.new(0,0,0,3); st.BackgroundTransparency = 1
            st.Font = Enum.Font.GothamSemibold; st.TextColor3 = SapphireLib.Themes.Default.TextDark; st.TextSize = 14; st.TextXAlignment = Enum.TextXAlignment.Left; st.Text = name
            local holder = Instance.new("Frame",sf)
            holder.Name = "Holder"; holder.AnchorPoint = Vector2.new(0,0); holder.Size = UDim2.new(1,0,1,-24); holder.Position = UDim2.new(0,0,0,23); holder.BackgroundTransparency = 1
            Instance.new("UIListLayout",holder).Padding = UDim.new(0,6)
            local function updateSize()
                sf.Size = UDim2.new(1,0,0, holder.UIListLayout.AbsoluteContentSize.Y + 31)
                holder.Size = UDim2.new(1,0,0, holder.UIListLayout.AbsoluteContentSize.Y)
            end
            local Section = {}
            for _, methodName in ipairs({"CreateButton","CreateToggle","CreateSlider","CreateDropdown","CreateColorPicker","CreateKeybind","CreateTextbox","CreateLabel","CreateParagraph","CreateDivider"}) do
                Section[methodName] = function(_, ...)
                    if not Tab[methodName] then return end
                    local elem = Tab[methodName](...)
                    if elem and elem.frame then
                        elem.frame.Parent = holder
                        -- defer size update
                        task.wait()
                        updateSize()
                    end
                    return elem
                end
            end
            return Section
        end

        Tab.CreateButton = function(config)
            if not checkConfig(config, "Button") then return end
            local frame, fText = elementBase("Button", config.Name)
            local click = Instance.new("TextButton",frame); click.Size = UDim2.new(1,0,1,0); click.BackgroundTransparency = 1; click.Text = ""
            local btn = {frame = frame}
            click.MouseEnter:Connect(function() TweenService:Create(frame,TweenInfo.new(0.25,Enum.EasingStyle.Quint),{BackgroundColor3 = SapphireLib.Themes.Default.Second * 1.1}):Play() end)
            click.MouseLeave:Connect(function() TweenService:Create(frame,TweenInfo.new(0.25,Enum.EasingStyle.Quint),{BackgroundColor3 = SapphireLib.Themes.Default.Second}):Play() end)
            click.MouseButton1Click:Connect(function()
                TweenService:Create(frame,TweenInfo.new(0.15,Enum.EasingStyle.Quint),{BackgroundColor3 = SapphireLib.Themes.Default.Second * 1.2}):Play(); wait(0.15)
                TweenService:Create(frame,TweenInfo.new(0.25,Enum.EasingStyle.Quint),{BackgroundColor3 = SapphireLib.Themes.Default.Second}):Play()
                safeCallback(config.Callback)
            end)
            btn.Set = function(self,txt) fText.Text = txt end
            return btn
        end

        Tab.CreateToggle = function(config)
            if not checkConfig(config, "Toggle") then return end
            local frame, fText = elementBase("Toggle", config.Name)
            local value = config.Default or false
            local tb = Instance.new("Frame",frame); tb.Size = UDim2.new(0,24,0,24); tb.Position = UDim2.new(1,-24,0.5,0); tb.AnchorPoint = Vector2.new(0.5,0.5); tb.BorderSizePixel = 0
            Instance.new("UICorner",tb).CornerRadius = UDim.new(0,4)
            local ts = Instance.new("UIStroke",tb); ts.Color = SapphireLib.Themes.Default.Stroke
            local ti = Instance.new("ImageLabel",tb); ti.Size = UDim2.new(0,20,0,20); ti.AnchorPoint = Vector2.new(0.5,0.5); ti.Position = UDim2.new(0.5,0,0.5,0)
            ti.BackgroundTransparency = 1; ti.Image = "rbxassetid://3944680095"; ti.ImageColor3 = Color3.fromRGB(255,255,255)
            local click = Instance.new("TextButton",frame); click.Size = UDim2.new(1,0,1,0); click.BackgroundTransparency = 1; click.Text = ""
            local toggle = {frame = frame, Value = value, Save = config.Save ~= false, Type = "Toggle"}
            local function updateVisual()
                if toggle.Value then
                    tb.BackgroundColor3 = config.Color or Color3.fromRGB(9,99,195)
                    ts.Color = config.Color or Color3.fromRGB(9,99,195)
                    ti.ImageTransparency = 0; ti.Size = UDim2.new(0,20,0,20)
                else
                    tb.BackgroundColor3 = SapphireLib.Themes.Default.Divider
                    ts.Color = SapphireLib.Themes.Default.Stroke
                    ti.ImageTransparency = 1; ti.Size = UDim2.new(0,8,0,8)
                end
            end
            updateVisual()
            click.MouseEnter:Connect(function() TweenService:Create(frame,TweenInfo.new(0.25,Enum.EasingStyle.Quint),{BackgroundColor3 = SapphireLib.Themes.Default.Second * 1.1}):Play() end)
            click.MouseLeave:Connect(function() TweenService:Create(frame,TweenInfo.new(0.25,Enum.EasingStyle.Quint),{BackgroundColor3 = SapphireLib.Themes.Default.Second}):Play() end)
            click.MouseButton1Click:Connect(function()
                toggle:Set(not toggle.Value)
                SapphireLib:SaveConfig()
            end)
            function toggle:Set(val)
                self.Value = val
                TweenService:Create(tb,TweenInfo.new(0.3,Enum.EasingStyle.Quint),{BackgroundColor3 = val and (config.Color or Color3.fromRGB(9,99,195)) or SapphireLib.Themes.Default.Divider}):Play()
                TweenService:Create(ts,TweenInfo.new(0.3,Enum.EasingStyle.Quint),{Color = val and (config.Color or Color3.fromRGB(9,99,195)) or SapphireLib.Themes.Default.Stroke}):Play()
                TweenService:Create(ti,TweenInfo.new(0.3,Enum.EasingStyle.Quint),{ImageTransparency = val and 0 or 1, Size = val and UDim2.new(0,20,0,20) or UDim2.new(0,8,0,8)}):Play()
                safeCallback(config.Callback, self.Value)
            end
            if config.Flag then SapphireLib.Flags[config.Flag] = toggle end
            return toggle
        end

        Tab.CreateSlider = function(config)
            if not checkConfig(config, "Slider") then return end
            local frame = Instance.new("Frame"); frame.Size = UDim2.new(1,0,0,65)
            frame.BackgroundColor3 = SapphireLib.Themes.Default.Second; frame.BorderSizePixel = 0
            Instance.new("UICorner",frame).CornerRadius = UDim.new(0,5); Instance.new("UIStroke",frame).Color = SapphireLib.Themes.Default.Stroke
            local fText = Instance.new("TextLabel",frame); fText.Size = UDim2.new(1,-12,0,14); fText.Position = UDim2.new(0,12,0,10); fText.BackgroundTransparency = 1
            fText.Font = Enum.Font.GothamBold; fText.TextColor3 = SapphireLib.Themes.Default.Text; fText.TextSize = 15; fText.TextXAlignment = Enum.TextXAlignment.Left; fText.Text = config.Name
            local sliderBar = Instance.new("Frame",frame); sliderBar.Size = UDim2.new(1,-24,0,26); sliderBar.Position = UDim2.new(0,12,0,30)
            sliderBar.BackgroundTransparency = 0.9; sliderBar.BackgroundColor3 = config.Color or Color3.fromRGB(9,149,98); sliderBar.BorderSizePixel = 0
            Instance.new("UICorner",sliderBar).CornerRadius = UDim.new(0,5); Instance.new("UIStroke",sliderBar).Color = config.Color or Color3.fromRGB(9,149,98)
            local sliderProgress = Instance.new("Frame",sliderBar); sliderProgress.Size = UDim2.new(0,0,1,0); sliderProgress.BackgroundColor3 = config.Color or Color3.fromRGB(9,149,98)
            sliderProgress.BackgroundTransparency = 0.3; sliderProgress.BorderSizePixel = 0; Instance.new("UICorner",sliderProgress).CornerRadius = UDim.new(0,5)
            local valueLabel = Instance.new("TextLabel",sliderBar); valueLabel.Size = UDim2.new(1,-12,1,0); valueLabel.Position = UDim2.new(0,12,0,0); valueLabel.BackgroundTransparency = 1
            valueLabel.Font = Enum.Font.GothamBold; valueLabel.TextColor3 = SapphireLib.Themes.Default.Text; valueLabel.TextSize = 13; valueLabel.TextXAlignment = Enum.TextXAlignment.Left; valueLabel.TextTransparency = 0.8
            local dragging = false
            local slider = {frame = frame, Value = config.Default or 50, Save = config.Save ~= false, Type = "Slider"}
            local function setVisual(val)
                val = math.clamp(round(val, config.Increment or 1), config.Min, config.Max)
                local frac = (val - config.Min) / (config.Max - config.Min)
                TweenService:Create(sliderProgress,TweenInfo.new(0.15,Enum.EasingStyle.Quad),{Size = UDim2.fromScale(frac,1)}):Play()
                valueLabel.Text = tostring(val) .. (config.Suffix and " " .. config.Suffix or "")
                slider.Value = val
            end
            setVisual(slider.Value)
            sliderBar.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true end end)
            sliderBar.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)
            addConnection(UserInputService.InputChanged, function(input)
                if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                    local frac = math.clamp((input.Position.X - sliderBar.AbsolutePosition.X)/sliderBar.AbsoluteSize.X, 0, 1)
                    local val = config.Min + frac * (config.Max - config.Min)
                    setVisual(val); safeCallback(config.Callback, slider.Value)
                    SapphireLib:SaveConfig()
                end
            end)
            function slider:Set(val) setVisual(val); safeCallback(config.Callback, self.Value) end
            if config.Flag then SapphireLib.Flags[config.Flag] = slider end
            return slider
        end

        Tab.CreateDropdown = function(config)
            if not checkConfig(config, "Dropdown") then return end
            local frame, fText = elementBase("Dropdown", config.Name)
            local value = config.Default or ""
            local toggled = false; local options = config.Options or {}
            local selLabel = Instance.new("TextLabel",frame); selLabel.Size = UDim2.new(1,-40,1,0); selLabel.BackgroundTransparency = 1; selLabel.Font = Enum.Font.Gotham
            selLabel.TextColor3 = SapphireLib.Themes.Default.TextDark; selLabel.TextSize = 13; selLabel.TextXAlignment = Enum.TextXAlignment.Right; selLabel.Text = value
            local dropIcon = Instance.new("ImageLabel",frame); dropIcon.Size = UDim2.new(0,20,0,20); dropIcon.Position = UDim2.new(1,-30,0.5,0); dropIcon.AnchorPoint = Vector2.new(0,0.5)
            dropIcon.BackgroundTransparency = 1; dropIcon.Image = "rbxassetid://7072706796"; dropIcon.ImageColor3 = SapphireLib.Themes.Default.TextDark
            local dropContainer = Instance.new("ScrollingFrame",frame)
            dropContainer.Position = UDim2.new(0,0,0,38); dropContainer.Size = UDim2.new(1,0,1,-38); dropContainer.BackgroundTransparency = 1
            dropContainer.CanvasSize = UDim2.new(0,0,0,0); dropContainer.ScrollBarThickness = 4
            dropContainer.ScrollBarImageColor3 = SapphireLib.Themes.Default.Divider; dropContainer.ClipsDescendants = true
            Instance.new("UIListLayout",dropContainer)
            local click = Instance.new("TextButton",frame); click.Size = UDim2.new(1,0,1,0); click.BackgroundTransparency = 1; click.Text = ""
            local dropdown = {frame = frame, Value = value, Options = options, Buttons = {}, Save = config.Save ~= false, Type = "Dropdown"}
            local function refresh(clear)
                if clear then for _,b in pairs(dropdown.Buttons) do b:Destroy() end; table.clear(dropdown.Buttons) end
                for _,opt in ipairs(options) do
                    local ob = Instance.new("TextButton",dropContainer); ob.Size = UDim2.new(1,0,0,28); ob.BackgroundTransparency = 1; ob.Text = ""
                    local ol = Instance.new("TextLabel",ob); ol.Size = UDim2.new(1,-8,1,0); ol.Position = UDim2.new(0,8,0,0); ol.BackgroundTransparency = 1; ol.Font = Enum.Font.Gotham; ol.TextColor3 = SapphireLib.Themes.Default.Text; ol.TextSize = 13; ol.TextXAlignment = Enum.TextXAlignment.Left; ol.Text = opt
                    ob.MouseButton1Click:Connect(function() dropdown:Set(opt); SapphireLib:SaveConfig() end)
                    dropdown.Buttons[opt] = ob
                end
                dropContainer.CanvasSize = UDim2.new(0,0,0, dropContainer.UIListLayout.AbsoluteContentSize.Y)
            end
            click.MouseButton1Click:Connect(function()
                toggled = not toggled
                TweenService:Create(dropIcon,TweenInfo.new(0.15,Enum.EasingStyle.Quad),{Rotation = toggled and 180 or 0}):Play()
                local max = #options > 5 and (5*28) or dropContainer.UIListLayout.AbsoluteContentSize.Y
                TweenService:Create(frame,TweenInfo.new(0.15,Enum.EasingStyle.Quad),{Size = toggled and UDim2.new(1,0,0, max+38) or UDim2.new(1,0,0,38)}):Play()
            end)
            function dropdown:Set(val)
                self.Value = val; selLabel.Text = val
                for _,b in pairs(self.Buttons) do TweenService:Create(b,TweenInfo.new(0.15,Enum.EasingStyle.Quad),{BackgroundTransparency = 1}):Play() end
                if self.Buttons[val] then TweenService:Create(self.Buttons[val],TweenInfo.new(0.15,Enum.EasingStyle.Quad),{BackgroundTransparency = 0}):Play() end
                safeCallback(config.Callback, val)
            end
            function dropdown:Refresh(newOpts) options = newOpts; refresh(true) end
            refresh(); dropdown:Set(value)
            if config.Flag then SapphireLib.Flags[config.Flag] = dropdown end
            return dropdown
        end

        Tab.CreateColorPicker = function(config)
            if not checkConfig(config, "ColorPicker") then return end
            local frame, fText = elementBase("ColorPicker", config.Name)
            local value = config.Default or Color3.fromRGB(255,255,255)
            local toggled = false
            local pickerCont = Instance.new("Frame",frame); pickerCont.Position = UDim2.new(0,0,0,38); pickerCont.Size = UDim2.new(1,0,1,-38); pickerCont.BackgroundTransparency = 1; pickerCont.ClipsDescendants = true
            local colorBox = Instance.new("Frame",frame); colorBox.Size = UDim2.new(0,24,0,24); colorBox.Position = UDim2.new(1,-12,0.5,0); colorBox.AnchorPoint = Vector2.new(1,0.5)
            colorBox.BackgroundColor3 = value; colorBox.BorderSizePixel = 0; Instance.new("UICorner",colorBox).CornerRadius = UDim.new(0,4); Instance.new("UIStroke",colorBox).Color = SapphireLib.Themes.Default.Stroke
            local canvas = Instance.new("ImageLabel",pickerCont); canvas.Size = UDim2.new(1,-25,1,0); canvas.BackgroundTransparency = 1; canvas.Image = "rbxassetid://4155801252"
            Instance.new("UICorner",canvas).CornerRadius = UDim.new(0,5)
            local colorSel = Instance.new("ImageLabel",canvas); colorSel.Size = UDim2.new(0,18,0,18); colorSel.AnchorPoint = Vector2.new(0.5,0.5); colorSel.BackgroundTransparency = 1; colorSel.Image = "http://www.roblox.com/asset/?id=4805639000"
            local hueFrame = Instance.new("Frame",pickerCont); hueFrame.Size = UDim2.new(0,20,1,0); hueFrame.Position = UDim2.new(1,-20,0,0); hueFrame.BorderSizePixel = 0; Instance.new("UICorner",hueFrame).CornerRadius = UDim.new(0,5)
            local hueGrad = Instance.new("UIGradient",hueFrame); hueGrad.Rotation = 270
            hueGrad.Color = ColorSequence.new{
                ColorSequenceKeypoint.new(0,Color3.fromRGB(255,0,4)),
                ColorSequenceKeypoint.new(0.2,Color3.fromRGB(234,255,0)),
                ColorSequenceKeypoint.new(0.4,Color3.fromRGB(21,255,0)),
                ColorSequenceKeypoint.new(0.6,Color3.fromRGB(0,255,255)),
                ColorSequenceKeypoint.new(0.8,Color3.fromRGB(0,17,255)),
                ColorSequenceKeypoint.new(0.9,Color3.fromRGB(255,0,251)),
                ColorSequenceKeypoint.new(1,Color3.fromRGB(255,0,4))
            }
            local hueSel = Instance.new("ImageLabel",hueFrame); hueSel.Size = UDim2.new(0,18,0,18); hueSel.AnchorPoint = Vector2.new(0.5,0.5); hueSel.BackgroundTransparency = 1; hueSel.Image = "http://www.roblox.com/asset/?id=4805639000"
            local click = Instance.new("TextButton",frame); click.Size = UDim2.new(1,0,1,0); click.BackgroundTransparency = 1; click.Text = ""
            local cp = {frame = frame, Value = value, Save = config.Save ~= false, Type = "Colorpicker"}
            local function updateColor()
                colorBox.BackgroundColor3 = cp.Value; canvas.BackgroundColor3 = Color3.fromHSV(cp.H or 1,1,1)
                local x = cp.S * canvas.AbsoluteSize.X; local y = (1 - cp.V) * canvas.AbsoluteSize.Y
                colorSel.Position = UDim2.new(0, x - colorSel.AbsoluteSize.X/2, 0, y - colorSel.AbsoluteSize.Y/2)
                local hy = (1 - cp.H) * hueFrame.AbsoluteSize.Y; hueSel.Position = UDim2.new(0.5,0,0, hy - hueSel.AbsoluteSize.Y/2)
                safeCallback(config.Callback, cp.Value)
            end
            local function setFromHSV()
                cp.Value = Color3.fromHSV(cp.H, cp.S, cp.V); updateColor(); SapphireLib:SaveConfig()
            end
            cp.H, cp.S, cp.V = Color3.toHSV(value); updateColor()
            click.MouseButton1Click:Connect(function()
                toggled = not toggled
                TweenService:Create(frame,TweenInfo.new(0.15,Enum.EasingStyle.Quad),{Size = toggled and UDim2.new(1,0,0,148) or UDim2.new(1,0,0,38)}):Play()
                canvas.Visible = toggled; hueFrame.Visible = toggled
            end)
            local cInput, hInput
            canvas.InputBegan:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1 then
                    if cInput then cInput:Disconnect() end
                    cInput = addConnection(RunService.RenderStepped, function()
                        local mx = math.clamp(Mouse.X - canvas.AbsolutePosition.X, 0, canvas.AbsoluteSize.X)
                        local my = math.clamp(Mouse.Y - canvas.AbsolutePosition.Y, 0, canvas.AbsoluteSize.Y)
                        cp.S = mx / canvas.AbsoluteSize.X; cp.V = 1 - my / canvas.AbsoluteSize.Y; setFromHSV()
                    end)
                end
            end)
            canvas.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 and cInput then cInput:Disconnect() end end)
            hueFrame.InputBegan:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1 then
                    if hInput then hInput:Disconnect() end
                    hInput = addConnection(RunService.RenderStepped, function()
                        local my = math.clamp(Mouse.Y - hueFrame.AbsolutePosition.Y, 0, hueFrame.AbsoluteSize.Y)
                        cp.H = 1 - my / hueFrame.AbsoluteSize.Y; setFromHSV()
                    end)
                end
            end)
            hueFrame.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 and hInput then hInput:Disconnect() end end)
            function cp:Set(col)
                self.Value = col; self.H, self.S, self.V = Color3.toHSV(col); updateColor()
            end
            if config.Flag then SapphireLib.Flags[config.Flag] = cp end
            return cp
        end

        Tab.CreateKeybind = function(config)
            if not checkConfig(config, "Keybind") then return end
            local frame, fText = elementBase("Keybind", config.Name)
            local currentKey = config.Default or Enum.KeyCode.Unknown
            local binding = false
            local keyLabel = Instance.new("TextLabel",frame); keyLabel.Size = UDim2.new(0,24,0,24); keyLabel.Position = UDim2.new(1,-12,0.5,0); keyLabel.AnchorPoint = Vector2.new(1,0.5)
            keyLabel.BackgroundColor3 = SapphireLib.Themes.Default.Main; keyLabel.BorderSizePixel = 0; Instance.new("UICorner",keyLabel).CornerRadius = UDim.new(0,4)
            Instance.new("UIStroke",keyLabel).Color = SapphireLib.Themes.Default.Stroke
            keyLabel.Font = Enum.Font.GothamBold; keyLabel.TextColor3 = SapphireLib.Themes.Default.Text; keyLabel.TextSize = 14; keyLabel.TextXAlignment = Enum.TextXAlignment.Center
            keyLabel.Text = currentKey.Name ~= "Unknown" and currentKey.Name or "..."
            local click = Instance.new("TextButton",frame); click.Size = UDim2.new(1,0,1,0); click.BackgroundTransparency = 1; click.Text = ""
            local kb = {frame = frame, Value = currentKey, Save = config.Save ~= false, Type = "Bind"}
            click.InputEnded:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1 and not binding then binding = true; keyLabel.Text = "..." end
            end)
            addConnection(UserInputService.InputBegan, function(input)
                if UserInputService:GetFocusedTextBox() then return end
                if (input.KeyCode == currentKey or input.UserInputType == currentKey) and not binding then
                    if config.Hold then
                        local hold = true; safeCallback(config.Callback, true)
                        local endCon; endCon = UserInputService.InputEnded:Connect(function(inp)
                            if inp.KeyCode == currentKey or inp.UserInputType == currentKey then
                                safeCallback(config.Callback, false); endCon:Disconnect()
                            end
                        end)
                    else safeCallback(config.Callback) end
                elseif binding then
                    local key = nil
                    local blacklist = {Enum.KeyCode.Unknown, Enum.KeyCode.W,Enum.KeyCode.A,Enum.KeyCode.S,Enum.KeyCode.D,Enum.KeyCode.Up,Enum.KeyCode.Left,Enum.KeyCode.Down,Enum.KeyCode.Right,Enum.KeyCode.Slash,Enum.KeyCode.Tab,Enum.KeyCode.Backspace,Enum.KeyCode.Escape}
                    pcall(function() if not table.find(blacklist, input.KeyCode) then key = input.KeyCode end end)
                    pcall(function() if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.MouseButton2 or input.UserInputType == Enum.UserInputType.MouseButton3 then if not key then key = input.UserInputType end end end)
                    key = key or currentKey; kb:Set(key); SapphireLib:SaveConfig()
                end
            end)
            function kb:Set(key)
                binding = false; self.Value = key; currentKey = key; keyLabel.Text = key.Name ~= "Unknown" and key.Name or "..."
            end
            if config.Flag then SapphireLib.Flags[config.Flag] = kb end
            return kb
        end

        Tab.CreateTextbox = function(config)
            if not checkConfig(config, "Textbox") then return end
            local frame, fText = elementBase("Textbox", config.Name)
            local textBox = Instance.new("TextBox",frame); textBox.Size = UDim2.new(0,24,0,24); textBox.Position = UDim2.new(1,-12,0.5,0); textBox.AnchorPoint = Vector2.new(1,0.5)
            textBox.BackgroundColor3 = SapphireLib.Themes.Default.Main; textBox.BorderSizePixel = 0; Instance.new("UICorner",textBox).CornerRadius = UDim.new(0,4)
            Instance.new("UIStroke",textBox).Color = SapphireLib.Themes.Default.Stroke
            textBox.Font = Enum.Font.GothamSemibold; textBox.TextColor3 = SapphireLib.Themes.Default.Text; textBox.TextSize = 14; textBox.TextXAlignment = Enum.TextXAlignment.Center
            textBox.ClearTextOnFocus = false; textBox.Text = config.Default or ""; textBox.PlaceholderText = config.Placeholder or "Input"; textBox.PlaceholderColor3 = Color3.fromRGB(210,210,210)
            textBox:GetPropertyChangedSignal("Text"):Connect(function()
                TweenService:Create(textBox,TweenInfo.new(0.45,Enum.EasingStyle.Quint),{Size = UDim2.new(0, textBox.TextBounds.X + 16, 0, 24)}):Play()
            end)
            textBox.FocusLost:Connect(function()
                safeCallback(config.Callback, textBox.Text)
                if config.TextDisappear then textBox.Text = "" end
            end)
            local click = Instance.new("TextButton",frame); click.Size = UDim2.new(1,0,1,0); click.BackgroundTransparency = 1; click.Text = ""
            click.MouseButton1Click:Connect(function() textBox:CaptureFocus() end)
            local obj = {frame = frame}
            function obj:Set(t) textBox.Text = t; safeCallback(config.Callback, t) end
            return obj
        end

        Tab.CreateLabel = function(text, iconID, colorOverride)
            local frame = Instance.new("Frame"); frame.Size = UDim2.new(1,0,0,30)
            frame.BackgroundColor3 = colorOverride or SapphireLib.Themes.Default.Second; frame.BackgroundTransparency = 0.7; frame.BorderSizePixel = 0
            Instance.new("UICorner",frame).CornerRadius = UDim.new(0,5); Instance.new("UIStroke",frame).Color = colorOverride and colorOverride or SapphireLib.Themes.Default.Stroke
            local lbl = Instance.new("TextLabel",frame); lbl.Size = UDim2.new(1,-12,1,0); lbl.Position = UDim2.new(0,12,0,0); lbl.BackgroundTransparency = 1
            lbl.Font = Enum.Font.GothamBold; lbl.TextColor3 = SapphireLib.Themes.Default.Text; lbl.TextSize = 15; lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Text = text
            if iconID then
                lbl.Position = UDim2.new(0,45,0,0); lbl.Size = UDim2.new(1,-100,0,14)
                local ic = Instance.new("ImageLabel",frame); ic.Size = UDim2.new(0,20,0,20); ic.Position = UDim2.new(0,12,0.5,0); ic.AnchorPoint = Vector2.new(0,0.5)
                ic.BackgroundTransparency = 1; ic.Image = getIcon(iconID) or iconID; ic.ImageColor3 = SapphireLib.Themes.Default.Text; ic.ImageTransparency = 0.2
            end
            local lab = {frame = frame}
            function lab:Set(t) lbl.Text = t end
            return lab
        end

        Tab.CreateParagraph = function(title, content)
            local frame = Instance.new("Frame"); frame.Size = UDim2.new(1,0,0,30)
            frame.BackgroundColor3 = SapphireLib.Themes.Default.Second; frame.BackgroundTransparency = 0.7; frame.BorderSizePixel = 0
            Instance.new("UICorner",frame).CornerRadius = UDim.new(0,5); Instance.new("UIStroke",frame).Color = SapphireLib.Themes.Default.Stroke
            local tl = Instance.new("TextLabel",frame); tl.Size = UDim2.new(1,-12,0,14); tl.Position = UDim2.new(0,12,0,10); tl.BackgroundTransparency = 1
            tl.Font = Enum.Font.GothamBold; tl.TextColor3 = SapphireLib.Themes.Default.Text; tl.TextSize = 15; tl.TextXAlignment = Enum.TextXAlignment.Left; tl.Text = title
            local cl = Instance.new("TextLabel",frame); cl.Size = UDim2.new(1,-24,0,0); cl.Position = UDim2.new(0,12,0,26); cl.BackgroundTransparency = 1
            cl.Font = Enum.Font.GothamSemibold; cl.TextColor3 = SapphireLib.Themes.Default.TextDark; cl.TextSize = 13; cl.TextXAlignment = Enum.TextXAlignment.Left; cl.TextWrapped = true; cl.Text = content
            cl:GetPropertyChangedSignal("Text"):Connect(function()
                cl.Size = UDim2.new(1,-24,0, cl.TextBounds.Y); frame.Size = UDim2.new(1,0,0, cl.TextBounds.Y + 35)
            end)
            local par = {frame = frame}
            function par:Set(cont) cl.Text = cont end
            return par
        end

        Tab.CreateDivider = function()
            local frame = Instance.new("Frame"); frame.Size = UDim2.new(1,0,0,1); frame.BackgroundColor3 = SapphireLib.Themes.Default.Stroke; frame.BackgroundTransparency = 0.85; frame.BorderSizePixel = 0
            local div = {frame = frame}
            function div:Set(v) frame.Visible = v end
            return div
        end

        return Tab
    end

    function Window:SetTheme(theme)
        if SapphireLib.Themes[theme] then
            SapphireLib.SelectedTheme = theme
            -- (Full theme update not implemented to keep code concise)
        end
    end

    return Window
end

function SapphireLib:Init()
    if SapphireLib.SaveCfg then self:LoadConfig() end
end
function SapphireLib:Destroy()
    Gui:Destroy()
end

return SapphireLib
