local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local StarterGui = game:GetService("StarterGui")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

if not game:IsLoaded() then game.Loaded:Wait() end

local SCRIPT_VERSION = "5.0.0"
local SCRIPT_AUTHOR = "Kenrser"
local SCRIPT_NAME = "Premium Hub Pro"
local NOTIFICATION_DURATION = 3
local INFINITE_JUMP_THROTTLE = 0.1
local MAX_TREE_DISTANCE = 500
local TREE_CACHE_DURATION = 2
local FLY_MAX_FORCE = 1e9
local FLY_MAX_TORQUE = 1e9
local AIMBOT_MAX_DISTANCE = 400
local ESP_DEFAULT_COLOR = Color3.fromRGB(139, 92, 246)
local ESP_ENEMY_COLOR = Color3.fromRGB(255, 70, 70)
local ESP_FRIENDLY_COLOR = Color3.fromRGB(139, 92, 246)
local WALLHACK_TRANSPARENCY = 0.6
local FULLBRIGHT_BRIGHTNESS = 2
local FULLBRIGHT_CLOCK_TIME = 14
local FULLBRIGHT_FOG_END = 100000
local LOW_GRAPHICS_FOG_END = 100
local DEFAULT_FOG_END = 10000
local BACKGROUND_IMAGE_URL = "https://i.postimg.cc/1VqBhycD/background.jpg"

local FeatureState = {
    DISABLED = "Disabled",
    ENABLING = "Enabling",
    ENABLED = "Enabled",
    DISABLING = "Disabling",
    ERROR = "Error",
}

local NotificationType = {
    SUCCESS = "Success",
    WARNING = "Warning",
    ERROR = "Error",
    INFO = "Info",
}

local Logger = {}
Logger.__index = Logger

function Logger.new(moduleName)
    local self = setmetatable({}, Logger)
    self.ModuleName = moduleName or "Unknown"
    return self
end

function Logger:Info(message)
    print(string.format("[%s][INFO] %s", self.ModuleName, tostring(message)))
end

function Logger:Warn(message)
    warn(string.format("[%s][WARN] %s", self.ModuleName, tostring(message)))
end

function Logger:Error(message)
    warn(string.format("[%s][ERROR] %s", self.ModuleName, tostring(message)))
end

function Logger:Debug(message)
    print(string.format("[%s][DEBUG] %s", self.ModuleName, tostring(message)))
end

local MainLogger = Logger.new(SCRIPT_NAME)

local ConnectionManager = {}
ConnectionManager.__index = ConnectionManager

function ConnectionManager.new()
    local self = setmetatable({}, ConnectionManager)
    self._connections = {}
    return self
end

function ConnectionManager:Add(connection)
    if connection and connection.Connected then
        table.insert(self._connections, connection)
        return true
    end
    return false
end

function ConnectionManager:Remove(connection)
    for i, conn in ipairs(self._connections) do
        if conn == connection then
            if conn.Connected then
                conn:Disconnect()
            end
            table.remove(self._connections, i)
            return true
        end
    end
    return false
end

function ConnectionManager:DisconnectAll()
    for i = #self._connections, 1, -1 do
        local conn = self._connections[i]
        if conn and conn.Connected then
            conn:Disconnect()
        end
        table.remove(self._connections, i)
    end
end

function ConnectionManager:GetCount()
    return #self._connections
end

function ConnectionManager:HasActiveConnections()
    for _, conn in ipairs(self._connections) do
        if conn and conn.Connected then
            return true
        end
    end
    return false
end

local ConnManager = ConnectionManager.new()

local EventBus = {}
EventBus.__index = EventBus

function EventBus.new()
    local self = setmetatable({}, EventBus)
    self._listeners = {}
    return self
end

function EventBus:Subscribe(eventName, callback)
    if not self._listeners[eventName] then
        self._listeners[eventName] = {}
    end
    table.insert(self._listeners[eventName], callback)
    return function()
        self:Unsubscribe(eventName, callback)
    end
end

function EventBus:Unsubscribe(eventName, callback)
    if self._listeners[eventName] then
        for i, cb in ipairs(self._listeners[eventName]) do
            if cb == callback then
                table.remove(self._listeners[eventName], i)
                return true
            end
        end
    end
    return false
end

function EventBus:Emit(eventName, ...)
    if self._listeners[eventName] then
        for _, callback in ipairs(self._listeners[eventName]) do
            local success, err = pcall(callback, ...)
            if not success then
                MainLogger:Error(string.format("EventBus error in '%s': %s", eventName, tostring(err)))
            end
        end
    end
end

function EventBus:Clear(eventName)
    if eventName then
        self._listeners[eventName] = nil
    else
        self._listeners = {}
    end
end

local Events = EventBus.new()

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
    ESPConnections = {},
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

local Utility = {}

function Utility.safeCall(func, ...)
    local success, result = pcall(func, ...)
    if not success then
        MainLogger:Error(string.format("safeCall error: %s", tostring(result)))
    end
    return success, result
end

function Utility.getCharacter()
    local character = LocalPlayer.Character
    if not character then
        LocalPlayer.CharacterAdded:Wait()
        character = LocalPlayer.Character
    end
    return character
end

function Utility.getHumanoid()
    local character = Utility.getCharacter()
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then
        humanoid = character:WaitForChild("Humanoid", 10)
    end
    return humanoid
end

function Utility.getRootPart()
    local character = Utility.getCharacter()
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then
        rootPart = character:WaitForChild("HumanoidRootPart", 10)
    end
    return rootPart
end

function Utility.cloneTable(original)
    if type(original) ~= "table" then return original end
    local copy = {}
    for key, value in pairs(original) do
        if type(value) == "table" then
            copy[key] = Utility.cloneTable(value)
        else
            copy[key] = value
        end
    end
    return copy
end

function Utility.deepEqual(table1, table2)
    if type(table1) ~= "table" or type(table2) ~= "table" then
        return table1 == table2
    end
    for key, value in pairs(table1) do
        if not Utility.deepEqual(value, table2[key]) then
            return false
        end
    end
    for key, value in pairs(table2) do
        if not Utility.deepEqual(value, table1[key]) then
            return false
        end
    end
    return true
end

function Utility.tableLength(tbl)
    local count = 0
    for _ in pairs(tbl) do
        count = count + 1
    end
    return count
end

function Utility.tableKeys(tbl)
    local keys = {}
    for key, _ in pairs(tbl) do
        table.insert(keys, key)
    end
    return keys
end

function Utility.tableValues(tbl)
    local values = {}
    for _, value in pairs(tbl) do
        table.insert(values, value)
    end
    return values
end

function Utility.stringStartsWith(str, prefix)
    return string.sub(str, 1, #prefix) == prefix
end

function Utility.stringEndsWith(str, suffix)
    return string.sub(str, -#suffix) == suffix
end

function Utility.stringContains(str, pattern)
    return string.find(str, pattern) ~= nil
end

function Utility.clamp(value, minValue, maxValue)
    return math.max(minValue, math.min(maxValue, value))
end

function Utility.lerp(startValue, endValue, alpha)
    return startValue + (endValue - startValue) * alpha
end

function Utility.round(value, decimals)
    local multiplier = 10 ^ (decimals or 0)
    return math.floor(value * multiplier + 0.5) / multiplier
end

function Utility.formatDistance(distance)
    if distance >= 1000 then
        return string.format("%.2f km", distance / 1000)
    else
        return string.format("%.0f m", distance)
    end
end

function Utility.createInstance(className, properties)
    local instance = Instance.new(className)
    if properties then
        for prop, value in pairs(properties) do
            local success, err = pcall(function()
                instance[prop] = value
            end)
            if not success then
                MainLogger:Warn(string.format("Failed to set property '%s' on %s: %s", prop, className, tostring(err)))
            end
        end
    end
    return instance
end

function Utility.addCorner(instance, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 16)
    corner.Parent = instance
    return corner
end

function Utility.addStroke(instance, color, thickness, transparency)
    local stroke = Instance.new("UIStroke")
    stroke.Color = color or Color3.fromRGB(255, 255, 255)
    stroke.Thickness = thickness or 1
    stroke.Transparency = transparency or 0.85
    stroke.Parent = instance
    return stroke
end

function Utility.addShadow(instance, size, transparency)
    local shadow = Instance.new("ImageLabel")
    shadow.Name = "Shadow"
    shadow.Size = UDim2.new(1, size or 30, 1, size or 30)
    shadow.Position = UDim2.new(0, -(size or 30)/2, 0, -(size or 30)/2)
    shadow.BackgroundTransparency = 1
    shadow.Image = "rbxassetid://6014261993"
    shadow.ImageTransparency = transparency or 0.65
    shadow.ScaleType = Enum.ScaleType.Slice
    shadow.SliceCenter = Rect.new(49, 49, 49, 49)
    shadow.ZIndex = -1
    shadow.Parent = instance
    return shadow
end

function Utility.addGradient(instance, color1, color2, rotation)
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, color1),
        ColorSequenceKeypoint.new(1, color2)
    })
    gradient.Rotation = rotation or 135
    gradient.Parent = instance
    return gradient
end

local NotificationService = {}
NotificationService.__index = NotificationService

function NotificationService.new()
    local self = setmetatable({}, NotificationService)
    self._activeNotifications = {}
    return self
end

function NotificationService:Send(title, content, duration, notificationType)
    duration = duration or NOTIFICATION_DURATION
    notificationType = notificationType or NotificationType.INFO

    local notification = {
        Title = title or "",
        Content = content or "",
        Duration = duration,
        Type = notificationType,
        Timestamp = tick(),
    }

    table.insert(self._activeNotifications, notification)

    Utility.safeCall(function()
        WindUI:Notify({
            Title = notification.Title,
            Content = notification.Content,
            Duration = notification.Duration,
        })
    end)

    task.delay(duration + 0.5, function()
        for i, notif in ipairs(self._activeNotifications) do
            if notif == notification then
                table.remove(self._activeNotifications, i)
                break
            end
        end
    end)

    return notification
end

function NotificationService:SendSuccess(title, content, duration)
    return self:Send(title, content, duration, NotificationType.SUCCESS)
end

function NotificationService:SendWarning(title, content, duration)
    return self:Send(title, content, duration, NotificationType.WARNING)
end

function NotificationService:SendError(title, content, duration)
    return self:Send(title, content, duration, NotificationType.ERROR)
end

function NotificationService:GetActiveCount()
    return #self._activeNotifications
end

function NotificationService:ClearAll()
    self._activeNotifications = {}
end

local Notifier = NotificationService.new()

local Window = WindUI:CreateWindow({
    Title = "PREMIUM HUB PRO",
    Icon = "star",
    Author = "by " .. SCRIPT_AUTHOR,
    Folder = "PremiumHubPro",
    Theme = "Dark",
    Size = UDim2.fromOffset(620, 520),
})

MainLogger:Info("Window created successfully")

local BackgroundManager = {}
BackgroundManager.__index = BackgroundManager

function BackgroundManager.new(mainFrame)
    local self = setmetatable({}, BackgroundManager)
    self.MainFrame = mainFrame
    self.BackgroundImage = nil
    self.DarkOverlay = nil
    self.IsLoaded = false
    return self
end

function BackgroundManager:Apply()
    if not self.MainFrame then
        MainLogger:Warn("BackgroundManager: MainFrame is nil, cannot apply background")
        return false
    end

    if self.IsLoaded then
        MainLogger:Warn("BackgroundManager: Background already applied")
        return false
    end

    local success, err = pcall(function()
        self.BackgroundImage = Instance.new("ImageLabel")
        self.BackgroundImage.Name = "BackgroundImage"
        self.BackgroundImage.Size = UDim2.new(1, 0, 1, 0)
        self.BackgroundImage.Position = UDim2.new(0, 0, 0, 0)
        self.BackgroundImage.BackgroundTransparency = 1
        self.BackgroundImage.Image = BACKGROUND_IMAGE_URL
        self.BackgroundImage.ScaleType = Enum.ScaleType.Crop
        self.BackgroundImage.ZIndex = 0
        self.BackgroundImage.Parent = self.MainFrame

        Utility.addCorner(self.BackgroundImage, 16)

        self.DarkOverlay = Instance.new("Frame")
        self.DarkOverlay.Name = "DarkOverlay"
        self.DarkOverlay.Size = UDim2.new(1, 0, 1, 0)
        self.DarkOverlay.Position = UDim2.new(0, 0, 0, 0)
        self.DarkOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        self.DarkOverlay.BackgroundTransparency = 0.4
        self.DarkOverlay.BorderSizePixel = 0
        self.DarkOverlay.ZIndex = 1
        self.DarkOverlay.Parent = self.MainFrame

        Utility.addCorner(self.DarkOverlay, 16)

        self.IsLoaded = true
    end)

    if not success then
        MainLogger:Error(string.format("BackgroundManager: Failed to apply background: %s", tostring(err)))
        return false
    end

    MainLogger:Info("BackgroundManager: Background applied successfully")
    return true
end

function BackgroundManager:SetTransparency(transparency)
    if self.DarkOverlay then
        self.DarkOverlay.BackgroundTransparency = Utility.clamp(transparency, 0, 1)
        return true
    end
    return false
end

function BackgroundManager:SetImage(url)
    if self.BackgroundImage then
        self.BackgroundImage.Image = url
        return true
    end
    return false
end

function BackgroundManager:Remove()
    if self.BackgroundImage then
        self.BackgroundImage:Destroy()
        self.BackgroundImage = nil
    end
    if self.DarkOverlay then
        self.DarkOverlay:Destroy()
        self.DarkOverlay = nil
    end
    self.IsLoaded = false
    MainLogger:Info("BackgroundManager: Background removed")
    return true
end

function BackgroundManager:IsVisible()
    return self.IsLoaded and self.BackgroundImage and self.BackgroundImage.Parent
end

task.wait(0.1)

local mainFrame = Window.UIElements and Window.UIElements.Main
if not mainFrame then
    local screenGui = CoreGui:FindFirstChild("PremiumHubPro")
    if screenGui then
        local descendants = screenGui:GetDescendants()
        for i = 1, #descendants do
            local child = descendants[i]
            if child:IsA("Frame") and child.Name == "Main" then
                mainFrame = child
                break
            end
        end
    end
end

local BgManager = BackgroundManager.new(mainFrame)
if mainFrame then
    BgManager:Apply()
else
    MainLogger:Warn("Could not find main frame for background application")
end

local UIEffects = {}
UIEffects.__index = UIEffects

function UIEffects.new()
    local self = setmetatable({}, UIEffects)
    self._activeEffects = {}
    return self
end

function UIEffects:AddShimmer(target, speed, transparency)
    speed = speed or 0.02
    transparency = transparency or 0.9

    local shimmer = Instance.new("UIGradient")
    shimmer.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255)),
    })
    shimmer.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, transparency + 0.05),
        NumberSequenceKeypoint.new(0.45, transparency - 0.05),
        NumberSequenceKeypoint.new(0.5, transparency - 0.15),
        NumberSequenceKeypoint.new(0.55, transparency - 0.05),
        NumberSequenceKeypoint.new(1, transparency + 0.05),
    })
    shimmer.Rotation = 60
    shimmer.Offset = Vector2.new(-1, 0)
    shimmer.Parent = target

    local shimmerData = {
        Gradient = shimmer,
        Target = target,
        Active = true,
    }

    table.insert(self._activeEffects, shimmerData)

    task.spawn(function()
        while shimmerData.Active and target and target.Parent do
            local offset = (tick() % 2) / 2
            shimmer.Offset = Vector2.new(-1 + offset * 2, 0)
            task.wait(speed)
        end
        if shimmer and shimmer.Parent then
            shimmer:Destroy()
        end
    end)

    return shimmerData
end

function UIEffects:AddRotatingLogo(target, speed)
    speed = speed or 0.5

    local logo = Instance.new("TextLabel")
    logo.Size = UDim2.new(0, 40, 0, 40)
    logo.Position = UDim2.new(1, -55, 0, 10)
    logo.BackgroundTransparency = 1
    logo.Text = "✦"
    logo.TextColor3 = Color3.fromRGB(139, 92, 246)
    logo.Font = Enum.Font.GothamBold
    logo.TextSize = 28
    logo.ZIndex = 10
    logo.Parent = target

    local logoData = {
        Logo = logo,
        Target = target,
        Active = true,
    }

    table.insert(self._activeEffects, logoData)

    task.spawn(function()
        while logoData.Active and logo and logo.Parent do
            logo.Rotation = (logo.Rotation or 0) + speed
            task.wait(0.02)
        end
        if logo and logo.Parent then
            logo:Destroy()
        end
    end)

    return logoData
end

function UIEffects:StopEffect(effectData)
    if effectData then
        effectData.Active = false
        for i, data in ipairs(self._activeEffects) do
            if data == effectData then
                table.remove(self._activeEffects, i)
                break
            end
        end
    end
end

function UIEffects:StopAll()
    for _, data in ipairs(self._activeEffects) do
        data.Active = false
    end
    self._activeEffects = {}
end

local Effects = UIEffects.new()

if mainFrame then
    local borderFrame = Instance.new("Frame")
    borderFrame.Size = UDim2.new(1, 0, 1, 0)
    borderFrame.BackgroundTransparency = 1
    borderFrame.ZIndex = 3
    borderFrame.Parent = mainFrame

    local borderStroke = Instance.new("UIStroke")
    borderStroke.Color = Color3.fromRGB(139, 92, 246)
    borderStroke.Thickness = 2
    borderStroke.Transparency = 0.7
    borderStroke.Parent = borderFrame

    local glow = Instance.new("UIGradient")
    glow.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(139, 92, 246)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(59, 130, 246)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(139, 92, 246)),
    })
    glow.Rotation = 45
    glow.Parent = borderStroke

    Effects:AddShimmer(borderStroke, 0.02, 0.85)
    Effects:AddRotatingLogo(mainFrame, 0.5)
end

local function Hook(signal, callback)
    local conn = signal:Connect(callback)
    ConnManager:Add(conn)
    return conn
end

local function safeCall(func, ...)
    return Utility.safeCall(func, ...)
end

local function Notify(title, content, duration)
    Notifier:Send(title, content, duration, NotificationType.INFO)
end

local function NotifySuccess(title, content, duration)
    Notifier:SendSuccess(title, content, duration)
end

local function NotifyWarning(title, content, duration)
    Notifier:SendWarning(title, content, duration)
end

local function NotifyError(title, content, duration)
    Notifier:SendError(title, content, duration)
end

local function getChar()
    return Utility.getCharacter()
end

local function getHum()
    return Utility.getHumanoid()
end

local function getRoot()
    return Utility.getRootPart()
end

local CharacterManager = {}
CharacterManager.__index = CharacterManager

function CharacterManager.new()
    local self = setmetatable({}, CharacterManager)
    self._characterAddedCallbacks = {}
    self._characterRemovingCallbacks = {}
    self._currentCharacter = LocalPlayer.Character

    Hook(LocalPlayer.CharacterAdded, function(character)
        self._currentCharacter = character
        for _, callback in ipairs(self._characterAddedCallbacks) do
            safeCall(callback, character)
        end
    end)

    Hook(LocalPlayer.CharacterRemoving, function(character)
        for _, callback in ipairs(self._characterRemovingCallbacks) do
            safeCall(callback, character)
        end
        self._currentCharacter = nil
    end)

    return self
end

function CharacterManager:OnCharacterAdded(callback)
    table.insert(self._characterAddedCallbacks, callback)
    if self._currentCharacter then
        safeCall(callback, self._currentCharacter)
    end
    return #self._characterAddedCallbacks
end

function CharacterManager:OnCharacterRemoving(callback)
    table.insert(self._characterRemovingCallbacks, callback)
    return #self._characterRemovingCallbacks
end

function CharacterManager:GetCurrentCharacter()
    return self._currentCharacter
end

function CharacterManager:GetHumanoid()
    if self._currentCharacter then
        return self._currentCharacter:FindFirstChildOfClass("Humanoid")
    end
    return nil
end

function CharacterManager:GetRootPart()
    if self._currentCharacter then
        return self._currentCharacter:FindFirstChild("HumanoidRootPart")
    end
    return nil
end

function CharacterManager:IsAlive()
    local humanoid = self:GetHumanoid()
    return humanoid ~= nil and humanoid.Health > 0
end

function CharacterManager:GetHealth()
    local humanoid = self:GetHumanoid()
    if humanoid then
        return humanoid.Health, humanoid.MaxHealth
    end
    return 0, 100
end

function CharacterManager:SetWalkSpeed(speed)
    local humanoid = self:GetHumanoid()
    if humanoid then
        humanoid.WalkSpeed = speed
        return true
    end
    return false
end

function CharacterManager:SetJumpPower(power)
    local humanoid = self:GetHumanoid()
    if humanoid then
        humanoid.JumpPower = power
        return true
    end
    return false
end

function CharacterManager:BreakJoints()
    if self._currentCharacter then
        self._currentCharacter:BreakJoints()
        return true
    end
    return false
end

local CharManager = CharacterManager.new()

local PlayerManager = {}
PlayerManager.__index = PlayerManager

function PlayerManager.new()
    local self = setmetatable({}, PlayerManager)
    self._playerAddedCallbacks = {}
    self._playerRemovingCallbacks = {}
    self._allPlayers = {}

    local function refreshPlayers()
        self._allPlayers = Players:GetPlayers()
    end

    refreshPlayers()

    Hook(Players.PlayerAdded, function(player)
        refreshPlayers()
        for _, callback in ipairs(self._playerAddedCallbacks) do
            safeCall(callback, player)
        end
    end)

    Hook(Players.PlayerRemoving, function(player)
        for _, callback in ipairs(self._playerRemovingCallbacks) do
            safeCall(callback, player)
        end
        refreshPlayers()
    end)

    return self
end

function PlayerManager:GetAllPlayers()
    return Players:GetPlayers()
end

function PlayerManager:GetAlivePlayers()
    local alive = {}
    for _, player in ipairs(self:GetAllPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
            if humanoid and humanoid.Health > 0 then
                table.insert(alive, player)
            end
        end
    end
    return alive
end

function PlayerManager:GetNearestPlayer(maxDistance)
    maxDistance = maxDistance or math.huge
    local rootPart = CharManager:GetRootPart()
    if not rootPart then return nil end

    local nearest = nil
    local minDist = maxDistance

    for _, player in ipairs(self:GetAllPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local targetRoot = player.Character:FindFirstChild("HumanoidRootPart")
            if targetRoot and targetRoot:IsDescendantOf(workspace) then
                local dist = (rootPart.Position - targetRoot.Position).Magnitude
                if dist < minDist then
                    minDist = dist
                    nearest = player
                end
            end
        end
    end

    return nearest, minDist
end

function PlayerManager:GetPlayerCount()
    return #Players:GetPlayers()
end

function PlayerManager:OnPlayerAdded(callback)
    table.insert(self._playerAddedCallbacks, callback)
    return #self._playerAddedCallbacks
end

function PlayerManager:OnPlayerRemoving(callback)
    table.insert(self._playerRemovingCallbacks, callback)
    return #self._playerRemovingCallbacks
end

local PlyManager = PlayerManager.new()

local FlyEngine = {}
FlyEngine.__index = FlyEngine

function FlyEngine.new()
    local self = setmetatable({}, FlyEngine)
    self.Enabled = false
    self.Speed = 50
    self.BodyVelocity = nil
    self.BodyGyro = nil
    self.RenderConnection = nil
    self.KeysDown = {}
    self.InputBeganConnection = nil
    self.InputEndedConnection = nil
    self.State = FeatureState.DISABLED
    return self
end

function FlyEngine:Enable()
    if self.Enabled then return false end
    if self.State == FeatureState.ENABLING then return false end

    self.State = FeatureState.ENABLING
    MainLogger:Info("FlyEngine: Enabling...")

    local character = getChar()
    local humanoid = getHum()
    local rootPart = getRoot()

    if not character or not humanoid or not rootPart then
        self.State = FeatureState.ERROR
        MainLogger:Error("FlyEngine: Failed to get character components")
        return false
    end

    humanoid.PlatformStand = true

    local bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.Name = "FlyVelocity"
    bodyVelocity.Velocity = Vector3.zero
    bodyVelocity.MaxForce = Vector3.new(FLY_MAX_FORCE, FLY_MAX_FORCE, FLY_MAX_FORCE)
    bodyVelocity.Parent = rootPart
    self.BodyVelocity = bodyVelocity

    local bodyGyro = Instance.new("BodyGyro")
    bodyGyro.Name = "FlyGyro"
    bodyGyro.MaxTorque = Vector3.new(FLY_MAX_TORQUE, FLY_MAX_TORQUE, FLY_MAX_TORQUE)
    bodyGyro.CFrame = Camera.CFrame
    bodyGyro.Parent = rootPart
    self.BodyGyro = bodyGyro

    self.KeysDown = {}

    self.InputBeganConnection = Hook(UserInputService.InputBegan, function(input, gameProcessedEvent)
        if not gameProcessedEvent and self.Enabled then
            self.KeysDown[input.KeyCode] = true
        end
    end)

    self.InputEndedConnection = Hook(UserInputService.InputEnded, function(input)
        self.KeysDown[input.KeyCode] = false
    end)

    self.RenderConnection = Hook(RunService.RenderStepped, function()
        if not self.Enabled then return end

        if not self.BodyVelocity or not self.BodyVelocity.Parent then
            self:Disable()
            return
        end

        local direction = Vector3.zero
        local cameraLook = Camera.CFrame.LookVector
        local cameraRight = Camera.CFrame.RightVector

        if self.KeysDown[Enum.KeyCode.W] then
            direction = direction + Vector3.new(cameraLook.X, 0, cameraLook.Z).Unit
        end
        if self.KeysDown[Enum.KeyCode.S] then
            direction = direction - Vector3.new(cameraLook.X, 0, cameraLook.Z).Unit
        end
        if self.KeysDown[Enum.KeyCode.A] then
            direction = direction - Vector3.new(cameraRight.X, 0, cameraRight.Z).Unit
        end
        if self.KeysDown[Enum.KeyCode.D] then
            direction = direction + Vector3.new(cameraRight.X, 0, cameraRight.Z).Unit
        end
        if self.KeysDown[Enum.KeyCode.Space] then
            direction = direction + Vector3.new(0, 1, 0)
        end
        if self.KeysDown[Enum.KeyCode.LeftShift] then
            direction = direction - Vector3.new(0, 1, 0)
        end

        if direction.Magnitude > 0 then
            direction = direction.Unit * self.Speed
        end

        self.BodyVelocity.Velocity = direction
        self.BodyGyro.CFrame = Camera.CFrame

        if humanoid and humanoid.PlatformStand ~= true then
            humanoid.PlatformStand = true
        end
    end)

    self.Enabled = true
    self.State = FeatureState.ENABLED
    MainLogger:Info("FlyEngine: Enabled successfully")
    Events:Emit("FlyStateChanged", true)
    return true
end

function FlyEngine:Disable()
    if not self.Enabled then return false end
    if self.State == FeatureState.DISABLING then return false end

    self.State = FeatureState.DISABLING
    MainLogger:Info("FlyEngine: Disabling...")

    self.Enabled = false

    safeCall(function()
        if self.BodyVelocity then
            self.BodyVelocity:Destroy()
            self.BodyVelocity = nil
        end

        if self.BodyGyro then
            self.BodyGyro:Destroy()
            self.BodyGyro = nil
        end

        if self.RenderConnection then
            self.RenderConnection:Disconnect()
            self.RenderConnection = nil
        end

        if self.InputBeganConnection then
            self.InputBeganConnection:Disconnect()
            self.InputBeganConnection = nil
        end

        if self.InputEndedConnection then
            self.InputEndedConnection:Disconnect()
            self.InputEndedConnection = nil
        end

        local character = LocalPlayer.Character
        if character then
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid.PlatformStand = false
            end
        end
    end)

    self.KeysDown = {}
    self.State = FeatureState.DISABLED
    MainLogger:Info("FlyEngine: Disabled successfully")
    Events:Emit("FlyStateChanged", false)
    return true
end

function FlyEngine:Toggle()
    if self.Enabled then
        return self:Disable()
    else
        return self:Enable()
    end
end

function FlyEngine:SetSpeed(speed)
    self.Speed = Utility.clamp(speed, 20, 300)
    Events:Emit("FlySpeedChanged", self.Speed)
end

function FlyEngine:GetSpeed()
    return self.Speed
end

function FlyEngine:IsEnabled()
    return self.Enabled
end

function FlyEngine:GetState()
    return self.State
end

function FlyEngine:Cleanup()
    if self.Enabled then
        self:Disable()
    end
    self.BodyVelocity = nil
    self.BodyGyro = nil
    self.RenderConnection = nil
    self.InputBeganConnection = nil
    self.InputEndedConnection = nil
    self.KeysDown = {}
end

local FlyController = FlyEngine.new()

local function EnableFly()
    if FlyController:Enable() then
        NotifySuccess("Fly", "Đã bật bay!", 2)
        Settings.FlyEnabled = true
        Settings.FlyBV = FlyController.BodyVelocity
        Settings.FlyBG = FlyController.BodyGyro
        Settings.FlyConn = FlyController.RenderConnection
    end
end

local function DisableFly()
    if FlyController:Disable() then
        Notify("Fly", "Đã tắt bay!", 2)
        Settings.FlyEnabled = false
        Settings.FlyBV = nil
        Settings.FlyBG = nil
        Settings.FlyConn = nil
    end
end

local function ToggleFly()
    if Settings.FlyEnabled then
        DisableFly()
    else
        EnableFly()
    end
end

Events:Subscribe("FlyStateChanged", function(enabled)
    Settings.FlyEnabled = enabled
end)

Events:Subscribe("FlySpeedChanged", function(speed)
    Settings.FlySpeed = speed
end)

local NoClipEngine = {}
NoClipEngine.__index = NoClipEngine

function NoClipEngine.new()
    local self = setmetatable({}, NoClipEngine)
    self.Enabled = false
    self.SteppedConnection = nil
    self.State = FeatureState.DISABLED
    return self
end

function NoClipEngine:Enable()
    if self.Enabled then return false end
    if self.State == FeatureState.ENABLING then return false end

    self.State = FeatureState.ENABLING
    MainLogger:Info("NoClipEngine: Enabling...")

    self.SteppedConnection = Hook(RunService.Stepped, function()
        if not self.Enabled then return end

        safeCall(function()
            local character = LocalPlayer.Character
            if not character then return end

            local descendants = character:GetDescendants()
            for i = 1, #descendants do
                local part = descendants[i]
                if part:IsA("BasePart") and part.CanCollide then
                    if not FlyController:IsEnabled() then
                        part.CanCollide = false
                    end
                end
            end
        end)
    end)

    self.Enabled = true
    self.State = FeatureState.ENABLED
    MainLogger:Info("NoClipEngine: Enabled successfully")
    Events:Emit("NoClipStateChanged", true)
    return true
end

function NoClipEngine:Disable()
    if not self.Enabled then return false end
    if self.State == FeatureState.DISABLING then return false end

    self.State = FeatureState.DISABLING
    MainLogger:Info("NoClipEngine: Disabling...")

    self.Enabled = false

    safeCall(function()
        if self.SteppedConnection then
            self.SteppedConnection:Disconnect()
            self.SteppedConnection = nil
        end

        local character = LocalPlayer.Character
        if character then
            local descendants = character:GetDescendants()
            for i = 1, #descendants do
                local part = descendants[i]
                if part:IsA("BasePart") then
                    part.CanCollide = true
                end
            end
        end
    end)

    self.State = FeatureState.DISABLED
    MainLogger:Info("NoClipEngine: Disabled successfully")
    Events:Emit("NoClipStateChanged", false)
    return true
end

function NoClipEngine:Toggle()
    if self.Enabled then
        return self:Disable()
    else
        return self:Enable()
    end
end

function NoClipEngine:IsEnabled()
    return self.Enabled
end

function NoClipEngine:GetState()
    return self.State
end

function NoClipEngine:Cleanup()
    if self.Enabled then
        self:Disable()
    end
    self.SteppedConnection = nil
end

local NoClipController = NoClipEngine.new()

local function EnableNoClip()
    if NoClipController:Enable() then
        NotifySuccess("NoClip", "Đã bật NoClip", 2)
        Settings.NoClipEnabled = true
        Settings.NoClipConn = NoClipController.SteppedConnection
    end
end

local function DisableNoClip()
    if NoClipController:Disable() then
        Notify("NoClip", "Đã tắt NoClip", 2)
        Settings.NoClipEnabled = false
        Settings.NoClipConn = nil
    end
end

Events:Subscribe("NoClipStateChanged", function(enabled)
    Settings.NoClipEnabled = enabled
end)

local InfiniteJumpEngine = {}
InfiniteJumpEngine.__index = InfiniteJumpEngine

function InfiniteJumpEngine.new()
    local self = setmetatable({}, InfiniteJumpEngine)
    self.Enabled = false
    self.JumpConnection = nil
    self.LastJumpTime = 0
    self.Throttle = INFINITE_JUMP_THROTTLE
    self.State = FeatureState.DISABLED
    self.JumpCount = 0
    return self
end

function InfiniteJumpEngine:Enable()
    if self.Enabled then return false end
    if self.State == FeatureState.ENABLING then return false end

    self.State = FeatureState.ENABLING
    MainLogger:Info("InfiniteJumpEngine: Enabling...")

    self.LastJumpTime = 0
    self.JumpCount = 0

    self.JumpConnection = Hook(UserInputService.JumpRequest, function()
        if not self.Enabled then return end

        local currentTime = tick()
        if currentTime - self.LastJumpTime < self.Throttle then
            return
        end

        self.LastJumpTime = currentTime
        self.JumpCount = self.JumpCount + 1

        safeCall(function()
            local character = LocalPlayer.Character
            if not character then return end

            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if not humanoid then return end

            humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end)
    end)

    self.Enabled = true
    self.State = FeatureState.ENABLED
    MainLogger:Info("InfiniteJumpEngine: Enabled successfully")
    Events:Emit("InfiniteJumpStateChanged", true)
    return true
end

function InfiniteJumpEngine:Disable()
    if not self.Enabled then return false end
    if self.State == FeatureState.DISABLING then return false end

    self.State = FeatureState.DISABLING
    MainLogger:Info("InfiniteJumpEngine: Disabling...")

    self.Enabled = false

    safeCall(function()
        if self.JumpConnection then
            self.JumpConnection:Disconnect()
            self.JumpConnection = nil
        end
    end)

    self.State = FeatureState.DISABLED
    MainLogger:Info("InfiniteJumpEngine: Disabled successfully")
    Events:Emit("InfiniteJumpStateChanged", false)
    return true
end

function InfiniteJumpEngine:Toggle()
    if self.Enabled then
        return self:Disable()
    else
        return self:Enable()
    end
end

function InfiniteJumpEngine:IsEnabled()
    return self.Enabled
end

function InfiniteJumpEngine:GetState()
    return self.State
end

function InfiniteJumpEngine:GetJumpCount()
    return self.JumpCount
end

function InfiniteJumpEngine:SetThrottle(throttle)
    self.Throttle = Utility.clamp(throttle, 0.05, 0.5)
end

function InfiniteJumpEngine:GetThrottle()
    return self.Throttle
end

function InfiniteJumpEngine:Cleanup()
    if self.Enabled then
        self:Disable()
    end
    self.JumpConnection = nil
    self.LastJumpTime = 0
    self.JumpCount = 0
end

local InfiniteJumpController = InfiniteJumpEngine.new()

local function EnableInfiniteJump()
    if InfiniteJumpController:Enable() then
        NotifySuccess("Nhảy vô hạn", "Đã bật", 2)
        Settings.InfiniteJump = true
        Settings.InfJumpConn = InfiniteJumpController.JumpConnection
    end
end

local function DisableInfiniteJump()
    if InfiniteJumpController:Disable() then
        Notify("Nhảy vô hạn", "Đã tắt", 2)
        Settings.InfiniteJump = false
        Settings.InfJumpConn = nil
    end
end

Events:Subscribe("InfiniteJumpStateChanged", function(enabled)
    Settings.InfiniteJump = enabled
end)

local AntiKnockbackEngine = {}
AntiKnockbackEngine.__index = AntiKnockbackEngine

function AntiKnockbackEngine.new()
    local self = setmetatable({}, AntiKnockbackEngine)
    self.Enabled = false
    self.RenderConnection = nil
    self.State = FeatureState.DISABLED
    self.BodiesRemoved = 0
    return self
end

function AntiKnockbackEngine:Enable()
    if self.Enabled then return false end
    if self.State == FeatureState.ENABLING then return false end

    self.State = FeatureState.ENABLING
    MainLogger:Info("AntiKnockbackEngine: Enabling...")

    self.BodiesRemoved = 0

    self.RenderConnection = Hook(RunService.RenderStepped, function()
        if not self.Enabled then return end

        safeCall(function()
            local character = LocalPlayer.Character
            if not character then return end

            local descendants = character:GetDescendants()
            for i = 1, #descendants do
                local instance = descendants[i]

                if instance:IsA("BodyVelocity") and instance ~= FlyController.BodyVelocity then
                    instance:Destroy()
                    self.BodiesRemoved = self.BodiesRemoved + 1
                end

                if instance:IsA("BodyPosition") then
                    instance:Destroy()
                    self.BodiesRemoved = self.BodiesRemoved + 1
                end
            end
        end)
    end)

    self.Enabled = true
    self.State = FeatureState.ENABLED
    MainLogger:Info("AntiKnockbackEngine: Enabled successfully")
    Events:Emit("AntiKBStateChanged", true)
    return true
end

function AntiKnockbackEngine:Disable()
    if not self.Enabled then return false end
    if self.State == FeatureState.DISABLING then return false end

    self.State = FeatureState.DISABLING
    MainLogger:Info("AntiKnockbackEngine: Disabling...")

    self.Enabled = false

    safeCall(function()
        if self.RenderConnection then
            self.RenderConnection:Disconnect()
            self.RenderConnection = nil
        end
    end)

    self.State = FeatureState.DISABLED
    MainLogger:Info("AntiKnockbackEngine: Disabled successfully")
    Events:Emit("AntiKBStateChanged", false)
    return true
end

function AntiKnockbackEngine:Toggle()
    if self.Enabled then
        return self:Disable()
    else
        return self:Enable()
    end
end

function AntiKnockbackEngine:IsEnabled()
    return self.Enabled
end

function AntiKnockbackEngine:GetState()
    return self.State
end

function AntiKnockbackEngine:GetBodiesRemoved()
    return self.BodiesRemoved
end

function AntiKnockbackEngine:Cleanup()
    if self.Enabled then
        self:Disable()
    end
    self.RenderConnection = nil
    self.BodiesRemoved = 0
end

local AntiKBController = AntiKnockbackEngine.new()

local function EnableAntiKB()
    if AntiKBController:Enable() then
        NotifySuccess("Anti KB", "Đã bật chống đẩy lùi", 2)
        Settings.AntiKnockback = true
        Settings.AntiKBConn = AntiKBController.RenderConnection
    end
end

local function DisableAntiKB()
    if AntiKBController:Disable() then
        Notify("Anti KB", "Đã tắt chống đẩy lùi", 2)
        Settings.AntiKnockback = false
        Settings.AntiKBConn = nil
    end
end

Events:Subscribe("AntiKBStateChanged", function(enabled)
    Settings.AntiKnockback = enabled
end)

local AimbotEngine = {}
AimbotEngine.__index = AimbotEngine

function AimbotEngine.new()
    local self = setmetatable({}, AimbotEngine)
    self.Enabled = false
    self.Smoothness = 0.5
    self.RenderConnection = nil
    self.State = FeatureState.DISABLED
    self.CurrentTarget = nil
    self.TargetsAcquired = 0
    return self
end

function AimbotEngine:Enable()
    if self.Enabled then return false end
    if self.State == FeatureState.ENABLING then return false end

    self.State = FeatureState.ENABLING
    MainLogger:Info("AimbotEngine: Enabling...")

    self.TargetsAcquired = 0
    self.CurrentTarget = nil

    self.RenderConnection = Hook(RunService.RenderStepped, function()
        if not self.Enabled then return end

        safeCall(function()
            local character = LocalPlayer.Character
            if not character then return end

            local rootPart = character:FindFirstChild("HumanoidRootPart")
            if not rootPart then return end

            local mouseLocation = UserInputService:GetMouseLocation()
            local nearestTarget = nil
            local minimumDistance = math.huge
            local allPlayers = Players:GetPlayers()

            for i = 1, #allPlayers do
                local targetPlayer = allPlayers[i]
                if targetPlayer ~= LocalPlayer and targetPlayer.Character then
                    local targetRoot = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
                    local targetHumanoid = targetPlayer.Character:FindFirstChildOfClass("Humanoid")

                    if targetRoot and targetHumanoid and targetHumanoid.Health > 0 then
                        local screenPosition, onScreen = Camera:WorldToViewportPoint(targetRoot.Position)

                        if onScreen then
                            local screenVector = Vector2.new(screenPosition.X, screenPosition.Y)
                            local distanceFromMouse = (screenVector - mouseLocation).Magnitude

                            if distanceFromMouse < minimumDistance and distanceFromMouse < AIMBOT_MAX_DISTANCE then
                                minimumDistance = distanceFromMouse
                                nearestTarget = targetRoot
                            end
                        end
                    end
                end
            end

            if nearestTarget then
                self.CurrentTarget = nearestTarget
                self.TargetsAcquired = self.TargetsAcquired + 1
                Camera.CFrame = CFrame.lookAt(Camera.CFrame.Position, nearestTarget.Position)
            else
                self.CurrentTarget = nil
            end
        end)
    end)

    self.Enabled = true
    self.State = FeatureState.ENABLED
    MainLogger:Info("AimbotEngine: Enabled successfully")
    Events:Emit("AimbotStateChanged", true)
    return true
end

function AimbotEngine:Disable()
    if not self.Enabled then return false end
    if self.State == FeatureState.DISABLING then return false end

    self.State = FeatureState.DISABLING
    MainLogger:Info("AimbotEngine: Disabling...")

    self.Enabled = false
    self.CurrentTarget = nil

    safeCall(function()
        if self.RenderConnection then
            self.RenderConnection:Disconnect()
            self.RenderConnection = nil
        end
    end)

    self.State = FeatureState.DISABLED
    MainLogger:Info("AimbotEngine: Disabled successfully")
    Events:Emit("AimbotStateChanged", false)
    return true
end

function AimbotEngine:Toggle()
    if self.Enabled then
        return self:Disable()
    else
        return self:Enable()
    end
end

function AimbotEngine:IsEnabled()
    return self.Enabled
end

function AimbotEngine:GetState()
    return self.State
end

function AimbotEngine:SetSmoothness(smoothness)
    self.Smoothness = Utility.clamp(smoothness, 0.1, 1.0)
    Events:Emit("AimbotSmoothnessChanged", self.Smoothness)
end

function AimbotEngine:GetSmoothness()
    return self.Smoothness
end

function AimbotEngine:GetCurrentTarget()
    return self.CurrentTarget
end

function AimbotEngine:GetTargetsAcquired()
    return self.TargetsAcquired
end

function AimbotEngine:Cleanup()
    if self.Enabled then
        self:Disable()
    end
    self.RenderConnection = nil
    self.CurrentTarget = nil
    self.TargetsAcquired = 0
end

local AimbotController = AimbotEngine.new()

local function EnableAimbot()
    if AimbotController:Enable() then
        NotifySuccess("Aimbot", "Đã bật", 2)
        Settings.AimbotEnabled = true
        Settings.AimbotConn = AimbotController.RenderConnection
    end
end

local function DisableAimbot()
    if AimbotController:Disable() then
        Notify("Aimbot", "Đã tắt", 2)
        Settings.AimbotEnabled = false
        Settings.AimbotConn = nil
    end
end

Events:Subscribe("AimbotStateChanged", function(enabled)
    Settings.AimbotEnabled = enabled
end)

Events:Subscribe("AimbotSmoothnessChanged", function(smoothness)
    Settings.AimbotSmoothness = smoothness
end)

local ESPEngine = {}
ESPEngine.__index = ESPEngine

function ESPEngine.new()
    local self = setmetatable({}, ESPEngine)
    self.Enabled = false
    self.Gui = nil
    self.Boxes = {}
    self.State = FeatureState.DISABLED
    self.HighlightEnabled = true
    self.TracerEnabled = true
    self.PlayerConnections = {}
    return self
end

function ESPEngine:Enable()
    if self.Enabled then return false end
    if self.State == FeatureState.ENABLING then return false end

    self.State = FeatureState.ENABLING
    MainLogger:Info("ESPEngine: Enabling...")

    if self.Gui then
        self.Gui:Destroy()
    end

    local espGui = Instance.new("ScreenGui")
    espGui.Name = "ESPGui"
    espGui.Parent = CoreGui
    espGui.DisplayOrder = 999
    espGui.ResetOnSpawn = false
    self.Gui = espGui

    self.Boxes = {}
    self.PlayerConnections = {}

    local function createESP(targetPlayer)
        if targetPlayer == LocalPlayer then return end

        local function setupESP()
            local character = targetPlayer.Character
            if not character then return end

            local rootPart = character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Head")
            if not rootPart then return end

            if self.Boxes[targetPlayer] then
                local oldData = self.Boxes[targetPlayer]
                for _, obj in ipairs(oldData) do
                    if obj and obj.Destroy and typeof(obj) ~= "RBXScriptConnection" then
                        safeCall(function() obj:Destroy() end)
                    end
                end
            end

            local tracer = Instance.new("Frame")
            tracer.BackgroundColor3 = ESP_DEFAULT_COLOR
            tracer.BackgroundTransparency = 0.7
            tracer.BorderSizePixel = 0
            tracer.Visible = false
            tracer.Parent = espGui

            local box = Instance.new("Frame")
            box.BackgroundColor3 = ESP_DEFAULT_COLOR
            box.BackgroundTransparency = 0.6
            box.BorderSizePixel = 0
            box.Visible = false
            box.Parent = espGui
            Utility.addCorner(box, 3)

            local boxStroke = Instance.new("UIStroke")
            boxStroke.Color = ESP_DEFAULT_COLOR
            boxStroke.Thickness = 1.5
            boxStroke.Transparency = 0.3
            boxStroke.Parent = box

            local nameLabel = Instance.new("TextLabel")
            nameLabel.BackgroundTransparency = 1
            nameLabel.Text = targetPlayer.Name
            nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            nameLabel.Font = Enum.Font.GothamBold
            nameLabel.TextSize = 11
            nameLabel.TextStrokeTransparency = 0.3
            nameLabel.Visible = false
            nameLabel.Parent = espGui

            local healthBackground = Instance.new("Frame")
            healthBackground.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
            healthBackground.BackgroundTransparency = 0.3
            healthBackground.BorderSizePixel = 0
            healthBackground.Visible = false
            healthBackground.Parent = espGui
            Utility.addCorner(healthBackground, 2)

            local healthFill = Instance.new("Frame")
            healthFill.BackgroundColor3 = Color3.fromRGB(50, 200, 100)
            healthFill.BorderSizePixel = 0
            healthFill.Parent = healthBackground
            Utility.addCorner(healthFill, 2)

            local distanceLabel = Instance.new("TextLabel")
            distanceLabel.BackgroundTransparency = 1
            distanceLabel.TextColor3 = Color3.fromRGB(160, 160, 170)
            distanceLabel.Font = Enum.Font.Gotham
            distanceLabel.TextSize = 9
            distanceLabel.Visible = false
            distanceLabel.Parent = espGui

            local highlight = Instance.new("Highlight")
            highlight.FillColor = ESP_DEFAULT_COLOR
            highlight.FillTransparency = 0.7
            highlight.OutlineColor = ESP_DEFAULT_COLOR
            highlight.OutlineTransparency = 0.3
            highlight.Enabled = self.HighlightEnabled
            highlight.Parent = character

            local renderConnection = Hook(RunService.RenderStepped, function()
                if not self.Enabled then
                    box.Visible = false
                    nameLabel.Visible = false
                    healthBackground.Visible = false
                    distanceLabel.Visible = false
                    tracer.Visible = false
                    if highlight then highlight.Enabled = false end
                    return
                end

                local currentCharacter = targetPlayer.Character
                if not currentCharacter then
                    box.Visible = false
                    nameLabel.Visible = false
                    healthBackground.Visible = false
                    distanceLabel.Visible = false
                    tracer.Visible = false
                    return
                end

                local currentRoot = currentCharacter:FindFirstChild("HumanoidRootPart") or currentCharacter:FindFirstChild("Head")
                if not currentRoot or not currentRoot:IsDescendantOf(workspace) then
                    box.Visible = false
                    nameLabel.Visible = false
                    healthBackground.Visible = false
                    distanceLabel.Visible = false
                    tracer.Visible = false
                    return
                end

                if highlight then
                    highlight.Parent = currentCharacter
                    highlight.Enabled = self.HighlightEnabled
                end

                local screenPosition, onScreen = Camera:WorldToViewportPoint(currentRoot.Position)
                if not onScreen then
                    box.Visible = false
                    nameLabel.Visible = false
                    healthBackground.Visible = false
                    distanceLabel.Visible = false
                    tracer.Visible = false
                    return
                end

                local humanoid = currentCharacter:FindFirstChildOfClass("Humanoid")
                local depth = math.max(0.1, (Camera.CFrame.Position - currentRoot.Position).Magnitude)
                local scale = math.clamp(200 / depth, 1.5, 4)
                local modelSize = currentCharacter:GetExtentsSize()
                local boxWidth = math.clamp(modelSize.X * scale, 30, 120)
                local boxHeight = math.clamp(modelSize.Y * scale, 50, 180)

                if self.TracerEnabled then
                    local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                    tracer.Visible = true
                    local deltaX = screenPosition.X - screenCenter.X
                    local deltaY = screenCenter.Y - screenPosition.Y
                    local traceLength = math.sqrt(deltaX * deltaX + deltaY * deltaY)
                    tracer.Size = UDim2.new(0, 1, 0, traceLength)
                    tracer.Position = UDim2.new(0, screenPosition.X, 0, screenPosition.Y)
                    tracer.Rotation = math.deg(math.atan2(deltaY, deltaX)) - 90
                else
                    tracer.Visible = false
                end

                box.Visible = true
                box.Size = UDim2.new(0, boxWidth, 0, boxHeight)
                box.Position = UDim2.new(0, screenPosition.X - boxWidth / 2, 0, screenPosition.Y - boxHeight / 2)

                nameLabel.Visible = true
                nameLabel.Size = UDim2.new(0, 120, 0, 16)
                nameLabel.Position = UDim2.new(0, screenPosition.X - 60, 0, screenPosition.Y - boxHeight / 2 - 20)

                if humanoid then
                    local healthPercent = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
                    healthFill.Size = UDim2.new(healthPercent, 0, 1, 0)

                    if healthPercent > 0.6 then
                        healthFill.BackgroundColor3 = Color3.fromRGB(50, 200, 100)
                    elseif healthPercent > 0.3 then
                        healthFill.BackgroundColor3 = Color3.fromRGB(255, 180, 50)
                    else
                        healthFill.BackgroundColor3 = Color3.fromRGB(255, 70, 70)
                    end
                end

                healthBackground.Visible = true
                healthBackground.Size = UDim2.new(0, boxWidth, 0, 4)
                healthBackground.Position = UDim2.new(0, screenPosition.X - boxWidth / 2, 0, screenPosition.Y + boxHeight / 2 + 6)

                local localCharacter = LocalPlayer.Character
                if localCharacter then
                    local localRoot = localCharacter:FindFirstChild("HumanoidRootPart")
                    if localRoot then
                        distanceLabel.Visible = true
                        distanceLabel.Size = UDim2.new(0, 60, 0, 14)
                        distanceLabel.Position = UDim2.new(0, screenPosition.X - 30, 0, screenPosition.Y + boxHeight / 2 + 14)
                        distanceLabel.Text = Utility.formatDistance((localRoot.Position - currentRoot.Position).Magnitude)
                    end
                end

                local isEnemy = targetPlayer.Team and LocalPlayer.Team and targetPlayer.Team ~= LocalPlayer.Team
                local espColor = isEnemy and ESP_ENEMY_COLOR or ESP_FRIENDLY_COLOR
                box.BackgroundColor3 = espColor
                boxStroke.Color = espColor
                tracer.BackgroundColor3 = espColor
            end)

            self.Boxes[targetPlayer] = {box, nameLabel, healthBackground, distanceLabel, renderConnection, tracer, highlight}
            table.insert(self.PlayerConnections, renderConnection)
        end

        if targetPlayer.Character then setupESP() end

        local charAddedConn = Hook(targetPlayer.CharacterAdded, function()
            task.wait(0.3)
            if self.Enabled then setupESP() end
        end)
        table.insert(self.PlayerConnections, charAddedConn)
    end

    local allPlayers = Players:GetPlayers()
    for i = 1, #allPlayers do
        createESP(allPlayers[i])
    end

    local playerAddedConn = Hook(Players.PlayerAdded, function(player)
        if self.Enabled then createESP(player) end
    end)
    table.insert(self.PlayerConnections, playerAddedConn)

    local playerRemovingConn = Hook(Players.PlayerRemoving, function(player)
        if self.Boxes[player] then
            local espData = self.Boxes[player]
            for _, obj in ipairs(espData) do
                if obj and obj.Destroy and typeof(obj) ~= "RBXScriptConnection" then
                    safeCall(function() obj:Destroy() end)
                end
            end
            self.Boxes[player] = nil
        end
    end)
    table.insert(self.PlayerConnections, playerRemovingConn)

    self.Enabled = true
    self.State = FeatureState.ENABLED
    MainLogger:Info("ESPEngine: Enabled successfully")
    Events:Emit("ESPStateChanged", true)
    return true
end

function ESPEngine:Disable()
    if not self.Enabled then return false end
    if self.State == FeatureState.DISABLING then return false end

    self.State = FeatureState.DISABLING
    MainLogger:Info("ESPEngine: Disabling...")

    self.Enabled = false

    for player, espData in pairs(self.Boxes) do
        for _, obj in ipairs(espData) do
            if obj and obj.Destroy and typeof(obj) ~= "RBXScriptConnection" then
                safeCall(function() obj:Destroy() end)
            end
        end
    end
    self.Boxes = {}

    for _, conn in ipairs(self.PlayerConnections) do
        if conn and conn.Connected then
            conn:Disconnect()
        end
    end
    self.PlayerConnections = {}

    if self.Gui then
        self.Gui:Destroy()
        self.Gui = nil
    end

    self.State = FeatureState.DISABLED
    MainLogger:Info("ESPEngine: Disabled successfully")
    Events:Emit("ESPStateChanged", false)
    return true
end

function ESPEngine:Toggle()
    if self.Enabled then
        return self:Disable()
    else
        return self:Enable()
    end
end

function ESPEngine:IsEnabled()
    return self.Enabled
end

function ESPEngine:GetState()
    return self.State
end

function ESPEngine:SetHighlightEnabled(enabled)
    self.HighlightEnabled = enabled
    Events:Emit("ESPHighlightChanged", enabled)
end

function ESPEngine:SetTracerEnabled(enabled)
    self.TracerEnabled = enabled
    Events:Emit("ESPTracerChanged", enabled)
end

function ESPEngine:GetPlayerCount()
    return Utility.tableLength(self.Boxes)
end

function ESPEngine:Cleanup()
    if self.Enabled then
        self:Disable()
    end
    self.Boxes = {}
    self.PlayerConnections = {}
    if self.Gui then
        self.Gui:Destroy()
        self.Gui = nil
    end
end

local ESPController = ESPEngine.new()

local function EnableESP()
    if ESPController:Enable() then
        NotifySuccess("ESP", "Đã bật ESP", 2)
        Settings.ESPEnabled = true
        Settings.ESPGui = ESPController.Gui
        Settings.ESPBoxes = ESPController.Boxes
    end
end

local function DisableESP()
    if ESPController:Disable() then
        Notify("ESP", "Đã tắt ESP", 2)
        Settings.ESPEnabled = false
        Settings.ESPGui = nil
        Settings.ESPBoxes = {}
    end
end

Events:Subscribe("ESPStateChanged", function(enabled)
    Settings.ESPEnabled = enabled
end)

Events:Subscribe("ESPHighlightChanged", function(enabled)
    Settings.ESPHighlight = enabled
end)

Events:Subscribe("ESPTracerChanged", function(enabled)
    Settings.ESPTracer = enabled
end)

local WallhackEngine = {}
WallhackEngine.__index = WallhackEngine

function WallhackEngine.new()
    local self = setmetatable({}, WallhackEngine)
    self.Enabled = false
    self.DescendantConnection = nil
    self.State = FeatureState.DISABLED
    self.ObjectsModified = 0
    return self
end

function WallhackEngine:Enable()
    if self.Enabled then return false end
    if self.State == FeatureState.ENABLING then return false end

    self.State = FeatureState.ENABLING
    MainLogger:Info("WallhackEngine: Enabling...")

    self.ObjectsModified = 0

    local function applyWallhack(object)
        if object:IsA("BasePart") and not object.Parent:FindFirstChildOfClass("Humanoid") then
            object.LocalTransparencyModifier = WALLHACK_TRANSPARENCY
            self.ObjectsModified = self.ObjectsModified + 1
        end
    end

    local allObjects = workspace:GetDescendants()
    for i = 1, #allObjects do
        applyWallhack(allObjects[i])
    end

    self.DescendantConnection = Hook(workspace.DescendantAdded, function(object)
        if self.Enabled then
            applyWallhack(object)
        end
    end)

    self.Enabled = true
    self.State = FeatureState.ENABLED
    MainLogger:Info(string.format("WallhackEngine: Enabled successfully, modified %d objects", self.ObjectsModified))
    Events:Emit("WallhackStateChanged", true)
    return true
end

function WallhackEngine:Disable()
    if not self.Enabled then return false end
    if self.State == FeatureState.DISABLING then return false end

    self.State = FeatureState.DISABLING
    MainLogger:Info("WallhackEngine: Disabling...")

    self.Enabled = false

    if self.DescendantConnection then
        self.DescendantConnection:Disconnect()
        self.DescendantConnection = nil
    end

    local allObjects = workspace:GetDescendants()
    for i = 1, #allObjects do
        local object = allObjects[i]
        if object:IsA("BasePart") then
            object.LocalTransparencyModifier = 0
        end
    end

    self.ObjectsModified = 0
    self.State = FeatureState.DISABLED
    MainLogger:Info("WallhackEngine: Disabled successfully")
    Events:Emit("WallhackStateChanged", false)
    return true
end

function WallhackEngine:Toggle()
    if self.Enabled then
        return self:Disable()
    else
        return self:Enable()
    end
end

function WallhackEngine:IsEnabled()
    return self.Enabled
end

function WallhackEngine:GetState()
    return self.State
end

function WallhackEngine:Cleanup()
    if self.Enabled then
        self:Disable()
    end
    self.DescendantConnection = nil
    self.ObjectsModified = 0
end

local WallhackController = WallhackEngine.new()

local function EnableWallhack()
    if WallhackController:Enable() then
        NotifySuccess("Wallhack", "Đã bật nhìn xuyên tường", 2)
        Settings.Wallhack = true
        Settings.WallhackConn = WallhackController.DescendantConnection
    end
end

local function DisableWallhack()
    if WallhackController:Disable() then
        Notify("Wallhack", "Đã tắt nhìn xuyên tường", 2)
        Settings.Wallhack = false
        Settings.WallhackConn = nil
    end
end

Events:Subscribe("WallhackStateChanged", function(enabled)
    Settings.Wallhack = enabled
end)

local FullbrightEngine = {}
FullbrightEngine.__index = FullbrightEngine

function FullbrightEngine.new()
    local self = setmetatable({}, FullbrightEngine)
    self.Enabled = false
    self.PropertyConnection = nil
    self.State = FeatureState.DISABLED
    self.OriginalBrightness = Lighting.Brightness
    self.OriginalFogEnd = Lighting.FogEnd
    return self
end

function FullbrightEngine:Enable()
    if self.Enabled then return false end
    if self.State == FeatureState.ENABLING then return false end

    self.State = FeatureState.ENABLING
    MainLogger:Info("FullbrightEngine: Enabling...")

    self.OriginalBrightness = Lighting.Brightness
    self.OriginalFogEnd = Lighting.FogEnd

    Lighting.Brightness = FULLBRIGHT_BRIGHTNESS
    Lighting.ClockTime = FULLBRIGHT_CLOCK_TIME
    Lighting.FogEnd = FULLBRIGHT_FOG_END

    self.PropertyConnection = Hook(Lighting:GetPropertyChangedSignal("Brightness"), function()
        if self.Enabled and Lighting.Brightness ~= FULLBRIGHT_BRIGHTNESS then
            Lighting.Brightness = FULLBRIGHT_BRIGHTNESS
        end
    end)

    self.Enabled = true
    self.State = FeatureState.ENABLED
    MainLogger:Info("FullbrightEngine: Enabled successfully")
    Events:Emit("FullbrightStateChanged", true)
    return true
end

function FullbrightEngine:Disable()
    if not self.Enabled then return false end
    if self.State == FeatureState.DISABLING then return false end

    self.State = FeatureState.DISABLING
    MainLogger:Info("FullbrightEngine: Disabling...")

    self.Enabled = false

    if self.PropertyConnection then
        self.PropertyConnection:Disconnect()
        self.PropertyConnection = nil
    end

    Lighting.Brightness = self.OriginalBrightness
    Lighting.FogEnd = self.OriginalFogEnd

    self.State = FeatureState.DISABLED
    MainLogger:Info("FullbrightEngine: Disabled successfully")
    Events:Emit("FullbrightStateChanged", false)
    return true
end

function FullbrightEngine:Toggle()
    if self.Enabled then
        return self:Disable()
    else
        return self:Enable()
    end
end

function FullbrightEngine:IsEnabled()
    return self.Enabled
end

function FullbrightEngine:GetState()
    return self.State
end

function FullbrightEngine:Cleanup()
    if self.Enabled then
        self:Disable()
    end
    self.PropertyConnection = nil
end

local FullbrightController = FullbrightEngine.new()

local function EnableFullbright()
    if FullbrightController:Enable() then
        NotifySuccess("Fullbright", "Đã bật đèn nền", 2)
        Settings.Fullbright = true
        Settings.FullbrightConn = FullbrightController.PropertyConnection
    end
end

local function DisableFullbright()
    if FullbrightController:Disable() then
        Notify("Fullbright", "Đã tắt đèn nền", 2)
        Settings.Fullbright = false
        Settings.FullbrightConn = nil
    end
end

Events:Subscribe("FullbrightStateChanged", function(enabled)
    Settings.Fullbright = enabled
end)

local FPSBoostEngine = {}
FPSBoostEngine.__index = FPSBoostEngine

function FPSBoostEngine.new()
    local self = setmetatable({}, FPSBoostEngine)
    self.Enabled = false
    self.State = FeatureState.DISABLED
    self.OriginalQualityLevel = nil
    return self
end

function FPSBoostEngine:Enable()
    if self.Enabled then return false end
    if self.State == FeatureState.ENABLING then return false end

    self.State = FeatureState.ENABLING
    MainLogger:Info("FPSBoostEngine: Enabling...")

    safeCall(function()
        self.OriginalQualityLevel = settings().Rendering.QualityLevel
        settings().Rendering.QualityLevel = 1
    end)

    self.Enabled = true
    self.State = FeatureState.ENABLED
    MainLogger:Info("FPSBoostEngine: Enabled successfully")
    Events:Emit("FPSBoostStateChanged", true)
    return true
end

function FPSBoostEngine:Disable()
    if not self.Enabled then return false end
    if self.State == FeatureState.DISABLING then return false end

    self.State = FeatureState.DISABLING
    MainLogger:Info("FPSBoostEngine: Disabling...")

    self.Enabled = false

    safeCall(function()
        if self.OriginalQualityLevel then
            settings().Rendering.QualityLevel = self.OriginalQualityLevel
        else
            settings().Rendering.QualityLevel = 10
        end
    end)

    self.State = FeatureState.DISABLED
    MainLogger:Info("FPSBoostEngine: Disabled successfully")
    Events:Emit("FPSBoostStateChanged", false)
    return true
end

function FPSBoostEngine:Toggle()
    if self.Enabled then
        return self:Disable()
    else
        return self:Enable()
    end
end

function FPSBoostEngine:IsEnabled()
    return self.Enabled
end

function FPSBoostEngine:GetState()
    return self.State
end

function FPSBoostEngine:Cleanup()
    if self.Enabled then
        self:Disable()
    end
end

local FPSBoostController = FPSBoostEngine.new()

local function EnableFPSBoost()
    if FPSBoostController:Enable() then
        NotifySuccess("FPS Boost", "Đã bật tăng FPS", 2)
        Settings.FPSBoost = true
    end
end

local function DisableFPSBoost()
    if FPSBoostController:Disable() then
        Notify("FPS Boost", "Đã tắt tăng FPS", 2)
        Settings.FPSBoost = false
    end
end

Events:Subscribe("FPSBoostStateChanged", function(enabled)
    Settings.FPSBoost = enabled
end)

local LowGraphicsEngine = {}
LowGraphicsEngine.__index = LowGraphicsEngine

function LowGraphicsEngine.new()
    local self = setmetatable({}, LowGraphicsEngine)
    self.Enabled = false
    self.State = FeatureState.DISABLED
    self.OriginalGlobalShadows = Lighting.GlobalShadows
    self.OriginalFogEnd = Lighting.FogEnd
    self.OriginalBrightness = Lighting.Brightness
    return self
end

function LowGraphicsEngine:Enable()
    if self.Enabled then return false end
    if self.State == FeatureState.ENABLING then return false end

    self.State = FeatureState.ENABLING
    MainLogger:Info("LowGraphicsEngine: Enabling...")

    self.OriginalGlobalShadows = Lighting.GlobalShadows
    self.OriginalFogEnd = Lighting.FogEnd
    self.OriginalBrightness = Lighting.Brightness

    Lighting.GlobalShadows = false
    Lighting.FogEnd = LOW_GRAPHICS_FOG_END
    Lighting.Brightness = 1

    self.Enabled = true
    self.State = FeatureState.ENABLED
    MainLogger:Info("LowGraphicsEngine: Enabled successfully")
    Events:Emit("LowGraphicsStateChanged", true)
    return true
end

function LowGraphicsEngine:Disable()
    if not self.Enabled then return false end
    if self.State == FeatureState.DISABLING then return false end

    self.State = FeatureState.DISABLING
    MainLogger:Info("LowGraphicsEngine: Disabling...")

    self.Enabled = false

    Lighting.GlobalShadows = self.OriginalGlobalShadows
    Lighting.FogEnd = self.OriginalFogEnd
    Lighting.Brightness = self.OriginalBrightness

    self.State = FeatureState.DISABLED
    MainLogger:Info("LowGraphicsEngine: Disabled successfully")
    Events:Emit("LowGraphicsStateChanged", false)
    return true
end

function LowGraphicsEngine:Toggle()
    if self.Enabled then
        return self:Disable()
    else
        return self:Enable()
    end
end

function LowGraphicsEngine:IsEnabled()
    return self.Enabled
end

function LowGraphicsEngine:GetState()
    return self.State
end

function LowGraphicsEngine:Cleanup()
    if self.Enabled then
        self:Disable()
    end
end

local LowGraphicsController = LowGraphicsEngine.new()

local function EnableLowGraphics()
    if LowGraphicsController:Enable() then
        NotifySuccess("Đồ họa", "Đã bật đồ họa thấp", 2)
        Settings.LowGraphics = true
    end
end

local function DisableLowGraphics()
    if LowGraphicsController:Disable() then
        Notify("Đồ họa", "Đã khôi phục đồ họa", 2)
        Settings.LowGraphics = false
    end
end

Events:Subscribe("LowGraphicsStateChanged", function(enabled)
    Settings.LowGraphics = enabled
end)

local TeleportSystem = {}
TeleportSystem.__index = TeleportSystem

function TeleportSystem.new()
    local self = setmetatable({}, TeleportSystem)
    self.MarkedPosition = nil
    self.MarkedTimestamp = nil
    self.TeleportCount = 0
    self.State = FeatureState.DISABLED
    return self
end

function TeleportSystem:MarkPosition()
    local rootPart = getRoot()
    if not rootPart then
        MainLogger:Warn("TeleportSystem: Cannot mark position, root part not found")
        return false
    end

    self.MarkedPosition = rootPart.CFrame
    self.MarkedTimestamp = tick()
    self.State = FeatureState.ENABLED

    MainLogger:Info(string.format("TeleportSystem: Position marked at %s", tostring(self.MarkedPosition.Position)))
    Events:Emit("TeleportMarkSet", self.MarkedPosition)
    return true
end

function TeleportSystem:TeleportToMark()
    if not self.MarkedPosition then
        MainLogger:Warn("TeleportSystem: No marked position to teleport to")
        return false
    end

    local rootPart = getRoot()
    if not rootPart then
        MainLogger:Warn("TeleportSystem: Cannot teleport, root part not found")
        return false
    end

    rootPart.CFrame = self.MarkedPosition
    self.TeleportCount = self.TeleportCount + 1

    MainLogger:Info("TeleportSystem: Teleported to marked position")
    Events:Emit("TeleportedToMark", self.MarkedPosition)
    return true
end

function TeleportSystem:TeleportToPlayer(targetPlayer)
    if not targetPlayer then
        local nearestPlayer = self:FindNearestPlayer()
        if not nearestPlayer then return false end
        targetPlayer = nearestPlayer
    end

    local rootPart = getRoot()
    if not rootPart then return false end

    local targetCharacter = targetPlayer.Character
    if not targetCharacter then return false end

    local targetRoot = targetCharacter:FindFirstChild("HumanoidRootPart")
    if not targetRoot or not targetRoot:IsDescendantOf(workspace) then return false end

    local targetPosition = targetRoot.CFrame + Vector3.new(0, 3, 0)
    rootPart.CFrame = targetPosition
    self.TeleportCount = self.TeleportCount + 1

    MainLogger:Info(string.format("TeleportSystem: Teleported to player %s", targetPlayer.Name))
    Events:Emit("TeleportedToPlayer", targetPlayer)
    return true
end

function TeleportSystem:FindNearestPlayer()
    local rootPart = getRoot()
    if not rootPart then return nil end

    local nearestPlayer = nil
    local minimumDistance = math.huge
    local allPlayers = Players:GetPlayers()

    for i = 1, #allPlayers do
        local player = allPlayers[i]
        if player ~= LocalPlayer and player.Character then
            local targetRoot = player.Character:FindFirstChild("HumanoidRootPart")
            if targetRoot and targetRoot:IsDescendantOf(workspace) then
                local distance = (rootPart.Position - targetRoot.Position).Magnitude
                if distance < minimumDistance then
                    minimumDistance = distance
                    nearestPlayer = player
                end
            end
        end
    end

    return nearestPlayer, minimumDistance
end

function TeleportSystem:FindNearestTree()
    local rootPart = getRoot()
    if not rootPart then return nil end

    local playerPosition = rootPart.Position
    local nearestTree = nil
    local minimumDistance = math.huge

    local treeKeywords = {
        "tree", "cay", "wood", "log", "pine", "oak", "birch", "maple",
        "palm", "trunk", "branch", "forest", "jungle", "timber", "lumber",
        "plant", "bush", "foliage", "bamboo", "cactus", "gỗ", "cây"
    }

    local allObjects = workspace:GetDescendants()
    for i = 1, #allObjects do
        local object = allObjects[i]
        local isTree = false
        local targetPart = nil

        if object:IsA("Model") then
            local name = string.lower(object.Name)
            for _, keyword in ipairs(treeKeywords) do
                if string.find(name, keyword) then
                    isTree = true
                    break
                end
            end
            if isTree then
                targetPart = object:FindFirstChild("HumanoidRootPart") or
                             object:FindFirstChild("Torso") or
                             object:FindFirstChild("PrimaryPart")
                if not targetPart then
                    local children = object:GetChildren()
                    for j = 1, #children do
                        local child = children[j]
                        if child:IsA("BasePart") then
                            targetPart = child
                            break
                        end
                    end
                end
            end
        elseif object:IsA("BasePart") then
            local name = string.lower(object.Name)
            for _, keyword in ipairs(treeKeywords) do
                if string.find(name, keyword) then
                    isTree = true
                    break
                end
            end
            if not isTree then
                if object.Material == Enum.Material.Wood or
                   object.Material == Enum.Material.WoodPlanks then
                    local parent = object.Parent
                    if parent and not parent:FindFirstChildOfClass("Humanoid") then
                        local parentName = string.lower(parent.Name)
                        for _, keyword in ipairs(treeKeywords) do
                            if string.find(parentName, keyword) then
                                isTree = true
                                break
                            end
                        end
                    end
                end
            end
            if isTree then
                targetPart = object
            end
        end

        if isTree and targetPart and not targetPart.Parent:FindFirstChildOfClass("Humanoid") then
            local distance = (playerPosition - targetPart.Position).Magnitude
            if distance < minimumDistance and distance < MAX_TREE_DISTANCE then
                minimumDistance = distance
                nearestTree = targetPart
            end
        end
    end

    return nearestTree, minimumDistance
end

function TeleportSystem:TeleportToNearestTree()
    local tree, distance = self:FindNearestTree()
    if not tree then
        MainLogger:Warn("TeleportSystem: No tree found within range")
        return false, "Không tìm thấy cây trong phạm vi " .. MAX_TREE_DISTANCE .. "m"
    end

    local rootPart = getRoot()
    if not rootPart then
        MainLogger:Warn("TeleportSystem: Cannot teleport, root part not found")
        return false, "Không tìm thấy nhân vật"
    end

    local targetPosition = tree.Position + Vector3.new(0, 5, 0)
    rootPart.CFrame = CFrame.new(targetPosition)
    self.TeleportCount = self.TeleportCount + 1

    MainLogger:Info(string.format("TeleportSystem: Teleported to tree at distance %.0fm", distance or 0))
    Events:Emit("TeleportedToTree", tree, distance)
    return true, nil
end

function TeleportSystem:GetMarkedPosition()
    return self.MarkedPosition, self.MarkedTimestamp
end

function TeleportSystem:GetTeleportCount()
    return self.TeleportCount
end

function TeleportSystem:ClearMark()
    self.MarkedPosition = nil
    self.MarkedTimestamp = nil
    self.State = FeatureState.DISABLED
    MainLogger:Info("TeleportSystem: Mark cleared")
    Events:Emit("TeleportMarkCleared")
end

local TeleportController = TeleportSystem.new()

local function SetTeleportMark()
    if TeleportController:MarkPosition() then
        NotifySuccess("Đánh dấu", "Đã đặt điểm dịch chuyển", 2)
        Settings.TeleportMark = TeleportController.MarkedPosition
    end
end

local function TeleportToMark()
    if TeleportController:TeleportToMark() then
        NotifySuccess("Dịch chuyển", "Đã về điểm đánh dấu", 2)
    else
        NotifyError("Lỗi", "Chưa đặt điểm đánh dấu", 2)
    end
end

local function TeleportToNearestPlayer()
    if TeleportController:TeleportToPlayer() then
        NotifySuccess("Dịch chuyển", "Đến người chơi gần nhất", 2)
    else
        NotifyError("Lỗi", "Không tìm thấy người chơi", 2)
    end
end

local function TeleportToNearestTree()
    local success, errorMessage = TeleportController:TeleportToNearestTree()
    if success then
        NotifySuccess("Dịch chuyển", "Đến cây gần nhất", 2)
    else
        NotifyError("Lỗi", errorMessage or "Không tìm thấy cây", 2)
    end
end

Events:Subscribe("TeleportMarkSet", function(position)
    Settings.TeleportMark = position
end)

Events:Subscribe("TeleportMarkCleared", function()
    Settings.TeleportMark = nil
end)

local UnloadSystem = {}
UnloadSystem.__index = UnloadSystem

function UnloadSystem.new()
    local self = setmetatable({}, UnloadSystem)
    self.IsUnloading = false
    return self
end

function UnloadSystem:Execute()
    if self.IsUnloading then
        MainLogger:Warn("UnloadSystem: Already unloading")
        return false
    end

    self.IsUnloading = true
    MainLogger:Info("UnloadSystem: Starting full cleanup...")

    Events:Emit("UnloadStarted")

    Settings.FlyEnabled = false
    Settings.NoClipEnabled = false
    Settings.ESPEnabled = false
    Settings.InfiniteJump = false
    Settings.AntiKnockback = false
    Settings.AimbotEnabled = false
    Settings.Wallhack = false
    Settings.Fullbright = false
    Settings.FPSBoost = false
    Settings.LowGraphics = false

    FlyController:Cleanup()
    NoClipController:Cleanup()
    InfiniteJumpController:Cleanup()
    AntiKBController:Cleanup()
    AimbotController:Cleanup()
    ESPController:Cleanup()
    WallhackController:Cleanup()
    FullbrightController:Cleanup()
    FPSBoostController:Cleanup()
    LowGraphicsController:Cleanup()

    Settings.FlyBV = nil
    Settings.FlyBG = nil
    Settings.FlyConn = nil
    Settings.NoClipConn = nil
    Settings.InfJumpConn = nil
    Settings.AntiKBConn = nil
    Settings.AimbotConn = nil
    Settings.ESPGui = nil
    Settings.ESPBoxes = {}
    Settings.WallhackConn = nil
    Settings.FullbrightConn = nil

    safeCall(function()
        local character = LocalPlayer.Character
        if character then
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid.PlatformStand = false
            end

            local descendants = character:GetDescendants()
            for i = 1, #descendants do
                local part = descendants[i]
                if part:IsA("BasePart") then
                    part.CanCollide = true
                end
            end
        end
    end)

    Lighting.Brightness = 1
    Lighting.FogEnd = DEFAULT_FOG_END
    Lighting.GlobalShadows = true

    local allObjects = workspace:GetDescendants()
    for i = 1, #allObjects do
        local object = allObjects[i]
        if object:IsA("BasePart") then
            object.LocalTransparencyModifier = 0
        end
    end

    safeCall(function()
        settings().Rendering.QualityLevel = 10
    end)

    TeleportController:ClearMark()

    BgManager:Remove()
    Effects:StopAll()

    ConnManager:DisconnectAll()

    Events:Emit("UnloadCompleted")

    MainLogger:Info("UnloadSystem: Cleanup completed")
    return true
end

function UnloadSystem:EmergencyCleanup()
    MainLogger:Warn("UnloadSystem: Emergency cleanup triggered")

    pcall(function()
        FlyController:Cleanup()
        NoClipController:Cleanup()
        ESPController:Cleanup()
    end)

    ConnManager:DisconnectAll()
end

local Unloader = UnloadSystem.new()

local function ResetCharacter()
    safeCall(function()
        local character = LocalPlayer.Character
        if character then
            character:BreakJoints()
        end
    end)
    Notify("Reset", "Đã reset nhân vật", 2)
end

local function UnloadAll()
    if Unloader:Execute() then
        Notify("Unload", "Đã gỡ bỏ script", 2)
        task.wait(0.5)
        Window:Destroy()
    end
end

game:BindToClose(function()
    MainLogger:Info("Game closing, performing cleanup...")
    Unloader:EmergencyCleanup()
end)

local MainTab = Window:Tab({ Title = "Main", Icon = "home" })

local FlySection = MainTab:Section({ Title = "Bay (Fly)" })
FlySection:Toggle({
    Title = "Bật Bay",
    Value = false,
    Callback = function(state)
        if state then
            EnableFly()
        else
            DisableFly()
        end
    end,
})
FlySection:Slider({
    Title = "Tốc độ bay",
    Step = 1,
    Value = { Min = 20, Max = 300, Default = 50 },
    Callback = function(value)
        FlyController:SetSpeed(value)
        Settings.FlySpeed = value
    end,
})

local MoveSection = MainTab:Section({ Title = "Di chuyển" })
MoveSection:Slider({
    Title = "Tốc độ",
    Step = 1,
    Value = { Min = 16, Max = 300, Default = 16 },
    Callback = function(value)
        CharManager:SetWalkSpeed(value)
    end,
})
MoveSection:Slider({
    Title = "Sức nhảy",
    Step = 1,
    Value = { Min = 50, Max = 500, Default = 50 },
    Callback = function(value)
        CharManager:SetJumpPower(value)
    end,
})
MoveSection:Toggle({
    Title = "NoClip (Xuyên tường)",
    Value = false,
    Callback = function(state)
        if state then
            EnableNoClip()
        else
            DisableNoClip()
        end
    end,
})

local PlayerTab = Window:Tab({ Title = "Player", Icon = "user" })

local PlayerSection = PlayerTab:Section({ Title = "Nhân vật" })
PlayerSection:Toggle({
    Title = "Nhảy vô hạn",
    Value = false,
    Callback = function(state)
        if state then
            EnableInfiniteJump()
        else
            DisableInfiniteJump()
        end
    end,
})
PlayerSection:Toggle({
    Title = "Anti Knockback",
    Value = false,
    Callback = function(state)
        if state then
            EnableAntiKB()
        else
            DisableAntiKB()
        end
    end,
})
PlayerSection:Slider({
    Title = "FOV (Trường nhìn)",
    Step = 1,
    Value = { Min = 30, Max = 120, Default = 70 },
    Callback = function(value)
        Camera.FieldOfView = value
    end,
})

local AimbotTab = Window:Tab({ Title = "Aimbot", Icon = "crosshair" })

local AimbotSection = AimbotTab:Section({ Title = "Cài đặt Aimbot" })
AimbotSection:Toggle({
    Title = "Bật Aimbot",
    Value = false,
    Callback = function(state)
        if state then
            EnableAimbot()
        else
            DisableAimbot()
        end
    end,
})
AimbotSection:Slider({
    Title = "Độ mượt",
    Step = 0.05,
    Value = { Min = 0.1, Max = 1.0, Default = 0.5 },
    Callback = function(value)
        AimbotController:SetSmoothness(value)
    end,
})

local VisualTab = Window:Tab({ Title = "Visual", Icon = "eye" })

local ESPSection = VisualTab:Section({ Title = "ESP Pro" })
ESPSection:Toggle({
    Title = "Bật ESP",
    Value = false,
    Callback = function(state)
        if state then
            EnableESP()
        else
            DisableESP()
        end
    end,
})
ESPSection:Toggle({
    Title = "Highlight",
    Value = true,
    Callback = function(state)
        ESPController:SetHighlightEnabled(state)
    end,
})
ESPSection:Toggle({
    Title = "Tracer",
    Value = true,
    Callback = function(state)
        ESPController:SetTracerEnabled(state)
    end,
})

local WorldSection = VisualTab:Section({ Title = "Thế giới" })
WorldSection:Toggle({
    Title = "Wallhack",
    Value = false,
    Callback = function(state)
        if state then
            EnableWallhack()
        else
            DisableWallhack()
        end
    end,
})
WorldSection:Toggle({
    Title = "Fullbright",
    Value = false,
    Callback = function(state)
        if state then
            EnableFullbright()
        else
            DisableFullbright()
        end
    end,
})
WorldSection:Toggle({
    Title = "Đồ họa thấp",
    Value = false,
    Callback = function(state)
        if state then
            EnableLowGraphics()
        else
            DisableLowGraphics()
        end
    end,
})
WorldSection:Toggle({
    Title = "FPS Boost",
    Value = false,
    Callback = function(state)
        if state then
            EnableFPSBoost()
        else
            DisableFPSBoost()
        end
    end,
})

local TeleportTab = Window:Tab({ Title = "Teleport", Icon = "move" })

local MarkSection = TeleportTab:Section({ Title = "Đánh dấu" })
MarkSection:Button({
    Title = "Đặt điểm",
    Callback = SetTeleportMark,
})
MarkSection:Button({
    Title = "Dịch chuyển về",
    Callback = TeleportToMark,
})

local TeleportSection = TeleportTab:Section({ Title = "Dịch chuyển nhanh" })
TeleportSection:Button({
    Title = "Đến cây gần nhất",
    Callback = TeleportToNearestTree,
})
TeleportSection:Button({
    Title = "Đến người chơi gần nhất",
    Callback = TeleportToNearestPlayer,
})

local MiscTab = Window:Tab({ Title = "Misc", Icon = "settings" })

local MiscSection = MiscTab:Section({ Title = "Tiện ích" })
MiscSection:Button({
    Title = "Reset nhân vật",
    Callback = ResetCharacter,
})

local SettingsTab = Window:Tab({ Title = "Settings", Icon = "settings" })

local SystemSection = SettingsTab:Section({ Title = "Hệ thống" })
SystemSection:Button({
    Title = "Unload (Xóa tất cả)",
    Callback = UnloadAll,
})

MainLogger:Info(string.format("%s v%s initialized successfully", SCRIPT_NAME, SCRIPT_VERSION))
Notifier:SendSuccess(SCRIPT_NAME, "v" .. SCRIPT_VERSION .. " đã sẵn sàng!", 5)
Events:Emit("ScriptLoaded", SCRIPT_VERSION)