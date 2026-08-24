--[[
    Anticheat-Safe Flight Script
    - Uses realistic physics simulation
    - Gradual speed changes (no instant velocity changes)
    - Realistic acceleration/deceleration
    - Reads from global config
]]--

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local scriptActive = true
local flightActive = false

-- Flight configuration
local Acceleration = 2
local MaxSpeed = 100
local Gravity = 0.2

-- Flight state
local flying = false
local character = nil
local humanoidRootPart = nil
local humanoid = nil
local velocity = Vector3.new(0, 0, 0)
local direction = Vector3.new(0, 0, 0)

-- Initialize config if not already present
if not _G.AuPlatoConfig then
    _G.AuPlatoConfig = {
        PlayerFlightEnabled = false,
        FlightSpeed = 50,
    }
end

--------------------------------------------------
-- UTILITY FUNCTIONS
--------------------------------------------------
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

--------------------------------------------------
-- FLIGHT SYSTEM
--------------------------------------------------
local function startFlight()
    if not setupCharacter() then return end
    
    flying = true
    flightActive = true
    print("[LocalPlayer] Flight Mode Activated")
    
    -- Disable default humanoid physics
    humanoid.PlatformStand = true
    
    -- Disable character collision effects
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
    print("[LocalPlayer] Flight Mode Deactivated")
    
    -- Re-enable humanoid physics
    humanoid.PlatformStand = false
    
    -- Re-enable character collision
    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = true
        end
    end
    
    -- Let gravity take over
    velocity = Vector3.new(0, 0, 0)
end

local function updateFlight()
    if not flying or not setupCharacter() then return end
    
    -- Update flight speed from global config
    local FlightSpeed = _G.AuPlatoConfig.FlightSpeed or 50
    
    local moveDirection = Vector3.new(0, 0, 0)
    
    -- Get input direction
    local moveZ = 0
    local moveX = 0
    local moveY = 0
    
    if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveZ = moveZ - 1 end
    if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveZ = moveZ + 1 end
    if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveX = moveX - 1 end
    if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveX = moveX + 1 end
    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveY = moveY + 1 end
    if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then moveY = moveY - 1 end
    
    -- Normalize input
    local inputDir = Vector3.new(moveX, moveY, moveZ).Unit
    if inputDir.Magnitude == 0 then
        inputDir = Vector3.new(0, 0, 0)
    end
    
    -- Apply camera-relative movement
    local camera = workspace.CurrentCamera
    local cameraCFrame = camera.CFrame
    
    -- Calculate relative direction based on camera
    local rightVec = cameraCFrame.RightVector
    local upVec = Vector3.new(0, 1, 0)
    local lookVec = cameraCFrame.LookVector * Vector3.new(1, 0, 1)
    lookVec = lookVec.Unit
    
    moveDirection = (rightVec * inputDir.X + upVec * inputDir.Y + lookVec * inputDir.Z)
    
    -- Smooth acceleration/deceleration
    if moveDirection.Magnitude > 0 then
        direction = direction:Lerp(moveDirection, 0.1)
        velocity = velocity:Lerp(direction * FlightSpeed, Acceleration / 100)
    else
        direction = direction:Lerp(Vector3.new(0, 0, 0), 0.15)
        velocity = velocity:Lerp(direction * FlightSpeed, Acceleration / 150)
    end
    
    -- Clamp velocity to max speed
    if velocity.Magnitude > MaxSpeed then
        velocity = velocity.Unit * MaxSpeed
    end
    
    -- Apply gravity resistance (not complete anti-gravity, more realistic)
    if not UserInputService:IsKeyDown(Enum.KeyCode.Space) and not UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
        velocity = velocity - Vector3.new(0, Gravity, 0)
    end
    
    -- Update position
    local newCFrame = humanoidRootPart.CFrame + velocity * 0.016 -- deltaTime approximation
    humanoidRootPart.CFrame = newCFrame
end

local function handleCharacterRespawn()
    local conn
    conn = LocalPlayer.CharacterAdded:Connect(function()
        if flying then
            task.wait(0.5)
            if _G.AuPlatoConfig.PlayerFlightEnabled and setupCharacter() then
                startFlight()
            end
        end
    end)
end

--------------------------------------------------
-- INPUT HANDLING
--------------------------------------------------
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

--------------------------------------------------
-- MAIN LOOP
--------------------------------------------------
local flightConnection
flightConnection = RunService.RenderStepped:Connect(function()
    -- Check if flight should be active
    if _G.AuPlatoConfig.PlayerFlightEnabled and not flying and scriptActive then
        startFlight()
    elseif not _G.AuPlatoConfig.PlayerFlightEnabled and flying then
        stopFlight()
    end
    
    if flying then
        updateFlight()
    end
end)

--------------------------------------------------
-- CLEANUP
--------------------------------------------------
LocalPlayer.CharacterAdded:Connect(function()
    if flying then
        stopFlight()
    end
    if _G.AuPlatoConfig.PlayerFlightEnabled then
        task.wait(0.5)
        startFlight()
    end
end)

-- Clean up when script is disabled
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

print("[LocalPlayer] Flight script loaded! Press F to toggle flight")
print("[LocalPlayer] W/A/S/D to move, Space/Ctrl for up/down")
