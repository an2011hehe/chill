local function setupExecutorAPI()
    local api = {}
    api.request = (syn and syn.request) or http_request or request or (fluxus and fluxus.request) or (http and http.request)
    api.getasset = getcustomasset or getsynasset
    api.writefile = writefile
    api.isfile = isfile
    api.gethui = gethui
    api.task_spawn = (task and task.spawn) or spawn or function(f) coroutine.wrap(f)() end
    api.task_wait = (task and task.wait) or wait
    api.task_delay = (task and task.delay) or delay
    api.task_cancel = (task and task.cancel) or function() end
    api.pcall = pcall
    api.collectgarbage = collectgarbage or function() end
    return api
end
local Executor = setupExecutorAPI()

local unloaded = false
local function SafeDestroy(obj)
    if obj and obj.Parent then pcall(function() obj:Destroy() end) end
end

pcall(function()
    local parent = Executor.gethui and Executor.gethui() or game:GetService("CoreGui")
    local old = parent:FindFirstChild("AndepzaiHubPro")
    if old then SafeDestroy(old) end
end)

local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ContentProvider = game:GetService("ContentProvider")
local HttpService = game:GetService("HttpService")
local TextService = game:GetService("TextService")
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

function ConnectionManager:AddSignal(name, conn)
    if conn and not unloaded then
        self._signals[name] = conn
    end
    return conn
end

function ConnectionManager:DisconnectSignal(name)
    if self._signals[name] then
        pcall(function() self._signals[name]:Disconnect() end)
        self._signals[name] = nil
    end
end

function ConnectionManager:Cleanup()
    for _, conn in ipairs(self._connections) do
        pcall(function() conn:Disconnect() end)
    end
    for _, conn in pairs(self._signals) do
        pcall(function() conn:Disconnect() end)
    end
    self._connections = {}
    self._signals = {}
end

local TweenManager = {}
TweenManager.__index = TweenManager

function TweenManager.new(connManager)
    local self = setmetatable({
        _tweens = {},
        _connManager = connManager
    }, TweenManager)
    return self
end

function TweenManager:Create(instance, info, props)
    if not instance or unloaded then return nil end
    return TweenService:Create(instance, info, props)
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

local Easing = {
    openWindow = TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
    closeWindow = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
    openSidebar = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    closeSidebar = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
    hover = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    click = TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    pulse = TweenInfo.new(0.75, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true, 0),
    slide = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    fade = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    ripple = TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    notification = TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
    elastic = TweenInfo.new(0.5, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out),
    spring = TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
    tabSwitch = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    pageTransition = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
}

local MemoryManager = {}
MemoryManager.__index = MemoryManager

function MemoryManager.new()
    return setmetatable({
        _objects = {},
        _cache = {}
    }, MemoryManager)
end

function MemoryManager:Track(obj)
    if obj then table.insert(self._objects, obj) end
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
        GlassBlur = true,
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
        GlassBlur = true,
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
        GlassBlur = true,
    },
}

function ThemeManager.new()
    local self = setmetatable({
        _currentTheme = Themes.Default,
        _themeName = "Default"
    }, ThemeManager)
    return self
end

function ThemeManager:SetTheme(name)
    if Themes[name] then
        self._currentTheme = Themes[name]
        self._themeName = name
        return true
    end
    return false
end

function ThemeManager:GetTheme()
    return self._currentTheme
end

function ThemeManager:GetColor(name)
    return self._currentTheme[name] or self._currentTheme.Primary
end

function ThemeManager:GetAllThemes()
    local list = {}
    for name, _ in pairs(Themes) do
        table.insert(list, name)
    end
    return list
end

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
        _downloadThread = nil,
    }, AssetManager)
    return self
end

function AssetManager:GetRequest()
    return Executor.request
end

function AssetManager:DownloadImage(callback)
    if unloaded or not Executor.isfile or not Executor.writefile then
        if callback then callback(false) end
        return false
    end
    if Executor.isfile(self._fileName) then
        self._assetPath = Executor.getasset(self._fileName)
        if callback then callback(true, self._assetPath) end
        return true
    end
    local req = self:GetRequest()
    if not req then
        if callback then callback(false) end
        return false
    end
    self._downloadThread = Executor.task_spawn(function()
        for attempt = 1, self._maxRetries do
            if unloaded then
                if callback then callback(false) end
                return
            end
            local success, res = pcall(function()
                return req({ Url = self._imageUrl, Method = "GET" })
            end)
            if unloaded then
                if callback then callback(false) end
                return
            end
            if success and res and res.Success and Executor.writefile then
                Executor.writefile(self._fileName, res.Body)
                self._assetPath = Executor.getasset(self._fileName)
                if callback then callback(true, self._assetPath) end
                return
            end
            if attempt < self._maxRetries then
                Executor.task_wait(self._retryDelay)
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
    Executor.task_spawn(function()
        local success = pcall(function()
            ContentProvider:PreloadAsync(assets)
        end)
        if callback then callback(success) end
    end)
end

function AssetManager:CancelDownload()
    if self._downloadThread then
        Executor.task_cancel(self._downloadThread)
        self._downloadThread = nil
    end
end

function AssetManager:Cleanup()
    self:CancelDownload()
    self._assetCache = {}
    self._downloadQueue = {}
end

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
        _useRenderStepped = true,
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
        if input.UserInputType == Enum.UserInputType.MouseButton1 or
           input.UserInputType == Enum.UserInputType.Touch then
            self._isDragging = true
            self._dragStart = input.Position
            self._startPos = target.Position
            self._target = target
            self._dragMoved = false
        end
    end))

    if self._useRenderStepped then
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
    end

    self._connManager:Add(UserInputService.InputEnded:Connect(function(input)
        if unloaded then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 or
           input.UserInputType == Enum.UserInputType.Touch then
            self._isDragging = false
            self._dragStart = nil
            self._startPos = nil
            self._target = nil
            Executor.task_delay(0.05, function()
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

local RippleSystem = {}
RippleSystem.__index = RippleSystem

function RippleSystem.new(tweenManager)
    return setmetatable({ _tweenManager = tweenManager }, RippleSystem)
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
    local tween = self._tweenManager:Create(ripple, Easing.ripple, {
        Size = UDim2.fromOffset(targetSize, targetSize),
        BackgroundTransparency = 1,
    })
    self._tweenManager:Play(tween, function()
        SafeDestroy(ripple)
        if callback then callback() end
    end)
end

local NotificationSystem = {}
NotificationSystem.__index = NotificationSystem

function NotificationSystem.new(tweenManager, themeManager)
    local self = setmetatable({
        _tweenManager = tweenManager,
        _themeManager = themeManager,
        _notifications = {},
        _maxNotifications = 5,
        _screenGui = nil,
    }, NotificationSystem)
    return self
end

function NotificationSystem:SetScreenGui(gui)
    self._screenGui = gui
end

function NotificationSystem:Show(title, message, duration, notificationType)
    if unloaded or not self._screenGui then return end
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
    notification.Parent = self._screenGui

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
        ColorSequenceKeypoint.new(1, theme.PrimaryDark),
    })
    gradient.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.9),
        NumberSequenceKeypoint.new(1, 0.95),
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
    local openTween = self._tweenManager:Create(notification, Easing.notification, {
        Size = UDim2.fromOffset(280, notificationHeight),
        Position = UDim2.new(1, -300, 1, -20 - (#self._notifications * (notificationHeight + 10))),
    })
    self._tweenManager:Play(openTween)

    local progressTween = self._tweenManager:Create(progressBar, TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 0, 0, 3),
    })
    self._tweenManager:Play(progressTween)

    table.insert(self._notifications, notification)

    Executor.task_delay(duration + 0.3, function()
        if unloaded then return end
        local closeTween = self._tweenManager:Create(notification, Easing.fade, {
            Size = UDim2.fromOffset(280, 0),
            BackgroundTransparency = 1,
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

local TooltipSystem = {}
TooltipSystem.__index = TooltipSystem

function TooltipSystem.new(connManager, tweenManager, themeManager)
    local self = setmetatable({
        _connManager = connManager,
        _tweenManager = tweenManager,
        _themeManager = themeManager,
        _currentTooltip = nil,
        _screenGui = nil,
    }, TooltipSystem)
    return self
end

function TooltipSystem:SetScreenGui(gui)
    self._screenGui = gui
end

function TooltipSystem:Attach(button, text, position)
    if not button or not self._screenGui then return end
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
    if not parent or unloaded or not self._screenGui then return end
    local theme = self._themeManager:GetTheme()
    local tooltip = Instance.new("Frame")
    tooltip.Size = UDim2.fromOffset(0, 0)
    tooltip.BackgroundColor3 = theme.Background
    tooltip.BackgroundTransparency = 0.1
    tooltip.ZIndex = 200
    tooltip.ClipsDescendants = true
    tooltip.Parent = self._screenGui

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

    local textSize = TextService:GetTextSize(text, 12, "Gotham", Vector2.new(1000, 1000))
    local tooltipWidth = textSize.X + 24
    local tooltipHeight = textSize.Y + 12
    local parentPos = parent.AbsolutePosition
    local parentSize = parent.AbsoluteSize
    local tooltipPos
    if position == "Top" then
        tooltipPos = UDim2.fromOffset(
            parentPos.X + parentSize.X / 2 - tooltipWidth / 2,
            parentPos.Y - tooltipHeight - 8
        )
    elseif position == "Bottom" then
        tooltipPos = UDim2.fromOffset(
            parentPos.X + parentSize.X / 2 - tooltipWidth / 2,
            parentPos.Y + parentSize.Y + 8
        )
    elseif position == "Left" then
        tooltipPos = UDim2.fromOffset(
            parentPos.X - tooltipWidth - 8,
            parentPos.Y + parentSize.Y / 2 - tooltipHeight / 2
        )
    else
        tooltipPos = UDim2.fromOffset(
            parentPos.X + parentSize.X + 8,
            parentPos.Y + parentSize.Y / 2 - tooltipHeight / 2
        )
    end
    tooltip.Position = tooltipPos

    local openTween = self._tweenManager:Create(tooltip, Easing.fade, {
        Size = UDim2.fromOffset(tooltipWidth, tooltipHeight),
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

local UIFactory = {}
UIFactory.__index = UIFactory

function UIFactory.new(connManager, tweenManager, themeManager, rippleSystem, tooltipSystem)
    local self = setmetatable({
        _connManager = connManager,
        _tweenManager = tweenManager,
        _themeManager = themeManager,
        _rippleSystem = rippleSystem,
        _tooltipSystem = tooltipSystem,
    }, UIFactory)
    return self
end

function UIFactory:CreateButton(parent, text, size, position, callback, tooltipText)
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
        ColorSequenceKeypoint.new(1, theme.PrimaryDark),
    })
    gradient.Rotation = 135
    gradient.Parent = button

    local scaleObj = Instance.new("UIScale")
    scaleObj.Parent = button

    self._connManager:Add(button.MouseEnter:Connect(function()
        if unloaded then return end
        local hoverTween = self._tweenManager:Create(button, Easing.hover, {
            BackgroundTransparency = 0.05,
        })
        self._tweenManager:Play(hoverTween)
    end))

    self._connManager:Add(button.MouseLeave:Connect(function()
        if unloaded then return end
        local leaveTween = self._tweenManager:Create(button, Easing.hover, {
            BackgroundTransparency = 0.1,
        })
        self._tweenManager:Play(leaveTween)
    end))

    if callback then
        self._connManager:Add(button.Activated:Connect(function()
            if unloaded then return end
            self._rippleSystem:Create(button)
            local clickTween = self._tweenManager:Create(scaleObj, Easing.click, { Scale = 0.9 })
            local releaseTween = self._tweenManager:Create(scaleObj, Easing.click, { Scale = 1 })
            self._tweenManager:Play(clickTween, function()
                if unloaded then return end
                self._tweenManager:Play(releaseTween)
                callback()
            end)
        end))
    end

    if tooltipText then
        self._tooltipSystem:Attach(button, tooltipText)
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
        local bgTween = self._tweenManager:Create(toggleButton, Easing.hover, {
            BackgroundColor3 = isToggled and theme.Primary or Color3.fromRGB(60, 60, 80),
        })
        local knobTween = self._tweenManager:Create(toggleKnob, Easing.hover, {
            Position = isToggled and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 3, 0.5, -9),
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

    local isDragging = false
    self._connManager:Add(sliderKnob.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or
           input.UserInputType == Enum.UserInputType.Touch then
            isDragging = true
        end
    end))

    self._connManager:Add(UserInputService.InputChanged:Connect(function(input)
        if not isDragging or unloaded then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement or
           input.UserInputType == Enum.UserInputType.Touch then
            local barPos = sliderBar.AbsolutePosition.X
            local barSize = sliderBar.AbsoluteSize.X
            local mouseX = input.Position.X
            local pct = math.clamp((mouseX - barPos) / barSize, 0, 1)
            value = min + (max - min) * pct
            value = math.round(value)
            sliderFill.Size = UDim2.fromScale((value - min) / (max - min), 1)
            sliderKnob.Position = UDim2.new((value - min) / (max - min), -8, 0.5, -8)
            label.Text = (text or "Slider") .. ": " .. tostring(value)
            if callback then callback(value) end
        end
    end))

    self._connManager:Add(UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or
           input.UserInputType == Enum.UserInputType.Touch then
            isDragging = false
        end
    end))

    return container
end

local function CreateFloatingButton(screenGui, connManager, tweenManager, themeManager, dragHandler, onOpen)
    local theme = themeManager:GetTheme()
    local floatBtn = Instance.new("TextButton")
    floatBtn.Name = "FloatButton"
    floatBtn.Size = isMobile and UDim2.fromOffset(64, 64) or UDim2.fromOffset(56, 56)
    floatBtn.Position = UDim2.new(0.92, 0, 0.85, 0)
    floatBtn.AnchorPoint = Vector2.new(0.5, 0.5)
    floatBtn.BackgroundColor3 = theme.Primary
    floatBtn.BackgroundTransparency = 0.1
    floatBtn.Text = "✦"
    floatBtn.TextColor3 = theme.Text
    floatBtn.Font = Enum.Font.GothamBold
    floatBtn.TextSize = isMobile and 32 or 28
    floatBtn.ClipsDescendants = true
    floatBtn.AutoButtonColor = false
    floatBtn.Parent = screenGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 32)
    corner.Parent = floatBtn

    local stroke = Instance.new("UIStroke")
    stroke.Color = theme.PrimaryLight
    stroke.Thickness = 2
    stroke.Transparency = 0.5
    stroke.Parent = floatBtn

    local glow = Instance.new("Frame")
    glow.Size = UDim2.fromScale(1, 1)
    glow.BackgroundColor3 = theme.Primary
    glow.BackgroundTransparency = 0.5
    glow.ZIndex = -1
    glow.Parent = floatBtn
    local glowCorner = Instance.new("UICorner")
    glowCorner.CornerRadius = UDim.new(0, 32)
    glowCorner.Parent = glow

    local scaleObj = Instance.new("UIScale")
    scaleObj.Parent = floatBtn

    local pulseRunning = true
    connManager:Add(RunService.Heartbeat:Connect(function()
        if floatBtn and floatBtn.Parent and pulseRunning then
            scaleObj.Scale = 1 + math.sin(os.clock() * 2) * 0.03
        end
    end))

    dragHandler:Bind(floatBtn, floatBtn, {
        clampPadding = 10,
        dragThreshold = 10,
    })

    local function onPress()
        if not dragHandler:IsDragging() then
            connManager:Add(tweenManager:Create(scaleObj, Easing.click, { Scale = 0.85 }))
            tweenManager:Play(connManager._tweens[#connManager._tweens], function()
                tweenManager:Create(scaleObj, Easing.click, { Scale = 1 })
                tweenManager:Play(connManager._tweens[#connManager._tweens])
            end)
            if onOpen then onOpen() end
        end
    end

    connManager:Add(floatBtn.Activated:Connect(onPress))

    return floatBtn
end

local function CreateMainWindow(screenGui, connManager, tweenManager, themeManager, assetManager, dragHandler, notificationSystem)
    local theme = themeManager:GetTheme()
    local mainSize = isMobile and UDim2.fromOffset(340, 440) or UDim2.fromOffset(420, 480)

    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainWindow"
    mainFrame.Size = mainSize
    mainFrame.Position = UDim2.fromScale(0.5, 0.5)
    mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    mainFrame.BackgroundColor3 = theme.Background
    mainFrame.BackgroundTransparency = 0.1
    mainFrame.ClipsDescendants = true
    mainFrame.Visible = false
    mainFrame.Parent = screenGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 20)
    corner.Parent = mainFrame

    local stroke = Instance.new("UIStroke")
    stroke.Color = theme.PrimaryLight
    stroke.Thickness = 1.5
    stroke.Transparency = 0.3
    stroke.Parent = mainFrame

    local assetPath = assetManager:GetAssetPath()
    local bg = Instance.new("ImageLabel")
    bg.Size = UDim2.fromScale(1, 1)
    bg.BackgroundTransparency = 1
    bg.Image = (assetPath ~= "") and assetPath or assetManager:GetPlaceholderAsset()
    bg.ScaleType = Enum.ScaleType.Crop
    bg.ImageTransparency = 0.3
    bg.Parent = mainFrame

    local bgCorner = Instance.new("UICorner")
    bgCorner.CornerRadius = UDim.new(0, 20)
    bgCorner.Parent = bg

    local blurOverlay = Instance.new("Frame")
    blurOverlay.Size = UDim2.fromScale(1, 1)
    blurOverlay.BackgroundColor3 = theme.Background
    blurOverlay.BackgroundTransparency = 0.6
    blurOverlay.ZIndex = 1
    blurOverlay.Parent = mainFrame

    local noise = Instance.new("ImageLabel")
    noise.Size = UDim2.fromScale(1, 1)
    noise.BackgroundTransparency = 1
    noise.Image = assetManager:GetNoiseAsset()
    noise.ImageTransparency = 0.95
    noise.ScaleType = Enum.ScaleType.Tile
    noise.TileSize = UDim2.fromOffset(128, 128)
    noise.ZIndex = 2
    noise.Parent = mainFrame

    local titleBar = Instance.new("Frame")
    titleBar.Size = UDim2.new(1, 0, 0, 48)
    titleBar.BackgroundTransparency = 1
    titleBar.ZIndex = 3
    titleBar.Parent = mainFrame

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(0.5, 0, 1, 0)
    titleLabel.Position = UDim2.new(0, 16, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "✦ ANDEPZAI HUB"
    titleLabel.TextColor3 = theme.Text
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextSize = isMobile and 15 or 17
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.ZIndex = 4
    titleLabel.Parent = titleBar

    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.fromOffset(isMobile and 32 or 28, isMobile and 32 or 28)
    closeBtn.Position = UDim2.new(1, -(isMobile and 36 or 32), 0.5, -(isMobile and 16 or 14))
    closeBtn.BackgroundTransparency = 1
    closeBtn.Text = "✕"
    closeBtn.TextColor3 = theme.Error
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = isMobile and 18 or 16
    closeBtn.AutoButtonColor = false
    closeBtn.ZIndex = 4
    closeBtn.Parent = titleBar

    local unloadBtn = Instance.new("TextButton")
    unloadBtn.Size = UDim2.fromOffset(isMobile and 32 or 28, isMobile and 32 or 28)
    unloadBtn.Position = UDim2.new(1, -(isMobile and 72 or 64), 0.5, -(isMobile and 16 or 14))
    unloadBtn.BackgroundTransparency = 1
    unloadBtn.Text = "⏻"
    unloadBtn.TextColor3 = theme.Accent
    unloadBtn.Font = Enum.Font.GothamBold
    unloadBtn.TextSize = isMobile and 18 or 16
    unloadBtn.AutoButtonColor = false
    unloadBtn.ZIndex = 4
    unloadBtn.Parent = titleBar

    local sidebar = Instance.new("ScrollingFrame")
    sidebar.Size = UDim2.new(0, isMobile and 160 or 180, 1, 0)
    sidebar.Position = UDim2.new(0, 0, 0, 48)
    sidebar.BackgroundColor3 = theme.Sidebar
    sidebar.BackgroundTransparency = theme.SidebarTransparency
    sidebar.BorderSizePixel = 0
    sidebar.ScrollBarThickness = 0
    sidebar.CanvasSize = UDim2.new(0, 0, 0, 0)
    sidebar.ZIndex = 3
    sidebar.Parent = mainFrame

    local sidebarContent = Instance.new("UIListLayout")
    sidebarContent.Padding = UDim.new(0, 4)
    sidebarContent.SortOrder = Enum.SortOrder.LayoutOrder
    sidebarContent.HorizontalAlignment = Enum.HorizontalAlignment.Center
    sidebarContent.Parent = sidebar

    local contentArea = Instance.new("ScrollingFrame")
    contentArea.Size = UDim2.new(1, -(isMobile and 160 or 180), 1, -48)
    contentArea.Position = UDim2.new(0, isMobile and 160 or 180, 0, 48)
    contentArea.BackgroundTransparency = 1
    contentArea.BorderSizePixel = 0
    contentArea.ScrollBarThickness = 3
    contentArea.ScrollBarImageColor3 = theme.Primary
    contentArea.ScrollBarImageTransparency = 0.6
    contentArea.CanvasSize = UDim2.new(0, 0, 0, 0)
    contentArea.ZIndex = 3
    contentArea.Parent = mainFrame

    local contentList = Instance.new("UIListLayout")
    contentList.Padding = UDim.new(0, 8)
    contentList.SortOrder = Enum.SortOrder.LayoutOrder
    contentList.HorizontalAlignment = Enum.HorizontalAlignment.Center
    contentList.Parent = contentArea

    dragHandler:Bind(mainFrame, titleBar, {
        clampPadding = 10,
        dragThreshold = 10,
    })

    local function closeUI()
        if not mainFrame.Visible then return end
        local closeTween = tweenManager:Create(mainFrame, Easing.closeWindow, {
            Size = UDim2.new(0, 0, 0, 0),
        })
        tweenManager:Play(closeTween, function()
            mainFrame.Visible = false
        end)
    end

    connManager:Add(closeBtn.Activated:Connect(closeUI))

    local function unloadUI()
        unloaded = true
        tweenManager:Cleanup()
        connManager:Cleanup()
        assetManager:Cleanup()
        dragHandler:Cleanup()
        notificationSystem:Cleanup()
        SafeDestroy(screenGui)
        mainFrame = nil
        screenGui = nil
    end

    connManager:Add(unloadBtn.Activated:Connect(unloadUI))

    local function openUI()
        if mainFrame.Visible then return end
        mainFrame.Size = UDim2.new(0, 0, 0, 0)
        mainFrame.Visible = true
        local openTween = tweenManager:Create(mainFrame, Easing.openWindow, {
            Size = mainSize,
        })
        tweenManager:Play(openTween)
    end

    local function toggleUI()
        if mainFrame.Visible then
            closeUI()
        else
            openUI()
        end
    end

    if not isMobile then
        connManager:Add(UserInputService.InputBegan:Connect(function(input, gpe)
            if gpe then return end
            if input.KeyCode == Enum.KeyCode.F1 then
                toggleUI()
            end
        end))
    end

    return {
        Frame = mainFrame,
        Open = openUI,
        Close = closeUI,
        Toggle = toggleUI,
        ContentArea = contentArea,
        ContentList = contentList,
        Sidebar = sidebar,
        SidebarContent = sidebarContent,
        TitleBar = titleBar,
    }
end

local function AddSidebarCategory(sidebar, connManager, tweenManager, themeManager, title)
    local theme = themeManager:GetTheme()
    local category = Instance.new("Frame")
    category.Size = UDim2.new(1, -12, 0, 32)
    category.BackgroundTransparency = 1
    category.Parent = sidebar

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.Position = UDim2.new(0, 12, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = title
    label.TextColor3 = theme.TextSecondary
    label.Font = Enum.Font.GothamBold
    label.TextSize = 10
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextTransparency = 0.4
    label.Parent = category

    return category
end

local function AddSidebarTab(sidebar, connManager, tweenManager, themeManager, rippleSystem, icon, title, callback, tooltipText)
    local theme = themeManager:GetTheme()
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, -12, 0, 36)
    button.Position = UDim2.new(0, 6, 0, 0)
    button.BackgroundColor3 = theme.Primary
    button.BackgroundTransparency = 1
    button.Text = ""
    button.AutoButtonColor = false
    button.ClipsDescendants = true
    button.Parent = sidebar

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = button

    local iconLabel = Instance.new("TextLabel")
    iconLabel.Size = UDim2.fromOffset(24, 24)
    iconLabel.Position = UDim2.new(0, 8, 0.5, -12)
    iconLabel.BackgroundTransparency = 1
    iconLabel.Text = icon or "•"
    iconLabel.TextColor3 = theme.TextSecondary
    iconLabel.Font = Enum.Font.Gotham
    iconLabel.TextSize = 16
    iconLabel.TextXAlignment = Enum.TextXAlignment.Center
    iconLabel.Parent = button

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -40, 1, 0)
    titleLabel.Position = UDim2.new(0, 36, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = title or "Tab"
    titleLabel.TextColor3 = theme.TextSecondary
    titleLabel.Font = Enum.Font.Gotham
    titleLabel.TextSize = 12
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = button

    local isActive = false
    local activeIndicator = Instance.new("Frame")
    activeIndicator.Size = UDim2.fromOffset(3, 16)
    activeIndicator.Position = UDim2.new(0, 0, 0.5, -8)
    activeIndicator.BackgroundColor3 = theme.Primary
    activeIndicator.BackgroundTransparency = 1
    activeIndicator.Parent = button
    local indicatorCorner = Instance.new("UICorner")
    indicatorCorner.CornerRadius = UDim.new(0, 2)
    indicatorCorner.Parent = activeIndicator

    local function setActive(active)
        isActive = active
        local targetTrans = active and 0 or 1
        local targetColor = active and theme.Text or theme.TextSecondary
        local targetBg = active and 0.8 or 1
        tweenManager:Create(activeIndicator, Easing.slide, { BackgroundTransparency = targetTrans })
        tweenManager:Play(connManager._tweens[#connManager._tweens])
        tweenManager:Create(titleLabel, Easing.fade, { TextColor3 = targetColor })
        tweenManager:Play(connManager._tweens[#connManager._tweens])
        tweenManager:Create(iconLabel, Easing.fade, { TextColor3 = targetColor })
        tweenManager:Play(connManager._tweens[#connManager._tweens])
        tweenManager:Create(button, Easing.hover, { BackgroundTransparency = targetBg })
        tweenManager:Play(connManager._tweens[#connManager._tweens])
    end

    connManager:Add(button.MouseEnter:Connect(function()
        if unloaded then return end
        if not isActive then
            tweenManager:Create(button, Easing.hover, { BackgroundTransparency = 0.85 })
            tweenManager:Play(connManager._tweens[#connManager._tweens])
        end
    end))

    connManager:Add(button.MouseLeave:Connect(function()
        if unloaded then return end
        if not isActive then
            tweenManager:Create(button, Easing.hover, { BackgroundTransparency = 1 })
            tweenManager:Play(connManager._tweens[#connManager._tweens])
        end
    end))

    connManager:Add(button.Activated:Connect(function()
        if unloaded then return end
        rippleSystem:Create(button)
        if callback then callback(button, setActive) end
        setActive(true)
    end))

    if tooltipText then
        local tooltipSystem = TooltipSystem.new(connManager, tweenManager, themeManager)
        tooltipSystem:Attach(button, tooltipText)
    end

    return button, setActive
end

local function Main()
    local connManager = ConnectionManager.new()
    local tweenManager = TweenManager.new(connManager)
    local memoryManager = MemoryManager.new()
    local themeManager = ThemeManager.new()
    local assetManager = AssetManager.new(connManager, memoryManager)
    local dragHandler = DragHandler.new(connManager, tweenManager)
    local rippleSystem = RippleSystem.new(tweenManager)
    local notificationSystem = NotificationSystem.new(tweenManager, themeManager)

    local guiParent = Executor.gethui and Executor.gethui() or game:GetService("CoreGui")
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "AndepzaiHubPro"
    screenGui.Parent = guiParent
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.IgnoreGuiInset = true
    memoryManager:Track(screenGui)

    notificationSystem:SetScreenGui(screenGui)

    assetManager:DownloadImage(function(success, path)
        if success and path and path ~= "" then
        end
    end)

    local floatBtn = CreateFloatingButton(
        screenGui,
        connManager,
        tweenManager,
        themeManager,
        dragHandler,
        function()
            mainWindow:Toggle()
        end
    )
    memoryManager:Track(floatBtn)

    local mainWindow = CreateMainWindow(
        screenGui,
        connManager,
        tweenManager,
        themeManager,
        assetManager,
        dragHandler,
        notificationSystem
    )
    memoryManager:Track(mainWindow.Frame)

    local selectedTab = nil

    local function onTabSelected(button, setActive)
        if selectedTab and selectedTab ~= button then
            selectedTab(false)
        end
        selectedTab = setActive
    end

    local category1 = AddSidebarCategory(mainWindow.Sidebar, connManager, tweenManager, themeManager, "MAIN")
    memoryManager:Track(category1)

    local tab1, setActive1 = AddSidebarTab(
        mainWindow.Sidebar,
        connManager,
        tweenManager,
        themeManager,
        rippleSystem,
        "🏠",
        "Home",
        function(btn, setActive)
            onTabSelected(btn, setActive)
            notificationSystem:Show("Home", "Welcome to Andepzai Hub Pro!", 2)
        end
    )
    memoryManager:Track(tab1)
    setActive1(true)
    selectedTab = setActive1

    local tab2, setActive2 = AddSidebarTab(
        mainWindow.Sidebar,
        connManager,
        tweenManager,
        themeManager,
        rippleSystem,
        "⚡",
        "Combat",
        function(btn, setActive)
            onTabSelected(btn, setActive)
            notificationSystem:Show("Combat", "Combat features loaded!", 2)
        end
    )
    memoryManager:Track(tab2)

    local tab3, setActive3 = AddSidebarTab(
        mainWindow.Sidebar,
        connManager,
        tweenManager,
        themeManager,
        rippleSystem,
        "👤",
        "Player",
        function(btn, setActive)
            onTabSelected(btn, setActive)
            notificationSystem:Show("Player", "Player settings loaded!", 2)
        end
    )
    memoryManager:Track(tab3)

    local tab4, setActive4 = AddSidebarTab(
        mainWindow.Sidebar,
        connManager,
        tweenManager,
        themeManager,
        rippleSystem,
        "🌀",
        "Teleport",
        function(btn, setActive)
            onTabSelected(btn, setActive)
            notificationSystem:Show("Teleport", "Teleport features loaded!", 2)
        end
    )
    memoryManager:Track(tab4)

    local tab5, setActive5 = AddSidebarTab(
        mainWindow.Sidebar,
        connManager,
        tweenManager,
        themeManager,
        rippleSystem,
        "⚙️",
        "Settings",
        function(btn, setActive)
            onTabSelected(btn, setActive)
            notificationSystem:Show("Settings", "Settings panel loaded!", 2)
        end
    )
    memoryManager:Track(tab5)

    local uiFactory = UIFactory.new(connManager, tweenManager, themeManager, rippleSystem, nil)

    local homeContent = Instance.new("Frame")
    homeContent.Size = UDim2.new(1, 0, 0, 0)
    homeContent.BackgroundTransparency = 1
    homeContent.Parent = mainWindow.ContentArea

    local welcomeLabel = Instance.new("TextLabel")
    welcomeLabel.Size = UDim2.new(1, 0, 0, 40)
    welcomeLabel.BackgroundTransparency = 1
    welcomeLabel.Text = "✦ Welcome to Andepzai Hub Pro"
    welcomeLabel.TextColor3 = themeManager:GetTheme().Text
    welcomeLabel.Font = Enum.Font.GothamBold
    welcomeLabel.TextSize = 20
    welcomeLabel.TextXAlignment = Enum.TextXAlignment.Center
    welcomeLabel.Parent = homeContent

    local descLabel = Instance.new("TextLabel")
    descLabel.Size = UDim2.new(1, 0, 0, 30)
    descLabel.BackgroundTransparency = 1
    descLabel.Text = "Premium UI Framework - Hoàn thiện toàn diện"
    descLabel.TextColor3 = themeManager:GetTheme().TextSecondary
    descLabel.Font = Enum.Font.Gotham
    descLabel.TextSize = 14
    descLabel.TextXAlignment = Enum.TextXAlignment.Center
    descLabel.Parent = homeContent

    uiFactory:CreateButton(
        homeContent,
        "📌 Sample Button",
        UDim2.fromOffset(200, 40),
        UDim2.fromScale(0.5, 0.5),
        function()
            notificationSystem:Show("Button", "You clicked the sample button!", 2, "Success")
        end,
        "Click me!"
    )

    local toggleContainer = uiFactory:CreateToggle(
        homeContent,
        "Sample Toggle",
        false,
        UDim2.fromScale(0.5, 0.8),
        function(value)
            notificationSystem:Show("Toggle", "Toggle is now: " .. tostring(value), 2)
        end
    )
    toggleContainer.Position = UDim2.fromScale(0.5, 0.8)

    local sliderContainer = uiFactory:CreateSlider(
        homeContent,
        "Sample Slider",
        0,
        100,
        50,
        UDim2.fromScale(0.5, 1.0),
        function(value)
        end
    )
    sliderContainer.Position = UDim2.fromScale(0.5, 1.0)

    local function updateCanvas()
        local totalHeight = 0
        for _, child in ipairs(mainWindow.ContentArea:GetChildren()) do
            if child:IsA("Frame") then
                totalHeight = totalHeight + child.Size.Y.Offset + 10
            end
        end
        mainWindow.ContentArea.CanvasSize = UDim2.new(0, 0, 0, totalHeight + 50)
    end
    updateCanvas()

    Executor.task_delay(0.5, function()
        notificationSystem:Show("Andepzai Hub Pro", "Script đã được tải thành công!\nNhấn F1 hoặc nút nổi để mở menu.", 4)
    end)
end

Executor.task_spawn(Main)