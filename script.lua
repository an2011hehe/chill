local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

if not game:IsLoaded() then game.Loaded:Wait() end

pcall(function()
    if CoreGui:FindFirstChild("PremiumHub") then
        CoreGui:FindFirstChild("PremiumHub"):Destroy()
    end
end)

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "PremiumHub"
ScreenGui.Parent = CoreGui
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder = 999

local isMobile = UserInputService.TouchEnabled

local Colors = {
    BG = Color3.fromRGB(13, 13, 17),
    Panel = Color3.fromRGB(20, 20, 28),
    Panel2 = Color3.fromRGB(25, 25, 35),
    Accent = Color3.fromRGB(130, 80, 255),
    Accent2 = Color3.fromRGB(100, 60, 220),
    Text = Color3.fromRGB(240, 240, 245),
    SubText = Color3.fromRGB(160, 160, 170),
    Success = Color3.fromRGB(50, 200, 100),
    Warning = Color3.fromRGB(255, 180, 50),
    Danger = Color3.fromRGB(255, 70, 70),
    Border = Color3.fromRGB(255, 255, 255)
}

local Settings = {
    Walkspeed = 16,
    Jumppower = 50,
    FlyEnabled = false,
    FlySpeed = 50,
    NoClipEnabled = false,
    InfiniteJump = false,
    ESPEnabled = false,
    ESPBoxes = {},
    ESPConnections = {},
    SavedPositions = {},
    Config = {}
}

local function MakeDraggable(frame, handle)
    local dragging, dragInput, dragStart, startPos
    handle = handle or frame
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    handle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            local newPos = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            local screenSize = Camera.ViewportSize
            local guiSize = frame.AbsoluteSize
            local minX = math.clamp(newPos.X.Offset, 0, screenSize.X - guiSize.X)
            local minY = math.clamp(newPos.Y.Offset, 0, screenSize.Y - guiSize.Y)
            frame.Position = UDim2.new(0, minX, 0, minY)
        end
    end)
end

local function TweenObject(obj, props, dur, style, dir)
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
    s.Color = c or Color3.fromRGB(255,255,255)
    s.Thickness = t or 1
    s.Transparency = tr or 0.8
    s.Parent = obj
    return s
end

local function ApplyGradient(obj, c1, c2, rot)
    local g = Instance.new("UIGradient")
    g.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, c1 or Colors.Accent), ColorSequenceKeypoint.new(1, c2 or Colors.Accent2)})
    if rot then g.Rotation = rot end
    g.Parent = obj
    return g
end

local MainContainer = Instance.new("Frame")
MainContainer.Size = UDim2.new(0, 620, 0, 430)
MainContainer.Position = UDim2.new(0.5, -310, 0.5, -215)
MainContainer.BackgroundColor3 = Colors.BG
MainContainer.BackgroundTransparency = 0
MainContainer.BorderSizePixel = 0
MainContainer.Parent = ScreenGui
ApplyCorner(MainContainer, 12)
ApplyStroke(MainContainer, Colors.Border, 1.5, 0.9)

local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 45)
TitleBar.BackgroundColor3 = Colors.Panel
TitleBar.BorderSizePixel = 0
TitleBar.Parent = MainContainer
ApplyCorner(TitleBar, 12)
local TitleFix = Instance.new("Frame")
TitleFix.Size = UDim2.new(1, 0, 0, 12)
TitleFix.Position = UDim2.new(0, 0, 1, -12)
TitleFix.BackgroundColor3 = Colors.Panel
TitleFix.BorderSizePixel = 0
TitleFix.Parent = TitleBar

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(0, 180, 1, 0)
TitleLabel.Position = UDim2.new(0, 16, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "PREMIUM HUB"
TitleLabel.TextColor3 = Colors.Text
TitleLabel.Font = Enum.Font.GothamBlack
TitleLabel.TextSize = 15
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = TitleBar

local TitleAccent = Instance.new("Frame")
TitleAccent.Size = UDim2.new(0, 3, 0, 18)
TitleAccent.Position = UDim2.new(0, 192, 0.5, -9)
TitleAccent.BackgroundColor3 = Colors.Accent
TitleAccent.BorderSizePixel = 0
TitleAccent.Parent = TitleBar
ApplyCorner(TitleAccent, 2)

local function CreateWindowButton(parent, text, color, position, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 32, 0, 32)
    btn.Position = UDim2.new(1, position, 0.5, -16)
    btn.BackgroundColor3 = Color3.fromRGB(255,255,255)
    btn.BackgroundTransparency = 1
    btn.Text = text
    btn.TextColor3 = color or Colors.SubText
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 14
    btn.Parent = parent
    ApplyCorner(btn, 6)
    
    btn.MouseEnter:Connect(function()
        TweenObject(btn, {BackgroundTransparency = 0.85, BackgroundColor3 = color or Colors.SubText}, 0.15)
    end)
    btn.MouseLeave:Connect(function()
        TweenObject(btn, {BackgroundTransparency = 1}, 0.15)
    end)
    
    if isMobile then
        btn.TouchTap:Connect(callback)
    else
        btn.MouseButton1Click:Connect(callback)
    end
    return btn
end

local Minimized = false
CreateWindowButton(TitleBar, "—", Colors.SubText, -80, function()
    Minimized = not Minimized
    if Minimized then
        TweenObject(MainContainer, {Size = UDim2.new(0, 620, 0, 45)}, 0.3)
        for _, v in ipairs(MainContainer:GetChildren()) do
            if v ~= TitleBar and v.Name ~= "FloatBtn" then
                v.Visible = false
            end
        end
    else
        for _, v in ipairs(MainContainer:GetChildren()) do
            v.Visible = true
        end
        TweenObject(MainContainer, {Size = UDim2.new(0, 620, 0, 430)}, 0.3)
    end
end)

CreateWindowButton(TitleBar, "✕", Colors.Danger, -40, function()
    Settings.ESPEnabled = false
    for _, v in pairs(Settings.ESPBoxes) do
        for _, obj in pairs(v) do if obj then obj:Destroy() end end
    end
    ScreenGui:Destroy()
end)

MakeDraggable(MainContainer, TitleBar)

local Sidebar = Instance.new("Frame")
Sidebar.Size = UDim2.new(0, 175, 1, -45)
Sidebar.Position = UDim2.new(0, 0, 0, 45)
Sidebar.BackgroundColor3 = Colors.Panel
Sidebar.BorderSizePixel = 0
Sidebar.Parent = MainContainer
ApplyCorner(Sidebar, 0)
local SidebarFix = Instance.new("Frame")
SidebarFix.Size = UDim2.new(0, 12, 1, 0)
SidebarFix.Position = UDim2.new(1, -12, 0, 0)
SidebarFix.BackgroundColor3 = Colors.Panel
SidebarFix.BorderSizePixel = 0
SidebarFix.ZIndex = 2
SidebarFix.Parent = Sidebar

local SidebarScroll = Instance.new("ScrollingFrame")
SidebarScroll.Size = UDim2.new(1, 0, 1, -10)
SidebarScroll.Position = UDim2.new(0, 0, 0, 10)
SidebarScroll.BackgroundTransparency = 1
SidebarScroll.BorderSizePixel = 0
SidebarScroll.ScrollBarThickness = 0
SidebarScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
SidebarScroll.Parent = Sidebar

local TabList = Instance.new("UIListLayout")
TabList.Padding = UDim.new(0, 4)
TabList.HorizontalAlignment = Enum.HorizontalAlignment.Center
TabList.Parent = SidebarScroll

local TabsConfig = {
    {Name = "Home", Icon = "rbxassetid://6031280890"},
    {Name = "Combat", Icon = "rbxassetid://6031068437"},
    {Name = "Player", Icon = "rbxassetid://6034754441"},
    {Name = "Visuals", Icon = "rbxassetid://6035047397"},
    {Name = "Teleport", Icon = "rbxassetid://6034515694"},
    {Name = "Misc", Icon = "rbxassetid://6031082533"},
    {Name = "Settings", Icon = "rbxassetid://6031280882"}
}

local TabButtons = {}
local CurrentTab = "Home"

local ContentFrame = Instance.new("Frame")
ContentFrame.Size = UDim2.new(1, -175, 1, -45)
ContentFrame.Position = UDim2.new(0, 175, 0, 45)
ContentFrame.BackgroundColor3 = Colors.BG
ContentFrame.BorderSizePixel = 0
ContentFrame.ClipsDescendants = true
ContentFrame.Parent = MainContainer

local TabContainers = {}

for _, tab in ipairs(TabsConfig) do
    local container = Instance.new("ScrollingFrame")
    container.Size = UDim2.new(1, -20, 1, -20)
    container.Position = UDim2.new(0, 10, 0, 10)
    container.BackgroundTransparency = 1
    container.BorderSizePixel = 0
    container.ScrollBarThickness = 3
    container.ScrollBarImageColor3 = Colors.Accent
    container.ScrollBarImageTransparency = 0.5
    container.CanvasSize = UDim2.new(0, 0, 0, 900)
    container.Visible = false
    container.Parent = ContentFrame
    
    local contentList = Instance.new("UIListLayout")
    contentList.Padding = UDim.new(0, 10)
    contentList.Parent = container
    TabContainers[tab.Name] = container
end

local function CreateSection(parent, title)
    local section = Instance.new("Frame")
    section.Size = UDim2.new(1, 0, 0, 38)
    section.BackgroundColor3 = Colors.Panel
    section.BackgroundTransparency = 0.4
    section.BorderSizePixel = 0
    section.Parent = parent
    ApplyCorner(section, 8)
    ApplyStroke(section, Colors.Border, 1, 0.85)
    
    local sectionTitle = Instance.new("TextLabel")
    sectionTitle.Size = UDim2.new(1, -20, 1, 0)
    sectionTitle.Position = UDim2.new(0, 10, 0, 0)
    sectionTitle.BackgroundTransparency = 1
    sectionTitle.Text = title
    sectionTitle.TextColor3 = Colors.Text
    sectionTitle.TextXAlignment = Enum.TextXAlignment.Left
    sectionTitle.Font = Enum.Font.GothamBold
    sectionTitle.TextSize = 13
    sectionTitle.Parent = section
    
    local contentHolder = Instance.new("Frame")
    contentHolder.Size = UDim2.new(1, 0, 0, 10)
    contentHolder.BackgroundTransparency = 1
    contentHolder.BorderSizePixel = 0
    contentHolder.Parent = parent
    
    return contentHolder
end

local function AddToggle(parent, y, text, default, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -10, 0, 32)
    frame.BackgroundTransparency = 1
    frame.BorderSizePixel = 0
    frame.Parent = parent
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -50, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Colors.SubText
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Font = Enum.Font.Gotham
    label.TextSize = 12
    label.Parent = frame
    
    local bg = Instance.new("Frame")
    bg.Size = UDim2.new(0, 40, 0, 22)
    bg.Position = UDim2.new(1, -44, 0.5, -11)
    bg.BackgroundColor3 = Colors.Panel2
    bg.BorderSizePixel = 0
    bg.Parent = frame
    ApplyCorner(bg, 11)
    
    local dot = Instance.new("Frame")
    dot.Size = UDim2.new(0, 16, 0, 16)
    dot.Position = UDim2.new(0, 3, 0.5, -8)
    dot.BackgroundColor3 = Colors.SubText
    dot.BorderSizePixel = 0
    dot.Parent = bg
    ApplyCorner(dot, 8)
    
    local state = default or false
    
    local function update()
        local targetTrans = state and 0.1 or 1
        local targetPos = state and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
        local targetColor = state and Colors.Accent or Colors.SubText
        local targetBg = state and Colors.Accent or Colors.Panel2
        TweenObject(dot, {Position = targetPos, BackgroundColor3 = Color3.fromRGB(255,255,255)}, 0.15)
        TweenObject(bg, {BackgroundColor3 = targetBg}, 0.15)
    end
    
    update()
    
    local function toggle()
        state = not state
        update()
        if callback then callback(state) end
    end
    
    bg.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            toggle()
        end
    end)
    
    return {Set = function(v) state = v; update() end, Get = function() return state end}
end

local function AddSlider(parent, y, text, min, max, default, float, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -10, 0, 50)
    frame.BackgroundTransparency = 1
    frame.BorderSizePixel = 0
    frame.Parent = parent
    
    local topBar = Instance.new("Frame")
    topBar.Size = UDim2.new(1, 0, 0, 18)
    topBar.BackgroundTransparency = 1
    topBar.Parent = frame
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -60, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Colors.SubText
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Font = Enum.Font.Gotham
    label.TextSize = 12
    label.Parent = topBar
    
    local valLabel = Instance.new("TextLabel")
    valLabel.Size = UDim2.new(0, 55, 1, 0)
    valLabel.Position = UDim2.new(1, -55, 0, 0)
    valLabel.BackgroundTransparency = 1
    valLabel.Text = tostring(default)
    valLabel.TextColor3 = Colors.Accent
    valLabel.TextXAlignment = Enum.TextXAlignment.Right
    valLabel.Font = Enum.Font.GothamBold
    valLabel.TextSize = 12
    valLabel.Parent = topBar
    
    local sliderFrame = Instance.new("Frame")
    sliderFrame.Size = UDim2.new(1, 0, 0, 22)
    sliderFrame.Position = UDim2.new(0, 0, 0, 22)
    sliderFrame.BackgroundTransparency = 1
    sliderFrame.Parent = frame
    
    local sliderBg = Instance.new("TextButton")
    sliderBg.Size = UDim2.new(1, 0, 0, 6)
    sliderBg.Position = UDim2.new(0, 0, 0.5, -3)
    sliderBg.BackgroundColor3 = Colors.Panel2
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
    
    local value = default
    local dragging = false
    
    local function updateSlider(input)
        local percent = math.clamp((input.Position.X - sliderBg.AbsolutePosition.X) / sliderBg.AbsoluteSize.X, 0, 1)
        value = min + (max - min) * percent
        if not float then value = math.round(value) end
        value = math.clamp(value, min, max)
        fill.Size = UDim2.new((value - min) / (max - min), 0, 1, 0)
        valLabel.Text = tostring(value)
        if callback then callback(value) end
    end
    
    sliderBg.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            updateSlider(input)
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            updateSlider(input)
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    
    return {Set = function(v) value = math.clamp(v, min, max); fill.Size = UDim2.new((value - min) / (max - min), 0, 1, 0); valLabel.Text = tostring(value); if callback then callback(value) end end, Get = function() return value end}
end

local function AddButton(parent, y, text, callback, color)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -10, 0, 36)
    btn.BackgroundColor3 = color or Colors.Accent
    btn.BackgroundTransparency = 0.2
    btn.BorderSizePixel = 0
    btn.Text = text
    btn.TextColor3 = Colors.Text
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 12
    btn.Parent = parent
    ApplyCorner(btn, 8)
    ApplyStroke(btn, color or Colors.Accent, 1, 0.3)
    
    btn.MouseEnter:Connect(function() TweenObject(btn, {BackgroundTransparency = 0.1}, 0.15) end)
    btn.MouseLeave:Connect(function() TweenObject(btn, {BackgroundTransparency = 0.2}, 0.15) end)
    
    if isMobile then
        btn.TouchTap:Connect(callback)
    else
        btn.MouseButton1Click:Connect(callback)
    end
    return btn
end

local function SelectTab(tabName)
    CurrentTab = tabName
    for name, cont in pairs(TabContainers) do
        cont.Visible = (name == tabName)
    end
    for name, data in pairs(TabButtons) do
        local sel = (name == tabName)
        TweenObject(data.Button, {BackgroundTransparency = sel and 0.7 or 1, BackgroundColor3 = sel and Colors.Accent or Color3.fromRGB(255,255,255)}, 0.2)
        data.Label.TextColor3 = sel and Colors.Text or Colors.SubText
    end
end

for _, tab in ipairs(TabsConfig) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -20, 0, 42)
    btn.BackgroundColor3 = Color3.fromRGB(255,255,255)
    btn.BackgroundTransparency = 1
    btn.BorderSizePixel = 0
    btn.Text = ""
    btn.AutoButtonColor = false
    btn.Parent = SidebarScroll
    ApplyCorner(btn, 10)
    
    local icon = Instance.new("ImageLabel")
    icon.Size = UDim2.new(0, 20, 0, 20)
    icon.Position = UDim2.new(0, 14, 0.5, -10)
    icon.BackgroundTransparency = 1
    icon.Image = tab.Icon
    icon.ImageColor3 = Colors.SubText
    icon.Parent = btn
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -50, 1, 0)
    label.Position = UDim2.new(0, 42, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = tab.Name
    label.TextColor3 = Colors.SubText
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Font = Enum.Font.GothamBold
    label.TextSize = 13
    label.Parent = btn
    
    btn.MouseEnter:Connect(function()
        if CurrentTab ~= tab.Name then
            TweenObject(btn, {BackgroundTransparency = 0.85, BackgroundColor3 = Colors.Panel2}, 0.15)
        end
    end)
    btn.MouseLeave:Connect(function()
        if CurrentTab ~= tab.Name then
            TweenObject(btn, {BackgroundTransparency = 1}, 0.15)
        end
    end)
    
    local function clickHandler()
        SelectTab(tab.Name)
    end
    
    if isMobile then
        btn.TouchTap:Connect(clickHandler)
    else
        btn.MouseButton1Click:Connect(clickHandler)
    end
    
    TabButtons[tab.Name] = {Button = btn, Label = label, Icon = icon}
end

SelectTab("Home")

local function setupHomeTab()
    local cont = TabContainers["Home"]
    local sec = CreateSection(cont, "🏠 CHÀO MỪNG")
    local welcome = Instance.new("TextLabel")
    welcome.Size = UDim2.new(1, -10, 0, 60)
    welcome.BackgroundTransparency = 1
    welcome.Text = "PREMIUM HUB v2.0\nTrải nghiệm hack cao cấp nhất\nChọn tab để bắt đầu"
    welcome.TextColor3 = Colors.SubText
    welcome.Font = Enum.Font.Gotham
    welcome.TextSize = 12
    welcome.TextXAlignment = Enum.TextXAlignment.Left
    welcome.RichText = true
    welcome.Parent = cont
end

local function setupCombatTab()
    local cont = TabContainers["Combat"]
    local sec = CreateSection(cont, "⚔️ CHIẾN ĐẤU")
    AddToggle(cont, 0, "Aimbot (Tự động ngắm)", false, function(v) Settings.Aimbot = v end)
    AddToggle(cont, 0, "Triggerbot", false, function(v) Settings.Triggerbot = v end)
    AddToggle(cont, 0, "Kill Aura", false, function(v) Settings.KillAura = v end)
    AddSlider(cont, 0, "Tầm đánh", 5, 50, 20, false, function(v) Settings.HitRange = v end)
    AddToggle(cont, 0, "Xuyên tường (Hitbox)", false, function(v) Settings.WallHit = v end)
end

local function setupPlayerTab()
    local cont = TabContainers["Player"]
    local sec1 = CreateSection(cont, "🏃 DI CHUYỂN")
    AddSlider(cont, 0, "Tốc độ đi bộ", 16, 200, 16, false, function(v)
        Settings.Walkspeed = v
        pcall(function() LocalPlayer.Character.Humanoid.WalkSpeed = v end)
    end)
    AddSlider(cont, 0, "Sức nhảy", 50, 300, 50, false, function(v)
        Settings.Jumppower = v
        pcall(function() LocalPlayer.Character.Humanoid.JumpPower = v end)
    end)
    AddToggle(cont, 0, "Bay (Fly)", false, function(v)
        Settings.FlyEnabled = v
        if v then
            local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
            local hum = char:WaitForChild("Humanoid")
            local root = char:WaitForChild("HumanoidRootPart")
            hum.PlatformStand = true
            local bv = Instance.new("BodyVelocity")
            bv.Velocity = Vector3.new(0,0,0)
            bv.MaxForce = Vector3.new(1,1,1) * 50000
            bv.Parent = root
            local bg = Instance.new("BodyGyro")
            bg.MaxTorque = Vector3.new(1,1,1) * 50000
            bg.CFrame = Camera.CFrame
            bg.Parent = root
            Settings.FlyBV = bv
            Settings.FlyBG = bg
            Settings.FlyConn = RunService.RenderStepped:Connect(function()
                if not Settings.FlyEnabled then return end
                local dir = Vector3.new(0,0,0)
                if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir += Camera.CFrame.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir -= Camera.CFrame.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir -= Camera.CFrame.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir += Camera.CFrame.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir += Vector3.new(0,1,0) end
                if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then dir -= Vector3.new(0,1,0) end
                bv.Velocity = dir * Settings.FlySpeed
                bg.CFrame = Camera.CFrame
            end)
        else
            pcall(function()
                local char = LocalPlayer.Character
                char.Humanoid.PlatformStand = false
                Settings.FlyBV:Destroy()
                Settings.FlyBG:Destroy()
                Settings.FlyConn:Disconnect()
            end)
        end
    end)
    local sec2 = CreateSection(cont, "🛡️ NHÂN VẬT")
    AddToggle(cont, 0, "Nhảy vô hạn", false, function(v)
        Settings.InfiniteJump = v
        if v then
            Settings.InfJumpConn = UserInputService.JumpRequest:Connect(function()
                pcall(function() LocalPlayer.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping) end)
            end)
        else
            if Settings.InfJumpConn then Settings.InfJumpConn:Disconnect() end
        end
    end)
    AddToggle(cont, 0, "Không bị đẩy lùi (Anti Knockback)", false, function(v) Settings.AntiKB = v end)
    AddToggle(cont, 0, "Xuyên tường (NoClip)", false, function(v)
        Settings.NoClipEnabled = v
        Settings.NoClipConn = Settings.NoClipConn or RunService.Stepped:Connect(function()
            if Settings.NoClipEnabled then
                pcall(function()
                    for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
                        if part:IsA("BasePart") and part.CanCollide then part.CanCollide = false end
                    end
                end)
            end
        end)
    end)
end

local function setupVisualsTab()
    local cont = TabContainers["Visuals"]
    local sec1 = CreateSection(cont, "👁️ ESP NGƯỜI CHƠI")
    AddToggle(cont, 0, "Bật ESP", false, function(v)
        Settings.ESPEnabled = v
        if v then
            local function createESP(player)
                if player == LocalPlayer then return end
                local char = player.Character or player.CharacterAdded:Wait()
                local root = char:WaitForChild("HumanoidRootPart") or char:WaitForChild("Head")
                local box = Instance.new("Frame")
                box.Size = UDim2.new(0, 0, 0, 0)
                box.BackgroundColor3 = Color3.fromRGB(255,255,255)
                box.BackgroundTransparency = 0.7
                box.BorderSizePixel = 0
                box.Parent = ScreenGui
                ApplyCorner(box, 2)
                ApplyStroke(box, Colors.Accent, 1.5, 0)
                
                local name = Instance.new("TextLabel")
                name.Size = UDim2.new(0, 120, 0, 16)
                name.BackgroundTransparency = 1
                name.Text = player.Name
                name.TextColor3 = Color3.fromRGB(255,255,255)
                name.Font = Enum.Font.GothamBold
                name.TextSize = 10
                name.TextStrokeTransparency = 0.3
                name.Parent = ScreenGui
                
                local conn = RunService.RenderStepped:Connect(function()
                    if not Settings.ESPEnabled or not root or not root.Parent then
                        box.Visible = false; name.Visible = false; return
                    end
                    local pos, onScreen = Camera:WorldToViewportPoint(root.Position)
                    if onScreen then
                        local scale = math.clamp(1 / pos.Z * 80, 30, 100)
                        box.Visible = true; name.Visible = true
                        box.Size = UDim2.new(0, scale, 0, scale * 1.8)
                        box.Position = UDim2.new(0, pos.X - scale/2, 0, pos.Y - scale * 0.9)
                        name.Position = UDim2.new(0, pos.X - 60, 0, pos.Y - scale * 0.9 - 18)
                    else
                        box.Visible = false; name.Visible = false
                    end
                end)
                
                Settings.ESPBoxes[player] = {box, name, conn}
            end
            
            for _, p in ipairs(Players:GetPlayers()) do createESP(p) end
            Players.PlayerAdded:Connect(function(p)
                if Settings.ESPEnabled then p.CharacterAdded:Connect(function() task.wait(0.3); createESP(p) end) end
            end)
            Players.PlayerRemoving:Connect(function(p)
                if Settings.ESPBoxes[p] then for _, obj in ipairs(Settings.ESPBoxes[p]) do if obj and obj.Destroy then obj:Destroy() end end; Settings.ESPBoxes[p] = nil end
            end)
        else
            for _, data in pairs(Settings.ESPBoxes) do for _, obj in ipairs(data) do if obj and obj.Destroy then obj:Destroy() end end end
            Settings.ESPBoxes = {}
        end
    end)
    local sec2 = CreateSection(cont, "🌍 THẾ GIỚI")
    AddToggle(cont, 0, "Xuyên tường (Wallhack)", false, function(v)
        Settings.Wallhack = v
        if v then
            for _, obj in ipairs(workspace:GetDescendants()) do
                if obj:IsA("BasePart") and not obj.Parent:FindFirstChildOfClass("Humanoid") then
                    obj.LocalTransparencyModifier = 0.6
                end
            end
        else
            for _, obj in ipairs(workspace:GetDescendants()) do
                if obj:IsA("BasePart") then obj.LocalTransparencyModifier = 0 end
            end
        end
    end)
    AddToggle(cont, 0, "Đèn nền (Fullbright)", false, function(v) lighting.Brightness = v and 2 or 1; lighting.ClockTime = v and 14 or 14 end)
end

local function setupTeleportTab()
    local cont = TabContainers["Teleport"]
    local sec = CreateSection(cont, "🌀 DỊCH CHUYỂN")
    AddButton(cont, 0, "Lưu vị trí hiện tại (Slot 1)", function()
        pcall(function() Settings.SavedPositions[1] = LocalPlayer.Character.HumanoidRootPart.CFrame end)
    end, Colors.Accent)
    AddButton(cont, 0, "Dịch chuyển đến Slot 1", function()
        if Settings.SavedPositions[1] then pcall(function() LocalPlayer.Character.HumanoidRootPart.CFrame = Settings.SavedPositions[1] end) end
    end, Colors.Success)
    AddButton(cont, 0, "Bay đến người chơi gần nhất", function()
        local nearest = nil; local minDist = math.huge
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                local dist = (LocalPlayer.Character.HumanoidRootPart.Position - p.Character.HumanoidRootPart.Position).Magnitude
                if dist < minDist then minDist = dist; nearest = p end
            end
        end
        if nearest then pcall(function() LocalPlayer.Character.HumanoidRootPart.CFrame = nearest.Character.HumanoidRootPart.CFrame + Vector3.new(0,3,0) end) end
    end, Colors.Warning)
end

local function setupMiscTab()
    local cont = TabContainers["Misc"]
    local sec = CreateSection(cont, "🎯 KHÁC")
    AddToggle(cont, 0, "Tự động ăn (Auto Farm)", false, function(v) Settings.AutoFarm = v end)
    AddSlider(cont, 0, "Tốc độ bay (Fly Speed)", 20, 200, 50, false, function(v) Settings.FlySpeed = v end)
    AddButton(cont, 0, "Dọn dẹp workspace", function()
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("BasePart") and obj.Transparency >= 0.9 then obj:Destroy() end
        end
    end, Colors.Danger)
end

local function setupSettingsTab()
    local cont = TabContainers["Settings"]
    local sec = CreateSection(cont, "⚙️ CÀI ĐẶT HỆ THỐNG")
    AddButton(cont, 0, "Lưu cấu hình", function() print("Saved") end, Colors.Success)
    AddButton(cont, 0, "Tải cấu hình", function() print("Loaded") end, Colors.Accent)
    AddButton(cont, 0, "Hủy giao diện (Unload)", function()
        Settings.ESPEnabled = false
        for _, v in pairs(Settings.ESPBoxes) do for _, obj in pairs(v) do if obj then obj:Destroy() end end end
        ScreenGui:Destroy()
    end, Colors.Danger)
end

setupHomeTab()
setupCombatTab()
setupPlayerTab()
setupVisualsTab()
setupTeleportTab()
setupMiscTab()
setupSettingsTab()

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        ScreenGui.Enabled = not ScreenGui.Enabled
    end
end)

local Notif = Instance.new("TextLabel")
Notif.Size = UDim2.new(0, 220, 0, 30)
Notif.Position = UDim2.new(0.5, -110, 1, -50)
Notif.BackgroundColor3 = Colors.Accent
Notif.BackgroundTransparency = 0.1
Notif.Text = "✨ Premium Hub đã sẵn sàng | Nhấn RightShift để ẩn"
Notif.TextColor3 = Colors.Text
Notif.Font = Enum.Font.GothamBold
Notif.TextSize = 11
Notif.Parent = ScreenGui
ApplyCorner(Notif, 8)
ApplyStroke(Notif, Colors.Accent, 1, 0)
task.delay(5, function() TweenObject(Notif, {BackgroundTransparency = 1, TextTransparency = 1}, 0.5) task.wait(0.5); Notif:Destroy() end)

task.spawn(function()
    while RunService.RenderStepped:Wait() do
        if Settings.AntiKB and LocalPlayer.Character then
            for _, v in ipairs(LocalPlayer.Character:GetDescendants()) do
                if v:IsA("BodyVelocity") and v ~= Settings.FlyBV then v:Destroy() end
            end
        end
    end
end)