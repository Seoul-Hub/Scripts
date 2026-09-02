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
local AUTOEXEC_PATH = "Auto Execute/DungeonLootr-SeoulHub.lua"

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
    
    -- Client Variables
    AutoReconnect = false,
    AutoExecute = false,
    AntiAFK = false
}

-- Detect if already installed on startup for Auto Execute
if isfile and isfile(AUTOEXEC_PATH) then
    State.AutoExecute = true
end

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
        page.Position = UDim2.new(0, 10, 0, 0)
        page.GroupTransparency = 1
        tween(page, SlowTween, {Position = UDim2.new(0, 0, 0, 0), GroupTransparency = 0})
    end

    btn.MouseButton1Click:Connect(switchTab)
    Tabs[name] = page
    TabButtons[name] = btn
    TabMarkers[name] = marker
    TabLabels[name] = label
    
    if not State.CurrentTab then switchTab() end
    return page
end

local function createSection(parent, titleText)
    local section = Instance.new("Frame")
    section.Size = UDim2.new(1, 0, 0, 24)
    section.BackgroundTransparency = 1
    section.Parent = parent

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 1, -4)
    lbl.Position = UDim2.new(0, 4, 0, 4)
    lbl.BackgroundTransparency = 1
    lbl.Text = titleText:upper()
    lbl.TextColor3 = Theme.AccentCyan
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 10
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = section

    local div = Instance.new("Frame")
    div.Size = UDim2.new(1, -6, 0, 1)
    div.Position = UDim2.new(0, 4, 1, 2)
    div.BackgroundColor3 = Theme.Border
    div.BorderSizePixel = 0
    div.Parent = section
    
    local layout = parent:FindFirstChildOfClass("UIListLayout")
    if layout then layout:ApplyLayout() end
end

local function createToggle(parent, title, stateKey, desc)
    local card = Instance.new("TextButton")
    card.Size = UDim2.new(1, 0, 0, desc and 52 or 38)
    card.BackgroundColor3 = Theme.CardBg
    card.Text = ""
    card.AutoButtonColor = false
    card.Parent = parent
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 8)
    addStroke(card)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -70, 0, 16)
    lbl.Position = UDim2.new(0, 14, 0, desc and 10 or 11)
    lbl.BackgroundTransparency = 1
    lbl.Text = title
    lbl.TextColor3 = Theme.TextMain
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextSize = 13
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = card

    if desc then
        local sub = Instance.new("TextLabel")
        sub.Size = UDim2.new(1, -70, 0, 14)
        sub.Position = UDim2.new(0, 14, 0, 28)
        sub.BackgroundTransparency = 1
        sub.Text = desc
        sub.TextColor3 = Theme.TextMuted
        sub.Font = Enum.Font.Gotham
        sub.TextSize = 10
        sub.TextXAlignment = Enum.TextXAlignment.Left
        sub.Parent = card
    end

    local track = Instance.new("Frame")
    track.Size = UDim2.new(0, 36, 0, 20)
    track.Position = UDim2.new(1, -48, 0.5, -10)
    track.BackgroundColor3 = State[stateKey] and Theme.AccentGreen or Theme.Off
    track.Parent = card
    Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)
    
    local trackStroke = addStroke(track)

    local thumb = Instance.new("Frame")
    thumb.Size = UDim2.new(0, 14, 0, 14)
    thumb.Position = State[stateKey] and UDim2.new(0, 19, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)
    thumb.BackgroundColor3 = Color3.new(1,1,1)
    thumb.Parent = track
    Instance.new("UICorner", thumb).CornerRadius = UDim.new(1, 0)

    card.MouseEnter:Connect(function() tween(card, FastTween, {BackgroundColor3 = Theme.CardHover}) end)
    card.MouseLeave:Connect(function() tween(card, FastTween, {BackgroundColor3 = Theme.CardBg}) end)

    local function updateVisuals()
        local isOn = State[stateKey]
        tween(track, FastTween, {BackgroundColor3 = isOn and Theme.AccentGreen or Theme.Off})
        tween(thumb, FastTween, {Position = isOn and UDim2.new(0, 19, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)})
        trackStroke.Color = isOn and Theme.AccentGreenDark or Theme.Border
    end

    table.insert(UIUpdateCallbacks, updateVisuals)

    card.MouseButton1Down:Connect(function() tween(card, PressTween, {BackgroundColor3 = Theme.CardPressed}) end)
    card.MouseButton1Up:Connect(function()
        tween(card, FastTween, {BackgroundColor3 = Theme.CardHover})
        State[stateKey] = not State[stateKey]
        updateVisuals()
    end)
end

local function createSlider(parent, title, stateKey, min, max, isFloat, desc)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, 0, 0, desc and 72 or 58)
    card.BackgroundColor3 = Theme.CardBg
    card.Parent = parent
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 8)
    addStroke(card)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -70, 0, 16)
    lbl.Position = UDim2.new(0, 14, 0, desc and 10 or 11)
    lbl.BackgroundTransparency = 1
    lbl.Text = title
    lbl.TextColor3 = Theme.TextMain
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextSize = 13
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = card

    if desc then
        local sub = Instance.new("TextLabel")
        sub.Size = UDim2.new(1, -70, 0, 14)
        sub.Position = UDim2.new(0, 14, 0, 26)
        sub.BackgroundTransparency = 1
        sub.Text = desc
        sub.TextColor3 = Theme.TextMuted
        sub.Font = Enum.Font.Gotham
        sub.TextSize = 10
        sub.TextXAlignment = Enum.TextXAlignment.Left
        sub.Parent = card
    end

    local valBox = Instance.new("TextBox")
    valBox.Size = UDim2.new(0, 45, 0, 22)
    valBox.Position = UDim2.new(1, -59, 0, desc and 10 or 8)
    valBox.BackgroundColor3 = Theme.MainBg
    valBox.TextColor3 = Theme.TextMain
    valBox.Font = Enum.Font.GothamMedium
    valBox.TextSize = 11
    valBox.Text = tostring(State[stateKey])
    valBox.Parent = card
    Instance.new("UICorner", valBox).CornerRadius = UDim.new(0, 4)
    addStroke(valBox)

    local track = Instance.new("TextButton")
    track.Size = UDim2.new(1, -28, 0, 6)
    track.Position = UDim2.new(0, 14, 1, -16)
    track.BackgroundColor3 = Theme.Border
    track.Text = ""
    track.AutoButtonColor = false
    track.Parent = card
    Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new(0, 0, 1, 0)
    fill.BackgroundColor3 = Theme.AccentGreen
    fill.Parent = track
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

    local thumb = Instance.new("Frame")
    thumb.Size = UDim2.new(0, 14, 0, 14)
    thumb.Position = UDim2.new(1, -7, 0.5, -7)
    thumb.BackgroundColor3 = Color3.new(1,1,1)
    thumb.Parent = fill
    Instance.new("UICorner", thumb).CornerRadius = UDim.new(1, 0)
    addStroke(thumb, 0)

    local function updateUI(val)
        valBox.Text = isFloat and string.format("%.1f", val) or tostring(math.floor(val))
        local pct = math.clamp((val - min) / (max - min), 0, 1)
        tween(fill, FastTween, {Size = UDim2.new(pct, 0, 1, 0)})
    end
    updateUI(State[stateKey])

    table.insert(UIUpdateCallbacks, function() updateUI(State[stateKey]) end)

    local sliding = false
    track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then sliding = true end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then sliding = false end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if sliding and input.UserInputType == Enum.UserInputType.MouseMovement then
            local mx = math.clamp(input.Position.X - track.AbsolutePosition.X, 0, track.AbsoluteSize.X)
            local pct = mx / track.AbsoluteSize.X
            local val = min + (max - min) * pct
            val = isFloat and math.floor(val * 10)/10 or math.floor(val)
            State[stateKey] = val
            updateUI(val)
        end
    end)

    valBox.FocusLost:Connect(function()
        local num = tonumber(valBox.Text)
        if num then
            num = math.clamp(num, min, max)
            State[stateKey] = num
            updateUI(num)
        else
            updateUI(State[stateKey])
        end
    end)
end

local function createKeybind(parent, title, stateKey, desc)
    local card = Instance.new("TextButton")
    card.Size = UDim2.new(1, 0, 0, desc and 52 or 38)
    card.BackgroundColor3 = Theme.CardBg
    card.Text = ""
    card.AutoButtonColor = false
    card.Parent = parent
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 8)
    addStroke(card)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -120, 0, 16)
    lbl.Position = UDim2.new(0, 14, 0, desc and 10 or 11)
    lbl.BackgroundTransparency = 1
    lbl.Text = title
    lbl.TextColor3 = Theme.TextMain
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextSize = 13
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = card

    if desc then
        local sub = Instance.new("TextLabel")
        sub.Size = UDim2.new(1, -120, 0, 14)
        sub.Position = UDim2.new(0, 14, 0, 28)
        sub.BackgroundTransparency = 1
        sub.Text = desc
        sub.TextColor3 = Theme.TextMuted
        sub.Font = Enum.Font.Gotham
        sub.TextSize = 10
        sub.TextXAlignment = Enum.TextXAlignment.Left
        sub.Parent = card
    end

    local bindBtn = Instance.new("TextButton")
    bindBtn.Size = UDim2.new(0, 90, 0, 24)
    bindBtn.Position = UDim2.new(1, -104, 0.5, -12)
    bindBtn.BackgroundColor3 = Theme.MainBg
    bindBtn.TextColor3 = Theme.AccentCyan
    bindBtn.Font = Enum.Font.GothamMedium
    bindBtn.TextSize = 11
    bindBtn.Text = State[stateKey].Name
    bindBtn.Parent = card
    Instance.new("UICorner", bindBtn).CornerRadius = UDim.new(0, 6)
    addStroke(bindBtn)

    card.MouseEnter:Connect(function() tween(card, FastTween, {BackgroundColor3 = Theme.CardHover}) end)
    card.MouseLeave:Connect(function() tween(card, FastTween, {BackgroundColor3 = Theme.CardBg}) end)

    local listening = false
    bindBtn.MouseButton1Click:Connect(function()
        listening = true
        bindBtn.Text = "..."
        bindBtn.TextColor3 = Theme.Danger
    end)

    table.insert(UIUpdateCallbacks, function()
        bindBtn.Text = State[stateKey].Name
        bindBtn.TextColor3 = Theme.AccentCyan
    end)

    UserInputService.InputBegan:Connect(function(input)
        if listening and input.UserInputType == Enum.UserInputType.Keyboard then
            State[stateKey] = input.KeyCode
            listening = false
            bindBtn.Text = State[stateKey].Name
            bindBtn.TextColor3 = Theme.AccentCyan
        end
    end)
end

local function createButton(parent, title, desc, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, desc and 52 or 38)
    btn.BackgroundColor3 = Theme.CardBg
    btn.Text = ""
    btn.AutoButtonColor = false
    btn.Parent = parent
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
    addStroke(btn)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -40, 0, 16)
    lbl.Position = UDim2.new(0, 14, 0, desc and 10 or 11)
    lbl.BackgroundTransparency = 1
    lbl.Text = title
    lbl.TextColor3 = Theme.AccentGreen
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 13
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = btn

    if desc then
        local sub = Instance.new("TextLabel")
        sub.Size = UDim2.new(1, -40, 0, 14)
        sub.Position = UDim2.new(0, 14, 0, 28)
        sub.BackgroundTransparency = 1
        sub.Text = desc
        sub.TextColor3 = Theme.TextMuted
        sub.Font = Enum.Font.Gotham
        sub.TextSize = 10
        sub.TextXAlignment = Enum.TextXAlignment.Left
        sub.Parent = btn
    end

    local arrow = Instance.new("TextLabel")
    arrow.Size = UDim2.new(0, 20, 0, 20)
    arrow.Position = UDim2.new(1, -30, 0.5, -10)
    arrow.BackgroundTransparency = 1
    arrow.Text = "›"
    arrow.TextColor3 = Theme.TextDim
    arrow.Font = Enum.Font.GothamMedium
    arrow.TextSize = 24
    arrow.Parent = btn

    btn.MouseEnter:Connect(function() 
        tween(btn, FastTween, {BackgroundColor3 = Theme.CardHover}) 
        tween(arrow, FastTween, {Position = UDim2.new(1, -25, 0.5, -10), TextColor3 = Theme.AccentGreen})
    end)
    btn.MouseLeave:Connect(function() 
        tween(btn, FastTween, {BackgroundColor3 = Theme.CardBg}) 
        tween(arrow, FastTween, {Position = UDim2.new(1, -30, 0.5, -10), TextColor3 = Theme.TextDim})
    end)

    btn.MouseButton1Down:Connect(function() tween(btn, PressTween, {BackgroundColor3 = Theme.CardPressed}) end)
    btn.MouseButton1Up:Connect(function()
        tween(btn, FastTween, {BackgroundColor3 = Theme.CardHover})
        pcall(callback)
    end)
end

local NotificationUI = Instance.new("ScreenGui")
NotificationUI.Name = "Seoul_Notifications"
NotificationUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
NotificationUI.Parent = successGui and coreGui or LocalPlayer:WaitForChild("PlayerGui")

local NotifList = Instance.new("Frame")
NotifList.Size = UDim2.new(0, 300, 1, -40)
NotifList.Position = UDim2.new(1, -320, 0, 20)
NotifList.BackgroundTransparency = 1
NotifList.Parent = NotificationUI

local NotifLayout = Instance.new("UIListLayout")
NotifLayout.Padding = UDim.new(0, 10)
NotifLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
NotifLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
NotifLayout.SortOrder = Enum.SortOrder.LayoutOrder
NotifLayout.Parent = NotifList

local function SendHubNotification(msg, duration)
    duration = duration or 3
    local f = Instance.new("Frame")
    f.Size = UDim2.new(0, 280, 0, 50)
    f.BackgroundColor3 = Theme.CardBg
    f.BackgroundTransparency = 1
    f.Parent = NotifList
    Instance.new("UICorner", f).CornerRadius = UDim.new(0, 8)
    
    local str = Instance.new("UIStroke")
    str.Color = Theme.Border
    str.Transparency = 1
    str.Thickness = 1
    str.Parent = f

    local band = Instance.new("Frame")
    band.Size = UDim2.new(0, 4, 1, 0)
    band.BackgroundColor3 = Theme.AccentGreen
    band.BackgroundTransparency = 1
    band.BorderSizePixel = 0
    band.Parent = f
    Instance.new("UICorner", band).CornerRadius = UDim.new(0, 8)

    local txt = Instance.new("TextLabel")
    txt.Size = UDim2.new(1, -20, 1, 0)
    txt.Position = UDim2.new(0, 14, 0, 0)
    txt.BackgroundTransparency = 1
    txt.Text = msg
    txt.TextColor3 = Theme.TextMain
    txt.TextTransparency = 1
    txt.Font = Enum.Font.GothamMedium
    txt.TextSize = 12
    txt.TextWrapped = true
    txt.TextXAlignment = Enum.TextXAlignment.Left
    txt.Parent = f

    tween(f, SlowTween, {BackgroundTransparency = 0})
    tween(str, SlowTween, {Transparency = 0.2})
    tween(band, SlowTween, {BackgroundTransparency = 0})
    tween(txt, SlowTween, {TextTransparency = 0})

    task.delay(duration, function()
        tween(f, FastTween, {BackgroundTransparency = 1})
        tween(str, FastTween, {Transparency = 1})
        tween(band, FastTween, {BackgroundTransparency = 1})
        local t = tween(txt, FastTween, {TextTransparency = 1})
        t.Completed:Connect(function() f:Destroy() end)
    end)
end

-- [[ CONFIG SYSTEM ]]
local SaveConfigBox, ConfigDropdown
local ActiveConfigFrame = nil 

local function SaveCurrentConfig(name)
    if not writefile then SendHubNotification("Executor does not support writefile.") return end
    name = name:gsub("[^%w%-_]", "")
    if name == "" then name = "Default" end
    
    local configData = {
        AntiAFK = State.AntiAFK,
        AutoReconnect = State.AutoReconnect,
        WalkSpeed = State.WalkSpeed,
        InfiniteJump = State.InfiniteJump,
        HideMenuKey = State.HideMenuKey.Name,

        AutoAttack = State.AutoAttack,
        AutoDungeon = State.AutoDungeon,
        AutoCollectChest = State.AutoCollectChest, 
        AutoSelectChest = State.AutoSelectChest, 
        AutoReplay = State.AutoReplay,
        AutoUsePotion = State.AutoUsePotion,
        AutoExecute = State.AutoExecute
    }

    local json = HttpService:JSONEncode(configData)
    local path = CONFIG_FOLDER .. "/" .. name .. ".json"
    
    local s, err = pcall(function() writefile(path, json) end)
    if s then 
        SendHubNotification("Saved config: " .. name, 2)
    else
        SendHubNotification("Failed to save config: " .. tostring(err))
    end
end

local function LoadConfig(name)
    if not readfile then return end
    local path = CONFIG_FOLDER .. "/" .. name .. ".json"
    if not isfile or not isfile(path) then return end
    
    local s, content = pcall(function() return readfile(path) end)
    if not s or not content then return end

    local s2, data = pcall(function() return HttpService:JSONDecode(content) end)
    if s2 and type(data) == "table" then
        for k, v in pairs(data) do
            if State[k] ~= nil then
                if k == "HideMenuKey" then
                    pcall(function() State[k] = Enum.KeyCode[v] end)
                else
                    State[k] = v
                end
            end
        end
        UpdateAllUI()
        SendHubNotification("Loaded config: " .. name, 2)
    end
end

local function BuildConfigListUI(parent)
    if ActiveConfigFrame then ActiveConfigFrame:Destroy() end
    local listContainer = Instance.new("Frame")
    listContainer.Size = UDim2.new(1, 0, 0, 150) 
    listContainer.BackgroundTransparency = 1
    listContainer.Parent = parent
    ActiveConfigFrame = listContainer
    
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 6)
    layout.Parent = listContainer
    
    local list = GetConfigList()
    if #list == 0 then
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, 0, 0, 20)
        lbl.BackgroundTransparency = 1
        lbl.Text = "No configurations found."
        lbl.TextColor3 = Theme.TextMuted
        lbl.Font = Enum.Font.Gotham
        lbl.TextSize = 11
        lbl.Parent = listContainer
    else
        for _, cfg in ipairs(list) do
            local cfgRow = Instance.new("Frame")
            cfgRow.Size = UDim2.new(1, 0, 0, 32)
            cfgRow.BackgroundColor3 = Theme.CardBg
            cfgRow.Parent = listContainer
            Instance.new("UICorner", cfgRow).CornerRadius = UDim.new(0, 6)
            
            local lbl = Instance.new("TextLabel")
            lbl.Size = UDim2.new(1, -70, 1, 0)
            lbl.Position = UDim2.new(0, 10, 0, 0)
            lbl.BackgroundTransparency = 1
            lbl.Text = cfg
            lbl.TextColor3 = Theme.TextMain
            lbl.Font = Enum.Font.GothamMedium
            lbl.TextSize = 12
            lbl.TextXAlignment = Enum.TextXAlignment.Left
            lbl.Parent = cfgRow

            local loadBtn = Instance.new("TextButton")
            loadBtn.Size = UDim2.new(0, 50, 0, 22)
            loadBtn.Position = UDim2.new(1, -60, 0.5, -11)
            loadBtn.BackgroundColor3 = Theme.MainBg
            loadBtn.TextColor3 = Theme.AccentGreen
            loadBtn.Text = "Load"
            loadBtn.Font = Enum.Font.GothamBold
            loadBtn.TextSize = 10
            loadBtn.Parent = cfgRow
            Instance.new("UICorner", loadBtn).CornerRadius = UDim.new(0, 4)
            addStroke(loadBtn)
            
            loadBtn.MouseButton1Click:Connect(function()
                LoadConfig(cfg)
            end)
        end
    end
end

-- [[ TABS & ELEMENTS ]]
local TabMain = createTab("Main")
local TabAuto = createTab("Auto Farming")
local TabSettings = createTab("Settings")

-- Main Tab
createSection(TabMain, "Character")
createToggle(TabMain, "Infinite Jump", "InfiniteJump", "Allows you to jump endlessly.")
createSlider(TabMain, "Walk Speed", "WalkSpeed", 16, 120, false, "Sets your character's walking speed.")
createButton(TabMain, "Redeem All Codes", "Automatically attempts to claim all known codes.", function()
    SendHubNotification("Attempting to redeem codes...")
    local codes = {"dungeon", "1KLIKES", "500LIKES"}
    for _, code in ipairs(codes) do
        ReplicatedStorage.RemoteEvents.RedeemCode:FireServer(code)
        task.wait(0.5)
    end
    SendHubNotification("Finished redeeming codes.")
end)

-- Auto Farming Tab
createSection(TabAuto, "Automation")
createToggle(TabAuto, "Auto Dungeon", "AutoDungeon", "Automatically attacks and progresses through dungeons without delay.")
createToggle(TabAuto, "Auto Replay Dungeon", "AutoReplay", "Automatically rejoins the previous dungeon/portal when finished.")
createToggle(TabAuto, "Auto Use Health Potions", "AutoUsePotion", "Automatically uses potions if health drops below 50%.")

createSection(TabAuto, "Rewards")
createToggle(TabAuto, "Auto Collect Drops", "AutoCollectChest", "Magnetizes drops and bags to your character instantly.")
createToggle(TabAuto, "Auto Select Chest", "AutoSelectChest", "Automatically opens reward chests at the end of a dungeon.")

-- Settings Tab
createSection(TabSettings, "User Interface")
createKeybind(TabSettings, "Toggle Menu Key", "HideMenuKey", "Press this key to hide or show the interface.")

createSection(TabSettings, "Configurations")

local ConfigNameBox = Instance.new("TextBox")
ConfigNameBox.Size = UDim2.new(1, 0, 0, 38)
ConfigNameBox.BackgroundColor3 = Theme.MainBg
ConfigNameBox.TextColor3 = Theme.TextMain
ConfigNameBox.PlaceholderText = "Enter configuration name..."
ConfigNameBox.Font = Enum.Font.GothamMedium
ConfigNameBox.TextSize = 12
ConfigNameBox.Text = ""
ConfigNameBox.Parent = TabSettings
Instance.new("UICorner", ConfigNameBox).CornerRadius = UDim.new(0, 6)
addStroke(ConfigNameBox)

createButton(TabSettings, "Save Configuration", "Saves current settings under the above name.", function()
    local t = ConfigNameBox.Text
    SaveCurrentConfig(t ~= "" and t or "Default")
    BuildConfigListUI(TabSettings) 
end)

createSection(TabSettings, "Saved Configs")
BuildConfigListUI(TabSettings) 

createSection(TabSettings, "Client")
createToggle(TabSettings, "Anti AFK", "AntiAFK", "Prevents Roblox from kicking you for being idle.")
createToggle(TabSettings, "Auto Reconnect", "AutoReconnect", "Automatically rejoins the server if you get disconnected.")
createToggle(TabSettings, "Auto Execute", "AutoExecute", "Automatically saves or removes the script in Madium's Auto Execute folder.")
createButton(TabSettings, "Unload Script", "Unloads Seoul Hub from memory and removes GUI.", function()
    for _, conn in pairs(State.Connections) do conn:Disconnect() end
    ScreenGui:Destroy()
    NotificationUI:Destroy()
end)


-- [[ AUTO EXECUTE TOGGLE HANDLER ]]
local lastAutoExecState = State.AutoExecute
table.insert(State.Connections, RunService.Heartbeat:Connect(function()
    if State.AutoExecute ~= lastAutoExecState then
        lastAutoExecState = State.AutoExecute
        
        if State.AutoExecute then
            -- Enable Logic: Create file
            if writefile then
                local success, err = pcall(function()
                    local loadstringCode = "loadstring(game:HttpGet('https://raw.githubusercontent.com/Seoul-Hub/Scripts/refs/heads/main/DungeonLootr.lua'))()"
                    if makefolder and isfolder and not isfolder("Auto Execute") then
                        makefolder("Auto Execute")
                    end
                    writefile(AUTOEXEC_PATH, loadstringCode)
                end)
                
                if success then
                    SendHubNotification("Auto Execute Enabled & File Saved!", 3)
                else
                    SendHubNotification("Failed to write file: " .. tostring(err), 3)
                    State.AutoExecute = false
                    UpdateAllUI()
                end
            else
                SendHubNotification("Your executor does not support writefile.", 3)
                State.AutoExecute = false
                UpdateAllUI()
            end
        else
            -- Disable Logic: Delete file
            if isfile and isfile(AUTOEXEC_PATH) and delfile then
                pcall(function() delfile(AUTOEXEC_PATH) end)
                SendHubNotification("Auto Execute Disabled & File Removed!", 3)
            end
        end
    end
end))

-- [[ BACKGROUND TASKS & CONNECTIONS ]]

-- Hide Menu Keybind
table.insert(State.Connections, UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and input.KeyCode == State.HideMenuKey then ToggleMenu() end
end))

-- Anti AFK Handler
table.insert(State.Connections, LocalPlayer.Idled:Connect(function()
    if State.AntiAFK then
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new(0, 0))
    end
end))

-- Auto Reconnect Handler
table.insert(State.Connections, GuiService.ErrorMessageChanged:Connect(function()
    if State.AutoReconnect then
        SendHubNotification("Disconnected! Rejoining...", 5)
        task.wait(2)
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
    end
end))

-- Infinite Jump Hook
table.insert(State.Connections, UserInputService.JumpRequest:Connect(function()
    if State.InfiniteJump and LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
        LocalPlayer.Character:FindFirstChildOfClass("Humanoid"):ChangeState(Enum.HumanoidStateType.Jumping)
    end
end))

-- WalkSpeed Mod
table.insert(State.Connections, RunService.Stepped:Connect(function()
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("Humanoid") then
        local hum = char.Humanoid
        if hum.WalkSpeed ~= State.WalkSpeed then
            hum.WalkSpeed = State.WalkSpeed
        end
    end
end))

-- Potions Loop
task.spawn(function()
    while task.wait(1) do
        if State.AutoUsePotion then
            local char = LocalPlayer.Character
            if char and char:FindFirstChild("Humanoid") then
                local hum = char.Humanoid
                if hum.Health > 0 and hum.Health < (hum.MaxHealth * 0.5) then
                    ReplicatedStorage.RemoteEvents.UsePotion:FireServer()
                end
            end
        end
    end
end)

-- Drops / Loot Loop
task.spawn(function()
    while task.wait(0.2) do
        if State.AutoCollectChest then
            local char = LocalPlayer.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                local hrp = char.HumanoidRootPart
                for _, obj in pairs(workspace:GetDescendants()) do
                    if obj:IsA("Part") and (obj.Name == "Coin" or obj.Name == "Gem" or obj.Name == "LootBag") then
                        obj.CFrame = hrp.CFrame
                    end
                end
            end
        end
    end
end)

-- [[ ZERO-DELAY AUTO DUNGEON LOGIC ]]
local CurrentTarget = nil
local PreviousDungeon = nil
local HasClaimedChest = false
local ChestBlacklist = {}
local orbitAngle = 0
local ORBIT_SPEED = 18 
local ORBIT_DISTANCE = 5 
local FAST_TP_OFFSET = CFrame.new(0, 0, -4) 
local CHEST_ORBIT_DISTANCE = 3 

local function getClosestEnemy(folder)
    if not folder then return nil end
    local closest, minDistance = nil, math.huge
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return nil end

    for _, obj in pairs(folder:GetChildren()) do
        if obj.Name == "Mob" and obj:FindFirstChild("Humanoid") and obj.Humanoid.Health > 0 and obj:FindFirstChild("HumanoidRootPart") then
            local dist = (char.HumanoidRootPart.Position - obj.HumanoidRootPart.Position).Magnitude
            if dist < minDistance then
                closest = obj
                minDistance = dist
            end
        end
    end
    return closest
end

-- Dungeon Heartbeat Loop
table.insert(State.Connections, RunService.Heartbeat:Connect(function(dt)
    -- RESET STATE IF TOGGLED OFF (Fixes state bug when loading configs)
    if not State.AutoDungeon then 
        CurrentTarget = nil
        PreviousDungeon = nil
        HasClaimedChest = false
        ChestBlacklist = {}
        return 
    end

    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    local hrp = char.HumanoidRootPart

    local activeDungeons = workspace:FindFirstChild("ActiveDungeons")
    if not activeDungeons then return end

    local folder = nil
    for _, f in pairs(activeDungeons:GetChildren()) do
        if f:FindFirstChild(LocalPlayer.Name) then 
            folder = f 
            break 
        end
    end

    if folder then
        if folder ~= PreviousDungeon then
            PreviousDungeon = folder
            HasClaimedChest = false 
            ChestBlacklist = {}
        end

        local currentEnemy = getClosestEnemy(folder)
        if currentEnemy and currentEnemy:FindFirstChild("HumanoidRootPart") then
            orbitAngle = (orbitAngle + ORBIT_SPEED * dt) % (math.pi * 2)
            local enemyPos = currentEnemy.HumanoidRootPart.Position
            local orbitOffset = Vector3.new(math.cos(orbitAngle) * ORBIT_DISTANCE, 2, math.sin(orbitAngle) * ORBIT_DISTANCE)
            
            hrp.CFrame = CFrame.new(enemyPos + orbitOffset, enemyPos)
            CurrentTarget = currentEnemy

            if tick() % 0.1 < 0.05 then
                ReplicatedStorage.RemoteEvents.Attack:FireServer()
            end
        else
            CurrentTarget = nil
            local portal = folder:FindFirstChild("NextPortal")
            if portal and portal:FindFirstChild("TouchInterest") then
                hrp.CFrame = portal.CFrame
                firetouchinterest(hrp, portal, 0)
                firetouchinterest(hrp, portal, 1)
            end
        end
    end
end))

-- [[ AUTO SELECT CHEST & AUTO REPLAY (ROOM DETECT LOOP) ]]
task.spawn(function()
    while task.wait(1.5) do
        -- Reset if completely disabled 
        if not State.AutoDungeon then
            HasClaimedChest = false
            continue
        end

        local activeDungeons = workspace:FindFirstChild("ActiveDungeons")
        if not activeDungeons then continue end
        
        local folder = nil
        for _, f in pairs(activeDungeons:GetChildren()) do
            if f:FindFirstChild(LocalPlayer.Name) then folder = f break end
        end

        if folder then
            if State.AutoSelectChest and not HasClaimedChest then
                local foundChest = false
                for _, obj in pairs(folder:GetDescendants()) do
                    if obj.Name == "RewardChest" and obj:FindFirstChild("RootPart") and not ChestBlacklist[obj] then
                        foundChest = true
                        ChestBlacklist[obj] = true 

                        local char = LocalPlayer.Character
                        if char and char:FindFirstChild("HumanoidRootPart") then
                            local hrp = char.HumanoidRootPart
                            local chestPos = obj.RootPart.Position
                            hrp.CFrame = CFrame.new(chestPos + Vector3.new(0, CHEST_ORBIT_DISTANCE, 0), chestPos)
                            
                            ReplicatedStorage.RemoteFunctions.SelectReward:InvokeServer(obj)
                            HasClaimedChest = true
                            SendHubNotification("Chest claimed!")
                            task.wait(1.5)
                        end
                        break 
                    end
                end
            end
            
            if State.AutoReplay and folder:FindFirstChild("Finished") then
                local endPortal = workspace:FindFirstChild("ReturnPortal") or folder:FindFirstChild("Portal")
                if endPortal and endPortal:FindFirstChild("TouchInterest") then
                    local char = LocalPlayer.Character
                    if char and char:FindFirstChild("HumanoidRootPart") then
                        firetouchinterest(char.HumanoidRootPart, endPortal, 0)
                        firetouchinterest(char.HumanoidRootPart, endPortal, 1)
                        SendHubNotification("Replaying Dungeon...")
                    end
                end
            end
        end
    end
end)

SendHubNotification("Seoul Hub Loaded Successfully!", 3)
