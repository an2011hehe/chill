local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

if not game:IsLoaded() then game.Loaded:Wait() end

local Window = WindUI:CreateWindow({
    Title = "Premium Hub",
    Icon = "star",
    Author = "by nhatanh",
    Folder = "PremiumHub",
    Theme = "Dark",
    Size = UDim2.fromOffset(580, 490),
})

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
}

local Connections = {}

local function Hook(signal, callback)
    local conn = signal:Connect(callback)
    table.insert(Connections, conn)
    return conn
end

local function KillConnections()
    for _, conn in ipairs(Connections) do
        if conn.Connected then conn:Disconnect() end
    end
    Connections = {}
end

local function safeCall(func, ...)
    return pcall(func, ...)
end

local function getChar()
    local char = LocalPlayer.Character
    if not char then
        LocalPlayer.CharacterAdded:Wait()
        char = LocalPlayer.Character
    end
    return char
end

local function getHum()
    return getChar():WaitForChild("Humanoid")
end

local function getRoot()
    return getChar():WaitForChild("HumanoidRootPart")
end

local function Notify(title, content, duration)
    WindUI:Notify({
        Title = title,
        Content = content,
        Duration = duration or 3,
    })
end

local function EnableFly()
    if Settings.FlyEnabled then return end
    Settings.FlyEnabled = true
    local char = getChar()
    local hum = getHum()
    local root = getRoot()
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
    Hook(UserInputService.InputBegan, function(input, gpe)
        if not gpe then keysDown[input.KeyCode] = true end
    end)
    Hook(UserInputService.InputEnded, function(input)
        keysDown[input.KeyCode] = false
    end)

    Settings.FlyConn = Hook(RunService.RenderStepped, function()
        if not Settings.FlyEnabled then return end
        if not Settings.FlyBV or not Settings.FlyBV.Parent then
            DisableFly()
            return
        end
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
    Notify("Fly", "Đã bật bay", 2)
end

local function DisableFly()
    Settings.FlyEnabled = false
    safeCall(function()
        if Settings.FlyBV then Settings.FlyBV:Destroy(); Settings.FlyBV = nil end
        if Settings.FlyBG then Settings.FlyBG:Destroy(); Settings.FlyBG = nil end
        if Settings.FlyConn then Settings.FlyConn:Disconnect(); Settings.FlyConn = nil end
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then hum.PlatformStand = false end
        end
    end)
    Notify("Fly", "Đã tắt bay", 2)
end

local function EnableNoClip()
    if Settings.NoClipEnabled then return end
    Settings.NoClipEnabled = true
    Settings.NoClipConn = Hook(RunService.Stepped, function()
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
    Notify("NoClip", "Đã bật NoClip", 2)
end

local function DisableNoClip()
    Settings.NoClipEnabled = false
    if Settings.NoClipConn then Settings.NoClipConn:Disconnect(); Settings.NoClipConn = nil end
    safeCall(function()
        local char = LocalPlayer.Character
        if char then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then part.CanCollide = true end
            end
        end
    end)
    Notify("NoClip", "Đã tắt NoClip", 2)
end

local function EnableESP()
    if Settings.ESPEnabled then return end
    Settings.ESPEnabled = true
    if Settings.ESPGui then Settings.ESPGui:Destroy() end
    local ESPGui = Instance.new("ScreenGui")
    ESPGui.Name = "ESPGui"
    ESPGui.Parent = game:GetService("CoreGui")
    ESPGui.DisplayOrder = 999
    Settings.ESPGui = ESPGui

    local function createESP(player)
        if player == LocalPlayer then return end

        local function setup()
            local char = player.Character
            if not char then return end
            local root = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Head")
            if not root then return end

            if Settings.ESPBoxes[player] then
                for _, obj in ipairs(Settings.ESPBoxes[player]) do
                    if obj and obj.Destroy and typeof(obj) ~= "RBXScriptConnection" then
                        safeCall(function() obj:Destroy() end)
                    end
                end
            end

            local box = Instance.new("Frame")
            box.BackgroundColor3 = Color3.fromRGB(139, 92, 246)
            box.BackgroundTransparency = 0.6
            box.BorderSizePixel = 0
            box.Parent = ESPGui
            Instance.new("UICorner", box).CornerRadius = UDim.new(0, 3)

            local stroke = Instance.new("UIStroke")
            stroke.Color = Color3.fromRGB(139, 92, 246)
            stroke.Thickness = 1.5
            stroke.Transparency = 0.3
            stroke.Parent = box

            local nameLabel = Instance.new("TextLabel")
            nameLabel.BackgroundTransparency = 1
            nameLabel.Text = player.Name
            nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            nameLabel.Font = Enum.Font.GothamBold
            nameLabel.TextSize = 11
            nameLabel.TextStrokeTransparency = 0.3
            nameLabel.Parent = ESPGui

            local healthBg = Instance.new("Frame")
            healthBg.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
            healthBg.BackgroundTransparency = 0.3
            healthBg.BorderSizePixel = 0
            healthBg.Parent = ESPGui
            Instance.new("UICorner", healthBg).CornerRadius = UDim.new(0, 2)

            local healthFill = Instance.new("Frame")
            healthFill.BackgroundColor3 = Color3.fromRGB(50, 200, 100)
            healthFill.BorderSizePixel = 0
            healthFill.Parent = healthBg
            Instance.new("UICorner", healthFill).CornerRadius = UDim.new(0, 2)

            local distLabel = Instance.new("TextLabel")
            distLabel.BackgroundTransparency = 1
            distLabel.TextColor3 = Color3.fromRGB(160, 160, 170)
            distLabel.Font = Enum.Font.Gotham
            distLabel.TextSize = 9
            distLabel.Parent = ESPGui

            local conn = Hook(RunService.RenderStepped, function()
                if not Settings.ESPEnabled then
                    box.Visible = false; nameLabel.Visible = false
                    healthBg.Visible = false; distLabel.Visible = false
                    return
                end
                local currentChar = player.Character
                if not currentChar then
                    box.Visible = false; nameLabel.Visible = false
                    healthBg.Visible = false; distLabel.Visible = false
                    return
                end
                local currentRoot = currentChar:FindFirstChild("HumanoidRootPart") or currentChar:FindFirstChild("Head")
                if not currentRoot or not currentRoot:IsDescendantOf(workspace) then
                    box.Visible = false; nameLabel.Visible = false
                    healthBg.Visible = false; distLabel.Visible = false
                    return
                end
                local pos, onScreen = Camera:WorldToViewportPoint(currentRoot.Position)
                if not onScreen then
                    box.Visible = false; nameLabel.Visible = false
                    healthBg.Visible = false; distLabel.Visible = false
                    return
                end
                local hum = currentChar:FindFirstChildOfClass("Humanoid")
                local depth = math.max(0.1, (Camera.CFrame.Position - currentRoot.Position).Magnitude)
                local scale = math.clamp(200 / depth, 1.5, 4)
                local modelSize = currentChar:GetExtentsSize()
                local width = math.clamp(modelSize.X * scale, 30, 120)
                local height = math.clamp(modelSize.Y * scale, 50, 180)

                box.Visible = true
                box.Size = UDim2.new(0, width, 0, height)
                box.Position = UDim2.new(0, pos.X - width / 2, 0, pos.Y - height / 2)

                nameLabel.Visible = true
                nameLabel.Size = UDim2.new(0, 120, 0, 16)
                nameLabel.Position = UDim2.new(0, pos.X - 60, 0, pos.Y - height / 2 - 20)

                if hum then
                    local hp = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
                    healthFill.Size = UDim2.new(hp, 0, 1, 0)
                    healthFill.BackgroundColor3 = hp > 0.6 and Color3.fromRGB(50, 200, 100) or (hp > 0.3 and Color3.fromRGB(255, 180, 50) or Color3.fromRGB(255, 70, 70))
                end

                healthBg.Visible = true
                healthBg.Size = UDim2.new(0, width, 0, 4)
                healthBg.Position = UDim2.new(0, pos.X - width / 2, 0, pos.Y + height / 2 + 6)

                if LocalPlayer.Character then
                    local localRoot = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if localRoot then
                        distLabel.Visible = true
                        distLabel.Size = UDim2.new(0, 60, 0, 14)
                        distLabel.Position = UDim2.new(0, pos.X - 30, 0, pos.Y + height / 2 + 14)
                        distLabel.Text = string.format("%.0f m", (localRoot.Position - currentRoot.Position).Magnitude)
                    end
                end

                local isEnemy = player.Team and LocalPlayer.Team and player.Team ~= LocalPlayer.Team
                local color = isEnemy and Color3.fromRGB(255, 70, 70) or Color3.fromRGB(139, 92, 246)
                box.BackgroundColor3 = color
                stroke.Color = color
            end)

            Settings.ESPBoxes[player] = {box, nameLabel, healthBg, distLabel, conn}
        end

        if player.Character then setup() end
        Hook(player.CharacterAdded, function()
            task.wait(0.3)
            if Settings.ESPEnabled then setup() end
        end)
    end

    for _, player in ipairs(Players:GetPlayers()) do createESP(player) end
    Hook(Players.PlayerAdded, function(player)
        if Settings.ESPEnabled then createESP(player) end
    end)
    Hook(Players.PlayerRemoving, function(player)
        if Settings.ESPBoxes[player] then
            for _, obj in ipairs(Settings.ESPBoxes[player]) do
                if obj and obj.Destroy and typeof(obj) ~= "RBXScriptConnection" then
                    safeCall(function() obj:Destroy() end)
                end
            end
            Settings.ESPBoxes[player] = nil
        end
    end)
    Notify("ESP", "Đã bật ESP", 2)
end

local function DisableESP()
    Settings.ESPEnabled = false
    for _, data in pairs(Settings.ESPBoxes) do
        for _, obj in ipairs(data) do
            if obj and obj.Destroy and typeof(obj) ~= "RBXScriptConnection" then
                safeCall(function() obj:Destroy() end)
            end
        end
    end
    Settings.ESPBoxes = {}
    if Settings.ESPGui then Settings.ESPGui:Destroy(); Settings.ESPGui = nil end
    Notify("ESP", "Đã tắt ESP", 2)
end

local function EnableAntiKB()
    if Settings.AntiKnockback then return end
    Settings.AntiKnockback = true
    Settings.AntiKBConn = Hook(RunService.RenderStepped, function()
        if not Settings.AntiKnockback then return end
        safeCall(function()
            local char = LocalPlayer.Character
            if char then
                for _, v in ipairs(char:GetDescendants()) do
                    if v:IsA("BodyVelocity") and v ~= Settings.FlyBV then v:Destroy() end
                end
            end
        end)
    end)
    Notify("Anti KB", "Đã bật chống đẩy lùi", 2)
end

local function DisableAntiKB()
    Settings.AntiKnockback = false
    if Settings.AntiKBConn then Settings.AntiKBConn:Disconnect(); Settings.AntiKBConn = nil end
    Notify("Anti KB", "Đã tắt chống đẩy lùi", 2)
end

local function EnableFPSBoost()
    Settings.FPSBoost = true
    safeCall(function() settings().Rendering.QualityLevel = 1 end)
    Notify("FPS Boost", "Đã bật tăng FPS", 2)
end

local function DisableFPSBoost()
    Settings.FPSBoost = false
    safeCall(function() settings().Rendering.QualityLevel = 10 end)
    Notify("FPS Boost", "Đã tắt tăng FPS", 2)
end

local function EnableLowGraphics()
    Settings.LowGraphics = true
    Lighting.GlobalShadows = false
    Lighting.FogEnd = 100
    Lighting.Brightness = 1
    Notify("Đồ họa", "Đã bật đồ họa thấp", 2)
end

local function DisableLowGraphics()
    Settings.LowGraphics = false
    Lighting.GlobalShadows = true
    Lighting.FogEnd = 10000
    Notify("Đồ họa", "Đã khôi phục đồ họa", 2)
end

local function EnableWallhack()
    if Settings.Wallhack then return end
    Settings.Wallhack = true
    local function applyWallhack(obj)
        if obj:IsA("BasePart") and not obj.Parent:FindFirstChildOfClass("Humanoid") then
            obj.LocalTransparencyModifier = 0.6
        end
    end
    for _, o in ipairs(workspace:GetDescendants()) do applyWallhack(o) end
    Settings.WallhackConn = Hook(workspace.DescendantAdded, function(obj)
        if Settings.Wallhack then applyWallhack(obj) end
    end)
    Notify("Wallhack", "Đã bật nhìn xuyên tường", 2)
end

local function DisableWallhack()
    Settings.Wallhack = false
    if Settings.WallhackConn then Settings.WallhackConn:Disconnect(); Settings.WallhackConn = nil end
    for _, o in ipairs(workspace:GetDescendants()) do
        if o:IsA("BasePart") then o.LocalTransparencyModifier = 0 end
    end
    Notify("Wallhack", "Đã tắt nhìn xuyên tường", 2)
end

local function EnableFullbright()
    if Settings.Fullbright then return end
    Settings.Fullbright = true
    Lighting.Brightness = 2
    Lighting.ClockTime = 14
    Lighting.FogEnd = 100000
    Settings.FullbrightConn = Hook(Lighting:GetPropertyChangedSignal("Brightness"), function()
        if Settings.Fullbright and Lighting.Brightness ~= 2 then Lighting.Brightness = 2 end
    end)
    Notify("Fullbright", "Đã bật đèn nền", 2)
end

local function DisableFullbright()
    Settings.Fullbright = false
    if Settings.FullbrightConn then Settings.FullbrightConn:Disconnect(); Settings.FullbrightConn = nil end
    Lighting.Brightness = 1
    Lighting.FogEnd = 10000
    Notify("Fullbright", "Đã tắt đèn nền", 2)
end

local function SetTeleportMark()
    safeCall(function() Settings.TeleportMark = getRoot().CFrame end)
    Notify("Đánh dấu", "Đã đặt điểm dịch chuyển", 2)
end

local function TeleportToMark()
    safeCall(function()
        if Settings.TeleportMark then
            getRoot().CFrame = Settings.TeleportMark
            Notify("Dịch chuyển", "Đã về điểm đánh dấu", 2)
        else
            Notify("Lỗi", "Chưa đặt điểm đánh dấu", 2)
        end
    end)
end

local function TeleportToNearestPlayer()
    safeCall(function()
        local root = getRoot()
        local nearest, minDist = nil, math.huge
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character then
                local tr = p.Character:FindFirstChild("HumanoidRootPart")
                if tr and tr:IsDescendantOf(workspace) then
                    local d = (root.Position - tr.Position).Magnitude
                    if d < minDist then minDist = d; nearest = tr end
                end
            end
        end
        if nearest then
            root.CFrame = nearest.CFrame + Vector3.new(0, 3, 0)
            Notify("Dịch chuyển", "Đến người chơi gần nhất", 2)
        else
            Notify("Lỗi", "Không tìm thấy người chơi", 2)
        end
    end)
end

local function FindNearestTree()
    local root = getRoot()
    local nearestTree, minDist = nil, math.huge
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and obj:IsDescendantOf(workspace) then
            local name = obj.Name:lower()
            if name:find("tree") or name:find("wood") or name:find("log") or
               obj.Material == Enum.Material.Wood or obj.Material == Enum.Material.WoodPlanks then
                if not obj.Parent:FindFirstChildOfClass("Humanoid") then
                    local d = (root.Position - obj.Position).Magnitude
                    if d < minDist then minDist = d; nearestTree = obj end
                end
            end
        end
    end
    return nearestTree
end

local function TeleportToNearestTree()
    safeCall(function()
        local tree = FindNearestTree()
        if tree then
            getRoot().CFrame = CFrame.new(tree.Position + Vector3.new(0, 5, 0))
            Notify("Dịch chuyển", "Đến cây gần nhất", 2)
        else
            Notify("Lỗi", "Không tìm thấy cây", 2)
        end
    end)
end

local MainTab = Window:Tab({ Title = "Main", Icon = "home" })

local FlySection = MainTab:Section({ Title = "Bay (Fly)" })
FlySection:Toggle({
    Title = "Bật Bay",
    Value = false,
    Callback = function(v) if v then EnableFly() else DisableFly() end end,
})
FlySection:Slider({
    Title = "Tốc độ bay",
    Step = 1,
    Value = { Min = 20, Max = 300, Default = 50 },
    Callback = function(v) Settings.FlySpeed = v end,
})

local MoveSection = MainTab:Section({ Title = "Di chuyển" })
MoveSection:Slider({
    Title = "Tốc độ",
    Step = 1,
    Value = { Min = 16, Max = 300, Default = 16 },
    Callback = function(v) safeCall(function() getHum().WalkSpeed = v end) end,
})
MoveSection:Slider({
    Title = "Sức nhảy",
    Step = 1,
    Value = { Min = 50, Max = 500, Default = 50 },
    Callback = function(v) safeCall(function() getHum().JumpPower = v end) end,
})
MoveSection:Toggle({
    Title = "NoClip (Xuyên tường)",
    Value = false,
    Callback = function(v) if v then EnableNoClip() else DisableNoClip() end end,
})

local PlayerTab = Window:Tab({ Title = "Player", Icon = "user" })

local PlayerSection = PlayerTab:Section({ Title = "Nhân vật" })
PlayerSection:Toggle({
    Title = "Nhảy vô hạn",
    Value = false,
    Callback = function(v)
        Settings.InfiniteJump = v
        if v then
            if Settings.InfJumpConn then Settings.InfJumpConn:Disconnect() end
            local lastJump = 0
            Settings.InfJumpConn = Hook(UserInputService.JumpRequest, function()
                local now = tick()
                if now - lastJump < 0.1 then return end
                lastJump = now
                safeCall(function() getHum():ChangeState(Enum.HumanoidStateType.Jumping) end)
            end)
        else
            if Settings.InfJumpConn then Settings.InfJumpConn:Disconnect(); Settings.InfJumpConn = nil end
        end
    end,
})
PlayerSection:Toggle({
    Title = "Anti Knockback",
    Value = false,
    Callback = function(v) if v then EnableAntiKB() else DisableAntiKB() end end,
})
PlayerSection:Slider({
    Title = "FOV (Trường nhìn)",
    Step = 1,
    Value = { Min = 30, Max = 120, Default = 70 },
    Callback = function(v) Camera.FieldOfView = v end,
})

local VisualTab = Window:Tab({ Title = "Visual", Icon = "eye" })

local ESPSection = VisualTab:Section({ Title = "ESP" })
ESPSection:Toggle({
    Title = "Bật ESP",
    Value = false,
    Callback = function(v) if v then EnableESP() else DisableESP() end end,
})

local WorldSection = VisualTab:Section({ Title = "Thế giới" })
WorldSection:Toggle({
    Title = "Wallhack",
    Value = false,
    Callback = function(v) if v then EnableWallhack() else DisableWallhack() end end,
})
WorldSection:Toggle({
    Title = "Fullbright",
    Value = false,
    Callback = function(v) if v then EnableFullbright() else DisableFullbright() end end,
})
WorldSection:Toggle({
    Title = "Đồ họa thấp",
    Value = false,
    Callback = function(v) if v then EnableLowGraphics() else DisableLowGraphics() end end,
})
WorldSection:Toggle({
    Title = "FPS Boost",
    Value = false,
    Callback = function(v) if v then EnableFPSBoost() else DisableFPSBoost() end end,
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
    Callback = function()
        safeCall(function() LocalPlayer.Character:BreakJoints() end)
        Notify("Reset", "Đã reset nhân vật", 2)
    end,
})

local SettingsTab = Window:Tab({ Title = "Settings", Icon = "settings" })

local SystemSection = SettingsTab:Section({ Title = "Hệ thống" })
SystemSection:Button({
    Title = "Unload (Xóa tất cả)",
    Callback = function()
        Settings.FlyEnabled = false
        Settings.NoClipEnabled = false
        Settings.ESPEnabled = false
        Settings.InfiniteJump = false
        Settings.AntiKnockback = false
        Settings.Wallhack = false
        Settings.Fullbright = false
        Settings.FPSBoost = false
        Settings.LowGraphics = false

        safeCall(function()
            if Settings.FlyBV then Settings.FlyBV:Destroy() end
            if Settings.FlyBG then Settings.FlyBG:Destroy() end
        end)
        safeCall(function()
            local char = LocalPlayer.Character
            if char then
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum then hum.PlatformStand = false end
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then part.CanCollide = true end
                end
            end
        end)
        for _, data in pairs(Settings.ESPBoxes) do
            for _, obj in ipairs(data) do
                if obj and obj.Destroy and typeof(obj) ~= "RBXScriptConnection" then
                    safeCall(function() obj:Destroy() end)
                end
            end
        end
        Settings.ESPBoxes = {}
        if Settings.ESPGui then Settings.ESPGui:Destroy(); Settings.ESPGui = nil end
        Lighting.Brightness = 1
        Lighting.FogEnd = 10000
        Lighting.GlobalShadows = true
        for _, o in ipairs(workspace:GetDescendants()) do
            if o:IsA("BasePart") then o.LocalTransparencyModifier = 0 end
        end
        safeCall(function() settings().Rendering.QualityLevel = 10 end)

        KillConnections()
        Window:Destroy()
    end,
})

Notify("Premium Hub", "Script đã sẵn sàng!", 5)