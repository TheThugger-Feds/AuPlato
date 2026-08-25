local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local SpawnRemote = ReplicatedStorage:FindFirstChild("GarageSpawnVehicle", true)

-- Initialize config fallback if not present
if not _G.AuPlatoConfig then
    _G.AuPlatoConfig = {
        FlyHeight = 300,
        AirdropSpeed = 110,
        ScanInterval = 2,
        UndergroundOffset = 10,
        ServerHopTimeout = 120,
        ActionWait = 0.5,
        CarWaitBeforeExit = 2.5,
        PreWalkWait = 1.0,
        TweenEasing = "Linear",
        ServerHopOnTimeout = true,
        AirdropFarmEnabled = false,
        AirdropStatus = "Idle",
    }
end

local FLY_HEIGHT = _G.AuPlatoConfig.FlyHeight or 300
local SPEED = _G.AuPlatoConfig.AirdropSpeed or 110
local SCAN_INTERVAL = _G.AuPlatoConfig.ScanInterval or 2
local UNDERGROUND_OFFSET = Vector3.new(0, -(_G.AuPlatoConfig.UndergroundOffset or 10), 0)
local SERVER_HOP_TIMEOUT = _G.AuPlatoConfig.ServerHopTimeout or 120
local ACTION_WAIT = _G.AuPlatoConfig.ActionWait or 0.5
local CAR_WAIT_BEFORE_EXIT = _G.AuPlatoConfig.CarWaitBeforeExit or 2.5
local PRE_WALK_WAIT = _G.AuPlatoConfig.PreWalkWait or 1.0
local TWEEN_EASING = _G.AuPlatoConfig.TweenEasing or "Linear"

local isRunning = false
local lastBriefcaseFoundTime = os.time()
local scriptActive = true

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

local function serverHop()
    if not (_G.ServerHopEnabled and _G.AuPlatoConfig.ServerHopOnTimeout) then
        _G.AuPlatoConfig.AirdropStatus = "Server hop disabled by config"
        return
    end
    
    _G.AuPlatoConfig.AirdropStatus = "Server hopping..."
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
                    _G.AuPlatoConfig.AirdropFarmEnabled = true
                end
                return
            end
        end
    end
    
    TeleportService:Teleport(placeId, LocalPlayer)
end

local function safePivotTween(model, targetCFrame, duration)
    if not model or not model:IsA("Model") then return end
    
    local cframeValue = Instance.new("CFrameValue")
    cframeValue.Value = model:GetPivot()
    
    local conn = cframeValue.Changed:Connect(function(newCFrame)
        if model and model.Parent then
            model:PivotTo(newCFrame)
        end
    end)
    
    local tweenInfo = TweenInfo.new(duration, getTweenEasing(TWEEN_EASING), Enum.EasingDirection.InOut)
    local tween = TweenService:Create(cframeValue, tweenInfo, {Value = targetCFrame})
    tween:Play()
    tween.Completed:Wait()
    
    conn:Disconnect()
    cframeValue:Destroy()
end

local function safePartTween(part, targetCFrame, duration)
    if not part or not part:IsA("BasePart") then return end
    local tweenInfo = TweenInfo.new(duration, getTweenEasing(TWEEN_EASING), Enum.EasingDirection.InOut)
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
    _G.AuPlatoConfig.AirdropStatus = "Spawning vehicle..."
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
            return car
        end
        retries = retries + 1
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
        task.wait(ACTION_WAIT)
        
        local hum = char:FindFirstChildWhichIsA("Humanoid")
        if hum then
            seat:Sit(hum)
            task.wait(ACTION_WAIT)
        end
        return hum and hum.SeatPart ~= nil
    end
    return false
end

local function executeBriefcaseRun(targetCrate)
    if not scriptActive then return end
    
    isRunning = true
    _G.AuPlatoConfig.AirdropStatus = "Target Found! Executing Run..."
    
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

    task.wait(ACTION_WAIT)

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
        local airStart = CFrame.new(startPivot.Position.X, FLY_HEIGHT, startPivot.Position.Z) * startPivot.Rotation
        local airCrate = CFrame.new(cratePos.X, FLY_HEIGHT, cratePos.Z) * startPivot.Rotation
        local groundTarget = CFrame.new(cratePos + Vector3.new(0, 3, 0)) * startPivot.Rotation

        _G.AuPlatoConfig.AirdropStatus = "Flying to Airdrop..."
        safePivotTween(car, airStart, 1.2)
        task.wait(ACTION_WAIT)

        local dist = (airStart.Position - airCrate.Position).Magnitude
        local flightTime = math.max(dist / SPEED, 0.5)
        safePivotTween(car, airCrate, flightTime)
        task.wait(ACTION_WAIT)

        _G.AuPlatoConfig.AirdropStatus = "Descending..."
        safePivotTween(car, groundTarget, 1.5)
        
        task.wait(CAR_WAIT_BEFORE_EXIT)
        hum.Sit = false
        task.wait(0.5)
    end

    task.wait(PRE_WALK_WAIT)

    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = false
        end
    end

    local safeUndergroundCFrame = CFrame.new(cratePos + UNDERGROUND_OFFSET)
    safePartTween(hrp, safeUndergroundCFrame, 0.5)
    task.wait(ACTION_WAIT)

    local pressRemote = targetCrate:FindFirstChild("BriefcasePress", true)
    local releaseRemote = targetCrate:FindFirstChild("BriefcaseRelease", true)
    local holdUpdateRemote = targetCrate:FindFirstChild("BriefcaseHoldUpdate", true)
    local collectRemote = targetCrate:FindFirstChild("BriefcaseCollect", true)
    
    local openDuration = targetCrate:GetAttribute("BriefcaseOpenTiming") or 4.0
    
    if pressRemote and collectRemote then
        _G.AuPlatoConfig.AirdropStatus = "Opening Briefcase Underground..."
        pcall(function() pressRemote:FireServer(false) end)
        task.wait(ACTION_WAIT)
        
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
        task.wait(ACTION_WAIT)
        
        pcall(function() collectRemote:FireServer() end)
        task.wait(ACTION_WAIT)
    end

    local aboveGroundCFrame = CFrame.new(cratePos + Vector3.new(0, 3, 0))
    safePartTween(hrp, aboveGroundCFrame, 0.5)
    task.wait(ACTION_WAIT)

    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = true
        end
    end

    task.wait(ACTION_WAIT)
    local returnCar = getMyVehicle()
    if returnCar then
        enterVehicle(returnCar)
    end
    
    _G.AuPlatoConfig.AirdropStatus = "Airdrop Claimed! Resuming Scan..."
    isRunning = false
    lastBriefcaseFoundTime = os.time()
end

task.spawn(function()
    while scriptActive do
        task.wait(SCAN_INTERVAL)
        
        FLY_HEIGHT = _G.AuPlatoConfig.FlyHeight or 300
        SPEED = _G.AuPlatoConfig.AirdropSpeed or 110
        SCAN_INTERVAL = _G.AuPlatoConfig.ScanInterval or 2
        UNDERGROUND_OFFSET = Vector3.new(0, -(_G.AuPlatoConfig.UndergroundOffset or 10), 0)
        SERVER_HOP_TIMEOUT = _G.AuPlatoConfig.ServerHopTimeout or 120
        ACTION_WAIT = _G.AuPlatoConfig.ActionWait or 0.5
        CAR_WAIT_BEFORE_EXIT = _G.AuPlatoConfig.CarWaitBeforeExit or 2.5
        PRE_WALK_WAIT = _G.AuPlatoConfig.PreWalkWait or 1.0
        TWEEN_EASING = _G.AuPlatoConfig.TweenEasing or "Linear"
        
        if _G.AuPlatoConfig.AirdropFarmEnabled and not isRunning then
            local target = getActiveBriefcase()
            if target then
                lastBriefcaseFoundTime = os.time()
                pcall(function()
                    executeBriefcaseRun(target)
                end)
            else
                local elapsed = os.time() - lastBriefcaseFoundTime
                _G.AuPlatoConfig.AirdropStatus = "Scanning for Airdrops... (" .. tostring(SERVER_HOP_TIMEOUT - elapsed) .. "s to hop)"
                if elapsed >= SERVER_HOP_TIMEOUT then
                    serverHop()
                    break
                end
            end
        elseif not _G.AuPlatoConfig.AirdropFarmEnabled then
            _G.AuPlatoConfig.AirdropStatus = "Idle"
            lastBriefcaseFoundTime = os.time()
        end
    end
end)
