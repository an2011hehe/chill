local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

if not game:IsLoaded() then
    game.Loaded:Wait()
end

local Window = WindUI:CreateWindow({
    Title = "Premium Hub",
    Icon = "star",
    Author = "by nhatanh",
    Folder = "PremiumHub",
    Theme = "Dark",
    Size = UDim2.fromOffset(580, 490),
})

local videoBg = Instance.new("VideoFrame")
videoBg.Size = UDim2.new(1, 0, 1, 0)
videoBg.BackgroundTransparency = 1
videoBg.Looped = true
videoBg.Playing = true
videoBg.Volume = 0
videoBg.Video = "https://files.catbox.moe/yyj3kl.webm"
videoBg.Parent = Window.UIElements.Main
videoBg.ZIndex = 0

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, Window.UICorner or 16)
corner.Parent = videoBg

local darkOverlay = Instance.new("Frame")
darkOverlay.Size = UDim2.new(1, 0, 1, 0)
darkOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
darkOverlay.BackgroundTransparency = 0.4
darkOverlay.ZIndex = 1
darkOverlay.Parent = Window.UIElements.Main

local overlayCorner = Instance.new("UICorner")
overlayCorner.CornerRadius = UDim.new(0, Window.UICorner or 16)
overlayCorner.Parent = darkOverlay

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
    local connection = signal:Connect(callback)
    table.insert(Connections, connection)
    return connection
end

local function KillConnections()
    for index = #Connections, 1, -1 do
        local connection = Connections[index]
        if connection and connection.Connected then
            connection:Disconnect()
        end
        table.remove(Connections, index)
    end
end

local function safeCall(func, ...)
    local success, result = pcall(func, ...)
    if not success then
        warn("[PremiumHub] Error:", result)
    end
    return success, result
end

local function getChar()
    local character = LocalPlayer.Character
    if not character then
        LocalPlayer.CharacterAdded:Wait()
        character = LocalPlayer.Character
    end
    return character
end

local function getHum()
    local character = getChar()
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then
        humanoid = character:WaitForChild("Humanoid", 10)
    end
    return humanoid
end

local function getRoot()
    local character = getChar()
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then
        rootPart = character:WaitForChild("HumanoidRootPart", 10)
    end
    return rootPart
end

local function Notify(title, content, duration)
    duration = duration or 3
    safeCall(function()
        WindUI:Notify({
            Title = title,
            Content = content,
            Duration = duration,
        })
    end)
end

local function EnableFly()
    if Settings.FlyEnabled then
        return
    end
    
    Settings.FlyEnabled = true
    
    local character = getChar()
    local humanoid = getHum()
    local rootPart = getRoot()
    
    humanoid.PlatformStand = true
    
    local bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.Name = "FlyVelocity"
    bodyVelocity.Velocity = Vector3.zero
    bodyVelocity.MaxForce = Vector3.new(400000, 400000, 400000)
    bodyVelocity.Parent = rootPart
    Settings.FlyBV = bodyVelocity
    
    local bodyGyro = Instance.new("BodyGyro")
    bodyGyro.Name = "FlyGyro"
    bodyGyro.MaxTorque = Vector3.new(400000, 400000, 400000)
    bodyGyro.CFrame = Camera.CFrame
    bodyGyro.Parent = rootPart
    Settings.FlyBG = bodyGyro
    
    local keysDown = {}
    
    Hook(UserInputService.InputBegan, function(input, gameProcessedEvent)
        if not gameProcessedEvent then
            keysDown[input.KeyCode] = true
        end
    end)
    
    Hook(UserInputService.InputEnded, function(input)
        keysDown[input.KeyCode] = false
    end)
    
    Settings.FlyConn = Hook(RunService.RenderStepped, function()
        if not Settings.FlyEnabled then
            return
        end
        
        if not Settings.FlyBV or not Settings.FlyBV.Parent then
            DisableFly()
            return
        end
        
        local direction = Vector3.zero
        
        if keysDown[Enum.KeyCode.W] then
            direction = direction + Camera.CFrame.LookVector
        end
        if keysDown[Enum.KeyCode.S] then
            direction = direction - Camera.CFrame.LookVector
        end
        if keysDown[Enum.KeyCode.A] then
            direction = direction - Camera.CFrame.RightVector
        end
        if keysDown[Enum.KeyCode.D] then
            direction = direction + Camera.CFrame.RightVector
        end
        if keysDown[Enum.KeyCode.Space] then
            direction = direction + Vector3.new(0, 1, 0)
        end
        if keysDown[Enum.KeyCode.LeftShift] then
            direction = direction - Vector3.new(0, 1, 0)
        end
        
        if direction.Magnitude > 0 then
            direction = direction.Unit * Settings.FlySpeed
        end
        
        bodyVelocity.Velocity = direction
        bodyGyro.CFrame = Camera.CFrame
    end)
    
    Notify("Fly", "Đã bật bay", 2)
end

local function DisableFly()
    Settings.FlyEnabled = false
    
    safeCall(function()
        if Settings.FlyBV then
            Settings.FlyBV:Destroy()
            Settings.FlyBV = nil
        end
        
        if Settings.FlyBG then
            Settings.FlyBG:Destroy()
            Settings.FlyBG = nil
        end
        
        if Settings.FlyConn then
            Settings.FlyConn:Disconnect()
            Settings.FlyConn = nil
        end
        
        local character = LocalPlayer.Character
        if character then
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid.PlatformStand = false
            end
        end
    end)
    
    Notify("Fly", "Đã tắt bay", 2)
end

local function EnableNoClip()
    if Settings.NoClipEnabled then
        return
    end
    
    Settings.NoClipEnabled = true
    
    Settings.NoClipConn = Hook(RunService.Stepped, function()
        if not Settings.NoClipEnabled then
            return
        end
        
        safeCall(function()
            local character = LocalPlayer.Character
            if not character then
                return
            end
            
            local descendants = character:GetDescendants()
            for index = 1, #descendants do
                local part = descendants[index]
                if part:IsA("BasePart") and part.CanCollide then
                    part.CanCollide = false
                end
            end
        end)
    end)
    
    Notify("NoClip", "Đã bật NoClip", 2)
end

local function DisableNoClip()
    Settings.NoClipEnabled = false
    
    if Settings.NoClipConn then
        Settings.NoClipConn:Disconnect()
        Settings.NoClipConn = nil
    end
    
    safeCall(function()
        local character = LocalPlayer.Character
        if not character then
            return
        end
        
        local descendants = character:GetDescendants()
        for index = 1, #descendants do
            local part = descendants[index]
            if part:IsA("BasePart") then
                part.CanCollide = true
            end
        end
    end)
    
    Notify("NoClip", "Đã tắt NoClip", 2)
end

local INFINITE_JUMP_THROTTLE = 0.1

local function EnableInfiniteJump()
    if Settings.InfiniteJump then
        return
    end
    
    Settings.InfiniteJump = true
    
    if Settings.InfJumpConn then
        Settings.InfJumpConn:Disconnect()
    end
    
    Settings.InfiniteJumpLastTime = 0
    
    Settings.InfJumpConn = Hook(UserInputService.JumpRequest, function()
        if not Settings.InfiniteJump then
            return
        end
        
        local currentTime = tick()
        if currentTime - Settings.InfiniteJumpLastTime < INFINITE_JUMP_THROTTLE then
            return
        end
        
        Settings.InfiniteJumpLastTime = currentTime
        
        safeCall(function()
            local character = LocalPlayer.Character
            if not character then
                return
            end
            
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if not humanoid then
                return
            end
            
            humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end)
    end)
    
    Notify("Nhảy vô hạn", "Đã bật", 2)
end

local function DisableInfiniteJump()
    Settings.InfiniteJump = false
    
    if Settings.InfJumpConn then
        Settings.InfJumpConn:Disconnect()
        Settings.InfJumpConn = nil
    end
    
    Notify("Nhảy vô hạn", "Đã tắt", 2)
end

local function EnableAntiKB()
    if Settings.AntiKnockback then
        return
    end
    
    Settings.AntiKnockback = true
    
    Settings.AntiKBConn = Hook(RunService.RenderStepped, function()
        if not Settings.AntiKnockback then
            return
        end
        
        safeCall(function()
            local character = LocalPlayer.Character
            if not character then
                return
            end
            
            local descendants = character:GetDescendants()
            for index = 1, #descendants do
                local instance = descendants[index]
                
                if instance:IsA("BodyVelocity") and instance ~= Settings.FlyBV then
                    instance:Destroy()
                end
                
                if instance:IsA("BodyPosition") then
                    instance:Destroy()
                end
            end
        end)
    end)
    
    Notify("Anti KB", "Đã bật chống đẩy lùi", 2)
end

local function DisableAntiKB()
    Settings.AntiKnockback = false
    
    if Settings.AntiKBConn then
        Settings.AntiKBConn:Disconnect()
        Settings.AntiKBConn = nil
    end
    
    Notify("Anti KB", "Đã tắt chống đẩy lùi", 2)
end

local function EnableESP()
    if Settings.ESPEnabled then
        return
    end
    
    Settings.ESPEnabled = true
    
    if Settings.ESPGui then
        Settings.ESPGui:Destroy()
    end
    
    local espGui = Instance.new("ScreenGui")
    espGui.Name = "ESPGui"
    espGui.Parent = CoreGui
    espGui.DisplayOrder = 999
    espGui.ResetOnSpawn = false
    Settings.ESPGui = espGui
    
    local function createESP(targetPlayer)
        if targetPlayer == LocalPlayer then
            return
        end
        
        local function setupESP()
            local character = targetPlayer.Character
            if not character then
                return
            end
            
            local rootPart = character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Head")
            if not rootPart then
                return
            end
            
            if Settings.ESPBoxes[targetPlayer] then
                local oldData = Settings.ESPBoxes[targetPlayer]
                for _, obj in ipairs(oldData) do
                    if obj and obj.Destroy and typeof(obj) ~= "RBXScriptConnection" then
                        safeCall(function()
                            obj:Destroy()
                        end)
                    end
                end
            end
            
            local box = Instance.new("Frame")
            box.BackgroundColor3 = Color3.fromRGB(139, 92, 246)
            box.BackgroundTransparency = 0.6
            box.BorderSizePixel = 0
            box.Parent = espGui
            
            local boxCorner = Instance.new("UICorner")
            boxCorner.CornerRadius = UDim.new(0, 3)
            boxCorner.Parent = box
            
            local boxStroke = Instance.new("UIStroke")
            boxStroke.Color = Color3.fromRGB(139, 92, 246)
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
            nameLabel.Parent = espGui
            
            local healthBackground = Instance.new("Frame")
            healthBackground.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
            healthBackground.BackgroundTransparency = 0.3
            healthBackground.BorderSizePixel = 0
            healthBackground.Parent = espGui
            
            local healthBgCorner = Instance.new("UICorner")
            healthBgCorner.CornerRadius = UDim.new(0, 2)
            healthBgCorner.Parent = healthBackground
            
            local healthFill = Instance.new("Frame")
            healthFill.BackgroundColor3 = Color3.fromRGB(50, 200, 100)
            healthFill.BorderSizePixel = 0
            healthFill.Parent = healthBackground
            
            local healthFillCorner = Instance.new("UICorner")
            healthFillCorner.CornerRadius = UDim.new(0, 2)
            healthFillCorner.Parent = healthFill
            
            local distanceLabel = Instance.new("TextLabel")
            distanceLabel.BackgroundTransparency = 1
            distanceLabel.TextColor3 = Color3.fromRGB(160, 160, 170)
            distanceLabel.Font = Enum.Font.Gotham
            distanceLabel.TextSize = 9
            distanceLabel.Parent = espGui
            
            local renderConnection = Hook(RunService.RenderStepped, function()
                if not Settings.ESPEnabled then
                    box.Visible = false
                    nameLabel.Visible = false
                    healthBackground.Visible = false
                    distanceLabel.Visible = false
                    return
                end
                
                local currentCharacter = targetPlayer.Character
                if not currentCharacter then
                    box.Visible = false
                    nameLabel.Visible = false
                    healthBackground.Visible = false
                    distanceLabel.Visible = false
                    return
                end
                
                local currentRoot = currentCharacter:FindFirstChild("HumanoidRootPart") or currentCharacter:FindFirstChild("Head")
                if not currentRoot or not currentRoot:IsDescendantOf(workspace) then
                    box.Visible = false
                    nameLabel.Visible = false
                    healthBackground.Visible = false
                    distanceLabel.Visible = false
                    return
                end
                
                local screenPosition, onScreen = Camera:WorldToViewportPoint(currentRoot.Position)
                if not onScreen then
                    box.Visible = false
                    nameLabel.Visible = false
                    healthBackground.Visible = false
                    distanceLabel.Visible = false
                    return
                end
                
                local humanoid = currentCharacter:FindFirstChildOfClass("Humanoid")
                local depth = math.max(0.1, (Camera.CFrame.Position - currentRoot.Position).Magnitude)
                local scale = math.clamp(200 / depth, 1.5, 4)
                local modelSize = currentCharacter:GetExtentsSize()
                local boxWidth = math.clamp(modelSize.X * scale, 30, 120)
                local boxHeight = math.clamp(modelSize.Y * scale, 50, 180)
                
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
                        distanceLabel.Text = string.format("%.0f m", (localRoot.Position - currentRoot.Position).Magnitude)
                    end
                end
                
                local isEnemy = targetPlayer.Team and LocalPlayer.Team and targetPlayer.Team ~= LocalPlayer.Team
                local espColor = isEnemy and Color3.fromRGB(255, 70, 70) or Color3.fromRGB(139, 92, 246)
                box.BackgroundColor3 = espColor
                boxStroke.Color = espColor
            end)
            
            Settings.ESPBoxes[targetPlayer] = {box, nameLabel, healthBackground, distanceLabel, renderConnection}
        end
        
        if targetPlayer.Character then
            setupESP()
        end
        
        Hook(targetPlayer.CharacterAdded, function()
            task.wait(0.3)
            if Settings.ESPEnabled then
                setupESP()
            end
        end)
    end
    
    local allPlayers = Players:GetPlayers()
    for index = 1, #allPlayers do
        createESP(allPlayers[index])
    end
    
    Hook(Players.PlayerAdded, function(player)
        if Settings.ESPEnabled then
            createESP(player)
        end
    end)
    
    Hook(Players.PlayerRemoving, function(player)
        if Settings.ESPBoxes[player] then
            local espData = Settings.ESPBoxes[player]
            for _, obj in ipairs(espData) do
                if obj and obj.Destroy and typeof(obj) ~= "RBXScriptConnection" then
                    safeCall(function()
                        obj:Destroy()
                    end)
                end
            end
            Settings.ESPBoxes[player] = nil
        end
    end)
    
    Notify("ESP", "Đã bật ESP", 2)
end

local function DisableESP()
    Settings.ESPEnabled = false
    
    for player, espData in pairs(Settings.ESPBoxes) do
        for _, obj in ipairs(espData) do
            if obj and obj.Destroy and typeof(obj) ~= "RBXScriptConnection" then
                safeCall(function()
                    obj:Destroy()
                end)
            end
        end
    end
    
    Settings.ESPBoxes = {}
    
    if Settings.ESPGui then
        Settings.ESPGui:Destroy()
        Settings.ESPGui = nil
    end
    
    Notify("ESP", "Đã tắt ESP", 2)
end

local function EnableWallhack()
    if Settings.Wallhack then
        return
    end
    
    Settings.Wallhack = true
    
    local function applyWallhack(object)
        if object:IsA("BasePart") and not object.Parent:FindFirstChildOfClass("Humanoid") then
            object.LocalTransparencyModifier = 0.6
        end
    end
    
    local allObjects = workspace:GetDescendants()
    for index = 1, #allObjects do
        applyWallhack(allObjects[index])
    end
    
    Settings.WallhackConn = Hook(workspace.DescendantAdded, function(object)
        if Settings.Wallhack then
            applyWallhack(object)
        end
    end)
    
    Notify("Wallhack", "Đã bật nhìn xuyên tường", 2)
end

local function DisableWallhack()
    Settings.Wallhack = false
    
    if Settings.WallhackConn then
        Settings.WallhackConn:Disconnect()
        Settings.WallhackConn = nil
    end
    
    local allObjects = workspace:GetDescendants()
    for index = 1, #allObjects do
        local object = allObjects[index]
        if object:IsA("BasePart") then
            object.LocalTransparencyModifier = 0
        end
    end
    
    Notify("Wallhack", "Đã tắt nhìn xuyên tường", 2)
end

local function EnableFullbright()
    if Settings.Fullbright then
        return
    end
    
    Settings.Fullbright = true
    
    Lighting.Brightness = 2
    Lighting.ClockTime = 14
    Lighting.FogEnd = 100000
    
    Settings.FullbrightConn = Hook(Lighting:GetPropertyChangedSignal("Brightness"), function()
        if Settings.Fullbright and Lighting.Brightness ~= 2 then
            Lighting.Brightness = 2
        end
    end)
    
    Notify("Fullbright", "Đã bật đèn nền", 2)
end

local function DisableFullbright()
    Settings.Fullbright = false
    
    if Settings.FullbrightConn then
        Settings.FullbrightConn:Disconnect()
        Settings.FullbrightConn = nil
    end
    
    Lighting.Brightness = 1
    Lighting.FogEnd = 10000
    
    Notify("Fullbright", "Đã tắt đèn nền", 2)
end

local function EnableFPSBoost()
    Settings.FPSBoost = true
    
    safeCall(function()
        settings().Rendering.QualityLevel = 1
    end)
    
    Notify("FPS Boost", "Đã bật tăng FPS", 2)
end

local function DisableFPSBoost()
    Settings.FPSBoost = false
    
    safeCall(function()
        settings().Rendering.QualityLevel = 10
    end)
    
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

local function SetTeleportMark()
    safeCall(function()
        local rootPart = getRoot()
        Settings.TeleportMark = rootPart.CFrame
    end)
    
    Notify("Đánh dấu", "Đã đặt điểm dịch chuyển", 2)
end

local function TeleportToMark()
    safeCall(function()
        if not Settings.TeleportMark then
            Notify("Lỗi", "Chưa đặt điểm đánh dấu", 2)
            return
        end
        
        local rootPart = getRoot()
        rootPart.CFrame = Settings.TeleportMark
        Notify("Dịch chuyển", "Đã về điểm đánh dấu", 2)
    end)
end

local function TeleportToNearestPlayer()
    safeCall(function()
        local rootPart = getRoot()
        local nearestRoot = nil
        local minimumDistance = math.huge
        
        local allPlayers = Players:GetPlayers()
        for index = 1, #allPlayers do
            local targetPlayer = allPlayers[index]
            if targetPlayer ~= LocalPlayer and targetPlayer.Character then
                local targetRoot = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
                if targetRoot and targetRoot:IsDescendantOf(workspace) then
                    local distance = (rootPart.Position - targetRoot.Position).Magnitude
                    if distance < minimumDistance then
                        minimumDistance = distance
                        nearestRoot = targetRoot
                    end
                end
            end
        end
        
        if nearestRoot then
            rootPart.CFrame = nearestRoot.CFrame + Vector3.new(0, 3, 0)
            Notify("Dịch chuyển", "Đến người chơi gần nhất", 2)
        end
    end)
end

local TreeCache = {}
local TreeCacheTimestamp = 0
local TREE_CACHE_DURATION = 2

local function FindNearestTree()
    local currentTime = tick()
    
    if currentTime - TreeCacheTimestamp < TREE_CACHE_DURATION and #TreeCache > 0 then
        local rootPart = getRoot()
        local nearestTree = nil
        local minimumDistance = math.huge
        
        for index = 1, #TreeCache do
            local tree = TreeCache[index]
            if tree and tree.Parent and tree:IsDescendantOf(workspace) then
                local distance = (rootPart.Position - tree.Position).Magnitude
                if distance < minimumDistance then
                    minimumDistance = distance
                    nearestTree = tree
                end
            end
        end
        
        if nearestTree then
            return nearestTree
        end
    end
    
    TreeCache = {}
    local rootPart = getRoot()
    local nearestTree = nil
    local minimumDistance = math.huge
    local woodMaterials = {
        [Enum.Material.Wood] = true,
        [Enum.Material.WoodPlanks] = true,
    }
    
    local allObjects = workspace:GetDescendants()
    for index = 1, #allObjects do
        local object = allObjects[index]
        if object:IsA("BasePart") and object:IsDescendantOf(workspace) then
            local isTree = false
            local objectName = object.Name:lower()
            
            if objectName:find("tree") or objectName:find("wood") or objectName:find("log") or
               objectName:find("oak") or objectName:find("pine") or objectName:find("birch") or
               objectName:find("maple") or objectName:find("palm") or objectName:find("bush") or
               objectName:find("plant") or objectName:find("trunk") then
                isTree = true
            elseif woodMaterials[object.Material] then
                local parent = object.Parent
                if parent and not parent:FindFirstChildOfClass("Humanoid") then
                    local parentName = parent.Name:lower()
                    if parentName:find("tree") or parentName:find("wood") or parentName:find("plant") or
                       parentName:find("bush") or parentName:find("trunk") or parentName:find("log") then
                        isTree = true
                    end
                end
            end
            
            if isTree and not object.Parent:FindFirstChildOfClass("Humanoid") then
                table.insert(TreeCache, object)
                local distance = (rootPart.Position - object.Position).Magnitude
                if distance < minimumDistance then
                    minimumDistance = distance
                    nearestTree = object
                end
            end
        end
    end
    
    TreeCacheTimestamp = currentTime
    return nearestTree
end

local function TeleportToNearestTree()
    safeCall(function()
        local tree = FindNearestTree()
        if tree then
            local rootPart = getRoot()
            rootPart.CFrame = CFrame.new(tree.Position + Vector3.new(0, 5, 0))
            Notify("Dịch chuyển", "Đến cây gần nhất", 2)
        else
            Notify("Lỗi", "Không tìm thấy cây", 2)
        end
    end)
end

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
        if Settings.FlyBV then Settings.FlyBV:Destroy(); Settings.FlyBV = nil end
        if Settings.FlyBG then Settings.FlyBG:Destroy(); Settings.FlyBG = nil end
    end)
    
    safeCall(function()
        local character = LocalPlayer.Character
        if character then
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if humanoid then humanoid.PlatformStand = false end
            
            local descendants = character:GetDescendants()
            for index = 1, #descendants do
                local part = descendants[index]
                if part:IsA("BasePart") then part.CanCollide = true end
            end
        end
    end)
    
    for _, espData in pairs(Settings.ESPBoxes) do
        for _, obj in ipairs(espData) do
            if obj and obj.Destroy and typeof(obj) ~= "RBXScriptConnection" then
                safeCall(function() obj:Destroy() end)
            end
        end
    end
    Settings.ESPBoxes = {}
    
    if Settings.ESPGui then
        Settings.ESPGui:Destroy()
        Settings.ESPGui = nil
    end
    
    Lighting.Brightness = 1
    Lighting.FogEnd = 10000
    Lighting.GlobalShadows = true
    
    local allObjects = workspace:GetDescendants()
    for index = 1, #allObjects do
        local object = allObjects[index]
        if object:IsA("BasePart") then object.LocalTransparencyModifier = 0 end
    end
    
    safeCall(function() settings().Rendering.QualityLevel = 10 end)
    
    TreeCache = {}
    
    KillConnections()
    Window:Destroy()
end

local MainTab = Window:Tab({ Title = "Main", Icon = "home" })

local FlySection = MainTab:Section({ Title = "Bay (Fly)" })
FlySection:Toggle({
    Title = "Bật Bay",
    Value = false,
    Callback = function(state)
        if state then EnableFly() else DisableFly() end
    end,
})
FlySection:Slider({
    Title = "Tốc độ bay",
    Step = 1,
    Value = { Min = 20, Max = 300, Default = 50 },
    Callback = function(value)
        Settings.FlySpeed = value
    end,
})

local MoveSection = MainTab:Section({ Title = "Di chuyển" })
MoveSection:Slider({
    Title = "Tốc độ",
    Step = 1,
    Value = { Min = 16, Max = 300, Default = 16 },
    Callback = function(value)
        safeCall(function()
            getHum().WalkSpeed = value
        end)
    end,
})
MoveSection:Slider({
    Title = "Sức nhảy",
    Step = 1,
    Value = { Min = 50, Max = 500, Default = 50 },
    Callback = function(value)
        safeCall(function()
            getHum().JumpPower = value
        end)
    end,
})
MoveSection:Toggle({
    Title = "NoClip (Xuyên tường)",
    Value = false,
    Callback = function(state)
        if state then EnableNoClip() else DisableNoClip() end
    end,
})

local PlayerTab = Window:Tab({ Title = "Player", Icon = "user" })

local PlayerSection = PlayerTab:Section({ Title = "Nhân vật" })
PlayerSection:Toggle({
    Title = "Nhảy vô hạn",
    Value = false,
    Callback = function(state)
        if state then EnableInfiniteJump() else DisableInfiniteJump() end
    end,
})
PlayerSection:Toggle({
    Title = "Anti Knockback",
    Value = false,
    Callback = function(state)
        if state then EnableAntiKB() else DisableAntiKB() end
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

local VisualTab = Window:Tab({ Title = "Visual", Icon = "eye" })

local ESPSection = VisualTab:Section({ Title = "ESP" })
ESPSection:Toggle({
    Title = "Bật ESP",
    Value = false,
    Callback = function(state)
        if state then EnableESP() else DisableESP() end
    end,
})

local WorldSection = VisualTab:Section({ Title = "Thế giới" })
WorldSection:Toggle({
    Title = "Wallhack",
    Value = false,
    Callback = function(state)
        if state then EnableWallhack() else DisableWallhack() end
    end,
})
WorldSection:Toggle({
    Title = "Fullbright",
    Value = false,
    Callback = function(state)
        if state then EnableFullbright() else DisableFullbright() end
    end,
})
WorldSection:Toggle({
    Title = "Đồ họa thấp",
    Value = false,
    Callback = function(state)
        if state then EnableLowGraphics() else DisableLowGraphics() end
    end,
})
WorldSection:Toggle({
    Title = "FPS Boost",
    Value = false,
    Callback = function(state)
        if state then EnableFPSBoost() else DisableFPSBoost() end    end,
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

Notify("Premium Hub", "Script đã sẵn sàng!", 5)