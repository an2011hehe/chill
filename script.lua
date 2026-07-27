local FloatBtn
local ScreenGui
local unloaded = false

local PART_LOADED = {}
local function CheckPart(partName)
    if PART_LOADED[partName] then return true end
    PART_LOADED[partName] = true
    return false
end

if CheckPart("Initialization") then return end

local ExecutorAPI = {
    request = nil,
    getasset = nil,
    writefile = nil,
    isfile = nil,
    gethui = nil,
    task_spawn = nil,
    task_wait = nil,
    task_delay = nil,
    task_cancel = nil,
    pcall = pcall,
    collectgarbage = nil
}

do
    ExecutorAPI.request = (syn and syn.request) or http_request or request or (fluxus and fluxus.request) or (http and http.request)
    ExecutorAPI.getasset = getcustomasset or getsynasset
    ExecutorAPI.writefile = writefile
    ExecutorAPI.isfile = isfile
    ExecutorAPI.gethui = gethui
    ExecutorAPI.task_spawn = task and task.spawn or spawn or function(f) coroutine.wrap(f)() end
    ExecutorAPI.task_wait = task and task.wait or wait or function(t) local s = os.clock() while os.clock() - s < (t or 0.03) do end end
    ExecutorAPI.task_delay = task and task.delay or delay or function(t, f) spawn(function() wait(t) f() end) end
    ExecutorAPI.task_cancel = task and task.cancel or function() end
    ExecutorAPI.collectgarbage = collectgarbage or function() end
end

local function SafeDestroy(obj)
    if obj and obj.Parent then
        pcall(function() obj:Destroy() end)
    end
end

local function SafeCall()
    pcall(function()
        local guiParent = ExecutorAPI.gethui and ExecutorAPI.gethui() or game:GetService("CoreGui")
        local oldGui = guiParent:FindFirstChild("AndepzaiHub")
        if oldGui then SafeDestroy(oldGui) end
    end)
end
SafeCall()

if CheckPart("CoreUtilities") then return end

local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ContentProvider = game:GetService("ContentProvider")
local HttpService = game:GetService("HttpService")

local isMobile = UserInputService.TouchEnabled
local Camera = workspace.CurrentCamera

local ConnectionManager = {}
ConnectionManager.__index = ConnectionManager

function ConnectionManager.new()
    local self = setmetatable({
        _connections = {},
        _signals = {}
    }, ConnectionManager)
    return self
end

function ConnectionManager:Add(conn)
    if conn and not unloaded then
        table.insert(self._connections, conn)
    end
    return conn
end

function ConnectionManager:AddSignal(signalName, conn)
    if conn and not unloaded then
        self._signals[signalName] = conn
    end
    return conn
end

function ConnectionManager:DisconnectSignal(signalName)
    if self._signals[signalName] then
        pcall(function() self._signals[signalName]:Disconnect() end)
        self._signals[signalName] = nil
    end
end

function ConnectionManager:Cleanup()
    for _, conn in ipairs(self._connections) do
        pcall(function() conn:Disconnect() end)
    end
    for signalName, conn in pairs(self._signals) do
        pcall(function() conn:Disconnect() end)
    end
    self._connections = {}
    self._signals = {}
end

local TweenManager = {}
TweenManager.__index = TweenManager

function TweenManager.new(connectionManager)
    local self = setmetatable({
        _tweens = {},
        _connManager = connectionManager
    }, TweenManager)
    return self
end

function TweenManager:Create(instance, tweenInfo, properties)
    if not instance or unloaded then return nil end
    local tween = TweenService:Create(instance, tweenInfo, properties)
    return tween
end

function TweenManager:Play(tween, callback)
    if not tween or unloaded then
        if callback then callback() end
        return nil
    end
    self._tweens[tween] = true
    local conn
    conn = tween.Completed:Connect(function(state)
        if unloaded then
            if conn then conn:Disconnect() end
            return
        end
        if state == Enum.PlaybackState.Completed then
            self._tweens[tween] = nil
            if callback then callback() end
        end
        if conn then
            conn:Disconnect()
            conn = nil
        end
    end)
    if self._connManager then
        self._connManager:Add(conn)
    end
    tween:Play()
    return tween
end

function TweenManager:Cancel(tween)
    if tween then
        pcall(function() tween:Cancel() end)
        self._tweens[tween] = nil
    end
end

function TweenManager:Cleanup()
    for tween, _ in pairs(self._tweens) do
        pcall(function() tween:Cancel() end)
    end
    self._tweens = {}
end

local EasingPresets = {
    openWindow = TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
    closeWindow = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
    hover = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    click = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    pulse = TweenInfo.new(0.75, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true, 0),
    slide = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    fade = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    ripple = TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    notification = TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
}

local MemoryManager = {}
MemoryManager.__index = MemoryManager

function MemoryManager.new()
    local self = setmetatable({
        _objects = {},
        _cache = {}
    }, MemoryManager)
    return self
end

function MemoryManager:Track(obj)
    if obj then
        table.insert(self._objects, obj)
    end
    return obj
end

function MemoryManager:Cache(key, value)
    self._cache[key] = value
    return value
end

function MemoryManager:GetCache(key)
    return self._cache[key]
end

function MemoryManager:ClearCache(key)
    if key then
        self._cache[key] = nil
    else
        self._cache = {}
    end
end

function MemoryManager:Cleanup()
    for _, obj in ipairs(self._objects) do
        SafeDestroy(obj)
    end
    self._objects = {}
    self._cache = {}
end

if CheckPart("ThemeManager") then return end

local ThemeManager = {}
ThemeManager.__index = ThemeManager

local Themes = {
    Default = {
        Name = "Default",
        Primary = Color3.fromRGB(139, 92, 246),
        PrimaryLight = Color3.fromRGB(200, 160, 255),
        PrimaryDark = Color3.fromRGB(100, 80, 220),
        Secondary = Color3.fromRGB(255, 100, 100),
        Background = Color3.fromRGB(18, 16, 24),
        Sidebar = Color3.fromRGB(12, 10, 18),
        Text = Color3.fromRGB(240, 240, 245),
        TextSecondary = Color3.fromRGB(200, 180, 255),
        Accent = Color3.fromRGB(255, 200, 100),
        Success = Color3.fromRGB(100, 255, 100),
        Warning = Color3.fromRGB(255, 200, 50),
        Error = Color3.fromRGB(255, 100, 100),
        GlassTransparency = 0.15,
        OverlayTransparency = 0.4,
        SidebarTransparency = 0.3,
        GlassBlur = true
    },
    Ocean = {
        Name = "Ocean",
        Primary = Color3.fromRGB(64, 128, 255),
        PrimaryLight = Color3.fromRGB(128, 192, 255),
        PrimaryDark = Color3.fromRGB(32, 64, 192),
        Secondary = Color3.fromRGB(255, 128, 64),
        Background = Color3.fromRGB(12, 16, 32),
        Sidebar = Color3.fromRGB(8, 10, 24),
        Text = Color3.fromRGB(240, 245, 255),
        TextSecondary = Color3.fromRGB(180, 200, 255),
        Accent = Color3.fromRGB(255, 220, 100),
        Success = Color3.fromRGB(100, 255, 150),
        Warning = Color3.fromRGB(255, 220, 80),
        Error = Color3.fromRGB(255, 80, 80),
        GlassTransparency = 0.12,
        OverlayTransparency = 0.35,
        SidebarTransparency = 0.25,
        GlassBlur = true
    },
    Midnight = {
        Name = "Midnight",
        Primary = Color3.fromRGB(180, 130, 255),
        PrimaryLight = Color3.fromRGB(220, 200, 255),
        PrimaryDark = Color3.fromRGB(120, 80, 200),
        Secondary = Color3.fromRGB(255, 150, 150),
        Background = Color3.fromRGB(8, 8, 16),
        Sidebar = Color3.fromRGB(4, 4, 12),
        Text = Color3.fromRGB(250, 250, 255),
        TextSecondary = Color3.fromRGB(200, 200, 220),
        Accent = Color3.fromRGB(255, 220, 150),
        Success = Color3.fromRGB(150, 255, 150),
        Warning = Color3.fromRGB(255, 220, 100),
        Error = Color3.fromRGB(255, 120, 120),
        GlassTransparency = 0.1,
        OverlayTransparency = 0.3,
        SidebarTransparency = 0.2,
        GlassBlur = true
    }
}

function ThemeManager.new()
    local self = setmetatable({
        _currentTheme = Themes.Default,
        _themeName = "Default"
    }, ThemeManager)
    return self
end

function ThemeManager:SetTheme(themeName)
    if Themes[themeName] then
        self._currentTheme = Themes[themeName]
        self._themeName = themeName
        return true
    end
    return false
end

function ThemeManager:GetTheme()
    return self._currentTheme
end

function ThemeManager:GetColor(colorName)
    return self._currentTheme[colorName] or self._currentTheme.Primary
end

function ThemeManager:GetAllThemes()
    local themeList = {}
    for name, _ in pairs(Themes) do
        table.insert(themeList, name)
    end
    return themeList
end

if CheckPart("AssetManager") then return end

local AssetManager = {}
AssetManager.__index = AssetManager

function AssetManager.new(connManager, memoryManager)
    local self = setmetatable({
        _connManager = connManager,
        _memoryManager = memoryManager,
        _assetCache = {},
        _downloadQueue = {},
        _isDownloading = false,
        _maxRetries = 3,
        _retryDelay = 1,
        _imageUrl = "https://i.postimg.cc/pr06jTmc/Messenger-creation-6997B64B-4FA2-4673-86DC-672451D8A8A4.jpg",
        _fileName = "premium_bg_v2.jpg",
        _placeholderAsset = "rbxassetid://6014261993",
        _shadowAsset = "rbxassetid://1316045217",
        _noiseAsset = "rbxassetid://4155801252",
        _assetPath = "",
        _downloadThread = nil
    }, AssetManager)
    return self
end

function AssetManager:GetRequest()
    return (syn and syn.request) or http_request or request or (fluxus and fluxus.request) or (http and http.request)
end

function AssetManager:DownloadImage(callback)
    if unloaded or not ExecutorAPI.isfile or not ExecutorAPI.writefile then
        if callback then callback(false) end
        return false
    end
    
    if ExecutorAPI.isfile(self._fileName) then
        self._assetPath = ExecutorAPI.getasset(self._fileName)
        if callback then callback(true, self._assetPath) end
        return true
    end
    
    local req = self:GetRequest()
    if not req then
        if callback then callback(false) end
        return false
    end
    
    self._downloadThread = ExecutorAPI.task_spawn(function()
        for attempt = 1, self._maxRetries do
            if unloaded then
                if callback then callback(false) end
                return
            end
            
            local success, res = pcall(function()
                return req({
                    Url = self._imageUrl,
                    Method = "GET"
                })
            end)
            
            if unloaded then
                if callback then callback(false) end
                return
            end
            
            if success and res and res.Success and ExecutorAPI.writefile then
                ExecutorAPI.writefile(self._fileName, res.Body)
                self._assetPath = ExecutorAPI.getasset(self._fileName)
                if callback then callback(true, self._assetPath) end
                return
            end
            
            if attempt < self._maxRetries then
                ExecutorAPI.task_wait(self._retryDelay)
            end
        end
        
        if callback then callback(false) end
    end)
    
    return false
end

function AssetManager:GetAssetPath()
    return self._assetPath
end

function AssetManager:GetPlaceholderAsset()
    return self._placeholderAsset
end

function AssetManager:GetShadowAsset()
    return self._shadowAsset
end

function AssetManager:GetNoiseAsset()
    return self._noiseAsset
end

function AssetManager:SetImageUrl(url)
    self._imageUrl = url
end

function AssetManager:SetFileName(name)
    self._fileName = name
end

function AssetManager:PreloadAssets(assets, callback)
    if unloaded or not assets then
        if callback then callback(false) end
        return
    end
    
    ExecutorAPI.task_spawn(function()
        local success = pcall(function()
            ContentProvider:PreloadAsync(assets)
        end)
        if callback then callback(success) end
    end)
end

function AssetManager:CancelDownload()
    if self._downloadThread then
        ExecutorAPI.task_cancel(self._downloadThread)
        self._downloadThread = nil
    end
end

function AssetManager:Cleanup()
    self:CancelDownload()
    self._assetCache = {}
    self._downloadQueue = {}
end

if CheckPart("DragHandler") then return end

local DragHandler = {}
DragHandler.__index = DragHandler

function DragHandler.new(connManager, tweenManager)
    local self = setmetatable({
        _connManager = connManager,
        _tweenManager = tweenManager,
        _isDragging = false,
        _dragStart = nil,
        _startPos = nil,
        _dragMoved = false,
        _target = nil,
        _dragThreshold = 10,
        _clampPadding = 10,
        _useRenderStepped = true
    }, DragHandler)
    return self
end

function DragHandler:Bind(target, dragRegion, options)
    if not target or not dragRegion then return end
    
    options = options or {}
    local clampPadding = options.clampPadding or self._clampPadding
    local dragThreshold = options.dragThreshold or self._dragThreshold
    
    self._connManager:Add(dragRegion.InputBegan:Connect(function(input)
        if unloaded then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            self._isDragging = true
            self._dragStart = input.Position
            self._startPos = target.Position
            self._target = target
            self._dragMoved = false
        end
    end))
    
    self._connManager:Add(RunService.RenderStepped:Connect(function()
        if unloaded or not self._isDragging or not self._target then return end
        if self._dragStart and self._startPos then
            local mousePos = UserInputService:GetMouseLocation()
            local delta = mousePos - self._dragStart
            
            if delta.Magnitude > dragThreshold then
                self._dragMoved = true
            end
            
            local viewportSize = Camera.ViewportSize
            local maxX = math.max(0, viewportSize.X - self._target.AbsoluteSize.X - clampPadding)
            local maxY = math.max(0, viewportSize.Y - self._target.AbsoluteSize.Y - clampPadding)
            
            local newX = math.clamp(self._startPos.X.Offset + delta.X, clampPadding, maxX)
            local newY = math.clamp(self._startPos.Y.Offset + delta.Y, clampPadding, maxY)
            
            self._target.Position = UDim2.new(self._startPos.X.Scale, newX, self._startPos.Y.Scale, newY)
        end
    end))
    
    self._connManager:Add(UserInputService.InputEnded:Connect(function(input)
        if unloaded then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            self._isDragging = false
            self._dragStart = nil
            self._startPos = nil
            self._target = nil
            ExecutorAPI.task_delay(0.05, function()
                if not unloaded then
                    self._dragMoved = false
                end
            end)
        end
    end))
end

function DragHandler:WasDragged()
    return self._dragMoved
end

function DragHandler:IsDragging()
    return self._isDragging
end

function DragHandler:Cleanup()
    self._isDragging = false
    self._dragStart = nil
    self._startPos = nil
    self._target = nil
    self._dragMoved = false
end

if CheckPart("RippleSystem") then return end

local RippleSystem = {}
RippleSystem.__index = RippleSystem

function RippleSystem.new(tweenManager)
    local self = setmetatable({
        _tweenManager = tweenManager
    }, RippleSystem)
    return self
end

function RippleSystem:Create(button, callback)
    if not button or unloaded then return end
    
    local ripple = Instance.new("Frame")
    ripple.Size = UDim2.fromScale(0, 0)
    ripple.AnchorPoint = Vector2.new(0.5, 0.5)
    ripple.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    ripple.BackgroundTransparency = 0.7
    ripple.ZIndex = 10
    ripple.ClipsDescendants = true
    ripple.Parent = button
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = ripple
    
    local targetSize = math.max(button.AbsoluteSize.X, button.AbsoluteSize.Y) * 2
    
    local tween = self._tweenManager:Create(ripple, EasingPresets.ripple, {
        Size = UDim2.fromOffset(targetSize, targetSize),
        BackgroundTransparency = 1
    })
    
    self._tweenManager:Play(tween, function()
        SafeDestroy(ripple)
        if callback then callback() end
    end)
end

if CheckPart("NotificationSystem") then return end

local NotificationSystem = {}
NotificationSystem.__index = NotificationSystem

function NotificationSystem.new(tweenManager, themeManager)
    local self = setmetatable({
        _tweenManager = tweenManager,
        _themeManager = themeManager,
        _notifications = {},
        _maxNotifications = 5
    }, NotificationSystem)
    return self
end

function NotificationSystem:Show(title, message, duration, notificationType)
    if unloaded or not ScreenGui then return end
    
    duration = duration or 3
    notificationType = notificationType or "Default"
    
    local theme = self._themeManager:GetTheme()
    local color
    
    if notificationType == "Success" then
        color = theme.Success
    elseif notificationType == "Warning" then
        color = theme.Warning
    elseif notificationType == "Error" then
        color = theme.Error
    else
        color = theme.Primary
    end
    
    local notification = Instance.new("Frame")
    notification.Size = UDim2.fromOffset(280, 0)
    notification.Position = UDim2.new(1, 300, 1, -20)
    notification.AnchorPoint = Vector2.new(1, 1)
    notification.BackgroundColor3 = theme.Background
    notification.BackgroundTransparency = 0.1
    notification.ClipsDescendants = true
    notification.ZIndex = 100
    notification.Parent = ScreenGui
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = color
    stroke.Thickness = 1.5
    stroke.Transparency = 0.5
    stroke.Parent = notification
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = notification
    
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, color),
        ColorSequenceKeypoint.new(1, theme.PrimaryDark)
    })
    gradient.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.9),
        NumberSequenceKeypoint.new(1, 0.95)
    })
    gradient.Rotation = 90
    gradient.Parent = notification
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -16, 0, 20)
    titleLabel.Position = UDim2.new(0, 12, 0, 10)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = title or "Notification"
    titleLabel.TextColor3 = color
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextSize = 14
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.ZIndex = 101
    titleLabel.Parent = notification
    
    local messageLabel = Instance.new("TextLabel")
    messageLabel.Size = UDim2.new(1, -16, 0, 16)
    messageLabel.Position = UDim2.new(0, 12, 0, 30)
    messageLabel.BackgroundTransparency = 1
    messageLabel.Text = message or ""
    messageLabel.TextColor3 = theme.TextSecondary
    messageLabel.Font = Enum.Font.Gotham
    messageLabel.TextSize = 12
    messageLabel.TextXAlignment = Enum.TextXAlignment.Left
    messageLabel.ZIndex = 101
    messageLabel.Parent = notification
    
    local progressBar = Instance.new("Frame")
    progressBar.Size = UDim2.new(1, 0, 0, 3)
    progressBar.Position = UDim2.new(0, 0, 1, -3)
    progressBar.BackgroundColor3 = color
    progressBar.BackgroundTransparency = 0.3
    progressBar.ZIndex = 102
    progressBar.Parent = notification
    
    local corner2 = Instance.new("UICorner")
    corner2.CornerRadius = UDim.new(0, 12)
    corner2.Parent = progressBar
    
    local notificationHeight = 60
    local openTween = self._tweenManager:Create(notification, EasingPresets.notification, {
        Size = UDim2.fromOffset(280, notificationHeight),
        Position = UDim2.new(1, -300, 1, -20 - (#self._notifications * (notificationHeight + 10)))
    })
    
    self._tweenManager:Play(openTween)
    
    local progressTween = self._tweenManager:Create(progressBar, TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 0, 0, 3)
    })
    
    self._tweenManager:Play(progressTween)
    
    table.insert(self._notifications, notification)
    
    ExecutorAPI.task_delay(duration + 0.3, function()
        if unloaded then return end
        local closeTween = self._tweenManager:Create(notification, EasingPresets.fade, {
            Size = UDim2.fromOffset(280, 0),
            BackgroundTransparency = 1
        })
        self._tweenManager:Play(closeTween, function()
            for i, notif in ipairs(self._notifications) do
                if notif == notification then
                    table.remove(self._notifications, i)
                    break
                end
            end
            SafeDestroy(notification)
        end)
    end)
    
    if #self._notifications > self._maxNotifications then
        local oldest = table.remove(self._notifications, 1)
        SafeDestroy(oldest)
    end
end

if CheckPart("TooltipSystem") then return end

local TooltipSystem = {}
TooltipSystem.__index = TooltipSystem

function TooltipSystem.new(connManager, tweenManager, themeManager)
    local self = setmetatable({
        _connManager = connManager,
        _tweenManager = tweenManager,
        _themeManager = themeManager,
        _currentTooltip = nil
    }, TooltipSystem)
    return self
end

function TooltipSystem:Attach(button, text, position)
    if not button or not ScreenGui then return end
    
    position = position or "Top"
    
    self._connManager:Add(button.MouseEnter:Connect(function()
        if unloaded then return end
        self:Show(button, text, position)
    end))
    
    self._connManager:Add(button.MouseLeave:Connect(function()
        self:Hide()
    end))
end

function TooltipSystem:Show(parent, text, position)
    self:Hide()
    
    if not parent or unloaded then return end
    
    local theme = self._themeManager:GetTheme()
    
    local tooltip = Instance.new("Frame")
    tooltip.Size = UDim2.fromOffset(0, 0)
    tooltip.BackgroundColor3 = theme.Background
    tooltip.BackgroundTransparency = 0.1
    tooltip.ZIndex = 200
    tooltip.ClipsDescendants = true
    tooltip.Parent = ScreenGui
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = theme.Primary
    stroke.Thickness = 1
    stroke.Transparency = 0.5
    stroke.Parent = tooltip
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = tooltip
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -16, 1, -8)
    label.Position = UDim2.new(0, 8, 0, 4)
    label.BackgroundTransparency = 1
    label.Text = text or ""
    label.TextColor3 = theme.Text
    label.Font = Enum.Font.Gotham
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Center
    label.ZIndex = 201
    label.Parent = tooltip
    
    local textSize = game:GetService("TextService"):GetTextSize(text, 12, "Gotham", Vector2.new(1000, 1000))
    local tooltipWidth = textSize.X + 24
    local tooltipHeight = textSize.Y + 12
    
    local parentPos = parent.AbsolutePosition
    local parentSize = parent.AbsoluteSize
    
    local tooltipPos
    if position == "Top" then
        tooltipPos = UDim2.fromOffset(
            parentPos.X + parentSize.X/2 - tooltipWidth/2,
            parentPos.Y - tooltipHeight - 8
        )
    elseif position == "Bottom" then
        tooltipPos = UDim2.fromOffset(
            parentPos.X + parentSize.X/2 - tooltipWidth/2,
            parentPos.Y + parentSize.Y + 8
        )
    elseif position == "Left" then
        tooltipPos = UDim2.fromOffset(
            parentPos.X - tooltipWidth - 8,
            parentPos.Y + parentSize.Y/2 - tooltipHeight/2
        )
    else
        tooltipPos = UDim2.fromOffset(
            parentPos.X + parentSize.X + 8,
            parentPos.Y + parentSize.Y/2 - tooltipHeight/2
        )
    end
    
    tooltip.Position = tooltipPos
    
    local openTween = self._tweenManager:Create(tooltip, EasingPresets.fade, {
        Size = UDim2.fromOffset(tooltipWidth, tooltipHeight)
    })
    
    self._tweenManager:Play(openTween)
    self._currentTooltip = tooltip
end

function TooltipSystem:Hide()
    if self._currentTooltip then
        SafeDestroy(self._currentTooltip)
        self._currentTooltip = nil
    end
end

function TooltipSystem:Cleanup()
    self:Hide()
end

if CheckPart("UIFactory") then return end

local UIFactory = {}
UIFactory.__index = UIFactory

function UIFactory.new(connManager, tweenManager, themeManager, rippleSystem, tooltipSystem)
    local self = setmetatable({
        _connManager = connManager,
        _tweenManager = tweenManager,
        _themeManager = themeManager,
        _rippleSystem = rippleSystem,
        _tooltipSystem = tooltipSystem,
        _scaleCache = {}
    }, UIFactory)
    return self
end

function UIFactory:CreateButton(parent, text, size, position, callback)
    local theme = self._themeManager:GetTheme()
    
    local button = Instance.new("TextButton")
    button.Size = size or UDim2.fromOffset(120, 40)
    button.Position = position or UDim2.fromScale(0, 0)
    button.BackgroundColor3 = theme.Primary
    button.BackgroundTransparency = 0.1
    button.Text = text or "Button"
    button.TextColor3 = theme.Text
    button.Font = Enum.Font.GothamBold
    button.TextSize = 14
    button.ClipsDescendants = true
    button.AutoButtonColor = false
    button.Parent = parent
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = theme.PrimaryLight
    stroke.Thickness = 1.5
    stroke.Transparency = 0.5
    stroke.Parent = button
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = button
    
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, theme.PrimaryLight),
        ColorSequenceKeypoint.new(1, theme.PrimaryDark)
    })
    gradient.Rotation = 135
    gradient.Parent = button
    
    local scaleObj = Instance.new("UIScale")
    scaleObj.Parent = button
    
    self._connManager:Add(button.MouseEnter:Connect(function()
        if unloaded then return end
        local hoverTween = self._tweenManager:Create(button, EasingPresets.hover, {
            BackgroundTransparency = 0.05
        })
        self._tweenManager:Play(hoverTween)
    end))
    
    self._connManager:Add(button.MouseLeave:Connect(function()
        if unloaded then return end
        local leaveTween = self._tweenManager:Create(button, EasingPresets.hover, {
            BackgroundTransparency = 0.1
        })
        self._tweenManager:Play(leaveTween)
    end))
    
    if callback then
        self._connManager:Add(button.Activated:Connect(function()
            if unloaded then return end
            self._rippleSystem:Create(button)
            
            local clickTween = self._tweenManager:Create(scaleObj, EasingPresets.click, {
                Scale = 0.9
            })
            local releaseTween = self._tweenManager:Create(scaleObj, EasingPresets.click, {
                Scale = 1
            })
            
            self._tweenManager:Play(clickTween, function()
                if unloaded then return end
                self._tweenManager:Play(releaseTween)
                callback()
            end)
        end))
    end
    
    return button
end

function UIFactory:CreateToggle(parent, text, default, position, callback)
    local theme = self._themeManager:GetTheme()
    local isToggled = default or false
    
    local container = Instance.new("Frame")
    container.Size = UDim2.fromOffset(200, 40)
    container.Position = position or UDim2.fromScale(0, 0)
    container.BackgroundTransparency = 1
    container.Parent = parent
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.6, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = text or "Toggle"
    label.TextColor3 = theme.Text
    label.Font = Enum.Font.Gotham
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = container
    
    local toggleButton = Instance.new("TextButton")
    toggleButton.Size = UDim2.fromOffset(44, 24)
    toggleButton.Position = UDim2.new(1, -44, 0.5, -12)
    toggleButton.BackgroundColor3 = isToggled and theme.Primary or Color3.fromRGB(60, 60, 80)
    toggleButton.Text = ""
    toggleButton.AutoButtonColor = false
    toggleButton.ClipsDescendants = true
    toggleButton.Parent = container
    
    local toggleCorner = Instance.new("UICorner")
    toggleCorner.CornerRadius = UDim.new(1, 0)
    toggleCorner.Parent = toggleButton
    
    local toggleKnob = Instance.new("Frame")
    toggleKnob.Size = UDim2.fromOffset(18, 18)
    toggleKnob.Position = isToggled and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 3, 0.5, -9)
    toggleKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    toggleKnob.Parent = toggleButton
    
    local knobCorner = Instance.new("UICorner")
    knobCorner.CornerRadius = UDim.new(1, 0)
    knobCorner.Parent = toggleKnob
    
    self._connManager:Add(toggleButton.Activated:Connect(function()
        if unloaded then return end
        isToggled = not isToggled
        
        local bgTween = self._tweenManager:Create(toggleButton, EasingPresets.hover, {
            BackgroundColor3 = isToggled and theme.Primary or Color3.fromRGB(60, 60, 80)
        })
        local knobTween = self._tweenManager:Create(toggleKnob, EasingPresets.hover, {
            Position = isToggled and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 3, 0.5, -9)
        })
        
        self._tweenManager:Play(bgTween)
        self._tweenManager:Play(knobTween)
        
        if callback then callback(isToggled) end
    end))
    
    return container
end

function UIFactory:CreateSlider(parent, text, min, max, default, position, callback)
    local theme = self._themeManager:GetTheme()
    min = min or 0
    max = max or 100
    local value = default or 50
    
    local container = Instance.new("Frame")
    container.Size = UDim2.fromOffset(200, 50)
    container.Position = position or UDim2.fromScale(0, 0)
    container.BackgroundTransparency = 1
    container.Parent = parent
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0, 20)
    label.BackgroundTransparency = 1
    label.Text = (text or "Slider") .. ": " .. tostring(value)
    label.TextColor3 = theme.Text
    label.Font = Enum.Font.Gotham
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = container
    
    local sliderBar = Instance.new("Frame")
    sliderBar.Size = UDim2.new(1, 0, 0, 6)
    sliderBar.Position = UDim2.new(0, 0, 0, 30)
    sliderBar.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
    sliderBar.Parent = container
    
    local sliderCorner = Instance.new("UICorner")
    sliderCorner.CornerRadius = UDim.new(1, 0)
    sliderCorner.Parent = sliderBar
    
    local sliderFill = Instance.new("Frame")
    sliderFill.Size = UDim2.fromScale((value - min) / (max - min), 1)
    sliderFill.BackgroundColor3 = theme.Primary
    sliderFill.Parent = sliderBar
    
    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(1, 0)
    fillCorner.Parent = sliderFill
    
    local sliderKnob = Instance.new("TextButton")
    sliderKnob.Size = UDim2.fromOffset(16, 16)
    sliderKnob.Position = UDim2.new((value - min) / (max - min), -8, 0.5, -8)
    sliderKnob.BackgroundColor3 = theme.PrimaryLight
    sliderKnob.Text = ""
    sliderKnob.AutoButtonColor = false
    sliderKnob.Parent = sliderBar
    
    local knobStroke = Instance.new("UIStroke")
    knobStroke.Color = Color3.fromRGB(255, 255, 255)
    knobStroke.Thickness = 2
    knobStroke.Parent = sliderKnob
    
    local knobCorner = Instance.new("UICorner")
    knobCorner.CornerRadius = UDim.new(1, 0)
    knobCorner.Parent = sliderKnob
    
    local isSliding = false
    
    self._connManager:Add(sliderKnob.InputBegan:Connect(function(input)
        if unloaded then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isSliding = true
        end
    end))
    
    self._connManager:Add(UserInputService.InputEnded:Connect(function(input)
        if unloaded then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isSliding = false
        end
    end))
    
    self._connManager:Add(RunService.RenderStepped:Connect(function()
        if unloaded or not isSliding then return end
        local mousePos = UserInputService:GetMouseLocation()
        local barPos = sliderBar.AbsolutePosition
        local barSize = sliderBar.AbsoluteSize
        local relativeX = math.clamp((mousePos.X - barPos.X) / barSize.X, 0, 1)
        
        value = math.floor(min + (max - min) * relativeX)
        sliderFill.Size = UDim2.fromScale(relativeX, 1)
        sliderKnob.Position = UDim2.new(relativeX, -8, 0.5, -8)
        label.Text = (text or "Slider") .. ": " .. tostring(value)
        
        if callback then callback(value) end
    end))
    
    return container
end

if CheckPart("MainUIConstruction") then return end

local connManager = ConnectionManager.new()
local tweenManager = TweenManager.new(connManager)
local memoryManager = MemoryManager.new()
local themeManager = ThemeManager.new()
local assetManager = AssetManager.new(connManager, memoryManager)
local dragHandler = DragHandler.new(connManager, tweenManager)
local rippleSystem = RippleSystem.new(tweenManager)
local notificationSystem = NotificationSystem.new(tweenManager, themeManager)
local tooltipSystem = TooltipSystem.new(connManager, tweenManager, themeManager)
local uiFactory = UIFactory.new(connManager, tweenManager, themeManager, rippleSystem, tooltipSystem)

ScreenGui = Instance.new("ScreenGui")
local guiParent = ExecutorAPI.gethui and ExecutorAPI.gethui() or game:GetService("CoreGui")
ScreenGui.Parent = guiParent
ScreenGui.Name = "AndepzaiHub"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.IgnoreGuiInset = true
memoryManager:Track(ScreenGui)

local MainSize = isMobile and UDim2.fromOffset(440, 500) or UDim2.fromOffset(820, 480)
local sidebarWidth = isMobile and 160 or 180

local theme = themeManager:GetTheme()

assetManager:PreloadAssets({}, nil)

local MainShadow = Instance.new("ImageLabel")
MainShadow.Name = "MainShadow"
MainShadow.Size = MainSize + UDim2.fromOffset(40, 40)
MainShadow.Position = UDim2.fromScale(0.5, 0.5)
MainShadow.AnchorPoint = Vector2.new(0.5, 0.5)
MainShadow.BackgroundTransparency = 1
MainShadow.Image = assetManager:GetShadowAsset()
MainShadow.ImageTransparency = 0.45
MainShadow.ScaleType = Enum.ScaleType.Slice
MainShadow.SliceCenter = Rect.new(99, 99, 99, 99)
MainShadow.ZIndex = 0
MainShadow.Visible = false
MainShadow.Parent = ScreenGui
Instance.new("UICorner", MainShadow).CornerRadius = UDim.new(0, 22)
memoryManager:Track(MainShadow)

local Main = Instance.new("Frame")
Main.Size = MainSize
Main.Position = UDim2.fromScale(0.5, 0.5)
Main.AnchorPoint = Vector2.new(0.5, 0.5)
Main.BackgroundColor3 = theme.Background
Main.BackgroundTransparency = theme.GlassTransparency
Main.Visible = false
Main.ClipsDescendants = true
Main.Parent = ScreenGui
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 22)
memoryManager:Track(Main)

local MainGradient = Instance.new("UIGradient")
MainGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, theme.PrimaryLight),
    ColorSequenceKeypoint.new(0.5, theme.Primary),
    ColorSequenceKeypoint.new(1, theme.PrimaryDark)
})
MainGradient.Rotation = 45
MainGradient.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 0.85),
    NumberSequenceKeypoint.new(0.5, 0.9),
    NumberSequenceKeypoint.new(1, 0.85)
})
MainGradient.Parent = Main

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = theme.Primary
MainStroke.Thickness = 1.5
MainStroke.Transparency = 0.5
MainStroke.Parent = Main

local BG = Instance.new("ImageLabel")
BG.Size = UDim2.fromScale(1, 1)
BG.BackgroundTransparency = 1
BG.ScaleType = Enum.ScaleType.Crop
BG.ImageTransparency = 0.28
BG.Image = assetManager:GetPlaceholderAsset()
BG.Parent = Main
Instance.new("UICorner", BG).CornerRadius = UDim.new(0, 22)

if ExecutorAPI.writefile and ExecutorAPI.isfile and ExecutorAPI.getasset then
    local assetPath = assetManager:GetAssetPath()
    if assetPath ~= "" then
        BG.Image = assetPath
    else
        assetManager:DownloadImage(function(success, path)
            if success and not unloaded and BG and BG.Parent then
                BG.Image = path
                assetManager:PreloadAssets({BG})
            end
        end)
    end
end

local BGNoise = Instance.new("ImageLabel")
BGNoise.Size = UDim2.fromScale(1, 1)
BGNoise.BackgroundTransparency = 1
BGNoise.ScaleType = Enum.ScaleType.Tile
BGNoise.Image = assetManager:GetNoiseAsset()
BGNoise.ImageTransparency = 0.85
BGNoise.TileSize = UDim2.fromOffset(96, 96)
BGNoise.ZIndex = 1
BGNoise.Parent = Main
Instance.new("UICorner", BGNoise).CornerRadius = UDim.new(0, 22)

local Overlay = Instance.new("Frame")
Overlay.Size = UDim2.fromScale(1, 1)
Overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
Overlay.BackgroundTransparency = theme.OverlayTransparency
Overlay.ZIndex = 0
Overlay.Parent = Main

local Sidebar = Instance.new("Frame")
Sidebar.Size = UDim2.new(0, sidebarWidth, 1, 0)
Sidebar.BackgroundColor3 = theme.Sidebar
Sidebar.BackgroundTransparency = theme.SidebarTransparency
Sidebar.BorderSizePixel = 0
Sidebar.ZIndex = 2
Sidebar.Parent = Main
Instance.new("UICorner", Sidebar).CornerRadius = UDim.new(0, 22)

local SidebarGradient = Instance.new("UIGradient")
SidebarGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, theme.PrimaryLight),
    ColorSequenceKeypoint.new(1, theme.PrimaryDark)
})
SidebarGradient.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 0.7),
    NumberSequenceKeypoint.new(1, 0.9)
})
SidebarGradient.Rotation = 180
SidebarGradient.Parent = Sidebar

local SidebarStroke = Instance.new("UIStroke")
SidebarStroke.Color = theme.Primary
SidebarStroke.Thickness = 1
SidebarStroke.Transparency = 0.6
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
TitleBar.Size = UDim2.new(1, -sidebarWidth, 0, isMobile and 44 or 48)
TitleBar.Position = UDim2.new(0, sidebarWidth, 0, 0)
TitleBar.BackgroundTransparency = 1
TitleBar.ZIndex = 3
TitleBar.Parent = Main

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(0.5, 0, 1, 0)
TitleLabel.Position = UDim2.new(0, 16, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "✦ ANDEPZAI HUB"
TitleLabel.TextColor3 = theme.Text
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextSize = isMobile and 15 or 18
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = TitleBar

local TitleGradient = Instance.new("UIGradient")
TitleGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
    ColorSequenceKeypoint.new(1, theme.TextSecondary)
})
TitleGradient.Parent = TitleLabel

dragHandler:Bind(Main, TitleBar, {
    clampPadding = 0,
    dragThreshold = 5
})

connManager:Add(RunService.RenderStepped:Connect(function()
    if unloaded then return end
    if dragHandler:IsDragging() and Main and Main.Visible and MainShadow and MainShadow.Visible then
        MainShadow.Position = Main.Position
    end
end))

local CameraViewportConnection = nil
local function SetupCameraListener()
    local function onViewportChange()
        if unloaded then return end
        if Main and Main.Visible then
            local viewportSize = Camera.ViewportSize
            local newX = math.clamp(Main.Position.X.Offset, 0, math.max(0, viewportSize.X - Main.AbsoluteSize.X))
            local newY = math.clamp(Main.Position.Y.Offset, 0, math.max(0, viewportSize.Y - Main.AbsoluteSize.Y))
            Main.Position = UDim2.new(Main.Position.X.Scale, newX, Main.Position.Y.Scale, newY)
            if MainShadow and MainShadow.Visible then
                MainShadow.Position = Main.Position
            end
        end
        if FloatBtn and FloatBtn.Parent then
            local padding = 10
            local viewportSize = Camera.ViewportSize
            local maxX = math.max(0, viewportSize.X - FloatBtn.AbsoluteSize.X - padding)
            local maxY = math.max(0, viewportSize.Y - FloatBtn.AbsoluteSize.Y - padding)
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
        repeat ExecutorAPI.task_wait() until workspace.CurrentCamera
        if unloaded then return end
        Camera = workspace.CurrentCamera
        CameraViewportConnection = Camera:GetPropertyChangedSignal("ViewportSize"):Connect(onViewportChange)
        onViewportChange()
    end

    connManager:Add(workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(onCameraChange))
    onCameraChange()
end

SetupCameraListener()

if CheckPart("FloatButton") then return end

FloatBtn = Instance.new("TextButton")
FloatBtn.Name = "OpenButton"
FloatBtn.Size = isMobile and UDim2.fromOffset(68, 68) or UDim2.fromOffset(60, 60)
FloatBtn.Position = UDim2.new(0.92, 0, 0.85, 0)
FloatBtn.AnchorPoint = Vector2.new(0.5, 0.5)
FloatBtn.BackgroundColor3 = theme.Primary
FloatBtn.BackgroundTransparency = 0.1
FloatBtn.Text = "✦"
FloatBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
FloatBtn.Font = Enum.Font.GothamBold
FloatBtn.TextSize = isMobile and 32 or 28
FloatBtn.ClipsDescendants = true
FloatBtn.Active = true
FloatBtn.AutoButtonColor = false
FloatBtn.Parent = ScreenGui
Instance.new("UICorner", FloatBtn).CornerRadius = UDim.new(0, 34)
memoryManager:Track(FloatBtn)

local FloatGradient = Instance.new("UIGradient")
FloatGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, theme.PrimaryLight),
    ColorSequenceKeypoint.new(1, theme.Primary)
})
FloatGradient.Rotation = 135
FloatGradient.Parent = FloatBtn

local FloatStroke = Instance.new("UIStroke")
FloatStroke.Color = theme.PrimaryLight
FloatStroke.Thickness = 2
FloatStroke.Transparency = 0.4
FloatStroke.Parent = FloatBtn

local FloatShadow = Instance.new("ImageLabel")
FloatShadow.Name = "Shadow"
FloatShadow.Size = UDim2.new(1, 28, 1, 28)
FloatShadow.AnchorPoint = Vector2.new(0.5, 0.5)
FloatShadow.Position = UDim2.new(0.5, 0, 0.5, 0)
FloatShadow.BackgroundTransparency = 1
FloatShadow.Image = assetManager:GetShadowAsset()
FloatShadow.ImageTransparency = 0.5
FloatShadow.ScaleType = Enum.ScaleType.Slice
FloatShadow.SliceCenter = Rect.new(99, 99, 99, 99)
FloatShadow.ZIndex = -2
FloatShadow.Parent = FloatBtn
Instance.new("UICorner", FloatShadow).CornerRadius = UDim.new(0, 34)

local FloatGlow = Instance.new("Frame")
FloatGlow.Size = UDim2.fromScale(1, 1)
FloatGlow.BackgroundColor3 = theme.Primary
FloatGlow.BackgroundTransparency = 0.5
FloatGlow.ZIndex = -1
FloatGlow.Parent = FloatBtn
Instance.new("UICorner", FloatGlow).CornerRadius = UDim.new(0, 34)

local FloatGlowGradient = Instance.new("UIGradient")
FloatGlowGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
    ColorSequenceKeypoint.new(1, theme.Primary)
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

local floatDragHandler = DragHandler.new(connManager, tweenManager)
floatDragHandler:Bind(FloatBtn, FloatBtn, {
    clampPadding = 10,
    dragThreshold = 8
})

connManager:Add(FloatBtn.MouseEnter:Connect(function()
    if unloaded or floatDragHandler:IsDragging() then return end
    local hoverTween = tweenManager:Create(FloatHoverHighlight, EasingPresets.hover, {
        BackgroundTransparency = 0.85
    })
    tweenManager:Play(hoverTween)
end))

connManager:Add(FloatBtn.MouseLeave:Connect(function()
    if unloaded then return end
    local hoverTween = tweenManager:Create(FloatHoverHighlight, EasingPresets.hover, {
        BackgroundTransparency = 1
    })
    tweenManager:Play(hoverTween)
end))

if CheckPart("WindowControls") then return end

local Busy = false

local function SetBusy(state)
    Busy = state
end

local Close = uiFactory:CreateButton(TitleBar, "✕", UDim2.fromOffset(isMobile and 36 or 32, isMobile and 36 or 32), UDim2.new(1, -(isMobile and 40 or 36), 0, isMobile and 6 or 4))
Close.BackgroundTransparency = 1
Close.TextColor3 = theme.Secondary
Close.ZIndex = 5

tooltipSystem:Attach(Close, "Close Window", "Bottom")

local UnloadBtn = uiFactory:CreateButton(TitleBar, "⏻", UDim2.fromOffset(isMobile and 30 or 26, isMobile and 30 or 26), UDim2.new(1, -(isMobile and 72 or 66), 0, isMobile and 6 or 4))
UnloadBtn.BackgroundTransparency = 1
UnloadBtn.TextColor3 = theme.Accent
UnloadBtn.ZIndex = 5

tooltipSystem:Attach(UnloadBtn, "Unload UI", "Bottom")

local function OpenUI()
    if unloaded or Busy or Main.Visible then return end
    SetBusy(true)
    
    Main.Size = UDim2.new(0, 0, 0, 0)
    Main.Visible = true
    MainShadow.Visible = true
    MainShadow.Size = UDim2.new(0, 0, 0, 0)
    
    local mainTween = tweenManager:Create(Main, EasingPresets.openWindow, { Size = MainSize })
    local shadowTween = tweenManager:Create(MainShadow, EasingPresets.openWindow, { Size = MainSize + UDim2.fromOffset(40, 40) })
    
    tweenManager:Play(mainTween, function()
        if unloaded then return end
        FloatBtn.Visible = false
        SetBusy(false)
    end)
    tweenManager:Play(shadowTween)
end

local function CloseUI()
    if unloaded or Busy or not Main.Visible then return end
    SetBusy(true)
    
    local mainTween = tweenManager:Create(Main, EasingPresets.closeWindow, { Size = UDim2.new(0, 0, 0, 0) })
    local shadowTween = tweenManager:Create(MainShadow, EasingPresets.closeWindow, { Size = UDim2.new(0, 0, 0, 0) })
    
    tweenManager:Play(mainTween, function()
        if unloaded then return end
        Main.Visible = false
        MainShadow.Visible = false
        FloatBtn.Visible = true
        SetBusy(false)
    end)
    tweenManager:Play(shadowTween)
end

local function OpenPressed()
    if not floatDragHandler:WasDragged() then
        rippleSystem:Create(FloatBtn, function()
            OpenUI()
        end)
    end
end

connManager:Add(FloatBtn.Activated:Connect(OpenPressed))

connManager:Add(Close.Activated:Connect(function()
    if not unloaded and Main.Visible then
        CloseUI()
    end
end))

connManager:Add(UnloadBtn.Activated:Connect(function()
    UnloadUI()
end))

local pulseTween
local function StartPulse()
    if unloaded then return end
    if pulseTween then
        tweenManager:Cancel(pulseTween)
    end
    if not FloatScale then return end
    pulseTween = tweenManager:Create(FloatScale, EasingPresets.pulse, { Scale = 1.12 })
    tweenManager:Play(pulseTween)
end
StartPulse()

if not isMobile then
    local Keybind = Enum.KeyCode.F1
    connManager:Add(UserInputService.InputBegan:Connect(function(input, gameProcessed)
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

if CheckPart("SidebarContent") then return end

local LogoArea = Instance.new("Frame")
LogoArea.Size = UDim2.new(1, 0, 0, isMobile and 60 or 70)
LogoArea.BackgroundTransparency = 1
LogoArea.Parent = Sidebar

local LogoIcon = Instance.new("TextLabel")
LogoIcon.Size = UDim2.fromOffset(isMobile and 40 or 50, isMobile and 40 or 50)
LogoIcon.Position = UDim2.fromOffset(20, 15)
LogoIcon.BackgroundColor3 = theme.Primary
LogoIcon.BackgroundTransparency = 0.1
LogoIcon.Text = "✦"
LogoIcon.TextColor3 = theme.PrimaryLight
LogoIcon.Font = Enum.Font.GothamBold
LogoIcon.TextSize = isMobile and 24 or 30
LogoIcon.Parent = LogoArea
Instance.new("UICorner", LogoIcon).CornerRadius = UDim.new(0, 12)

local LogoStroke = Instance.new("UIStroke")
LogoStroke.Color = theme.PrimaryLight
LogoStroke.Thickness = 1.5
LogoStroke.Transparency = 0.5
LogoStroke.Parent = LogoIcon

local Separator = Instance.new("Frame")
Separator.Size = UDim2.new(1, -32, 0, 1)
Separator.Position = UDim2.new(0, 16, 0, isMobile and 65 or 75)
Separator.BackgroundColor3 = theme.Primary
Separator.BackgroundTransparency = 0.7
Separator.BorderSizePixel = 0
Separator.Parent = Sidebar

if CheckPart("UnloadFunction") then return end

function UnloadUI()
    if unloaded then return end
    unloaded = true
    
    SetBusy(true)
    
    assetManager:CancelDownload()
    
    if pulseTween then
        tweenManager:Cancel(pulseTween)
        pulseTween = nil
    end
    
    dragHandler:Cleanup()
    floatDragHandler:Cleanup()
    tooltipSystem:Cleanup()
    tweenManager:Cleanup()
    connManager:Cleanup()
    assetManager:Cleanup()
    
    pcall(function()
        if ScreenGui and ScreenGui.Parent then
            ScreenGui:Destroy()
        end
    end)
    
    uiFactory._scaleCache = {}
    PART_LOADED = {}
    
    ExecutorAPI.collectgarbage("collect")
end

if CheckPart("PublicAPI") then return end

local AndepzaiHub = {
    Open = OpenUI,
    Close = CloseUI,
    Unload = UnloadUI,
    SetTheme = function(themeName) return themeManager:SetTheme(themeName) end,
    GetTheme = function() return themeManager:GetTheme() end,
    GetThemes = function() return themeManager:GetAllThemes() end,
    Notify = function(title, message, duration, notifType)
        notificationSystem:Show(title, message, duration, notifType)
    end,
    CreateButton = function(parent, text, size, position, callback)
        return uiFactory:CreateButton(parent or ContentArea, text, size, position, callback)
    end,
    CreateToggle = function(parent, text, default, position, callback)
        return uiFactory:CreateToggle(parent or ContentArea, text, default, position, callback)
    end,
    CreateSlider = function(parent, text, min, max, default, position, callback)
        return uiFactory:CreateSlider(parent or ContentArea, text, min, max, default, position, callback)
    end,
    GetMainFrame = function() return Main end,
    GetContentArea = function() return ContentArea end,
    GetSidebar = function() return Sidebar end,
    GetFloatButton = function() return FloatBtn end,
    IsMobile = function() return isMobile end,
    SetFloatButtonIcon = function(icon)
        if FloatBtn then FloatBtn.Text = icon end
    end,
    SetFloatButtonColor = function(color)
        if FloatBtn then
            FloatBtn.BackgroundColor3 = color
            FloatGradient.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(
                    math.min(color.R * 255 + 50, 255),
                    math.min(color.G * 255 + 50, 255),
                    math.min(color.B * 255 + 50, 255)
                )),
                ColorSequenceKeypoint.new(1, color)
            })
        end
    end,
    SetFloatButtonSize = function(size)
        if FloatBtn and size then
            FloatBtn.Size = size
        end
    end,
    SetBackgroundImage = function(url)
        assetManager:SetImageUrl(url)
    end
}

getgenv().AndepzaiHub = AndepzaiHub

return AndepzaiHub