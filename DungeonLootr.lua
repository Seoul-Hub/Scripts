-- [[ WAIT FOR GAME TO LOAD ]]
if not game:IsLoaded() then
    game.Loaded:Wait()
end

local MarketplaceService = game:GetService("MarketplaceService")

-- [[ GAME VERIFICATION ]]
local success, gameInfo = pcall(function()
    return MarketplaceService:GetProductInfo(game.PlaceId)
end)

local expectedName = "Dungeon Lootr"
if not success or not string.find(gameInfo.Name, expectedName) then
    local currentName = success and gameInfo.Name or "Unknown"
    warn("Seoul Hub: Execution blocked. This script is locked to '" .. expectedName .. "'. (Current game: " .. currentName .. ")")
    return 
end

-- [[ VARIABLES & SERVICES ]]
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")
local VirtualUser = game:GetService("VirtualUser")
local TeleportService = game:GetService("TeleportService")
local GuiService = game:GetService("GuiService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer

-- [[ FOLDER STRUCTURE ]]
local ROOT_FOLDER = "Seoul Hub"
local GAME_FOLDER = "Dungeon Lootr"
local CONFIG_FOLDER = ROOT_FOLDER .. "/" .. GAME_FOLDER

local function EnsureFolders()
    if makefolder and isfolder then
        if not isfolder(ROOT_FOLDER) then pcall(makefolder, ROOT_FOLDER) end
        if not isfolder(CONFIG_FOLDER) then pcall(makefolder, CONFIG_FOLDER) end
    end
end
EnsureFolders()

local function GetConfigList()
    EnsureFolders()
    local list = {}
    if listfiles then
        local success, files = pcall(listfiles, CONFIG_FOLDER)
        if success and files then
            for _, file in ipairs(files) do
                if file:sub(-5) == ".json" then
                    local name = file:match("([^/\\]+)%.json$")
                    if name then
                        table.insert(list, name)
                    end
                end
            end
        end
    end
    return list
end

-- [[ STATE MANAGEMENT ]]
local getgenv = getgenv or function() return _G end
if getgenv().SeoulHub then getgenv().SeoulHub:Destroy() end -- Unload previous instance

local State = {
    MenuVisible = true,
    HideMenuKey = Enum.KeyCode.CapsLock,
    WalkSpeed = 30,
    Connections = {},
    CurrentTab = nil,
    NewConfigName = "Default",
    
    -- Auto Variables
    AutoAttack = false,
    InfiniteJump = false,
    AutoDungeon = false,
    AutoCollectChest = false, 
    AutoSelectChest = false, 
    AutoReplay = false,
    AutoUsePotion = false,
}
local UI = {}
local UIUpdateCallbacks = {}

local function UpdateAllUI()
    for _, cb in ipairs(UIUpdateCallbacks) do
        pcall(cb)
    end
end

-- [[ MODERN UI THEME ]]
local TweenService = game:GetService("TweenService")

local Theme = {
    MainBg = Color3.fromRGB(14, 15, 18),
    WindowBg = Color3.fromRGB(18, 20, 25),
    SidebarBg = Color3.fromRGB(11, 13, 16),
    TopBarBg = Color3.fromRGB(13, 15, 19),
    CardBg = Color3.fromRGB(24, 27, 33),
    CardHover = Color3.fromRGB(32, 36, 44),
    CardPressed = Color3.fromRGB(39, 45, 54),
    AccentGreen = Color3.fromRGB(43, 136, 255),
    AccentGreenDark = Color3.fromRGB(25, 95, 185),
    AccentCyan = Color3.fromRGB(88, 199, 255),
    Danger = Color3.fromRGB(255, 107, 120),
    Border = Color3.fromRGB(45, 49, 57),
    TextMain = Color3.fromRGB(243, 245, 247),
    TextDim = Color3.fromRGB(154, 163, 175),
    TextMuted = Color3.fromRGB(105, 114, 126),
    Off = Color3.fromRGB(90, 97, 107)
}

local function tween(object, info, properties)
    local animation = TweenService:Create(object, info, properties)
    animation:Play()
    return animation
end

local FastTween = TweenInfo.new(0.14, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local PressTween = TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local SlowTween = TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

-- [[ UI CREATION ]]
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SEOUL_Modern_Dark"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local successGui, coreGui = pcall(function() return game:GetService("CoreGui") end)
ScreenGui.Parent = successGui and coreGui or LocalPlayer:WaitForChild("PlayerGui")
getgenv().SeoulHub = ScreenGui

local MainFrame = Instance.new("Frame")
MainFrame.Name = "Window"
MainFrame.Size = UDim2.new(0, 720, 0, 460)
MainFrame.Position = UDim2.new(0.5, -360, 0.5, -230)
MainFrame.BackgroundColor3 = Theme.WindowBg
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.ClipsDescendants = true
MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 12)

local windowStroke = Instance.new("UIStroke")
windowStroke.Color = Theme.Border
windowStroke.Transparency = 0.22
windowStroke.Thickness = 1
windowStroke.Parent = MainFrame

local Shadow = Instance.new("Frame")
Shadow.Name = "Shadow"
Shadow.Size = UDim2.new(1, 18, 1, 18)
Shadow.Position = UDim2.new(0, -9, 0, 9)
Shadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
Shadow.BackgroundTransparency = 0.72
Shadow.BorderSizePixel = 0
Shadow.ZIndex = 0
Shadow.Parent = MainFrame
Instance.new("UICorner", Shadow).CornerRadius = UDim.new(0, 15)

-- [[ MINIMIZED LOGO CREATION ]]
local LogoButton = Instance.new("TextButton")
LogoButton.Name = "MinimizedLogo"
LogoButton.Size = UDim2.new(0, 46, 0, 46)
LogoButton.Position = UDim2.new(0.5, -23, 0, 30)
LogoButton.BackgroundColor3 = Theme.CardBg
LogoButton.TextColor3 = Theme.AccentGreen
LogoButton.Font = Enum.Font.GothamBold
LogoButton.TextSize = 24
LogoButton.Text = "S"
LogoButton.Visible = false
LogoButton.AutoButtonColor = false
LogoButton.ZIndex = 10
LogoButton.Parent = ScreenGui
Instance.new("UICorner", LogoButton).CornerRadius = UDim.new(0, 10)

local logoStroke = Instance.new("UIStroke")
logoStroke.Color = Theme.Border
logoStroke.Transparency = 0.22
logoStroke.Thickness = 1
logoStroke.Parent = LogoButton

LogoButton.MouseEnter:Connect(function() tween(LogoButton, FastTween, {BackgroundColor3 = Theme.CardHover}) end)
LogoButton.MouseLeave:Connect(function() tween(LogoButton, FastTween, {BackgroundColor3 = Theme.CardBg}) end)

local logoDragging, logoDragStart, logoStartPos, isDraggingLogo
LogoButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        logoDragging = true
        isDraggingLogo = false
        logoDragStart = input.Position
        logoStartPos = LogoButton.Position
    end
end)
LogoButton.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        logoDragging = false
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if logoDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        isDraggingLogo = true
        local delta = input.Position - logoDragStart
        LogoButton.Position = UDim2.new(
            logoStartPos.X.Scale, logoStartPos.X.Offset + delta.X, 
            logoStartPos.Y.Scale, logoStartPos.Y.Offset + delta.Y
        )
    end
end)

local MouseUnlocker = Instance.new("TextButton")
MouseUnlocker.Size = UDim2.new(0, 0, 0, 0)
MouseUnlocker.BackgroundTransparency = 1
MouseUnlocker.Text = ""
MouseUnlocker.Modal = true
MouseUnlocker.Parent = MainFrame

local function ToggleMenu()
    State.MenuVisible = not State.MenuVisible
    MainFrame.Visible = State.MenuVisible
    MouseUnlocker.Modal = State.MenuVisible
    LogoButton.Visible = not State.MenuVisible
end

LogoButton.MouseButton1Click:Connect(function()
    if not isDraggingLogo then
        ToggleMenu()
    end
end)

-- Header
local TopBar = Instance.new("Frame")
TopBar.Name = "TopBar"
TopBar.Size = UDim2.new(1, 0, 0, 50)
TopBar.BackgroundColor3 = Theme.TopBarBg
TopBar.BorderSizePixel = 0
TopBar.ZIndex = 2
TopBar.Parent = MainFrame

local headerGradient = Instance.new("UIGradient")
headerGradient.Rotation = 90
headerGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(19, 22, 27)),
    ColorSequenceKeypoint.new(1, Theme.TopBarBg)
})
headerGradient.Parent = TopBar

local BrandIcon = Instance.new("TextLabel")
BrandIcon.Size = UDim2.new(0, 28, 0, 28)
BrandIcon.Position = UDim2.new(0, 16, 0.5, -14)
BrandIcon.BackgroundColor3 = Theme.AccentGreen
BrandIcon.TextColor3 = Color3.fromRGB(4, 12, 9)
BrandIcon.Font = Enum.Font.GothamBold
BrandIcon.TextSize = 36
BrandIcon.Text = "S"
BrandIcon.ZIndex = 3
BrandIcon.Parent = TopBar
Instance.new("UICorner", BrandIcon).CornerRadius = UDim.new(0, 8)

local TitleText = Instance.new("TextLabel")
TitleText.Size = UDim2.new(0, 220, 0, 20)
TitleText.Position = UDim2.new(0, 52, 0, 10)
TitleText.BackgroundTransparency = 1
TitleText.TextColor3 = Theme.TextMain
TitleText.Text = "SEOUL HUB"
TitleText.Font = Enum.Font.GothamBold
TitleText.TextSize = 15
TitleText.TextXAlignment = Enum.TextXAlignment.Left
TitleText.ZIndex = 3
TitleText.Parent = TopBar

local VersionText = Instance.new("TextLabel")
VersionText.Size = UDim2.new(0, 100, 0, 16)
VersionText.Position = UDim2.new(0, 52, 0, 27)
VersionText.BackgroundTransparency = 1
VersionText.TextColor3 = Theme.TextMuted
VersionText.Text = "Dungeon Lootr  •  v1.0"
VersionText.Font = Enum.Font.Gotham
VersionText.TextSize = 10
VersionText.TextXAlignment = Enum.TextXAlignment.Left
VersionText.ZIndex = 3
VersionText.Parent = TopBar

local StatusBadge = Instance.new("Frame")
StatusBadge.Size = UDim2.new(0, 104, 0, 26)
StatusBadge.Position = UDim2.new(1, -150, 0.5, -13)
StatusBadge.BackgroundColor3 = Color3.fromRGB(22, 44, 36)
StatusBadge.BorderSizePixel = 0
StatusBadge.ZIndex = 3
StatusBadge.Parent = TopBar
Instance.new("UICorner", StatusBadge).CornerRadius = UDim.new(0, 8)
local statusStroke = Instance.new("UIStroke")
statusStroke.Color = Theme.AccentGreen
statusStroke.Transparency = 0.72
statusStroke.Thickness = 1
statusStroke.Parent = StatusBadge

local StatusDot = Instance.new("Frame")
StatusDot.Size = UDim2.new(0, 7, 0, 7)
StatusDot.Position = UDim2.new(0, 11, 0.5, -3)
StatusDot.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
StatusDot.BorderSizePixel = 0
StatusDot.Parent = StatusBadge
Instance.new("UICorner", StatusDot).CornerRadius = UDim.new(1, 0)

local StatusText = Instance.new("TextLabel")
StatusText.Size = UDim2.new(1, -26, 1, 0)
StatusText.Position = UDim2.new(0, 24, 0, 0)
StatusText.BackgroundTransparency = 1
StatusText.TextColor3 = Theme.TextMain
StatusText.Text = "ONLINE"
StatusText.Font = Enum.Font.GothamBold
StatusText.TextSize = 10
StatusText.TextXAlignment = Enum.TextXAlignment.Left
StatusText.Parent = StatusBadge

local MinimizeButton = Instance.new("TextButton")
MinimizeButton.Size = UDim2.new(0, 32, 0, 32)
MinimizeButton.Position = UDim2.new(1, -40, 0.5, -16)
MinimizeButton.BackgroundColor3 = Theme.CardBg
MinimizeButton.TextColor3 = Theme.TextDim
MinimizeButton.Text = "—"
MinimizeButton.Font = Enum.Font.GothamBold
MinimizeButton.TextSize = 16
MinimizeButton.AutoButtonColor = false
MinimizeButton.ZIndex = 3
MinimizeButton.Parent = TopBar
Instance.new("UICorner", MinimizeButton).CornerRadius = UDim.new(0, 8)
MinimizeButton.MouseEnter:Connect(function() tween(MinimizeButton, FastTween, {BackgroundColor3 = Theme.CardHover, TextColor3 = Theme.TextMain}) end)
MinimizeButton.MouseLeave:Connect(function() tween(MinimizeButton, FastTween, {BackgroundColor3 = Theme.CardBg, TextColor3 = Theme.TextDim}) end)
MinimizeButton.MouseButton1Click:Connect(function()
    ToggleMenu()
end)

local TopLine = Instance.new("Frame")
TopLine.Size = UDim2.new(1, 0, 0, 1)
TopLine.Position = UDim2.new(0, 0, 1, -1)
TopLine.BackgroundColor3 = Theme.Border
TopLine.BorderSizePixel = 0
TopLine.ZIndex = 4
TopLine.Parent = TopBar

-- Sidebar
local Sidebar = Instance.new("Frame")
Sidebar.Size = UDim2.new(0, 176, 1, -50)
Sidebar.Position = UDim2.new(0, 0, 0, 50)
Sidebar.BackgroundColor3 = Theme.SidebarBg
Sidebar.BorderSizePixel = 0
Sidebar.ZIndex = 2
Sidebar.Parent = MainFrame

local SidebarPadding = Instance.new("UIPadding")
SidebarPadding.PaddingTop = UDim.new(0, 10) 
SidebarPadding.PaddingLeft = UDim.new(0, 12)
SidebarPadding.PaddingRight = UDim.new(0, 12)
SidebarPadding.PaddingBottom = UDim.new(0, 12)
SidebarPadding.Parent = Sidebar

local TabList = Instance.new("Frame")
TabList.Size = UDim2.new(1, 0, 1, -80)
TabList.Position = UDim2.new(0, 0, 0, 0) 
TabList.BackgroundTransparency = 1
TabList.Parent = Sidebar

local TabListLayout = Instance.new("UIListLayout")
TabListLayout.Padding = UDim.new(0, 2)
TabListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
TabListLayout.SortOrder = Enum.SortOrder.LayoutOrder
TabListLayout.Parent = TabList

local SidebarDivider = Instance.new("Frame")
SidebarDivider.Size = UDim2.new(1, 0, 0, 1)
SidebarDivider.Position = UDim2.new(0, 0, 1, -58)
SidebarDivider.BackgroundColor3 = Theme.Border
SidebarDivider.BackgroundTransparency = 0.65
SidebarDivider.BorderSizePixel = 0
SidebarDivider.Parent = Sidebar

local SidebarStatus = Instance.new("TextLabel")
SidebarStatus.Size = UDim2.new(1, 0, 0, 18)
SidebarStatus.Position = UDim2.new(0, 0, 1, -45)
SidebarStatus.BackgroundTransparency = 1
SidebarStatus.Text = "●  Connected"
SidebarStatus.TextColor3 = Color3.fromRGB(46, 204, 113)
SidebarStatus.Font = Enum.Font.GothamMedium
SidebarStatus.TextSize = 10
SidebarStatus.TextXAlignment = Enum.TextXAlignment.Left
SidebarStatus.Parent = Sidebar

local SidebarHint = Instance.new("TextLabel")
SidebarHint.Size = UDim2.new(1, 0, 0, 16)
SidebarHint.Position = UDim2.new(0, 1, 1, -26)
SidebarHint.BackgroundTransparency = 1
SidebarHint.Text = "THE PORTAL | 00:00:00"
SidebarHint.TextColor3 = Theme.TextMuted
SidebarHint.Font = Enum.Font.Gotham
SidebarHint.TextSize = 11
SidebarHint.TextXAlignment = Enum.TextXAlignment.Left
SidebarHint.Parent = Sidebar

-- Runtime logic
local startTime = os.time()
task.spawn(function()
    while task.wait(1) do
        local elapsed = os.time() - startTime
        local hours = math.floor(elapsed / 3600)
        local minutes = math.floor((elapsed % 3600) / 60)
        local seconds = elapsed % 60
        SidebarHint.Text = string.format("THE PORTAL | %02d:%02d:%02d", hours, minutes, seconds)
    end
end)

-- Content Area
local ContentArea = Instance.new("Frame")
ContentArea.Size = UDim2.new(1, -176, 1, -50)
ContentArea.Position = UDim2.new(0, 176, 0, 50)
ContentArea.BackgroundColor3 = Theme.MainBg
ContentArea.BorderSizePixel = 0
ContentArea.Parent = MainFrame

local ContentPadding = Instance.new("UIPadding")
ContentPadding.PaddingTop = UDim.new(0, 18)
ContentPadding.PaddingBottom = UDim.new(0, 16)
ContentPadding.PaddingLeft = UDim.new(0, 18)
ContentPadding.PaddingRight = UDim.new(0, 18)
ContentPadding.Parent = ContentArea

-- Dragging Logic
local dragging, dragStart, startPos
TopBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
        tween(Shadow, FastTween, {BackgroundTransparency = 0.62})
    end
end)
TopBar.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
        tween(Shadow, FastTween, {BackgroundTransparency = 0.72})
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- [[ UI COMPONENT BUILDERS ]]
local Tabs, TabButtons, TabMarkers, TabLabels = {}, {}, {}, {}

local function addStroke(parent, transparency)
    local stroke = Instance.new("UIStroke")
    stroke.Color = Theme.Border
    stroke.Transparency = transparency or 0.42
    stroke.Thickness = 1
    stroke.Parent = parent
    return stroke
end

local function createTab(name)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 34)
    btn.BackgroundColor3 = Theme.SidebarBg
    btn.Text = ""
    btn.AutoButtonColor = false
    btn.Parent = TabList
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -24, 1, 0)
    label.Position = UDim2.new(0, 16, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = Theme.TextDim
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = btn

    local marker = Instance.new("Frame")
    marker.Size = UDim2.new(0, 3, 0, 16)
    marker.Position = UDim2.new(0, 0, 0.5, -8)
    marker.BackgroundColor3 = Theme.AccentGreen
    marker.BorderSizePixel = 0
    marker.Visible = false
    marker.Parent = btn
    Instance.new("UICorner", marker).CornerRadius = UDim.new(1, 0)

    local page = Instance.new("ScrollingFrame")
    page.Size = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.ScrollBarThickness = 3
    page.ScrollBarImageColor3 = Color3.fromRGB(70, 77, 87)
    page.ScrollBarImageTransparency = 0.2
    page.Visible = false
    page.CanvasSize = UDim2.new(0, 0, 0, 0)
    page.Parent = ContentArea

    local pageLayout = Instance.new("UIListLayout")
    pageLayout.Padding = UDim.new(0, 10)
    pageLayout.SortOrder = Enum.SortOrder.LayoutOrder
    pageLayout.Parent = page

    local pagePadding = Instance.new("UIPadding")
    pagePadding.PaddingBottom = UDim.new(0, 12)
    pagePadding.Parent = page

    pageLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        page.CanvasSize = UDim2.new(0, 0, 0, pageLayout.AbsoluteContentSize.Y + 14)
    end)

    local function setButtonSelected(selected)
        if selected then
            tween(btn, FastTween, {BackgroundColor3 = Theme.CardBg})
            tween(label, FastTween, {TextColor3 = Theme.TextMain})
            marker.Visible = true
        end
    end

    btn.MouseEnter:Connect(function()
        if State.CurrentTab ~= name then
            tween(btn, FastTween, {BackgroundColor3 = Color3.fromRGB(17, 20, 24)})
        end
    end)
    btn.MouseLeave:Connect(function()
        if State.CurrentTab ~= name then
            tween(btn, FastTween, {BackgroundColor3 = Theme.SidebarBg})
        end
    end)

    local function switchTab()
        if State.CurrentTab and State.CurrentTab ~= name then
            local oldPage = Tabs[State.CurrentTab]
            if oldPage then oldPage.Visible = false end
            
            if TabButtons[State.CurrentTab] then tween(TabButtons[State.CurrentTab], FastTween, {BackgroundColor3 = Theme.SidebarBg}) end
            if TabLabels[State.CurrentTab] then tween(TabLabels[State.CurrentTab], FastTween, {TextColor3 = Theme.TextDim}) end
            if TabMarkers[State.CurrentTab] then TabMarkers[State.CurrentTab].Visible = false end
        end

        State.CurrentTab = name
        page.Visible = true
        setButtonSelected(true)
        page.Position = UDim2.new(0, 8, 0, 0)
        page.CanvasPosition = Vector2.new(0, 0)
        tween(page, SlowTween, {Position = UDim2.new(0, 0, 0, 0)})
    end

    btn.MouseButton1Click:Connect(function()
        tween(btn, PressTween, {Size = UDim2.new(1, -3, 0, 32)})
        task.delay(0.08, function() tween(btn, PressTween, {Size = UDim2.new(1, 0, 0, 34)}) end)
        switchTab()
    end)

    Tabs[name] = page
    TabButtons[name] = btn
    TabMarkers[name] = marker
    TabLabels[name] = label

    if not State.CurrentTab then switchTab() end
    return page
end

local function createPageHeader(parent, title, subtitle)
    local wrap = Instance.new("Frame")
    wrap.Size = UDim2.new(1, -2, 0, 54)
    wrap.BackgroundTransparency = 1
    wrap.Parent = parent

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, 0, 0, 26)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = title
    titleLabel.TextColor3 = Theme.TextMain
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextSize = 20
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = wrap

    local subLabel = Instance.new("TextLabel")
    subLabel.Size = UDim2.new(1, 0, 0, 20)
    subLabel.Position = UDim2.new(0, 0, 0, 27)
    subLabel.BackgroundTransparency = 1
    subLabel.Text = subtitle
    subLabel.TextColor3 = Theme.TextMuted
    subLabel.Font = Enum.Font.Gotham
    subLabel.TextSize = 10
    subLabel.TextXAlignment = Enum.TextXAlignment.Left
    subLabel.Parent = wrap
    return wrap
end

local function createSection(parent, text)
    local wrap = Instance.new("Frame")
    wrap.Size = UDim2.new(1, -2, 0, 23)
    wrap.BackgroundTransparency = 1
    wrap.Parent = parent

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0, 100, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = text:upper()
    label.TextColor3 = Theme.TextMuted
    label.Font = Enum.Font.GothamBold
    label.TextSize = 9
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = wrap

    local line = Instance.new("Frame")
    line.Size = UDim2.new(1, -112, 0, 1)
    line.Position = UDim2.new(0, 112, 0.5, 0)
    line.BackgroundColor3 = Theme.Border
    line.BackgroundTransparency = 0.55
    line.BorderSizePixel = 0
    line.Parent = wrap
end

local function createSwitch(parent)
    local track = Instance.new("Frame")
    track.Size = UDim2.new(0, 40, 0, 22)
    track.Position = UDim2.new(1, -50, 0.5, -11)
    track.BackgroundColor3 = Theme.Off
    track.BorderSizePixel = 0
    track.Parent = parent
    Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 16, 0, 16)
    knob.Position = UDim2.new(0, 3, 0.5, -8)
    knob.BackgroundColor3 = Theme.TextMain
    knob.BorderSizePixel = 0
    knob.Parent = track
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)
    return track, knob
end

local function createFeatureCard(parent, name, description, stateKey, bindKey, callback)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, -2, 0, bindKey and 66 or 60)
    card.BackgroundColor3 = Theme.CardBg
    card.BorderSizePixel = 0
    card.Parent = parent
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 10)
    local stroke = addStroke(card, 0.55)

    local icon = Instance.new("TextLabel")
    icon.Size = UDim2.new(0, 34, 0, 34)
    icon.Position = UDim2.new(0, 12, 0, 13)
    icon.BackgroundColor3 = Color3.fromRGB(28, 33, 39)
    icon.Text = "•"
    icon.TextColor3 = Theme.AccentGreen
    icon.Font = Enum.Font.GothamBold
    icon.TextSize = 14
    icon.Parent = card
    Instance.new("UICorner", icon).CornerRadius = UDim.new(0, 9)

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -150, 0, 20)
    title.Position = UDim2.new(0, 57, 0, 10)
    title.BackgroundTransparency = 1
    title.RichText = true
    title.Text = name
    title.TextColor3 = Theme.TextMain
    title.Font = Enum.Font.GothamMedium
    title.TextSize = 12
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = card

    local desc = Instance.new("TextLabel")
    desc.Size = UDim2.new(1, -165, 0, 24)
    desc.Position = UDim2.new(0, 57, 0, 29)
    desc.BackgroundTransparency = 1
    desc.Text = description
    desc.TextColor3 = Theme.TextMuted
    desc.Font = Enum.Font.Gotham
    desc.TextSize = 9
    desc.TextWrapped = true
    desc.TextXAlignment = Enum.TextXAlignment.Left
    desc.Parent = card

    local track, knob = createSwitch(card)
    local keyButton
    if bindKey then
        keyButton = Instance.new("TextButton")
        keyButton.Size = UDim2.new(0, 64, 0, 32)
        keyButton.Position = UDim2.new(1, -130, 0.5, -11)
        keyButton.BackgroundColor3 = Theme.SidebarBg
        keyButton.TextColor3 = Theme.TextDim
        keyButton.Font = Enum.Font.GothamMedium
        keyButton.TextSize = 12
        keyButton.Text = "[" .. (State[bindKey] and State[bindKey].Name or "None") .. "]"
        keyButton.AutoButtonColor = false
        keyButton.Parent = card
        Instance.new("UICorner", keyButton).CornerRadius = UDim.new(0, 7)
        addStroke(keyButton, 0.7)
    end

    local function updateVisuals()
        local enabled = State[stateKey]
        tween(track, FastTween, {BackgroundColor3 = enabled and Theme.AccentGreenDark or Theme.Off})
        tween(knob, FastTween, {Position = enabled and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)})
        tween(stroke, FastTween, {Color = enabled and Theme.AccentGreen or Theme.Border, Transparency = enabled and 0.5 or 0.55})
        if keyButton and State[bindKey] then
            keyButton.Text = "[" .. State[bindKey].Name .. "]"
        end
    end

    table.insert(UIUpdateCallbacks, updateVisuals)

    local clickTarget = Instance.new("TextButton")
    clickTarget.Size = UDim2.new(1, 0, 1, 0)
    clickTarget.BackgroundTransparency = 1
    clickTarget.Text = ""
    clickTarget.AutoButtonColor = false
    clickTarget.ZIndex = 5
    clickTarget.Parent = card
    clickTarget.MouseEnter:Connect(function() tween(card, FastTween, {BackgroundColor3 = Theme.CardHover}) end)
    clickTarget.MouseLeave:Connect(function() tween(card, FastTween, {BackgroundColor3 = Theme.CardBg}) end)
    clickTarget.MouseButton1Click:Connect(function()
        State[stateKey] = not State[stateKey]
        updateVisuals()
        if callback then callback(State[stateKey]) end
        tween(card, PressTween, {Size = UDim2.new(1, -5, 0, bindKey and 63 or 57)})
        task.delay(0.08, function() tween(card, PressTween, {Size = UDim2.new(1, -2, 0, bindKey and 66 or 60)}) end)
    end)

    if keyButton then
        keyButton.ZIndex = 6
        local changing = false
        keyButton.MouseEnter:Connect(function() tween(keyButton, FastTween, {BackgroundColor3 = Theme.CardHover, TextColor3 = Theme.TextMain}) end)
        keyButton.MouseLeave:Connect(function() if not changing then tween(keyButton, FastTween, {BackgroundColor3 = Theme.SidebarBg, TextColor3 = Theme.TextDim}) end end)
        keyButton.MouseButton1Click:Connect(function()
            changing = true
            keyButton.Text = "[...]"
            tween(keyButton, FastTween, {BackgroundColor3 = Theme.AccentGreen, TextColor3 = Color3.fromRGB(4, 12, 9)})
        end)
        table.insert(State.Connections, UserInputService.InputBegan:Connect(function(input)
            if changing and input.UserInputType == Enum.UserInputType.Keyboard then
                State[bindKey] = input.KeyCode
                keyButton.Text = "[" .. State[bindKey].Name .. "]"
                changing = false
                tween(keyButton, FastTween, {BackgroundColor3 = Theme.SidebarBg, TextColor3 = Theme.TextDim})
            end
        end))
    end

    updateVisuals()
    return updateVisuals
end

local function createToggle(parent, name, stateKey, description, callback)
    return createFeatureCard(parent, name, description or "Toggle this feature on or off.", stateKey, nil, callback)
end

local function createToggleWithBind(parent, name, stateKey, bindKey, description, callback)
    return createFeatureCard(parent, name, description or "Toggle this feature with a custom keybind.", stateKey, bindKey, callback)
end

local function createInput(parent, name, stateKey, isNumber)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, -2, 0, 52)
    card.BackgroundColor3 = Theme.CardBg
    card.BorderSizePixel = 0
    card.Parent = parent
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 10)
    addStroke(card, 0.55)

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -100, 1, 0)
    title.Position = UDim2.new(0, 15, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = name
    title.TextColor3 = Theme.TextMain
    title.Font = Enum.Font.GothamMedium
    title.TextSize = 12
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = card
    
    local inputBg = Instance.new("Frame")
    inputBg.Size = UDim2.new(0, 110, 0, 28)
    inputBg.Position = UDim2.new(1, -125, 0.5, -14)
    inputBg.BackgroundColor3 = Theme.SidebarBg
    inputBg.Parent = card
    Instance.new("UICorner", inputBg).CornerRadius = UDim.new(0, 6)
    addStroke(inputBg, 0.6)

    local textBox = Instance.new("TextBox")
    textBox.Size = UDim2.new(1, 0, 1, 0)
    textBox.BackgroundTransparency = 1
    textBox.Text = tostring(State[stateKey] or "")
    textBox.TextColor3 = Theme.TextDim
    textBox.Font = Enum.Font.GothamBold
    textBox.TextSize = 12
    textBox.ClearTextOnFocus = true
    textBox.Parent = inputBg

    textBox.FocusLost:Connect(function()
        local val = textBox.Text
        if isNumber then
            val = tonumber(val) or State[stateKey]
            textBox.Text = tostring(val)
        end
        State[stateKey] = val
    end)
    
    local function updateInputVisual()
        textBox.Text = tostring(State[stateKey] or "")
    end
    table.insert(UIUpdateCallbacks, updateInputVisual)

    return textBox 
end

local function createButton(parent, name, description, callback)
    if type(description) == "function" then
        callback = description
        description = "Click to execute action."
    end
    description = type(description) == "string" and description or ""

    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, -2, 0, 60)
    card.BackgroundColor3 = Theme.CardBg
    card.BorderSizePixel = 0
    card.Parent = parent
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 10)
    local stroke = addStroke(card, 0.55)

    local icon = Instance.new("TextLabel")
    icon.Size = UDim2.new(0, 34, 0, 34)
    icon.Position = UDim2.new(0, 12, 0, 13)
    icon.BackgroundColor3 = Color3.fromRGB(28, 33, 39)
    icon.Text = "▶"
    icon.TextColor3 = Theme.AccentCyan
    icon.Font = Enum.Font.GothamBold
    icon.TextSize = 14
    icon.Parent = card
    Instance.new("UICorner", icon).CornerRadius = UDim.new(0, 9)

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -60, 0, 20)
    title.Position = UDim2.new(0, 57, 0, 10)
    title.BackgroundTransparency = 1
    title.Text = name
    title.TextColor3 = Theme.TextMain
    title.Font = Enum.Font.GothamMedium
    title.TextSize = 12
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = card

    local desc = Instance.new("TextLabel")
    desc.Size = UDim2.new(1, -60, 0, 24)
    desc.Position = UDim2.new(0, 57, 0, 29)
    desc.BackgroundTransparency = 1
    desc.Text = description
    desc.TextColor3 = Theme.TextMuted
    desc.Font = Enum.Font.Gotham
    desc.TextSize = 9
    desc.TextWrapped = true
    desc.TextXAlignment = Enum.TextXAlignment.Left
    desc.Parent = card

    local clickTarget = Instance.new("TextButton")
    clickTarget.Size = UDim2.new(1, 0, 1, 0)
    clickTarget.BackgroundTransparency = 1
    clickTarget.Text = ""
    clickTarget.AutoButtonColor = false
    clickTarget.ZIndex = 5
    clickTarget.Parent = card
    
    clickTarget.MouseEnter:Connect(function() tween(card, FastTween, {BackgroundColor3 = Theme.CardHover}) end)
    clickTarget.MouseLeave:Connect(function() tween(card, FastTween, {BackgroundColor3 = Theme.CardBg}) end)
    clickTarget.MouseButton1Click:Connect(function()
        tween(card, PressTween, {Size = UDim2.new(1, -5, 0, 57)})
        task.delay(0.08, function() tween(card, PressTween, {Size = UDim2.new(1, -2, 0, 60)}) end)
        if callback then callback() end
    end)
    return card
end

local function createKeybind(parent, name, bindKey)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, -2, 0, 54)
    card.BackgroundColor3 = Theme.CardBg
    card.BorderSizePixel = 0
    card.Parent = parent
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 10)
    addStroke(card, 0.58)

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -110, 1, 0)
    label.Position = UDim2.new(0, 15, 0, 0)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 11
    label.TextColor3 = Theme.TextMain
    label.Text = name
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = card

    local bindBtn = Instance.new("TextButton")
    bindBtn.Size = UDim2.new(0, 76, 0, 26)
    bindBtn.Position = UDim2.new(1, -89, 0.5, -13)
    bindBtn.BackgroundColor3 = Theme.SidebarBg
    bindBtn.TextColor3 = Theme.TextDim
    bindBtn.Font = Enum.Font.GothamMedium
    bindBtn.TextSize = 12
    bindBtn.Text = "[" .. (State[bindKey] and State[bindKey].Name or "None") .. "]"
    bindBtn.AutoButtonColor = false
    bindBtn.Parent = card
    Instance.new("UICorner", bindBtn).CornerRadius = UDim.new(0, 7)
    addStroke(bindBtn, 0.68)

    local function updateKeybindVisual()
        if State[bindKey] then
            bindBtn.Text = "[" .. State[bindKey].Name .. "]"
        end
    end
    table.insert(UIUpdateCallbacks, updateKeybindVisual)

    bindBtn.MouseEnter:Connect(function() tween(bindBtn, FastTween, {BackgroundColor3 = Theme.CardHover, TextColor3 = Theme.TextMain}) end)
    bindBtn.MouseLeave:Connect(function() tween(bindBtn, FastTween, {BackgroundColor3 = Theme.SidebarBg, TextColor3 = Theme.TextDim}) end)

    local changing = false
    bindBtn.MouseButton1Click:Connect(function()
        changing = true
        bindBtn.Text = "PRESS KEY"
        tween(bindBtn, FastTween, {BackgroundColor3 = Theme.AccentGreen, TextColor3 = Color3.fromRGB(4, 12, 9)})
    end)
    table.insert(State.Connections, UserInputService.InputBegan:Connect(function(input)
        if changing and input.UserInputType == Enum.UserInputType.Keyboard then
            State[bindKey] = input.KeyCode
            bindBtn.Text = "[" .. State[bindKey].Name .. "]"
            changing = false
            tween(bindBtn, FastTween, {BackgroundColor3 = Theme.SidebarBg, TextColor3 = Theme.TextDim})
        end
    end))
end

local function createDropdown(parent, name, initialOptions, callback)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, -2, 0, 52)
    container.BackgroundColor3 = Theme.CardBg
    container.ClipsDescendants = true
    container.Parent = parent
    Instance.new("UICorner", container).CornerRadius = UDim.new(0, 10)
    local stroke = addStroke(container, 0.58)

    local mainBtn = Instance.new("TextButton")
    mainBtn.Size = UDim2.new(1, 0, 0, 52)
    mainBtn.BackgroundTransparency = 1
    mainBtn.Text = ""
    mainBtn.Parent = container

    local iconLabel = Instance.new("TextLabel")
    iconLabel.Size = UDim2.new(0, 30, 0, 30)
    iconLabel.Position = UDim2.new(0, 11, 0, 11)
    iconLabel.BackgroundColor3 = Color3.fromRGB(28, 33, 39)
    iconLabel.Text = "≡"
    iconLabel.TextColor3 = Theme.AccentGreen
    iconLabel.Font = Enum.Font.GothamBold
    iconLabel.TextSize = 14
    iconLabel.Parent = mainBtn
    Instance.new("UICorner", iconLabel).CornerRadius = UDim.new(0, 8)

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -88, 0, 52)
    title.Position = UDim2.new(0, 52, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = name .. " - Select..."
    title.TextColor3 = Theme.TextMain
    title.Font = Enum.Font.GothamMedium
    title.TextSize = 12
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = mainBtn

    local arrow = Instance.new("TextLabel")
    arrow.Size = UDim2.new(0, 24, 0, 52)
    arrow.Position = UDim2.new(1, -34, 0, 0)
    arrow.BackgroundTransparency = 1
    arrow.Text = "▼"
    arrow.TextColor3 = Theme.TextMuted
    arrow.Font = Enum.Font.GothamBold
    arrow.TextSize = 12
    arrow.Parent = mainBtn

    local dropFrame = Instance.new("ScrollingFrame")
    dropFrame.Size = UDim2.new(1, -24, 0, 120)
    dropFrame.Position = UDim2.new(0, 12, 0, 52)
    dropFrame.BackgroundTransparency = 1
    dropFrame.BorderSizePixel = 0
    dropFrame.ScrollBarThickness = 2
    dropFrame.ScrollBarImageColor3 = Theme.Border
    dropFrame.Parent = container
    
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 6)
    layout.Parent = dropFrame

    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0, 6)
    padding.PaddingBottom = UDim.new(0, 6)
    padding.Parent = dropFrame

    local isOpen = false
    mainBtn.MouseEnter:Connect(function() tween(container, FastTween, {BackgroundColor3 = Theme.CardHover}) end)
    mainBtn.MouseLeave:Connect(function() if not isOpen then tween(container, FastTween, {BackgroundColor3 = Theme.CardBg}) end end)

    mainBtn.MouseButton1Click:Connect(function()
        isOpen = not isOpen
        if isOpen then
            tween(container, SlowTween, {Size = UDim2.new(1, -2, 0, 180)})
            tween(arrow, FastTween, {Rotation = 180, TextColor3 = Theme.AccentGreen})
        else
            tween(container, SlowTween, {Size = UDim2.new(1, -2, 0, 52), BackgroundColor3 = Theme.CardBg})
            tween(arrow, FastTween, {Rotation = 0, TextColor3 = Theme.TextMuted})
        end
    end)

    local function buildOptions(newOptions)
        for _, child in ipairs(dropFrame:GetChildren()) do
            if child:IsA("TextButton") then child:Destroy() end
        end

        for _, opt in ipairs(newOptions) do
            local optBtn = Instance.new("TextButton")
            optBtn.Size = UDim2.new(1, 0, 0, 32)
            optBtn.BackgroundColor3 = Theme.SidebarBg
            optBtn.Text = "  " .. opt
            optBtn.TextColor3 = Theme.TextDim
            optBtn.Font = Enum.Font.Gotham
            optBtn.TextSize = 11
            optBtn.TextXAlignment = Enum.TextXAlignment.Left
            optBtn.AutoButtonColor = false
            optBtn.Parent = dropFrame
            Instance.new("UICorner", optBtn).CornerRadius = UDim.new(0, 6)

            optBtn.MouseEnter:Connect(function() tween(optBtn, FastTween, {BackgroundColor3 = Color3.fromRGB(28, 33, 39), TextColor3 = Theme.TextMain}) end)
            optBtn.MouseLeave:Connect(function() tween(optBtn, FastTween, {BackgroundColor3 = Theme.SidebarBg, TextColor3 = Theme.TextDim}) end)
            
            optBtn.MouseButton1Click:Connect(function()
                title.Text = name .. " - " .. opt
                isOpen = false
                tween(container, SlowTween, {Size = UDim2.new(1, -2, 0, 52), BackgroundColor3 = Theme.CardBg})
                tween(arrow, FastTween, {Rotation = 0, TextColor3 = Theme.TextMuted})
                callback(opt)
            end)
        end
    end
    
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        dropFrame.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 12)
    end)
    
    buildOptions(initialOptions)
    
    return container, buildOptions, title
end

-- [[ CUSTOM NOTIFICATION SYSTEM ]]
local NotifContainer = Instance.new("Frame")
NotifContainer.Name = "NotifContainer"
NotifContainer.Size = UDim2.new(0, 240, 1, -20)
NotifContainer.Position = UDim2.new(1, -10, 1, -10)
NotifContainer.AnchorPoint = Vector2.new(1, 1)
NotifContainer.BackgroundTransparency = 1
NotifContainer.Parent = ScreenGui

local NotifLayout = Instance.new("UIListLayout")
NotifLayout.SortOrder = Enum.SortOrder.LayoutOrder
NotifLayout.Padding = UDim.new(0, 8)
NotifLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
NotifLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
NotifLayout.Parent = NotifContainer

local function SendHubNotification(text, duration)
    duration = duration or 3
    
    local notif = Instance.new("Frame")
    notif.Size = UDim2.new(1, 0, 0, 60)
    notif.BackgroundColor3 = Theme.CardBg
    notif.BackgroundTransparency = 1
    notif.Parent = NotifContainer
    Instance.new("UICorner", notif).CornerRadius = UDim.new(0, 8)
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = Theme.AccentGreen
    stroke.Thickness = 1
    stroke.Transparency = 1
    stroke.Parent = notif
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -20, 0, 20)
    title.Position = UDim2.new(0, 12, 0, 8)
    title.BackgroundTransparency = 1
    title.Text = "SEOUL HUB"
    title.TextColor3 = Theme.AccentGreen
    title.Font = Enum.Font.GothamBold
    title.TextSize = 12
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.TextTransparency = 1
    title.Parent = notif
    
    local msg = Instance.new("TextLabel")
    msg.Size = UDim2.new(1, -24, 0, 24)
    msg.Position = UDim2.new(0, 12, 0, 28)
    msg.BackgroundTransparency = 1
    msg.Text = text
    msg.TextColor3 = Theme.TextMain
    msg.Font = Enum.Font.GothamMedium
    msg.TextSize = 11
    msg.TextWrapped = true
    msg.TextXAlignment = Enum.TextXAlignment.Left
    msg.TextTransparency = 1
    msg.Parent = notif
    
    tween(notif, FastTween, {BackgroundTransparency = 0})
    tween(stroke, FastTween, {Transparency = 0.5})
    tween(title, FastTween, {TextTransparency = 0})
    tween(msg, FastTween, {TextTransparency = 0})
    
    task.delay(duration, function()
        tween(notif, FastTween, {BackgroundTransparency = 1})
        tween(stroke, FastTween, {Transparency = 1})
        tween(title, FastTween, {TextTransparency = 1})
        local outTween = tween(msg, FastTween, {TextTransparency = 1})
        outTween.Completed:Wait()
        notif:Destroy()
    end)
end

-- [[ HELPER FUNCTIONS FOR AUTO TAB ]]
local function TriggerEnterDungeon()
    pcall(function()
        local remote = ReplicatedStorage:FindFirstChild("PodPromptRequested", true)
        if remote then
            if typeof(firesignal) == "function" then
                firesignal(remote.OnClientEvent, "Dungeon")
            else
                local outgoingRemote = ReplicatedStorage:FindFirstChild("RequestSelectDungeon", true) 
                    or ReplicatedStorage:FindFirstChild("RequestParty", true)
                if outgoingRemote then
                    outgoingRemote:FireServer("Dungeon")
                end
            end
        end
    end)
end

local function GetCurrentDungeonFolder()
    for _, child in ipairs(workspace:GetChildren()) do
        if string.find(child.Name, "^Generated_") then
            return child
        end
    end
    return nil
end

local function GetClosestEnemy()
    local folder = GetCurrentDungeonFolder()
    if not folder or not folder:FindFirstChild("NPCs") then return nil end
    
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    
    local closest = nil
    local minDistance = math.huge

    for _, npc in ipairs(folder.NPCs:GetChildren()) do
        local hum = npc:FindFirstChildOfClass("Humanoid") or npc:FindFirstChild("Humanoid")
        local root = npc:FindFirstChild("HumanoidRootPart") or npc:FindFirstChild("Torso") or npc.PrimaryPart
        
        if not root then
            for _, part in ipairs(npc:GetChildren()) do
                if part:IsA("BasePart") then
                    root = part
                    break
                end
            end
        end

        local isAlive = hum and (hum.Health > 0) or (root ~= nil)

        if isAlive and root then
            if hrp then
                local dist = (root.Position - hrp.Position).Magnitude
                if dist < minDistance then
                    minDistance = dist
                    closest = npc
                end
            else
                return npc
            end
        end
    end
    
    return closest
end

-- [[ CHEST CACHE / BLACKLIST ]]
local ChestBlacklist = {}

local function GetValidChest(folder)
    for _, child in ipairs(folder:GetDescendants()) do
        if string.match(child.Name, "^DungeonChest_") or string.match(child.Name, "^Chest") then
            if ChestBlacklist[child] then continue end 
            
            local isLocked = false
            local parent = child.Parent
            
            while parent and parent ~= workspace do
                if string.match(parent.Name, "^Locked_") or string.match(parent.Name, "^Locked") then
                    isLocked = true
                    break
                end
                parent = parent.Parent
            end
            
            if not isLocked then
                local chestPart = child:IsA("Model") and child.PrimaryPart or child:FindFirstChildWhichIsA("BasePart") or (child:IsA("BasePart") and child)
                
                if chestPart and chestPart.Transparency < 1 then 
                    return child, chestPart 
                end
            end
        end
    end
    return nil, nil
end

-- Auto Tab
local TabAuto = createTab("Auto")

createSection(TabAuto, "Auto Dungeon")
createToggle(TabAuto, "Auto Dungeon", "AutoDungeon", "Automatically teleports, circles, and attacks nearby enemies in dungeons.")
createToggle(TabAuto, "Auto Collect Chest", "AutoCollectChest", "Collects physical chest drops after clearing room enemies.")
createToggle(TabAuto, "Auto Select Chest", "AutoSelectChest", "Selects reward chests at dungeon completion once all enemies are defeated.")
createToggle(TabAuto, "Auto Replay Dungeon", "AutoReplay", "Automatically replays after dungeon chest selection is completed.")
createToggle(TabAuto, "Auto Use Potion", "AutoUsePotion", "Uses a potion automatically when player health drops to 50% or lower.")

createSection(TabAuto, "Combat")
createToggle(TabAuto, "Auto Attack", "AutoAttack", "Automatically fires the attack action continuously.")

createSection(TabAuto, "Dungeon Navigation")
createButton(TabAuto, "Enter Dungeon", "Triggers the dungeon pod prompt.", function()
    TriggerEnterDungeon()
    SendHubNotification("Requested Dungeon Pod", 3)
end)

local TabPlayer = createTab("Player")

createSection(TabPlayer, "Movement")
local speedInputBox = createInput(TabPlayer, "Custom WalkSpeed", "WalkSpeed", true)

createButton(TabPlayer, "Apply Speed", "Applies custom WalkSpeed.", function()
    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.WalkSpeed = State.WalkSpeed
            SendHubNotification("WalkSpeed set to " .. tostring(State.WalkSpeed), 3)
        end
    end
end)

createButton(TabPlayer, "Reset Speed", "Resets WalkSpeed back to 16.", function()
    State.WalkSpeed = 16
    speedInputBox.Text = "16"
    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.WalkSpeed = 16
            SendHubNotification("WalkSpeed reset to standard 16.", 3)
        end
    end
end)

createSection(TabPlayer, "Abilities")
createToggle(TabPlayer, "Infinite Jump", "InfiniteJump", "Allows you to jump endlessly in mid-air.")

-- Settings
local TabSettings = createTab("Settings")
createPageHeader(TabSettings, "Settings", "Customize controls and configuration files.")

-- [[ CONFIGURATION MANAGEMENT ]]
createSection(TabSettings, "New Config")

local selectedConfigName = ""
createInput(TabSettings, "New Config Name", "NewConfigName", false)

local configDropdownContainer, updateConfigDropdown, configTitle

local function SaveCurrentConfig(targetName)
    EnsureFolders()
    local filePath = CONFIG_FOLDER .. "/" .. targetName .. ".json"
    local configData = {
        AntiAFK = State.AntiAFK,
        AutoReconnect = State.AutoReconnect,
        WalkSpeed = State.WalkSpeed,
        InfiniteJump = State.InfiniteJump,
        HideMenuKey = State.HideMenuKey.Name,

        AutoAttack = State.AutoAttack,
        InfiniteJump = State.InfiniteJump,
        AutoDungeon = State.AutoDungeon,
        AutoCollectChest = State.AutoCollectChest, 
        AutoSelectChest = State.AutoSelectChest, 
        AutoReplay = State.AutoReplay,
        AutoUsePotion = State.AutoUsePotion,
    }
    
    if writefile then
        local success, err = pcall(function()
            writefile(filePath, HttpService:JSONEncode(configData))
        end)
        return success, err
    end
    return false, "writefile not supported"
end

createButton(TabSettings, "Create Config", "Creates a new config file with the specified name.", function()
    local name = State.NewConfigName
    if not name or name:gsub("%s+", "") == "" then
        SendHubNotification("Please enter a valid config name!", 3)
        return
    end

    local success, err = SaveCurrentConfig(name)
    if success then
        selectedConfigName = name
        local currentList = GetConfigList()
        updateConfigDropdown(currentList)
        if configTitle then configTitle.Text = "Select Config - " .. name end
        SendHubNotification("Created config: " .. name, 3)
    else
        SendHubNotification("Failed to create config: " .. tostring(err), 3)
    end
end)

createSection(TabSettings, "Load Config")

local detectedConfigs = GetConfigList()
configDropdownContainer, updateConfigDropdown, configTitle = createDropdown(TabSettings, "Select Config", detectedConfigs, function(opt)
    selectedConfigName = opt
end)

createButton(TabSettings, "Overwrite Config", "Overwrites selected configuration with current settings.", function()
    if selectedConfigName == "" then
        SendHubNotification("No config selected to overwrite!", 3)
        return
    end
    local success, err = SaveCurrentConfig(selectedConfigName)
    if success then
        SendHubNotification("Overwrote config: " .. selectedConfigName, 3)
    else
        SendHubNotification("Failed to overwrite: " .. tostring(err), 3)
    end
end)

createButton(TabSettings, "Load Config", "Loads settings from selected configuration file.", function()
    if selectedConfigName == "" then
        SendHubNotification("No config selected to load!", 3)
        return
    end

    EnsureFolders()
    local filePath = CONFIG_FOLDER .. "/" .. selectedConfigName .. ".json"
    if isfile and isfile(filePath) and readfile then
        local success, data = pcall(function() return HttpService:JSONDecode(readfile(filePath)) end)
        if success and type(data) == "table" then
            for k, v in pairs(data) do
                if k == "AutoAttackKey" or k == "HideMenuKey" then
                    if type(v) == "string" and Enum.KeyCode[v] then
                        State[k] = Enum.KeyCode[v]
                    end
                else
                    State[k] = v
                end
            end
            UpdateAllUI()
            SendHubNotification("Loaded config: " .. selectedConfigName, 3)
        else
            SendHubNotification("Failed to load config file.", 3)
        end
    else
        SendHubNotification("Config file not found!", 3)
    end
end)

createButton(TabSettings, "Set Auto Load Config", "Sets selected configuration to load automatically on script execution.", function()
    if selectedConfigName == "" then
        SendHubNotification("No config selected for Auto Load!", 3)
        return
    end

    EnsureFolders()
    local autoLoadPath = CONFIG_FOLDER .. "/autoload.txt"
    if writefile then
        pcall(function() writefile(autoLoadPath, selectedConfigName) end)
        SendHubNotification("Auto Load set to: " .. selectedConfigName, 3)
    end
end)

createButton(TabSettings, "Delete Config", "Permanently deletes the selected configuration file.", function()
    if selectedConfigName == "" then
        SendHubNotification("No config selected to delete!", 3)
        return
    end

    EnsureFolders()
    local countBefore = #GetConfigList()
    local filePath = CONFIG_FOLDER .. "/" .. selectedConfigName .. ".json"

    if isfile and isfile(filePath) and delfile then
        pcall(function() delfile(filePath) end)
        SendHubNotification("Deleted config: " .. selectedConfigName, 3)

        local remainingList = GetConfigList()
        updateConfigDropdown(remainingList)

        selectedConfigName = ""
        if configTitle then configTitle.Text = "Select Config - None" end
    else
        SendHubNotification("Could not delete config or delfile not supported.", 3)
    end
end)

createSection(TabSettings, "Utility")
createToggle(TabSettings, "Anti AFK", "AntiAFK", "Prevents the game from kicking you for inactivity.")

createSection(TabSettings, "Keybinds")
createKeybind(TabSettings, "Hide / Show Menu", "HideMenuKey")

createSection(TabSettings, "Client")
createToggle(TabSettings, "Auto Reconnect", "AutoReconnect", "Automatically rejoins the server if you get disconnected.")

createButton(TabSettings, "Unload Script", "Unloads Seoul Hub from memory and removes GUI.", function()
    for _, conn in pairs(State.Connections) do conn:Disconnect() end
    ScreenGui:Destroy()
end)

-- [[ AUTO LOAD LOGIC ON STARTUP ]]
task.spawn(function()
    EnsureFolders()
    local autoLoadPath = CONFIG_FOLDER .. "/autoload.txt"
    if isfile and isfile(autoLoadPath) and readfile then
        local autoName = readfile(autoLoadPath)
        if autoName and autoName ~= "" then
            local filePath = CONFIG_FOLDER .. "/" .. autoName .. ".json"
            if isfile(filePath) then
                local success, data = pcall(function() return HttpService:JSONDecode(readfile(filePath)) end)
                if success and type(data) == "table" then
                    for k, v in pairs(data) do
                        if k == "AutoAttackKey" or k == "HideMenuKey" then
                            if type(v) == "string" and Enum.KeyCode[v] then
                                State[k] = Enum.KeyCode[v]
                            end
                        else
                            State[k] = v
                        end
                    end
                    UpdateAllUI()
                    SendHubNotification("Auto Loaded config: " .. autoName, 3)
                end
            end
        end
    end
end)

-- [[ GLOBAL KEYBINDS LOGIC ]]
table.insert(State.Connections, UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == State.HideMenuKey then
        ToggleMenu()
    elseif input.KeyCode == State.AutoAttackKey then
        State.AutoAttack = not State.AutoAttack; if UI.UpdateAutoAttack then UI.UpdateAutoAttack() end
    end
end))

-- [[ MAIN AUTOMATION LOOPS ]]

-- Infinite Jump Core Logic
table.insert(State.Connections, UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end 
    
    if State.InfiniteJump and input.KeyCode == Enum.KeyCode.Space then
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then
                hum:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end
    end
end))

-- Auto Attack Standard
task.spawn(function()
    while task.wait() do
        if State.AutoAttack and not State.AutoDungeon then
            pcall(function()
                game:GetService("ReplicatedStorage"):WaitForChild("Player"):WaitForChild("Remotes"):WaitForChild("Inputs"):WaitForChild("Attack"):FireServer(Vector3.zero)
            end)
        end
    end
end)

-- [[ AUTO USE POTION LOOP (AT <= 50% HP) ]]
task.spawn(function()
    while task.wait(1) do
        if State.AutoUsePotion then
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                local healthPercentage = hum.Health / hum.MaxHealth
                if healthPercentage <= 0.5 then
                    pcall(function()
                        local potionRF = ReplicatedStorage.Packages._Index["sleitnick_knit@1.7.0"].knit.Services.PotionService.RF.UsePotion
                        potionRF:InvokeServer()
                    end)
                end
            end
        end
    end
end)

-- [[ GLOBALS FOR AUTO DUNGEON ]]
local PreviousDungeon = nil
local CurrentRoomNumber = 2
local HasClaimedChest = false

-- [[ AUTO SELECT CHEST & AUTO REPLAY (ROOM DETECT LOOP) ]]
task.spawn(function()
    while task.wait(1.5) do
        if State.AutoDungeon and not HasClaimedChest then
            local folder = GetCurrentDungeonFolder()
            
            if folder then
                local currentEnemy = GetClosestEnemy()
                local nextRoomExists = folder:FindFirstChild("Room_" .. tostring(CurrentRoomNumber))
                
                -- Determine clear status: No alive enemies AND no next room to advance to
                if not currentEnemy and not nextRoomExists then
                    task.wait(1.5) -- Buffer to account for late spawns
                    
                    -- Second confirmation check
                    if not GetClosestEnemy() and State.AutoDungeon and not HasClaimedChest then
                        HasClaimedChest = true 
                        
                        local DungeonRunService = ReplicatedStorage.Packages._Index["sleitnick_knit@1.7.0"].knit.Services.DungeonRunService
                        
                        -- STEP 1: Select End-of-Dungeon Chest Reward
                        if State.AutoSelectChest then
                            pcall(function()
                                local Event = ReplicatedStorage.Packages._Index["sleitnick_knit@1.7.0"].knit.Services.DungeonRunService.RF.SelectChests
                                Event:InvokeServer({1, 2, 3})
                            end)
                            task.wait(2)
                        end
                        
                        -- STEP 2: Replay Dungeon
                        if State.AutoReplay then
                            pcall(function()
                                DungeonRunService.RF.RequestReplay:InvokeServer()
                            end)
                            SendHubNotification("Auto Replay Triggered!", 3)
                        end
                    end
                end
            end
        end
    end
end)

-- [[ ZERO-DELAY AUTO DUNGEON LOGIC V1.8 ]]
local orbitAngle = 0
local OrbitRadius = 6    
local OrbitHeight = 4.5  
local OrbitSpeed = 4   

local CurrentTarget = nil
local ActiveChestTimer = 0
local CurrentChestModel = nil

table.insert(State.Connections, RunService.Heartbeat:Connect(function(deltaTime)
    -- FIX: If Auto Dungeon is turned off, this ensures the tracker is fully reset. 
    -- Next time it turns on (or a config gets loaded), it won't be stuck thinking it already looted the chest.
    if not State.AutoDungeon then
        PreviousDungeon = nil
        HasClaimedChest = false 
        return
    end

    local char = LocalPlayer.Character
    local myHrp = char and char:FindFirstChild("HumanoidRootPart")
    if not myHrp then return end
    
    local folder = GetCurrentDungeonFolder()
    
    -- Reset variables for new dungeon instance
    if folder ~= PreviousDungeon then
        PreviousDungeon = folder
        CurrentRoomNumber = 2 
        CurrentTarget = nil
        ChestBlacklist = {}
        HasClaimedChest = false -- Crucial so we can collect the chest at the end of THIS new run
    end
    
    if not folder then return end

    -- [[ PRIORITY 1: ENEMIES ]]
    if CurrentTarget then
        local hum = CurrentTarget:FindFirstChildOfClass("Humanoid") or CurrentTarget:FindFirstChild("Humanoid")
        local root = CurrentTarget:FindFirstChild("HumanoidRootPart") or CurrentTarget:FindFirstChild("Torso") or CurrentTarget.PrimaryPart
        
        if (hum and hum.Health <= 0) or not root or not CurrentTarget.Parent then
            CurrentTarget = nil
        end
    end
    
    if not CurrentTarget then
        CurrentTarget = GetClosestEnemy()
    end
    
    if CurrentTarget then
        local targetHrp = CurrentTarget:FindFirstChild("HumanoidRootPart") or CurrentTarget:FindFirstChild("Torso") or CurrentTarget.PrimaryPart
        if targetHrp then
            orbitAngle = orbitAngle + (OrbitSpeed * deltaTime)
            local offset = Vector3.new(math.cos(orbitAngle) * OrbitRadius, OrbitHeight, math.sin(orbitAngle) * OrbitRadius)
            
            myHrp.CFrame = CFrame.new(targetHrp.Position + offset, targetHrp.Position)
            myHrp.Velocity = Vector3.zero 
            
            pcall(function()
                game:GetService("ReplicatedStorage"):WaitForChild("Player"):WaitForChild("Remotes"):WaitForChild("Inputs"):WaitForChild("Attack"):FireServer(Vector3.zero)
            end)
        end
        
    else
        -- [[ PRIORITY 2: PHYSICAL IN-ROOM CHESTS (AutoCollectChest) ]]
        local validChestModel, validChestPart = nil, nil
        if State.AutoCollectChest then
            validChestModel, validChestPart = GetValidChest(folder)
        end

        if validChestPart then
            if CurrentChestModel ~= validChestModel then
                CurrentChestModel = validChestModel
                ActiveChestTimer = tick()
            elseif tick() - ActiveChestTimer > 4 then
                ChestBlacklist[validChestModel] = true
                CurrentChestModel = nil
                validChestModel = nil
                validChestPart = nil
            end
            
            if validChestPart then
                local chestDist = (myHrp.Position - validChestPart.Position).Magnitude
                if chestDist > 4 then
                    myHrp.Velocity = Vector3.zero 
                    myHrp.CFrame = CFrame.new(validChestPart.Position + Vector3.new(0, 3, 0))
                else
                    pcall(function()
                        for _, obj in ipairs(validChestModel:GetDescendants()) do
                            if obj:IsA("ProximityPrompt") then
                                fireproximityprompt(obj)
                            end
                        end
                    end)
                end
            end
            
        else
            -- [[ PRIORITY 3: NEXT ROOM ]]
            CurrentChestModel = nil
            
            local nextRoom = folder:FindFirstChild("Room_" .. tostring(CurrentRoomNumber))
            
            if nextRoom then
                local roomPart = nextRoom:IsA("Model") and nextRoom.PrimaryPart or nextRoom:FindFirstChildWhichIsA("BasePart") or (nextRoom:IsA("BasePart") and nextRoom)
                
                if roomPart then
                    local roomDist = (myHrp.Position - roomPart.Position).Magnitude
                    
                    if roomDist > 15 then
                        myHrp.Velocity = Vector3.zero
                        myHrp.CFrame = CFrame.new(roomPart.Position + Vector3.new(0, 5, 0))
                    else
                        CurrentRoomNumber = CurrentRoomNumber + 1
                    end
                end
            end
        end
    end
end))

-- Anti AFK Logic
table.insert(State.Connections, LocalPlayer.Idled:Connect(function()
    if State.AntiAFK then
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end
end))

-- Auto Reconnect Logic
table.insert(State.Connections, GuiService.ErrorMessageChanged:Connect(function(err)
    if State.AutoReconnect then
        task.wait(1)
        pcall(function()
            TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
        end)
    end
end))

SendHubNotification("Seoul Hub Loaded Successfully!", 3)
