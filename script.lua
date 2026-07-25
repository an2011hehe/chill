local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

if not game:IsLoaded() then game.Loaded:Wait() end

repeat task.wait() until LocalPlayer and LocalPlayer.Character
repeat task.wait() until LocalPlayer.Character:FindFirstChild("HumanoidRootPart")

local Window = WindUI:CreateWindow({
    Title = "PREMIUM HUB PRO",
    Icon = "star",
    Author = "by Kenrser",
    Folder = "PremiumHubPro",
    Theme = "Dark",
    Size = UDim2.fromOffset(620, 520),
})

local Settings = {
    FlyEnabled = false, FlySpeed = 50, FlyBV = nil, FlyBG = nil, FlyConn = nil,
    NoClipEnabled = false, NoClipConn = nil,
    InfiniteJump = false, InfJumpConn = nil, InfiniteJumpLastTime = 0,
    AntiKnockback = false, AntiKBConn = nil,
    ESPEnabled = false, ESPBoxes = {}, ESPGui = nil,
    Wallhack = false, WallhackConn = nil,
    Fullbright = false, FullbrightConn = nil,
    FPSBoost = false, LowGraphics = false,
    TeleportMark = nil,
    AimbotEnabled = false, AimbotSmoothness = 0.5, AimbotConn = nil,
    ESPHighlight = true, ESPTracer = true,
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

local function Notify(title, content, duration)
    duration = duration or 3
    safeCall(function()
        WindUI:Notify({ Title = title, Content = content, Duration = duration })
    end)
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

task.wait(0.3)

local mainFrame = nil
local screenGui = CoreGui:FindFirstChild("PremiumHubPro") or CoreGui:FindFirstChild("WindUI")

if screenGui then
    local allDescendants = screenGui:GetDescendants()
    for _, child in ipairs(allDescendants) do
        if child:IsA("Frame") and (child.Name == "Main" or child.Name == "Container" or child.Name == "Window") then
            if child.AbsoluteSize.X > 100 and child.AbsoluteSize.Y > 100 then
                mainFrame = child
                break
            end
        end
    end
end

if not mainFrame and screenGui then
    local allFrames = {}
    for _, child in ipairs(screenGui:GetDescendants()) do
        if child:IsA("Frame") then
            table.insert(allFrames, child)
        end
    end
    if #allFrames > 0 then
        table.sort(allFrames, function(a, b)
            return a.AbsoluteSize.X * a.AbsoluteSize.Y > b.AbsoluteSize.X * b.AbsoluteSize.Y
        end)
        mainFrame = allFrames[1]
    end
end

if mainFrame then
    local existingBg = mainFrame:FindFirstChild("BackgroundImage")
    if existingBg then existingBg:Destroy() end
    local existingOverlay = mainFrame:FindFirstChild("DarkOverlay")
    if existingOverlay then existingOverlay:Destroy() end

    local bgImage = Instance.new("ImageLabel")
    bgImage.Name = "BackgroundImage"
    bgImage.Size = UDim2.new(1, 0, 1, 0)
    bgImage.Position = UDim2.new(0, 0, 0, 0)
    bgImage.BackgroundTransparency = 1
    bgImage.Image = "https://i.postimg.cc/1VqBhycD/background.jpg"
    bgImage.ScaleType = Enum.ScaleType.Crop
    bgImage.ZIndex = 0
    bgImage.Parent = mainFrame

    local bgCorner = Instance.new("UICorner")
    bgCorner.CornerRadius = UDim.new(0, 16)
    bgCorner.Parent = bgImage

    local darkOverlay = Instance.new("Frame")
    darkOverlay.Name = "DarkOverlay"
    darkOverlay.Size = UDim2.new(1, 0, 1, 0)
    darkOverlay.Position = UDim2.new(0, 0, 0, 0)
    darkOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    darkOverlay.BackgroundTransparency = 0.4
    darkOverlay.BorderSizePixel = 0
    darkOverlay.ZIndex = 1
    darkOverlay.Parent = mainFrame

    local overlayCorner = Instance.new("UICorner")
    overlayCorner.CornerRadius = UDim.new(0, 16)
    overlayCorner.Parent = darkOverlay
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
    Notify("Fly", "Đã bật bay!", 2)
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
    Notify("Fly", "Đã tắt bay!", 2)
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
    Notify("NoClip", "Đã bật NoClip", 2)
end

local function DisableNoClip()
    Settings.NoClipEnabled = false
    if Settings.NoClipConn then Settings.NoClipConn:Disconnect(); Settings.NoClipConn = nil end
    safeCall(function()
        local c = LocalPlayer.Character; if not c then return end
        local d = c:GetDescendants()
        for i = 1, #d do local p = d[i] if p:IsA("BasePart") then p.CanCollide = true end end
    end)
    Notify("NoClip", "Đã tắt NoClip", 2)
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
    Notify("Nhảy vô hạn", "Đã bật", 2)
end

local function DisableInfiniteJump()
    Settings.InfiniteJump = false
    if Settings.InfJumpConn then Settings.InfJumpConn:Disconnect(); Settings.InfJumpConn = nil end
    Notify("Nhảy vô hạn", "Đã tắt", 2)
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
    Notify("Anti KB", "Đã bật chống đẩy lùi", 2)
end

local function DisableAntiKB()
    Settings.AntiKnockback = false
    if Settings.AntiKBConn then Settings.AntiKBConn:Disconnect(); Settings.AntiKBConn = nil end
    Notify("Anti KB", "Đã tắt chống đẩy lùi", 2)
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
    Notify("Aimbot", "Đã bật", 2)
end

local function DisableAimbot()
    Settings.AimbotEnabled = false
    if Settings.AimbotConn then Settings.AimbotConn:Disconnect(); Settings.AimbotConn = nil end
    Notify("Aimbot", "Đã tắt", 2)
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
    Notify("ESP", "Đã bật ESP", 2)
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
    Notify("ESP", "Đã tắt ESP", 2)
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
    Notify("Wallhack", "Đã bật nhìn xuyên tường", 2)
end

local function DisableWallhack()
    Settings.Wallhack = false
    if Settings.WallhackConn then Settings.WallhackConn:Disconnect(); Settings.WallhackConn = nil end
    local ao = workspace:GetDescendants()
    for i = 1, #ao do local o = ao[i] if o:IsA("BasePart") then o.LocalTransparencyModifier = 0 end end
    Notify("Wallhack", "Đã tắt nhìn xuyên tường", 2)
end

local function EnableFullbright()
    if Settings.Fullbright then return end
    Settings.Fullbright = true
    Lighting.Brightness = 2; Lighting.ClockTime = 14; Lighting.FogEnd = 100000
    Settings.FullbrightConn = Hook(Lighting:GetPropertyChangedSignal("Brightness"), function()
        if Settings.Fullbright and Lighting.Brightness ~= 2 then Lighting.Brightness = 2 end
    end)
    Notify("Fullbright", "Đã bật đèn nền", 2)
end

local function DisableFullbright()
    Settings.Fullbright = false
    if Settings.FullbrightConn then Settings.FullbrightConn:Disconnect(); Settings.FullbrightConn = nil end
    Lighting.Brightness = 1; Lighting.FogEnd = 10000
    Notify("Fullbright", "Đã tắt đèn nền", 2)
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
    Lighting.GlobalShadows = false; Lighting.FogEnd = 100; Lighting.Brightness = 1
    Notify("Đồ họa", "Đã bật đồ họa thấp", 2)
end

local function DisableLowGraphics()
    Settings.LowGraphics = false
    Lighting.GlobalShadows = true; Lighting.FogEnd = 10000
    Notify("Đồ họa", "Đã khôi phục đồ họa", 2)
end

local function SetTeleportMark()
    safeCall(function()
        local r = getRoot()
        Settings.TeleportMark = r.CFrame
    end)
    Notify("Đánh dấu", "Đã đặt điểm dịch chuyển", 2)
end

local function TeleportToMark()
    safeCall(function()
        if not Settings.TeleportMark then Notify("Lỗi", "Chưa đặt điểm đánh dấu", 2); return end
        local r = getRoot(); r.CFrame = Settings.TeleportMark
        Notify("Dịch chuyển", "Đã về điểm đánh dấu", 2)
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
        if nr then r.CFrame = nr.CFrame + Vector3.new(0, 3, 0); Notify("Dịch chuyển", "Đến người chơi gần nhất", 2) end
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
            Notify("Dịch chuyển", "Đến cây gần nhất", 2)
        else Notify("Lỗi", "Không tìm thấy cây trong phạm vi 500m", 2) end
    end)
end

local function ResetCharacter()
    safeCall(function()
        local c = LocalPlayer.Character; if c then c:BreakJoints() end
    end)
    Notify("Reset", "Đã reset nhân vật", 2)
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
    Window:Destroy()
end

local MainTab = Window:Tab({ Title = "Main", Icon = "home" })
local FlySection = MainTab:Section({ Title = "Bay (Fly)" })
FlySection:Toggle({ Title = "Bật Bay", Value = false, Callback = function(s) if s then EnableFly() else DisableFly() end end })
FlySection:Slider({ Title = "Tốc độ bay", Step = 1, Value = { Min = 20, Max = 300, Default = 50 }, Callback = function(v) Settings.FlySpeed = v end })

local MoveSection = MainTab:Section({ Title = "Di chuyển" })
MoveSection:Slider({ Title = "Tốc độ", Step = 1, Value = { Min = 16, Max = 300, Default = 16 }, Callback = function(v) safeCall(function() getHum().WalkSpeed = v end) end })
MoveSection:Slider({ Title = "Sức nhảy", Step = 1, Value = { Min = 50, Max = 500, Default = 50 }, Callback = function(v) safeCall(function() getHum().JumpPower = v end) end })
MoveSection:Toggle({ Title = "NoClip (Xuyên tường)", Value = false, Callback = function(s) if s then EnableNoClip() else DisableNoClip() end end })

local PlayerTab = Window:Tab({ Title = "Player", Icon = "user" })
local PlayerSection = PlayerTab:Section({ Title = "Nhân vật" })
PlayerSection:Toggle({ Title = "Nhảy vô hạn", Value = false, Callback = function(s) if s then EnableInfiniteJump() else DisableInfiniteJump() end end })
PlayerSection:Toggle({ Title = "Anti Knockback", Value = false, Callback = function(s) if s then EnableAntiKB() else DisableAntiKB() end end })
PlayerSection:Slider({ Title = "FOV (Trường nhìn)", Step = 1, Value = { Min = 30, Max = 120, Default = 70 }, Callback = function(v) Camera.FieldOfView = v end })

local AimbotTab = Window:Tab({ Title = "Aimbot", Icon = "crosshair" })
local AimbotSection = AimbotTab:Section({ Title = "Cài đặt Aimbot" })
AimbotSection:Toggle({ Title = "Bật Aimbot", Value = false, Callback = function(s) if s then EnableAimbot() else DisableAimbot() end end })
AimbotSection:Slider({ Title = "Độ mượt", Step = 0.05, Value = { Min = 0.1, Max = 1.0, Default = 0.5 }, Callback = function(v) Settings.AimbotSmoothness = v end })

local VisualTab = Window:Tab({ Title = "Visual", Icon = "eye" })
local ESPSection = VisualTab:Section({ Title = "ESP Pro" })
ESPSection:Toggle({ Title = "Bật ESP", Value = false, Callback = function(s) if s then EnableESP() else DisableESP() end end })
ESPSection:Toggle({ Title = "Highlight", Value = true, Callback = function(s) Settings.ESPHighlight = s end })
ESPSection:Toggle({ Title = "Tracer", Value = true, Callback = function(s) Settings.ESPTracer = s end })

local WorldSection = VisualTab:Section({ Title = "Thế giới" })
WorldSection:Toggle({ Title = "Wallhack", Value = false, Callback = function(s) if s then EnableWallhack() else DisableWallhack() end end })
WorldSection:Toggle({ Title = "Fullbright", Value = false, Callback = function(s) if s then EnableFullbright() else DisableFullbright() end end })
WorldSection:Toggle({ Title = "Đồ họa thấp", Value = false, Callback = function(s) if s then EnableLowGraphics() else DisableLowGraphics() end end })
WorldSection:Toggle({ Title = "FPS Boost", Value = false, Callback = function(s) if s then EnableFPSBoost() else DisableFPSBoost() end end })

local TeleportTab = Window:Tab({ Title = "Teleport", Icon = "move" })
local MarkSection = TeleportTab:Section({ Title = "Đánh dấu" })
MarkSection:Button({ Title = "Đặt điểm", Callback = SetTeleportMark })
MarkSection:Button({ Title = "Dịch chuyển về", Callback = TeleportToMark })
MarkSection:Button({ Title = "Đến cây gần nhất", Callback = TeleportToNearestTree })
MarkSection:Button({ Title = "Đến người chơi gần nhất", Callback = TeleportToNearestPlayer })

local MiscTab = Window:Tab({ Title = "Misc", Icon = "settings" })
local MiscSection = MiscTab:Section({ Title = "Tiện ích" })
MiscSection:Button({ Title = "Reset nhân vật", Callback = ResetCharacter })

local SettingsTab = Window:Tab({ Title = "Settings", Icon = "settings" })
local SystemSection = SettingsTab:Section({ Title = "Hệ thống" })
SystemSection:Button({ Title = "Unload (Xóa tất cả)", Callback = UnloadAll })

Notify("PREMIUM HUB PRO", "Đã sẵn sàng!", 3)