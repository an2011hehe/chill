local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local Lighting = game:GetService("Lighting")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

if not game:IsLoaded() then game.Loaded:Wait() end

pcall(function()
    if CoreGui:FindFirstChild("FloatingHub") then
        CoreGui:FindFirstChild("FloatingHub"):Destroy()
    end
end)

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "FloatingHub"
ScreenGui.Parent = CoreGui
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder = 999

local isMobile = UserInputService.TouchEnabled
local screenSize = Camera.ViewportSize

local Colors = {
    BG = Color3.fromRGB(10, 10, 15),
    Card = Color3.fromRGB(22, 22, 32),
    Card2 = Color3.fromRGB(30, 30, 42),
    Accent = Color3.fromRGB(130, 80, 255),
    AccentLight = Color3.fromRGB(160, 120, 255),
    Text = Color3.fromRGB(240, 240, 245),
    SubText = Color3.fromRGB(150, 150, 165),
    Success = Color3.fromRGB(50, 200, 100),
    Danger = Color3.fromRGB(255, 70, 70),
    Warning = Color3.fromRGB(255, 180, 50),
    White = Color3.fromRGB(255, 255, 255)
}

local Connections = {}
local function Connect(signal, callback)
    local conn = signal:Connect(callback)
    table.insert(Connections, conn)
    return conn
end

local function CleanupConnections()
    for _, conn in ipairs(Connections) do
        if conn and conn.Connected then conn:Disconnect() end
    end
    Connections = {}
end

local function Tween(obj, props, dur, style, dir)
    dur = dur or 0.25
    style = style or Enum.EasingStyle.Quart
    dir = dir or Enum.EasingDirection.Out
    local t = TweenService:Create(obj, TweenInfo.new(dur, style, dir), props)
    t:Play()
    return t
end

local function ApplyCorner(obj, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 8)
    c.Parent = obj
    return c
end

local function ApplyStroke(obj, c, t, tr)
    local s = Instance.new("UIStroke")
    s.Color = c or Colors.White
    s.Thickness = t or 1
    s.Transparency = tr or 0.85
    s.Parent = obj
    return s
end

local function ApplyGradient(obj, c1, c2)
    local g = Instance.new("UIGradient")
    g.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, c1 or Colors.Accent),
        ColorSequenceKeypoint.new(1, c2 or Colors.AccentLight)
    })
    g.Rotation = 135
    g.Parent = obj
    return g
end

local function SendNotification(text, duration, color)
    local notif = Instance.new("TextLabel")
    notif.Size = UDim2.new(0, 200, 0, 28)
    notif.Position = UDim2.new(0.5, -100, 1, -45)
    notif.BackgroundColor3 = color or Colors.Accent
    notif.BackgroundTransparency = 0.1
    notif.Text = text
    notif.TextColor3 = Colors.White
    notif.Font = Enum.Font.GothamBold
    notif.TextSize = 10
    notif.ZIndex = 200
    notif.Parent = ScreenGui
    ApplyCorner(notif, 14)
    ApplyStroke(notif, color or Colors.Accent, 1, 0)
    task.delay(duration or 3, function()
        Tween(notif, {BackgroundTransparency = 1, TextTransparency = 1}, 0.4)
        task.delay(0.4, function() notif:Destroy() end)
    end)
end

local Settings = {
    Walkspeed = 16,
    Jumppower = 50,
    FlyEnabled = false,
    FlySpeed = 50,
    FlyBV = nil,
    FlyBG = nil,
    FlyConn = nil,
    NoClipEnabled = false,
    NoClipConn = nil,
    InfiniteJump = false,
    InfJumpConn = nil,
    AntiKnockback = false,
    AntiKBConn = nil,
    ESPEnabled = false,
    ESPBoxes = {},
    Wallhack = false,
    Fullbright = false,
    FPSBoost = false,
    LowGraphics = false,
    AutoAttack = false,
    AttackRange = 20,
    AutoAttackConn = nil,
    SavedPositions = {}
}

local function safeCall(func, ...)
    return pcall(func, ...)
end

local function getCharacter()
    local char = LocalPlayer.Character
    if not char then char = LocalPlayer.CharacterAdded:Wait() end
    return char
end

local function getHumanoid()
    return getCharacter():WaitForChild("Humanoid")
end

local function getRootPart()
    local char = getCharacter()
    return char:FindFirstChild("HumanoidRootPart") or char:WaitForChild("HumanoidRootPart")
end

local Bubble = Instance.new("TextButton")
Bubble.Size = UDim2.new(0, 56, 0, 56)
Bubble.Position = UDim2.new(0, screenSize.X - 72, 0.5, -28)
Bubble.BackgroundColor3 = Colors.Accent
Bubble.BackgroundTransparency = 0.1
Bubble.BorderSizePixel = 0
Bubble.Text = ""
Bubble.AutoButtonColor = false
Bubble.ZIndex = 100
Bubble.Parent = ScreenGui
ApplyCorner(Bubble, 28)

local BubbleShadow = Instance.new("ImageLabel")
BubbleShadow.Size = UDim2.new(1, 24, 1, 24)
BubbleShadow.Position = UDim2.new(0, -12, 0, -12)
BubbleShadow.BackgroundTransparency = 1
BubbleShadow.Image = "rbxassetid://6014261993"
BubbleShadow.ImageTransparency = 0.5
BubbleShadow.ScaleType = Enum.ScaleType.Slice
BubbleShadow.SliceCenter = Rect.new(49, 49, 49, 49)
BubbleShadow.ZIndex = 99
BubbleShadow.Parent = Bubble

ApplyGradient(Bubble, Colors.Accent, Color3.fromRGB(180, 120, 255))

local BubbleGlow = Instance.new("Frame")
BubbleGlow.Size = UDim2.new(1, 16, 1, 16)
BubbleGlow.Position = UDim2.new(0, -8, 0, -8)
BubbleGlow.BackgroundTransparency = 1
BubbleGlow.BorderSizePixel = 0
BubbleGlow.ZIndex = 98
BubbleGlow.Parent = Bubble
ApplyCorner(BubbleGlow, 36)
ApplyStroke(BubbleGlow, Colors.Accent, 2, 0.6)

local BubbleIcon = Instance.new("TextLabel")
BubbleIcon.Size = UDim2.new(1, 0, 1, 0)
BubbleIcon.BackgroundTransparency = 1
BubbleIcon.Text = "⚡"
BubbleIcon.TextColor3 = Colors.White
BubbleIcon.Font = Enum.Font.GothamBold
BubbleIcon.TextSize = 24
BubbleIcon.ZIndex = 101
BubbleIcon.Parent = Bubble

local rippleCircle = Instance.new("Frame")
rippleCircle.Size = UDim2.new(1, 0, 1, 0)
rippleCircle.Position = UDim2.new(0, 0, 0, 0)
rippleCircle.BackgroundColor3 = Colors.White
rippleCircle.BackgroundTransparency = 1
rippleCircle.BorderSizePixel = 0
rippleCircle.ZIndex = 102
rippleCircle.Parent = Bubble
ApplyCorner(rippleCircle, 28)

local function PlayRipple()
    rippleCircle.Size = UDim2.new(1, 0, 1, 0)
    rippleCircle.BackgroundTransparency = 0.7
    rippleCircle.Position = UDim2.new(0, 0, 0, 0)
    Tween(rippleCircle, {
        Size = UDim2.new(0, Bubble.AbsoluteSize.X * 2.5, 0, Bubble.AbsoluteSize.Y * 2.5),
        Position = UDim2.new(-0.75, 0, -0.75, 0),
        BackgroundTransparency = 1
    }, 0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
end

local draggingBubble = false
local dragStartPos = nil
local bubbleStartPos = nil

local function ClampToScreen(posX, posY, sizeX, sizeY)
    local topBarOffset = 30
    local bottomBarOffset = isMobile and 40 or 0
    return math.clamp(posX, 0, screenSize.X - sizeX), math.clamp(posY, topBarOffset, screenSize.Y - sizeY - bottomBarOffset)
end

local function SnapToEdge(targetX, sizeX)
    return (targetX + sizeX / 2 < screenSize.X / 2) and 8 or (screenSize.X - sizeX - 8)
end

Connect(UserInputService.InputBegan, function(input, gpe)
    if gpe then return end
    local pos = input.Position
    local bPos = Bubble.AbsolutePosition
    local bSize = Bubble.AbsoluteSize
    if pos.X >= bPos.X - 15 and pos.X <= bPos.X + bSize.X + 15 and pos.Y >= bPos.Y - 15 and pos.Y <= bPos.Y + bSize.Y + 15 then
        draggingBubble = true
        dragStartPos = input.Position
        bubbleStartPos = Bubble.Position
        Tween(Bubble, {Size = UDim2.new(0, 62, 0, 62)}, 0.15)
        Bubble.BackgroundTransparency = 0
    end
end)

Connect(UserInputService.InputChanged, function(input)
    if not draggingBubble then return end
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        local delta = input.Position - dragStartPos
        local newX, newY = ClampToScreen(bubbleStartPos.X.Offset + delta.X, bubbleStartPos.Y.Offset + delta.Y, Bubble.AbsoluteSize.X, Bubble.AbsoluteSize.Y)
        Bubble.Position = UDim2.new(0, newX, 0, newY)
    end
end)

Connect(UserInputService.InputEnded, function(input)
    if not draggingBubble then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        draggingBubble = false
        local currentX = Bubble.AbsolutePosition.X
        local snapX = SnapToEdge(currentX, Bubble.AbsoluteSize.X)
        local snapDuration = math.clamp(math.abs(currentX - snapX) / 800, 0.15, 0.35)
        Tween(Bubble, {
            Position = UDim2.new(0, snapX, 0, Bubble.Position.Y.Offset),
            Size = UDim2.new(0, 56, 0, 56),
            BackgroundTransparency = 0.1
        }, snapDuration, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    end
end)

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0.92, 0, 0.75, 0)
MainFrame.Position = UDim2.new(0.04, 0, 0.125, 0)
MainFrame.BackgroundColor3 = Colors.BG
MainFrame.BackgroundTransparency = 1
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = true
MainFrame.Visible = false
MainFrame.ZIndex = 50
MainFrame.Parent = ScreenGui
ApplyCorner(MainFrame, 20)
ApplyStroke(MainFrame, Colors.White, 1.5, 0.92)

local MainShadow = Instance.new("ImageLabel")
MainShadow.Size = UDim2.new(1, 40, 1, 40)
MainShadow.Position = UDim2.new(0, -20, 0, -20)
MainShadow.BackgroundTransparency = 1
MainShadow.Image = "rbxassetid://6014261993"
MainShadow.ImageTransparency = 0.6
MainShadow.ScaleType = Enum.ScaleType.Slice
MainShadow.SliceCenter = Rect.new(49, 49, 49, 49)
MainShadow.ZIndex = 49
MainShadow.Parent = MainFrame

local MenuOpen = false
local isDraggingMenu = false
local menuDragStart = nil
local menuStartPos = nil

local function OpenMenu()
    if MenuOpen then return end
    MenuOpen = true
    PlayRipple()
    MainFrame.Visible = true
    MainFrame.BackgroundTransparency = 1
    MainFrame.Size = UDim2.new(0, 0, 0, 0)
    MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    Tween(MainFrame, {
        Size = UDim2.new(0.92, 0, 0.75, 0),
        Position = UDim2.new(0.04, 0, 0.125, 0),
        BackgroundTransparency = 0
    }, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
end

local function CloseMenu()
    if not MenuOpen then return end
    MenuOpen = false
    Tween(MainFrame, {
        Size = UDim2.new(0, 0, 0, 0),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        BackgroundTransparency = 1
    }, 0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
    task.delay(0.25, function() if not MenuOpen then MainFrame.Visible = false end end)
end

Bubble.MouseButton1Click:Connect(function()
    if draggingBubble then return end
    if MenuOpen then CloseMenu() else OpenMenu() end
end)

if isMobile then
    Bubble.TouchTap:Connect(function()
        if draggingBubble then return end
        if MenuOpen then CloseMenu() else OpenMenu() end
    end)
end

local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 50)
TitleBar.BackgroundColor3 = Colors.Card
TitleBar.BorderSizePixel = 0
TitleBar.Parent = MainFrame
ApplyCorner(TitleBar, 20)
local TitleBarFix = Instance.new("Frame")
TitleBarFix.Size = UDim2.new(1, 0, 0, 20)
TitleBarFix.Position = UDim2.new(0, 0, 1, -20)
TitleBarFix.BackgroundColor3 = Colors.Card
TitleBarFix.BorderSizePixel = 0
TitleBarFix.Parent = TitleBar

local TitleAccent = Instance.new("Frame")
TitleAccent.Size = UDim2.new(0, 4, 0, 22)
TitleAccent.Position = UDim2.new(0, 16, 0.5, -11)
TitleAccent.BackgroundColor3 = Colors.Accent
TitleAccent.BorderSizePixel = 0
TitleAccent.Parent = TitleBar
ApplyCorner(TitleAccent, 2)
ApplyGradient(TitleAccent, Colors.Accent, Colors.AccentLight)

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(0, 180, 1, 0)
TitleLabel.Position = UDim2.new(0, 28, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "FLOATING HUB"
TitleLabel.TextColor3 = Colors.Text
TitleLabel.Font = Enum.Font.GothamBlack
TitleLabel.TextSize = 14
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = TitleBar

local FPSLabel = Instance.new("TextLabel")
FPSLabel.Size = UDim2.new(0, 55, 1, 0)
FPSLabel.Position = UDim2.new(0, 210, 0, 0)
FPSLabel.BackgroundTransparency = 1
FPSLabel.Text = "60 FPS"
FPSLabel.TextColor3 = Colors.Success
FPSLabel.Font = Enum.Font.GothamBold
FPSLabel.TextSize = 10
FPSLabel.TextXAlignment = Enum.TextXAlignment.Left
FPSLabel.Parent = TitleBar

local lastFPSUpdate = 0
local frameCount = 0
Connect(RunService.RenderStepped, function()
    frameCount = frameCount + 1
    if tick() - lastFPSUpdate >= 0.5 then
        local currentFPS = math.round(frameCount / (tick() - lastFPSUpdate))
        FPSLabel.Text = string.format("%d FPS", currentFPS)
        FPSLabel.TextColor3 = currentFPS >= 50 and Colors.Success or (currentFPS >= 30 and Colors.Warning or Colors.Danger)
        frameCount = 0
        lastFPSUpdate = tick()
    end
end)

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 34, 0, 34)
CloseBtn.Position = UDim2.new(1, -42, 0.5, -17)
CloseBtn.BackgroundColor3 = Colors.Danger
CloseBtn.BackgroundTransparency = 0.85
CloseBtn.BorderSizePixel = 0
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Colors.White
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 14
CloseBtn.Parent = TitleBar
ApplyCorner(CloseBtn, 17)

CloseBtn.MouseButton1Click:Connect(CloseMenu)
if isMobile then CloseBtn.TouchTap:Connect(CloseMenu) end

Connect(TitleBar.InputBegan, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        isDraggingMenu = true
        menuDragStart = input.Position
        menuStartPos = MainFrame.Position
    end
end)

Connect(UserInputService.InputChanged, function(input)
    if not isDraggingMenu then return end
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        local delta = input.Position - menuDragStart
        local newX = math.clamp(menuStartPos.X.Offset + delta.X, 0, screenSize.X - MainFrame.AbsoluteSize.X)
        local newY = math.clamp(menuStartPos.Y.Offset + delta.Y, 0, screenSize.Y - MainFrame.AbsoluteSize.Y)
        MainFrame.Position = UDim2.new(0, newX, 0, newY)
    end
end)

Connect(UserInputService.InputEnded, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        isDraggingMenu = false
    end
end)

local Sidebar = Instance.new("Frame")
Sidebar.Size = UDim2.new(0, 155, 1, -50)
Sidebar.Position = UDim2.new(0, 0, 0, 50)
Sidebar.BackgroundColor3 = Colors.Card
Sidebar.BackgroundTransparency = 0.3
Sidebar.BorderSizePixel = 0
Sidebar.Parent = MainFrame

local SidebarScroll = Instance.new("ScrollingFrame")
SidebarScroll.Size = UDim2.new(1, 0, 1, -12)
SidebarScroll.Position = UDim2.new(0, 0, 0, 12)
SidebarScroll.BackgroundTransparency = 1
SidebarScroll.BorderSizePixel = 0
SidebarScroll.ScrollBarThickness = 0
SidebarScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
SidebarScroll.Parent = Sidebar

local SidebarList = Instance.new("UIListLayout")
SidebarList.Padding = UDim.new(0, 4)
SidebarList.HorizontalAlignment = Enum.HorizontalAlignment.Center
SidebarList.Parent = SidebarScroll

local Tabs = {
    {Name = "Home", Icon = "🏠"},
    {Name = "Main", Icon = "⚡"},
    {Name = "Player", Icon = "👤"},
    {Name = "Visual", Icon = "👁️"},
    {Name = "Teleport", Icon = "🌀"},
    {Name = "Combat", Icon = "⚔️"},
    {Name = "Misc", Icon = "🎯"},
    {Name = "Settings", Icon = "⚙️"}
}

local TabButtons = {}
local CurrentTab = "Home"

local ContentArea = Instance.new("Frame")
ContentArea.Size = UDim2.new(1, -155, 1, -50)
ContentArea.Position = UDim2.new(0, 155, 0, 50)
ContentArea.BackgroundColor3 = Colors.BG
ContentArea.BorderSizePixel = 0
ContentArea.ClipsDescendants = true
ContentArea.Parent = MainFrame

local TabContainers = {}

for _, tab in ipairs(Tabs) do
    local container = Instance.new("ScrollingFrame")
    container.Size = UDim2.new(1, -16, 1, -16)
    container.Position = UDim2.new(0, 8, 0, 8)
    container.BackgroundTransparency = 1
    container.BorderSizePixel = 0
    container.ScrollBarThickness = 3
    container.ScrollBarImageColor3 = Colors.Accent
    container.ScrollBarImageTransparency = 0.5
    container.CanvasSize = UDim2.new(0, 0, 0, 1600)
    container.Visible = false
    container.Parent = ContentArea
    local list = Instance.new("UIListLayout")
    list.Padding = UDim.new(0, 10)
    list.Parent = container
    TabContainers[tab.Name] = container
end

local function SelectTab(name)
    CurrentTab = name
    for n, c in pairs(TabContainers) do c.Visible = (n == name) end
    for n, d in pairs(TabButtons) do
        local sel = (n == name)
        Tween(d.Btn, {BackgroundTransparency = sel and 0.7 or 1, BackgroundColor3 = sel and Colors.Accent or Colors.White}, 0.2)
        d.Label.TextColor3 = sel and Colors.Text or Colors.SubText
    end
end

for _, tab in ipairs(Tabs) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -16, 0, 42)
    btn.BackgroundColor3 = Colors.White
    btn.BackgroundTransparency = 1
    btn.BorderSizePixel = 0
    btn.Text = ""
    btn.AutoButtonColor = false
    btn.Parent = SidebarScroll
    ApplyCorner(btn, 12)
    
    local icon = Instance.new("TextLabel")
    icon.Size = UDim2.new(0, 28, 1, 0)
    icon.Position = UDim2.new(0, 12, 0, 0)
    icon.BackgroundTransparency = 1
    icon.Text = tab.Icon
    icon.TextColor3 = Colors.SubText
    icon.Font = Enum.Font.Gotham
    icon.TextSize = 17
    icon.Parent = btn
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -48, 1, 0)
    label.Position = UDim2.new(0, 44, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = tab.Name
    label.TextColor3 = Colors.SubText
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Font = Enum.Font.GothamBold
    label.TextSize = 12
    label.Parent = btn
    
    btn.MouseButton1Click:Connect(function() SelectTab(tab.Name) end)
    if isMobile then btn.TouchTap:Connect(function() SelectTab(tab.Name) end) end
    
    TabButtons[tab.Name] = {Btn = btn, Label = label}
end

SelectTab("Home")

local function CreateSection(parent, title)
    local sec = Instance.new("Frame")
    sec.Size = UDim2.new(1, 0, 0, 38)
    sec.BackgroundColor3 = Colors.Card
    sec.BackgroundTransparency = 0.4
    sec.BorderSizePixel = 0
    sec.Parent = parent
    ApplyCorner(sec, 12)
    ApplyStroke(sec, Colors.White, 1, 0.88)
    
    local accent = Instance.new("Frame")
    accent.Size = UDim2.new(0, 3, 0, 20)
    accent.Position = UDim2.new(0, 12, 0.5, -10)
    accent.BackgroundColor3 = Colors.Accent
    accent.BorderSizePixel = 0
    accent.Parent = sec
    ApplyCorner(accent, 2)
    
    local txt = Instance.new("TextLabel")
    txt.Size = UDim2.new(1, -30, 1, 0)
    txt.Position = UDim2.new(0, 22, 0, 0)
    txt.BackgroundTransparency = 1
    txt.Text = title
    txt.TextColor3 = Colors.Text
    txt.TextXAlignment = Enum.TextXAlignment.Left
    txt.Font = Enum.Font.GothamBold
    txt.TextSize = 11
    txt.Parent = sec
end

local function AddToggle(parent, text, default, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -4, 0, 32)
    frame.BackgroundTransparency = 1
    frame.Parent = parent
    
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -48, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = Colors.SubText
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 11
    lbl.Parent = frame
    
    local bg = Instance.new("Frame")
    bg.Size = UDim2.new(0, 42, 0, 22)
    bg.Position = UDim2.new(1, -44, 0.5, -11)
    bg.BackgroundColor3 = Colors.Card2
    bg.BorderSizePixel = 0
    bg.Parent = frame
    ApplyCorner(bg, 11)
    ApplyStroke(bg, Colors.White, 1, 0.8)
    
    local dot = Instance.new("Frame")
    dot.Size = UDim2.new(0, 16, 0, 16)
    dot.Position = UDim2.new(0, 3, 0.5, -8)
    dot.BackgroundColor3 = Colors.SubText
    dot.BorderSizePixel = 0
    dot.Parent = bg
    ApplyCorner(dot, 8)
    
    local state = default or false
    
    local function update()
        if state then
            Tween(dot, {Position = UDim2.new(1, -19, 0.5, -8), BackgroundColor3 = Colors.White}, 0.15)
            Tween(bg, {BackgroundColor3 = Colors.Accent}, 0.15)
            for _, s in ipairs(bg:GetChildren()) do if s:IsA("UIStroke") then s.Color = Colors.Accent end end
        else
            Tween(dot, {Position = UDim2.new(0, 3, 0.5, -8), BackgroundColor3 = Colors.SubText}, 0.15)
            Tween(bg, {BackgroundColor3 = Colors.Card2}, 0.15)
            for _, s in ipairs(bg:GetChildren()) do if s:IsA("UIStroke") then s.Color = Colors.White end end
        end
    end
    
    update()
    
    bg.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            state = not state
            update()
            if callback then callback(state) end
        end
    end)
    
    return {Set = function(v) state = v; update() end, Get = function() return state end}
end

local function AddSlider(parent, text, min, max, default, float, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -4, 0, 48)
    frame.BackgroundTransparency = 1
    frame.Parent = parent
    
    local top = Instance.new("Frame")
    top.Size = UDim2.new(1, 0, 0, 18)
    top.BackgroundTransparency = 1
    top.Parent = frame
    
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -50, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = Colors.SubText
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 11
    lbl.Parent = top
    
    local valLbl = Instance.new("TextLabel")
    valLbl.Size = UDim2.new(0, 45, 1, 0)
    valLbl.Position = UDim2.new(1, -45, 0, 0)
    valLbl.BackgroundTransparency = 1
    valLbl.Text = tostring(default)
    valLbl.TextColor3 = Colors.Accent
    valLbl.TextXAlignment = Enum.TextXAlignment.Right
    valLbl.Font = Enum.Font.GothamBold
    valLbl.TextSize = 11
    valLbl.Parent = top
    
    local sliderFrame = Instance.new("Frame")
    sliderFrame.Size = UDim2.new(1, 0, 0, 22)
    sliderFrame.Position = UDim2.new(0, 0, 0, 20)
    sliderFrame.BackgroundTransparency = 1
    sliderFrame.Parent = frame
    
    local sliderBg = Instance.new("TextButton")
    sliderBg.Size = UDim2.new(1, 0, 0, 6)
    sliderBg.Position = UDim2.new(0, 0, 0.5, -3)
    sliderBg.BackgroundColor3 = Colors.Card2
    sliderBg.BorderSizePixel = 0
    sliderBg.Text = ""
    sliderBg.AutoButtonColor = false
    sliderBg.Parent = sliderFrame
    ApplyCorner(sliderBg, 3)
    
    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    fill.BackgroundColor3 = Colors.Accent
    fill.BorderSizePixel = 0
    fill.Parent = sliderBg
    ApplyCorner(fill, 3)
    ApplyGradient(fill, Colors.Accent, Colors.AccentLight)
    
    local value = default
    local drag = false
    
    local function updateSlider(input)
        local pct = math.clamp((input.Position.X - sliderBg.AbsolutePosition.X) / sliderBg.AbsoluteSize.X, 0, 1)
        value = min + (max - min) * pct
        if not float then value = math.round(value) end
        value = math.clamp(value, min, max)
        fill.Size = UDim2.new((value - min) / (max - min), 0, 1, 0)
        valLbl.Text = tostring(value)
        if callback then callback(value) end
    end
    
    sliderBg.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            drag = true; updateSlider(i)
        end
    end)
    Connect(UserInputService.InputChanged, function(i)
        if drag and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then updateSlider(i) end
    end)
    Connect(UserInputService.InputEnded, function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then drag = false end
    end)
    
    return {Set = function(v) value = math.clamp(v, min, max); fill.Size = UDim2.new((value - min) / (max - min), 0, 1, 0); valLbl.Text = tostring(value); if callback then callback(value) end end}
end

local function AddButton(parent, text, callback, color)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -4, 0, 36)
    btn.BackgroundColor3 = color or Colors.Accent
    btn.BackgroundTransparency = 0.15
    btn.BorderSizePixel = 0
    btn.Text = text
    btn.TextColor3 = Colors.White
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 11
    btn.Parent = parent
    ApplyCorner(btn, 10)
    ApplyStroke(btn, color or Colors.Accent, 1, 0.3)
    
    btn.MouseEnter:Connect(function() Tween(btn, {BackgroundTransparency = 0.05}, 0.15) end)
    btn.MouseLeave:Connect(function() Tween(btn, {BackgroundTransparency = 0.15}, 0.15) end)
    btn.MouseButton1Click:Connect(callback)
    if isMobile then btn.TouchTap:Connect(callback) end
end

local function EnableFly()
    if Settings.FlyEnabled then return end
    Settings.FlyEnabled = true
    local char = getCharacter()
    local hum = char:WaitForChild("Humanoid")
    local root = char:WaitForChild("HumanoidRootPart")
    hum.PlatformStand = true
    
    local bv = Instance.new("BodyVelocity")
    bv.Velocity = Vector3.zero
    bv.MaxForce = Vector3.new(400000, 400000, 400000)
    bv.Parent = root
    Settings.FlyBV = bv
    
    local bg = Instance.new("BodyGyro")
    bg.MaxTorque = Vector3.new(400000, 400000, 400000)
    bg.CFrame = Camera.CFrame
    bg.Parent = root
    Settings.FlyBG = bg
    
    local keysDown = {}
    
    local keyBegan = UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        keysDown[input.KeyCode] = true
    end)
    table.insert(Connections, keyBegan)
    
    local keyEnded = UserInputService.InputEnded:Connect(function(input)
        keysDown[input.KeyCode] = false
    end)
    table.insert(Connections, keyEnded)
    
    Settings.FlyConn = Connect(RunService.RenderStepped, function()
        if not Settings.FlyEnabled then return end
        local dir = Vector3.zero
        if keysDown[Enum.KeyCode.W] then dir += Camera.CFrame.LookVector end
        if keysDown[Enum.KeyCode.S] then dir -= Camera.CFrame.LookVector end
        if keysDown[Enum.KeyCode.A] then dir -= Camera.CFrame.RightVector end
        if keysDown[Enum.KeyCode.D] then dir += Camera.CFrame.RightVector end
        if keysDown[Enum.KeyCode.Space] then dir += Vector3.new(0, 1, 0) end
        if keysDown[Enum.KeyCode.LeftShift] then dir -= Vector3.new(0, 1, 0) end
        if dir.Magnitude > 0 then dir = dir.Unit * Settings.FlySpeed end
        bv.Velocity = dir
        bg.CFrame = Camera.CFrame
    end)
end

local function DisableFly()
    Settings.FlyEnabled = false
    safeCall(function()
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then hum.PlatformStand = false end
        end
        if Settings.FlyBV then Settings.FlyBV:Destroy() end
        if Settings.FlyBG then Settings.FlyBG:Destroy() end
        if Settings.FlyConn then Settings.FlyConn:Disconnect() end
    end)
end

local function EnableNoClip()
    if Settings.NoClipEnabled then return end
    Settings.NoClipEnabled = true
    Settings.NoClipConn = Connect(RunService.Stepped, function()
        if not Settings.NoClipEnabled then return end
        safeCall(function()
            local char = LocalPlayer.Character
            if char then
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BasePart") and part.CanCollide then
                        part.CanCollide = false
                    end
                end
            end
        end)
    end)
end

local function DisableNoClip()
    Settings.NoClipEnabled = false
    if Settings.NoClipConn then Settings.NoClipConn:Disconnect() end
    safeCall(function()
        local char = LocalPlayer.Character
        if char then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = true
                end
            end
        end
    end)
end

local function EnableESP()
    if Settings.ESPEnabled then return end
    Settings.ESPEnabled = true
    
    local function createESP(player)
        if player == LocalPlayer then return end
        if Settings.ESPBoxes[player] then return end
        
        local char = player.Character
        if not char then char = player.CharacterAdded:Wait() end
        
        local root = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Head")
        if not root then root = char:WaitForChild("HumanoidRootPart") end
        
        local box = Instance.new("Frame", ScreenGui)
        box.Size = UDim2.new(0, 0, 0, 0)
        box.BackgroundColor3 = Colors.Accent
        box.BackgroundTransparency = 0.55
        box.BorderSizePixel = 0
        ApplyCorner(box, 3)
        ApplyStroke(box, Colors.Accent, 1.5, 0)
        
        local nameLabel = Instance.new("TextLabel", ScreenGui)
        nameLabel.Size = UDim2.new(0, 120, 0, 16)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = player.Name
        nameLabel.TextColor3 = Colors.White
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.TextSize = 10
        nameLabel.TextStrokeTransparency = 0.3
        
        local healthBg = Instance.new("Frame", ScreenGui)
        healthBg.Size = UDim2.new(0, 60, 0, 4)
        healthBg.BackgroundColor3 = Colors.Card
        healthBg.BackgroundTransparency = 0.3
        healthBg.BorderSizePixel = 0
        ApplyCorner(healthBg, 2)
        
        local healthFill = Instance.new("Frame", healthBg)
        healthFill.Size = UDim2.new(1, 0, 1, 0)
        healthFill.BackgroundColor3 = Colors.Success
        healthFill.BorderSizePixel = 0
        ApplyCorner(healthFill, 2)
        
        local distLabel = Instance.new("TextLabel", ScreenGui)
        distLabel.Size = UDim2.new(0, 60, 0, 14)
        distLabel.BackgroundTransparency = 1
        distLabel.Text = ""
        distLabel.TextColor3 = Colors.SubText
        distLabel.Font = Enum.Font.Gotham
        distLabel.TextSize = 9
        
        local conn = Connect(RunService.RenderStepped, function()
            if not Settings.ESPEnabled or not root or not root.Parent then
                box.Visible = false; nameLabel.Visible = false
                healthBg.Visible = false; distLabel.Visible = false
                return
            end
            
            local pos, onScreen = Camera:WorldToViewportPoint(root.Position)
            if onScreen then
                local scale = math.clamp(1 / pos.Z * 80, 25, 90)
                local boxHeight = scale * 1.8
                
                box.Visible = true
                box.Size = UDim2.new(0, scale, 0, boxHeight)
                box.Position = UDim2.new(0, pos.X - scale/2, 0, pos.Y - boxHeight/2)
                
                nameLabel.Visible = true
                nameLabel.Position = UDim2.new(0, pos.X - 60, 0, pos.Y - boxHeight/2 - 18)
                nameLabel.Text = player.Name
                
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum then
                    local healthPercent = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
                    healthFill.Size = UDim2.new(healthPercent, 0, 1, 0)
                    healthFill.BackgroundColor3 = healthPercent > 0.6 and Colors.Success or (healthPercent > 0.3 and Colors.Warning or Colors.Danger)
                end
                
                healthBg.Visible = true
                healthBg.Position = UDim2.new(0, pos.X - 30, 0, pos.Y + boxHeight/2 + 6)
                
                local localRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if localRoot then
                    local dist = (localRoot.Position - root.Position).Magnitude
                    distLabel.Text = string.format("%.0f m", dist)
                end
                
                distLabel.Visible = true
                distLabel.Position = UDim2.new(0, pos.X - 30, 0, pos.Y + boxHeight/2 + 16)
                
                local isEnemy = player.Team and LocalPlayer.Team and player.Team ~= LocalPlayer.Team
                local color = isEnemy and Colors.Danger or Colors.Accent
                box.BackgroundColor3 = color
                for _, s in ipairs(box:GetChildren()) do if s:IsA("UIStroke") then s.Color = color end end
            else
                box.Visible = false; nameLabel.Visible = false
                healthBg.Visible = false; distLabel.Visible = false
            end
        end)
        
        Settings.ESPBoxes[player] = {box, nameLabel, healthBg, distLabel, conn}
    end
    
    for _, p in ipairs(Players:GetPlayers()) do createESP(p) end
    
    local playerAddedConn = Players.PlayerAdded:Connect(function(p)
        if Settings.ESPEnabled then
            p.CharacterAdded:Connect(function()
                task.wait(0.3)
                createESP(p)
            end)
        end
    end)
    table.insert(Connections, playerAddedConn)
    
    local playerRemovingConn = Players.PlayerRemoving:Connect(function(p)
        if Settings.ESPBoxes[p] then
            for _, obj in ipairs(Settings.ESPBoxes[p]) do
                safeCall(function() obj:Destroy() end)
            end
            Settings.ESPBoxes[p] = nil
        end
    end)
    table.insert(Connections, playerRemovingConn)
end

local function DisableESP()
    Settings.ESPEnabled = false
    for _, data in pairs(Settings.ESPBoxes) do
        for _, obj in ipairs(data) do
            safeCall(function() obj:Destroy() end)
        end
    end
    Settings.ESPBoxes = {}
end

local function EnableAutoAttack()
    if Settings.AutoAttack then return end
    Settings.AutoAttack = true
    Settings.AutoAttackConn = Connect(RunService.Heartbeat, function()
        if not Settings.AutoAttack then return end
        safeCall(function()
            local char = LocalPlayer.Character
            if not char then return end
            local root = char:FindFirstChild("HumanoidRootPart")
            if not root then return end
            
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p.Character then
                    local targetRoot = p.Character:FindFirstChild("HumanoidRootPart")
                    local targetHum = p.Character:FindFirstChildOfClass("Humanoid")
                    if targetRoot and targetHum and targetHum.Health > 0 then
                        local dist = (root.Position - targetRoot.Position).Magnitude
                        if dist < Settings.AttackRange then
                            root.CFrame = CFrame.lookAt(root.Position, Vector3.new(targetRoot.Position.X, root.Position.Y, targetRoot.Position.Z))
                            if dist < 10 then
                                for _, tool in ipairs(char:GetChildren()) do
                                    if tool:IsA("Tool") then tool:Activate() end
                                end
                            end
                        end
                    end
                end
            end
        end)
    end)
end

local function DisableAutoAttack()
    Settings.AutoAttack = false
    if Settings.AutoAttackConn then Settings.AutoAttackConn:Disconnect() end
end

local function EnableAntiKB()
    if Settings.AntiKnockback then return end
    Settings.AntiKnockback = true
    Settings.AntiKBConn = Connect(RunService.RenderStepped, function()
        if not Settings.AntiKnockback then return end
        safeCall(function()
            local char = LocalPlayer.Character
            if char then
                for _, v in ipairs(char:GetDescendants()) do
                    if v:IsA("BodyVelocity") and v ~= Settings.FlyBV then v:Destroy() end
                    if v:IsA("BodyPosition") then v:Destroy() end
                end
            end
        end)
    end)
end

local function DisableAntiKB()
    Settings.AntiKnockback = false
    if Settings.AntiKBConn then Settings.AntiKBConn:Disconnect() end
end

local function EnableFPSBoost()
    Settings.FPSBoost = true
    safeCall(function()
        settings().Rendering.QualityLevel = 1
        settings().Rendering.MeshPartDetailLevel = Enum.MeshPartDetailLevel.Level01
    end)
    for _, v in ipairs(workspace:GetDescendants()) do
        if v:IsA("BasePart") and v.Material == Enum.Material.Grass then
            v.Material = Enum.Material.SmoothPlastic
        end
    end
    SendNotification("✅ FPS Boost đã bật", 2, Colors.Success)
end

local function DisableFPSBoost()
    Settings.FPSBoost = false
    safeCall(function()
        settings().Rendering.QualityLevel = 10
        settings().Rendering.MeshPartDetailLevel = Enum.MeshPartDetailLevel.Level04
    end)
    SendNotification("FPS Boost đã tắt", 2, Colors.Warning)
end

local function EnableLowGraphics()
    Settings.LowGraphics = true
    Lighting.GlobalShadows = false
    Lighting.FogEnd = 100
    Lighting.Brightness = 1
    safeCall(function() settings().Rendering.QualityLevel = 1 end)
    for _, v in ipairs(workspace:GetDescendants()) do
        if v:IsA("BasePart") then
            v.Material = Enum.Material.SmoothPlastic
            v.Reflectance = 0
        end
        if v:IsA("Texture") or v:IsA("Decal") then
            safeCall(function() v:Destroy() end)
        end
    end
    SendNotification("✅ Đồ họa thấp đã bật", 2, Colors.Success)
end

local function DisableLowGraphics()
    Settings.LowGraphics = false
    Lighting.GlobalShadows = true
    Lighting.FogEnd = 10000
    safeCall(function() settings().Rendering.QualityLevel = 10 end)
    SendNotification("Đồ họa đã khôi phục", 2, Colors.Warning)
end

local function SavePosition(slot)
    slot = slot or 1
    safeCall(function()
        Settings.SavedPositions[slot] = getRootPart().CFrame
        SendNotification("📌 Đã lưu vị trí Slot " .. slot, 2, Colors.Success)
    end)
end

local function LoadPosition(slot)
    slot = slot or 1
    safeCall(function()
        local root = getRootPart()
        if Settings.SavedPositions[slot] then
            root.CFrame = Settings.SavedPositions[slot]
            SendNotification("🌀 Đã dịch chuyển đến Slot " .. slot, 2, Colors.Success)
        end
    end)
end

local function TeleportToNearestPlayer()
    safeCall(function()
        local root = getRootPart()
        local nearest = nil
        local minDist = math.huge
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character then
                local targetRoot = p.Character:FindFirstChild("HumanoidRootPart")
                if targetRoot then
                    local dist = (root.Position - targetRoot.Position).Magnitude
                    if dist < minDist then
                        minDist = dist
                        nearest = targetRoot
                    end
                end
            end
        end
        if nearest then
            root.CFrame = nearest.CFrame + Vector3.new(0, 3, 0)
            SendNotification("🌀 Đã dịch chuyển", 2, Colors.Success)
        end
    end)
end

do
    local c = TabContainers["Home"]
    CreateSection(c, "🏠 CHÀO MỪNG")
    local welcomeFrame = Instance.new("Frame")
    welcomeFrame.Size = UDim2.new(1, -4, 0, 80)
    welcomeFrame.BackgroundColor3 = Colors.Card
    welcomeFrame.BackgroundTransparency = 0.4
    welcomeFrame.BorderSizePixel = 0
    welcomeFrame.Parent = c
    ApplyCorner(welcomeFrame, 12)
    ApplyStroke(welcomeFrame, Colors.White, 1, 0.85)
    
    local w = Instance.new("TextLabel")
    w.Size = UDim2.new(1, -16, 1, 0)
    w.Position = UDim2.new(0, 8, 0, 0)
    w.BackgroundTransparency = 1
    w.Text = "⚡ FLOATING HUB v2.0\n\n👆 Kéo Bubble để di chuyển\n👆 Chạm Bubble để mở Hub\n📱 Kéo thanh tiêu đề để di chuyển menu"
    w.TextColor3 = Colors.SubText
    w.Font = Enum.Font.Gotham
    w.TextSize = 11
    w.TextXAlignment = Enum.TextXAlignment.Left
    w.RichText = true
    w.Parent = welcomeFrame
end

do
    local c = TabContainers["Main"]
    CreateSection(c, "✈️ BAY (FLY)")
    AddToggle(c, "Bật Bay", false, function(v)
        if v then EnableFly() else DisableFly() end
    end)
    AddSlider(c, "Tốc độ bay", 20, 300, 50, false, function(v) Settings.FlySpeed = v end)
    
    CreateSection(c, "🚶 DI CHUYỂN")
    AddSlider(c, "Tốc độ đi bộ", 16, 300, 16, false, function(v)
        Settings.Walkspeed = v
        safeCall(function() getHumanoid().WalkSpeed = v end)
    end)
    AddSlider(c, "Sức nhảy", 50, 500, 50, false, function(v)
        Settings.Jumppower = v
        safeCall(function() getHumanoid().JumpPower = v end)
    end)
    AddToggle(c, "Xuyên tường (NoClip)", false, function(v)
        if v then EnableNoClip() else DisableNoClip() end
    end)
end

do
    local c = TabContainers["Player"]
    CreateSection(c, "👤 NHÂN VẬT")
    AddToggle(c, "Nhảy vô hạn", false, function(v)
        Settings.InfiniteJump = v
        if v then
            if Settings.InfJumpConn then Settings.InfJumpConn:Disconnect() end
            Settings.InfJumpConn = Connect(UserInputService.JumpRequest, function()
                safeCall(function() getHumanoid():ChangeState(Enum.HumanoidStateType.Jumping) end)
            end)
        else
            if Settings.InfJumpConn then Settings.InfJumpConn:Disconnect() end
        end
    end)
    AddToggle(c, "Không bị đẩy lùi", false, function(v)
        if v then EnableAntiKB() else DisableAntiKB() end
    end)
    
    CreateSection(c, "🎭 NGOẠI HÌNH")
    AddSlider(c, "FOV (Trường nhìn)", 30, 120, 70, false, function(v)
        Camera.FieldOfView = v
    end)
end

do
    local c = TabContainers["Visual"]
    CreateSection(c, "👁️ ESP NGƯỜI CHƠI")
    AddToggle(c, "Bật ESP", false, function(v)
        if v then EnableESP() else DisableESP() end
    end)
    
    CreateSection(c, "🌍 THẾ GIỚI")
    AddToggle(c, "Xuyên tường (Wallhack)", false, function(v)
        Settings.Wallhack = v
        for _, o in ipairs(workspace:GetDescendants()) do
            if o:IsA("BasePart") and not o.Parent:FindFirstChildOfClass("Humanoid") then
                o.LocalTransparencyModifier = v and 0.6 or 0
            end
        end
    end)
    AddToggle(c, "Đèn nền (Fullbright)", false, function(v)
        Settings.Fullbright = v
        Lighting.Brightness = v and 2 or 1
        Lighting.ClockTime = 14
        Lighting.FogEnd = v and 100000 or 10000
    end)
    AddToggle(c, "Đồ họa thấp", false, function(v)
        if v then EnableLowGraphics() else DisableLowGraphics() end
    end)
    AddToggle(c, "FPS Boost", false, function(v)
        if v then EnableFPSBoost() else DisableFPSBoost() end
    end)
end

do
    local c = TabContainers["Teleport"]
    CreateSection(c, "📌 LƯU VỊ TRÍ")
    AddButton(c, "Lưu vị trí (Slot 1)", function() SavePosition(1) end, Colors.Accent)
    AddButton(c, "Dịch chuyển về Slot 1", function() LoadPosition(1) end, Colors.Success)
    AddButton(c, "Lưu vị trí (Slot 2)", function() SavePosition(2) end, Colors.Accent)
    AddButton(c, "Dịch chuyển về Slot 2", function() LoadPosition(2) end, Colors.Success)
    
    CreateSection(c, "🌀 DỊCH CHUYỂN NHANH")
    AddButton(c, "Bay đến người chơi gần nhất", TeleportToNearestPlayer, Colors.Warning)
end

do
    local c = TabContainers["Combat"]
    CreateSection(c, "⚔️ CHIẾN ĐẤU")
    AddToggle(c, "Tự động tấn công", false, function(v)
        if v then EnableAutoAttack() else DisableAutoAttack() end
    end)
    AddSlider(c, "Phạm vi tấn công", 5, 50, 20, false, function(v) Settings.AttackRange = v end)
end

do
    local c = TabContainers["Misc"]
    CreateSection(c, "🎯 TIỆN ÍCH")
    AddButton(c, "Dọn dẹp workspace", function()
        local count = 0
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("BasePart") and obj.Transparency >= 0.95 and not obj.Parent:FindFirstChildOfClass("Humanoid") then
                obj:Destroy()
                count = count + 1
            end
        end
        SendNotification("🧹 Đã xóa " .. count .. " object", 2, Colors.Success)
    end, Colors.Danger)
    
    AddButton(c, "Reset nhân vật", function()
        safeCall(function() LocalPlayer.Character:BreakJoints() end)
        SendNotification("🔄 Đã reset nhân vật", 2, Colors.Warning)
    end, Colors.Warning)
end

do
    local c = TabContainers["Settings"]
    CreateSection(c, "🔧 HỆ THỐNG")
    AddButton(c, "Hủy giao diện (Unload)", function()
        Settings.ESPEnabled = false
        Settings.FlyEnabled = false
        Settings.NoClipEnabled = false
        Settings.AutoAttack = false
        Settings.InfiniteJump = false
        Settings.AntiKnockback = false
        Settings.FPSBoost = false
        Settings.LowGraphics = false
        Settings.Wallhack = false
        Settings.Fullbright = false
        
        DisableFly()
        DisableNoClip()
        DisableESP()
        DisableAutoAttack()
        DisableAntiKB()
        DisableFPSBoost()
        DisableLowGraphics()
        
        for _, data in pairs(Settings.ESPBoxes) do
            for _, obj in ipairs(data) do
                safeCall(function() obj:Destroy() end)
            end
        end
        Settings.ESPBoxes = {}
        
        CleanupConnections()
        ScreenGui:Destroy()
    end, Colors.Danger)
end

SelectTab("Home")
SendNotification("✨ Chạm Bubble để mở Hub | Kéo để di chuyển", 4, Colors.Accent)