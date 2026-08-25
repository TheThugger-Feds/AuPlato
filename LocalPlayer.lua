--[[
    Replicated Game Flight Script
    - Matches CmdrClient fly logic directly
    - Hooks into PlayerModule / ControlModule GetMoveVector()
    - Uses Heartbeat loop with zeroed AssemblyVelocities
]]--

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

local flyConnection = nil
local getMoveVectorFunc = nil

-- Initialize config fallback if not present
if not _G.AuPlatoConfig then
    _G.AuPlatoConfig = {
        PlayerFlightEnabled = false,
        FlightSpeed = 50,
    }
end

--------------------------------------------------
-- CONTROL MODULE BINDING
--------------------------------------------------
local function setupControlModule()
    if getMoveVectorFunc then return true end
    
    local playerScripts = LocalPlayer:FindFirstChild("PlayerScripts")
    if not playerScripts then return false end

    local playerModule = playerScripts:WaitForChild("PlayerModule", 5)
    if playerModule then
        local controlModule = playerModule:WaitForChild("ControlModule", 5)
        if controlModule then
            local controls = require(controlModule)
            getMoveVectorFunc = function()
                return controls:GetMoveVector()
            end
            return true
        end
    end
    return false
end

--------------------------------------------------
-- FLIGHT SYSTEM
--------------------------------------------------
local function stopFlight()
    if flyConnection then
        flyConnection:Disconnect()
        flyConnection = nil
    end
    print("[LocalPlayer] Flight Mode Deactivated")
end

local function startFlight()
    stopFlight()

    if not setupControlModule() then
        warn("[LocalPlayer] Failed to hook ControlModule")
        return
    end

    print("[LocalPlayer] Flight Mode Activated")

    flyConnection = RunService.Heartbeat:Connect(function(deltaTime)
        if not _G.AuPlatoConfig.PlayerFlightEnabled then
            stopFlight()
            return
        end

        local character = LocalPlayer.Character
        if not character or not character:FindFirstChild("PrimaryPart") then return end

        local primaryPart = character.PrimaryPart
        local camera = workspace.CurrentCamera
        local speed = _G.AuPlatoConfig.FlightSpeed or 50

        -- Fetch move vector (WASD / Mobile Thumbstick / Controller)
        local moveVector = getMoveVectorFunc()
        
        -- Calculate direction matching the game's original fly command
        local direction = (camera.CFrame.RightVector * moveVector.X) + (camera.CFrame.LookVector * -moveVector.Z)
        if direction.Magnitude > 0 then
            direction = direction.Unit
        end

        -- Calculate next target CFrame
        local nextPosition = primaryPart.Position + (direction * speed * deltaTime)

        -- Replicate native velocity locking and CFrame updating
        primaryPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
        primaryPart.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
        primaryPart.CFrame = CFrame.new(nextPosition, nextPosition + camera.CFrame.LookVector)
    end)
end

--------------------------------------------------
-- STATE MONITOR
--------------------------------------------------
RunService.RenderStepped:Connect(function()
    if _G.AuPlatoConfig.PlayerFlightEnabled and not flyConnection then
        startFlight()
    elseif not _G.AuPlatoConfig.PlayerFlightEnabled and flyConnection then
        stopFlight()
    end
end)

