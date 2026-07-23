local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")
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

pcall(function() Window:Show() end)

local Settings = {
    FlyEnabled = false, FlySpeed = 50, FlyBV = nil, FlyBG = nil, FlyConn = nil,
    NoClipEnabled = false, NoClipConn = nil,
    InfiniteJump = false, InfJumpConn = nil, InfiniteJumpLastTime = 0,
    AntiKnockback = false, AntiKBConn = nil,
    ESPEnabled = false, ESPBoxes = {}, ESPGui = nil,
    Wallhack = false, WallhackConn = nil,
    Fullbright = false, FullbrightConn = nil,
    FPSBoost = false, LowGraphics = false,
    TeleportMark = nil, GifConnection = nil,
}

local Connections = {}
local function Hook(signal, callback) local c = signal:Connect(callback) table.insert(Connections, c) return c end
local function KillConnections() for i = #Connections, 1, -1 do local c = Connections[i] if c and c.Connected then c:Disconnect() end table.remove(Connections, i) end end
local function safeCall(f, ...) local s, r = pcall(f, ...) if not s then warn(r) end return s, r end
local function getChar() local c = LocalPlayer.Character if not c then LocalPlayer.CharacterAdded:Wait() c = LocalPlayer.Character end return c end
local function getHum() local c = getChar() local h = c:FindFirstChildOfClass("Humanoid") if not h then h = c:WaitForChild("Humanoid", 10) end return h end
local function getRoot() local c = getChar() local r = c:FindFirstChild("HumanoidRootPart") if not r then r = c:WaitForChild("HumanoidRootPart", 10) end return r end
local function Notify(title, content, duration) duration = duration or 3 safeCall(function() WindUI:Notify({Title = title, Content = content, Duration = duration}) end) end

local gifBackground = Instance.new("ImageLabel")
gifBackground.Name = "GifBackground"
gifBackground.Size = UDim2.new(1,0,1,0)
gifBackground.BackgroundTransparency = 1
gifBackground.ScaleType = Enum.ScaleType.Stretch
gifBackground.ZIndex = 0
if Window.UIElements.Main then gifBackground.Parent = Window.UIElements.Main end
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, Window.UICorner or 16)
corner.Parent = gifBackground

pcall(function()
    local GifDecoder = loadstring(game:HttpGet("https://raw.githubusercontent.com/richie0866/GifDecoder/main/Module.lua"))()
    local function playGif(url)
        local success, result = pcall(function()
            local resp = game:HttpGet(url)
            local data = GifDecoder.Decode(resp)
            local frames = data.Frames
            if #frames == 0 then error("no frames") end
            for i, f in ipairs(frames) do f.TextureId = "rbxassetid://" .. f.AssetId end
            return frames
        end)
        if not success then
            pcall(function()
                local resp = game:HttpGet(url)
                local data = GifDecoder.Decode(resp)
                if #data.Frames > 0 then gifBackground.Image = "rbxassetid://" .. data.Frames[1].AssetId end
            end)
            return
        end
        local frames = result
        local current = 1
        local total = #frames
        local elapsed = 0
        local conn = RunService.RenderStepped:Connect(function(dt)
            if not gifBackground.Parent then conn:Disconnect() return end
            elapsed = elapsed + dt
            if elapsed >= 0.05 then
                current = (current % total) + 1
                gifBackground.Image = frames[current].TextureId
                elapsed = 0
            end
        end)
        Settings.GifConnection = conn
    end
    playGif("https://cdn.discordapp.com/attachments/1233881531404124202/1525688210175430727/C92A5C7B-1B74-4A71-AD62-0075A31245A3.gif?ex=6a63749f&is=6a62231f&hm=e4e28c6a4e9daada020bd5e6da9168a74747dbf274b18a9d2823a2914b29cdcf&")
end)

local darkOverlay = Instance.new("Frame")
darkOverlay.Size = UDim2.new(1,0,1,0)
darkOverlay.BackgroundColor3 = Color3.fromRGB(0,0,0)
darkOverlay.BackgroundTransparency = 0.4
darkOverlay.ZIndex = 1
if Window.UIElements.Main then darkOverlay.Parent = Window.UIElements.Main end
local oc = Instance.new("UICorner")
oc.CornerRadius = UDim.new(0, Window.UICorner or 16)
oc.Parent = darkOverlay

local function EnableFly()
    if Settings.FlyEnabled then return end
    Settings.FlyEnabled = true
    local char = getChar()
    local hum = getHum()
    local root = getRoot()
    hum.PlatformStand = true
    local bv = Instance.new("BodyVelocity")
    bv.Name = "FlyVelocity"
    bv.Velocity = Vector3.zero
    bv.MaxForce = Vector3.new(400000,400000,400000)
    bv.Parent = root
    Settings.FlyBV = bv
    local bg = Instance.new("BodyGyro")
    bg.Name = "FlyGyro"
    bg.MaxTorque = Vector3.new(400000,400000,400000)
    bg.CFrame = Camera.CFrame
    bg.Parent = root
    Settings.FlyBG = bg
    local keys = {}
    Hook(UserInputService.InputBegan, function(inp, gp) if not gp then keys[inp.KeyCode] = true end end)
    Hook(UserInputService.InputEnded, function(inp) keys[inp.KeyCode] = false end)
    Settings.FlyConn = Hook(RunService.RenderStepped, function()
        if not Settings.FlyEnabled then return end
        if not Settings.FlyBV or not Settings.FlyBV.Parent then DisableFly() return end
        local dir = Vector3.zero
        if keys[Enum.KeyCode.W] then dir = dir + Camera.CFrame.LookVector end
        if keys[Enum.KeyCode.S] then dir = dir - Camera.CFrame.LookVector end
        if keys[Enum.KeyCode.A] then dir = dir - Camera.CFrame.RightVector end
        if keys[Enum.KeyCode.D] then dir = dir + Camera.CFrame.RightVector end
        if keys[Enum.KeyCode.Space] then dir = dir + Vector3.new(0,1,0) end
        if keys[Enum.KeyCode.LeftShift] then dir = dir - Vector3.new(0,1,0) end
        if dir.Magnitude > 0 then dir = dir.Unit * Settings.FlySpeed end
        bv.Velocity = dir
        bg.CFrame = Camera.CFrame
    end)
    Notify("Fly","On",2)
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
    Notify("Fly","Off",2)
end

local function EnableNoClip()
    if Settings.NoClipEnabled then return end
    Settings.NoClipEnabled = true
    Settings.NoClipConn = Hook(RunService.Stepped, function()
        if not Settings.NoClipEnabled then return end
        safeCall(function()
            local c = LocalPlayer.Character
            if not c then return end
            for _, p in ipairs(c:GetDescendants()) do if p:IsA("BasePart") and p.CanCollide then p.CanCollide = false end end
        end)
    end)
    Notify("NoClip","On",2)
end
local function DisableNoClip()
    Settings.NoClipEnabled = false
    if Settings.NoClipConn then Settings.NoClipConn:Disconnect(); Settings.NoClipConn = nil end
    safeCall(function()
        local c = LocalPlayer.Character
        if not c then return end
        for _, p in ipairs(c:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = true end end
    end)
    Notify("NoClip","Off",2)
end

local function EnableInfiniteJump()
    if Settings.InfiniteJump then return end
    Settings.InfiniteJump = true
    Settings.InfiniteJumpLastTime = 0
    Settings.InfJumpConn = Hook(UserInputService.JumpRequest, function()
        if not Settings.InfiniteJump then return end
        local now = tick()
        if now - Settings.InfiniteJumpLastTime < 0.1 then return end
        Settings.InfiniteJumpLastTime = now
        safeCall(function()
            local c = LocalPlayer.Character
            if not c then return end
            local h = c:FindFirstChildOfClass("Humanoid")
            if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
        end)
    end)
    Notify("Inf Jump","On",2)
end
local function DisableInfiniteJump()
    Settings.InfiniteJump = false
    if Settings.InfJumpConn then Settings.InfJumpConn:Disconnect(); Settings.InfJumpConn = nil end
    Notify("Inf Jump","Off",2)
end

local function EnableAntiKB()
    if Settings.AntiKnockback then return end
    Settings.AntiKnockback = true
    Settings.AntiKBConn = Hook(RunService.RenderStepped, function()
        if not Settings.AntiKnockback then return end
        safeCall(function()
            local c = LocalPlayer.Character
            if not c then return end
            for _, inst in ipairs(c:GetDescendants()) do
                if inst:IsA("BodyVelocity") and inst ~= Settings.FlyBV then inst:Destroy() end
                if inst:IsA("BodyPosition") then inst:Destroy() end
            end
        end)
    end)
    Notify("Anti KB","On",2)
end
local function DisableAntiKB()
    Settings.AntiKnockback = false
    if Settings.AntiKBConn then Settings.AntiKBConn:Disconnect(); Settings.AntiKBConn = nil end
    Notify("Anti KB","Off",2)
end

local function EnableESP()
    if Settings.ESPEnabled then return end
    Settings.ESPEnabled = true
    if Settings.ESPGui then Settings.ESPGui:Destroy() end
    local gui = Instance.new("ScreenGui")
    gui.Name = "ESPGui"
    gui.Parent = CoreGui
    gui.DisplayOrder = 999
    gui.ResetOnSpawn = false
    Settings.ESPGui = gui
    local function createESP(p)
        if p == LocalPlayer then return end
        local function setup()
            local c = p.Character
            if not c then return end
            local root = c:FindFirstChild("HumanoidRootPart") or c:FindFirstChild("Head")
            if not root then return end
            if Settings.ESPBoxes[p] then
                for _, obj in ipairs(Settings.ESPBoxes[p]) do
                    if obj and obj.Destroy and typeof(obj) ~= "RBXScriptConnection" then pcall(obj.Destroy, obj) end
                end
            end
            local box = Instance.new("Frame")
            box.BackgroundColor3 = Color3.fromRGB(139,92,246)
            box.BackgroundTransparency = 0.6
            box.BorderSizePixel = 0
            box.Parent = gui
            local boxCorner = Instance.new("UICorner")
            boxCorner.CornerRadius = UDim.new(0,3)
            boxCorner.Parent = box
            local boxStroke = Instance.new("UIStroke")
            boxStroke.Color = Color3.fromRGB(139,92,246)
            boxStroke.Thickness = 1.5
            boxStroke.Transparency = 0.3
            boxStroke.Parent = box
            local nameLabel = Instance.new("TextLabel")
            nameLabel.BackgroundTransparency = 1
            nameLabel.Text = p.Name
            nameLabel.TextColor3 = Color3.fromRGB(255,255,255)
            nameLabel.Font = Enum.Font.GothamBold
            nameLabel.TextSize = 11
            nameLabel.TextStrokeTransparency = 0.3
            nameLabel.Parent = gui
            local healthBg = Instance.new("Frame")
            healthBg.BackgroundColor3 = Color3.fromRGB(20,20,20)
            healthBg.BackgroundTransparency = 0.3
            healthBg.BorderSizePixel = 0
            healthBg.Parent = gui
            local hbgCorner = Instance.new("UICorner")
            hbgCorner.CornerRadius = UDim.new(0,2)
            hbgCorner.Parent = healthBg
            local healthFill = Instance.new("Frame")
            healthFill.BackgroundColor3 = Color3.fromRGB(50,200,100)
            healthFill.BorderSizePixel = 0
            healthFill.Parent = healthBg
            local hfCorner = Instance.new("UICorner")
            hfCorner.CornerRadius = UDim.new(0,2)
            hfCorner.Parent = healthFill
            local distLabel = Instance.new("TextLabel")
            distLabel.BackgroundTransparency = 1
            distLabel.TextColor3 = Color3.fromRGB(160,160,170)
            distLabel.Font = Enum.Font.Gotham
            distLabel.TextSize = 9
            distLabel.Parent = gui
            local conn = Hook(RunService.RenderStepped, function()
                if not Settings.ESPEnabled then
                    box.Visible = false; nameLabel.Visible = false; healthBg.Visible = false; distLabel.Visible = false
                    return
                end
                local curChar = p.Character
                if not curChar then box.Visible = false; nameLabel.Visible = false; healthBg.Visible = false; distLabel.Visible = false return end
                local curRoot = curChar:FindFirstChild("HumanoidRootPart") or curChar:FindFirstChild("Head")
                if not curRoot or not curRoot:IsDescendantOf(workspace) then
                    box.Visible = false; nameLabel.Visible = false; healthBg.Visible = false; distLabel.Visible = false
                    return
                end
                local pos, onScreen = Camera:WorldToViewportPoint(curRoot.Position)
                if not onScreen then
                    box.Visible = false; nameLabel.Visible = false; healthBg.Visible = false; distLabel.Visible = false
                    return
                end
                local hum = curChar:FindFirstChildOfClass("Humanoid")
                local depth = math.max(0.1, (Camera.CFrame.Position - curRoot.Position).Magnitude)
                local scale = math.clamp(200/depth, 1.5, 4)
                local size = curChar:GetExtentsSize()
                local w = math.clamp(size.X * scale, 30, 120)
                local h = math.clamp(size.Y * scale, 50, 180)
                box.Visible = true
                box.Size = UDim2.new(0,w,0,h)
                box.Position = UDim2.new(0, pos.X - w/2, 0, pos.Y - h/2)
                nameLabel.Visible = true
                nameLabel.Size = UDim2.new(0,120,0,16)
                nameLabel.Position = UDim2.new(0, pos.X - 60, 0, pos.Y - h/2 - 20)
                if hum then
                    local hp = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
                    healthFill.Size = UDim2.new(hp,0,1,0)
                    if hp > 0.6 then healthFill.BackgroundColor3 = Color3.fromRGB(50,200,100)
                    elseif hp > 0.3 then healthFill.BackgroundColor3 = Color3.fromRGB(255,180,50)
                    else healthFill.BackgroundColor3 = Color3.fromRGB(255,70,70) end
                end
                healthBg.Visible = true
                healthBg.Size = UDim2.new(0,w,0,4)
                healthBg.Position = UDim2.new(0, pos.X - w/2, 0, pos.Y + h/2 + 6)
                local loc = LocalPlayer.Character
                if loc then
                    local lr = loc:FindFirstChild("HumanoidRootPart")
                    if lr then
                        distLabel.Visible = true
                        distLabel.Size = UDim2.new(0,60,0,14)
                        distLabel.Position = UDim2.new(0, pos.X - 30, 0, pos.Y + h/2 + 14)
                        distLabel.Text = string.format("%.0f m", (lr.Position - curRoot.Position).Magnitude)
                    end
                end
                local enemy = p.Team and LocalPlayer.Team and p.Team ~= LocalPlayer.Team
                local col = enemy and Color3.fromRGB(255,70,70) or Color3.fromRGB(139,92,246)
                box.BackgroundColor3 = col
                boxStroke.Color = col
            end)
            Settings.ESPBoxes[p] = {box, nameLabel, healthBg, distLabel, conn}
        end
        if p.Character then setup() end
        Hook(p.CharacterAdded, function() task.wait(0.3); if Settings.ESPEnabled then setup() end end)
    end
    for _, p in ipairs(Players:GetPlayers()) do createESP(p) end
    Hook(Players.PlayerAdded, function(p) if Settings.ESPEnabled then createESP(p) end end)
    Hook(Players.PlayerRemoving, function(p)
        if Settings.ESPBoxes[p] then
            for _, obj in ipairs(Settings.ESPBoxes[p]) do
                if obj and obj.Destroy and typeof(obj) ~= "RBXScriptConnection" then pcall(obj.Destroy, obj) end
            end
            Settings.ESPBoxes[p] = nil
        end
    end)
    Notify("ESP","On",2)
end
local function DisableESP()
    Settings.ESPEnabled = false
    for p, data in pairs(Settings.ESPBoxes) do
        for _, obj in ipairs(data) do
            if obj and obj.Destroy and typeof(obj) ~= "RBXScriptConnection" then pcall(obj.Destroy, obj) end
        end
    end
    Settings.ESPBoxes = {}
    if Settings.ESPGui then Settings.ESPGui:Destroy(); Settings.ESPGui = nil end
    Notify("ESP","Off",2)
end

local function EnableWallhack()
    if Settings.Wallhack then return end
    Settings.Wallhack = true
    local function apply(obj)
        if obj:IsA("BasePart") and not obj.Parent:FindFirstChildOfClass("Humanoid") then
            obj.LocalTransparencyModifier = 0.6
        end
    end
    for _, obj in ipairs(workspace:GetDescendants()) do apply(obj) end
    Settings.WallhackConn = Hook(workspace.DescendantAdded, function(obj) if Settings.Wallhack then apply(obj) end end)
    Notify("Wallhack","On",2)
end
local function DisableWallhack()
    Settings.Wallhack = false
    if Settings.WallhackConn then Settings.WallhackConn:Disconnect(); Settings.WallhackConn = nil end
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") then obj.LocalTransparencyModifier = 0 end
    end
    Notify("Wallhack","Off",2)
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
    Notify("Fullbright","On",2)
end
local function DisableFullbright()
    Settings.Fullbright = false
    if Settings.FullbrightConn then Settings.FullbrightConn:Disconnect(); Settings.FullbrightConn = nil end
    Lighting.Brightness = 1
    Lighting.FogEnd = 10000
    Notify("Fullbright","Off",2)
end

local function EnableFPSBoost()
    Settings.FPSBoost = true
    safeCall(function() settings().Rendering.QualityLevel = 1 end)
    Notify("FPS Boost","On",2)
end
local function DisableFPSBoost()
    Settings.FPSBoost = false
    safeCall(function() settings().Rendering.QualityLevel = 10 end)
    Notify("FPS Boost","Off",2)
end

local function EnableLowGraphics()
    Settings.LowGraphics = true
    Lighting.GlobalShadows = false
    Lighting.FogEnd = 100
    Lighting.Brightness = 1
    Notify("Low Graphics","On",2)
end
local function DisableLowGraphics()
    Settings.LowGraphics = false
    Lighting.GlobalShadows = true
    Lighting.FogEnd = 10000
    Notify("Low Graphics","Off",2)
end

local function SetTeleportMark()
    safeCall(function() Settings.TeleportMark = getRoot().CFrame end)
    Notify("Mark","Set",2)
end
local function TeleportToMark()
    safeCall(function()
        if not Settings.TeleportMark then Notify("Error","No mark",2) return end
        getRoot().CFrame = Settings.TeleportMark
        Notify("Teleport","Done",2)
    end)
end
local function TeleportToNearestPlayer()
    safeCall(function()
        local root = getRoot()
        local nearest = nil
        local minDist = math.huge
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character then
                local r = p.Character:FindFirstChild("HumanoidRootPart")
                if r and r:IsDescendantOf(workspace) then
                    local d = (root.Position - r.Position).Magnitude
                    if d < minDist then minDist = d; nearest = r end
                end
            end
        end
        if nearest then root.CFrame = nearest.CFrame + Vector3.new(0,3,0); Notify("Teleport","Nearest player",2) end
    end)
end
local TreeCache = {}
local TreeCacheTimestamp = 0
local function FindNearestTree()
    local now = tick()
    if now - TreeCacheTimestamp < 2 and #TreeCache > 0 then
        local root = getRoot()
        local nearest = nil
        local minDist = math.huge
        for _, t in ipairs(TreeCache) do
            if t and t.Parent and t:IsDescendantOf(workspace) then
                local d = (root.Position - t.Position).Magnitude
                if d < minDist then minDist = d; nearest = t end
            end
        end
        if nearest then return nearest end
    end
    TreeCache = {}
    local root = getRoot()
    local nearest = nil
    local minDist = math.huge
    local wood = {[Enum.Material.Wood]=true, [Enum.Material.WoodPlanks]=true}
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and obj:IsDescendantOf(workspace) then
            local isTree = false
            local name = obj.Name:lower()
            if name:find("tree") or name:find("wood") or name:find("log") or name:find("oak") or name:find("pine") or name:find("birch") or name:find("maple") or name:find("palm") or name:find("bush") or name:find("plant") or name:find("trunk") then
                isTree = true
            elseif wood[obj.Material] then
                local parent = obj.Parent
                if parent and not parent:FindFirstChildOfClass("Humanoid") then
                    local pname = parent.Name:lower()
                    if pname:find("tree") or pname:find("wood") or pname:find("plant") or pname:find("bush") or pname:find("trunk") or pname:find("log") then isTree = true end
                end
            end
            if isTree and not obj.Parent:FindFirstChildOfClass("Humanoid") then
                table.insert(TreeCache, obj)
                local d = (root.Position - obj.Position).Magnitude
                if d < minDist then minDist = d; nearest = obj end
            end
        end
    end
    TreeCacheTimestamp = now
    return nearest
end
local function TeleportToNearestTree()
    safeCall(function()
        local tree = FindNearestTree()
        if tree then getRoot().CFrame = CFrame.new(tree.Position + Vector3.new(0,5,0)); Notify("Teleport","Nearest tree",2)
        else Notify("Error","No tree found",2) end
    end)
end

local function ResetCharacter()
    safeCall(function() local c = LocalPlayer.Character if c then c:BreakJoints() end end)
    Notify("Reset","Done",2)
end

local function UnloadAll()
    Settings.FlyEnabled = false; Settings.NoClipEnabled = false; Settings.ESPEnabled = false
    Settings.InfiniteJump = false; Settings.AntiKnockback = false; Settings.Wallhack = false
    Settings.Fullbright = false; Settings.FPSBoost = false; Settings.LowGraphics = false
    safeCall(function() if Settings.FlyBV then Settings.FlyBV:Destroy(); Settings.FlyBV = nil end; if Settings.FlyBG then Settings.FlyBG:Destroy(); Settings.FlyBG = nil end end)
    safeCall(function()
        local c = LocalPlayer.Character
        if c then
            local h = c:FindFirstChildOfClass("Humanoid") if h then h.PlatformStand = false end
            for _, p in ipairs(c:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = true end end
        end
    end)
    for p, data in pairs(Settings.ESPBoxes) do
        for _, obj in ipairs(data) do if obj and obj.Destroy and typeof(obj) ~= "RBXScriptConnection" then pcall(obj.Destroy, obj) end end
    end
    Settings.ESPBoxes = {}
    if Settings.ESPGui then Settings.ESPGui:Destroy(); Settings.ESPGui = nil end
    Lighting.Brightness = 1; Lighting.FogEnd = 10000; Lighting.GlobalShadows = true
    for _, obj in ipairs(workspace:GetDescendants()) do if obj:IsA("BasePart") then obj.LocalTransparencyModifier = 0 end end
    safeCall(function() settings().Rendering.QualityLevel = 10 end)
    TreeCache = {}
    if Settings.GifConnection then Settings.GifConnection:Disconnect(); Settings.GifConnection = nil end
    KillConnections()
    Window:Destroy()
end

local MainTab = Window:Tab({Title = "Main", Icon = "home"})
local FlySection = MainTab:Section({Title = "Bay (Fly)"})
FlySection:Toggle({Title = "Bật Bay", Value = false, Callback = function(s) if s then EnableFly() else DisableFly() end end})
FlySection:Slider({Title = "Tốc độ bay", Step = 1, Value = {Min=20, Max=300, Default=50}, Callback = function(v) Settings.FlySpeed = v end})

local MoveSection = MainTab:Section({Title = "Di chuyển"})
MoveSection:Slider({Title = "Tốc độ", Step = 1, Value = {Min=16, Max=300, Default=16}, Callback = function(v) safeCall(function() getHum().WalkSpeed = v end) end})
MoveSection:Slider({Title = "Sức nhảy", Step = 1, Value = {Min=50, Max=500, Default=50}, Callback = function(v) safeCall(function() getHum().JumpPower = v end) end})
MoveSection:Toggle({Title = "NoClip (Xuyên tường)", Value = false, Callback = function(s) if s then EnableNoClip() else DisableNoClip() end end})

local PlayerTab = Window:Tab({Title = "Player", Icon = "user"})
local PlayerSection = PlayerTab:Section({Title = "Nhân vật"})
PlayerSection:Toggle({Title = "Nhảy vô hạn", Value = false, Callback = function(s) if s then EnableInfiniteJump() else DisableInfiniteJump() end end})
PlayerSection:Toggle({Title = "Anti Knockback", Value = false, Callback = function(s) if s then EnableAntiKB() else DisableAntiKB() end end})
PlayerSection:Slider({Title = "FOV", Step = 1, Value = {Min=30, Max=120, Default=70}, Callback = function(v) Camera.FieldOfView = v end})

local VisualTab = Window:Tab({Title = "Visual", Icon = "eye"})
local ESPSection = VisualTab:Section({Title = "ESP"})
ESPSection:Toggle({Title = "Bật ESP", Value = false, Callback = function(s) if s then EnableESP() else DisableESP() end end})
local WorldSection = VisualTab:Section({Title = "Thế giới"})
WorldSection:Toggle({Title = "Wallhack", Value = false, Callback = function(s) if s then EnableWallhack() else DisableWallhack() end end})
WorldSection:Toggle({Title = "Fullbright", Value = false, Callback = function(s) if s then EnableFullbright() else DisableFullbright() end end})
WorldSection:Toggle({Title = "Đồ họa thấp", Value = false, Callback = function(s) if s then EnableLowGraphics() else DisableLowGraphics() end end})
WorldSection:Toggle({Title = "FPS Boost", Value = false, Callback = function(s) if s then EnableFPSBoost() else DisableFPSBoost() end end})

local TeleportTab = Window:Tab({Title = "Teleport", Icon = "move"})
local MarkSection = TeleportTab:Section({Title = "Đánh dấu"})
MarkSection:Button({Title = "Đặt điểm", Callback = SetTeleportMark})
MarkSection:Button({Title = "Dịch chuyển về", Callback = TeleportToMark})
local TeleportSection = TeleportTab:Section({Title = "Dịch chuyển nhanh"})
TeleportSection:Button({Title = "Đến cây gần nhất", Callback = TeleportToNearestTree})
TeleportSection:Button({Title = "Đến người chơi gần nhất", Callback = TeleportToNearestPlayer})

local MiscTab = Window:Tab({Title = "Misc", Icon = "settings"})
local MiscSection = MiscTab:Section({Title = "Tiện ích"})
MiscSection:Button({Title = "Reset nhân vật", Callback = ResetCharacter})

local SettingsTab = Window:Tab({Title = "Settings", Icon = "settings"})
local SystemSection = SettingsTab:Section({Title = "Hệ thống"})
SystemSection:Button({Title = "Unload (Xóa tất cả)", Callback = UnloadAll})

Notify("Premium Hub","Script ready!",5)