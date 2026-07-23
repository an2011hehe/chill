local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/source.lua"))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

task.wait(0.5)

local Window = WindUI:CreateWindow({
    Title = "Premium Hub",
    Folder = "PremiumHub",
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
    ESPConnections = {},
    ESPGui = nil,
    Wallhack = false,
    Fullbright = false,
    FPSBoost = false,
    LowGraphics = false,
    TeleportMark = nil,
}

local function safe(f, ...) return pcall(f, ...) end
local function getChar() local c = LocalPlayer.Character; if not c then c = LocalPlayer.CharacterAdded:Wait() end; return c end
local function getHum() return getChar():WaitForChild("Humanoid") end
local function getRoot() local c = getChar(); return c:FindFirstChild("HumanoidRootPart") or c:WaitForChild("HumanoidRootPart") end

local Connections = {}
local function Hook(s, f) local c = s:Connect(f); table.insert(Connections, c); return c end

local function KillAll()
    for _, c in ipairs(Connections) do
        if c and c.Connected then c:Disconnect() end
    end
    Connections = {}
end

local function EnableFly()
    if Settings.FlyEnabled then return end
    Settings.FlyEnabled = true
    local char = getChar()
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
    Hook(UserInputService.InputBegan, function(input, gpe) if not gpe then keysDown[input.KeyCode] = true end end)
    Hook(UserInputService.InputEnded, function(input) keysDown[input.KeyCode] = false end)

    Settings.FlyConn = Hook(RunService.RenderStepped, function()
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
    safe(function()
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
            LocalPlayer.Character.Humanoid.PlatformStand = false
        end
        if Settings.FlyBV then Settings.FlyBV:Destroy(); Settings.FlyBV = nil end
        if Settings.FlyBG then Settings.FlyBG:Destroy(); Settings.FlyBG = nil end
        if Settings.FlyConn then Settings.FlyConn:Disconnect(); Settings.FlyConn = nil end
    end)
end

local function EnableNoClip()
    if Settings.NoClipEnabled then return end
    Settings.NoClipEnabled = true
    Settings.NoClipConn = Hook(RunService.Stepped, function()
        if not Settings.NoClipEnabled then return end
        safe(function()
            local char = LocalPlayer.Character
            if char then
                for _, p in ipairs(char:GetDescendants()) do
                    if p:IsA("BasePart") and p.CanCollide then p.CanCollide = false end
                end
            end
        end)
    end)
end

local function DisableNoClip()
    Settings.NoClipEnabled = false
    if Settings.NoClipConn then Settings.NoClipConn:Disconnect(); Settings.NoClipConn = nil end
    safe(function()
        local char = LocalPlayer.Character
        if char then
            for _, p in ipairs(char:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide = true end
            end
        end
    end)
end

local function EnableESP()
    if Settings.ESPEnabled then return end
    Settings.ESPEnabled = true

    local CoreGui = game:GetService("CoreGui")
    if Settings.ESPGui then Settings.ESPGui:Destroy() end
    local ESPGui = Instance.new("ScreenGui")
    ESPGui.Name = "ESPGui"
    ESPGui.Parent = CoreGui
    ESPGui.DisplayOrder = 999
    ESPGui.Enabled = true
    Settings.ESPGui = ESPGui

    local function createESP(player)
        if player == LocalPlayer then return end
        if Settings.ESPBoxes[player] then return end

        local char = player.Character
        if not char then char = player.CharacterAdded:Wait() end

        local root = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Head")
        if not root then root = char:WaitForChild("HumanoidRootPart") end

        local box = Instance.new("Frame")
        box.Size = UDim2.new(0, 0, 0, 0)
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
        nameLabel.Size = UDim2.new(0, 120, 0, 16)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = player.Name
        nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.TextSize = 11
        nameLabel.TextStrokeTransparency = 0.3
        nameLabel.Parent = ESPGui

        local healthBg = Instance.new("Frame")
        healthBg.Size = UDim2.new(0, 60, 0, 4)
        healthBg.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
        healthBg.BackgroundTransparency = 0.3
        healthBg.BorderSizePixel = 0
        healthBg.Parent = ESPGui
        Instance.new("UICorner", healthBg).CornerRadius = UDim.new(0, 2)

        local healthFill = Instance.new("Frame")
        healthFill.Size = UDim2.new(1, 0, 1, 0)
        healthFill.BackgroundColor3 = Color3.fromRGB(50, 200, 100)
        healthFill.BorderSizePixel = 0
        healthFill.Parent = healthBg
        Instance.new("UICorner", healthFill).CornerRadius = UDim.new(0, 2)

        local distLabel = Instance.new("TextLabel")
        distLabel.Size = UDim2.new(0, 60, 0, 14)
        distLabel.BackgroundTransparency = 1
        distLabel.Text = ""
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
            if not currentRoot then
                box.Visible = false; nameLabel.Visible = false
                healthBg.Visible = false; distLabel.Visible = false
                return
            end

            local pos, onScreen = Camera:WorldToViewportPoint(currentRoot.Position)
            if onScreen then
                local hum = currentChar:FindFirstChildOfClass("Humanoid")
                local depth = math.max(0.1, (Camera.CFrame.Position - currentRoot.Position).Magnitude)
                local scaleFactor = math.clamp(200 / depth, 1.5, 4)
                local modelSize = currentChar:GetExtentsSize()
                local width = math.clamp(modelSize.X * scaleFactor, 30, 120)
                local height = math.clamp(modelSize.Y * scaleFactor, 50, 180)

                box.Visible = true
                box.Size = UDim2.new(0, width, 0, height)
                box.Position = UDim2.new(0, pos.X - width / 2, 0, pos.Y - height / 2)

                nameLabel.Visible = true
                nameLabel.Position = UDim2.new(0, pos.X - 60, 0, pos.Y - height / 2 - 20)
                nameLabel.Text = player.Name

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
                        distLabel.Text = string.format("%.0f m", (localRoot.Position - currentRoot.Position).Magnitude)
                    end
                end

                distLabel.Visible = true
                distLabel.Position = UDim2.new(0, pos.X - 30, 0, pos.Y + height / 2 + 14)

                local isEnemy = player.Team and LocalPlayer.Team and player.Team ~= LocalPlayer.Team
                local color = isEnemy and Color3.fromRGB(255, 70, 70) or Color3.fromRGB(139, 92, 246)
                box.BackgroundColor3 = color
                stroke.Color = color
            else
                box.Visible = false; nameLabel.Visible = false
                healthBg.Visible = false; distLabel.Visible = false
            end
        end)

        Settings.ESPBoxes[player] = {box, nameLabel, healthBg, distLabel, conn}
        table.insert(Settings.ESPConnections, conn)
    end

    for _, p in ipairs(Players:GetPlayers()) do createESP(p) end

    Hook(Players.PlayerAdded, function(p)
        if Settings.ESPEnabled then
            p.CharacterAdded:Connect(function()
                task.wait(0.3)
                createESP(p)
            end)
        end
    end)

    Hook(Players.PlayerRemoving, function(p)
        if Settings.ESPBoxes[p] then
            for _, obj in ipairs(Settings.ESPBoxes[p]) do
                if obj and obj.Destroy and typeof(obj) ~= "RBXScriptConnection" then
                    safe(function() obj:Destroy() end)
                end
            end
            Settings.ESPBoxes[p] = nil
        end
    end)
end

local function DisableESP()
    Settings.ESPEnabled = false
    for _, conn in ipairs(Settings.ESPConnections) do
        if conn and conn.Connected then conn:Disconnect() end
    end
    Settings.ESPConnections = {}
    for _, data in pairs(Settings.ESPBoxes) do
        for _, obj in ipairs(data) do
            if obj and obj.Destroy and typeof(obj) ~= "RBXScriptConnection" then
                safe(function() obj:Destroy() end)
            end
        end
    end
    Settings.ESPBoxes = {}
    if Settings.ESPGui then Settings.ESPGui:Destroy(); Settings.ESPGui = nil end
end

local function EnableAntiKB()
    if Settings.AntiKnockback then return end
    Settings.AntiKnockback = true
    Settings.AntiKBConn = Hook(RunService.RenderStepped, function()
        if not Settings.AntiKnockback then return end
        safe(function()
            local char = LocalPlayer.Character
            if not char then return end
            for _, v in ipairs(char:GetDescendants()) do
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

local function EnableFPSBoost()
    Settings.FPSBoost = true
    safe(function()
        settings().Rendering.QualityLevel = 1
        settings().Rendering.MeshPartDetailLevel = Enum.MeshPartDetailLevel.Level01
    end)
end

local function DisableFPSBoost()
    Settings.FPSBoost = false
    safe(function()
        settings().Rendering.QualityLevel = 10
        settings().Rendering.MeshPartDetailLevel = Enum.MeshPartDetailLevel.Level04
    end)
end

local function EnableLowGraphics()
    Settings.LowGraphics = true
    Lighting.GlobalShadows = false
    Lighting.FogEnd = 100
    Lighting.Brightness = 1
    safe(function() settings().Rendering.QualityLevel = 1 end)
end

local function DisableLowGraphics()
    Settings.LowGraphics = false
    Lighting.GlobalShadows = true
    Lighting.FogEnd = 10000
    safe(function() settings().Rendering.QualityLevel = 10 end)
end

local function SetTeleportMark()
    safe(function() Settings.TeleportMark = getRoot().CFrame end)
end

local function TeleportToMark()
    safe(function()
        if Settings.TeleportMark then getRoot().CFrame = Settings.TeleportMark end
    end)
end

local function TeleportToNearestPlayer()
    safe(function()
        local root = getRoot()
        local nearest, minDist = nil, math.huge
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character then
                local tr = p.Character:FindFirstChild("HumanoidRootPart")
                if tr then
                    local d = (root.Position - tr.Position).Magnitude
                    if d < minDist then minDist = d; nearest = tr end
                end
            end
        end
        if nearest then root.CFrame = nearest.CFrame + Vector3.new(0, 3, 0) end
    end)
end

local function FindNearestTree()
    local root = getRoot()
    local nearestTree = nil
    local minDist = math.huge
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and (obj.Name:lower():find("tree") or obj.Name:lower():find("wood") or obj.Name:lower():find("log") or obj.Material == Enum.Material.Wood or obj.Material == Enum.Material.WoodPlanks) then
            if not obj.Parent:FindFirstChildOfClass("Humanoid") then
                local dist = (root.Position - obj.Position).Magnitude
                if dist < minDist then minDist = dist; nearestTree = obj end
            end
        end
    end
    return nearestTree
end

local function TeleportToNearestTree()
    safe(function()
        local tree = FindNearestTree()
        if tree then getRoot().CFrame = CFrame.new(tree.Position + Vector3.new(0, 5, 0)) end
    end)
end

local MainTab = Window:Tab({ Title = "Main" })
MainTab:Section({ Title = "✈️ Bay (Fly)" })
MainTab:Toggle({ Title = "Bật Bay", Default = false, Callback = function(v) if v then EnableFly() else DisableFly() end end })
MainTab:Slider({ Title = "Tốc độ bay", Min = 20, Max = 300, Default = 50, Callback = function(v) Settings.FlySpeed = v end })
MainTab:Section({ Title = "🚶 Di chuyển" })
MainTab:Slider({ Title = "Tốc độ đi bộ", Min = 16, Max = 300, Default = 16, Callback = function(v) safe(function() getHum().WalkSpeed = v end) end })
MainTab:Slider({ Title = "Sức nhảy", Min = 50, Max = 500, Default = 50, Callback = function(v) safe(function() getHum().JumpPower = v end) end })
MainTab:Toggle({ Title = "Xuyên tường (NoClip)", Default = false, Callback = function(v) if v then EnableNoClip() else DisableNoClip() end end })

local PlayerTab = Window:Tab({ Title = "Player" })
PlayerTab:Section({ Title = "👤 Nhân vật" })
PlayerTab:Toggle({ Title = "Nhảy vô hạn", Default = false, Callback = function(v)
    Settings.InfiniteJump = v
    if v then
        if Settings.InfJumpConn then Settings.InfJumpConn:Disconnect() end
        Settings.InfJumpConn = Hook(UserInputService.JumpRequest, function() safe(function() getHum():ChangeState(Enum.HumanoidStateType.Jumping) end) end)
    else
        if Settings.InfJumpConn then Settings.InfJumpConn:Disconnect(); Settings.InfJumpConn = nil end
    end
end })
PlayerTab:Toggle({ Title = "Không bị đẩy lùi", Default = false, Callback = function(v) if v then EnableAntiKB() else DisableAntiKB() end end })
PlayerTab:Slider({ Title = "FOV", Min = 30, Max = 120, Default = 70, Callback = function(v) Camera.FieldOfView = v end })

local VisualTab = Window:Tab({ Title = "Visual" })
VisualTab:Section({ Title = "👁️ ESP" })
VisualTab:Toggle({ Title = "Bật ESP", Default = false, Callback = function(v) if v then EnableESP() else DisableESP() end end })
VisualTab:Section({ Title = "🌍 Thế giới" })
VisualTab:Toggle({ Title = "Xuyên tường (Wallhack)", Default = false, Callback = function(v)
    Settings.Wallhack = v
    for _, o in ipairs(workspace:GetDescendants()) do
        if o:IsA("BasePart") and not o.Parent:FindFirstChildOfClass("Humanoid") then o.LocalTransparencyModifier = v and 0.6 or 0 end
    end
end })
VisualTab:Toggle({ Title = "Đèn nền (Fullbright)", Default = false, Callback = function(v)
    Settings.Fullbright = v
    Lighting.Brightness = v and 2 or 1; Lighting.ClockTime = 14; Lighting.FogEnd = v and 100000 or 10000
end })
VisualTab:Toggle({ Title = "Đồ họa thấp", Default = false, Callback = function(v) if v then EnableLowGraphics() else DisableLowGraphics() end end })
VisualTab:Toggle({ Title = "FPS Boost", Default = false, Callback = function(v) if v then EnableFPSBoost() else DisableFPSBoost() end end })

local TeleportTab = Window:Tab({ Title = "Teleport" })
TeleportTab:Section({ Title = "📌 Đánh dấu" })
TeleportTab:Button({ Title = "📌 Đặt điểm dịch chuyển", Callback = SetTeleportMark })
TeleportTab:Button({ Title = "🌀 Dịch chuyển về điểm đã đặt", Callback = TeleportToMark })
TeleportTab:Section({ Title = "🌲 Cây" })
TeleportTab:Button({ Title = "🌳 Bay đến cây gần nhất", Callback = TeleportToNearestTree })
TeleportTab:Section({ Title = "👤 Người chơi" })
TeleportTab:Button({ Title = "👤 Bay đến người chơi gần nhất", Callback = TeleportToNearestPlayer })

local MiscTab = Window:Tab({ Title = "Misc" })
MiscTab:Section({ Title = "🎯 Tiện ích" })
MiscTab:Button({ Title = "Reset nhân vật", Callback = function() safe(function() LocalPlayer.Character:BreakJoints() end) end })

local SettingsTab = Window:Tab({ Title = "Settings" })
SettingsTab:Section({ Title = "🔧 Hệ thống" })
SettingsTab:Button({ Title = "Hủy giao diện (Unload)", Callback = function()
    DisableFly(); DisableNoClip(); DisableESP(); DisableAntiKB()
    DisableFPSBoost(); DisableLowGraphics()
    KillAll()
    if Settings.ESPGui then Settings.ESPGui:Destroy() end
    Window:Destroy()
end })