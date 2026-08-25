--[[
    AuPlato Framework - Dynamic Scaled ESP Module
    - Fixed huge billboard/health bar screen takeover
    - Uses 3D World space offset and StudsScale to match camera distance
]]--

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

if not _G.AuPlatoConfig then
    _G.AuPlatoConfig = {
        PoliceEspEnabled = false,
        CriminalEspEnabled = false,
        PrisonerEspEnabled = false,
        ShowDistance = true,
        ShowUsername = true,
        ShowHealth = true,
        ShowTracers = false,
        PoliceColor = Color3.fromRGB(0, 150, 255),
        CriminalColor = Color3.fromRGB(255, 50, 50),
        PrisonerColor = Color3.fromRGB(255, 170, 0),
    }
end

local ESPFolder = Instance.new("Folder")
ESPFolder.Name = "AuPlato_ESP_Container"
ESPFolder.Parent = CoreGui

local activeTrackers = {}

local function getPlayerTeamCategory(player)
    if not player or not player.Team then return nil end
    local teamName = string.lower(player.Team.Name)
    
    if string.find(teamName, "police") or string.find(teamName, "cop") or string.find(teamName, "guard") then
        return "Police"
    elseif string.find(teamName, "crim") or string.find(teamName, "inmate") or string.find(teamName, "villain") then
        return "Criminal"
    elseif string.find(teamName, "pris") then
        return "Prisoner"
    end
    
    return nil
end

local function isEspActiveForPlayer(player)
    if player == LocalPlayer then return false, nil end
    local category = getPlayerTeamCategory(player)
    
    if category == "Police" and _G.AuPlatoConfig.PoliceEspEnabled then
        return true, _G.AuPlatoConfig.PoliceColor
    elseif category == "Criminal" and _G.AuPlatoConfig.CriminalEspEnabled then
        return true, _G.AuPlatoConfig.CriminalColor
    elseif category == "Prisoner" and _G.AuPlatoConfig.PrisonerEspEnabled then
        return true, _G.AuPlatoConfig.PrisonerColor
    end
    
    return false, nil
end

local function createESPTracker(player)
    if activeTrackers[player] then return end

    local tracker = {
        Player = player,
        Highlight = nil,
        Billboard = nil,
        TextLabel = nil,
        HealthBarFrame = nil,
        HealthFill = nil,
        TracerLine = nil
    }

    -- Character Highlight
    local highlight = Instance.new("Highlight")
    highlight.Name = "AuPlato_HL_" .. player.Name
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.FillTransparency = 0.6
    highlight.OutlineTransparency = 0
    highlight.Enabled = false
    highlight.Parent = ESPFolder
    tracker.Highlight = highlight

    -- Dynamically Scaled Overhead Billboard
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "AuPlato_BB_" .. player.Name
    billboard.Size = UDim2.new(0, 120, 0, 40) -- Scaled down pixel baseline
    billboard.StudsOffsetWorldSpace = Vector3.new(0, 3.5, 0)
    billboard.AlwaysOnTop = true
    billboard.SizeOffset = Vector2.new(0, 0)
    billboard.MaxDistance = 2500
    billboard.Enabled = false
    billboard.Parent = ESPFolder
    tracker.Billboard = billboard

    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, 0, 0.6, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    textLabel.TextStrokeTransparency = 0
    textLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    textLabel.Font = Enum.Font.SourceSansBold
    textLabel.TextSize = 13
    textLabel.TextScaled = false
    textLabel.Text = ""
    textLabel.Parent = billboard
    tracker.TextLabel = textLabel

    -- Scaled Health Bar
    local healthBg = Instance.new("Frame")
    healthBg.Size = UDim2.new(0.8, 0, 0.12, 0)
    healthBg.Position = UDim2.new(0.1, 0, 0.7, 0)
    healthBg.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    healthBg.BorderSizePixel = 1
    healthBg.BorderColor3 = Color3.fromRGB(0, 0, 0)
    healthBg.Parent = billboard
    tracker.HealthBarFrame = healthBg

    local healthFill = Instance.new("Frame")
    healthFill.Size = UDim2.new(1, 0, 1, 0)
    healthFill.BackgroundColor3 = Color3.fromRGB(0, 255, 100)
    healthFill.BorderSizePixel = 0
    healthFill.Parent = healthBg
    tracker.HealthFill = healthFill

    -- Tracers
    if Drawing then
        local line = Drawing.new("Line")
        line.Thickness = 1.5
        line.Transparency = 1
        line.Visible = false
        tracker.TracerLine = line
    end

    activeTrackers[player] = tracker
end

local function removeESPTracker(player)
    local tracker = activeTrackers[player]
    if tracker then
        if tracker.Highlight then tracker.Highlight:Destroy() end
        if tracker.Billboard then tracker.Billboard:Destroy() end
        if tracker.TracerLine then tracker.TracerLine:Remove() end
        activeTrackers[player] = nil
    end
end

RunService.RenderStepped:Connect(function()
    local localChar = LocalPlayer.Character
    local localHrp = localChar and localChar:FindFirstChild("HumanoidRootPart")

    for player, tracker in pairs(activeTrackers) do
        local enabled, teamColor = isEspActiveForPlayer(player)
        local targetChar = player.Character
        local targetHrp = targetChar and targetChar:FindFirstChild("HumanoidRootPart")
        local targetHum = targetChar and targetChar:FindFirstChildWhichIsA("Humanoid")

        if enabled and targetChar and targetHrp and targetHum and targetHum.Health > 0 then
            -- Update Highlight
            tracker.Highlight.Adornee = targetChar
            tracker.Highlight.FillColor = teamColor
            tracker.Highlight.OutlineColor = teamColor
            tracker.Highlight.Enabled = true

            -- Distance calculation for visual scaling
            local distance = localHrp and math.floor((localHrp.Position - targetHrp.Position).Magnitude) or 0
            
            -- Update Billboard Attachment & Position
            tracker.Billboard.Adornee = targetHrp
            tracker.Billboard.Enabled = true

            -- Dynamically scale text size based on distance
            if distance > 300 then
                tracker.TextLabel.TextSize = 11
            else
                tracker.TextLabel.TextSize = 13
            end

            -- Construct Overhead Labels
            local displayText = ""
            if _G.AuPlatoConfig.ShowUsername then
                displayText = player.DisplayName .. " (@" .. player.Name .. ")"
            end

            if localHrp and _G.AuPlatoConfig.ShowDistance then
                if displayText ~= "" then
                    displayText = displayText .. "\n[" .. tostring(distance) .. " studs]"
                else
                    displayText = "[" .. tostring(distance) .. " studs]"
                end
            end

            tracker.TextLabel.Text = displayText
            tracker.TextLabel.TextColor3 = teamColor

            -- Update Health Bar
            if _G.AuPlatoConfig.ShowHealth then
                tracker.HealthBarFrame.Visible = true
                local healthPercent = math.clamp(targetHum.Health / targetHum.MaxHealth, 0, 1)
                tracker.HealthFill.Size = UDim2.new(healthPercent, 0, 1, 0)
                tracker.HealthFill.BackgroundColor3 = Color3.fromRGB(255, 0, 0):Lerp(Color3.fromRGB(0, 255, 100), healthPercent)
            else
                tracker.HealthBarFrame.Visible = false
            end

            -- Update Tracers
            if tracker.TracerLine then
                if _G.AuPlatoConfig.ShowTracers then
                    local screenPos, onScreen = Camera:WorldToViewportPoint(targetHrp.Position)
                    if onScreen then
                        tracker.TracerLine.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                        tracker.TracerLine.To = Vector2.new(screenPos.X, screenPos.Y)
                        tracker.TracerLine.Color = teamColor
                        tracker.TracerLine.Visible = true
                    else
                        tracker.TracerLine.Visible = false
                    end
                else
                    tracker.TracerLine.Visible = false
                end
            end
        else
            tracker.Highlight.Enabled = false
            tracker.Billboard.Enabled = false
            if tracker.TracerLine then
                tracker.TracerLine.Visible = false
            end
        end
    end
end)

for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then createESPTracker(player) end
end

Players.PlayerAdded:Connect(function(player)
    if player ~= LocalPlayer then createESPTracker(player) end
end)

Players.PlayerRemoving:Connect(function(player)
    removeESPTracker(player)
end)

