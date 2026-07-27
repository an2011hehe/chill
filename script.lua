local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local Lighting = game:GetService("Lighting")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

if not game:IsLoaded() then game.Loaded:Wait() end

repeat task.wait() until LocalPlayer and LocalPlayer.Character
repeat task.wait() until LocalPlayer.Character:FindFirstChild("HumanoidRootPart")

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "PremiumHubPro"
ScreenGui.Parent = CoreGui
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder = 999
ScreenGui.ResetOnSpawn = false

local MainFrame = Instance.new("Frame")
MainFrame.Name = "Main"
MainFrame.Size = UDim2.fromOffset(620, 520)
MainFrame.Position = UDim2.new(0.5, -310, 0.5, -260)
MainFrame.BackgroundColor3 = Color3.fromRGB(17, 17, 17)
MainFrame.BackgroundTransparency = 0
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = true
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 16)
MainCorner.Parent = MainFrame

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(255, 255, 255)
MainStroke.Thickness = 1.5
MainStroke.Transparency = 0.9
MainStroke.Parent = MainFrame

local BgImage = Instance.new("ImageLabel")
BgImage.Name = "BackgroundImage"
BgImage.Size = UDim2.new(1, 0, 1, 0)
BgImage.Position = UDim2.new(0, 0, 0, 0)
BgImage.BackgroundTransparency = 1
BgImage.Image = "https://i.postimg.cc/pr06jTmc/Messenger-creation-6997B64B-4FA2-4673-86DC-672451D8A8A4.jpg"
BgImage.ScaleType = Enum.ScaleType.Crop
BgImage.ZIndex = 0
BgImage.Parent = MainFrame

local BgCorner = Instance.new("UICorner")
BgCorner.CornerRadius = UDim.new(0, 16)
BgCorner.Parent = BgImage

local DarkOverlay = Instance.new("Frame")
DarkOverlay.Name = "DarkOverlay"
DarkOverlay.Size = UDim2.new(1, 0, 1, 0)
DarkOverlay.Position = UDim2.new(0, 0, 0, 0)
DarkOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
DarkOverlay.BackgroundTransparency = 0.4
DarkOverlay.BorderSizePixel = 0
DarkOverlay.ZIndex = 1
DarkOverlay.Parent = MainFrame

local OverlayCorner = Instance.new("UICorner")
OverlayCorner.CornerRadius = UDim.new(0, 16)
OverlayCorner.Parent = DarkOverlay

local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 48)
TitleBar.BackgroundColor3 = Color3.fromRGB(26, 26, 26)
TitleBar.BackgroundTransparency = 0.2
TitleBar.BorderSizePixel = 0
TitleBar.ZIndex = 2
TitleBar.Parent = MainFrame

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 16)
TitleCorner.Parent = TitleBar

local TitleFix = Instance.new("Frame")
TitleFix.Size = UDim2.new(1, 0, 0, 16)
TitleFix.Position = UDim2.new(0, 0, 1, -16)
TitleFix.BackgroundColor3 = Color3.fromRGB(26, 26, 26)
TitleFix.BackgroundTransparency = 0.2
TitleFix.BorderSizePixel = 0
TitleFix.ZIndex = 2
TitleFix.Parent = TitleBar

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(0, 200, 1, 0)
TitleLabel.Position = UDim2.new(0, 16, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "PREMIUM HUB PRO"
TitleLabel.TextColor3 = Color3.fromRGB(240, 240, 245)
TitleLabel.Font = Enum.Font.GothamBlack
TitleLabel.TextSize = 14
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.ZIndex = 2
TitleLabel.Parent = TitleBar

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 32, 0, 32)
CloseBtn.Position = UDim2.new(1, -40, 0.5, -16)
CloseBtn.BackgroundColor3 = Color3.fromRGB(255, 70, 70)
CloseBtn.BackgroundTransparency = 0.85
CloseBtn.BorderSizePixel = 0
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 14
CloseBtn.ZIndex = 2
CloseBtn.Parent = TitleBar

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 16)
CloseCorner.Parent = CloseBtn

local isDragging = false
local dragStart = nil
local startPos = nil

TitleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        isDragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if isDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(
            startPos.X.Scale, math.clamp(startPos.X.Offset + delta.X, 0, Camera.ViewportSize.X - MainFrame.AbsoluteSize.X),
            startPos.Y.Scale, math.clamp(startPos.Y.Offset + delta.Y, 0, Camera.ViewportSize.Y - MainFrame.AbsoluteSize.Y)
        )
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        isDragging = false
    end
end)

CloseBtn.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

local Sidebar = Instance.new("Frame")
Sidebar.Size = UDim2.new(0, 160, 1, -48)
Sidebar.Position = UDim2.new(0, 0, 0, 48)
Sidebar.BackgroundColor3 = Color3.fromRGB(26, 26, 26)
Sidebar.BackgroundTransparency = 0.4
Sidebar.BorderSizePixel = 0
Sidebar.ZIndex = 2
Sidebar.Parent = MainFrame

local SidebarScroll = Instance.new("ScrollingFrame")
SidebarScroll.Size = UDim2.new(1, 0, 1, -10)
SidebarScroll.Position = UDim2.new(0, 0, 0, 10)
SidebarScroll.BackgroundTransparency = 1
SidebarScroll.BorderSizePixel = 0
SidebarScroll.ScrollBarThickness = 0
SidebarScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
SidebarScroll.ZIndex = 2
SidebarScroll.Parent = Sidebar

local SidebarList = Instance.new("UIListLayout")
SidebarList.Padding = UDim.new(0, 4)
SidebarList.HorizontalAlignment = Enum.HorizontalAlignment.Center
SidebarList.Parent = SidebarScroll

local ContentArea = Instance.new("Frame")
ContentArea.Size = UDim2.new(1, -160, 1, -48)
ContentArea.Position = UDim2.new(0, 160, 0, 48)
ContentArea.BackgroundColor3 = Color3.fromRGB(17, 17, 17)
ContentArea.BorderSizePixel = 0
ContentArea.ClipsDescendants = true
ContentArea.ZIndex = 2
ContentArea.Parent = MainFrame

local Tabs = {
    {Name = "Main", Icon = "home"},
    {Name = "Player", Icon = "user"},
    {Name = "Aimbot", Icon = "crosshair"},
    {Name = "Visual", Icon = "eye"},
    {Name = "Teleport", Icon = "move"},
    {Name = "Misc", Icon = "settings"},
}

local TabButtons = {}
local TabContainers = {}
local CurrentTab = nil

for _, tab in ipairs(Tabs) do
    local container = Instance.new("ScrollingFrame")
    container.Size = UDim2.new(1, -16, 1, -16)
    container.Position = UDim2.new(0, 8, 0, 8)
    container.BackgroundTransparency = 1
    container.BorderSizePixel = 0
    container.ScrollBarThickness = 3
    container.ScrollBarImageColor3 = Color3.fromRGB(139, 92, 246)
    container.ScrollBarImageTransparency = 0.4
    container.CanvasSize = UDim2.new(0, 0, 0, 1200)
    container.Visible = false
    container.ZIndex = 2
    container.Parent = ContentArea

    local list = Instance.new("UIListLayout")
    list.Padding = UDim.new(0, 10)
    list.Parent = container

    TabContainers[tab.Name] = container
end

local function SelectTab(name)
    CurrentTab = name
    for n, c in pairs(TabContainers) do
        c.Visible = (n == name)
    end
    for n, d in pairs(TabButtons) do
        local sel = (n == name)
        local btn = d.Btn
        local label = d.Label
        local targetTrans = sel and 0.72 or 1
        local targetColor = sel and Color3.fromRGB(139, 92, 246) or Color3.fromRGB(255, 255, 255)
        local targetText = sel and Color3.fromRGB(240, 240, 245) or Color3.fromRGB(150, 150, 160)
        TweenService:Create(btn, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            BackgroundTransparency = targetTrans,
            BackgroundColor3 = targetColor,
        }):Play()
        TweenService:Create(label, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            TextColor3 = targetText,
        }):Play()
    end
end

for _, tab in ipairs(Tabs) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -16, 0, 42)
    btn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    btn.BackgroundTransparency = 1
    btn.BorderSizePixel = 0
    btn.Text = ""
    btn.AutoButtonColor = false
    btn.ZIndex = 2
    btn.Parent = SidebarScroll

    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 13)
    btnCorner.Parent = btn

    local iconLabel = Instance.new("TextLabel")
    iconLabel.Size = UDim2.new(0, 30, 1, 0)
    iconLabel.Position = UDim2.new(0, 14, 0, 0)
    iconLabel.BackgroundTransparency = 1
    iconLabel.Text = tab.Icon
    iconLabel.TextColor3 = Color3.fromRGB(150, 150, 160)
    iconLabel.Font = Enum.Font.Gotham
    iconLabel.TextSize = 17
    iconLabel.ZIndex = 2
    iconLabel.Parent = btn

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, -52, 1, 0)
    nameLabel.Position = UDim2.new(0, 48, 0, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = tab.Name
    nameLabel.TextColor3 = Color3.fromRGB(150, 150, 160)
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextSize = 12
    nameLabel.ZIndex = 2
    nameLabel.Parent = btn

    btn.MouseButton1Click:Connect(function()
        SelectTab(tab.Name)
    end)

    TabButtons[tab.Name] = {Btn = btn, Label = nameLabel}
end

SelectTab("Main")

local function CreateSection(parent, title)
    local sec = Instance.new("Frame")
    sec.Size = UDim2.new(1, 0, 0, 40)
    sec.BackgroundColor3 = Color3.fromRGB(26, 26, 26)
    sec.BackgroundTransparency = 0.4
    sec.BorderSizePixel = 0
    sec.ZIndex = 2
    sec.Parent = parent

    local secCorner = Instance.new("UICorner")
    secCorner.CornerRadius = UDim.new(0, 14)
    secCorner.Parent = sec

    local secStroke = Instance.new("UIStroke")
    secStroke.Color = Color3.fromRGB(255, 255, 255)
    secStroke.Thickness = 1
    secStroke.Transparency = 0.88
    secStroke.Parent = sec

    local accent = Instance.new("Frame")
    accent.Size = UDim2.new(0, 3, 0, 20)
    accent.Position = UDim2.new(0, 14, 0.5, -10)
    accent.BackgroundColor3 = Color3.fromRGB(139, 92, 246)
    accent.BorderSizePixel = 0
    accent.ZIndex = 2
    accent.Parent = sec

    local accentCorner = Instance.new("UICorner")
    accentCorner.CornerRadius = UDim.new(0, 2)
    accentCorner.Parent = accent

    local txt = Instance.new("TextLabel")
    txt.Size = UDim2.new(1, -28, 1, 0)
    txt.Position = UDim2.new(0, 24, 0, 0)
    txt.BackgroundTransparency = 1
    txt.Text = title
    txt.TextColor3 = Color3.fromRGB(240, 240, 245)
    txt.TextXAlignment = Enum.TextXAlignment.Left
    txt.Font = Enum.Font.GothamBold
    txt.TextSize = 11
    txt.ZIndex = 2
    txt.Parent = sec
end

local function AddToggle(parent, text, default, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 32)
    frame.BackgroundTransparency = 1
    frame.ZIndex = 2
    frame.Parent = parent

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -48, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = Color3.fromRGB(150, 150, 160)
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 11
    lbl.ZIndex = 2
    lbl.Parent = frame

    local bg = Instance.new("Frame")
    bg.Size = UDim2.new(0, 44, 0, 24)
    bg.Position = UDim2.new(1, -46, 0.5, -12)
    bg.BackgroundColor3 = Color3.fromRGB(32, 32, 40)
    bg.BorderSizePixel = 0
    bg.ZIndex = 2
    bg.Parent = frame

    local bgCorner = Instance.new("UICorner")
    bgCorner.CornerRadius = UDim.new(0, 12)
    bgCorner.Parent = bg

    local bgStroke = Instance.new("UIStroke")
    bgStroke.Color = Color3.fromRGB(255, 255, 255)
    bgStroke.Thickness = 1
    bgStroke.Transparency = 0.8
    bgStroke.Parent = bg

    local dot = Instance.new("Frame")
    dot.Size = UDim2.new(0, 18, 0, 18)
    dot.Position = UDim2.new(0, 3, 0.5, -9)
    dot.BackgroundColor3 = Color3.fromRGB(150, 150, 160)
    dot.BorderSizePixel = 0
    dot.ZIndex = 2
    dot.Parent = bg

    local dotCorner = Instance.new("UICorner")
    dotCorner.CornerRadius = UDim.new(0, 9)
    dotCorner.Parent = dot

    local state = default or false

    local function update()
        if state then
            TweenService:Create(dot, TweenInfo.new(0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                Position = UDim2.new(1, -21, 0.5, -9),
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            }):Play()
            TweenService:Create(bg, TweenInfo.new(0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                BackgroundColor3 = Color3.fromRGB(139, 92, 246),
            }):Play()
        else
            TweenService:Create(dot, TweenInfo.new(0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                Position = UDim2.new(0, 3, 0.5, -9),
                BackgroundColor3 = Color3.fromRGB(150, 150, 160),
            }):Play()
            TweenService:Create(bg, TweenInfo.new(0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                BackgroundColor3 = Color3.fromRGB(32, 32, 40),
            }):Play()
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
    frame.Size = UDim2.new(1, 0, 0, 48)
    frame.BackgroundTransparency = 1
    frame.ZIndex = 2
    frame.Parent = parent

    local top = Instance.new("Frame")
    top.Size = UDim2.new(1, 0, 0, 18)
    top.BackgroundTransparency = 1
    top.ZIndex = 2
    top.Parent = frame

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -50, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = Color3.fromRGB(150, 150, 160)
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 11
    lbl.ZIndex = 2
    lbl.Parent = top

    local valLbl = Instance.new("TextLabel")
    valLbl.Size = UDim2.new(0, 45, 1, 0)
    valLbl.Position = UDim2.new(1, -45, 0, 0)
    valLbl.BackgroundTransparency = 1
    valLbl.Text = tostring(default)
    valLbl.TextColor3 = Color3.fromRGB(139, 92, 246)
    valLbl.TextXAlignment = Enum.TextXAlignment.Right
    valLbl.Font = Enum.Font.GothamBold
    valLbl.TextSize = 11
    valLbl.ZIndex = 2
    valLbl.Parent = top

    local sf = Instance.new("Frame")
    sf.Size = UDim2.new(1, 0, 0, 22)
    sf.Position = UDim2.new(0, 0, 0, 20)
    sf.BackgroundTransparency = 1
    sf.ZIndex = 2
    sf.Parent = frame

    local sliderBg = Instance.new("TextButton")
    sliderBg.Size = UDim2.new(1, 0, 0, 6)
    sliderBg.Position = UDim2.new(0, 0, 0.5, -3)
    sliderBg.BackgroundColor3 = Color3.fromRGB(32, 32, 40)
    sliderBg.BorderSizePixel = 0
    sliderBg.Text = ""
    sliderBg.AutoButtonColor = false
    sliderBg.ZIndex = 2
    sliderBg.Parent = sf

    local sliderBgCorner = Instance.new("UICorner")
    sliderBgCorner.CornerRadius = UDim.new(0, 3)
    sliderBgCorner.Parent = sliderBg

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(139, 92, 246)
    fill.BorderSizePixel = 0
    fill.ZIndex = 2
    fill.Parent = sliderBg

    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(0, 3)
    fillCorner.Parent = fill

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

    UserInputService.InputChanged:Connect(function(i)
        if drag and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            updateSlider(i)
        end
    end)

    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            drag = false
        end
    end)

    return {Set = function(v) value = math.clamp(v, min, max); fill.Size = UDim2.new((value - min) / (max - min), 0, 1, 0); valLbl.Text = tostring(value); if callback then callback(value) end end}
end

local function AddButton(parent, text, callback, color)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 38)
    btn.BackgroundColor3 = color or Color3.fromRGB(139, 92, 246)
    btn.BackgroundTransparency = 0.12
    btn.BorderSizePixel = 0
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 11
    btn.ZIndex = 2
    btn.Parent = parent

    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 10)
    btnCorner.Parent = btn

    local btnStroke = Instance.new("UIStroke")
    btnStroke.Color = color or Color3.fromRGB(139, 92, 246)
    btnStroke.Thickness = 1.5
    btnStroke.Transparency = 0.25
    btnStroke.Parent = btn

    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            BackgroundTransparency = 0.03,
        }):Play()
    end)

    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            BackgroundTransparency = 0.12,
        }):Play()
    end)

    btn.MouseButton1Down:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.05, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            Size = UDim2.new(1, 0, 0, 35),
        }):Play()
    end)

    btn.MouseButton1Up:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.05, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            Size = UDim2.new(1, 0, 0, 38),
        }):Play()
    end)

    btn.MouseButton1Click:Connect(callback)

    return btn
end

local Settings = {
    FlyEnabled = false,
    FlySpeed = 50,
    FlyBV = nil,
    FlyBG = nil,
    FlyConn = nil,
    NoClipEnabled = false,
    NoClipConn = nil,
    InfiniteJump = false,
    InfJumpConn = nil,
    InfiniteJumpLastTime = 0,
    AntiKnockback = false,
    AntiKBConn = nil,
    ESPEnabled = false,
    ESPBoxes = {},
    ESPGui = nil,
    Wallhack = false,
    WallhackConn = nil,
    Fullbright = false,
    FullbrightConn = nil,
    FPSBoost = false,
    LowGraphics = false,
    TeleportMark = nil,
    AimbotEnabled = false,
    AimbotSmoothness = 0.5,
    AimbotConn = nil,
    ESPHighlight = true,
    ESPTracer = true,
}

local Connections = {}

local function Hook(signal, callback)
    local conn = signal:Connect(callback)
    table.insert(Connections, conn)
    return conn
end

local function KillConnections()
    for i = #Connections, 1, -1 do
        local conn = Connections[i]
        if conn and conn.Connected then conn:Disconnect() end
        table.remove(Connections, i)
    end
end

local function safeCall(func, ...)
    local s, r = pcall(func, ...)
    if not s then warn("[PremiumHubPro] Error:", r) end
    return s, r
end

local function getChar()
    local c = LocalPlayer.Character
    if not c then LocalPlayer.CharacterAdded:Wait(); c = LocalPlayer.Character end
    return c
end

local function getHum()
    local c = getChar()
    local h = c:FindFirstChildOfClass("Humanoid")
    if not h then h = c:WaitForChild("Humanoid", 10) end
    return h
end

local function getRoot()
    local c = getChar()
    local r = c:FindFirstChild("HumanoidRootPart")
    if not r then r = c:WaitForChild("HumanoidRootPart", 10) end
    return r
end

local function EnableFly()
    if Settings.FlyEnabled then return end
    Settings.FlyEnabled = true
    local c = getChar(); local h = getHum(); local r = getRoot()
    h.PlatformStand = true

    local bv = Instance.new("BodyVelocity")
    bv.Name = "FlyVelocity"; bv.Velocity = Vector3.zero
    bv.MaxForce = Vector3.new(1e9, 1e9, 1e9); bv.Parent = r
    Settings.FlyBV = bv

    local bg = Instance.new("BodyGyro")
    bg.Name = "FlyGyro"; bg.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
    bg.CFrame = Camera.CFrame; bg.Parent = r
    Settings.FlyBG = bg

    local keysDown = {}
    Hook(UserInputService.InputBegan, function(i, g) if not g and Settings.FlyEnabled then keysDown[i.KeyCode] = true end end)
    Hook(UserInputService.InputEnded, function(i) keysDown[i.KeyCode] = false end)

    Settings.FlyConn = Hook(RunService.RenderStepped, function()
        if not Settings.FlyEnabled then return end
        if not Settings.FlyBV or not Settings.FlyBV.Parent then DisableFly(); return end
        local d = Vector3.zero
        local cl = Camera.CFrame.LookVector; local cr = Camera.CFrame.RightVector
        if keysDown[Enum.KeyCode.W] then d = d + Vector3.new(cl.X, 0, cl.Z).Unit end
        if keysDown[Enum.KeyCode.S] then d = d - Vector3.new(cl.X, 0, cl.Z).Unit end
        if keysDown[Enum.KeyCode.A] then d = d - Vector3.new(cr.X, 0, cr.Z).Unit end
        if keysDown[Enum.KeyCode.D] then d = d + Vector3.new(cr.X, 0, cr.Z).Unit end
        if keysDown[Enum.KeyCode.Space] then d = d + Vector3.new(0, 1, 0) end
        if keysDown[Enum.KeyCode.LeftShift] then d = d - Vector3.new(0, 1, 0) end
        if d.Magnitude > 0 then d = d.Unit * Settings.FlySpeed end
        bv.Velocity = d; bg.CFrame = Camera.CFrame
        if h and h.PlatformStand ~= true then h.PlatformStand = true end
    end)
end

local function DisableFly()
    Settings.FlyEnabled = false
    safeCall(function()
        if Settings.FlyBV then Settings.FlyBV:Destroy(); Settings.FlyBV = nil end
        if Settings.FlyBG then Settings.FlyBG:Destroy(); Settings.FlyBG = nil end
        if Settings.FlyConn then Settings.FlyConn:Disconnect(); Settings.FlyConn = nil end
        local c = LocalPlayer.Character
        if c then local h = c:FindFirstChildOfClass("Humanoid") if h then h.PlatformStand = false end end
    end)
end

local function EnableNoClip()
    if Settings.NoClipEnabled then return end
    Settings.NoClipEnabled = true
    Settings.NoClipConn = Hook(RunService.Stepped, function()
        if not Settings.NoClipEnabled then return end
        safeCall(function()
            local c = LocalPlayer.Character; if not c then return end
            local d = c:GetDescendants()
            for i = 1, #d do local p = d[i] if p:IsA("BasePart") and p.CanCollide and not Settings.FlyEnabled then p.CanCollide = false end end
        end)
    end)
end

local function DisableNoClip()
    Settings.NoClipEnabled = false
    if Settings.NoClipConn then Settings.NoClipConn:Disconnect(); Settings.NoClipConn = nil end
    safeCall(function()
        local c = LocalPlayer.Character; if not c then return end
        local d = c:GetDescendants()
        for i = 1, #d do local p = d[i] if p:IsA("BasePart") then p.CanCollide = true end end
    end)
end

local INFINITE_JUMP_THROTTLE = 0.1

local function EnableInfiniteJump()
    if Settings.InfiniteJump then return end
    Settings.InfiniteJump = true
    if Settings.InfJumpConn then Settings.InfJumpConn:Disconnect() end
    Settings.InfiniteJumpLastTime = 0
    Settings.InfJumpConn = Hook(UserInputService.JumpRequest, function()
        if not Settings.InfiniteJump then return end
        local t = tick()
        if t - Settings.InfiniteJumpLastTime < INFINITE_JUMP_THROTTLE then return end
        Settings.InfiniteJumpLastTime = t
        safeCall(function()
            local c = LocalPlayer.Character; if not c then return end
            local h = c:FindFirstChildOfClass("Humanoid"); if not h then return end
            h:ChangeState(Enum.HumanoidStateType.Jumping)
        end)
    end)
end

local function DisableInfiniteJump()
    Settings.InfiniteJump = false
    if Settings.InfJumpConn then Settings.InfJumpConn:Disconnect(); Settings.InfJumpConn = nil end
end

local function EnableAntiKB()
    if Settings.AntiKnockback then return end
    Settings.AntiKnockback = true
    Settings.AntiKBConn = Hook(RunService.RenderStepped, function()
        if not Settings.AntiKnockback then return end
        safeCall(function()
            local c = LocalPlayer.Character; if not c then return end
            local d = c:GetDescendants()
            for i = 1, #d do
                local v = d[i]
                if v:IsA("BodyVelocity") and v ~= Settings.FlyBV then v:Destroy() end
                if v:IsA("BodyPosition") then v:Destroy() end
            end
        end)
    end)
end

local function DisableAntiKB()
    Settings.AntiKnockback = false
    if Settings.AntiKBConn then Settings.AntiKBConn:Disconnect(); Settings.AntiKBConn = nil end
end

local function EnableAimbot()
    if Settings.AimbotEnabled then return end
    Settings.AimbotEnabled = true
    Settings.AimbotConn = Hook(RunService.RenderStepped, function()
        if not Settings.AimbotEnabled then return end
        safeCall(function()
            local c = LocalPlayer.Character; if not c then return end
            local r = c:FindFirstChild("HumanoidRootPart"); if not r then return end
            local m = UserInputService:GetMouseLocation()
            local nt, md = nil, math.huge
            local ap = Players:GetPlayers()
            for i = 1, #ap do
                local tp = ap[i]
                if tp ~= LocalPlayer and tp.Character then
                    local tr = tp.Character:FindFirstChild("HumanoidRootPart")
                    local th = tp.Character:FindFirstChildOfClass("Humanoid")
                    if tr and th and th.Health > 0 then
                        local sp, os = Camera:WorldToViewportPoint(tr.Position)
                        if os then
                            local sv = Vector2.new(sp.X, sp.Y)
                            local dm = (sv - m).Magnitude
                            if dm < md and dm < 400 then md = dm; nt = tr end
                        end
                    end
                end
            end
            if nt then Camera.CFrame = CFrame.lookAt(Camera.CFrame.Position, nt.Position) end
        end)
    end)
end

local function DisableAimbot()
    Settings.AimbotEnabled = false
    if Settings.AimbotConn then Settings.AimbotConn:Disconnect(); Settings.AimbotConn = nil end
end

local function EnableESP()
    if Settings.ESPEnabled then return end
    Settings.ESPEnabled = true
    if Settings.ESPGui then Settings.ESPGui:Destroy() end
    local eg = Instance.new("ScreenGui")
    eg.Name = "ESPGui"; eg.Parent = CoreGui; eg.DisplayOrder = 999; eg.ResetOnSpawn = false
    Settings.ESPGui = eg

    local function ce(p)
        if p == LocalPlayer then return end
        local function se()
            local c = p.Character; if not c then return end
            local r = c:FindFirstChild("HumanoidRootPart") or c:FindFirstChild("Head")
            if not r then return end
            if Settings.ESPBoxes[p] then
                for _, o in ipairs(Settings.ESPBoxes[p]) do
                    if o and o.Destroy and typeof(o) ~= "RBXScriptConnection" then safeCall(function() o:Destroy() end) end
                end
            end

            local tr = Instance.new("Frame")
            tr.BackgroundColor3 = Color3.fromRGB(139, 92, 246); tr.BackgroundTransparency = 0.7; tr.BorderSizePixel = 0
            tr.Visible = false; tr.Parent = eg

            local bx = Instance.new("Frame")
            bx.BackgroundColor3 = Color3.fromRGB(139, 92, 246); bx.BackgroundTransparency = 0.6; bx.BorderSizePixel = 0
            bx.Visible = false; bx.Parent = eg
            Instance.new("UICorner", bx).CornerRadius = UDim.new(0, 3)
            local bs = Instance.new("UIStroke")
            bs.Color = Color3.fromRGB(139, 92, 246); bs.Thickness = 1.5; bs.Transparency = 0.3; bs.Parent = bx

            local nl = Instance.new("TextLabel")
            nl.BackgroundTransparency = 1; nl.Text = p.Name; nl.TextColor3 = Color3.fromRGB(255, 255, 255)
            nl.Font = Enum.Font.GothamBold; nl.TextSize = 11; nl.TextStrokeTransparency = 0.3
            nl.Visible = false; nl.Parent = eg

            local hb = Instance.new("Frame")
            hb.BackgroundColor3 = Color3.fromRGB(20, 20, 20); hb.BackgroundTransparency = 0.3; hb.BorderSizePixel = 0
            hb.Visible = false; hb.Parent = eg
            Instance.new("UICorner", hb).CornerRadius = UDim.new(0, 2)

            local hf = Instance.new("Frame")
            hf.BackgroundColor3 = Color3.fromRGB(50, 200, 100); hf.BorderSizePixel = 0; hf.Parent = hb
            Instance.new("UICorner", hf).CornerRadius = UDim.new(0, 2)

            local dl = Instance.new("TextLabel")
            dl.BackgroundTransparency = 1; dl.TextColor3 = Color3.fromRGB(160, 160, 170)
            dl.Font = Enum.Font.Gotham; dl.TextSize = 9; dl.Visible = false; dl.Parent = eg

            local hl = Instance.new("Highlight")
            hl.FillColor = Color3.fromRGB(139, 92, 246); hl.FillTransparency = 0.7
            hl.OutlineColor = Color3.fromRGB(139, 92, 246); hl.OutlineTransparency = 0.3
            hl.Enabled = Settings.ESPHighlight; hl.Parent = c

            local rc = Hook(RunService.RenderStepped, function()
                if not Settings.ESPEnabled then bx.Visible = false; nl.Visible = false; hb.Visible = false; dl.Visible = false; tr.Visible = false; if hl then hl.Enabled = false end; return end
                local cc = p.Character; if not cc then bx.Visible = false; nl.Visible = false; hb.Visible = false; dl.Visible = false; tr.Visible = false; return end
                local cr = cc:FindFirstChild("HumanoidRootPart") or cc:FindFirstChild("Head")
                if not cr or not cr:IsDescendantOf(workspace) then bx.Visible = false; nl.Visible = false; hb.Visible = false; dl.Visible = false; tr.Visible = false; return end
                if hl then hl.Parent = cc; hl.Enabled = Settings.ESPHighlight end
                local sp, os = Camera:WorldToViewportPoint(cr.Position)
                if not os then bx.Visible = false; nl.Visible = false; hb.Visible = false; dl.Visible = false; tr.Visible = false; return end
                local hm = cc:FindFirstChildOfClass("Humanoid")
                local dp = math.max(0.1, (Camera.CFrame.Position - cr.Position).Magnitude)
                local sc = math.clamp(200 / dp, 1.5, 4)
                local ms = cc:GetExtentsSize()
                local bw = math.clamp(ms.X * sc, 30, 120)
                local bh = math.clamp(ms.Y * sc, 50, 180)

                if Settings.ESPTracer then
                    local sc2 = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                    tr.Visible = true
                    local dx = sp.X - sc2.X; local dy = sc2.Y - sp.Y
                    local tl = math.sqrt(dx * dx + dy * dy)
                    tr.Size = UDim2.new(0, 1, 0, tl); tr.Position = UDim2.new(0, sp.X, 0, sp.Y)
                    tr.Rotation = math.deg(math.atan2(dy, dx)) - 90
                else tr.Visible = false end

                bx.Visible = true; bx.Size = UDim2.new(0, bw, 0, bh)
                bx.Position = UDim2.new(0, sp.X - bw / 2, 0, sp.Y - bh / 2)

                nl.Visible = true; nl.Size = UDim2.new(0, 120, 0, 16)
                nl.Position = UDim2.new(0, sp.X - 60, 0, sp.Y - bh / 2 - 20)

                if hm then
                    local hp = math.clamp(hm.Health / hm.MaxHealth, 0, 1)
                    hf.Size = UDim2.new(hp, 0, 1, 0)
                    if hp > 0.6 then hf.BackgroundColor3 = Color3.fromRGB(50, 200, 100)
                    elseif hp > 0.3 then hf.BackgroundColor3 = Color3.fromRGB(255, 180, 50)
                    else hf.BackgroundColor3 = Color3.fromRGB(255, 70, 70) end
                end

                hb.Visible = true; hb.Size = UDim2.new(0, bw, 0, 4)
                hb.Position = UDim2.new(0, sp.X - bw / 2, 0, sp.Y + bh / 2 + 6)

                local lc = LocalPlayer.Character
                if lc then
                    local lr = lc:FindFirstChild("HumanoidRootPart")
                    if lr then
                        dl.Visible = true; dl.Size = UDim2.new(0, 60, 0, 14)
                        dl.Position = UDim2.new(0, sp.X - 30, 0, sp.Y + bh / 2 + 14)
                        dl.Text = string.format("%.0f m", (lr.Position - cr.Position).Magnitude)
                    end
                end

                local ie = p.Team and LocalPlayer.Team and p.Team ~= LocalPlayer.Team
                local ec = ie and Color3.fromRGB(255, 70, 70) or Color3.fromRGB(139, 92, 246)
                bx.BackgroundColor3 = ec; bs.Color = ec; tr.BackgroundColor3 = ec
            end)

            Settings.ESPBoxes[p] = {bx, nl, hb, dl, rc, tr, hl}
        end

        if p.Character then se() end
        Hook(p.CharacterAdded, function() task.wait(0.3); if Settings.ESPEnabled then se() end end)
    end

    local ap = Players:GetPlayers()
    for i = 1, #ap do ce(ap[i]) end
    Hook(Players.PlayerAdded, function(p) if Settings.ESPEnabled then ce(p) end end)
    Hook(Players.PlayerRemoving, function(p)
        if Settings.ESPBoxes[p] then
            for _, o in ipairs(Settings.ESPBoxes[p]) do
                if o and o.Destroy and typeof(o) ~= "RBXScriptConnection" then safeCall(function() o:Destroy() end) end
            end
            Settings.ESPBoxes[p] = nil
        end
    end)
end

local function DisableESP()
    Settings.ESPEnabled = false
    for _, d in pairs(Settings.ESPBoxes) do
        for _, o in ipairs(d) do
            if o and o.Destroy and typeof(o) ~= "RBXScriptConnection" then safeCall(function() o:Destroy() end) end
        end
    end
    Settings.ESPBoxes = {}
    if Settings.ESPGui then Settings.ESPGui:Destroy(); Settings.ESPGui = nil end
end

local function EnableWallhack()
    if Settings.Wallhack then return end
    Settings.Wallhack = true
    local function aw(o)
        if o:IsA("BasePart") and not o.Parent:FindFirstChildOfClass("Humanoid") then o.LocalTransparencyModifier = 0.6 end
    end
    local ao = workspace:GetDescendants()
    for i = 1, #ao do aw(ao[i]) end
    Settings.WallhackConn = Hook(workspace.DescendantAdded, function(o) if Settings.Wallhack then aw(o) end end)
end

local function DisableWallhack()
    Settings.Wallhack = false
    if Settings.WallhackConn then Settings.WallhackConn:Disconnect(); Settings.WallhackConn = nil end
    local ao = workspace:GetDescendants()
    for i = 1, #ao do local o = ao[i] if o:IsA("BasePart") then o.LocalTransparencyModifier = 0 end end
end

local function EnableFullbright()
    if Settings.Fullbright then return end
    Settings.Fullbright = true
    Lighting.Brightness = 2; Lighting.ClockTime = 14; Lighting.FogEnd = 100000
    Settings.FullbrightConn = Hook(Lighting:GetPropertyChangedSignal("Brightness"), function()
        if Settings.Fullbright and Lighting.Brightness ~= 2 then Lighting.Brightness = 2 end
    end)
end

local function DisableFullbright()
    Settings.Fullbright = false
    if Settings.FullbrightConn then Settings.FullbrightConn:Disconnect(); Settings.FullbrightConn = nil end
    Lighting.Brightness = 1; Lighting.FogEnd = 10000
end

local function EnableFPSBoost()
    Settings.FPSBoost = true
    safeCall(function() settings().Rendering.QualityLevel = 1 end)
end

local function DisableFPSBoost()
    Settings.FPSBoost = false
    safeCall(function() settings().Rendering.QualityLevel = 10 end)
end

local function EnableLowGraphics()
    Settings.LowGraphics = true
    Lighting.GlobalShadows = false; Lighting.FogEnd = 100; Lighting.Brightness = 1
end

local function DisableLowGraphics()
    Settings.LowGraphics = false
    Lighting.GlobalShadows = true; Lighting.FogEnd = 10000
end

local function SetTeleportMark()
    safeCall(function()
        local r = getRoot()
        Settings.TeleportMark = r.CFrame
    end)
end

local function TeleportToMark()
    safeCall(function()
        if not Settings.TeleportMark then return end
        local r = getRoot(); r.CFrame = Settings.TeleportMark
    end)
end

local function TeleportToNearestPlayer()
    safeCall(function()
        local r = getRoot()
        local nr, md = nil, math.huge
        local ap = Players:GetPlayers()
        for i = 1, #ap do
            local tp = ap[i]
            if tp ~= LocalPlayer and tp.Character then
                local tr = tp.Character:FindFirstChild("HumanoidRootPart")
                if tr and tr:IsDescendantOf(workspace) then
                    local d = (r.Position - tr.Position).Magnitude
                    if d < md then md = d; nr = tr end
                end
            end
        end
        if nr then r.CFrame = nr.CFrame + Vector3.new(0, 3, 0) end
    end)
end

local function FindNearestTree()
    local r = getRoot(); if not r then return nil end
    local pp = r.Position
    local nt, md = nil, math.huge
    local tk = {"tree", "cay", "wood", "log", "pine", "oak", "birch", "maple", "palm", "trunk", "branch", "forest", "jungle", "timber", "lumber", "plant", "bush", "foliage", "bamboo", "cactus", "gỗ", "cây"}
    local ao = workspace:GetDescendants()
    for i = 1, #ao do
        local o = ao[i]; local it = false; local tp = nil
        if o:IsA("Model") then
            local n = string.lower(o.Name)
            for _, kw in ipairs(tk) do if string.find(n, kw) then it = true; break end end
            if it then
                tp = o:FindFirstChild("HumanoidRootPart") or o:FindFirstChild("Torso") or o:FindFirstChild("PrimaryPart")
                if not tp then local ch = o:GetChildren() for j = 1, #ch do if ch[j]:IsA("BasePart") then tp = ch[j]; break end end end
            end
        elseif o:IsA("BasePart") then
            local n = string.lower(o.Name)
            for _, kw in ipairs(tk) do if string.find(n, kw) then it = true; break end end
            if not it then
                if o.Material == Enum.Material.Wood or o.Material == Enum.Material.WoodPlanks then
                    local p = o.Parent
                    if p and not p:FindFirstChildOfClass("Humanoid") then
                        local pn = string.lower(p.Name)
                        for _, kw in ipairs(tk) do if string.find(pn, kw) then it = true; break end end
                    end
                end
            end
            if it then tp = o end
        end
        if it and tp and not tp.Parent:FindFirstChildOfClass("Humanoid") then
            local d = (pp - tp.Position).Magnitude
            if d < md and d < 500 then md = d; nt = tp end
        end
    end
    return nt
end

local function TeleportToNearestTree()
    safeCall(function()
        local t = FindNearestTree()
        if t then
            local r = getRoot(); r.CFrame = CFrame.new(t.Position + Vector3.new(0, 5, 0))
        end
    end)
end

local function ResetCharacter()
    safeCall(function()
        local c = LocalPlayer.Character; if c then c:BreakJoints() end
    end)
end

local function UnloadAll()
    Settings.FlyEnabled = false; Settings.NoClipEnabled = false; Settings.ESPEnabled = false
    Settings.InfiniteJump = false; Settings.AntiKnockback = false; Settings.AimbotEnabled = false
    Settings.Wallhack = false; Settings.Fullbright = false; Settings.FPSBoost = false; Settings.LowGraphics = false

    safeCall(function() if Settings.FlyBV then Settings.FlyBV:Destroy(); Settings.FlyBV = nil end; if Settings.FlyBG then Settings.FlyBG:Destroy(); Settings.FlyBG = nil end end)
    safeCall(function()
        local c = LocalPlayer.Character
        if c then
            local h = c:FindFirstChildOfClass("Humanoid"); if h then h.PlatformStand = false end
            local d = c:GetDescendants()
            for i = 1, #d do local p = d[i] if p:IsA("BasePart") then p.CanCollide = true end end
        end
    end)
    for _, ed in pairs(Settings.ESPBoxes) do
        for _, o in ipairs(ed) do if o and o.Destroy and typeof(o) ~= "RBXScriptConnection" then safeCall(function() o:Destroy() end) end end
    end
    Settings.ESPBoxes = {}
    if Settings.ESPGui then Settings.ESPGui:Destroy(); Settings.ESPGui = nil end
    Lighting.Brightness = 1; Lighting.FogEnd = 10000; Lighting.GlobalShadows = true
    local ao = workspace:GetDescendants()
    for i = 1, #ao do local o = ao[i] if o:IsA("BasePart") then o.LocalTransparencyModifier = 0 end end
    safeCall(function() settings().Rendering.QualityLevel = 10 end)
    KillConnections()
    ScreenGui:Destroy()
end

local mainContainer = TabContainers["Main"]

CreateSection(mainContainer, "Fly")
AddToggle(mainContainer, "Bật Bay", false, function(s) if s then EnableFly() else DisableFly() end end)
AddSlider(mainContainer, "Tốc độ bay", 20, 300, 50, false, function(v) Settings.FlySpeed = v end)

CreateSection(mainContainer, "Di chuyển")
AddSlider(mainContainer, "Tốc độ", 16, 300, 16, false, function(v) safeCall(function() getHum().WalkSpeed = v end) end)
AddSlider(mainContainer, "Sức nhảy", 50, 500, 50, false, function(v) safeCall(function() getHum().JumpPower = v end) end)
AddToggle(mainContainer, "NoClip", false, function(s) if s then EnableNoClip() else DisableNoClip() end end)

local playerContainer = TabContainers["Player"]

CreateSection(playerContainer, "Nhân vật")
AddToggle(playerContainer, "Nhảy vô hạn", false, function(s) if s then EnableInfiniteJump() else DisableInfiniteJump() end end)
AddToggle(playerContainer, "Anti Knockback", false, function(s) if s then EnableAntiKB() else DisableAntiKB() end end)
AddSlider(playerContainer, "FOV", 30, 120, 70, false, function(v) Camera.FieldOfView = v end)

local aimbotContainer = TabContainers["Aimbot"]

CreateSection(aimbotContainer, "Aimbot")
AddToggle(aimbotContainer, "Bật Aimbot", false, function(s) if s then EnableAimbot() else DisableAimbot() end end)
AddSlider(aimbotContainer, "Độ mượt", 0.1, 1.0, 0.5, true, function(v) Settings.AimbotSmoothness = v end)

local visualContainer = TabContainers["Visual"]

CreateSection(visualContainer, "ESP")
AddToggle(visualContainer, "Bật ESP", false, function(s) if s then EnableESP() else DisableESP() end end)
AddToggle(visualContainer, "Highlight", true, function(s) Settings.ESPHighlight = s end)
AddToggle(visualContainer, "Tracer", true, function(s) Settings.ESPTracer = s end)

CreateSection(visualContainer, "Thế giới")
AddToggle(visualContainer, "Wallhack", false, function(s) if s then EnableWallhack() else DisableWallhack() end end)
AddToggle(visualContainer, "Fullbright", false, function(s) if s then EnableFullbright() else DisableFullbright() end end)
AddToggle(visualContainer, "Đồ họa thấp", false, function(s) if s then EnableLowGraphics() else DisableLowGraphics() end end)
AddToggle(visualContainer, "FPS Boost", false, function(s) if s then EnableFPSBoost() else DisableFPSBoost() end end)

local teleportContainer = TabContainers["Teleport"]

CreateSection(teleportContainer, "Đánh dấu")
AddButton(teleportContainer, "Đặt điểm", SetTeleportMark, Color3.fromRGB(139, 92, 246))
AddButton(teleportContainer, "Dịch chuyển về", TeleportToMark, Color3.fromRGB(50, 200, 100))

CreateSection(teleportContainer, "Dịch chuyển nhanh")
AddButton(teleportContainer, "Đến cây gần nhất", TeleportToNearestTree, Color3.fromRGB(255, 180, 50))
AddButton(teleportContainer, "Đến người chơi gần nhất", TeleportToNearestPlayer, Color3.fromRGB(255, 180, 50))

local miscContainer = TabContainers["Misc"]

CreateSection(miscContainer, "Tiện ích")
AddButton(miscContainer, "Reset nhân vật", ResetCharacter, Color3.fromRGB(255, 70, 70))
AddButton(miscContainer, "Unload", UnloadAll, Color3.fromRGB(255, 70, 70))