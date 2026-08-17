-- [[ VARIABLES & SERVICES ]]
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- [[ STATE MANAGEMENT ]]
local getgenv = getgenv or function() return _G end
if getgenv().SeoulHub then getgenv().SeoulHub:Destroy() end -- Unload previous instance

local State = {
    AutoAttack = false,
    AutoRespawn = false,
    AutoChop = false,
    AutoMine = false, 
    AutoPlaytime = false,
    AutoAlltime = false,
    AutoBattlepass = false,
    MenuVisible = true,
    AutoAttackKey = Enum.KeyCode.F1,
    HideMenuKey = Enum.KeyCode.CapsLock,
    AttackRange = 5, 
    Connections = {},
    CurrentTab = nil
}
local UI = {}

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

local success, coreGui = pcall(function() return game:GetService("CoreGui") end)
ScreenGui.Parent = success and coreGui or LocalPlayer:WaitForChild("PlayerGui")
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
VersionText.Text = "THE PORTAL  •  v1.0"
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
TabListLayout.Padding = UDim.new(0, 6)
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
SidebarHint.Position = UDim2.new(0, 0, 1, -26)
SidebarHint.BackgroundTransparency = 1
SidebarHint.Text = "CAPS  •  Hide / Show"
SidebarHint.TextColor3 = Theme.TextMuted
SidebarHint.Font = Enum.Font.Gotham
SidebarHint.TextSize = 9
SidebarHint.TextXAlignment = Enum.TextXAlignment.Left
SidebarHint.Parent = Sidebar

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

-- Dragging Logic for Main Window
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
local Tabs, TabButtons, TabMarkers, TabIcons, TabLabels = {}, {}, {}, {}, {}

local function addStroke(parent, transparency)
    local stroke = Instance.new("UIStroke")
    stroke.Color = Theme.Border
    stroke.Transparency = transparency or 0.42
    stroke.Thickness = 1
    stroke.Parent = parent
    return stroke
end

local function createTab(name, icon)
    icon = icon or "•"
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 42)
    btn.BackgroundColor3 = Theme.SidebarBg
    btn.Text = ""
    btn.AutoButtonColor = false
    btn.Parent = TabList
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 9)

    local iconLabel = Instance.new("TextLabel")
    iconLabel.Size = UDim2.new(0, 26, 1, 0)
    iconLabel.Position = UDim2.new(0, 10, 0, 0)
    iconLabel.BackgroundTransparency = 1
    iconLabel.Text = icon
    iconLabel.TextColor3 = Theme.TextDim
    iconLabel.Font = Enum.Font.GothamBold
    iconLabel.TextSize = 18
    iconLabel.Parent = btn

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -48, 1, 0)
    label.Position = UDim2.new(0, 40, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = Theme.TextDim
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = btn

    local marker = Instance.new("Frame")
    marker.Size = UDim2.new(0, 3, 0, 18)
    marker.Position = UDim2.new(0, 0, 0.5, -9)
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
            tween(iconLabel, FastTween, {TextColor3 = Theme.AccentGreen})
            marker.Visible = true
        end
    end

    btn.MouseEnter:Connect(function()
        if State.CurrentTab ~= name then
            tween(btn, FastTween, {BackgroundColor3 = Color3.fromRGB(17, 20, 24)})
            tween(iconLabel, FastTween, {TextColor3 = Theme.TextMain})
        end
    end)
    btn.MouseLeave:Connect(function()
        if State.CurrentTab ~= name then
            tween(btn, FastTween, {BackgroundColor3 = Theme.SidebarBg})
            tween(iconLabel, FastTween, {TextColor3 = Theme.TextDim})
        end
    end)

    local function switchTab()
        if State.CurrentTab and State.CurrentTab ~= name then
            local oldPage = Tabs[State.CurrentTab]
            if oldPage then oldPage.Visible = false end
            
            if TabButtons[State.CurrentTab] then tween(TabButtons[State.CurrentTab], FastTween, {BackgroundColor3 = Theme.SidebarBg}) end
            if TabLabels[State.CurrentTab] then tween(TabLabels[State.CurrentTab], FastTween, {TextColor3 = Theme.TextDim}) end
            if TabIcons[State.CurrentTab] then tween(TabIcons[State.CurrentTab], FastTween, {TextColor3 = Theme.TextDim}) end
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
        tween(btn, PressTween, {Size = UDim2.new(1, -3, 0, 40)})
        task.delay(0.08, function() tween(btn, PressTween, {Size = UDim2.new(1, 0, 0, 42)}) end)
        switchTab()
    end)

    Tabs[name] = page
    TabButtons[name] = btn
    TabMarkers[name] = marker
    TabIcons[name] = iconLabel
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

local function createFeatureCard(parent, name, description, stateKey, bindKey)
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
        keyButton.Text = "[" .. State[bindKey].Name .. "]"
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
    end

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

local function createToggle(parent, name, stateKey, description)
    return createFeatureCard(parent, name, description or "Toggle this feature on or off.", stateKey)
end

local function createToggleWithBind(parent, name, stateKey, bindKey, description)
    return createFeatureCard(parent, name, description or "Toggle this feature with a custom keybind.", stateKey, bindKey)
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
    inputBg.Size = UDim2.new(0, 70, 0, 28)
    inputBg.Position = UDim2.new(1, -85, 0.5, -14)
    inputBg.BackgroundColor3 = Theme.SidebarBg
    inputBg.Parent = card
    Instance.new("UICorner", inputBg).CornerRadius = UDim.new(0, 6)
    addStroke(inputBg, 0.6)

    local textBox = Instance.new("TextBox")
    textBox.Size = UDim2.new(1, 0, 1, 0)
    textBox.BackgroundTransparency = 1
    textBox.Text = tostring(State[stateKey])
    textBox.TextColor3 = Theme.TextDim
    textBox.Font = Enum.Font.GothamBold
    textBox.TextSize = 12
    textBox.ClearTextOnFocus = false
    textBox.Parent = inputBg

    textBox.FocusLost:Connect(function()
        local val = textBox.Text
        if isNumber then
            val = tonumber(val) or State[stateKey]
            textBox.Text = tostring(val)
        end
        State[stateKey] = val
    end)
end

local function createButton(parent, name, callback, icon)
    local card = Instance.new("TextButton")
    card.Size = UDim2.new(1, -2, 0, 52)
    card.BackgroundColor3 = Theme.CardBg
    card.Text = ""
    card.AutoButtonColor = false
    card.Parent = parent
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 10)
    local stroke = addStroke(card, 0.58)

    local iconLabel = Instance.new("TextLabel")
    iconLabel.Size = UDim2.new(0, 30, 0, 30)
    iconLabel.Position = UDim2.new(0, 11, 0.5, -15)
    iconLabel.BackgroundColor3 = Color3.fromRGB(28, 33, 39)
    iconLabel.Text = icon or "→"
    iconLabel.TextColor3 = Theme.AccentGreen
    iconLabel.Font = Enum.Font.GothamBold
    iconLabel.TextSize = 12
    iconLabel.Parent = card
    Instance.new("UICorner", iconLabel).CornerRadius = UDim.new(0, 8)

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -88, 1, 0)
    label.Position = UDim2.new(0, 52, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = Theme.TextMain
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = card

    local arrow = Instance.new("TextLabel")
    arrow.Size = UDim2.new(0, 24, 1, 0)
    arrow.Position = UDim2.new(1, -34, 0, 0)
    arrow.BackgroundTransparency = 1
    arrow.Text = "›"
    arrow.TextColor3 = Theme.TextMuted
    arrow.Font = Enum.Font.GothamBold
    arrow.TextSize = 20
    arrow.Parent = card

    card.MouseEnter:Connect(function()
        tween(card, FastTween, {BackgroundColor3 = Theme.CardHover})
        tween(stroke, FastTween, {Color = Theme.AccentGreen, Transparency = 0.72})
        tween(arrow, FastTween, {TextColor3 = Theme.AccentGreen, Position = UDim2.new(1, -31, 0, 0)})
    end)
    card.MouseLeave:Connect(function()
        tween(card, FastTween, {BackgroundColor3 = Theme.CardBg})
        tween(stroke, FastTween, {Color = Theme.Border, Transparency = 0.58})
        tween(arrow, FastTween, {TextColor3 = Theme.TextMuted, Position = UDim2.new(1, -34, 0, 0)})
    end)
    card.MouseButton1Click:Connect(function()
        tween(card, PressTween, {Size = UDim2.new(1, -5, 0, 49)})
        task.delay(0.08, function() tween(card, PressTween, {Size = UDim2.new(1, -2, 0, 52)}) end)
        callback()
    end)
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
    bindBtn.Text = "[" .. State[bindKey].Name .. "]"
    bindBtn.AutoButtonColor = false
    bindBtn.Parent = card
    Instance.new("UICorner", bindBtn).CornerRadius = UDim.new(0, 7)
    addStroke(bindBtn, 0.68)

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

local function createCheckboxGroup(parent, titleText, checkboxes)
    local container = Instance.new("Frame")
    -- Calculate height based on number of checkboxes
    container.Size = UDim2.new(1, -2, 0, 45 + (#checkboxes * 35))
    container.BackgroundColor3 = Theme.CardBg
    container.Parent = parent
    Instance.new("UICorner", container).CornerRadius = UDim.new(0, 10)
    addStroke(container, 0.55)

    -- Group Title
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -24, 0, 40)
    title.Position = UDim2.new(0, 12, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = titleText
    title.TextColor3 = Theme.TextMain
    title.Font = Enum.Font.GothamBold
    title.TextSize = 12
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = container

    -- Divider Line
    local line = Instance.new("Frame")
    line.Size = UDim2.new(1, -24, 0, 1)
    line.Position = UDim2.new(0, 12, 0, 35)
    line.BackgroundColor3 = Theme.Border
    line.BorderSizePixel = 0
    line.Parent = container

    local yOffset = 45
    for _, cb in ipairs(checkboxes) do
        local cbContainer = Instance.new("Frame")
        cbContainer.Size = UDim2.new(1, -24, 0, 30)
        cbContainer.Position = UDim2.new(0, 12, 0, yOffset)
        cbContainer.BackgroundTransparency = 1
        cbContainer.Parent = container

        -- Checkbox Square
        local box = Instance.new("Frame")
        box.Size = UDim2.new(0, 18, 0, 18)
        box.Position = UDim2.new(0, 0, 0.5, -9)
        box.BackgroundColor3 = Theme.SidebarBg
        box.Parent = cbContainer
        Instance.new("UICorner", box).CornerRadius = UDim.new(0, 4)
        local boxStroke = addStroke(box, 0.4)

        -- Checkmark Icon
        local check = Instance.new("TextLabel")
        check.Size = UDim2.new(1, 0, 1, 0)
        check.BackgroundTransparency = 1
        check.Text = "✓"
        check.TextColor3 = Theme.MainBg
        check.Font = Enum.Font.GothamBold
        check.TextSize = 12
        check.TextTransparency = 1
        check.Parent = box

        -- Checkbox Label
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -28, 1, 0)
        label.Position = UDim2.new(0, 26, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = cb.Name
        label.TextColor3 = Theme.TextDim
        label.Font = Enum.Font.GothamMedium
        label.TextSize = 11
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = cbContainer

        local clickBtn = Instance.new("TextButton")
        clickBtn.Size = UDim2.new(1, 0, 1, 0)
        clickBtn.BackgroundTransparency = 1
        clickBtn.Text = ""
        clickBtn.Parent = cbContainer

        local function update()
            local enabled = State[cb.StateKey]
            tween(box, FastTween, {BackgroundColor3 = enabled and Theme.AccentGreen or Theme.SidebarBg})
            tween(check, FastTween, {TextTransparency = enabled and 0 or 1})
            tween(label, FastTween, {TextColor3 = enabled and Theme.TextMain or Theme.TextDim})
        end

        -- Make the update function available to the UI table so logic blocks can update visual checkboxes
        UI["Update" .. cb.StateKey] = update

        clickBtn.MouseEnter:Connect(function() 
            tween(boxStroke, FastTween, {Color = Theme.AccentGreen, Transparency = 0})
        end)
        clickBtn.MouseLeave:Connect(function() 
            tween(boxStroke, FastTween, {Color = Theme.Border, Transparency = 0.4})
        end)
        clickBtn.MouseButton1Click:Connect(function()
            State[cb.StateKey] = not State[cb.StateKey]
            update()
        end)

        update()
        yOffset = yOffset + 35
    end
    return container
end

-- [[ BUILD TABS & CONTENT ]]

local TabMain = createTab("Main", "◉")

createSection(TabMain, "Farming")
UI.UpdateAutoAttack = createToggleWithBind(TabMain, "Auto Attack", "AutoAttack", "AutoAttackKey", "Automatically attacks nearby valid targets.")

createInput(TabMain, "Attack Range", "AttackRange", true) 

createSection(TabMain, "Resource")
createToggle(TabMain, "Auto Chop Tree	*(NEED EQUIP AXE)", "AutoChop", "Automatically harvests trees and nearby drops.")
createToggle(TabMain, "Auto Mine Ore	*(NEED EQUIP PICKAXE)", "AutoMine", "Automatically mines detected ore nodes.")

createSection(TabMain, "Other")
createToggle(TabMain, "Auto Respawn", "AutoRespawn", "Automatically requests a respawn after death.")

-- Teleport
local TabTeleport = createTab("Teleport", "◇")

createSection(TabTeleport, "Spawn Point")

local spawnAreas = {
    ["Dewdrop Village"] = {
        { Display = "Bonfire 1", Target = "DewdropSpawn_1" }
    },
    ["Goblin Junkyard"] = {
        { Display = "Bonfire 1", Target = "GoblinJunkyardSpawn_1" },
        { Display = "Bonfire 2", Target = "GoblinJunkyardSpawn_2" },
        { Display = "Bonfire 3", Target = "GoblinJunkyardSpawn_3" }
    }
}

local currentSpawnArea = nil
local selectedSpawnTarget = nil

local function detectClosestSpawnArea()
    local character = LocalPlayer.Character
    local hrp = character and character:FindFirstChild("HumanoidRootPart")
    if not hrp then return "Dewdrop Village" end
    
    local closestArea = "Dewdrop Village"
    local minDistance = math.huge
    
    local portalFolder = workspace:FindFirstChild("Maps") and workspace.Maps:FindFirstChild("Portal")
    if not portalFolder then return closestArea end
    
    for areaName, spawns in pairs(spawnAreas) do
        for _, spawnInfo in ipairs(spawns) do
            local spawnArea = portalFolder:FindFirstChild(spawnInfo.Target)
            if spawnArea then
                local targetTarget = spawnArea:FindFirstChild("SpawnPoint", true) or spawnArea
                local targetPart = (targetTarget:IsA("Model") and (targetTarget.PrimaryPart or targetTarget:FindFirstChildWhichIsA("BasePart", true))) or (targetTarget:IsA("BasePart") and targetTarget)
                
                if targetPart then
                    local dist = (hrp.Position - targetPart.Position).Magnitude
                    if dist < minDistance then
                        minDistance = dist
                        closestArea = areaName
                    end
                end
            end
        end
    end
    return closestArea
end

local spawnDropdownContainer, updateSpawnDropdown, spawnTitle = createDropdown(TabTeleport, "Spawn Point", {}, function(selectedDisplayOption)
    if currentSpawnArea and spawnAreas[currentSpawnArea] then
        for _, info in ipairs(spawnAreas[currentSpawnArea]) do
            if info.Display == selectedDisplayOption then
                selectedSpawnTarget = info.Target
                break
            end
        end
    end
end)

task.spawn(function()
    while task.wait(2) do
        local newArea = detectClosestSpawnArea()
        if newArea ~= currentSpawnArea then
            currentSpawnArea = newArea
            local areaSpawns = spawnAreas[currentSpawnArea]
            
            local displayOptions = {}
            for _, info in ipairs(areaSpawns) do
                table.insert(displayOptions, info.Display)
            end
            
            updateSpawnDropdown(displayOptions)
            
            selectedSpawnTarget = areaSpawns[1].Target
            if spawnTitle then
                spawnTitle.Text = "Spawn Point - " .. areaSpawns[1].Display
            end
        end
    end
end)

createButton(TabTeleport, "Teleport to Spawn Point", function()
    local character = LocalPlayer.Character
    local hrp = character and character:FindFirstChild("HumanoidRootPart")
    
    if hrp and selectedSpawnTarget then
        pcall(function()
            local portalFolder = workspace:FindFirstChild("Maps") and workspace.Maps:FindFirstChild("Portal")
            local spawnArea = portalFolder and portalFolder:FindFirstChild(selectedSpawnTarget)
            if not spawnArea then return end
            
            local spawnpoint = spawnArea:FindFirstChild("SpawnPoint", true) 
            local targetTarget = spawnpoint or spawnArea
            
            local targetPart
            if targetTarget:IsA("Model") then
                targetPart = targetTarget.PrimaryPart or targetTarget:FindFirstChildWhichIsA("BasePart", true)
            elseif targetTarget:IsA("BasePart") then
                targetPart = targetTarget
            end
            
            if targetPart then
                hrp.CFrame = targetPart.CFrame + Vector3.new(0, 5, 0)
            end
        end)
    end
end, "🔥")

local function teleportTo(dest)
    local character = LocalPlayer.Character
    local hrp = character and character:FindFirstChild("HumanoidRootPart")
    
    if hrp then
        local target = workspace:FindFirstChild(dest, true)
        if target then
            if target:IsA("Model") then
                local root = target:FindFirstChild("HumanoidRootPart") or target.PrimaryPart
                if root then
                    hrp.CFrame = root.CFrame + Vector3.new(0, 5, 0)
                    return
                else
                    local part = target:FindFirstChildWhichIsA("BasePart")
                    if part then
                        hrp.CFrame = part.CFrame + Vector3.new(0, 5, 0)
                        return
                    end
                end
            elseif target:IsA("BasePart") then
                hrp.CFrame = target.CFrame + Vector3.new(0, 5, 0)
                return
            end
        end
    end
    
    pcall(function()
        if ReplicatedStorage:FindFirstChild("Remotes") then
            pcall(function() ReplicatedStorage.Remotes.World.Teleport:FireServer({ ["Destination"] = dest }) end)
        end
    end)
end

createSection(TabTeleport, "Locations")

local locationMapping = {
    ["Dewdrop Village"] = "DewdropVillage",
    ["Goblin Junkyard"] = "GoblinJunkyard",
    ["Goblin Cogtown"] = "GoblinCogtown",
    ["Farm"] = "Farm"
}
local locationList = {"Dewdrop Village", "Goblin Junkyard", "Goblin Cogtown", "Farm"}
local selectedLocationTarget = nil

createDropdown(TabTeleport, "Select Location", locationList, function(selectedOption)
    selectedLocationTarget = locationMapping[selectedOption]
end)

createButton(TabTeleport, "Teleport to Location", function()
    if selectedLocationTarget then
        teleportTo(selectedLocationTarget)
    end
end, "✈")

local function TeleportToNPCWaypoint(npcName)
    local character = LocalPlayer.Character
    local hrp = character and character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local target = workspace:FindFirstChild(npcName, true)
    if target then
        local targetCFrame = nil
        if target:IsA("Model") then
            local root = target:FindFirstChild("HumanoidRootPart") or target.PrimaryPart
            if root then
                targetCFrame = root.CFrame
            else
                local part = target:FindFirstChildWhichIsA("BasePart")
                if part then targetCFrame = part.CFrame end
            end
        elseif target:IsA("BasePart") then
            targetCFrame = target.CFrame
        end
        if targetCFrame then
            hrp.CFrame = (targetCFrame * CFrame.new(0, 0, -4)) + Vector3.new(0, 4, 0)
        end
    else
        warn("SEOUL HUB: Could not find NPC '" .. npcName .. "' in workspace.")
    end
end

createSection(TabTeleport, "NPCs")
local npcList = {"Leaf", "Rendall", "Hogan", "Arlette", "Breda", "Theron", "Neria", "Eren"}

createDropdown(TabTeleport, "Teleport to NPC", npcList, function(selectedNpc)
    TeleportToNPCWaypoint(selectedNpc)
end)


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
    
    -- Fade In
    tween(notif, FastTween, {BackgroundTransparency = 0})
    tween(stroke, FastTween, {Transparency = 0.5})
    tween(title, FastTween, {TextTransparency = 0})
    tween(msg, FastTween, {TextTransparency = 0})
    
    -- Fade Out & Destroy
    task.delay(duration, function()
        tween(notif, FastTween, {BackgroundTransparency = 1})
        tween(stroke, FastTween, {Transparency = 1})
        tween(title, FastTween, {TextTransparency = 1})
        local outTween = tween(msg, FastTween, {TextTransparency = 1})
        outTween.Completed:Wait()
        notif:Destroy()
    end)
end


-- [[ MISC TAB ]]
local TabMisc = createTab("Misc", "✮")

createSection(TabMisc, "Codes")
local codesList = {"1KLIKES", "2KLIKES", "5KLIKES", "RELEASE", "THROUGHTHEPORTAL"}
createButton(TabMisc, "Redeem All Codes", function()
    task.spawn(function()
        for _, code in ipairs(codesList) do
            pcall(function()
                game:GetService("ReplicatedStorage").Remotes.RedeemCode.RequestRedeemCode:FireServer(code)
            end)
            task.wait(2)
        end
        
        SendHubNotification("Finished redeeming all codes.", 4)
    end)
end, "🎁")

createSection(TabMisc, "Auto Claim")
createCheckboxGroup(TabMisc, "Auto Claim", {
    {Name = "Playtime", StateKey = "AutoPlaytime"},
    {Name = "Alltime", StateKey = "AutoAlltime"},
    {Name = "Battlepass", StateKey = "AutoBattlepass"}
})


-- Settings
local TabSettings = createTab("Settings", "⚙")
createPageHeader(TabSettings, "Settings", "Customize controls and interface behavior.")
createSection(TabSettings, "Keybinds")
createKeybind(TabSettings, "Hide / Show Menu", "HideMenuKey")

createSection(TabSettings, "Client")
createButton(TabSettings, "Unload Script", function()
    for _, conn in pairs(State.Connections) do conn:Disconnect() end
    ScreenGui:Destroy()
end, "×")

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

-- 1. Kill Auto Attack Loop
local attackDelay = 0
table.insert(State.Connections, RunService.Heartbeat:Connect(function(dt)
    if not State.AutoAttack or not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then return end
    attackDelay = attackDelay + dt
    if attackDelay < 0.2 then return end 
    attackDelay = 0

    local hrp = LocalPlayer.Character.HumanoidRootPart
    local mobsFolder = workspace:FindFirstChild("Mobs")
    if mobsFolder and mobsFolder:FindFirstChild("Active") then
        local targetsToHit = {}
        for _, monster in pairs(mobsFolder.Active:GetChildren()) do
            local monHum = monster:FindFirstChild("Humanoid") or monster:FindFirstChildWhichIsA("Humanoid")
            local monHrp = monster:FindFirstChild("HumanoidRootPart") or monster.PrimaryPart
            
            if monHum and monHrp and monHum.Health > 0 and (monHrp.Position - hrp.Position).Magnitude <= State.AttackRange then
                local vector, onScreen = Camera:WorldToViewportPoint(monHrp.Position)
                if onScreen then
                    local entityIdObj = monster:FindFirstChild("EntityId")
                    local monsterEntityId = entityIdObj and entityIdObj:IsA("StringValue") and entityIdObj.Value or monster:GetAttribute("EntityId")
                    if monsterEntityId then table.insert(targetsToHit, monsterEntityId) end
                end
            end
        end
        if #targetsToHit > 0 then ReplicatedStorage.Remotes.Combat.RequestMeleeHits:FireServer(targetsToHit) end
    end
end))

-- 2. Auto Respawn Logic
local isRespawning = false 
local function SetupAutoRespawn(character)
    local humanoid = character:WaitForChild("Humanoid", 5)
    if humanoid then
        humanoid.Died:Connect(function()
            if not State.AutoRespawn or isRespawning then return end
            isRespawning = true
            task.spawn(function()
                task.wait(5); ReplicatedStorage.Remotes.Combat.RequestRespawn:FireServer()
                task.wait(1); VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Z, false, game)
                task.wait(0.05); VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Z, false, game)
                task.wait(2); isRespawning = false
            end)
        end)
    end
end
if LocalPlayer.Character then SetupAutoRespawn(LocalPlayer.Character) end
table.insert(State.Connections, LocalPlayer.CharacterAdded:Connect(SetupAutoRespawn))

-- 3. Auto Chop Tree Logic
task.spawn(function()
    while task.wait(0.5) do
        if not State.AutoChop then continue end
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then continue end

        local mapsFolder = workspace:FindFirstChild("Maps")
        if not mapsFolder then continue end
        local vegetationFolder = mapsFolder:FindFirstChild("Vegetation")
        if not vegetationFolder then continue end
        local treesFolder = vegetationFolder:FindFirstChild("Trees")
        if not treesFolder then continue end

        for _, tree in pairs(treesFolder:GetChildren()) do
            if not State.AutoChop then break end 
            if tree.Name:match("^Tree_Type[1-9]$") then
                local treePart = tree:IsA("Model") and (tree.PrimaryPart or tree:FindFirstChildWhichIsA("BasePart")) or (tree:IsA("BasePart") and tree or nil)
                if treePart then
                    hrp.CFrame = (treePart.CFrame * CFrame.new(0, 0, 3)) + Vector3.new(0, 5, 0)
                    task.wait(1) 
                    
                    if not hrp or not hrp.Parent then break end

                    if State.AutoChop then
                        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.F, false, game)
                        task.wait(1)
                        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.F, false, game)
                        task.wait(5.2) 
                    end

                    local worldItems = workspace:FindFirstChild("WorldItems")
                    if worldItems and State.AutoChop then
                        for _, item in pairs(worldItems:GetChildren()) do
                            if item.Name:match("^pickup_") and item:FindFirstChild("Mat_WoodMesh", true) then
                                local itemPart = item:FindFirstChildWhichIsA("BasePart", true)
                                if itemPart and (itemPart.Position - treePart.Position).Magnitude <= 50 then
                                    hrp.CFrame = itemPart.CFrame + Vector3.new(0, 3, 0)
                                    task.wait(1)
                                    
                                    if not hrp or not hrp.Parent then break end
                                    
                                    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.F, false, game)
                                    task.wait(1)
                                    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.F, false, game)
                                    
                                    task.wait(1.5)
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end)

-- 4. Auto Mine Ore Logic
task.spawn(function()
    local oreDelays = {
        ["Ore_Stone"] = 5.2,
        ["Ore_Solite"] = 10.2,
        ["Ore_Lumite"] = 15.2,
        ["Ore_Aurorite"] = 20.2
    }

    while task.wait(0.5) do
        if not State.AutoMine then continue end
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then continue end

        local mapsFolder = workspace:FindFirstChild("Maps")
        if not mapsFolder then continue end
        local worldFolder = mapsFolder:FindFirstChild("World")
        if not worldFolder then continue end
        local spawnOreFolder = worldFolder:FindFirstChild("Spawn_Ore")
        if not spawnOreFolder then continue end

        for i = 1, 47 do
            if not State.AutoMine then break end 
            
            local oreNode = spawnOreFolder:FindFirstChild("SP" .. tostring(i))
            if oreNode then
                local targetOre = nil
                local targetName = ""
                
                for oreName, delayTime in pairs(oreDelays) do
                    local foundOre = oreNode:FindFirstChild(oreName)
                    if foundOre then
                        targetOre = foundOre
                        targetName = oreName
                        break
                    end
                end

                if targetOre then
                    local orePart = targetOre:IsA("Model") and (targetOre.PrimaryPart or targetOre:FindFirstChildWhichIsA("BasePart")) or (targetOre:IsA("BasePart") and targetOre or nil)
                    if orePart then
                        hrp.CFrame = (orePart.CFrame * CFrame.new(0, 0, 3)) + Vector3.new(0, 5, 0)
                        task.wait(1) 
                        
                        if not hrp or not hrp.Parent then break end

                        if State.AutoMine then
                            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.F, false, game)
                            task.wait(1)
                            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.F, false, game)
                            
                            task.wait(oreDelays[targetName]) 
                        end

                        local worldItems = workspace:FindFirstChild("WorldItems")
                        if worldItems and State.AutoMine then
                            for _, item in pairs(worldItems:GetChildren()) do
                                if item.Name:match("^pickup_") and (item:FindFirstChild("Mat_StoneMesh", true) or item:FindFirstChild("Mat_SoliteMesh", true) or item:FindFirstChild("Mat_LumiteMesh", true) or item:FindFirstChild("Mat_AuroriteMesh", true)) then
                                    local itemPart = item:FindFirstChildWhichIsA("BasePart", true)
                                    
                                    if itemPart and (itemPart.Position - orePart.Position).Magnitude <= 30 then
                                        hrp.CFrame = itemPart.CFrame + Vector3.new(0, 3, 0)
                                        task.wait(1) 
                                        
                                        if not hrp or not hrp.Parent then break end
                                        
                                        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.F, false, game)
                                        task.wait(1)
                                        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.F, false, game)
                                        
                                        task.wait(1.5)
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end)

-- 5. Auto Claim Rewards Logic
task.spawn(function()
    while task.wait(15) do 
        
        -- [[ PLAYTIME LOGIC ]]
        if State.AutoPlaytime then
            -- Replace 'true' with your game's actual LocalPlayer data check for a true scan
            local hasAvailableRewards = true 
            
            if hasAvailableRewards then
                for i = 1, 10 do
                    pcall(function() game:GetService("ReplicatedStorage").Remotes.Rewards.Claim:FireServer("PlayTime", i) end)
                    task.wait(1.2) 
                end
                SendHubNotification("Attempted to claim available Playtime rewards.", 3)
            else
                SendHubNotification("No Playtime rewards available to claim.", 3)
            end
        end
        
        -- [[ ALL-TIME LOGIC ]]
        if State.AutoAlltime then
            -- Replace 'true' with your game's actual LocalPlayer data check for a true scan
            local hasAvailableRewards = true 
            
            if hasAvailableRewards then
                for i = 1, 8 do
                    pcall(function() game:GetService("ReplicatedStorage").Remotes.Rewards.Claim:FireServer("AllTime", i) end)
                    task.wait(1.2) 
                end
                
                -- Turn off Auto Claim State and update the UI Toggle
                State.AutoAlltime = false
                if UI.UpdateAutoAlltime then UI.UpdateAutoAlltime() end
                SendHubNotification("All-Time rewards claimed! Auto All-Time turned off.", 3)
            else
                SendHubNotification("No All-Time rewards available to claim.", 3)
            end
        end

        -- [[ BATTLEPASS LOGIC ]]
        if State.AutoBattlepass then
            -- Replace 'true' with your game's actual LocalPlayer data check for a true scan
            local hasAvailableRewards = true 
            
            if hasAvailableRewards then
                for i = 1, 30 do
                    pcall(function() game:GetService("ReplicatedStorage").Remotes.BattlePass.ClaimTier:FireServer(i, "Free") end)
                    task.wait(0.7) 
                    pcall(function() game:GetService("ReplicatedStorage").Remotes.BattlePass.ClaimTier:FireServer(i, "Premium") end)
                    task.wait(0.7) 
                end
                SendHubNotification("Attempted to claim available Battlepass rewards.", 3)
            else
                SendHubNotification("No Battlepass rewards available to claim.", 3)
            end
        end
        
    end
end)
