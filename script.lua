local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "PremiumHub"
ScreenGui.Parent = CoreGui
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local isMobile = UserInputService.TouchEnabled

local Config = {
    Theme = "Dark",
    UIScale = 1,
    Blur = true,
    Sound = true,
    AnimSpeed = 0.3,
    FPSMode = false,
    ESPEnabled = false,
    ESPColor = Color3.fromRGB(139, 92, 246),
    ESPTeamColor = Color3.fromRGB(34, 197, 94),
    ESPEnemyColor = Color3.fromRGB(239, 68, 68)
}

local Colors = {
    Background = Color3.fromHex("#111111"),
    Card = Color3.fromHex("#181818"),
    Sidebar = Color3.fromHex("#151515"),
    Border = Color3.fromHex("#FFFFFF", 0.05),
    Primary = Color3.fromHex("#8B5CF6"),
    Success = Color3.fromHex("#22C55E"),
    Warning = Color3.fromHex("#FACC15"),
    Danger = Color3.fromHex("#EF4444"),
    Text = Color3.fromHex("#FFFFFF"),
    SubText = Color3.fromHex("#A1A1AA")
}

local ESPObjects = {}
local ESPEnabled = false

local function Tween(obj, props, duration, style)
    duration = duration or Config.AnimSpeed
    style = style or Enum.EasingStyle.Quad
    local tween = TweenService:Create(obj, TweenInfo.new(duration, style, Enum.EasingDirection.Out), props)
    tween:Play()
    return tween
end

local function CreateCorner(obj, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 16)
    corner.Parent = obj
    return corner
end

local function CreateStroke(obj, color, thickness, transparency)
    local stroke = Instance.new("UIStroke")
    stroke.Color = color or Colors.Border
    stroke.Thickness = thickness or 1
    stroke.Transparency = transparency or 0.5
    stroke.Parent = obj
    return stroke
end

local LoadingFrame = Instance.new("Frame")
LoadingFrame.Size = UDim2.new(1, 0, 1, 0)
LoadingFrame.BackgroundColor3 = Colors.Background
LoadingFrame.Parent = ScreenGui
CreateCorner(LoadingFrame, 0)

local LogoText = Instance.new("TextLabel")
LogoText.Size = UDim2.new(1, 0, 0, 60)
LogoText.Position = UDim2.new(0, 0, 0.35, -30)
LogoText.BackgroundTransparency = 1
LogoText.Text = "⚡ PREMIUM HUB"
LogoText.TextColor3 = Colors.Primary
LogoText.Font = Enum.Font.GothamBold
LogoText.TextSize = 36
LogoText.Parent = LoadingFrame

local SubText = Instance.new("TextLabel")
SubText.Size = UDim2.new(1, 0, 0, 30)
SubText.Position = UDim2.new(0, 0, 0.45, 0)
SubText.BackgroundTransparency = 1
SubText.Text = "Loading..."
SubText.TextColor3 = Colors.SubText
SubText.Font = Enum.Font.Gotham
SubText.TextSize = 16
SubText.Parent = LoadingFrame

local ProgressBar = Instance.new("Frame")
ProgressBar.Size = UDim2.new(0, 250, 0, 4)
ProgressBar.Position = UDim2.new(0.5, -125, 0.55, 0)
ProgressBar.BackgroundColor3 = Colors.Card
ProgressBar.Parent = LoadingFrame
CreateCorner(ProgressBar, 4)

local ProgressFill = Instance.new("Frame")
ProgressFill.Size = UDim2.new(0, 0, 1, 0)
ProgressFill.BackgroundColor3 = Colors.Primary
ProgressFill.Parent = ProgressBar
CreateCorner(ProgressFill, 4)

local ProgressText = Instance.new("TextLabel")
ProgressText.Size = UDim2.new(0, 60, 0, 20)
ProgressText.Position = UDim2.new(0.5, -30, 0.58, 0)
ProgressText.BackgroundTransparency = 1
ProgressText.Text = "0%"
ProgressText.TextColor3 = Colors.SubText
ProgressText.Font = Enum.Font.GothamBold
ProgressText.TextSize = 14
ProgressText.Parent = LoadingFrame

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 0, 0, 0)
MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
MainFrame.BackgroundColor3 = Colors.Background
MainFrame.BackgroundTransparency = 1
MainFrame.ClipsDescendants = true
MainFrame.Parent = ScreenGui

local BlurEffect = Instance.new("BlurEffect")
BlurEffect.Size = 0
BlurEffect.Parent = MainFrame

local MainBg = Instance.new("Frame")
MainBg.Size = UDim2.new(1, 0, 1, 0)
MainBg.BackgroundColor3 = Colors.Background
MainBg.BackgroundTransparency = 0.02
MainBg.Parent = MainFrame
CreateCorner(MainBg, 20)

local TopBar = Instance.new("Frame")
TopBar.Size = UDim2.new(1, 0, 0, 60)
TopBar.BackgroundColor3 = Colors.Background
TopBar.BackgroundTransparency = 0.5
TopBar.Parent = MainFrame

local TopLeft = Instance.new("Frame")
TopLeft.Size = UDim2.new(0, 200, 1, 0)
TopLeft.BackgroundTransparency = 1
TopLeft.Parent = TopBar

local Logo = Instance.new("TextLabel")
Logo.Size = UDim2.new(0, 30, 1, 0)
Logo.BackgroundTransparency = 1
Logo.Text = "⚡"
Logo.TextColor3 = Colors.Primary
Logo.Font = Enum.Font.GothamBold
Logo.TextSize = 24
Logo.Parent = TopLeft

local HubName = Instance.new("TextLabel")
HubName.Size = UDim2.new(1, -35, 1, 0)
HubName.Position = UDim2.new(0, 35, 0, 0)
HubName.BackgroundTransparency = 1
HubName.Text = "Premium Hub"
HubName.TextColor3 = Colors.Text
HubName.TextXAlignment = Enum.TextXAlignment.Left
HubName.Font = Enum.Font.GothamBold
HubName.TextSize = 18
HubName.Parent = TopLeft

local TopRight = Instance.new("Frame")
TopRight.Size = UDim2.new(0, 200, 1, 0)
TopRight.Position = UDim2.new(1, -200, 0, 0)
TopRight.BackgroundTransparency = 1
TopRight.Parent = TopBar

local FPSLabel = Instance.new("TextLabel")
FPSLabel.Size = UDim2.new(0, 40, 1, 0)
FPSLabel.BackgroundTransparency = 1
FPSLabel.Text = "60"
FPSLabel.TextColor3 = Colors.Success
FPSLabel.Font = Enum.Font.Gotham
FPSLabel.TextSize = 12
FPSLabel.Parent = TopRight

local PingLabel = Instance.new("TextLabel")
PingLabel.Size = UDim2.new(0, 40, 1, 0)
PingLabel.Position = UDim2.new(0, 45, 0, 0)
PingLabel.BackgroundTransparency = 1
PingLabel.Text = "12ms"
PingLabel.TextColor3 = Colors.Success
PingLabel.Font = Enum.Font.Gotham
PingLabel.TextSize = 12
PingLabel.Parent = TopRight

local MinimizeBtn = Instance.new("TextButton")
MinimizeBtn.Size = UDim2.new(0, 30, 1, 0)
MinimizeBtn.Position = UDim2.new(0, 90, 0, 0)
MinimizeBtn.BackgroundTransparency = 1
MinimizeBtn.Text = "─"
MinimizeBtn.TextColor3 = Colors.Text
MinimizeBtn.Font = Enum.Font.Gotham
MinimizeBtn.TextSize = 20
MinimizeBtn.Parent = TopRight

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 30, 1, 0)
CloseBtn.Position = UDim2.new(0, 125, 0, 0)
CloseBtn.BackgroundTransparency = 1
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Colors.Danger
CloseBtn.Font = Enum.Font.Gotham
CloseBtn.TextSize = 16
CloseBtn.Parent = TopRight

local Sidebar = Instance.new("Frame")
Sidebar.Size = UDim2.new(0, isMobile and 180 or 220, 1, -60)
Sidebar.Position = UDim2.new(0, 0, 0, 60)
Sidebar.BackgroundColor3 = Colors.Sidebar
Sidebar.BackgroundTransparency = 0.8
Sidebar.Parent = MainFrame
CreateCorner(Sidebar, 0)

local SidebarScroll = Instance.new("ScrollingFrame")
SidebarScroll.Size = UDim2.new(1, 0, 1, 0)
SidebarScroll.BackgroundTransparency = 1
SidebarScroll.BorderSizePixel = 0
SidebarScroll.ScrollBarThickness = 0
SidebarScroll.CanvasSize = UDim2.new(0, 0, 0, 400)
SidebarScroll.Parent = Sidebar

local Tabs = {
    {name = "Home", icon = "🏠"},
    {name = "Main", icon = "⚡"},
    {name = "Player", icon = "👤"},
    {name = "Visual", icon = "👁️"},
    {name = "Teleport", icon = "🌀"},
    {name = "Farming", icon = "🌾"},
    {name = "Misc", icon = "🎯"},
    {name = "Settings", icon = "⚙️"}
}

local TabButtons = {}
local SelectedTab = "Home"

local function CreateTabButton(tab, y)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -20, 0, isMobile and 44 or 48)
    btn.Position = UDim2.new(0, 10, 0, y)
    btn.BackgroundColor3 = Colors.Card
    btn.BackgroundTransparency = 0.8
    btn.Text = ""
    btn.Parent = SidebarScroll
    CreateCorner(btn, 10)
    
    local icon = Instance.new("TextLabel")
    icon.Size = UDim2.new(0, 30, 1, 0)
    icon.BackgroundTransparency = 1
    icon.Text = tab.icon
    icon.TextColor3 = Colors.SubText
    icon.Font = Enum.Font.Gotham
    icon.TextSize = 18
    icon.Parent = btn
    
    local name = Instance.new("TextLabel")
    name.Size = UDim2.new(1, -35, 1, 0)
    name.Position = UDim2.new(0, 35, 0, 0)
    name.BackgroundTransparency = 1
    name.Text = tab.name
    name.TextColor3 = Colors.SubText
    name.TextXAlignment = Enum.TextXAlignment.Left
    name.Font = Enum.Font.Gotham
    name.TextSize = isMobile and 13 or 14
    name.Parent = btn
    
    local indicator = Instance.new("Frame")
    indicator.Size = UDim2.new(0, 3, 0, 20)
    indicator.Position = UDim2.new(0, 0, 0.5, -10)
    indicator.BackgroundColor3 = Colors.Primary
    indicator.BackgroundTransparency = 1
    indicator.Parent = btn
    CreateCorner(indicator, 2)
    
    btn.MouseButton1Click:Connect(function()
        SelectTab(tab.name)
    end)
    
    if isMobile then
        btn.TouchTap:Connect(function()
            SelectTab(tab.name)
        end)
    end
    
    TabButtons[tab.name] = {btn = btn, icon = icon, name = name, indicator = indicator}
    return btn
end

local yPos = 10
for _, tab in pairs(Tabs) do
    CreateTabButton(tab, yPos)
    yPos = yPos + (isMobile and 50 or 54)
end

local ContentArea = Instance.new("Frame")
ContentArea.Size = UDim2.new(1, -(isMobile and 180 or 220), 1, -60)
ContentArea.Position = UDim2.new(0, isMobile and 180 or 220, 0, 60)
ContentArea.BackgroundTransparency = 1
ContentArea.Parent = MainFrame

local ContentScroll = Instance.new("ScrollingFrame")
ContentScroll.Size = UDim2.new(1, -20, 1, -20)
ContentScroll.Position = UDim2.new(0, 10, 0, 10)
ContentScroll.BackgroundTransparency = 1
ContentScroll.BorderSizePixel = 0
ContentScroll.ScrollBarThickness = 4
ContentScroll.ScrollBarImageColor3 = Colors.Primary
ContentScroll.CanvasSize = UDim2.new(0, 0, 0, 800)
ContentScroll.Parent = ContentArea

local TabContent = {}

for _, tab in pairs(Tabs) do
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, 0, 0, 0)
    container.BackgroundTransparency = 1
    container.Visible = false
    container.Parent = ContentScroll
    TabContent[tab.name] = container
end

local function CreateCard(parent, y, title)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, -10, 0, 0)
    card.Position = UDim2.new(0, 5, 0, y)
    card.BackgroundColor3 = Colors.Card
    card.BackgroundTransparency = 0.3
    card.Parent = parent
    CreateCorner(card, 16)
    CreateStroke(card)
    
    local header = Instance.new("TextLabel")
    header.Size = UDim2.new(1, -20, 0, 40)
    header.Position = UDim2.new(0, 10, 0, 5)
    header.BackgroundTransparency = 1
    header.Text = title
    header.TextColor3 = Colors.Text
    header.TextXAlignment = Enum.TextXAlignment.Left
    header.Font = Enum.Font.GothamBold
    header.TextSize = 16
    header.Parent = card
    
    return card, header
end

local function CreateToggle(parent, y, label, default, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -20, 0, 40)
    frame.Position = UDim2.new(0, 10, 0, y)
    frame.BackgroundTransparency = 1
    frame.Parent = parent
    
    local labelText = Instance.new("TextLabel")
    labelText.Size = UDim2.new(1, -70, 1, 0)
    labelText.BackgroundTransparency = 1
    labelText.Text = label
    labelText.TextColor3 = Colors.Text
    labelText.TextXAlignment = Enum.TextXAlignment.Left
    labelText.Font = Enum.Font.Gotham
    labelText.TextSize = 14
    labelText.Parent = frame
    
    local toggleBg = Instance.new("Frame")
    toggleBg.Size = UDim2.new(0, 50, 0, 28)
    toggleBg.Position = UDim2.new(1, -55, 0.5, -14)
    toggleBg.BackgroundColor3 = Colors.Card
    toggleBg.Parent = frame
    CreateCorner(toggleBg, 14)
    
    local toggleDot = Instance.new("Frame")
    toggleDot.Size = UDim2.new(0, 22, 0, 22)
    toggleDot.Position = UDim2.new(0, 3, 0.5, -11)
    toggleDot.BackgroundColor3 = Colors.SubText
    toggleDot.Parent = toggleBg
    CreateCorner(toggleDot, 11)
    
    local state = default or false
    
    local function UpdateToggle()
        if state then
            toggleBg.BackgroundColor3 = Colors.Primary
            toggleDot.Position = UDim2.new(1, -25, 0.5, -11)
            toggleDot.BackgroundColor3 = Colors.Text
        else
            toggleBg.BackgroundColor3 = Colors.Card
            toggleDot.Position = UDim2.new(0, 3, 0.5, -11)
            toggleDot.BackgroundColor3 = Colors.SubText
        end
    end
    
    UpdateToggle()
    
    local function Toggle()
        state = not state
        UpdateToggle()
        if callback then callback(state) end
    end
    
    toggleBg.MouseButton1Click:Connect(Toggle)
    if isMobile then
        toggleBg.TouchTap:Connect(Toggle)
    end
    
    return toggleBg, function() return state end
end

local function CreateSlider(parent, y, label, min, max, default, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -20, 0, 50)
    frame.Position = UDim2.new(0, 10, 0, y)
    frame.BackgroundTransparency = 1
    frame.Parent = parent
    
    local labelText = Instance.new("TextLabel")
    labelText.Size = UDim2.new(1, -60, 0, 20)
    labelText.BackgroundTransparency = 1
    labelText.Text = label
    labelText.TextColor3 = Colors.Text
    labelText.TextXAlignment = Enum.TextXAlignment.Left
    labelText.Font = Enum.Font.Gotham
    labelText.TextSize = 14
    labelText.Parent = frame
    
    local valueText = Instance.new("TextLabel")
    valueText.Size = UDim2.new(0, 50, 0, 20)
    valueText.Position = UDim2.new(1, -55, 0, 0)
    valueText.BackgroundTransparency = 1
    valueText.Text = tostring(default)
    valueText.TextColor3 = Colors.Primary
    valueText.TextXAlignment = Enum.TextXAlignment.Right
    valueText.Font = Enum.Font.GothamBold
    valueText.TextSize = 14
    valueText.Parent = frame
    
    local sliderBg = Instance.new("Frame")
    sliderBg.Size = UDim2.new(1, 0, 0, 4)
    sliderBg.Position = UDim2.new(0, 0, 1, -4)
    sliderBg.BackgroundColor3 = Colors.Card
    sliderBg.Parent = frame
    CreateCorner(sliderBg, 2)
    
    local sliderFill = Instance.new("Frame")
    sliderFill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    sliderFill.BackgroundColor3 = Colors.Primary
    sliderFill.Parent = sliderBg
    CreateCorner(sliderFill, 2)
    
    local sliderDot = Instance.new("Frame")
    sliderDot.Size = UDim2.new(0, 16, 0, 16)
    sliderDot.Position = UDim2.new((default - min) / (max - min), -8, 0.5, -8)
    sliderDot.BackgroundColor3 = Colors.Primary
    sliderDot.Parent = frame
    CreateCorner(sliderDot, 8)
    
    local value = default or min
    local dragging = false
    
    local function UpdateSlider(val)
        value = math.clamp(val, min, max)
        local percent = (value - min) / (max - min)
        sliderFill.Size = UDim2.new(percent, 0, 1, 0)
        sliderDot.Position = UDim2.new(percent, -8, 0.5, -8)
        valueText.Text = tostring(math.round(value))
        if callback then callback(value) end
    end
    
    sliderBg.MouseButton1Down:Connect(function()
        dragging = true
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local pos = input.Position.X - sliderBg.AbsolutePosition.X
            local percent = math.clamp(pos / sliderBg.AbsoluteSize.X, 0, 1)
            local val = min + (max - min) * percent
            UpdateSlider(val)
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    
    return sliderBg, function() return value end
end

local function CreateButton(parent, y, label, color, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -20, 0, 40)
    btn.Position = UDim2.new(0, 10, 0, y)
    btn.Text = label
    btn.TextColor3 = Colors.Text
    btn.BackgroundColor3 = color or Colors.Primary
    btn.BackgroundTransparency = 0.2
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 14
    btn.Parent = parent
    CreateCorner(btn, 10)
    
    btn.MouseButton1Click:Connect(callback)
    if isMobile then
        btn.TouchTap:Connect(callback)
    end
    
    return btn
end

local function CreateESP(player)
    if not player or player == LocalPlayer then return end
    if ESPObjects[player] then return end
    
    local char = player.Character
    if not char then return end
    
    local root = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso")
    if not root then return end
    
    local esp = {}
    
    local box = Instance.new("Frame")
    box.Size = UDim2.new(0, 0, 0, 0)
    box.BackgroundColor3 = Config.ESPColor
    box.BackgroundTransparency = 0.3
    box.BorderSizePixel = 0
    box.Parent = ScreenGui
    CreateCorner(box, 4)
    CreateStroke(box, Config.ESPColor, 1.5, 0.2)
    
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(0, 120, 0, 20)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = player.Name
    nameLabel.TextColor3 = Colors.Text
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextSize = 12
    nameLabel.TextStrokeTransparency = 0.3
    nameLabel.Parent = ScreenGui
    
    local healthBg = Instance.new("Frame")
    healthBg.Size = UDim2.new(0, 80, 0, 4)
    healthBg.BackgroundColor3 = Colors.Card
    healthBg.BackgroundTransparency = 0.3
    healthBg.Parent = ScreenGui
    CreateCorner(healthBg, 2)
    
    local healthFill = Instance.new("Frame")
    healthFill.Size = UDim2.new(1, 0, 1, 0)
    healthFill.BackgroundColor3 = Colors.Success
    healthFill.Parent = healthBg
    CreateCorner(healthFill, 2)
    
    local distanceLabel = Instance.new("TextLabel")
    distanceLabel.Size = UDim2.new(0, 60, 0, 16)
    distanceLabel.BackgroundTransparency = 1
    distanceLabel.Text = ""
    distanceLabel.TextColor3 = Colors.SubText
    distanceLabel.Font = Enum.Font.Gotham
    distanceLabel.TextSize = 10
    distanceLabel.TextStrokeTransparency = 0.3
    distanceLabel.Parent = ScreenGui
    
    esp.box = box
    esp.name = nameLabel
    esp.healthBg = healthBg
    esp.healthFill = healthFill
    esp.distance = distanceLabel
    esp.root = root
    esp.player = player
    esp.character = char
    
    ESPObjects[player] = esp
end

local function RemoveESP(player)
    local esp = ESPObjects[player]
    if esp then
        if esp.box then esp.box:Destroy() end
        if esp.name then esp.name:Destroy() end
        if esp.healthBg then esp.healthBg:Destroy() end
        if esp.distance then esp.distance:Destroy() end
        ESPObjects[player] = nil
    end
end

local function ClearESP()
    for player, esp in pairs(ESPObjects) do
        if esp.box then esp.box:Destroy() end
        if esp.name then esp.name:Destroy() end
        if esp.healthBg then esp.healthBg:Destroy() end
        if esp.distance then esp.distance:Destroy() end
    end
    ESPObjects = {}
end

local function UpdateESP()
    if not ESPEnabled then
        ClearESP()
        return
    end
    
    local camera = workspace.CurrentCamera
    if not camera then return end
    
    for player, esp in pairs(ESPObjects) do
        if not esp.root or not esp.root.Parent then
            RemoveESP(player)
            continue
        end
        
        local pos, onScreen = camera:WorldToScreenPoint(esp.root.Position)
        if not onScreen then
            esp.box.Visible = false
            esp.name.Visible = false
            esp.healthBg.Visible = false
            esp.distance.Visible = false
            continue
        end
        
        esp.box.Visible = true
        esp.name.Visible = true
        esp.healthBg.Visible = true
        esp.distance.Visible = true
        
        local scale = 1 / pos.Z * 100
        local boxSize = math.clamp(scale * 1.5, 30, 120)
        local boxHeight = math.clamp(scale * 3, 60, 180)
        
        esp.box.Size = UDim2.new(0, boxSize, 0, boxHeight)
        esp.box.Position = UDim2.new(0, pos.X - boxSize / 2, 0, pos.Y - boxHeight / 2)
        
        esp.name.Position = UDim2.new(0, pos.X - 60, 0, pos.Y - boxHeight / 2 - 22)
        esp.name.Text = esp.player.Name
        
        local health = esp.player.Character and esp.player.Character:FindFirstChildOfClass("Humanoid")
        if health then
            local healthPercent = math.clamp(health.Health / health.MaxHealth, 0, 1)
            esp.healthFill.Size = UDim2.new(healthPercent, 0, 1, 0)
            esp.healthFill.BackgroundColor3 = healthPercent > 0.6 and Colors.Success or (healthPercent > 0.3 and Colors.Warning or Colors.Danger)
        end
        
        esp.healthBg.Position = UDim2.new(0, pos.X - 40, 0, pos.Y + boxHeight / 2 + 8)
        
        local dist = (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and (LocalPlayer.Character.HumanoidRootPart.Position - esp.root.Position).Magnitude or 0)
        esp.distance.Text = math.floor(dist) .. "m"
        esp.distance.Position = UDim2.new(0, pos.X - 30, 0, pos.Y + boxHeight / 2 + 20)
        
        local isEnemy = esp.player.Team and LocalPlayer.Team and esp.player.Team ~= LocalPlayer.Team
        local color = isEnemy and Config.ESPEnemyColor or Config.ESPTeamColor
        
        esp.box.BackgroundColor3 = color
        esp.box.BackgroundTransparency = 0.15
        esp.box.BorderColor3 = color
    end
end

local function ToggleESP()
    ESPEnabled = not ESPEnabled
    Config.ESPEnabled = ESPEnabled
    
    if ESPEnabled then
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                CreateESP(player)
            end
        end
        
        Players.PlayerAdded:Connect(function(player)
            if ESPEnabled then
                player.CharacterAdded:Connect(function()
                    if ESPEnabled then
                        task.wait(0.5)
                        CreateESP(player)
                    end
                end)
                task.wait(0.5)
                CreateESP(player)
            end
        end)
        
        Players.PlayerRemoving:Connect(function(player)
            RemoveESP(player)
        end)
    else
        ClearESP()
    end
end

local homeContent = TabContent["Home"]
local homeCard, homeHeader = CreateCard(homeContent, 10, "🏠 Welcome")
homeCard.Size = UDim2.new(1, -10, 0, 200)

local welcome = Instance.new("TextLabel")
welcome.Size = UDim2.new(1, -20, 0, 40)
welcome.Position = UDim2.new(0, 10, 0, 50)
welcome.BackgroundTransparency = 1
welcome.Text = "Welcome to Premium Hub!\nSelect a tab to get started."
welcome.TextColor3 = Colors.SubText
welcome.Font = Enum.Font.Gotham
welcome.TextSize = 14
welcome.Parent = homeCard

local mainContent = TabContent["Main"]
local mainCard, mainHeader = CreateCard(mainContent, 10, "⚡ Main Features")
mainCard.Size = UDim2.new(1, -10, 0, 300)

local speedSlider = CreateSlider(mainCard, 55, "Walk Speed", 10, 100, 50, function(val)
    Settings.Speed = val
end)

local jumpSlider = CreateSlider(mainCard, 110, "Jump Power", 40, 200, 80, function(val)
    Settings.JumpPower = val
end)

local flyToggle = CreateToggle(mainCard, 165, "Fly Mode", false, function(state)
    Settings.FlyMode = state
    if state then
        ToggleFly()
    end
end)

local noclipToggle = CreateToggle(mainCard, 210, "NoClip", false, function(state)
    Settings.NoClipEnabled = state
    if state then
        ToggleNoClip()
    end
end)

local playerContent = TabContent["Player"]
local playerCard, playerHeader = CreateCard(playerContent, 10, "👤 Player Settings")
playerCard.Size = UDim2.new(1, -10, 0, 200)

local infiniteJump = CreateToggle(playerCard, 55, "Infinite Jump", false, function(state)
    Settings.InfiniteJump = state
end)

local autoHeal = CreateToggle(playerCard, 100, "Auto Heal", false, function(state)
    Settings.AutoHeal = state
end)

local visualContent = TabContent["Visual"]
local visualCard, visualHeader = CreateCard(visualContent, 10, "👁️ Visual Settings")
visualCard.Size = UDim2.new(1, -10, 0, 350)

local espToggle = CreateToggle(visualCard, 55, "ESP Player", false, function(state)
    ToggleESP()
    local espBtn = visualCard:FindFirstChild("ESPButton")
    if espBtn then
        espBtn.Text = state and "ESP: ✅" or "ESP: ❌"
    end
end)

local function CreateESPColorPicker(parent, y, label, colorKey, defaultColor)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -20, 0, 40)
    frame.Position = UDim2.new(0, 10, 0, y)
    frame.BackgroundTransparency = 1
    frame.Parent = parent
    
    local labelText = Instance.new("TextLabel")
    labelText.Size = UDim2.new(1, -70, 1, 0)
    labelText.BackgroundTransparency = 1
    labelText.Text = label
    labelText.TextColor3 = Colors.Text
    labelText.TextXAlignment = Enum.TextXAlignment.Left
    labelText.Font = Enum.Font.Gotham
    labelText.TextSize = 14
    labelText.Parent = frame
    
    local colorBtn = Instance.new("TextButton")
    colorBtn.Size = UDim2.new(0, 50, 0, 30)
    colorBtn.Position = UDim2.new(1, -55, 0.5, -15)
    colorBtn.BackgroundColor3 = defaultColor or Colors.Primary
    colorBtn.BackgroundTransparency = 0.2
    colorBtn.Text = ""
    colorBtn.Parent = frame
    CreateCorner(colorBtn, 8)
    CreateStroke(colorBtn, defaultColor or Colors.Primary, 2, 0.3)
    
    local colors = {
        Color3.fromRGB(139, 92, 246),
        Color3.fromRGB(34, 197, 94),
        Color3.fromRGB(239, 68, 68),
        Color3.fromRGB(59, 130, 246),
        Color3.fromRGB(236, 72, 153),
        Color3.fromRGB(251, 191, 36),
        Color3.fromRGB(16, 185, 129),
        Color3.fromRGB(99, 102, 241)
    }
    
    local currentColor = defaultColor or Colors.Primary
    local colorIndex = 1
    
    colorBtn.MouseButton1Click:Connect(function()
        colorIndex = colorIndex % #colors + 1
        currentColor = colors[colorIndex]
        colorBtn.BackgroundColor3 = currentColor
        colorBtn.BorderColor3 = currentColor
        Config[colorKey] = currentColor
    end)
    
    return colorBtn, function() return currentColor end
end

local espTeamColor = CreateESPColorPicker(visualCard, 105, "Team Color", "ESPTeamColor", Colors.Success)
local espEnemyColor = CreateESPColorPicker(visualCard, 155, "Enemy Color", "ESPEnemyColor", Colors.Danger)

local wallToggle = CreateToggle(visualCard, 205, "WallHack", false, function(state)
    Settings.WallHackEnabled = state
end)

local teleportContent = TabContent["Teleport"]
local teleportCard, teleportHeader = CreateCard(teleportContent, 10, "🌀 Teleport")
teleportCard.Size = UDim2.new(1, -10, 0, 250)

local saveBtn = CreateButton(teleportCard, 55, "📌 Save Position", Colors.Primary, function()
    SavePosition(1)
end)

local teleBtn = CreateButton(teleportCard, 100, "🌀 Teleport Back", Colors.Primary, function()
    LoadPosition(1)
end)

local flyTree = CreateButton(teleportCard, 145, "✈️ Fly to Nearest Tree", Colors.Success, function()
    local tree, _ = FindNearestTree()
    if tree then
        local part = tree:FindFirstChild("HumanoidRootPart") or tree:FindFirstChild("Torso") or tree:FindFirstChild("PrimaryPart") or tree:FindFirstChildWhichIsA("BasePart")
        if part then
            FlyToTarget(part.Position)
        end
    end
end)

function SelectTab(tabName)
    SelectedTab = tabName
    
    for name, container in pairs(TabContent) do
        container.Visible = (name == tabName)
    end
    
    for name, data in pairs(TabButtons) do
        local isSelected = (name == tabName)
        data.name.TextColor3 = isSelected and Colors.Text or Colors.SubText
        data.icon.TextColor3 = isSelected and Colors.Primary or Colors.SubText
        data.indicator.BackgroundTransparency = isSelected and 0 or 1
        data.btn.BackgroundTransparency = isSelected and 0.1 or 0.8
    end
end

SelectTab("Home")

local function ShowUI()
    MainFrame.BackgroundTransparency = 0
    MainFrame.Size = UDim2.new(0.92, 0, 0.85, 0)
    MainFrame.Position = UDim2.new(0.04, 0, 0.075, 0)
    
    Tween(MainFrame, {
        Size = UDim2.new(0.92, 0, 0.85, 0),
        Position = UDim2.new(0.04, 0, 0.075, 0)
    }, 0.4)
end

local function HideUI()
    Tween(MainFrame, {
        Size = UDim2.new(0, 0, 0, 0),
        Position = UDim2.new(0.5, 0, 0.5, 0)
    }, 0.3)
end

local function Load()
    local progress = 0
    while progress < 100 do
        progress = progress + math.random(1, 5)
        progress = math.min(progress, 100)
        ProgressFill.Size = UDim2.new(progress / 100, 0, 1, 0)
        ProgressText.Text = tostring(progress) .. "%"
        task.wait(0.05)
    end
    
    task.wait(0.3)
    
    Tween(LoadingFrame, {
        BackgroundTransparency = 1
    }, 0.5)
    
    task.wait(0.3)
    LoadingFrame.Visible = false
    
    ShowUI()
end

Load()

local FloatBtn = Instance.new("TextButton")
FloatBtn.Size = UDim2.new(0, 50, 0, 50)
FloatBtn.Position = UDim2.new(1, -65, 0.5, -25)
FloatBtn.BackgroundColor3 = Colors.Primary
FloatBtn.BackgroundTransparency = 0.2
FloatBtn.Text = "⚡"
FloatBtn.TextColor3 = Colors.Text
FloatBtn.Font = Enum.Font.GothamBold
FloatBtn.TextSize = 24
FloatBtn.Visible = false
FloatBtn.Parent = ScreenGui
CreateCorner(FloatBtn, 25)
CreateStroke(FloatBtn, Colors.Primary, 2)

FloatBtn.MouseButton1Click:Connect(function()
    ShowUI()
    FloatBtn.Visible = false
end)

if isMobile then
    FloatBtn.TouchTap:Connect(function()
        ShowUI()
        FloatBtn.Visible = false
    end)
end

MinimizeBtn.MouseButton1Click:Connect(function()
    HideUI()
    task.wait(0.3)
    FloatBtn.Visible = true
end)

CloseBtn.MouseButton1Click:Connect(function()
    ClearESP()
    ScreenGui:Destroy()
end)

local settingsContent = TabContent["Settings"]
local settingsCard, settingsHeader = CreateCard(settingsContent, 10, "⚙️ Settings")
settingsCard.Size = UDim2.new(1, -10, 0, 500)

local uiScale = CreateSlider(settingsCard, 55, "UI Scale", 0.5, 1.5, 1, function(val)
    MainFrame.UIScale = val
end)

local animSpeed = CreateSlider(settingsCard, 110, "Animation Speed", 0.1, 0.8, 0.3, function(val)
    Config.AnimSpeed = val
end)

local saveConfig = CreateButton(settingsCard, 165, "💾 Save Config", Colors.Success, function()
    print("Config saved")
end)

local loadConfig = CreateButton(settingsCard, 210, "📂 Load Config", Colors.Primary, function()
    print("Config loaded")
end)

local resetConfig = CreateButton(settingsCard, 255, "🔄 Reset Config", Colors.Danger, function()
    print("Config reset")
end)

coroutine.wrap(function()
    while RunService:IsRunning() do
        task.wait(0.1)
        if ESPEnabled then
            UpdateESP()
        end
    end
end)()

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.F1 then
        if MainFrame.Visible then
            HideUI()
            task.wait(0.3)
            FloatBtn.Visible = true
        else
            ShowUI()
            FloatBtn.Visible = false
        end
    end
end)

print("✨ Premium Hub loaded successfully!")