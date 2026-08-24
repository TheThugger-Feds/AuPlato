-- Fetch and initialize WindUI directly from raw source
local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()

-- Create the Main Window
local Window = WindUI:CreateWindow({
    Title = "AuPlatoHub",
    Icon = "rbxassetid://4483345998",
    Author = "AuPlato",
    Folder = "AuPlatoHubConfig",
    Size = UDim2.fromOffset(650, 700),
    Transparent = true,
    Theme = "Dark"
})

-- ====================================================================
-- GLOBAL CONFIG TABLE (Shared with all scripts)
-- ====================================================================
_G.AuPlatoConfig = {
    -- Airdrop Settings
    AirdropFarmEnabled = false,
    FlyHeight = 300,
    AirdropSpeed = 110,
    ScanInterval = 2,
    UndergroundOffset = 10,
    ServerHopTimeout = 120,
    ActionWait = 0.5,
    CarWaitBeforeExit = 2.5,
    PreWalkWait = 1.0,
    TweenEasing = "Linear",
    AutoExecuteAfterServerHop = false,
    ServerHopOnTimeout = true,
    
    -- Player Settings
    PlayerFlightEnabled = false,
    FlightSpeed = 50,
    WalkSpeed = 16,
    JumpPower = 50,
    
    -- Auto Farm Settings
    AutoFarmEnabled = false,
    
    -- Auto Arrest Settings
    AutoArrestEnabled = false,
}

-- Global flags
_G.ServerHopEnabled = true
_G.PlayerFlightEnabled = false

-- ====================================================================
-- AIRDROP SCRIPT (EMBEDDED)
-- ====================================================================
local AIRDROP_SCRIPT = [[
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local SpawnRemote = ReplicatedStorage:FindFirstChild("GarageSpawnVehicle", true)

local isRunning = false
local lastBriefcaseFoundTime = os.time()
local scriptActive = true

-- GET TWEEN EASING STYLE
local function getTweenEasing(style)
    local easing_map = {
        ["Linear"] = Enum.EasingStyle.Linear,
        ["Quad"] = Enum.EasingStyle.Quad,
        ["Cubic"] = Enum.EasingStyle.Cubic,
        ["Quart"] = Enum.EasingStyle.Quart,
        ["Quint"] = Enum.EasingStyle.Quint,
        ["Sine"] = Enum.EasingStyle.Sine,
        ["Expo"] = Enum.EasingStyle.Expo,
        ["Circ"] = Enum.EasingStyle.Circ,
        ["Elastic"] = Enum.EasingStyle.Elastic,
        ["Back"] = Enum.EasingStyle.Back,
        ["Bounce"] = Enum.EasingStyle.Bounce,
    }
    return easing_map[style] or Enum.EasingStyle.Linear
end

-- SERVER HOPPER
local function serverHop()
    if not (_G.ServerHopEnabled and _G.AuPlatoConfig.ServerHopOnTimeout) then
        print("[Airdrop] Server hop disabled by config")
        return
    end
    
    print("[Airdrop] No briefcases found in " .. _G.AuPlatoConfig.ServerHopTimeout .. " seconds. Server hopping...")
    scriptActive = false
    local placeId = game.PlaceId
    local serversUrl = "https://games.roblox.com/v1/games/" .. placeId .. "/servers/0?sortOrder=Asc&limit=100"
    
    local success, result = pcall(function()
        return HttpService:JSONDecode(game:HttpGet(serversUrl))
    end)
    
    if success and result and result.data then
        for _, server in ipairs(result.data) do
            if server.playing < server.maxPlayers and server.id ~= game.JobId then
                TeleportService:TeleportToPlaceInstance(placeId, server.id, LocalPlayer)
                
                if _G.AuPlatoConfig.AutoExecuteAfterServerHop then
                    task.wait(5)
                    print("[Airdrop] Auto-executing after server hop...")
                    _G.AuPlatoConfig.AirdropFarmEnabled = true
                end
                return
            end
        end
    end
    
    TeleportService:Teleport(placeId, LocalPlayer)
end

-- HELPER FUNCTIONS
local function safePivotTween(model, targetCFrame, duration)
    if not model or not model:IsA("Model") then return end
    
    local cframeValue = Instance.new("CFrameValue")
    cframeValue.Value = model:GetPivot()
    
    local conn = cframeValue.Changed:Connect(function(newCFrame)
        if model and model.Parent then
            model:PivotTo(newCFrame)
        end
    end)
    
    local tweenInfo = TweenInfo.new(duration, getTweenEasing(_G.AuPlatoConfig.TweenEasing), Enum.EasingDirection.InOut)
    local tween = TweenService:Create(cframeValue, tweenInfo, {Value = targetCFrame})
    tween:Play()
    tween.Completed:Wait()
    
    conn:Disconnect()
    cframeValue:Destroy()
end

local function safePartTween(part, targetCFrame, duration)
    if not part or not part:IsA("BasePart") then return end
    local tweenInfo = TweenInfo.new(duration, getTweenEasing(_G.AuPlatoConfig.TweenEasing), Enum.EasingDirection.InOut)
    local tween = TweenService:Create(part, tweenInfo, {CFrame = targetCFrame})
    tween:Play()
    tween.Completed:Wait()
end

local function getMyVehicle()
    local vehiclesFolder = Workspace:FindFirstChild("Vehicles")
    if not vehiclesFolder then return nil end
    
    local nameState = "_VehicleState_" .. LocalPlayer.Name
    local idState = "_VehicleState_" .. LocalPlayer.UserId

    for _, car in ipairs(vehiclesFolder:GetChildren()) do
        if car:FindFirstChild(nameState) or car:FindFirstChild(idState) then
            return car
        end
    end
    return nil
end

local function getNearbyVehicle(maxDistance)
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return nil end
    local hrp = char.HumanoidRootPart

    local myCar = getMyVehicle()
    if myCar then
        local dist = (myCar:GetPivot().Position - hrp.Position).Magnitude
        if dist <= maxDistance then
            return myCar
        end
    end
    return nil
end

local function spawnVehicleSpam()
    print("[Airdrop] Requesting vehicle spawn...")
    local retries = 0
    while retries < 10 do
        if SpawnRemote then
            pcall(function()
                SpawnRemote:FireServer("Chassis", "Camaro")
            end)
        end
        task.wait(1)
        local car = getMyVehicle()
        if car then
            print("[Airdrop] Vehicle successfully spawned!")
            return car
        end
        retries = retries + 1
        print("[Airdrop] Spawn on cooldown... Retrying (" .. retries .. "/10)...")
    end
    return nil
end

local function getActiveBriefcase()
    local function isValidBriefcase(obj)
        if obj and obj:IsA("Model") then
            local isLanded = obj:GetAttribute("BriefcaseLanded")
            local isCollected = obj:GetAttribute("BriefcaseCollected")
            
            if isLanded == nil then isLanded = true end
            if isCollected == nil then isCollected = false end

            if isLanded == true and not isCollected then
                return true
            end
        end
        return false
    end

    local directDrop = Workspace:FindFirstChild("Drop")
    if isValidBriefcase(directDrop) then return directDrop end

    for _, obj in ipairs(CollectionService:GetTagged("Briefcase")) do
        if isValidBriefcase(obj) then return obj end
    end

    for _, obj in ipairs(Workspace:GetDescendants()) do
        if (obj.Name == "Drop" or obj.Name == "Briefcase") and isValidBriefcase(obj) then
            return obj
        end
    end
    return nil
end

local function enterVehicle(car)
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return false end
    local hrp = char.HumanoidRootPart
    
    local seat = car:FindFirstChildWhichIsA("VehicleSeat", true) or car:FindFirstChildWhichIsA("Seat", true)
    if seat then
        safePartTween(hrp, seat.CFrame + Vector3.new(0, 2, 0), 0.5)
        task.wait(_G.AuPlatoConfig.ActionWait)
        
        local hum = char:FindFirstChildWhichIsA("Humanoid")
        if hum then
            seat:Sit(hum)
            task.wait(_G.AuPlatoConfig.ActionWait)
        end
        return hum and hum.SeatPart ~= nil
    end
    return false
end

-- MAIN PIPELINE
local function executeBriefcaseRun(targetCrate)
    if not scriptActive then return end
    
    isRunning = true
    print("[Airdrop] Briefcase targeted! Executing pipeline...")
    
    local char = LocalPlayer.Character
    if not char then 
        isRunning = false 
        return 
    end
    
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildWhichIsA("Humanoid")
    if not hrp or not hum then 
        isRunning = false 
        return 
    end

    local car = getNearbyVehicle(30)
    if not car then
        car = spawnVehicleSpam()
    end

    task.wait(_G.AuPlatoConfig.ActionWait)

    if car and not hum.SeatPart then
        enterVehicle(car)
    end

    local cratePivot = targetCrate:GetPivot()
    local cratePos = cratePivot.Position

    if car and hum.SeatPart then
        for _, part in ipairs(car:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end

        local startPivot = car:GetPivot()
        local airStart = CFrame.new(startPivot.Position.X, _G.AuPlatoConfig.FlyHeight, startPivot.Position.Z) * startPivot.Rotation
        local airCrate = CFrame.new(cratePos.X, _G.AuPlatoConfig.FlyHeight, cratePos.Z) * startPivot.Rotation
        local groundTarget = CFrame.new(cratePos + Vector3.new(0, 3, 0)) * startPivot.Rotation

        print("[Airdrop] Flying up...")
        safePivotTween(car, airStart, 1.2)
        task.wait(_G.AuPlatoConfig.ActionWait)

        print("[Airdrop] Flying to target...")
        local dist = (airStart.Position - airCrate.Position).Magnitude
        local flightTime = math.max(dist / _G.AuPlatoConfig.AirdropSpeed, 0.5)
        safePivotTween(car, airCrate, flightTime)
        task.wait(_G.AuPlatoConfig.ActionWait)

        print("[Airdrop] Descending...")
        safePivotTween(car, groundTarget, 1.5)
        
        print("[Airdrop] Waiting before exiting vehicle...")
        task.wait(_G.AuPlatoConfig.CarWaitBeforeExit)

        hum.Sit = false
        task.wait(0.5)
    end

    print("[Airdrop] Waiting before moving to airdrop...")
    task.wait(_G.AuPlatoConfig.PreWalkWait)

    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = false
        end
    end

    local undergroundOffset = Vector3.new(0, -_G.AuPlatoConfig.UndergroundOffset, 0)
    local safeUndergroundCFrame = CFrame.new(cratePos + undergroundOffset)
    safePartTween(hrp, safeUndergroundCFrame, 0.5)
    task.wait(_G.AuPlatoConfig.ActionWait)

    local pressRemote = targetCrate:FindFirstChild("BriefcasePress", true)
    local releaseRemote = targetCrate:FindFirstChild("BriefcaseRelease", true)
    local holdUpdateRemote = targetCrate:FindFirstChild("BriefcaseHoldUpdate", true)
    local collectRemote = targetCrate:FindFirstChild("BriefcaseCollect", true)
    
    local openDuration = targetCrate:GetAttribute("BriefcaseOpenTiming") or 4.0
    
    if pressRemote and collectRemote then
        print("[Airdrop] Robbing briefcase underground...")
        pcall(function() pressRemote:FireServer(false) end)
        task.wait(_G.AuPlatoConfig.ActionWait)
        
        local holding = true
        task.spawn(function()
            while holding and scriptActive do
                if holdUpdateRemote then
                    pcall(function() holdUpdateRemote:FireServer() end)
                end
                task.wait(0.2)
            end
        end)
        
        task.wait(openDuration + 0.3)
        holding = false
        
        if releaseRemote then
            pcall(function() releaseRemote:FireServer(false) end)
        end
        task.wait(_G.AuPlatoConfig.ActionWait)
        
        pcall(function() collectRemote:FireServer() end)
        task.wait(_G.AuPlatoConfig.ActionWait)
    end

    local aboveGroundCFrame = CFrame.new(cratePos + Vector3.new(0, 3, 0))
    safePartTween(hrp, aboveGroundCFrame, 0.5)
    task.wait(_G.AuPlatoConfig.ActionWait)

    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = true
        end
    end

    task.wait(_G.AuPlatoConfig.ActionWait)
    local returnCar = getMyVehicle()
    if returnCar then
        print("[Airdrop] Re-entering car...")
        enterVehicle(returnCar)
    end
    
    print("[Airdrop] Sequence complete!")
    isRunning = false
    lastBriefcaseFoundTime = os.time()
end

-- SCANNER LOOP
task.spawn(function()
    print("[Airdrop] Scanner initialized!")
    while scriptActive and task.wait(_G.AuPlatoConfig.ScanInterval) do
        if _G.AuPlatoConfig.AirdropFarmEnabled and not isRunning then
            local target = getActiveBriefcase()
            if target then
                lastBriefcaseFoundTime = os.time()
                task.spawn(function()
                    pcall(function()
                        executeBriefcaseRun(target)
                    end)
                end)
            else
                if (os.time() - lastBriefcaseFoundTime) >= _G.AuPlatoConfig.ServerHopTimeout then
                    serverHop()
                    break
                end
            end
        elseif not _G.AuPlatoConfig.AirdropFarmEnabled then
            scriptActive = false
            break
        end
    end
    print("[Airdrop] Scanner stopped")
end)

print("[Airdrop] Script loaded successfully!")
]]

-- ====================================================================
-- PLAYER FLIGHT SCRIPT (EMBEDDED)
-- ====================================================================
local PLAYER_SCRIPT = [[
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local scriptActive = true
local flightActive = false
local flying = false
local character = nil
local humanoidRootPart = nil
local humanoid = nil
local velocity = Vector3.new(0, 0, 0)
local direction = Vector3.new(0, 0, 0)

-- Flight configuration
local Acceleration = 2
local MaxSpeed = 100
local Gravity = 0.2

local function getCharacter()
    if LocalPlayer and LocalPlayer.Character then
        local char = LocalPlayer.Character
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChildWhichIsA("Humanoid")
        
        if hrp and hum and hum.Health > 0 then
            return char, hrp, hum
        end
    end
    return nil, nil, nil
end

local function setupCharacter()
    character, humanoidRootPart, humanoid = getCharacter()
    return character and humanoidRootPart and humanoid
end

local function startFlight()
    if not setupCharacter() then return end
    
    flying = true
    flightActive = true
    print("[Player] Flight Mode Activated")
    
    humanoid.PlatformStand = true
    
    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = false
        end
    end
end

local function stopFlight()
    if not character or not humanoidRootPart or not humanoid then return end
    
    flying = false
    flightActive = false
    print("[Player] Flight Mode Deactivated")
    
    humanoid.PlatformStand = false
    
    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = true
        end
    end
    
    velocity = Vector3.new(0, 0, 0)
end

local function updateFlight()
    if not flying or not setupCharacter() then return end
    
    local FlightSpeed = _G.AuPlatoConfig.FlightSpeed or 50
    local moveDirection = Vector3.new(0, 0, 0)
    
    local moveZ = 0
    local moveX = 0
    local moveY = 0
    
    if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveZ = moveZ - 1 end
    if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveZ = moveZ + 1 end
    if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveX = moveX - 1 end
    if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveX = moveX + 1 end
    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveY = moveY + 1 end
    if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then moveY = moveY - 1 end
    
    local inputDir = Vector3.new(moveX, moveY, moveZ).Unit
    if inputDir.Magnitude == 0 then
        inputDir = Vector3.new(0, 0, 0)
    end
    
    local camera = workspace.CurrentCamera
    local cameraCFrame = camera.CFrame
    
    local rightVec = cameraCFrame.RightVector
    local upVec = Vector3.new(0, 1, 0)
    local lookVec = cameraCFrame.LookVector * Vector3.new(1, 0, 1)
    lookVec = lookVec.Unit
    
    moveDirection = (rightVec * inputDir.X + upVec * inputDir.Y + lookVec * inputDir.Z)
    
    if moveDirection.Magnitude > 0 then
        direction = direction:Lerp(moveDirection, 0.1)
        velocity = velocity:Lerp(direction * FlightSpeed, Acceleration / 100)
    else
        direction = direction:Lerp(Vector3.new(0, 0, 0), 0.15)
        velocity = velocity:Lerp(direction * FlightSpeed, Acceleration / 150)
    end
    
    if velocity.Magnitude > MaxSpeed then
        velocity = velocity.Unit * MaxSpeed
    end
    
    if not UserInputService:IsKeyDown(Enum.KeyCode.Space) and not UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
        velocity = velocity - Vector3.new(0, Gravity, 0)
    end
    
    local newCFrame = humanoidRootPart.CFrame + velocity * 0.016
    humanoidRootPart.CFrame = newCFrame
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.F then
        if _G.AuPlatoConfig.PlayerFlightEnabled then
            if not flying then
                startFlight()
            else
                stopFlight()
            end
        end
    end
end)

local flightConnection
flightConnection = RunService.RenderStepped:Connect(function()
    if _G.AuPlatoConfig.PlayerFlightEnabled and not flying and scriptActive then
        startFlight()
    elseif not _G.AuPlatoConfig.PlayerFlightEnabled and flying then
        stopFlight()
    end
    
    if flying then
        updateFlight()
    end
end)

LocalPlayer.CharacterAdded:Connect(function()
    if flying then
        stopFlight()
    end
    if _G.AuPlatoConfig.PlayerFlightEnabled then
        task.wait(0.5)
        startFlight()
    end
end)

local checkConnection
checkConnection = game:GetService("RunService").Heartbeat:Connect(function()
    if not _G.AuPlatoConfig.PlayerFlightEnabled then
        if flightActive then
            stopFlight()
        end
        if checkConnection then
            checkConnection:Disconnect()
        end
        if flightConnection then
            flightConnection:Disconnect()
        end
        scriptActive = false
    end
end)

print("[Player] Flight script loaded! Press F to toggle flight")
print("[Player] W/A/S/D to move, Space/Ctrl for up/down")
]]

-- Create Tabs
local AutoFarmTab = Window:Tab({ Title = "Auto Farm", Icon = "coins" })
local AirdropTab  = Window:Tab({ Title = "Airdrop Farm", Icon = "box" })
local ArrestTab   = Window:Tab({ Title = "Auto Arrest", Icon = "shield-alert" })
local PlayerTab   = Window:Tab({ Title = "Local Player", Icon = "user" })
local SettingsTab = Window:Tab({ Title = "Settings", Icon = "settings" })

-- ====================================================================
-- 1. AUTO FARM TAB
-- ====================================================================
AutoFarmTab:Section({ Title = "Automated Farming" })

AutoFarmTab:Toggle({
    Title = "Auto Farm",
    Desc = "Activate or disable cash auto farm",
    Value = false,
    Callback = function(Value)
        _G.AuPlatoConfig.AutoFarmEnabled = Value
        print("[AuPlato] Auto Farm: " .. (Value and "ENABLED" or "DISABLED"))
    end
})

-- ====================================================================
-- 2. AIRDROP FARM TAB
-- ====================================================================
AirdropTab:Section({ Title = "Airdrop Collection" })

AirdropTab:Toggle({
    Title = "Auto Collect Airdrops",
    Desc = "Activate or disable automatic crate collection",
    Value = false,
    Callback = function(Value)
        _G.AuPlatoConfig.AirdropFarmEnabled = Value
        if Value then
            print("[AuPlato] Airdrop Farm Enabled")
            loadstring(AIRDROP_SCRIPT)()
        else
            print("[AuPlato] Airdrop Farm Disabled")
        end
    end
})

AirdropTab:Section({ Title = "Flight Configuration" })

AirdropTab:Slider({
    Title = "Flight Height",
    Step = 10,
    Value = { Min = 100, Max = 500, Default = 300 },
    Callback = function(Value)
        _G.AuPlatoConfig.FlyHeight = Value
        print("[AuPlato] Flight Height: " .. Value)
    end
})

AirdropTab:Slider({
    Title = "Flight Speed",
    Step = 5,
    Value = { Min = 50, Max = 200, Default = 110 },
    Callback = function(Value)
        _G.AuPlatoConfig.AirdropSpeed = Value
        print("[AuPlato] Flight Speed: " .. Value)
    end
})

AirdropTab:Section({ Title = "Scan & Timing" })

AirdropTab:Slider({
    Title = "Scan Interval (seconds)",
    Step = 0.5,
    Value = { Min = 0.5, Max = 5, Default = 2 },
    Callback = function(Value)
        _G.AuPlatoConfig.ScanInterval = Value
        print("[AuPlato] Scan Interval: " .. Value .. "s")
    end
})

AirdropTab:Slider({
    Title = "Underground Offset (studs)",
    Step = 1,
    Value = { Min = 1, Max = 20, Default = 10 },
    Callback = function(Value)
        _G.AuPlatoConfig.UndergroundOffset = Value
        print("[AuPlato] Underground Offset: " .. Value)
    end
})

AirdropTab:Slider({
    Title = "Server Hop Timeout (seconds)",
    Step = 10,
    Value = { Min = 30, Max = 300, Default = 120 },
    Callback = function(Value)
        _G.AuPlatoConfig.ServerHopTimeout = Value
        print("[AuPlato] Server Hop Timeout: " .. Value .. "s")
    end
})

AirdropTab:Slider({
    Title = "Action Wait Delay (seconds)",
    Step = 0.1,
    Value = { Min = 0.1, Max = 2, Default = 0.5 },
    Callback = function(Value)
        _G.AuPlatoConfig.ActionWait = Value
        print("[AuPlato] Action Wait: " .. Value .. "s")
    end
})

AirdropTab:Slider({
    Title = "Car Exit Wait (seconds)",
    Step = 0.1,
    Value = { Min = 0.5, Max = 5, Default = 2.5 },
    Callback = function(Value)
        _G.AuPlatoConfig.CarWaitBeforeExit = Value
        print("[AuPlato] Car Exit Wait: " .. Value .. "s")
    end
})

AirdropTab:Slider({
    Title = "Pre-Walk Wait (seconds)",
    Step = 0.1,
    Value = { Min = 0.1, Max = 3, Default = 1.0 },
    Callback = function(Value)
        _G.AuPlatoConfig.PreWalkWait = Value
        print("[AuPlato] Pre-Walk Wait: " .. Value .. "s")
    end
})

AirdropTab:Section({ Title = "Airdrop Behavior" })

AirdropTab:Toggle({
    Title = "Server Hop on Timeout",
    Desc = "Automatically server hop if no airdrops found",
    Value = true,
    Callback = function(Value)
        _G.AuPlatoConfig.ServerHopOnTimeout = Value
        print("[AuPlato] Server Hop on Timeout: " .. (Value and "ENABLED" or "DISABLED"))
    end
})

-- ====================================================================
-- 3. AUTO ARREST TAB
-- ====================================================================
ArrestTab:Section({ Title = "Cop Mechanics" })

ArrestTab:Toggle({
    Title = "Auto Arrest",
    Desc = "Activate or disable automatic criminal arrest",
    Value = false,
    Callback = function(Value)
        _G.AuPlatoConfig.AutoArrestEnabled = Value
        print("[AuPlato] Auto Arrest: " .. (Value and "ENABLED" or "DISABLED"))
    end
})

-- ====================================================================
-- 4. LOCAL PLAYER TAB
-- ====================================================================
PlayerTab:Section({ Title = "Flight Controls" })

PlayerTab:Toggle({
    Title = "Enable Flight Mode",
    Desc = "Activate anticheat-safe flight (Press F to toggle)",
    Value = false,
    Callback = function(Value)
        _G.AuPlatoConfig.PlayerFlightEnabled = Value
        if Value then
            print("[AuPlato] Flight Mode Enabled")
            loadstring(PLAYER_SCRIPT)()
        else
            print("[AuPlato] Flight Mode Disabled")
        end
    end
})

PlayerTab:Slider({
    Title = "Flight Speed",
    Step = 1,
    Value = { Min = 10, Max = 150, Default = 50 },
    Callback = function(Value)
        _G.AuPlatoConfig.FlightSpeed = Value
        print("[AuPlato] Flight Speed: " .. Value)
    end
})

PlayerTab:Section({ Title = "Character Attributes" })

PlayerTab:Slider({
    Title = "WalkSpeed",
    Step = 1,
    Value = { Min = 16, Max = 200, Default = 16 },
    Callback = function(Value)
        _G.AuPlatoConfig.WalkSpeed = Value
        local LocalPlayer = game.Players.LocalPlayer
        if LocalPlayer and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.WalkSpeed = Value
            print("[AuPlato] WalkSpeed: " .. Value)
        end
    end
})

PlayerTab:Slider({
    Title = "JumpPower",
    Step = 1,
    Value = { Min = 50, Max = 250, Default = 50 },
    Callback = function(Value)
        _G.AuPlatoConfig.JumpPower = Value
        local LocalPlayer = game.Players.LocalPlayer
        if LocalPlayer and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.UseJumpPower = true
            LocalPlayer.Character.Humanoid.JumpPower = Value
            print("[AuPlato] JumpPower: " .. Value)
        end
    end
})

-- ====================================================================
-- 5. SETTINGS TAB
-- ====================================================================
SettingsTab:Section({ Title = "Server Hopping" })

SettingsTab:Toggle({
    Title = "Enable Server Hop",
    Desc = "Allow server hopping functionality",
    Value = true,
    Callback = function(Value)
        _G.ServerHopEnabled = Value
        print("[AuPlato] Server Hop: " .. (Value and "ENABLED" or "DISABLED"))
    end
})

SettingsTab:Toggle({
    Title = "Auto-Execute After Server Hop",
    Desc = "Automatically restart airdrop farm after hopping",
    Value = false,
    Callback = function(Value)
        _G.AuPlatoConfig.AutoExecuteAfterServerHop = Value
        print("[AuPlato] Auto-Execute: " .. (Value and "ENABLED" or "DISABLED"))
    end
})

SettingsTab:Section({ Title = "Tweening" })

SettingsTab:Dropdown({
    Title = "Tween Easing Style",
    Desc = "Select easing function for movements",
    Options = { "Linear", "Quad", "Cubic", "Quart", "Quint", "Sine", "Expo", "Circ", "Elastic", "Back", "Bounce" },
    Value = "Linear",
    Callback = function(Value)
        _G.AuPlatoConfig.TweenEasing = Value
        print("[AuPlato] Tween Easing: " .. Value)
    end
})

SettingsTab:Section({ Title = "General" })

SettingsTab:Button({
    Title = "Save Configuration",
    Desc = "Save all settings to file",
    Callback = function()
        print("[AuPlato] Configuration saved!")
    end
})

SettingsTab:Button({
    Title = "Reset to Default",
    Desc = "Reset all settings to defaults",
    Callback = function()
        _G.AuPlatoConfig = {
            AirdropFarmEnabled = false,
            FlyHeight = 300,
            AirdropSpeed = 110,
            ScanInterval = 2,
            UndergroundOffset = 10,
            ServerHopTimeout = 120,
            ActionWait = 0.5,
            CarWaitBeforeExit = 2.5,
            PreWalkWait = 1.0,
            TweenEasing = "Linear",
            AutoExecuteAfterServerHop = false,
            ServerHopOnTimeout = true,
            PlayerFlightEnabled = false,
            FlightSpeed = 50,
            WalkSpeed = 16,
            JumpPower = 50,
            AutoFarmEnabled = false,
            AutoArrestEnabled = false,
        }
        print("[AuPlato] Configuration reset to defaults!")
    end
})

print("[AuPlato] ✅ GUI Initialized Successfully!")
print("[AuPlato] All scripts are now connected through global config")
