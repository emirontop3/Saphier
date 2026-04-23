--[[
    Sapphire UI Library
    Usage:
    local lib = loadstring(game:HttpGet("URL"))()
    local win = lib:CreateWindow({...})
    local tab = win:CreateTab("Tab", iconId)
    local section = tab:CreateSection("Section")
    section:CreateButton({...})
    lib:Notify({...})
    lib:Init()
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

-- Icon library fallback
local Icons = {}
pcall(function()
    Icons = HttpService:JSONDecode(game:HttpGetAsync("https://raw.githubusercontent.com/evoincorp/lucideblox/master/src/modules/util/icons.json")).icons
end)

-- Helper functions
local function getIcon(iconName)
    if Icons[iconName] then return Icons[iconName] end
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
        Main = Color3.fromRGB(25, 25, 25),
        Second = Color3.fromRGB(32, 32, 32),
        Stroke = Color3.fromRGB(60, 60, 60),
        Text = Color3.fromRGB(240, 240, 240),
        TextDark = Color3.fromRGB(150, 150, 150),
        Divider = Color3.fromRGB(60, 60, 60),
    }
}
SapphireLib.SelectedTheme = "Default"

SapphireLib.Flags = {}
SapphireLib.Connections = {}
SapphireLib.Folder = nil
SapphireLib.SaveCfg = false

-- ScreenGui setup
local Gui = Instance.new("ScreenGui")
Gui.Name = "SapphireUI"
if syn then
    syn.protect_gui(Gui)
    Gui.Parent = CoreGui
else
    Gui.Parent = gethui() or CoreGui
end

-- Remove old duplicates
if gethui then
    for _, v in ipairs(gethui():GetChildren()) do
        if v.Name == Gui.Name and v ~= Gui then v:Destroy() end
    end
else
    for _, v in ipairs(CoreGui:GetChildren()) do
        if v.Name == Gui.Name and v ~= Gui then v:Destroy() end
    end
end

local NotificationHolder = Instance.new("Frame")
NotificationHolder.Name = "NotificationHolder"
NotificationHolder.Position = UDim2.new(1, -25, 1, -25)
NotificationHolder.Size = UDim2.new(0, 300, 1, -25)
NotificationHolder.AnchorPoint = Vector2.new(1, 1)
NotificationHolder.BackgroundTransparency = 1
NotificationHolder.Parent = Gui

local function addConnection(signal, func)
    if not Gui or not Gui.Parent then return end
    local con = signal:Connect(func)
    table.insert(SapphireLib.Connections, con)
    return con
end

-- Clean up connections when Gui is destroyed
Gui.Destroying:Connect(function()
    for _, con in ipairs(SapphireLib.Connections) do
        con:Disconnect()
    end
    SapphireLib.Connections = {}
end)

-- Notification system
function SapphireLib:Notify(config)
    spawn(function()
        local notif = Instance.new("Frame")
        notif.Name = "Notification"
        notif.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
        notif.BorderSizePixel = 0
        notif.Size = UDim2.new(1, 0, 0, 0)
        notif.AutomaticSize = Enum.AutomaticSize.Y
        notif.ClipsDescendants = true

        local corner = Instance.new("UICorner", notif)
        corner.CornerRadius = UDim.new(0, 8)

        local stroke = Instance.new("UIStroke", notif)
        stroke.Color = Color3.fromRGB(93, 93, 93)
        stroke.Thickness = 1.2

        local icon = Instance.new("ImageLabel", notif)
        icon.Name = "Icon"
        icon.BackgroundTransparency = 1
        icon.Size = UDim2.new(0, 20, 0, 20)
        icon.Position = UDim2.new(0, 12, 0, 12)
        icon.ImageColor3 = Color3.fromRGB(240, 240, 240)
        if config.Image then
            icon.Image = getIcon(config.Image) or config.Image
        else
            icon.Image = "rbxassetid://4384403532"
        end

        local title = Instance.new("TextLabel", notif)
        title.Name = "Title"
        title.BackgroundTransparency = 1
        title.Size = UDim2.new(1, -42, 0, 18)
        title.Position = UDim2.new(0, 42, 0, 12)
        title.Font = Enum.Font.GothamBold
        title.TextColor3 = Color3.fromRGB(240, 240, 240)
        title.TextSize = 15
        title.TextXAlignment = Enum.TextXAlignment.Left
        title.Text = config.Title or "Notification"

        local content = Instance.new("TextLabel", notif)
        content.Name = "Content"
        content.BackgroundTransparency = 1
        content.Size = UDim2.new(1, -24, 0, 0)
        content.Position = UDim2.new(0, 12, 0, 36)
        content.Font = Enum.Font.GothamSemibold
        content.TextColor3 = Color3.fromRGB(200, 200, 200)
        content.TextSize = 14
        content.TextXAlignment = Enum.TextXAlignment.Left
        content.TextWrapped = true
        content.AutomaticSize = Enum.AutomaticSize.Y
        content.Text = config.Content or ""

        notif.Parent = NotificationHolder

        -- Tween in
        notif.Size = UDim2.new(1, -30, 0, 0)
        local finalY = content.TextBounds.Y + 50
        TweenService:Create(notif, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {Size = UDim2.new(1, -30, 0, finalY)}):Play()
        wait(0.1)
        TweenService:Create(notif, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {BackgroundColor3 = Color3.fromRGB(35,35,35)}):Play()

        wait((config.Duration or 5) - 1.2)
        TweenService:Create(icon, TweenInfo.new(0.4, Enum.EasingStyle.Quint), {ImageTransparency = 1}):Play()
        TweenService:Create(content, TweenInfo.new(0.4, Enum.EasingStyle.Quint), {TextTransparency = 1}):Play()
        TweenService:Create(title, TweenInfo.new(0.4, Enum.EasingStyle.Quint), {TextTransparency = 0.5}):Play()
        TweenService:Create(stroke, TweenInfo.new(0.4, Enum.EasingStyle.Quint), {Transparency = 0.8}):Play()
        wait(0.1)
        TweenService:Create(notif, TweenInfo.new(0.6, Enum.EasingStyle.Quint), {BackgroundTransparency = 0.5, Size = UDim2.new(1, -30, 0, 0)}):Play()
        wait(0.6)
        TweenService:Create(notif, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {Size = UDim2.new(1, -70, 0, 0)}):Play()
        wait(0.6)
        notif:Destroy()
    end)
end

-- Configuration saving
function SapphireLib:LoadConfig()
    if not SapphireLib.SaveCfg or not isfolder or not isfile or not readfile then return end
    pcall(function()
        local path = SapphireLib.Folder .. "/" .. game.GameId .. ".json"
        if isfile(path) then
            local data = HttpService:JSONDecode(readfile(path))
            for flagName, flagVal in pairs(data) do
                if SapphireLib.Flags[flagName] then
                    spawn(function()
                        local flag = SapphireLib.Flags[flagName]
                        if flag.Type == "Colorpicker" then
                            flag:Set(unpackColor(flagVal))
                        else
                            flag:Set(flagVal)
                        end
                    end)
                end
            end
            SapphireLib:Notify({Title = "Configuration", Content = "Loaded saved configuration.", Duration = 4})
        end
    end)
end

function SapphireLib:SaveConfig()
    if not SapphireLib.SaveCfg or not isfolder or not writefile then return end
    local data = {}
    for name, flag in pairs(SapphireLib.Flags) do
        if flag.Save then
            if flag.Type == "Colorpicker" then
                data[name] = packColor(flag.Value)
            else
                data[name] = flag.Value
            end
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
    local ConfigFolder = config.ConfigFolder or WindowName
    local IntroEnabled = config.IntroEnabled ~= false
    local IntroText = config.IntroText or "Sapphire UI"
    local IntroIcon = config.IntroIcon or "rbxassetid://8834748103"
    local ShowIcon = config.ShowIcon or false
    local HidePremium = config.HidePremium or false

    SapphireLib.Folder = ConfigFolder
    SapphireLib.SaveCfg = config.SaveConfig or false

    if SapphireLib.SaveCfg and not isfolder(ConfigFolder) then
        makefolder(ConfigFolder)
    end

    local Main = Instance.new("Frame")
    Main.Name = "Main"
    Main.Parent = Gui
    Main.BackgroundColor3 = SapphireLib.Themes.Default.Main
    Main.Position = UDim2.new(0.5, -307, 0.5, -172)
    Main.Size = UDim2.new(0, 615, 0, 344)
    Main.ClipsDescendants = true
    Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 10)

    local MainShadow = Instance.new("ImageLabel", Main)
    MainShadow.BackgroundTransparency = 1
    MainShadow.Image = "rbxassetid://3523728077"
    MainShadow.AnchorPoint = Vector2.new(0.5,0.5)
    MainShadow.Position = UDim2.new(0.5,0,0.5,0)
    MainShadow.Size = UDim2.new(1,80,1,320)
    MainShadow.ImageColor3 = Color3.fromRGB(33,33,33)
    MainShadow.ImageTransparency = 0.7

    -- Top bar
    local TopBar = Instance.new("Frame", Main)
    TopBar.Name = "TopBar"
    TopBar.Size = UDim2.new(1,0,0,50)
    TopBar.BackgroundTransparency = 1

    local dragFrame = Instance.new("Frame", TopBar)
    dragFrame.Size = UDim2.new(1,0,0,50)
    dragFrame.BackgroundTransparency = 1

    local windowTitle = Instance.new("TextLabel", TopBar)
    windowTitle.Name = "Title"
    windowTitle.Size = UDim2.new(1,-90,2,0)
    windowTitle.Position = UDim2.new(0,25,0,-24)
    windowTitle.Font = Enum.Font.GothamBlack
    windowTitle.TextColor3 = SapphireLib.Themes.Default.Text
    windowTitle.TextSize = 20
    windowTitle.BackgroundTransparency = 1
    windowTitle.Text = WindowName

    if ShowIcon then
        windowTitle.Position = UDim2.new(0,50,0,-24)
        local icon = Instance.new("ImageLabel", TopBar)
        icon.Size = UDim2.new(0,20,0,20)
        icon.Position = UDim2.new(0,25,0,15)
        icon.BackgroundTransparency = 1
        icon.Image = getIcon(config.Icon) or config.Icon or "rbxassetid://8834748103"
    end

    local topBarLine = Instance.new("Frame", TopBar)
    topBarLine.Size = UDim2.new(1,0,0,1)
    topBarLine.Position = UDim2.new(0,0,1,-1)
    topBarLine.BackgroundColor3 = SapphireLib.Themes.Default.Stroke
    topBarLine.BorderSizePixel = 0

    -- Minimize/Close buttons
    local btnFrame = Instance.new("Frame", TopBar)
    btnFrame.BackgroundColor3 = SapphireLib.Themes.Default.Second
    btnFrame.BorderSizePixel = 0
    btnFrame.Size = UDim2.new(0,70,0,30)
    btnFrame.Position = UDim2.new(1,-90,0,10)
    Instance.new("UICorner", btnFrame).CornerRadius = UDim.new(0,7)
    Instance.new("UIStroke", btnFrame).Color = SapphireLib.Themes.Default.Stroke
    local btnDivider = Instance.new("Frame", btnFrame)
    btnDivider.Size = UDim2.new(0,1,1,0)
    btnDivider.Position = UDim2.new(0.5,0,0,0)
    btnDivider.BackgroundColor3 = SapphireLib.Themes.Default.Stroke

    local closeBtn = Instance.new("TextButton", btnFrame)
    closeBtn.Size = UDim2.new(0.5,0,1,0)
    closeBtn.BackgroundTransparency = 1
    closeBtn.Text = ""
    local closeIcon = Instance.new("ImageLabel", closeBtn)
    closeIcon.Size = UDim2.new(0,18,0,18)
    closeIcon.Position = UDim2.new(0,9,0,6)
    closeIcon.BackgroundTransparency = 1
    closeIcon.Image = "rbxassetid://7072725342"
    closeIcon.ImageColor3 = SapphireLib.Themes.Default.Text

    local minBtn = Instance.new("TextButton", btnFrame)
    minBtn.Size = UDim2.new(0.5,0,1,0)
    minBtn.Position = UDim2.new(0.5,0,0,0)
    minBtn.BackgroundTransparency = 1
    minBtn.Text = ""
    local minIcon = Instance.new("ImageLabel", minBtn)
    minIcon.Size = UDim2.new(0,18,0,18)
    minIcon.Position = UDim2.new(0,9,0,6)
    minIcon.BackgroundTransparency = 1
    minIcon.Image = "rbxassetid://7072719338"
    minIcon.ImageColor3 = SapphireLib.Themes.Default.Text

    -- Tab holder and side panel
    local SidePanel = Instance.new("Frame", Main)
    SidePanel.Name = "SidePanel"
    SidePanel.Size = UDim2.new(0,150,1,-50)
    SidePanel.Position = UDim2.new(0,0,0,50)
    SidePanel.BackgroundColor3 = SapphireLib.Themes.Default.Second
    Instance.new("UICorner", SidePanel).CornerRadius = UDim.new(0,10)
    local patch1 = Instance.new("Frame", SidePanel)
    patch1.BackgroundColor3 = SidePanel.BackgroundColor3
    patch1.BorderSizePixel = 0
    patch1.Size = UDim2.new(1,0,0,10)
    patch1.Position = UDim2.new(0,0,0,0)
    local patch2 = Instance.new("Frame", SidePanel)
    patch2.BackgroundColor3 = SidePanel.BackgroundColor3
    patch2.BorderSizePixel = 0
    patch2.Size = UDim2.new(0,10,1,0)
    patch2.Position = UDim2.new(1,-10,0,0)
    local sideStroke = Instance.new("Frame", SidePanel)
    sideStroke.Size = UDim2.new(0,1,1,0)
    sideStroke.Position = UDim2.new(1,-1,0,0)
    sideStroke.BackgroundColor3 = SapphireLib.Themes.Default.Stroke

    local TabList = Instance.new("ScrollingFrame", SidePanel)
    TabList.Name = "TabList"
    TabList.Size = UDim2.new(1,0,1,-50)
    TabList.BackgroundTransparency = 1
    TabList.ScrollBarThickness = 4
    TabList.ScrollBarImageColor3 = SapphireLib.Themes.Default.Divider
    TabList.CanvasSize = UDim2.new(0,0,0,0)
    Instance.new("UIListLayout", TabList).Padding = UDim.new(0,8)
    local tabListPadding = Instance.new("UIPadding", TabList)
    tabListPadding.PaddingTop = UDim.new(0,8)

    local userSection = Instance.new("Frame", SidePanel)
    userSection.Size = UDim2.new(1,0,0,50)
    userSection.Position = UDim2.new(0,0,1,-50)
    userSection.BackgroundTransparency = 1
    local userStroke = Instance.new("Frame", userSection)
    userStroke.Size = UDim2.new(1,0,0,1)
    userStroke.BackgroundColor3 = SapphireLib.Themes.Default.Stroke

    local avatarFrame = Instance.new("Frame", userSection)
    avatarFrame.AnchorPoint = Vector2.new(0,0.5)
    avatarFrame.Size = UDim2.new(0,32,0,32)
    avatarFrame.Position = UDim2.new(0,10,0.5,0)
    avatarFrame.BackgroundTransparency = 1
    local avatarImage = Instance.new("ImageLabel", avatarFrame)
    avatarImage.Size = UDim2.new(1,0,1,0)
    avatarImage.BackgroundTransparency = 1
    avatarImage.Image = "https://www.roblox.com/headshot-thumbnail/image?userId=".. LocalPlayer.UserId .."&width=420&height=420&format=png"
    Instance.new("UICorner", avatarFrame).CornerRadius = UDim.new(1,0)
    Instance.new("UIStroke", avatarFrame).Color = SapphireLib.Themes.Default.Stroke
    local avatarCover = Instance.new("ImageLabel", avatarFrame)
    avatarCover.Size = UDim2.new(1,0,1,0)
    avatarCover.BackgroundTransparency = 1
    avatarCover.Image = "rbxassetid://4031889928"
    avatarCover.ImageColor3 = SapphireLib.Themes.Default.Second

    local userName = Instance.new("TextLabel", userSection)
    userName.Size = UDim2.new(1,-60,0,13)
    userName.Position = HidePremium and UDim2.new(0,50,0,19) or UDim2.new(0,50,0,12)
    userName.Font = Enum.Font.GothamBold
    userName.TextColor3 = SapphireLib.Themes.Default.Text
    userName.TextSize = 13
    userName.BackgroundTransparency = 1
    userName.Text = LocalPlayer.DisplayName

    local userTag = Instance.new("TextLabel", userSection)
    userTag.Size = UDim2.new(1,-60,0,12)
    userTag.Position = UDim2.new(0,50,1,-25)
    userTag.Font = Enum.Font.GothamSemibold
    userTag.TextColor3 = SapphireLib.Themes.Default.TextDark
    userTag.TextSize = 12
    userTag.BackgroundTransparency = 1
    userTag.Text = ""
    if HidePremium then userTag.Visible = false end

    -- Elements container
    local ElementsContainer = Instance.new("ScrollingFrame", Main)
    ElementsContainer.Name = "ElementsContainer"
    ElementsContainer.Size = UDim2.new(1,-150,1,-50)
    ElementsContainer.Position = UDim2.new(0,150,0,50)
    ElementsContainer.BackgroundTransparency = 1
    ElementsContainer.ScrollBarThickness = 5
    ElementsContainer.ScrollBarImageColor3 = SapphireLib.Themes.Default.Divider
    ElementsContainer.CanvasSize = UDim2.new(0,0,0,0)
    Instance.new("UIListLayout", ElementsContainer).Padding = UDim.new(0,6)

    -- FIXED: UIPadding for ElementsContainer
    local elementsPadding = Instance.new("UIPadding", ElementsContainer)
    elementsPadding.PaddingTop = UDim.new(0, 15)
    elementsPadding.PaddingBottom = UDim.new(0, 10)
    elementsPadding.PaddingLeft = UDim.new(0, 10)
    elementsPadding.PaddingRight = UDim.new(0, 15)

    -- Dragging
    local dragging, dragInput, mousePos, framePos
    dragFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            mousePos = input.Position
            framePos = Main.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    dragFrame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)
    addConnection(UserInputService.InputChanged, function(input)
        if input == dragInput and dragging then
            local delta = input.Position - mousePos
            TweenService:Create(Main, TweenInfo.new(0.45, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                Position = UDim2.new(framePos.X.Scale, framePos.X.Offset + delta.X, framePos.Y.Scale, framePos.Y.Offset + delta.Y)
            }):Play()
        end
    end)

    -- Minimize button toggle
    local minimized = false
    minBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        if minimized then
            minIcon.Image = "rbxassetid://7072720870"
            Main.Size = UDim2.new(0, windowTitle.TextBounds.X + 140, 0, 50)
            Main.ClipsDescendants = true
            SidePanel.Visible = false
            topBarLine.Visible = false
        else
            minIcon.Image = "rbxassetid://7072719338"
            Main.Size = UDim2.new(0, 615, 0, 344)
            wait(0.1)
            Main.ClipsDescendants = false
            SidePanel.Visible = true
            topBarLine.Visible = true
        end
    end)

    -- Close button
    local hidden = false
    closeBtn.MouseButton1Click:Connect(function()
        Main.Visible = false
        hidden = true
        SapphireLib:Notify({Title = "Hidden", Content = "Press RightShift to toggle UI.", Duration = 5})
    end)
    addConnection(UserInputService.InputBegan, function(input)
        if input.KeyCode == Enum.KeyCode.RightShift and hidden then
            Main.Visible = true
            hidden = false
        end
    end)

    -- Tab system
    local firstTab = true
    local currentTab = nil

    local function selectTab(btn, container)
        if currentTab == container then return end
        currentTab = container
        for _, tabBtn in ipairs(TabList:GetChildren()) do
            if tabBtn:IsA("TextButton") then
                TweenService:Create(tabBtn.Ico, TweenInfo.new(0.25, Enum.EasingStyle.Quint), {ImageTransparency = 0.4}):Play()
                TweenService:Create(tabBtn.Title, TweenInfo.new(0.25, Enum.EasingStyle.Quint), {TextTransparency = 0.4}):Play()
                tabBtn.Title.Font = Enum.Font.GothamSemibold
            end
        end
        for _, elContainer in ipairs(Main:GetChildren()) do
            if elContainer.Name == "ElementsContainer" and elContainer ~= container then
                elContainer.Visible = false
            end
        end
        if container then container.Visible = true end
        if btn then
            TweenService:Create(btn.Ico, TweenInfo.new(0.25, Enum.EasingStyle.Quint), {ImageTransparency = 0}):Play()
            TweenService:Create(btn.Title, TweenInfo.new(0.25, Enum.EasingStyle.Quint), {TextTransparency = 0}):Play()
            btn.Title.Font = Enum.Font.GothamBlack
        end
    end

    -- Intro sequence
    if IntroEnabled then
        Main.Visible = false
        local logo = Instance.new("ImageLabel", Gui)
        logo.AnchorPoint = Vector2.new(0.5,0.5)
        logo.Position = UDim2.new(0.5,0,0.4,0)
        logo.Size = UDim2.new(0,28,0,28)
        logo.BackgroundTransparency = 1
        logo.Image = getIcon(IntroIcon) or IntroIcon
        logo.ImageTransparency = 1
        local introText = Instance.new("TextLabel", Gui)
        introText.AnchorPoint = Vector2.new(0.5,0.5)
        introText.Position = UDim2.new(0.5,19,0.5,0)
        introText.Size = UDim2.new(1,0,1,0)
        introText.BackgroundTransparency = 1
        introText.Font = Enum.Font.GothamBold
        introText.TextColor3 = Color3.fromRGB(255,255,255)
        introText.TextSize = 14
        introText.TextXAlignment = Enum.TextXAlignment.Center
        introText.TextTransparency = 1
        introText.Text = IntroText
        TweenService:Create(logo, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {ImageTransparency = 0, Position = UDim2.new(0.5,0,0.5,0)}):Play()
        wait(0.8)
        TweenService:Create(logo, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {Position = UDim2.new(0.5, -(introText.TextBounds.X/2), 0.5, 0)}):Play()
        wait(0.3)
        TweenService:Create(introText, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {TextTransparency = 0}):Play()
        wait(2)
        TweenService:Create(introText, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {TextTransparency = 1}):Play()
        Main.Visible = true
        logo:Destroy()
        introText:Destroy()
    end

    -- Window API
    local Window = {}
    function Window:CreateTab(name, iconID)
        local tabBtn = Instance.new("TextButton", TabList)
        tabBtn.Name = name
        tabBtn.Size = UDim2.new(1,0,0,30)
        tabBtn.BackgroundTransparency = 1
        tabBtn.Text = ""
        local tabIco = Instance.new("ImageLabel", tabBtn)
        tabIco.Name = "Ico"
        tabIco.AnchorPoint = Vector2.new(0,0.5)
        tabIco.Size = UDim2.new(0,18,0,18)
        tabIco.Position = UDim2.new(0,10,0.5,0)
        tabIco.BackgroundTransparency = 1
        tabIco.Image = getIcon(iconID) or iconID or ""
        tabIco.ImageTransparency = 0.4
        tabIco.ImageColor3 = SapphireLib.Themes.Default.Text
        local tabTitle = Instance.new("TextLabel", tabBtn)
        tabTitle.Name = "Title"
        tabTitle.Size = UDim2.new(1,-35,1,0)
        tabTitle.Position = UDim2.new(0,35,0,0)
        tabTitle.BackgroundTransparency = 1
        tabTitle.Font = Enum.Font.GothamSemibold
        tabTitle.TextColor3 = SapphireLib.Themes.Default.Text
        tabTitle.TextSize = 14
        tabTitle.TextTransparency = 0.4
        tabTitle.TextXAlignment = Enum.TextXAlignment.Left
        tabTitle.Text = name

        local tabContainer = Instance.new("ScrollingFrame", Main)
        tabContainer.Name = name .. "_container"
        tabContainer.Size = UDim2.new(1, -150, 1, -50)
        tabContainer.Position = UDim2.new(0, 150, 0, 50)
        tabContainer.BackgroundTransparency = 1
        tabContainer.ScrollBarThickness = 5
        tabContainer.ScrollBarImageColor3 = SapphireLib.Themes.Default.Divider
        tabContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
        tabContainer.Visible = false

        Instance.new("UIListLayout", tabContainer).Padding = UDim.new(0, 6)

        -- FIXED: UIPadding for tab container
        local tabPadding = Instance.new("UIPadding", tabContainer)
        tabPadding.PaddingTop = UDim.new(0, 15)
        tabPadding.PaddingBottom = UDim.new(0, 10)
        tabPadding.PaddingLeft = UDim.new(0, 10)
        tabPadding.PaddingRight = UDim.new(0, 15)

        tabBtn.MouseButton1Click:Connect(function()
            selectTab(tabBtn, tabContainer)
        end)

        if firstTab then
            firstTab = false
            selectTab(tabBtn, tabContainer)
        end

        -- Elements added to this tab
        local function addElementToTab(frame)
            frame.Parent = tabContainer
            tabContainer.CanvasSize = UDim2.new(0,0,0,tabContainer.UIListLayout.AbsoluteContentSize.Y + 30)
            return frame
        end

        local Tab = {}
        --- SECTION ---
        function Tab:CreateSection(SectionName)
            local sectionFrame = Instance.new("Frame", tabContainer)
            sectionFrame.Size = UDim2.new(1,0,0,30)
            sectionFrame.BackgroundTransparency = 1
            local sectionTitle = Instance.new("TextLabel", sectionFrame)
            sectionTitle.Size = UDim2.new(1,-12,0,16)
            sectionTitle.Position = UDim2.new(0,0,0,3)
            sectionTitle.BackgroundTransparency = 1
            sectionTitle.Font = Enum.Font.GothamSemibold
            sectionTitle.TextColor3 = SapphireLib.Themes.Default.TextDark
            sectionTitle.TextSize = 14
            sectionTitle.TextXAlignment = Enum.TextXAlignment.Left
            sectionTitle.Text = SectionName
            local holder = Instance.new("Frame", sectionFrame)
            holder.Name = "Holder"
            holder.AnchorPoint = Vector2.new(0,0)
            holder.Size = UDim2.new(1,0,1,-24)
            holder.Position = UDim2.new(0,0,0,23)
            holder.BackgroundTransparency = 1
            Instance.new("UIListLayout", holder).Padding = UDim.new(0,6)
            local function updateSize()
                sectionFrame.Size = UDim2.new(1,0,0, holder.UIListLayout.AbsoluteContentSize.Y + 31)
                holder.Size = UDim2.new(1,0,0, holder.UIListLayout.AbsoluteContentSize.Y)
            end
            local Section = {}
            for _, methodName in ipairs({"CreateButton","CreateToggle","CreateSlider","CreateDropdown","CreateColorPicker","CreateKeybind","CreateTextbox","CreateLabel","CreateParagraph","CreateDivider"}) do
                Section[methodName] = function(sectionSelf, ...)
                    local elem = Tab[methodName](...)
                    elem.frame.Parent = holder
                    tabContainer:WaitForChild("UIListLayout")
                    updateSize()
                    return elem
                end
            end
            return Section
        end

        -- Common base for elements
        local function elementBase(name, configText)
            local frame = Instance.new("Frame")
            frame.Name = name
            frame.Size = UDim2.new(1,0,0,38)
            frame.BackgroundColor3 = SapphireLib.Themes.Default.Second
            frame.BorderSizePixel = 0
            Instance.new("UICorner", frame).CornerRadius = UDim.new(0,5)
            Instance.new("UIStroke", frame).Color = SapphireLib.Themes.Default.Stroke
            local fText = Instance.new("TextLabel", frame)
            fText.Size = UDim2.new(1,-12,1,0)
            fText.Position = UDim2.new(0,12,0,0)
            fText.BackgroundTransparency = 1
            fText.Font = Enum.Font.GothamBold
            fText.TextColor3 = SapphireLib.Themes.Default.Text
            fText.TextSize = 15
            fText.TextXAlignment = Enum.TextXAlignment.Left
            fText.Text = configText
            return frame, fText
        end

        --- BUTTON ---
        function Tab:CreateButton(config)
            local frame, fText = elementBase("Button", config.Name)
            local click = Instance.new("TextButton", frame)
            click.Size = UDim2.new(1,0,1,0)
            click.BackgroundTransparency = 1
            click.Text = ""
            local btn = {frame = frame}
            click.MouseEnter:Connect(function()
                TweenService:Create(frame, TweenInfo.new(0.25, Enum.EasingStyle.Quint), {BackgroundColor3 = SapphireLib.Themes.Default.Second * 1.1}):Play()
            end)
            click.MouseLeave:Connect(function()
                TweenService:Create(frame, TweenInfo.new(0.25, Enum.EasingStyle.Quint), {BackgroundColor3 = SapphireLib.Themes.Default.Second}):Play()
            end)
            click.MouseButton1Click:Connect(function()
                TweenService:Create(frame, TweenInfo.new(0.15, Enum.EasingStyle.Quint), {BackgroundColor3 = SapphireLib.Themes.Default.Second * 1.2}):Play()
                wait(0.15)
                TweenService:Create(frame, TweenInfo.new(0.25, Enum.EasingStyle.Quint), {BackgroundColor3 = SapphireLib.Themes.Default.Second}):Play()
                pcall(config.Callback)
            end)
            function btn:Set(text) fText.Text = text end
            return btn
        end

        --- TOGGLE ---
        function Tab:CreateToggle(config)
            local frame, fText = elementBase("Toggle", config.Name)
            local value = config.Default or false
            local toggleBox = Instance.new("Frame", frame)
            toggleBox.Size = UDim2.new(0,24,0,24)
            toggleBox.Position = UDim2.new(1,-24,0.5,0)
            toggleBox.AnchorPoint = Vector2.new(0.5,0.5)
            toggleBox.BorderSizePixel = 0
            Instance.new("UICorner", toggleBox).CornerRadius = UDim.new(0,4)
            local toggleStroke = Instance.new("UIStroke", toggleBox)
            toggleStroke.Color = SapphireLib.Themes.Default.Stroke
            local toggleIco = Instance.new("ImageLabel", toggleBox)
            toggleIco.Size = UDim2.new(0,20,0,20)
            toggleIco.AnchorPoint = Vector2.new(0.5,0.5)
            toggleIco.Position = UDim2.new(0.5,0,0.5,0)
            toggleIco.BackgroundTransparency = 1
            toggleIco.Image = "rbxassetid://3944680095"
            toggleIco.ImageColor3 = Color3.fromRGB(255,255,255)
            local click = Instance.new("TextButton", frame)
            click.Size = UDim2.new(1,0,1,0)
            click.BackgroundTransparency = 1
            click.Text = ""
            local toggle = {frame = frame, Value = value, Save = config.Save ~= false, Type = "Toggle"}
            local function updateVisual()
                if toggle.Value then
                    toggleBox.BackgroundColor3 = config.Color or Color3.fromRGB(9,99,195)
                    toggleStroke.Color = config.Color or Color3.fromRGB(9,99,195)
                    toggleIco.ImageTransparency = 0
                    toggleIco.Size = UDim2.new(0,20,0,20)
                else
                    toggleBox.BackgroundColor3 = SapphireLib.Themes.Default.Divider
                    toggleStroke.Color = SapphireLib.Themes.Default.Stroke
                    toggleIco.ImageTransparency = 1
                    toggleIco.Size = UDim2.new(0,8,0,8)
                end
            end
            updateVisual()
            click.MouseEnter:Connect(function()
                TweenService:Create(frame, TweenInfo.new(0.25, Enum.EasingStyle.Quint), {BackgroundColor3 = SapphireLib.Themes.Default.Second * 1.1}):Play()
            end)
            click.MouseLeave:Connect(function()
                TweenService:Create(frame, TweenInfo.new(0.25, Enum.EasingStyle.Quint), {BackgroundColor3 = SapphireLib.Themes.Default.Second}):Play()
            end)
            click.MouseButton1Click:Connect(function()
                toggle:Set(not toggle.Value)
                SapphireLib:SaveConfig()
            end)
            function toggle:Set(val)
                self.Value = val
                TweenService:Create(toggleBox, TweenInfo.new(0.3, Enum.EasingStyle.Quint), {BackgroundColor3 = val and (config.Color or Color3.fromRGB(9,99,195)) or SapphireLib.Themes.Default.Divider}):Play()
                TweenService:Create(toggleStroke, TweenInfo.new(0.3, Enum.EasingStyle.Quint), {Color = val and (config.Color or Color3.fromRGB(9,99,195)) or SapphireLib.Themes.Default.Stroke}):Play()
                TweenService:Create(toggleIco, TweenInfo.new(0.3, Enum.EasingStyle.Quint), {ImageTransparency = val and 0 or 1, Size = val and UDim2.new(0,20,0,20) or UDim2.new(0,8,0,8)}):Play()
                pcall(config.Callback, self.Value)
            end
            if config.Flag then SapphireLib.Flags[config.Flag] = toggle end
            return toggle
        end

        --- SLIDER ---
        function Tab:CreateSlider(config)
            local frame = Instance.new("Frame")
            frame.Size = UDim2.new(1,0,0,65)
            frame.BackgroundColor3 = SapphireLib.Themes.Default.Second
            frame.BorderSizePixel = 0
            Instance.new("UICorner", frame).CornerRadius = UDim.new(0,5)
            Instance.new("UIStroke", frame).Color = SapphireLib.Themes.Default.Stroke
            local fText = Instance.new("TextLabel", frame)
            fText.Size = UDim2.new(1,-12,0,14)
            fText.Position = UDim2.new(0,12,0,10)
            fText.BackgroundTransparency = 1
            fText.Font = Enum.Font.GothamBold
            fText.TextColor3 = SapphireLib.Themes.Default.Text
            fText.TextSize = 15
            fText.TextXAlignment = Enum.TextXAlignment.Left
            fText.Text = config.Name

            local sliderBar = Instance.new("Frame", frame)
            sliderBar.Size = UDim2.new(1,-24,0,26)
            sliderBar.Position = UDim2.new(0,12,0,30)
            sliderBar.BackgroundTransparency = 0.9
            sliderBar.BackgroundColor3 = config.Color or Color3.fromRGB(9,149,98)
            sliderBar.BorderSizePixel = 0
            Instance.new("UICorner", sliderBar).CornerRadius = UDim.new(0,5)
            Instance.new("UIStroke", sliderBar).Color = config.Color or Color3.fromRGB(9,149,98)

            local sliderProgress = Instance.new("Frame", sliderBar)
            sliderProgress.Size = UDim2.new(0,0,1,0)
            sliderProgress.BackgroundColor3 = config.Color or Color3.fromRGB(9,149,98)
            sliderProgress.BackgroundTransparency = 0.3
            sliderProgress.BorderSizePixel = 0
            Instance.new("UICorner", sliderProgress).CornerRadius = UDim.new(0,5)

            local sliderValueLabel = Instance.new("TextLabel", sliderBar)
            sliderValueLabel.Size = UDim2.new(1,-12,1,0)
            sliderValueLabel.Position = UDim2.new(0,12,0,0)
            sliderValueLabel.BackgroundTransparency = 1
            sliderValueLabel.Font = Enum.Font.GothamBold
            sliderValueLabel.TextColor3 = SapphireLib.Themes.Default.Text
            sliderValueLabel.TextSize = 13
            sliderValueLabel.TextXAlignment = Enum.TextXAlignment.Left
            sliderValueLabel.TextTransparency = 0.8

            local dragging = false
            local slider = {frame = frame, Value = config.Default or 50, Save = config.Save ~= false, Type = "Slider"}
            local function updateSlider(val)
                val = math.clamp(round(val, config.Increment or 1), config.Min, config.Max)
                local frac = (val - config.Min) / (config.Max - config.Min)
                TweenService:Create(sliderProgress, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {Size = UDim2.fromScale(frac, 1)}):Play()
                if config.Suffix then
                    sliderValueLabel.Text = tostring(val) .. " " .. config.Suffix
                else
                    sliderValueLabel.Text = tostring(val)
                end
                slider.Value = val
            end
            slider:Set(config.Default or 50)

            sliderBar.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = true
                end
            end)
            sliderBar.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = false
                end
            end)
            addConnection(UserInputService.InputChanged, function(input)
                if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                    local frac = math.clamp((input.Position.X - sliderBar.AbsolutePosition.X) / sliderBar.AbsoluteSize.X, 0, 1)
                    slider:Set(config.Min + frac * (config.Max - config.Min))
                    pcall(config.Callback, slider.Value)
                    SapphireLib:SaveConfig()
                end
            end)
            function slider:Set(val)
                updateSlider(val)
                pcall(config.Callback, self.Value)
            end
            if config.Flag then SapphireLib.Flags[config.Flag] = slider end
            return slider
        end

        --- DROPDOWN ---
        function Tab:CreateDropdown(config)
            local frame, fText = elementBase("Dropdown", config.Name)
            local value = config.Default or ""
            local toggled = false
            local options = config.Options or {}

            local selectedLabel = Instance.new("TextLabel", frame)
            selectedLabel.Size = UDim2.new(1,-40,1,0)
            selectedLabel.BackgroundTransparency = 1
            selectedLabel.Font = Enum.Font.Gotham
            selectedLabel.TextColor3 = SapphireLib.Themes.Default.TextDark
            selectedLabel.TextSize = 13
            selectedLabel.TextXAlignment = Enum.TextXAlignment.Right
            selectedLabel.Text = value

            local dropIcon = Instance.new("ImageLabel", frame)
            dropIcon.Size = UDim2.new(0,20,0,20)
            dropIcon.Position = UDim2.new(1,-30,0.5,0)
            dropIcon.AnchorPoint = Vector2.new(0,0.5)
            dropIcon.BackgroundTransparency = 1
            dropIcon.Image = "rbxassetid://7072706796"
            dropIcon.ImageColor3 = SapphireLib.Themes.Default.TextDark

            local dropContainer = Instance.new("ScrollingFrame", frame)
            dropContainer.Position = UDim2.new(0,0,0,38)
            dropContainer.Size = UDim2.new(1,0,1,-38)
            dropContainer.BackgroundTransparency = 1
            dropContainer.CanvasSize = UDim2.new(0,0,0,0)
            dropContainer.ScrollBarThickness = 4
            dropContainer.ScrollBarImageColor3 = SapphireLib.Themes.Default.Divider
            dropContainer.ClipsDescendants = true
            Instance.new("UIListLayout", dropContainer)

            local click = Instance.new("TextButton", frame)
            click.Size = UDim2.new(1,0,1,0)
            click.BackgroundTransparency = 1
            click.Text = ""

            local dropdown = {frame = frame, Value = value, Options = options, Buttons = {}, Save = config.Save ~= false, Type = "Dropdown"}

            local function refreshOptions(deleteOld)
                if deleteOld then
                    for _, btn in pairs(dropdown.Buttons) do btn:Destroy() end
                    table.clear(dropdown.Buttons)
                    table.clear(dropdown.Options)
                end
                for _, opt in ipairs(options) do
                    local optBtn = Instance.new("TextButton", dropContainer)
                    optBtn.Size = UDim2.new(1,0,0,28)
                    optBtn.BackgroundTransparency = 1
                    optBtn.Text = ""
                    local optLabel = Instance.new("TextLabel", optBtn)
                    optLabel.Size = UDim2.new(1,-8,1,0)
                    optLabel.Position = UDim2.new(0,8,0,0)
                    optLabel.BackgroundTransparency = 1
                    optLabel.Font = Enum.Font.Gotham
                    optLabel.TextColor3 = SapphireLib.Themes.Default.Text
                    optLabel.TextSize = 13
                    optLabel.TextXAlignment = Enum.TextXAlignment.Left
                    optLabel.Text = opt
                    optBtn.MouseButton1Click:Connect(function()
                        dropdown:Set(opt)
                        SapphireLib:SaveConfig()
                    end)
                    dropdown.Buttons[opt] = optBtn
                end
                dropContainer.CanvasSize = UDim2.new(0,0,0,dropContainer.UIListLayout.AbsoluteContentSize.Y)
            end

            click.MouseButton1Click:Connect(function()
                toggled = not toggled
                TweenService:Create(dropIcon, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {Rotation = toggled and 180 or 0}):Play()
                local maxHeight = #options > 5 and (5*28) or dropContainer.UIListLayout.AbsoluteContentSize.Y
                TweenService:Create(frame, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {Size = toggled and UDim2.new(1,0,0, maxHeight+38) or UDim2.new(1,0,0,38)}):Play()
            end)

            function dropdown:Set(val)
                self.Value = val
                selectedLabel.Text = val
                for opt, btn in pairs(self.Buttons) do
                    TweenService:Create(btn, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {BackgroundTransparency = 1}):Play()
                    TweenService:Create(btn.optLabel, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {TextTransparency = 0.4}):Play()
                end
                if self.Buttons[val] then
                    TweenService:Create(self.Buttons[val], TweenInfo.new(0.15, Enum.EasingStyle.Quad), {BackgroundTransparency = 0}):Play()
                    TweenService:Create(self.Buttons[val].optLabel, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {TextTransparency = 0}):Play()
                end
                pcall(config.Callback, self.Value)
            end

            function dropdown:Refresh(newOptions)
                options = newOptions
                refreshOptions(true)
            end

            refreshOptions()
            dropdown:Set(value)
            if config.Flag then SapphireLib.Flags[config.Flag] = dropdown end
            return dropdown
        end

        --- COLORPICKER ---
        function Tab:CreateColorPicker(config)
            local frame, fText = elementBase("ColorPicker", config.Name)
            local value = config.Default or Color3.fromRGB(255,255,255)
            local toggled = false

            local pickerContainer = Instance.new("Frame", frame)
            pickerContainer.Position = UDim2.new(0,0,0,38)
            pickerContainer.Size = UDim2.new(1,0,1,-38)
            pickerContainer.BackgroundTransparency = 1
            pickerContainer.ClipsDescendants = true

            local colorBox = Instance.new("Frame", frame) -- preview
            colorBox.Size = UDim2.new(0,24,0,24)
            colorBox.Position = UDim2.new(1,-12,0.5,0)
            colorBox.AnchorPoint = Vector2.new(1,0.5)
            colorBox.BackgroundColor3 = value
            colorBox.BorderSizePixel = 0
            Instance.new("UICorner", colorBox).CornerRadius = UDim.new(0,4)
            Instance.new("UIStroke", colorBox).Color = SapphireLib.Themes.Default.Stroke

            local colorCanvas = Instance.new("ImageLabel", pickerContainer)
            colorCanvas.Size = UDim2.new(1,-25,1,0)
            colorCanvas.BackgroundTransparency = 1
            colorCanvas.Image = "rbxassetid://4155801252"
            Instance.new("UICorner", colorCanvas).CornerRadius = UDim.new(0,5)
            local colorSelect = Instance.new("ImageLabel", colorCanvas)
            colorSelect.Size = UDim2.new(0,18,0,18)
            colorSelect.AnchorPoint = Vector2.new(0.5,0.5)
            colorSelect.BackgroundTransparency = 1
            colorSelect.Image = "http://www.roblox.com/asset/?id=4805639000"

            local hueFrame = Instance.new("Frame", pickerContainer)
            hueFrame.Size = UDim2.new(0,20,1,0)
            hueFrame.Position = UDim2.new(1,-20,0,0)
            hueFrame.BorderSizePixel = 0
            Instance.new("UICorner", hueFrame).CornerRadius = UDim.new(0,5)
            local hueGradient = Instance.new("UIGradient", hueFrame)
            hueGradient.Rotation = 270
            hueGradient.Color = ColorSequence.new{
                ColorSequenceKeypoint.new(0, Color3.fromRGB(255,0,4)),
                ColorSequenceKeypoint.new(0.2, Color3.fromRGB(234,255,0)),
                ColorSequenceKeypoint.new(0.4, Color3.fromRGB(21,255,0)),
                ColorSequenceKeypoint.new(0.6, Color3.fromRGB(0,255,255)),
                ColorSequenceKeypoint.new(0.8, Color3.fromRGB(0,17,255)),
                ColorSequenceKeypoint.new(0.9, Color3.fromRGB(255,0,251)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(255,0,4))
            }
            local hueSelect = Instance.new("ImageLabel", hueFrame)
            hueSelect.Size = UDim2.new(0,18,0,18)
            hueSelect.AnchorPoint = Vector2.new(0.5,0.5)
            hueSelect.BackgroundTransparency = 1
            hueSelect.Image = "http://www.roblox.com/asset/?id=4805639000"

            local click = Instance.new("TextButton", frame)
            click.Size = UDim2.new(1,0,1,0)
            click.BackgroundTransparency = 1
            click.Text = ""

            local colorpicker = {frame = frame, Value = value, Save = config.Save ~= false, Type = "Colorpicker"}

            local function updateColorDisplay()
                colorBox.BackgroundColor3 = colorpicker.Value
                colorCanvas.BackgroundColor3 = Color3.fromHSV(colorpicker.H or 1, 1, 1)
                local x = colorpicker.S * colorCanvas.AbsoluteSize.X
                local y = (1 - colorpicker.V) * colorCanvas.AbsoluteSize.Y
                colorSelect.Position = UDim2.new(0, x - colorSelect.AbsoluteSize.X/2, 0, y - colorSelect.AbsoluteSize.Y/2)
                local hy = (1 - colorpicker.H) * hueFrame.AbsoluteSize.Y
                hueSelect.Position = UDim2.new(0.5,0,0, hy - hueSelect.AbsoluteSize.Y/2)
                pcall(config.Callback, colorpicker.Value)
            end

            local function setFromHSV()
                colorpicker.Value = Color3.fromHSV(colorpicker.H, colorpicker.S, colorpicker.V)
                updateColorDisplay()
                SapphireLib:SaveConfig()
            end

            colorpicker.H, colorpicker.S, colorpicker.V = Color3.toHSV(value)
            updateColorDisplay()

            click.MouseButton1Click:Connect(function()
                toggled = not toggled
                TweenService:Create(frame, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {Size = toggled and UDim2.new(1,0,0,148) or UDim2.new(1,0,0,38)}):Play()
                colorCanvas.Visible = toggled
                hueFrame.Visible = toggled
            end)

            local colorInput, hueInput
            colorCanvas.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    if colorInput then colorInput:Disconnect() end
                    colorInput = addConnection(RunService.RenderStepped, function()
                        local mx = math.clamp(Mouse.X - colorCanvas.AbsolutePosition.X, 0, colorCanvas.AbsoluteSize.X)
                        local my = math.clamp(Mouse.Y - colorCanvas.AbsolutePosition.Y, 0, colorCanvas.AbsoluteSize.Y)
                        colorpicker.S = mx / colorCanvas.AbsoluteSize.X
                        colorpicker.V = 1 - (my / colorCanvas.AbsoluteSize.Y)
                        setFromHSV()
                    end)
                end
            end)
            colorCanvas.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 and colorInput then
                    colorInput:Disconnect()
                end
            end)

            hueFrame.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    if hueInput then hueInput:Disconnect() end
                    hueInput = addConnection(RunService.RenderStepped, function()
                        local my = math.clamp(Mouse.Y - hueFrame.AbsolutePosition.Y, 0, hueFrame.AbsoluteSize.Y)
                        colorpicker.H = 1 - (my / hueFrame.AbsoluteSize.Y)
                        setFromHSV()
                    end)
                end
            end)
            hueFrame.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 and hueInput then
                    hueInput:Disconnect()
                end
            end)

            function colorpicker:Set(newColor)
                self.Value = newColor
                self.H, self.S, self.V = Color3.toHSV(newColor)
                updateColorDisplay()
                pcall(config.Callback, self.Value)
            end

            if config.Flag then SapphireLib.Flags[config.Flag] = colorpicker end
            return colorpicker
        end

        --- KEYBIND ---
        function Tab:CreateKeybind(config)
            local frame, fText = elementBase("Keybind", config.Name)
            local currentKey = config.Default or Enum.KeyCode.Unknown
            local binding = false

            local keyLabel = Instance.new("TextLabel", frame)
            keyLabel.Size = UDim2.new(0,24,0,24)
            keyLabel.Position = UDim2.new(1,-12,0.5,0)
            keyLabel.AnchorPoint = Vector2.new(1,0.5)
            keyLabel.BackgroundColor3 = SapphireLib.Themes.Default.Main
            keyLabel.BorderSizePixel = 0
            Instance.new("UICorner", keyLabel).CornerRadius = UDim.new(0,4)
            Instance.new("UIStroke", keyLabel).Color = SapphireLib.Themes.Default.Stroke
            keyLabel.Font = Enum.Font.GothamBold
            keyLabel.TextColor3 = SapphireLib.Themes.Default.Text
            keyLabel.TextSize = 14
            keyLabel.TextXAlignment = Enum.TextXAlignment.Center
            keyLabel.Text = currentKey.Name ~= "Unknown" and currentKey.Name or "..."

            local click = Instance.new("TextButton", frame)
            click.Size = UDim2.new(1,0,1,0)
            click.BackgroundTransparency = 1
            click.Text = ""

            local keybind = {frame = frame, Value = currentKey, Save = config.Save ~= false, Type = "Bind"}
            click.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    if not binding then
                        binding = true
                        keyLabel.Text = "..."
                    end
                end
            end)
            addConnection(UserInputService.InputBegan, function(input)
                if UserInputService:GetFocusedTextBox() then return end
                if (input.KeyCode == currentKey or input.UserInputType == currentKey) and not binding then
                    if config.Hold then
                        local holding = true
                        config.Callback(true)
                        local holdEnded
                        holdEnded = UserInputService.InputEnded:Connect(function(inp)
                            if inp.KeyCode == currentKey or inp.UserInputType == currentKey then
                                config.Callback(false)
                                holdEnded:Disconnect()
                            end
                        end)
                    else
                        config.Callback()
                    end
                elseif binding then
                    local key = nil
                    local blacklist = {Enum.KeyCode.Unknown, Enum.KeyCode.W,Enum.KeyCode.A,Enum.KeyCode.S,Enum.KeyCode.D,Enum.KeyCode.Up,Enum.KeyCode.Left,Enum.KeyCode.Down,Enum.KeyCode.Right,Enum.KeyCode.Slash,Enum.KeyCode.Tab,Enum.KeyCode.Backspace,Enum.KeyCode.Escape}
                    local function isBlacklisted(k) for _, v in ipairs(blacklist) do if v == k then return true end end return false end
                    pcall(function()
                        if not isBlacklisted(input.KeyCode) then key = input.KeyCode end
                    end)
                    pcall(function()
                        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.MouseButton2 or input.UserInputType == Enum.UserInputType.MouseButton3 then
                            if not key then key = input.UserInputType end
                        end
                    end)
                    key = key or currentKey
                    keybind:Set(key)
                    SapphireLib:SaveConfig()
                end
            end)
            function keybind:Set(key)
                binding = false
                self.Value = key
                currentKey = key
                keyLabel.Text = key.Name ~= "Unknown" and key.Name or "..."
            end
            if config.Flag then SapphireLib.Flags[config.Flag] = keybind end
            return keybind
        end

        --- TEXTBOX ---
        function Tab:CreateTextbox(config)
            local frame, fText = elementBase("Textbox", config.Name)
            local textBox = Instance.new("TextBox", frame)
            textBox.Size = UDim2.new(0,24,0,24)
            textBox.Position = UDim2.new(1,-12,0.5,0)
            textBox.AnchorPoint = Vector2.new(1,0.5)
            textBox.BackgroundColor3 = SapphireLib.Themes.Default.Main
            textBox.BorderSizePixel = 0
            Instance.new("UICorner", textBox).CornerRadius = UDim.new(0,4)
            Instance.new("UIStroke", textBox).Color = SapphireLib.Themes.Default.Stroke
            textBox.Font = Enum.Font.GothamSemibold
            textBox.TextColor3 = SapphireLib.Themes.Default.Text
            textBox.TextSize = 14
            textBox.TextXAlignment = Enum.TextXAlignment.Center
            textBox.ClearTextOnFocus = false
            textBox.Text = config.Default or ""
            textBox.PlaceholderText = config.Placeholder or "Input"
            textBox.PlaceholderColor3 = Color3.fromRGB(210,210,210)
            textBox:GetPropertyChangedSignal("Text"):Connect(function()
                TweenService:Create(textBox, TweenInfo.new(0.45, Enum.EasingStyle.Quint), {Size = UDim2.new(0, textBox.TextBounds.X + 16, 0, 24)}):Play()
            end)
            textBox.FocusLost:Connect(function()
                pcall(config.Callback, textBox.Text)
                if config.TextDisappear then textBox.Text = "" end
            end)
            local click = Instance.new("TextButton", frame)
            click.Size = UDim2.new(1,0,1,0)
            click.BackgroundTransparency = 1
            click.Text = ""
            click.MouseButton1Click:Connect(function()
                textBox:CaptureFocus()
            end)
            local textboxObj = {frame = frame}
            function textboxObj:Set(txt)
                textBox.Text = txt
                pcall(config.Callback, txt)
            end
            return textboxObj
        end

        --- LABEL ---
        function Tab:CreateLabel(text, iconID, colorOverride)
            local frame = Instance.new("Frame")
            frame.Size = UDim2.new(1,0,0,30)
            frame.BackgroundColor3 = colorOverride or SapphireLib.Themes.Default.Second
            frame.BackgroundTransparency = 0.7
            frame.BorderSizePixel = 0
            Instance.new("UICorner", frame).CornerRadius = UDim.new(0,5)
            Instance.new("UIStroke", frame).Color = colorOverride and colorOverride or SapphireLib.Themes.Default.Stroke
            local labelText = Instance.new("TextLabel", frame)
            labelText.Size = UDim2.new(1,-12,1,0)
            labelText.Position = UDim2.new(0,12,0,0)
            labelText.BackgroundTransparency = 1
            labelText.Font = Enum.Font.GothamBold
            labelText.TextColor3 = SapphireLib.Themes.Default.Text
            labelText.TextSize = 15
            labelText.TextXAlignment = Enum.TextXAlignment.Left
            labelText.Text = text
            if iconID then
                labelText.Position = UDim2.new(0,45,0,0)
                labelText.Size = UDim2.new(1,-100,0,14)
                local icon = Instance.new("ImageLabel", frame)
                icon.Size = UDim2.new(0,20,0,20)
                icon.Position = UDim2.new(0,12,0.5,0)
                icon.AnchorPoint = Vector2.new(0,0.5)
                icon.BackgroundTransparency = 1
                icon.Image = getIcon(iconID) or iconID
                icon.ImageColor3 = SapphireLib.Themes.Default.Text
                icon.ImageTransparency = 0.2
            end
            local label = {frame = frame}
            function label:Set(newText) labelText.Text = newText end
            return label
        end

        --- PARAGRAPH ---
        function Tab:CreateParagraph(title, content)
            local frame = Instance.new("Frame")
            frame.Size = UDim2.new(1,0,0,30)
            frame.BackgroundColor3 = SapphireLib.Themes.Default.Second
            frame.BackgroundTransparency = 0.7
            frame.BorderSizePixel = 0
            Instance.new("UICorner", frame).CornerRadius = UDim.new(0,5)
            Instance.new("UIStroke", frame).Color = SapphireLib.Themes.Default.Stroke
            local titleLabel = Instance.new("TextLabel", frame)
            titleLabel.Size = UDim2.new(1,-12,0,14)
            titleLabel.Position = UDim2.new(0,12,0,10)
            titleLabel.BackgroundTransparency = 1
            titleLabel.Font = Enum.Font.GothamBold
            titleLabel.TextColor3 = SapphireLib.Themes.Default.Text
            titleLabel.TextSize = 15
            titleLabel.TextXAlignment = Enum.TextXAlignment.Left
            titleLabel.Text = title
            local contentLabel = Instance.new("TextLabel", frame)
            contentLabel.Size = UDim2.new(1,-24,0,0)
            contentLabel.Position = UDim2.new(0,12,0,26)
            contentLabel.BackgroundTransparency = 1
            contentLabel.Font = Enum.Font.GothamSemibold
            contentLabel.TextColor3 = SapphireLib.Themes.Default.TextDark
            contentLabel.TextSize = 13
            contentLabel.TextXAlignment = Enum.TextXAlignment.Left
            contentLabel.TextWrapped = true
            contentLabel.Text = content
            contentLabel:GetPropertyChangedSignal("Text"):Connect(function()
                contentLabel.Size = UDim2.new(1,-24,0, contentLabel.TextBounds.Y)
                frame.Size = UDim2.new(1,0,0, contentLabel.TextBounds.Y + 35)
            end)
            local para = {frame = frame}
            function para:Set(newContent) contentLabel.Text = newContent end
            return para
        end

        --- DIVIDER ---
        function Tab:CreateDivider()
            local frame = Instance.new("Frame")
            frame.Size = UDim2.new(1,0,0,1)
            frame.BackgroundColor3 = SapphireLib.Themes.Default.Stroke
            frame.BackgroundTransparency = 0.85
            frame.BorderSizePixel = 0
            local div = {frame = frame}
            function div:Set(visible) frame.Visible = visible end
            return div
        end

        return Tab
    end

    function Window:SetTheme(theme)
        if SapphireLib.Themes[theme] then
            SapphireLib.SelectedTheme = theme
            local t = SapphireLib.Themes[theme]
            Main.BackgroundColor3 = t.Main
            SidePanel.BackgroundColor3 = t.Second
            topBarLine.BackgroundColor3 = t.Stroke
            windowTitle.TextColor3 = t.Text
            -- full theme refresh is possible but beyond scope
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