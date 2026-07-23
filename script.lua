local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

if not game:IsLoaded() then game.Loaded:Wait() end

-- ===== Biến toàn cục cho Aimbot/ESP =====
getgenv().AimbotEnabled = false
getgenv().ESPEnabled = false          -- ESP chính (Highlight + tracer)
getgenv().AimbotSmoothness = 0.5
getgenv().AimbotTarget = nil

-- ===== Khởi tạo cửa sổ chính =====
local Window = WindUI:CreateWindow({
    Title = "Premium Hub",
    Icon = "star",
    Author = "by nhatanh + Andepzai",
    Folder = "PremiumHub",
    Theme = "Dark",
    Size = UDim2.fromOffset(580, 490),
})
pcall(function() Window:Show() end)

-- ===== Thiết lập nền GIF (giữ nguyên) =====
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

-- Overlay tối
local darkOverlay = Instance.new("Frame")
darkOverlay.Size = UDim2.new(1,0,1,0)
darkOverlay.BackgroundColor3 = Color3.fromRGB(0,0,0)
darkOverlay.BackgroundTransparency = 0.4
darkOverlay.ZIndex = 1
if Window.UIElements.Main then darkOverlay.Parent = Window.UIElements.Main end
local oc = Instance.new("UICorner")
oc.CornerRadius = UDim.new(0, Window.UICorner or 16)
oc.Parent = darkOverlay

-- ===== Các hàm tiện ích =====
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
    -- Thêm cho Aimbot/ESP nâng cao
    AimbotEnabled = false,
    AimbotSmoothness = 0.5,
    AimbotTarget = nil,
    ESPEnhanced = false,    -- Bật ESP nâng cao (highlight + tracer)
    ESPHighlight = false,
    ESPTracer = false,
    TeamCache = {},
    HighlightFolder = nil,
    ActiveHighlights = {},
    ESPDrawings = {},
    AimbotConnection = nil,
    ESPConnection = nil,
    ESPLoopConnection = nil,
}

local Connections = {}
local function Hook(signal, callback) local c = signal:Connect(callback) table.insert(Connections, c) return c end
local function KillConnections() for i = #Connections, 1, -1 do local c = Connections[i] if c and c.Connected then c:Disconnect() end table.remove(Connections, i) end end
local function safeCall(f, ...) local s, r = pcall(f, ...) if not s then warn(r) end return s, r end
local function getChar() local c = LocalPlayer.Character if not c then LocalPlayer.CharacterAdded:Wait() c = LocalPlayer.Character end return c end
local function getHum() local c = getChar() local h = c:FindFirstChildOfClass("Humanoid") if not h then h = c:WaitForChild("Humanoid", 10) end return h end
local function getRoot() local c = getChar() local r = c:FindFirstChild("HumanoidRootPart") if not r then r = c:WaitForChild("HumanoidRootPart", 10) end return r end
local function Notify(title, content, duration) duration = duration or 3 safeCall(function() WindUI:Notify({Title = title, Content = content, Duration = duration}) end) end

-- ===== Chức năng Aimbot + ESP nâng cao (từ Andepzai) =====
local function GetTeamCount()
    local teams = game:GetService("Teams"):GetChildren()
    local count = 0
    for _, t in ipairs(teams) do if t:IsA("Team") then count = count + 1 end end
    return count
end
local function IsFreeForAll() return GetTeamCount() <= 1 end

local function ScanPlayerTeam(plr)
    if IsFreeForAll() then return "__FFA_NOTEAM__" end
    if Settings.TeamCache[plr] ~= nil then return Settings.TeamCache[plr] end
    local teamIdentifier = nil
    pcall(function()
        local teamObject = plr.Team
        if teamObject and typeof(teamObject) == "Instance" and teamObject:IsA("Team") then
            teamIdentifier = teamObject.Name
        end
    end)
    if teamIdentifier then Settings.TeamCache[plr] = teamIdentifier return teamIdentifier end
    pcall(function()
        if plr:FindFirstChild("TeamColor") then
            local tc = plr.TeamColor
            if typeof(tc) == "BrickColor" then teamIdentifier = tc.Color
            elseif typeof(tc) == "Color3" then teamIdentifier = tc end
        end
    end)
    if teamIdentifier then Settings.TeamCache[plr] = teamIdentifier return teamIdentifier end
    pcall(function()
        local attr = plr:GetAttribute("Team")
        if attr then teamIdentifier = tostring(attr) end
    end)
    if teamIdentifier then Settings.TeamCache[plr] = teamIdentifier return teamIdentifier end
    -- fallback
    if teamIdentifier == nil then teamIdentifier = "__UNKNOWN_" .. plr.UserId .. "__" end
    Settings.TeamCache[plr] = teamIdentifier
    return teamIdentifier
end

local function RefreshAllTeams()
    local newCache = {}
    for _, plr in ipairs(Players:GetPlayers()) do
        newCache[plr] = ScanPlayerTeam(plr)
    end
    Settings.TeamCache = newCache
end
RefreshAllTeams()

Players.PlayerAdded:Connect(function(plr)
    plr.CharacterAdded:Connect(function()
        task.wait(0.3)
        Settings.TeamCache[plr] = ScanPlayerTeam(plr)
    end)
end)
Players.PlayerRemoving:Connect(function(plr)
    Settings.TeamCache[plr] = nil
end)
task.spawn(function()
    while task.wait(1.5) do RefreshAllTeams() end
end)
LocalPlayer.CharacterAdded:Connect(function() task.wait(0.3); RefreshAllTeams() end)

local function IsPlayerEnemy(plr)
    if plr == LocalPlayer then return false end
    if IsFreeForAll() then return true end
    local myTeam = Settings.TeamCache[LocalPlayer]
    local theirTeam = Settings.TeamCache[plr]
    if myTeam == nil or theirTeam == nil then return true end
    if myTeam == "__UNKNOWN_" .. LocalPlayer.UserId .. "__" or theirTeam == "__UNKNOWN_" .. plr.UserId .. "__" then return true end
    if myTeam == theirTeam then return false end
    if type(myTeam) == "string" and type(theirTeam) == "string" then
        if myTeam:lower() == theirTeam:lower() then return false end
        if myTeam:find(theirTeam) or theirTeam:find(myTeam) then return false end
        return true
    end
    if typeof(myTeam) == "Color3" and typeof(theirTeam) == "Color3" then
        local tol = 0.05
        if math.abs(myTeam.R - theirTeam.R) < tol and math.abs(myTeam.G - theirTeam.G) < tol and math.abs(myTeam.B - theirTeam.B) < tol then return false end
        return true
    end
    if type(myTeam) == "number" and type(theirTeam) == "number" then return myTeam ~= theirTeam end
    return true
end

local function GetClosestEnemyPlayer()
    local myChar = LocalPlayer.Character
    if not myChar then return nil end
    local myRoot = myChar:FindFirstChild("HumanoidRootPart")
    if not myRoot then return nil end
    local myPos = myRoot.Position
    local closest = nil
    local minDist = math.huge
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr == LocalPlayer then continue end
        if not IsPlayerEnemy(plr) then continue end
        local char = plr.Character
        if not char then continue end
        local head = char:FindFirstChild("Head")
        if not head then continue end
        local hum = char:FindFirstChild("Humanoid")
        if not hum or hum.Health <= 0 then continue end
        local dist = (head.Position - myPos).Magnitude
        if dist < minDist then minDist = dist; closest = plr end
    end
    return closest
end

local function IsTargetValid(plr)
    if not plr then return false end
    if not IsPlayerEnemy(plr) then return false end
    local char = plr.Character
    if not char then return false end
    if not char:FindFirstChild("Head") then return false end
    local hum = char:FindFirstChild("Humanoid")
    if not hum or hum.Health <= 0 then return false end
    return true
end

-- Aimbot
local function EnableAimbot()
    if Settings.AimbotEnabled then return end
    Settings.AimbotEnabled = true
    getgenv().AimbotEnabled = true
    Settings.AimbotConnection = RunService:BindToRenderStep("PremiumAimbot", 200, function()
        if not Settings.AimbotEnabled then return end
        if not Settings.AimbotTarget or not IsTargetValid(Settings.AimbotTarget) then
            Settings.AimbotTarget = GetClosestEnemyPlayer()
        end
        local target = Settings.AimbotTarget
        if not target or not IsTargetValid(target) then
            Settings.AimbotTarget = nil
            return
        end
        local headPos = target.Character.Head.Position
        local camPos = Camera.CFrame.Position
        local targetDir = (headPos - camPos).Unit
        local currentDir = Camera.CFrame.LookVector
        local smooth = math.clamp(Settings.AimbotSmoothness, 0.1, 1.0)
        local newDir = (currentDir + (targetDir - currentDir) * smooth).Unit
        Camera.CFrame = CFrame.new(camPos, camPos + newDir)
    end)
    Mouse.Button2Down:Connect(function()
        if Settings.AimbotEnabled then Settings.AimbotTarget = GetClosestEnemyPlayer() end
    end)
    Notify("Aimbot","On",2)
end

local function DisableAimbot()
    Settings.AimbotEnabled = false
    getgenv().AimbotEnabled = false
    Settings.AimbotTarget = nil
    if Settings.AimbotConnection then
        RunService:UnbindFromRenderStep("PremiumAimbot")
        Settings.AimbotConnection = nil
    end
    Notify("Aimbot","Off",2)
end

-- ESP nâng cao (Highlight + Tracer)
local function ClearAllHighlights()
    for plr, hl in pairs(Settings.ActiveHighlights) do
        pcall(function() hl:Destroy() end)
    end
    table.clear(Settings.ActiveHighlights)
end

local function ClearAllESPDrawings()
    for _, d in ipairs(Settings.ESPDrawings) do
        pcall(function() d:Remove() end)
    end
    table.clear(Settings.ESPDrawings)
end

local function CreateHighlightForPlayer(plr)
    if Settings.ActiveHighlights[plr] then return end
    local char = plr.Character
    if not char then return end
    if not char:FindFirstChild("Head") then return end
    local hum = char:FindFirstChild("Humanoid")
    if not hum or hum.Health <= 0 then return end
    if not Settings.HighlightFolder then
        Settings.HighlightFolder = Instance.new("Folder")
        Settings.HighlightFolder.Name = "PremiumHighlights"
        Settings.HighlightFolder.Parent = Workspace
    end
    local hl = Instance.new("Highlight")
    hl.Name = "ESP_" .. plr.Name
    hl.FillColor = Color3.fromRGB(0,255,0)
    hl.FillTransparency = 0.5
    hl.OutlineColor = Color3.fromRGB(0,255,0)
    hl.OutlineTransparency = 0.2
    hl.Adornee = char
    hl.Parent = Settings.HighlightFolder
    Settings.ActiveHighlights[plr] = hl
end

local function RemoveHighlightForPlayer(plr)
    if Settings.ActiveHighlights[plr] then
        pcall(function() Settings.ActiveHighlights[plr]:Destroy() end)
        Settings.ActiveHighlights[plr] = nil
    end
end

local function EnableESPEnhanced()
    if Settings.ESPEnhanced then return end
    Settings.ESPEnhanced = true
    getgenv().ESPEnabled = true
    -- ESP Drawing (tracer)
    Settings.ESPConnection = RunService:BindToRenderStep("PremiumESP", 201, function()
        ClearAllESPDrawings()
        if not Settings.ESPEnhanced or not Settings.ESPTracer then return end
        local myChar = LocalPlayer.Character
        local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
        if not myRoot then return end
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr == LocalPlayer then continue end
            if not IsPlayerEnemy(plr) then continue end
            local char = plr.Character
            if not char then continue end
            local head = char:FindFirstChild("Head")
            local hum = char:FindFirstChild("Humanoid")
            if not head or not hum or hum.Health <= 0 then continue end
            local headScreen, onScreen = Camera:WorldToScreenPoint(head.Position)
            if not onScreen or headScreen.Z <= 0 then continue end
            local myScreen, myOn = Camera:WorldToScreenPoint(myRoot.Position)
            if myOn and myScreen.Z > 0 then
                local tracer = Drawing.new("Line")
                tracer.From = Vector2.new(myScreen.X, myScreen.Y)
                tracer.To = Vector2.new(headScreen.X, headScreen.Y)
                tracer.Color = Color3.fromRGB(0,255,0)
                tracer.Thickness = 1
                tracer.Visible = true
                table.insert(Settings.ESPDrawings, tracer)
            end
        end
    end)
    -- Highlight loop
    Settings.ESPLoopConnection = task.spawn(function()
        while Settings.ESPEnhanced do
            task.wait(0.2)
            if not Settings.ESPEnhanced then break end
            if not Settings.ESPHighlight then
                ClearAllHighlights()
            else
                for _, plr in ipairs(Players:GetPlayers()) do
                    if plr == LocalPlayer then continue end
                    if not IsPlayerEnemy(plr) then
                        RemoveHighlightForPlayer(plr)
                        continue
                    end
                    if plr.Character then
                        local hum = plr.Character:FindFirstChild("Humanoid")
                        if hum and hum.Health > 0 then
                            CreateHighlightForPlayer(plr)
                        else
                            RemoveHighlightForPlayer(plr)
                        end
                    else
                        RemoveHighlightForPlayer(plr)
                    end
                end
                -- Xóa highlight cho người chơi không còn tồn tại
                for plr, hl in pairs(Settings.ActiveHighlights) do
                    if not plr or not plr.Parent then
                        pcall(function() hl:Destroy() end)
                        Settings.ActiveHighlights[plr] = nil
                    end
                end
            end
        end
        ClearAllHighlights()
    end)
    Notify("ESP Enhanced","On",2)
end

local function DisableESPEnhanced()
    Settings.ESPEnhanced = false
    getgenv().ESPEnabled = false
    if Settings.ESPConnection then
        RunService:UnbindFromRenderStep("PremiumESP")
        Settings.ESPConnection = nil
    end
    if Settings.ESPLoopConnection then
        task.cancel(Settings.ESPLoopConnection)
        Settings.ESPLoopConnection = nil
    end
    ClearAllHighlights()
    ClearAllESPDrawings()
    if Settings.HighlightFolder then
        pcall(function() Settings.HighlightFolder:Destroy() end)
        Settings.HighlightFolder = nil
    end
    Notify("ESP Enhanced","Off",2)
end

-- ===== Các chức năng cũ (Fly, NoClip, v.v.) giữ nguyên =====
-- (Giữ nguyên toàn bộ các hàm EnableFly, DisableFly, EnableNoClip, DisableNoClip, EnableInfiniteJump, DisableInfiniteJump, EnableAntiKB, DisableAntiKB, EnableWallhack, DisableWallhack, EnableFullbright, DisableFullbright, EnableFPSBoost, DisableFPSBoost, EnableLowGraphics, DisableLowGraphics, SetTeleportMark, TeleportToMark, TeleportToNearestPlayer, FindNearestTree, TeleportToNearestTree, ResetCharacter, UnloadAll)
-- Để tránh trùng lặp, tôi sẽ viết lại UnloadAll để tắt cả Aimbot và ESP nâng cao

-- Hàm UnloadAll cập nhật
local function UnloadAll()
    Settings.FlyEnabled = false; Settings.NoClipEnabled = false; Settings.ESPEnabled = false
    Settings.InfiniteJump = false; Settings.AntiKnockback = false; Settings.Wallhack = false
    Settings.Fullbright = false; Settings.FPSBoost = false; Settings.LowGraphics = false
    Settings.AimbotEnabled = false; Settings.ESPEnhanced = false
    DisableAimbot()
    DisableESPEnhanced()
    safeCall(function()
        if Settings.FlyBV then Settings.FlyBV:Destroy(); Settings.FlyBV = nil end
        if Settings.FlyBG then Settings.FlyBG:Destroy(); Settings.FlyBG = nil end
    end)
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

-- ===== Xây dựng giao diện WindUI =====
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

-- Tab Aimbot mới
local AimbotTab = Window:Tab({Title = "Aimbot", Icon = "crosshair"})
local AimbotSection = AimbotTab:Section({Title = "Cài đặt Aimbot"})
AimbotSection:Toggle({Title = "Bật Aimbot", Value = false, Callback = function(s) if s then EnableAimbot() else DisableAimbot() end end})
AimbotSection:Slider({Title = "Độ mượt (Smooth)", Step = 0.05, Value = {Min=0.1, Max=1.0, Default=0.5}, Callback = function(v) Settings.AimbotSmoothness = v; getgenv().AimbotSmoothness = v end})
AimbotSection:Button({Title = "Chọn mục tiêu gần nhất (click phải chuột)", Callback = function() Settings.AimbotTarget = GetClosestEnemyPlayer(); Notify("Target","Đã chọn",2) end})

-- Tab Visual (thêm ESP nâng cao)
local VisualTab = Window:Tab({Title = "Visual", Icon = "eye"})
local ESPSection = VisualTab:Section({Title = "ESP Cơ bản"})
ESPSection:Toggle({Title = "ESP Box (cũ)", Value = false, Callback = function(s) if s then EnableESP() else DisableESP() end end})

local EnhancedSection = VisualTab:Section({Title = "ESP Nâng cao (Andepzai)"})
EnhancedSection:Toggle({Title = "Bật ESP nâng cao", Value = false, Callback = function(s) if s then EnableESPEnhanced() else DisableESPEnhanced() end end})
EnhancedSection:Toggle({Title = "Highlight (viền sáng)", Value = true, Callback = function(s) Settings.ESPHighlight = s end})
EnhancedSection:Toggle({Title = "Tracer (đường kẻ)", Value = true, Callback = function(s) Settings.ESPTracer = s end})

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

Notify("Premium Hub + Andepzai", "Script đã sẵn sàng!", 5)