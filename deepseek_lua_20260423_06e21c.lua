--[[
    ███████╗ █████╗ ██████╗ ██████╗ ██╗  ██╗██╗██████╗ ███████╗
    ██╔════╝██╔══██╗██╔══██╗██╔══██╗██║  ██║██║██╔══██╗██╔════╝
    ███████╗███████║██████╔╝██████╔╝███████║██║██████╔╝█████╗  
         ██║██╔══██║██╔═══╝ ██╔═══╝ ██╔══██║██║██╔══██╗██╔══╝  
    ███████║██║  ██║██║     ██║     ██║  ██║██║██║  ██║███████╗
    ╚══════╝╚═╝  ╚═╝╚═╝     ╚═╝     ╚═╝  ╚═╝╚═╝╚═╝  ╚═╝╚══════╝
     
    Sapphire UI Library v3 – Robust & Mobile-Ready
    by Sapphire Team (2026)
    
    Features:
     ✔ Full mobile scaling & touch support
     ✔ 10 built‑in themes
     ✔ All standard elements (Button, Toggle, Slider, Dropdown,
       ColorPicker, Keybind, Textbox, Label, Paragraph, Divider)
     ✔ Flag‑based config saving
     ✔ Smart anti‑crash (nil config, corrupted saves)
     ✔ Notifications, intro animation
     ✔ Dragging with touch
     ✔ Mobile‑only show/hide prompt
     
    Usage:
     local lib = loadstring(game:HttpGet('RAW_URL'))()
     local win = lib:CreateWindow({Name = "Hub", SaveConfig = true})
     local tab = win:CreateTab("Main")
     local sec = tab:CreateSection("Combat")
     sec:CreateToggle({Name = "Enabled", Flag = "myFlag", Save = true, Callback = function(v) end})
     lib:Notify({Title = "Ready", Content = "Script loaded"})
     lib:Init()
--]]

--========== SERVICES ==========
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

--========== ICONS (optional) ==========
local Icons = {}
pcall(function()
    Icons = HttpService:JSONDecode(game:HttpGetAsync(
        "https://raw.githubusercontent.com/evoincorp/lucideblox/master/src/modules/util/icons.json"
    )).icons
end)
local function getIcon(name)
    if Icons[name] then return Icons[name] end
    return nil
end

--========== HELPER FUNCTIONS ==========
local function packColor(c)
    return { R = c.R * 255, G = c.G * 255, B = c.B * 255 }
end
local function unpackColor(t)
    return Color3.fromRGB(t.R, t.G, t.B)
end
local function round(num, inc)
    local r = math.floor(num/inc + math.sign(num)*0.5) * inc
    if r < 0 then r = r + inc end
    return r
end

-- Mobile detection
local IS_MOBILE = UserInputService.TouchEnabled
local MOBILE_SCALE = IS_MOBILE and 1.3 or 1
local BASE_ELEMENT_HEIGHT = 38 * MOBILE_SCALE
local BASE_FONT_SIZE = 15 * MOBILE_SCALE
local BASE_SMALL_FONT_SIZE = 13 * MOBILE_SCALE

-- Safe callback runner
local function safeCallback(fn, ...)
    if fn then
        local ok, err = pcall(fn, ...)
        if not ok then
            warn("Sapphire Library – Callback error: " .. tostring(err))
        end
    end
end

-- Validate element config (prevents nil/table mismatch)
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

-- Connection manager
local connections = {}
local function addConnection(signal, func)
    local con = signal:Connect(func)
    table.insert(connections, con)
    return con
end
local function cleanupConnections()
    for _, c in ipairs(connections) do c:Disconnect() end
    connections = {}
end

--========== THEMES ==========
local SapphireLib = {}
SapphireLib.Themes = {
    Default = {
        Main = Color3.fromRGB(25,25,25), Second = Color3.fromRGB(32,32,32),
        Stroke = Color3.fromRGB(60,60,60), Text = Color3.fromRGB(240,240,240),
        TextDark = Color3.fromRGB(150,150,150), Divider = Color3.fromRGB(60,60,60),
    },
    Light = {
        Main = Color3.fromRGB(245,245,245), Second = Color3.fromRGB(230,230,230),
        Stroke = Color3.fromRGB(180,180,180), Text = Color3.fromRGB(40,40,40),
        TextDark = Color3.fromRGB(100,100,100), Divider = Color3.fromRGB(200,200,200),
    },
    Ocean = {
        Main = Color3.fromRGB(20,30,30), Second = Color3.fromRGB(30,45,45),
        Stroke = Color3.fromRGB(45,70,70), Text = Color3.fromRGB(230,240,240),
        TextDark = Color3.fromRGB(140,160,160), Divider = Color3.fromRGB(50,70,70),
    },
    AmberGlow = {
        Main = Color3.fromRGB(45,30,20), Second = Color3.fromRGB(55,40,30),
        Stroke = Color3.fromRGB(85,60,45), Text = Color3.fromRGB(255,245,230),
        TextDark = Color3.fromRGB(190,150,130), Divider = Color3.fromRGB(90,65,50),
    },
    Amethyst = {
        Main = Color3.fromRGB(30,20,40), Second = Color3.fromRGB(40,30,55),
        Stroke = Color3.fromRGB(70,50,85), Text = Color3.fromRGB(240,240,250),
        TextDark = Color3.fromRGB(178,150,200), Divider = Color3.fromRGB(80,50,110),
    },
    DarkBlue = {
        Main = Color3.fromRGB(20,25,30), Second = Color3.fromRGB(30,35,40),
        Stroke = Color3.fromRGB(45,50,60), Text = Color3.fromRGB(230,230,230),
        TextDark = Color3.fromRGB(150,150,160), Divider = Color3.fromRGB(45,50,60),
    },
    Green = {
        Main = Color3.fromRGB(235,245,235), Second = Color3.fromRGB(225,240,225),
        Stroke = Color3.fromRGB(180,200,180), Text = Color3.fromRGB(30,60,30),
        TextDark = Color3.fromRGB(120,140,120), Divider = Color3.fromRGB(180,200,180),
    },
    Bloom = {
        Main = Color3.fromRGB(255,240,245), Second = Color3.fromRGB(255,235,240),
        Stroke = Color3.fromRGB(230,200,210), Text = Color3.fromRGB(60,40,50),
        TextDark = Color3.fromRGB(170,130,140), Divider = Color3.fromRGB(230,200,210),
    },
    Serenity = {
        Main = Color3.fromRGB(240,245,250), Second = Color3.fromRGB(210,220,230),
        Stroke = Color3.fromRGB(190,200,210), Text = Color3.fromRGB(50,55,60),
        TextDark = Color3.fromRGB(150,150,150), Divider = Color3.fromRGB(190,200,210),
    },
    Midnight = {
        Main = Color3.fromRGB(15,15,35), Second = Color3.fromRGB(20,20,50),
        Stroke = Color3.fromRGB(50,50,90), Text = Color3.fromRGB(220,220,255),
        TextDark = Color3.fromRGB(130,130,180), Divider = Color3.fromRGB(50,50,90),
    }
}
SapphireLib.SelectedTheme = "Default"

--========== SCREEN GUI ==========
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

-- Notification holder
local NotificationHolder = Instance.new("Frame")
NotificationHolder.Name = "NotifHolder"
NotificationHolder.Position = UDim2.new(1, -25, 1, -25)
NotificationHolder.Size = UDim2.new(0, 300, 1, -25)
NotificationHolder.AnchorPoint = Vector2.new(1, 1)
NotificationHolder.BackgroundTransparency = 1
NotificationHolder.Parent = Gui

-- Mobile show/hide prompt (only on touch devices)
local MobilePrompt = nil
if IS_MOBILE then
    MobilePrompt = Instance.new("Frame")
    MobilePrompt.Name = "MobilePrompt"
    MobilePrompt.Size = UDim2.new(0, 120, 0, 30)
    MobilePrompt.Position = UDim2.new(0.5, 0, 0, -50)
    MobilePrompt.AnchorPoint = Vector2.new(0.5, 0)
    MobilePrompt.BackgroundColor3 = Color3.fromRGB(25,25,25)
    MobilePrompt.BackgroundTransparency = 1
    MobilePrompt.ClipsDescendants = true
    Instance.new("UICorner", MobilePrompt).CornerRadius = UDim.new(0, 8)
    Instance.new("UIStroke", MobilePrompt).Color = Color3.fromRGB(93,93,93)
    local btn = Instance.new("TextButton", MobilePrompt)
    btn.Size = UDim2.new(1,0,1,0)
    btn.BackgroundTransparency = 1
    btn.Text = "Show UI"
    btn.Font = Enum.Font.GothamBold
    btn.TextColor3 = Color3.fromRGB(240,240,240)
    btn.TextSize = 14
    MobilePrompt.Parent = Gui
end

--========== NOTIFICATIONS ==========
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

--========== CONFIG SAVING ==========
SapphireLib.Flags = {}
SapphireLib.Folder = nil
SapphireLib.SaveCfg = false

function SapphireLib:LoadConfig()
    if not SapphireLib.SaveCfg or not isfolder or not isfile or not readfile then return end
    local path = SapphireLib.Folder .. "/" .. game.GameId .. ".json"
    if not isfile(path) then return end

    local decodeSuccess, data = pcall(function()
        return HttpService:JSONDecode(readfile(path))
    end)
    if not decodeSuccess then
        warn("Sapphire Library – Config file is corrupted, ignoring.")
        return
    end

    for flagName, flagVal in pairs(data) do
        if SapphireLib.Flags[flagName] then
            spawn(function()
                local flag = SapphireLib.Flags[flagName]
                local ok, err = pcall(function()
                    if flag.Type == "Colorpicker" then
                        flag:Set(unpackColor(flagVal))
                    else
                        flag:Set(flagVal)
                    end
                end)
                if not ok then
                    warn("Sapphire Library – Failed to load flag '" .. flagName .. "': " .. tostring(err))
                end
            end)
        end
    end
    self:Notify({Title = "Config", Content = "Loaded saved configuration.", Duration = 4})
end

function SapphireLib:SaveConfig()
    if not SapphireLib.SaveCfg or not isfolder or not writefile then return end
    local data = {}
    for name, flag in pairs(SapphireLib.Flags) do
        if flag.Save then
            local ok, val = pcall(function()
                if flag.Type == "Colorpicker" then
                    return packColor(flag.Value)
                else
                    return flag.Value
                end
            end)
            if ok then data[name] = val end
        end
    end
    local path = SapphireLib.Folder .. "/" .. game.GameId .. ".json"
    pcall(function()
        if not isfolder(SapphireLib.Folder) then makefolder(SapphireLib.Folder) end
        writefile(path, HttpService:JSONEncode(data))
    end)
end

--========== WINDOW CREATION ==========
function SapphireLib:CreateWindow(config)
    config = config or {}
    local WindowName = config.Name or "Sapphire UI"
    SapphireLib.Folder = config.ConfigFolder or WindowName
    SapphireLib.SaveCfg = config.SaveConfig or false
    if SapphireLib.SaveCfg and not isfolder(SapphireLib.Folder) then
        makefolder(SapphireLib.Folder)
    end

    local Main = Instance.new("Frame")
    Main.Name = "Main"
    Main.Parent = Gui
    Main.BackgroundColor3 = SapphireLib.Themes.Default.Main
    Main.Position = UDim2.new(0.5, -307, 0.5, -172)
    Main.Size = UDim2.new(0, 615 * MOBILE_SCALE, 0, 344 * MOBILE_SCALE)
    Main.ClipsDescendants = true
    Instance.new("UICorner",Main).CornerRadius = UDim.new(0,10)

    local MainShadow = Instance.new("ImageLabel",Main)
    MainShadow.BackgroundTransparency = 1
    MainShadow.Image = "rbxassetid://3523728077"
    MainShadow.AnchorPoint = Vector2.new(0.5,0.5)
    MainShadow.Position = UDim2.new(0.5,0,0.5,0)
    MainShadow.Size = UDim2.new(1,80,1,320)
    MainShadow.ImageColor3 = Color3.fromRGB(33,33,33)
    MainShadow.ImageTransparency = 0.7

    -- Topbar
    local TopBar = Instance.new("Frame",Main)
    TopBar.Size = UDim2.new(1,0,0,50 * MOBILE_SCALE)
    TopBar.BackgroundTransparency = 1

    local dragFrame = Instance.new("Frame",TopBar)
    dragFrame.Size = UDim2.new(1,0,1,0)
    dragFrame.BackgroundTransparency = 1

    local windowTitle = Instance.new("TextLabel",TopBar)
    windowTitle.Name = "Title"
    windowTitle.Size = UDim2.new(1,-90,2,0)
    windowTitle.Position = UDim2.new(0,25,0,-24)
    windowTitle.Font = Enum.Font.GothamBlack
    windowTitle.TextColor3 = SapphireLib.Themes.Default.Text
    windowTitle.TextSize = 20 * MOBILE_SCALE
    windowTitle.BackgroundTransparency = 1
    windowTitle.Text = WindowName

    if config.ShowIcon then
        windowTitle.Position = UDim2.new(0,50,0,-24)
        local icon = Instance.new("ImageLabel",TopBar)
        icon.Size = UDim2.new(0,20,0,20)
        icon.Position = UDim2.new(0,25,0,15)
        icon.BackgroundTransparency = 1
        icon.Image = getIcon(config.Icon) or config.Icon or "rbxassetid://8834748103"
    end

    local topBarLine = Instance.new("Frame",TopBar)
    topBarLine.Size = UDim2.new(1,0,0,1)
    topBarLine.Position = UDim2.new(0,0,1,-1)
    topBarLine.BackgroundColor3 = SapphireLib.Themes.Default.Stroke
    topBarLine.BorderSizePixel = 0

    -- Minimize/Close buttons
    local btnFrame = Instance.new("Frame",TopBar)
    btnFrame.BackgroundColor3 = SapphireLib.Themes.Default.Second
    btnFrame.BorderSizePixel = 0
    btnFrame.Size = UDim2.new(0,70 * MOBILE_SCALE,0,30 * MOBILE_SCALE)
    btnFrame.Position = UDim2.new(1,-90,0,10 * MOBILE_SCALE)
    Instance.new("UICorner",btnFrame).CornerRadius = UDim.new(0,7)
    Instance.new("UIStroke",btnFrame).Color = SapphireLib.Themes.Default.Stroke

    local btnDiv = Instance.new("Frame",btnFrame)
    btnDiv.Size = UDim2.new(0,1,1,0)
    btnDiv.Position = UDim2.new(0.5,0,0,0)
    btnDiv.BackgroundColor3 = SapphireLib.Themes.Default.Stroke

    local closeBtn = Instance.new("TextButton",btnFrame)
    closeBtn.Size = UDim2.new(0.5,0,1,0)
    closeBtn.BackgroundTransparency = 1
    closeBtn.Text = ""
    local closeIco = Instance.new("ImageLabel",closeBtn)
    closeIco.Size = UDim2.new(0,18 * MOBILE_SCALE,0,18 * MOBILE_SCALE)
    closeIco.Position = UDim2.new(0,9,0,6)
    closeIco.BackgroundTransparency = 1
    closeIco.Image = "rbxassetid://7072725342"
    closeIco.ImageColor3 = SapphireLib.Themes.Default.Text

    local minBtn = Instance.new("TextButton",btnFrame)
    minBtn.Size = UDim2.new(0.5,0,1,0)
    minBtn.Position = UDim2.new(0.5,0,0,0)
    minBtn.BackgroundTransparency = 1
    minBtn.Text = ""
    local minIco = Instance.new("ImageLabel",minBtn)
    minIco.Size = UDim2.new(0,18 * MOBILE_SCALE,0,18 * MOBILE_SCALE)
    minIco.Position = UDim2.new(0,9,0,6)
    minIco.BackgroundTransparency = 1
    minIco.Image = "rbxassetid://7072719338"
    minIco.ImageColor3 = SapphireLib.Themes.Default.Text

    -- Side panel
    local SidePanel = Instance.new("Frame",Main)
    SidePanel.Name = "SidePanel"
    SidePanel.Size = UDim2.new(0,150 * MOBILE_SCALE,1,-50 * MOBILE_SCALE)
    SidePanel.Position = UDim2.new(0,0,0,50 * MOBILE_SCALE)
    SidePanel.BackgroundColor3 = SapphireLib.Themes.Default.Second
    Instance.new("UICorner",SidePanel).CornerRadius = UDim.new(0,10)

    local patch1 = Instance.new("Frame",SidePanel)
    patch1.BackgroundColor3 = SidePanel.BackgroundColor3; patch1.Size = UDim2.new(1,0,0,10); patch1.Position = UDim2.new(0,0,0,0)
    local patch2 = Instance.new("Frame",SidePanel)
    patch2.BackgroundColor3 = SidePanel.BackgroundColor3; patch2.Size = UDim2.new(0,10,1,0); patch2.Position = UDim2.new(1,-10,0,0)

    local sideStroke = Instance.new("Frame",SidePanel)
    sideStroke.Size = UDim2.new(0,1,1,0)
    sideStroke.Position = UDim2.new(1,-1,0,0)
    sideStroke.BackgroundColor3 = SapphireLib.Themes.Default.Stroke

    local TabList = Instance.new("ScrollingFrame",SidePanel)
    TabList.Name = "TabList"
    TabList.Size = UDim2.new(1,0,1,-50 * MOBILE_SCALE)
    TabList.BackgroundTransparency = 1
    TabList.ScrollBarThickness = 4
    TabList.ScrollBarImageColor3 = SapphireLib.Themes.Default.Divider
    TabList.CanvasSize = UDim2.new(0,0,0,0)
    Instance.new("UIListLayout",TabList).Padding = UDim.new(0,8)
    Instance.new("UIPadding",TabList).PaddingTop = UDim.new(0,8)

    -- User info section
    local userSection = Instance.new("Frame",SidePanel)
    userSection.Size = UDim2.new(1,0,0,50 * MOBILE_SCALE)
    userSection.Position = UDim2.new(0,0,1,-50 * MOBILE_SCALE)
    userSection.BackgroundTransparency = 1
    local userStroke = Instance.new("Frame",userSection)
    userStroke.Size = UDim2.new(1,0,0,1); userStroke.BackgroundColor3 = SapphireLib.Themes.Default.Stroke

    local avatarFrame = Instance.new("Frame",userSection)
    avatarFrame.AnchorPoint = Vector2.new(0,0.5)
    avatarFrame.Size = UDim2.new(0,32 * MOBILE_SCALE,0,32 * MOBILE_SCALE)
    avatarFrame.Position = UDim2.new(0,10,0.5,0)
    avatarFrame.BackgroundTransparency = 1
    local avatarImage = Instance.new("ImageLabel",avatarFrame)
    avatarImage.Size = UDim2.new(1,0,1,0)
    avatarImage.BackgroundTransparency = 1
    avatarImage.Image = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. LocalPlayer.UserId .. "&width=420&height=420&format=png"
    Instance.new("UICorner",avatarFrame).CornerRadius = UDim.new(1,0)
    Instance.new("UIStroke",avatarFrame).Color = SapphireLib.Themes.Default.Stroke
    local avatarCover = Instance.new("ImageLabel",avatarFrame)
    avatarCover.Size = UDim2.new(1,0,1,0); avatarCover.BackgroundTransparency = 1
    avatarCover.Image = "rbxassetid://4031889928"; avatarCover.ImageColor3 = SapphireLib.Themes.Default.Second

    local userName = Instance.new("TextLabel",userSection)
    userName.Size = UDim2.new(1,-60,0,13 * MOBILE_SCALE)
    userName.Position = config.HidePremium and UDim2.new(0,50,0,19) or UDim2.new(0,50,0,12)
    userName.Font = Enum.Font.GothamBold
    userName.TextColor3 = SapphireLib.Themes.Default.Text
    userName.TextSize = 13 * MOBILE_SCALE
    userName.BackgroundTransparency = 1
    userName.Text = LocalPlayer.DisplayName

    local userTag = Instance.new("TextLabel",userSection)
    userTag.Size = UDim2.new(1,-60,0,12 * MOBILE_SCALE)
    userTag.Position = UDim2.new(0,50,1,-25)
    userTag.Font = Enum.Font.GothamSemibold
    userTag.TextColor3 = SapphireLib.Themes.Default.TextDark
    userTag.TextSize = 12 * MOBILE_SCALE
    userTag.BackgroundTransparency = 1
    userTag.Text = ""
    if config.HidePremium then userTag.Visible = false end

    -- Main elements container
    local ElementsContainer = Instance.new("ScrollingFrame",Main)
    ElementsContainer.Name = "ElementsContainer"
    ElementsContainer.Size = UDim2.new(1,-150 * MOBILE_SCALE,1,-50 * MOBILE_SCALE)
    ElementsContainer.Position = UDim2.new(0,150 * MOBILE_SCALE,0,50 * MOBILE_SCALE)
    ElementsContainer.BackgroundTransparency = 1
    ElementsContainer.ScrollBarThickness = 5
    ElementsContainer.ScrollBarImageColor3 = SapphireLib.Themes.Default.Divider
    ElementsContainer.CanvasSize = UDim2.new(0,0,0,0)
    Instance.new("UIListLayout",ElementsContainer).Padding = UDim.new(0,6)
    local ep = Instance.new("UIPadding",ElementsContainer)
    ep.PaddingTop    = UDim.new(0,15); ep.PaddingBottom = UDim.new(0,10)
    ep.PaddingLeft   = UDim.new(0,10); ep.PaddingRight  = UDim.new(0,15)

    -- Dragging logic (touch + mouse)
    local dragging, dragInput, mousePos, framePos
    dragFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            mousePos = input.Position
            framePos = Main.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    dragFrame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    addConnection(UserInputService.InputChanged, function(input)
        if input == dragInput and dragging then
            local delta = input.Position - mousePos
            TweenService:Create(Main, TweenInfo.new(0.45,Enum.EasingStyle.Quint,Enum.EasingDirection.Out), {
                Position = UDim2.new(framePos.X.Scale, framePos.X.Offset + delta.X, framePos.Y.Scale, framePos.Y.Offset + delta.Y)
            }):Play()
        end
    end)

    -- Minimize / Close functionality
    local minimized = false
    local hidden = false
    local mobileHideBtn = MobilePrompt and MobilePrompt:FindFirstChildOfClass("TextButton")

    minBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        if minimized then
            minIco.Image = "rbxassetid://7072720870"
            Main.Size = UDim2.new(0, windowTitle.TextBounds.X * MOBILE_SCALE + 140 * MOBILE_SCALE, 0, 50 * MOBILE_SCALE)
            Main.ClipsDescendants = true
            SidePanel.Visible = false; topBarLine.Visible = false
        else
            minIco.Image = "rbxassetid://7072719338"
            Main.Size = UDim2.new(0, 615 * MOBILE_SCALE, 0, 344 * MOBILE_SCALE)
            wait(0.1)
            Main.ClipsDescendants = false
            SidePanel.Visible = true; topBarLine.Visible = true
        end
    end)

    closeBtn.MouseButton1Click:Connect(function()
        Main.Visible = false; hidden = true
        if MobilePrompt then
            MobilePrompt.Position = UDim2.new(0.5,0,0,20)
            MobilePrompt.Visible = true
            TweenService:Create(MobilePrompt,TweenInfo.new(0.5,Enum.EasingStyle.Quint),{BackgroundTransparency = 0.3}):Play()
        else
            SapphireLib:Notify({Title = "Hidden", Content = "Press RightShift to toggle UI.", Duration = 5})
        end
    end)

    if mobileHideBtn then
        mobileHideBtn.MouseButton1Click:Connect(function()
            Main.Visible = true; hidden = false
            MobilePrompt.Visible = false
        end)
    else
        addConnection(UserInputService.InputBegan, function(input)
            if input.KeyCode == Enum.KeyCode.RightShift and hidden then
                Main.Visible = true; hidden = false
            end
        end)
    end

    -- Intro animation
    if config.IntroEnabled ~= false then
        Main.Visible = false
        local logo = Instance.new("ImageLabel",Gui)
        logo.AnchorPoint = Vector2.new(0.5,0.5)
        logo.Position = UDim2.new(0.5,0,0.4,0)
        logo.Size = UDim2.new(0,28 * MOBILE_SCALE,0,28 * MOBILE_SCALE)
        logo.BackgroundTransparency = 1
        logo.Image = getIcon(config.IntroIcon) or config.IntroIcon or ""
        logo.ImageTransparency = 1
        local intro = Instance.new("TextLabel",Gui)
        intro.AnchorPoint = Vector2.new(0.5,0.5)
        intro.Position = UDim2.new(0.5,19,0.5,0)
        intro.Size = UDim2.new(1,0,1,0)
        intro.BackgroundTransparency = 1
        intro.Font = Enum.Font.GothamBold
        intro.TextColor3 = Color3.fromRGB(255,255,255)
        intro.TextSize = 14 * MOBILE_SCALE
        intro.TextXAlignment = Enum.TextXAlignment.Center
        intro.TextTransparency = 1
        intro.Text = config.IntroText or "Sapphire UI"
        TweenService:Create(logo,TweenInfo.new(0.3,Enum.EasingStyle.Quad),{ImageTransparency = 0, Position = UDim2.new(0.5,0,0.5,0)}):Play()
        wait(0.8)
        TweenService:Create(logo,TweenInfo.new(0.3,Enum.EasingStyle.Quad),{Position = UDim2.new(0.5, -(intro.TextBounds.X/2),0.5,0)}):Play()
        wait(0.3)
        TweenService:Create(intro,TweenInfo.new(0.3,Enum.EasingStyle.Quad),{TextTransparency = 0}):Play()
        wait(2)
        TweenService:Create(intro,TweenInfo.new(0.3,Enum.EasingStyle.Quad),{TextTransparency = 1}):Play()
        Main.Visible = true
        logo:Destroy(); intro:Destroy()
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
        btn.Name = name; btn.Size = UDim2.new(1,0,0,30 * MOBILE_SCALE); btn.BackgroundTransparency = 1; btn.Text = ""
        local ico = Instance.new("ImageLabel",btn); ico.Name = "Ico"; ico.AnchorPoint = Vector2.new(0,0.5)
        ico.Size = UDim2.new(0,18 * MOBILE_SCALE,0,18 * MOBILE_SCALE); ico.Position = UDim2.new(0,10,0.5,0)
        ico.BackgroundTransparency = 1; ico.Image = getIcon(iconID) or iconID or ""; ico.ImageTransparency = 0.4; ico.ImageColor3 = SapphireLib.Themes.Default.Text
        local tit = Instance.new("TextLabel",btn); tit.Name = "Title"; tit.Size = UDim2.new(1,-35 * MOBILE_SCALE,1,0); tit.Position = UDim2.new(0,35,0,0)
        tit.BackgroundTransparency = 1; tit.Font = Enum.Font.GothamSemibold; tit.TextColor3 = SapphireLib.Themes.Default.Text
        tit.TextSize = 14 * MOBILE_SCALE; tit.TextTransparency = 0.4; tit.TextXAlignment = Enum.TextXAlignment.Left; tit.Text = name

        local tabContainer = Instance.new("ScrollingFrame",Main)
        tabContainer.Name = name .. "_container"
        tabContainer.Size = UDim2.new(1,-150 * MOBILE_SCALE,1,-50 * MOBILE_SCALE)
        tabContainer.Position = UDim2.new(0,150 * MOBILE_SCALE,0,50 * MOBILE_SCALE)
        tabContainer.BackgroundTransparency = 1; tabContainer.ScrollBarThickness = 5
        tabContainer.ScrollBarImageColor3 = SapphireLib.Themes.Default.Divider; tabContainer.CanvasSize = UDim2.new(0,0,0,0)
        tabContainer.Visible = false
        Instance.new("UIListLayout",tabContainer).Padding = UDim.new(0,6)
        local tp = Instance.new("UIPadding",tabContainer)
        tp.PaddingTop = UDim.new(0,15); tp.PaddingBottom = UDim.new(0,10); tp.PaddingLeft = UDim.new(0,10); tp.PaddingRight = UDim.new(0,15)

        btn.MouseButton1Click:Connect(function() selectTab(btn, tabContainer) end)
        if firstTab then firstTab = false; selectTab(btn, tabContainer) end

        -- Element base
        local function elementBase(elemType, confName, height)
            local h = height or BASE_ELEMENT_HEIGHT
            local frame = Instance.new("Frame")
            frame.Name = confName; frame.Size = UDim2.new(1,0,0,h); frame.BackgroundColor3 = SapphireLib.Themes.Default.Second; frame.BorderSizePixel = 0
            Instance.new("UICorner",frame).CornerRadius = UDim.new(0,5)
            Instance.new("UIStroke",frame).Color = SapphireLib.Themes.Default.Stroke
            local txt = Instance.new("TextLabel",frame)
            txt.Size = UDim2.new(1,-12,1,0); txt.Position = UDim2.new(0,12,0,0); txt.BackgroundTransparency = 1
            txt.Font = Enum.Font.GothamBold; txt.TextColor3 = SapphireLib.Themes.Default.Text; txt.TextSize = BASE_FONT_SIZE
            txt.TextXAlignment = Enum.TextXAlignment.Left; txt.Text = confName
            return frame, txt
        end

        local Tab = {}

        -- Section wrapper
        function Tab:CreateSection(name)
            local sf = Instance.new("Frame", tabContainer)
            sf.Size = UDim2.new(1,0,0,30 * MOBILE_SCALE); sf.BackgroundTransparency = 1
            local st = Instance.new("TextLabel",sf)
            st.Size = UDim2.new(1,-12,0,16 * MOBILE_SCALE); st.Position = UDim2.new(0,0,0,3); st.BackgroundTransparency = 1
            st.Font = Enum.Font.GothamSemibold; st.TextColor3 = SapphireLib.Themes.Default.TextDark; st.TextSize = 14 * MOBILE_SCALE
            st.TextXAlignment = Enum.TextXAlignment.Left; st.Text = name
            local holder = Instance.new("Frame",sf)
            holder.Name = "Holder"; holder.AnchorPoint = Vector2.new(0,0); holder.Size = UDim2.new(1,0,1,-24 * MOBILE_SCALE); holder.Position = UDim2.new(0,0,0,23)
            holder.BackgroundTransparency = 1; Instance.new("UIListLayout",holder).Padding = UDim.new(0,6)
            local function updateSize()
                sf.Size = UDim2.new(1,0,0, holder.UIListLayout.AbsoluteContentSize.Y + 31 * MOBILE_SCALE)
                holder.Size = UDim2.new(1,0,0, holder.UIListLayout.AbsoluteContentSize.Y)
            end
            local Section = {}
            for _, methodName in ipairs({"CreateButton","CreateToggle","CreateSlider","CreateDropdown",
                "CreateColorPicker","CreateKeybind","CreateTextbox","CreateLabel","CreateParagraph","CreateDivider"}) do
                Section[methodName] = function(_, ...)
                    if not Tab[methodName] then return end
                    local elem = Tab[methodName](...)
                    if elem and elem.frame then
                        elem.frame.Parent = holder
                        task.wait()
                        updateSize()
                    end
                    return elem
                end
            end
            return Section
        end

        -- BUTTON
        Tab.CreateButton = function(config)
            if not checkConfig(config, "Button") then return {} end
            local frame, fText = elementBase("Button", config.Name)
            local click = Instance.new("TextButton",frame)
            click.Size = UDim2.new(1,0,1,0); click.BackgroundTransparency = 1; click.Text = ""
            local btn = {frame = frame}
            click.MouseEnter:Connect(function()
                TweenService:Create(frame,TweenInfo.new(0.25,Enum.EasingStyle.Quint),{BackgroundColor3 = SapphireLib.Themes.Default.Second * 1.1}):Play()
            end)
            click.MouseLeave:Connect(function()
                TweenService:Create(frame,TweenInfo.new(0.25,Enum.EasingStyle.Quint),{BackgroundColor3 = SapphireLib.Themes.Default.Second}):Play()
            end)
            click.MouseButton1Click:Connect(function()
                TweenService:Create(frame,TweenInfo.new(0.15,Enum.EasingStyle.Quint),{BackgroundColor3 = SapphireLib.Themes.Default.Second * 1.2}):Play()
                wait(0.15)
                TweenService:Create(frame,TweenInfo.new(0.25,Enum.EasingStyle.Quint),{BackgroundColor3 = SapphireLib.Themes.Default.Second}):Play()
                safeCallback(config.Callback)
            end)
            function btn:Set(txt) fText.Text = txt end
            return btn
        end

        -- TOGGLE
        Tab.CreateToggle = function(config)
            if not checkConfig(config, "Toggle") then return {} end
            local frame, fText = elementBase("Toggle", config.Name)
            local value = config.Default or false
            local tb = Instance.new("Frame",frame)
            tb.Size = UDim2.new(0,24 * MOBILE_SCALE,0,24 * MOBILE_SCALE); tb.Position = UDim2.new(1,-24,0.5,0); tb.AnchorPoint = Vector2.new(0.5,0.5); tb.BorderSizePixel = 0
            Instance.new("UICorner",tb).CornerRadius = UDim.new(0,4)
            local ts = Instance.new("UIStroke",tb); ts.Color = SapphireLib.Themes.Default.Stroke
            local ti = Instance.new("ImageLabel",tb)
            ti.Size = UDim2.new(0,20 * MOBILE_SCALE,0,20 * MOBILE_SCALE); ti.AnchorPoint = Vector2.new(0.5,0.5); ti.Position = UDim2.new(0.5,0,0.5,0)
            ti.BackgroundTransparency = 1; ti.Image = "rbxassetid://3944680095"; ti.ImageColor3 = Color3.fromRGB(255,255,255)
            local click = Instance.new("TextButton",frame)
            click.Size = UDim2.new(1,0,1,0); click.BackgroundTransparency = 1; click.Text = ""
            local toggle = {frame = frame, Value = value, Save = config.Save ~= false, Type = "Toggle"}
            local function updateVisual()
                if toggle.Value then
                    tb.BackgroundColor3 = config.Color or Color3.fromRGB(9,99,195)
                    ts.Color = config.Color or Color3.fromRGB(9,99,195)
                    ti.ImageTransparency = 0; ti.Size = UDim2.new(0,20 * MOBILE_SCALE,0,20 * MOBILE_SCALE)
                else
                    tb.BackgroundColor3 = SapphireLib.Themes.Default.Divider
                    ts.Color = SapphireLib.Themes.Default.Stroke
                    ti.ImageTransparency = 1; ti.Size = UDim2.new(0,8 * MOBILE_SCALE,0,8 * MOBILE_SCALE)
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
                TweenService:Create(ti,TweenInfo.new(0.3,Enum.EasingStyle.Quint),{ImageTransparency = val and 0 or 1, Size = val and UDim2.new(0,20 * MOBILE_SCALE,0,20 * MOBILE_SCALE) or UDim2.new(0,8 * MOBILE_SCALE,0,8 * MOBILE_SCALE)}):Play()
                safeCallback(config.Callback, self.Value)
            end
            if config.Flag then SapphireLib.Flags[config.Flag] = toggle end
            return toggle
        end

        -- SLIDER
        Tab.CreateSlider = function(config)
            if not checkConfig(config, "Slider") then return {} end
            local frame = Instance.new("Frame")
            frame.Size = UDim2.new(1,0,0,65 * MOBILE_SCALE); frame.BackgroundColor3 = SapphireLib.Themes.Default.Second; frame.BorderSizePixel = 0
            Instance.new("UICorner",frame).CornerRadius = UDim.new(0,5)
            Instance.new("UIStroke",frame).Color = SapphireLib.Themes.Default.Stroke
            local fText = Instance.new("TextLabel",frame)
            fText.Size = UDim2.new(1,-12,0,14 * MOBILE_SCALE); fText.Position = UDim2.new(0,12,0,10); fText.BackgroundTransparency = 1
            fText.Font = Enum.Font.GothamBold; fText.TextColor3 = SapphireLib.Themes.Default.Text; fText.TextSize = BASE_FONT_SIZE; fText.TextXAlignment = Enum.TextXAlignment.Left
            fText.Text = config.Name

            local sliderBar = Instance.new("Frame",frame)
            sliderBar.Size = UDim2.new(1,-24,0,26 * MOBILE_SCALE); sliderBar.Position = UDim2.new(0,12,0,30 * MOBILE_SCALE)
            sliderBar.BackgroundTransparency = 0.9; sliderBar.BackgroundColor3 = config.Color or Color3.fromRGB(9,149,98); sliderBar.BorderSizePixel = 0
            Instance.new("UICorner",sliderBar).CornerRadius = UDim.new(0,5)
            Instance.new("UIStroke",sliderBar).Color = config.Color or Color3.fromRGB(9,149,98)

            local sliderProgress = Instance.new("Frame",sliderBar)
            sliderProgress.Size = UDim2.new(0,0,1,0); sliderProgress.BackgroundColor3 = config.Color or Color3.fromRGB(9,149,98)
            sliderProgress.BackgroundTransparency = 0.3; sliderProgress.BorderSizePixel = 0; Instance.new("UICorner",sliderProgress).CornerRadius = UDim.new(0,5)

            local valueLabel = Instance.new("TextLabel",sliderBar)
            valueLabel.Size = UDim2.new(1,-12,1,0); valueLabel.Position = UDim2.new(0,12,0,0); valueLabel.BackgroundTransparency = 1
            valueLabel.Font = Enum.Font.GothamBold; valueLabel.TextColor3 = SapphireLib.Themes.Default.Text; valueLabel.TextSize = BASE_SMALL_FONT_SIZE
            valueLabel.TextXAlignment = Enum.TextXAlignment.Left; valueLabel.TextTransparency = 0.8

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

            sliderBar.InputBegan:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
                    dragging = true
                end
            end)
            sliderBar.InputEnded:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
                    dragging = false
                end
            end)
            addConnection(UserInputService.InputChanged, function(input)
                if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                    local frac = math.clamp((input.Position.X - sliderBar.AbsolutePosition.X)/sliderBar.AbsoluteSize.X, 0, 1)
                    local val = config.Min + frac * (config.Max - config.Min)
                    setVisual(val)
                    safeCallback(config.Callback, slider.Value)
                    SapphireLib:SaveConfig()
                end
            end)
            function slider:Set(val)
                setVisual(val); safeCallback(config.Callback, self.Value)
            end
            if config.Flag then SapphireLib.Flags[config.Flag] = slider end
            return slider
        end

        -- DROPDOWN
        Tab.CreateDropdown = function(config)
            if not checkConfig(config, "Dropdown") then return {} end
            local frame, fText = elementBase("Dropdown", config.Name)
            local value = config.Default or ""; local toggled = false
            local options = config.Options or {}
            local selLabel = Instance.new("TextLabel",frame)
            selLabel.Size = UDim2.new(1,-40,1,0); selLabel.BackgroundTransparency = 1; selLabel.Font = Enum.Font.Gotham
            selLabel.TextColor3 = SapphireLib.Themes.Default.TextDark; selLabel.TextSize = BASE_SMALL_FONT_SIZE; selLabel.TextXAlignment = Enum.TextXAlignment.Right; selLabel.Text = value
            local dropIcon = Instance.new("ImageLabel",frame)
            dropIcon.Size = UDim2.new(0,20 * MOBILE_SCALE,0,20 * MOBILE_SCALE); dropIcon.Position = UDim2.new(1,-30,0.5,0); dropIcon.AnchorPoint = Vector2.new(0,0.5)
            dropIcon.BackgroundTransparency = 1; dropIcon.Image = "rbxassetid://7072706796"; dropIcon.ImageColor3 = SapphireLib.Themes.Default.TextDark
            local dropContainer = Instance.new("ScrollingFrame",frame)
            dropContainer.Position = UDim2.new(0,0,0,BASE_ELEMENT_HEIGHT); dropContainer.Size = UDim2.new(1,0,1,-BASE_ELEMENT_HEIGHT)
            dropContainer.BackgroundTransparency = 1; dropContainer.CanvasSize = UDim2.new(0,0,0,0)
            dropContainer.ScrollBarThickness = 4; dropContainer.ScrollBarImageColor3 = SapphireLib.Themes.Default.Divider; dropContainer.ClipsDescendants = true
            Instance.new("UIListLayout",dropContainer)
            local click = Instance.new("TextButton",frame)
            click.Size = UDim2.new(1,0,1,0); click.BackgroundTransparency = 1; click.Text = ""
            local dropdown = {frame = frame, Value = value, Options = options, Buttons = {}, Save = config.Save ~= false, Type = "Dropdown"}
            local function refresh(clear)
                if clear then for _,b in pairs(dropdown.Buttons) do b:Destroy() end; table.clear(dropdown.Buttons) end
                for _,opt in ipairs(options) do
                    local ob = Instance.new("TextButton",dropContainer)
                    ob.Size = UDim2.new(1,0,0,28 * MOBILE_SCALE); ob.BackgroundTransparency = 1; ob.Text = ""
                    local ol = Instance.new("TextLabel",ob)
                    ol.Size = UDim2.new(1,-8,1,0); ol.Position = UDim2.new(0,8,0,0); ol.BackgroundTransparency = 1
                    ol.Font = Enum.Font.Gotham; ol.TextColor3 = SapphireLib.Themes.Default.Text; ol.TextSize = BASE_SMALL_FONT_SIZE
                    ol.TextXAlignment = Enum.TextXAlignment.Left; ol.Text = opt
                    ob.MouseButton1Click:Connect(function() dropdown:Set(opt); SapphireLib:SaveConfig() end)
                    dropdown.Buttons[opt] = ob
                end
                dropContainer.CanvasSize = UDim2.new(0,0,0, dropContainer.UIListLayout.AbsoluteContentSize.Y)
            end
            click.MouseButton1Click:Connect(function()
                toggled = not toggled
                TweenService:Create(dropIcon,TweenInfo.new(0.15,Enum.EasingStyle.Quad),{Rotation = toggled and 180 or 0}):Play()
                local maxHeight = #options > 5 and (5*28 * MOBILE_SCALE) or dropContainer.UIListLayout.AbsoluteContentSize.Y
                TweenService:Create(frame,TweenInfo.new(0.15,Enum.EasingStyle.Quad),{Size = toggled and UDim2.new(1,0,0, maxHeight + BASE_ELEMENT_HEIGHT) or UDim2.new(1,0,0,BASE_ELEMENT_HEIGHT)}):Play()
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

        -- COLOR PICKER
        Tab.CreateColorPicker = function(config)
            if not checkConfig(config, "ColorPicker") then return {} end
            local frame, fText = elementBase("ColorPicker", config.Name)
            local value = config.Default or Color3.fromRGB(255,255,255)
            local toggled = false
            local pickerCont = Instance.new("Frame",frame); pickerCont.Position = UDim2.new(0,0,0,BASE_ELEMENT_HEIGHT); pickerCont.Size = UDim2.new(1,0,1,-BASE_ELEMENT_HEIGHT); pickerCont.BackgroundTransparency = 1; pickerCont.ClipsDescendants = true
            local colorBox = Instance.new("Frame",frame)
            colorBox.Size = UDim2.new(0,24 * MOBILE_SCALE,0,24 * MOBILE_SCALE); colorBox.Position = UDim2.new(1,-12,0.5,0); colorBox.AnchorPoint = Vector2.new(1,0.5)
            colorBox.BackgroundColor3 = value; colorBox.BorderSizePixel = 0; Instance.new("UICorner",colorBox).CornerRadius = UDim.new(0,4)
            Instance.new("UIStroke",colorBox).Color = SapphireLib.Themes.Default.Stroke
            local canvas = Instance.new("ImageLabel",pickerCont); canvas.Size = UDim2.new(1,-25,1,0); canvas.BackgroundTransparency = 1; canvas.Image = "rbxassetid://4155801252"
            Instance.new("UICorner",canvas).CornerRadius = UDim.new(0,5)
            local colorSel = Instance.new("ImageLabel",canvas); colorSel.Size = UDim2.new(0,18 * MOBILE_SCALE,0,18 * MOBILE_SCALE); colorSel.AnchorPoint = Vector2.new(0.5,0.5); colorSel.BackgroundTransparency = 1; colorSel.Image = "http://www.roblox.com/asset/?id=4805639000"
            local hueFrame = Instance.new("Frame",pickerCont); hueFrame.Size = UDim2.new(0,20 * MOBILE_SCALE,1,0); hueFrame.Position = UDim2.new(1,-20 * MOBILE_SCALE,0,0); hueFrame.BorderSizePixel = 0
            Instance.new("UICorner",hueFrame).CornerRadius = UDim.new(0,5)
            local hueGrad = Instance.new("UIGradient",hueFrame); hueGrad.Rotation = 270
            hueGrad.Color = ColorSequence.new{
                ColorSequenceKeypoint.new(0,Color3.fromRGB(255,0,4)), ColorSequenceKeypoint.new(0.2,Color3.fromRGB(234,255,0)),
                ColorSequenceKeypoint.new(0.4,Color3.fromRGB(21,255,0)), ColorSequenceKeypoint.new(0.6,Color3.fromRGB(0,255,255)),
                ColorSequenceKeypoint.new(0.8,Color3.fromRGB(0,17,255)), ColorSequenceKeypoint.new(0.9,Color3.fromRGB(255,0,251)),
                ColorSequenceKeypoint.new(1,Color3.fromRGB(255,0,4))
            }
            local hueSel = Instance.new("ImageLabel",hueFrame); hueSel.Size = UDim2.new(0,18 * MOBILE_SCALE,0,18 * MOBILE_SCALE); hueSel.AnchorPoint = Vector2.new(0.5,0.5); hueSel.BackgroundTransparency = 1; hueSel.Image = "http://www.roblox.com/asset/?id=4805639000"
            local click = Instance.new("TextButton",frame); click.Size = UDim2.new(1,0,1,0); click.BackgroundTransparency = 1; click.Text = ""
            local cp = {frame = frame, Value = value, Save = config.Save ~= false, Type = "Colorpicker"}
            local function updateColor()
                colorBox.BackgroundColor3 = cp.Value; canvas.BackgroundColor3 = Color3.fromHSV(cp.H or 1,1,1)
                local x = cp.S * canvas.AbsoluteSize.X; local y = (1 - cp.V) * canvas.AbsoluteSize.Y
                colorSel.Position = UDim2.new(0, x - colorSel.AbsoluteSize.X/2, 0, y - colorSel.AbsoluteSize.Y/2)
                local hy = (1 - cp.H) * hueFrame.AbsoluteSize.Y
                hueSel.Position = UDim2.new(0.5,0,0, hy - hueSel.AbsoluteSize.Y/2)
                safeCallback(config.Callback, cp.Value)
            end
            local function setFromHSV()
                cp.Value = Color3.fromHSV(cp.H, cp.S, cp.V); updateColor(); SapphireLib:SaveConfig()
            end
            cp.H, cp.S, cp.V = Color3.toHSV(value); updateColor()
            click.MouseButton1Click:Connect(function()
                toggled = not toggled
                TweenService:Create(frame,TweenInfo.new(0.15,Enum.EasingStyle.Quad),{Size = toggled and UDim2.new(1,0,0,148 * MOBILE_SCALE) or UDim2.new(1,0,0,BASE_ELEMENT_HEIGHT)}):Play()
                canvas.Visible = toggled; hueFrame.Visible = toggled
            end)
            local cInput, hInput
            canvas.InputBegan:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
                    if cInput then cInput:Disconnect() end
                    cInput = addConnection(RunService.RenderStepped, function()
                        local mx = math.clamp(Mouse.X - canvas.AbsolutePosition.X, 0, canvas.AbsoluteSize.X)
                        local my = math.clamp(Mouse.Y - canvas.AbsolutePosition.Y, 0, canvas.AbsoluteSize.Y)
                        cp.S = mx / canvas.AbsoluteSize.X; cp.V = 1 - my / canvas.AbsoluteSize.Y; setFromHSV()
                    end)
                end
            end)
            canvas.InputEnded:Connect(function(i) if (i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch) and cInput then cInput:Disconnect() end end)
            hueFrame.InputBegan:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
                    if hInput then hInput:Disconnect() end
                    hInput = addConnection(RunService.RenderStepped, function()
                        local my = math.clamp(Mouse.Y - hueFrame.AbsolutePosition.Y, 0, hueFrame.AbsoluteSize.Y)
                        cp.H = 1 - my / hueFrame.AbsoluteSize.Y; setFromHSV()
                    end)
                end
            end)
            hueFrame.InputEnded:Connect(function(i) if (i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch) and hInput then hInput:Disconnect() end end)
            function cp:Set(col) self.Value = col; self.H, self.S, self.V = Color3.toHSV(col); updateColor() end
            if config.Flag then SapphireLib.Flags[config.Flag] = cp end
            return cp
        end

        -- KEYBIND
        Tab.CreateKeybind = function(config)
            if not checkConfig(config, "Keybind") then return {} end
            local frame, fText = elementBase("Keybind", config.Name)
            local currentKey = config.Default or Enum.KeyCode.Unknown
            local binding = false
            local keyLabel = Instance.new("TextLabel",frame)
            keyLabel.Size = UDim2.new(0,24 * MOBILE_SCALE,0,24 * MOBILE_SCALE); keyLabel.Position = UDim2.new(1,-12,0.5,0); keyLabel.AnchorPoint = Vector2.new(1,0.5)
            keyLabel.BackgroundColor3 = SapphireLib.Themes.Default.Main; keyLabel.BorderSizePixel = 0; Instance.new("UICorner",keyLabel).CornerRadius = UDim.new(0,4)
            Instance.new("UIStroke",keyLabel).Color = SapphireLib.Themes.Default.Stroke
            keyLabel.Font = Enum.Font.GothamBold; keyLabel.TextColor3 = SapphireLib.Themes.Default.Text; keyLabel.TextSize = 14 * MOBILE_SCALE
            keyLabel.TextXAlignment = Enum.TextXAlignment.Center; keyLabel.Text = currentKey.Name ~= "Unknown" and currentKey.Name or "..."
            local click = Instance.new("TextButton",frame)
            click.Size = UDim2.new(1,0,1,0); click.BackgroundTransparency = 1; click.Text = ""
            local kb = {frame = frame, Value = currentKey, Save = config.Save ~= false, Type = "Bind"}
            click.InputEnded:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1 then
                    if not binding then binding = true; keyLabel.Text = "..." end
                end
            end)
            addConnection(UserInputService.InputBegan, function(input)
                if UserInputService:GetFocusedTextBox() then return end
                if (input.KeyCode == currentKey or input.UserInputType == currentKey) and not binding then
                    if config.Hold then
                        local holding = true; safeCallback(config.Callback, true)
                        local endCon; endCon = UserInputService.InputEnded:Connect(function(inp)
                            if inp.KeyCode == currentKey or inp.UserInputType == currentKey then
                                safeCallback(config.Callback, false); endCon:Disconnect()
                            end
                        end)
                    else safeCallback(config.Callback) end
                elseif binding then
                    local key = nil
                    local blacklist = {Enum.KeyCode.Unknown, Enum.KeyCode.W, Enum.KeyCode.A, Enum.KeyCode.S, Enum.KeyCode.D, Enum.KeyCode.Up, Enum.KeyCode.Left, Enum.KeyCode.Down, Enum.KeyCode.Right, Enum.KeyCode.Slash, Enum.KeyCode.Tab, Enum.KeyCode.Backspace, Enum.KeyCode.Escape}
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

        -- TEXTBOX
        Tab.CreateTextbox = function(config)
            if not checkConfig(config, "Textbox") then return {} end
            local frame, fText = elementBase("Textbox", config.Name)
            local textBox = Instance.new("TextBox",frame)
            textBox.Size = UDim2.new(0,24 * MOBILE_SCALE,0,24 * MOBILE_SCALE); textBox.Position = UDim2.new(1,-12,0.5,0); textBox.AnchorPoint = Vector2.new(1,0.5)
            textBox.BackgroundColor3 = SapphireLib.Themes.Default.Main; textBox.BorderSizePixel = 0
            Instance.new("UICorner",textBox).CornerRadius = UDim.new(0,4)
            Instance.new("UIStroke",textBox).Color = SapphireLib.Themes.Default.Stroke
            textBox.Font = Enum.Font.GothamSemibold; textBox.TextColor3 = SapphireLib.Themes.Default.Text; textBox.TextSize = 14 * MOBILE_SCALE
            textBox.TextXAlignment = Enum.TextXAlignment.Center; textBox.ClearTextOnFocus = false
            textBox.Text = config.Default or ""; textBox.PlaceholderText = config.Placeholder or "Input"; textBox.PlaceholderColor3 = Color3.fromRGB(210,210,210)
            textBox:GetPropertyChangedSignal("Text"):Connect(function()
                TweenService:Create(textBox,TweenInfo.new(0.45,Enum.EasingStyle.Quint),{Size = UDim2.new(0, textBox.TextBounds.X + 16 * MOBILE_SCALE, 0, 24 * MOBILE_SCALE)}):Play()
            end)
            textBox.FocusLost:Connect(function()
                safeCallback(config.Callback, textBox.Text)
                if config.TextDisappear then textBox.Text = "" end
            end)
            local click = Instance.new("TextButton",frame)
            click.Size = UDim2.new(1,0,1,0); click.BackgroundTransparency = 1; click.Text = ""
            click.MouseButton1Click:Connect(function() textBox:CaptureFocus() end)
            local obj = {frame = frame}
            function obj:Set(t) textBox.Text = t; safeCallback(config.Callback, t) end
            return obj
        end

        -- LABEL
        Tab.CreateLabel = function(text, iconID, colorOverride)
            local frame = Instance.new("Frame"); frame.Size = UDim2.new(1,0,0,30 * MOBILE_SCALE)
            frame.BackgroundColor3 = colorOverride or SapphireLib.Themes.Default.Second; frame.BackgroundTransparency = 0.7; frame.BorderSizePixel = 0
            Instance.new("UICorner",frame).CornerRadius = UDim.new(0,5)
            Instance.new("UIStroke",frame).Color = colorOverride and colorOverride or SapphireLib.Themes.Default.Stroke
            local lbl = Instance.new("TextLabel",frame)
            lbl.Size = UDim2.new(1,-12,1,0); lbl.Position = UDim2.new(0,12,0,0); lbl.BackgroundTransparency = 1
            lbl.Font = Enum.Font.GothamBold; lbl.TextColor3 = SapphireLib.Themes.Default.Text; lbl.TextSize = BASE_FONT_SIZE; lbl.TextXAlignment = Enum.TextXAlignment.Left
            lbl.Text = text
            if iconID then
                lbl.Position = UDim2.new(0,45,0,0); lbl.Size = UDim2.new(1,-100,0,14 * MOBILE_SCALE)
                local ic = Instance.new("ImageLabel",frame)
                ic.Size = UDim2.new(0,20 * MOBILE_SCALE,0,20 * MOBILE_SCALE); ic.Position = UDim2.new(0,12,0.5,0); ic.AnchorPoint = Vector2.new(0,0.5)
                ic.BackgroundTransparency = 1; ic.Image = getIcon(iconID) or iconID; ic.ImageColor3 = SapphireLib.Themes.Default.Text; ic.ImageTransparency = 0.2
            end
            local lab = {frame = frame}
            function lab:Set(t) lbl.Text = t end
            return lab
        end

        -- PARAGRAPH
        Tab.CreateParagraph = function(title, content)
            local frame = Instance.new("Frame"); frame.Size = UDim2.new(1,0,0,30 * MOBILE_SCALE)
            frame.BackgroundColor3 = SapphireLib.Themes.Default.Second; frame.BackgroundTransparency = 0.7; frame.BorderSizePixel = 0
            Instance.new("UICorner",frame).CornerRadius = UDim.new(0,5)
            Instance.new("UIStroke",frame).Color = SapphireLib.Themes.Default.Stroke
            local tl = Instance.new("TextLabel",frame)
            tl.Size = UDim2.new(1,-12,0,14 * MOBILE_SCALE); tl.Position = UDim2.new(0,12,0,10); tl.BackgroundTransparency = 1
            tl.Font = Enum.Font.GothamBold; tl.TextColor3 = SapphireLib.Themes.Default.Text; tl.TextSize = BASE_FONT_SIZE; tl.TextXAlignment = Enum.TextXAlignment.Left; tl.Text = title
            local cl = Instance.new("TextLabel",frame)
            cl.Size = UDim2.new(1,-24,0,0); cl.Position = UDim2.new(0,12,0,26 * MOBILE_SCALE); cl.BackgroundTransparency = 1
            cl.Font = Enum.Font.GothamSemibold; cl.TextColor3 = SapphireLib.Themes.Default.TextDark; cl.TextSize = BASE_SMALL_FONT_SIZE
            cl.TextXAlignment = Enum.TextXAlignment.Left; cl.TextWrapped = true; cl.Text = content
            cl:GetPropertyChangedSignal("Text"):Connect(function()
                cl.Size = UDim2.new(1,-24,0, cl.TextBounds.Y); frame.Size = UDim2.new(1,0,0, cl.TextBounds.Y + 35 * MOBILE_SCALE)
            end)
            local par = {frame = frame}
            function par:Set(cont) cl.Text = cont end
            return par
        end

        -- DIVIDER
        Tab.CreateDivider = function()
            local frame = Instance.new("Frame"); frame.Size = UDim2.new(1,0,0,1); frame.BackgroundColor3 = SapphireLib.Themes.Default.Stroke
            frame.BackgroundTransparency = 0.85; frame.BorderSizePixel = 0
            local div = {frame = frame}
            function div:Set(v) frame.Visible = v end
            return div
        end

        return Tab
    end

    function Window:SetTheme(themeName)
        if SapphireLib.Themes[themeName] then
            SapphireLib.SelectedTheme = themeName
            SapphireLib:Notify({Title = "Theme", Content = "Theme set to " .. themeName, Duration = 2})
        else
            warn("Sapphire Library – Theme not found: " .. tostring(themeName))
        end
    end

    return Window
end

function SapphireLib:Init()
    if SapphireLib.SaveCfg then self:LoadConfig() end
end

function SapphireLib:Destroy()
    cleanupConnections()
    Gui:Destroy()
end

return SapphireLib
