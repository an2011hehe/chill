local FloatBtn
local ScreenGui
local unloaded = false

local pcall = pcall
local function safeCall()
    pcall(function()
        local guiParent = gethui and gethui() or game:GetService("CoreGui")
        local oldGui = guiParent:FindFirstChild("AndepzaiHub")
        if oldGui then oldGui:Destroy() end
    end)
end
safeCall()

local getasset = getcustomasset or getsynasset

ScreenGui = Instance.new("ScreenGui")
local guiParent = gethui and gethui() or game:GetService("CoreGui")
ScreenGui.Parent = guiParent
ScreenGui.Name = "AndepzaiHub"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.IgnoreGuiInset = true

local isMobile = game:GetService("UserInputService").TouchEnabled
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local ContentProvider = game:GetService("ContentProvider")

local MainSize = isMobile and UDim2.fromOffset(420, 560) or UDim2.fromOffset(720, 500)
local sidebarWidth = isMobile and 160 or 170

local imageUrl = "https://i.postimg.cc/pr06jTmc/Messenger-creation-6997B64B-4FA2-4673-86DC-672451D8A8A4.jpg"
local fileName = "premium_bg.jpg"
local assetPath = ""
local placeholderAsset = "rbxassetid://6014261993"
local shadowAsset = "rbxassetid://1316045217"
local noiseAsset = "rbxassetid://4155801252"
local maxDownloadAttempts = 3
local downloadThread = nil

local function getRequest()
    return (syn and syn.request) or http_request or request or (fluxus and fluxus.request) or (http and http.request)
end

local function downloadImage()
    if unloaded or not isfile or not writefile then return false end
    if isfile(fileName) then return true end
    local req = getRequest()
    if not req or unloaded then return false end
    for attempt = 1, maxDownloadAttempts do
        if unloaded then return false end
        local success, res = pcall(function()
            return req({
                Url = imageUrl,
                Method = "GET"
            })
        end)
        if unloaded then return false end
        if success and res and res.Success and writefile then
            writefile(fileName, res.Body)
            return true
        end
        if attempt < maxDownloadAttempts then
            task.wait(1)
        end
    end
    return false
end

if writefile and isfile and getasset then
    if not isfile(fileName) then
        downloadThread = task.spawn(function()
            if downloadImage() then
                if unloaded then return end
                assetPath = getasset(fileName)
                while not BG and not unloaded do
                    task.wait()
                end
                if unloaded then return end
                if BG and BG.Parent then
                    BG.Image = assetPath
                    pcall(function()
                        ContentProvider:PreloadAsync({BG})
                    end)
                end
            end
        end)
    else
        assetPath = getasset(fileName)
    end
end

local Connections = {}
local Tweens = {}

local function AddConnection(conn)
    if conn and not unloaded then
        table.insert(Connections, conn)
    end
    return conn
end

local function AddTween(tween, callback)
    if not tween or unloaded then return tween end
    Tweens[tween] = true
    if callback then
        local conn
        conn = tween.Completed:Connect(function(state)
            if unloaded then
                if conn then
                    conn:Disconnect()
                    conn = nil
                end
                return
            end
            if state == Enum.PlaybackState.Completed then
                Tweens[tween] = nil
                if callback then callback() end
            end
            if conn then
                conn:Disconnect()
                conn = nil
            end
        end)
        table.insert(Connections, conn)
    else
        local conn
        conn = tween.Completed:Connect(function(state)
            if state == Enum.PlaybackState.Completed then
                Tweens[tween] = nil
            end
            if conn then
                conn:Disconnect()
                conn = nil
            end
        end)
        table.insert(Connections, conn)
    end
    return tween
end

local function CleanupTweens()
    for tween, _ in pairs(Tweens) do
        pcall(function() tween:Cancel() end)
    end
    Tweens = {}
end

local function CleanupConnections()
    for _, conn in ipairs(Connections) do
        pcall(function() conn:Disconnect() end)
    end
    Connections = {}
end

local function CleanupAll()
    CleanupTweens()
    CleanupConnections()
end

local MainShadow = Instance.new("ImageLabel")
MainShadow.Name = "MainShadow"
MainShadow.Size = MainSize + UDim2.fromOffset(30, 30)
MainShadow.Position = UDim2.fromScale(0.5, 0.5)
MainShadow.AnchorPoint = Vector2.new(0.5, 0.5)
MainShadow.BackgroundTransparency = 1
MainShadow.Image = shadowAsset
MainShadow.ImageTransparency = 0.5
MainShadow.ScaleType = Enum.ScaleType.Slice
MainShadow.SliceCenter = Rect.new(99, 99, 99, 99)
MainShadow.ZIndex = 0
MainShadow.Visible = false
MainShadow.Parent = ScreenGui
Instance.new("UICorner", MainShadow).CornerRadius = UDim.new(0, 20)

local Main = Instance.new("Frame")
Main.Size = MainSize
Main.Position = UDim2.fromScale(.5,.5)
Main.AnchorPoint = Vector2.new(.5,.5)
Main.BackgroundColor3 = Color3.fromRGB(18,16,24)
Main.BackgroundTransparency = 0.15
Main.Visible = false
Main.ClipsDescendants = true
Main.Parent = ScreenGui
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 20)

local MainGradient = Instance.new("UIGradient")
MainGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(139, 92, 246)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(100, 80, 220)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(139, 92, 246))
})
MainGradient.Rotation = 45
MainGradient.Parent = Main

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(139, 92, 246)
MainStroke.Thickness = 1.5
MainStroke.Transparency = 0.6
MainStroke.Parent = Main

local BG = Instance.new("ImageLabel")
BG.Size = UDim2.fromScale(1,1)
BG.BackgroundTransparency = 1
BG.ScaleType = Enum.ScaleType.Crop
BG.ImageTransparency = 0.28
BG.Image = assetPath ~= "" and assetPath or placeholderAsset
BG.Parent = Main
Instance.new("UICorner", BG).CornerRadius = UDim.new(0, 20)

local BGNoise = Instance.new("ImageLabel")
BGNoise.Size = UDim2.fromScale(1,1)
BGNoise.BackgroundTransparency = 1
BGNoise.ScaleType = Enum.ScaleType.Tile
BGNoise.Image = noiseAsset
BGNoise.ImageTransparency = 0.85
BGNoise.TileSize = UDim2.fromOffset(96, 96)
BGNoise.ZIndex = 1
BGNoise.Parent = Main
Instance.new("UICorner", BGNoise).CornerRadius = UDim.new(0, 20)

task.spawn(function()
    if unloaded then return end
    pcall(function()
        ContentProvider:PreloadAsync({BG, BGNoise})
    end)
end)

local Overlay = Instance.new("Frame")
Overlay.Size = UDim2.fromScale(1,1)
Overlay.BackgroundColor3 = Color3.fromRGB(0,0,0)
Overlay.BackgroundTransparency = 0.4
Overlay.ZIndex = 0
Overlay.Parent = Main

local Sidebar = Instance.new("Frame")
Sidebar.Size = UDim2.new(0, sidebarWidth, 1, 0)
Sidebar.BackgroundColor3 = Color3.fromRGB(12, 10, 18)
Sidebar.BackgroundTransparency = 0.3
Sidebar.BorderSizePixel = 0
Sidebar.ZIndex = 2
Sidebar.Parent = Main
Instance.new("UICorner", Sidebar).CornerRadius = UDim.new(0, 20)

local SidebarGradient = Instance.new("UIGradient")
SidebarGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(139, 92, 246)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 60, 180))
})
SidebarGradient.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 0.7),
    NumberSequenceKeypoint.new(1, 0.9)
})
SidebarGradient.Rotation = 180
SidebarGradient.Parent = Sidebar

local SidebarStroke = Instance.new("UIStroke")
SidebarStroke.Color = Color3.fromRGB(139, 92, 246)
SidebarStroke.Thickness = 1
SidebarStroke.Transparency = 0.7
SidebarStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
SidebarStroke.Parent = Sidebar

local ContentArea = Instance.new("Frame")
ContentArea.Size = UDim2.new(1, -sidebarWidth, 1, 0)
ContentArea.Position = UDim2.new(0, sidebarWidth, 0, 0)
ContentArea.BackgroundTransparency = 1
ContentArea.ClipsDescendants = true
ContentArea.ZIndex = 2
ContentArea.Parent = Main

local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, -sidebarWidth, 0, isMobile and 40 or 44)
TitleBar.Position = UDim2.new(0, sidebarWidth, 0, 0)
TitleBar.BackgroundTransparency = 1
TitleBar.ZIndex = 3
TitleBar.Parent = Main

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(0.5,0,1,0)
TitleLabel.Position = UDim2.new(0,12,0,0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "✦ ANDEPZAI HUB"
TitleLabel.TextColor3 = Color3.fromRGB(240,240,245)
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextSize = isMobile and 14 or 16
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = TitleBar

local TitleGradient = Instance.new("UIGradient")
TitleGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(255,255,255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(200,180,255))
})
TitleGradient.Parent = TitleLabel

local dragToggle = true
local isDragging = false
local dragStart = nil
local startPos = nil

AddConnection(TitleBar.InputBegan:Connect(function(input)
    if unloaded or not dragToggle then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        isDragging = true
        dragStart = input.Position
        startPos = Main.Position
    end
end))

AddConnection(RunService.RenderStepped:Connect(function()
    if unloaded then return end
    if isDragging and dragStart and startPos then
        local mousePos = UserInputService:GetMouseLocation()
        local delta = mousePos - dragStart
        local newX = math.clamp(startPos.X.Offset + delta.X, 0, (Camera.ViewportSize.X or 1920) - Main.AbsoluteSize.X)
        local newY = math.clamp(startPos.Y.Offset + delta.Y, 0, (Camera.ViewportSize.Y or 1080) - Main.AbsoluteSize.Y)
        Main.Position = UDim2.new(startPos.X.Scale, newX, startPos.Y.Scale, newY)
        if MainShadow and MainShadow.Visible then
            MainShadow.Position = UDim2.new(startPos.X.Scale, newX, startPos.Y.Scale, newY)
        end
    end
end))

AddConnection(UserInputService.InputEnded:Connect(function(input)
    if unloaded then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        isDragging = false
        dragStart = nil
        startPos = nil
    end
end))

local CameraViewportConnection = nil
local function SetupCameraListener()
    local function onViewportChange()
        if unloaded then return end
        if Main.Visible then
            local newX = math.clamp(Main.Position.X.Offset, 0, (Camera.ViewportSize.X or 1920) - Main.AbsoluteSize.X)
            local newY = math.clamp(Main.Position.Y.Offset, 0, (Camera.ViewportSize.Y or 1080) - Main.AbsoluteSize.Y)
            Main.Position = UDim2.new(Main.Position.X.Scale, newX, Main.Position.Y.Scale, newY)
        end
        if FloatBtn and FloatBtn.Parent then
            local padding = 10
            local maxX = (Camera.ViewportSize.X or 1920) - FloatBtn.AbsoluteSize.X - padding
            local maxY = (Camera.ViewportSize.Y or 1080) - FloatBtn.AbsoluteSize.Y - padding
            local newX = math.clamp(FloatBtn.Position.X.Offset, padding, maxX)
            local newY = math.clamp(FloatBtn.Position.Y.Offset, padding, maxY)
            FloatBtn.Position = UDim2.new(FloatBtn.Position.X.Scale, newX, FloatBtn.Position.Y.Scale, newY)
        end
    end

    local function onCameraChange()
        if unloaded then return end
        if CameraViewportConnection then
            pcall(function() CameraViewportConnection:Disconnect() end)
        end
        repeat task.wait() until workspace.CurrentCamera
        if unloaded then return end
        Camera = workspace.CurrentCamera
        CameraViewportConnection = Camera:GetPropertyChangedSignal("ViewportSize"):Connect(onViewportChange)
        onViewportChange()
    end

    AddConnection(workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(onCameraChange))
    onCameraChange()
end

FloatBtn = Instance.new("TextButton")
FloatBtn.Name = "OpenButton"
FloatBtn.Size = isMobile and UDim2.fromOffset(68, 68) or UDim2.fromOffset(60, 60)
FloatBtn.Position = UDim2.new(0.92, 0, 0.85, 0)
FloatBtn.AnchorPoint = Vector2.new(0.5, 0.5)
FloatBtn.BackgroundColor3 = Color3.fromRGB(139, 92, 246)
FloatBtn.BackgroundTransparency = 0.1
FloatBtn.Text = "✦"
FloatBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
FloatBtn.Font = Enum.Font.GothamBold
FloatBtn.TextSize = isMobile and 32 or 28
FloatBtn.ClipsDescendants = true
FloatBtn.Active = true
FloatBtn.AutoButtonColor = true
FloatBtn.Parent = ScreenGui
Instance.new("UICorner", FloatBtn).CornerRadius = UDim.new(0, 34)

local FloatGradient = Instance.new("UIGradient")
FloatGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(200, 160, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(139, 92, 246))
})
FloatGradient.Rotation = 135
FloatGradient.Parent = FloatBtn

local FloatStroke = Instance.new("UIStroke")
FloatStroke.Color = Color3.fromRGB(200, 160, 255)
FloatStroke.Thickness = 2
FloatStroke.Transparency = 0.4
FloatStroke.Parent = FloatBtn

local FloatShadow = Instance.new("ImageLabel")
FloatShadow.Name = "Shadow"
FloatShadow.Size = UDim2.new(1, 24, 1, 24)
FloatShadow.AnchorPoint = Vector2.new(0.5, 0.5)
FloatShadow.Position = UDim2.new(0.5, 0, 0.5, 0)
FloatShadow.BackgroundTransparency = 1
FloatShadow.Image = shadowAsset
FloatShadow.ImageTransparency = 0.55
FloatShadow.ScaleType = Enum.ScaleType.Slice
FloatShadow.SliceCenter = Rect.new(99, 99, 99, 99)
FloatShadow.ZIndex = -2
FloatShadow.Parent = FloatBtn
Instance.new("UICorner", FloatShadow).CornerRadius = UDim.new(0, 34)

local FloatGlow = Instance.new("Frame")
FloatGlow.Size = UDim2.fromScale(1, 1)
FloatGlow.BackgroundColor3 = Color3.fromRGB(139, 92, 246)
FloatGlow.BackgroundTransparency = 0.5
FloatGlow.ZIndex = -1
FloatGlow.Parent = FloatBtn
Instance.new("UICorner", FloatGlow).CornerRadius = UDim.new(0, 34)

local FloatGlowGradient = Instance.new("UIGradient")
FloatGlowGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(139, 92, 246))
})
FloatGlowGradient.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 0.2),
    NumberSequenceKeypoint.new(1, 0.8)
})
FloatGlowGradient.Parent = FloatGlow

local FloatHoverHighlight = Instance.new("Frame")
FloatHoverHighlight.Size = UDim2.fromScale(1, 1)
FloatHoverHighlight.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
FloatHoverHighlight.BackgroundTransparency = 1
FloatHoverHighlight.ZIndex = 5
FloatHoverHighlight.Parent = FloatBtn
Instance.new("UICorner", FloatHoverHighlight).CornerRadius = UDim.new(0, 34)

local FloatScale = Instance.new("UIScale")
FloatScale.Parent = FloatBtn

SetupCameraListener()

local isFloatDragging = false
local floatDragStart = nil
local floatStartPos = nil
local dragMoved = false
local Busy = false

local function SetBusy(state)
    Busy = state
end

AddConnection(FloatBtn.InputBegan:Connect(function(input)
    if unloaded then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        isFloatDragging = true
        floatDragStart = input.Position
        floatStartPos = FloatBtn.Position
        dragMoved = false
    end
end))

AddConnection(FloatBtn.MouseEnter:Connect(function()
    if unloaded or isFloatDragging then return end
    local hoverTween = TweenService:Create(FloatHoverHighlight, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundTransparency = 0.85 })
    AddTween(hoverTween)
    hoverTween:Play()
end))

AddConnection(FloatBtn.MouseLeave:Connect(function()
    if unloaded then return end
    local hoverTween = TweenService:Create(FloatHoverHighlight, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundTransparency = 1 })
    AddTween(hoverTween)
    hoverTween:Play()
end))

AddConnection(RunService.RenderStepped:Connect(function()
    if unloaded then return end
    if isFloatDragging and floatDragStart and floatStartPos then
        local mousePos = UserInputService:GetMouseLocation()
        local delta = mousePos - floatDragStart
        if delta.Magnitude > 10 then
            dragMoved = true
        end
        local padding = 10
        local maxX = (Camera.ViewportSize.X or 1920) - FloatBtn.AbsoluteSize.X - padding
        local maxY = (Camera.ViewportSize.Y or 1080) - FloatBtn.AbsoluteSize.Y - padding
        FloatBtn.Position = UDim2.new(floatStartPos.X.Scale, math.clamp(floatStartPos.X.Offset + delta.X, padding, maxX), floatStartPos.Y.Scale, math.clamp(floatStartPos.Y.Offset + delta.Y, padding, maxY))
    end
end))

AddConnection(UserInputService.InputEnded:Connect(function(input)
    if unloaded then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        isFloatDragging = false
        floatDragStart = nil
        floatStartPos = nil
        task.delay(0.05, function()
            if unloaded then return end
            dragMoved = false
        end)
    end
end))

local Close = Instance.new("TextButton")
Close.Size = UDim2.fromOffset(isMobile and 36 or 32, isMobile and 36 or 32)
Close.Position = UDim2.new(1,-(isMobile and 40 or 36), 0, isMobile and 6 or 4)
Close.Text = "✕"
Close.BackgroundTransparency = 1
Close.TextColor3 = Color3.fromRGB(255,255,255)
Close.TextSize = isMobile and 20 or 18
Close.Font = Enum.Font.GothamBold
Close.AutoButtonColor = true
Close.ZIndex = 5
Close.Parent = TitleBar

local CloseGlow = Instance.new("Frame")
CloseGlow.Size = UDim2.fromScale(1, 1)
CloseGlow.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
CloseGlow.BackgroundTransparency = 0.8
CloseGlow.ZIndex = 4
CloseGlow.Parent = Close
Instance.new("UICorner", CloseGlow).CornerRadius = UDim.new(0, 16)

local scaleObjCache = {}
local function ClickEffect(btn, callback)
    if unloaded then return end
    local scaleObj = scaleObjCache[btn]
    if not scaleObj then
        scaleObj = btn:FindFirstChildOfClass("UIScale")
        if not scaleObj then
            scaleObj = Instance.new("UIScale")
            scaleObj.Parent = btn
        end
        scaleObjCache[btn] = scaleObj
    end
    local originalScale = scaleObj.Scale
    local t1 = TweenService:Create(scaleObj, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Scale = 0.85 })
    local t2 = TweenService:Create(scaleObj, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Scale = originalScale })
    AddTween(t1, function()
        if unloaded then return end
        t2:Play()
        if callback then callback() end
    end)
    AddTween(t2)
    t1:Play()
end

local function OpenUI()
    if unloaded or Busy or Main.Visible then return end
    SetBusy(true)
    Main.Size = UDim2.new(0, 0, 0, 0)
    Main.Visible = true
    MainShadow.Visible = true
    MainShadow.Size = UDim2.new(0, 0, 0, 0)
    local t1 = TweenService:Create(Main, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Size = MainSize })
    local t2 = TweenService:Create(MainShadow, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Size = MainSize + UDim2.fromOffset(30, 30) })
    AddTween(t1, function()
        if unloaded then return end
        FloatBtn.Visible = false
        SetBusy(false)
    end)
    AddTween(t2)
    t1:Play()
    t2:Play()
end

local function CloseUI()
    if unloaded or Busy or not Main.Visible then return end
    SetBusy(true)
    local t1 = TweenService:Create(Main, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Size = UDim2.new(0, 0, 0, 0) })
    local t2 = TweenService:Create(MainShadow, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Size = UDim2.new(0, 0, 0, 0) })
    AddTween(t1, function()
        if unloaded then return end
        Main.Visible = false
        MainShadow.Visible = false
        FloatBtn.Visible = true
        SetBusy(false)
    end)
    AddTween(t2)
    t1:Play()
    t2:Play()
end

local function OpenPressed()
    if not dragMoved then
        ClickEffect(FloatBtn, OpenUI)
    end
end

AddConnection(FloatBtn.Activated:Connect(OpenPressed))

AddConnection(Close.MouseButton1Click:Connect(function()
    if not unloaded and Main.Visible then
        ClickEffect(Close, CloseUI)
    end
end))

local pulseTween
local function StartPulse()
    if unloaded then return end
    if pulseTween then
        pcall(function() pulseTween:Cancel() end)
    end
    if not FloatScale then return end
    pulseTween = TweenService:Create(FloatScale, TweenInfo.new(0.75, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true, 0), { Scale = 1.12 })
    pulseTween:Play()
end
StartPulse()

local function UnloadUI()
    if unloaded then return end
    unloaded = true
    SetBusy(true)
    if downloadThread then
        task.cancel(downloadThread)
        downloadThread = nil
    end
    if pulseTween then
        pcall(function() pulseTween:Cancel() end)
        pulseTween = nil
    end
    CleanupAll()
    pcall(function()
        if ScreenGui then
            ScreenGui:Destroy()
        end
    end)
    table.clear(scaleObjCache)
    table.clear(Connections)
    table.clear(Tweens)
end

if not isMobile then
    local Keybind = Enum.KeyCode.F1
    AddConnection(UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if unloaded or gameProcessed then return end
        if input.KeyCode == Keybind then
            if Main.Visible then
                CloseUI()
            else
                OpenUI()
            end
        end
    end))
end

local UnloadBtn = Instance.new("TextButton")
UnloadBtn.Size = UDim2.fromOffset(isMobile and 30 or 26, isMobile and 30 or 26)
UnloadBtn.Position = UDim2.new(1, -(isMobile and 72 or 66), 0, isMobile and 6 or 4)
UnloadBtn.Text = "⏻"
UnloadBtn.BackgroundTransparency = 1
UnloadBtn.TextColor3 = Color3.fromRGB(255,200,100)
UnloadBtn.TextSize = isMobile and 16 or 14
UnloadBtn.Font = Enum.Font.GothamBold
UnloadBtn.AutoButtonColor = true
UnloadBtn.ZIndex = 5
UnloadBtn.Parent = TitleBar

AddConnection(UnloadBtn.MouseButton1Click:Connect(function()
    UnloadUI()
end))