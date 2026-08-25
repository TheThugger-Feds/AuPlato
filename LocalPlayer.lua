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

-- Initialize config fallback if not present
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
    flying = false
    print("[LocalPlayer] Flight Mode Deactivated")
    
    if setupCharacter() then
        -- Re-enable humanoid physics
        humanoid.PlatformStand = false
        
        -- Re-enable character collision
        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = true
            end
        end
    end
    
    -- Reset velocity vectors
    velocity = Vector3.new(0, 0, 0)
    direction = Vector3.new(0, 0, 0)
end

local function updateFlight(deltaTime)
    if not flying or not setupCharacter() then return end
    
    -- Update flight speed from global config
    local FlightSpeed = _G.AuPlatoConfig.FlightSpeed or 50
    
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
    
    local inputDir = Vector3.new(moveX, moveY, moveZ)
    if inputDir.Magnitude > 0 then
        inputDir = inputDir.Unit
    end
    
    -- Calculate relative direction based on camera
    local camera = workspace.CurrentCamera
    local cameraCFrame = camera.CFrame
    
    local rightVec = cameraCFrame.RightVector
    local upVec = Vector3.new(0, 1, 0)
    local lookVec = cameraCFrame.LookVector * Vector3.new(1, 0, 1)
    
    if lookVec.Magnitude > 0 then
        lookVec = lookVec.Unit
    else
        lookVec = cameraCFrame.LookVector
    end
    
    local moveDirection = (rightVec * inputDir.X + upVec * inputDir.Y + lookVec * inputDir.Z)
    
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
    
    -- Apply slight gravity resistance when idle
    if not UserInputService:IsKeyDown(Enum.KeyCode.Space) and not UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
        velocity = velocity - Vector3.new(0, Gravity, 0)
    end
    
    -- Update position cleanly using deltaTime
    local step = (deltaTime and deltaTime > 0) and deltaTime or 0.016
    humanoidRootPart.CFrame = humanoidRootPart.CFrame + velocity * step
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
-- MAIN LOOP & RESPONSIVE STATE MONITOR
--------------------------------------------------
RunService.RenderStepped:Connect(function(deltaTime)
    -- Start or stop flight dynamically based on UI Toggle state
    if _G.AuPlatoConfig.PlayerFlightEnabled and not flying then
        startFlight()
    elseif not _G.AuPlatoConfig.PlayerFlightEnabled and flying then
        stopFlight()
    end
    
    if flying then
        updateFlight(deltaTime)
    end
end)

--------------------------------------------------
-- RESPAWN HANDLER
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

print("[LocalPlayer] Flight script loaded! Press F or toggle UI to flight mode")
print("[LocalPlayer] Controls: W/A/S/D to move, Space/Ctrl for vertical elevation")
