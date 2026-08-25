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

    -- ESP Settings
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

-- Global flags
_G.ServerHopEnabled = true

-- State trackers for single-instance script initialization
local airdropScriptLoaded = false
local flightScriptLoaded = false
local espScriptLoaded = false

-- Create Tabs
local AutoFarmTab = Window:Tab({ Title = "Auto Farm", Icon = "coins" })
local AirdropTab  = Window:Tab({ Title = "Airdrop Farm", Icon = "box" })
local ArrestTab   = Window:Tab({ Title = "Auto Arrest", Icon = "shield-alert" })
local PlayerTab   = Window:Tab({ Title = "Local Player", Icon = "user" })
local EspTab      = Window:Tab({ Title = "ESP Visuals", Icon = "eye" })
local SettingsTab = Window:Tab({ Title = "Settings", Icon = "settings" })

-- Helper function to dynamic-load ESP script on first toggle
local function ensureEspLoaded()
    if not espScriptLoaded then
        espScriptLoaded = true
        task.spawn(function()
            loadstring(game:HttpGet("https://raw.githubusercontent.com/TheThugger-Feds/AuPlato/refs/heads/main/Esp.lua"))()
        end)
    end
end

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
        if Value and not airdropScriptLoaded then
            airdropScriptLoaded = true
            task.spawn(function()
                loadstring(game:HttpGet("https://raw.githubusercontent.com/TheThugger-Feds/AuPlato/refs/heads/main/Airdrop.lua"))()
            end)
        end
    end
})

AirdropTab:Section({ Title = "Flight Configuration" })

AirdropTab:Slider({
    Title = "Flight Height",
    Step = 10,
    Value = { Min = 100, Max = 500, Default = 300 },
    Callback = function(Value) _G.AuPlatoConfig.FlyHeight = Value end
})

AirdropTab:Slider({
    Title = "Flight Speed",
    Step = 5,
    Value = { Min = 50, Max = 200, Default = 110 },
    Callback = function(Value) _G.AuPlatoConfig.AirdropSpeed = Value end
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
        if Value and not flightScriptLoaded then
            flightScriptLoaded = true
            task.spawn(function()
                loadstring(game:HttpGet("https://raw.githubusercontent.com/TheThugger-Feds/AuPlato/refs/heads/main/LocalPlayer.lua"))()
            end)
        end
    end
})

PlayerTab:Slider({
    Title = "Flight Speed",
    Step = 1,
    Value = { Min = 10, Max = 150, Default = 50 },
    Callback = function(Value) _G.AuPlatoConfig.FlightSpeed = Value end
})

PlayerTab:Slider({
    Title = "WalkSpeed",
    Step = 1,
    Value = { Min = 16, Max = 200, Default = 16 },
    Callback = function(Value)
        _G.AuPlatoConfig.WalkSpeed = Value
        local lp = game.Players.LocalPlayer
        if lp and lp.Character and lp.Character:FindFirstChild("Humanoid") then
            lp.Character.Humanoid.WalkSpeed = Value
        end
    end
})

PlayerTab:Slider({
    Title = "JumpPower",
    Step = 1,
    Value = { Min = 50, Max = 250, Default = 50 },
    Callback = function(Value)
        _G.AuPlatoConfig.JumpPower = Value
        local lp = game.Players.LocalPlayer
        if lp and lp.Character and lp.Character:FindFirstChild("Humanoid") then
            lp.Character.Humanoid.UseJumpPower = true
            lp.Character.Humanoid.JumpPower = Value
        end
    end
})

-- ====================================================================
-- 5. ESP TAB
-- ====================================================================
EspTab:Section({ Title = "Team ESP Toggles" })

EspTab:Toggle({
    Title = "Police ESP",
    Desc = "Highlight players on the Police team",
    Value = false,
    Callback = function(Value)
        _G.AuPlatoConfig.PoliceEspEnabled = Value
        if Value then ensureEspLoaded() end
    end
})

EspTab:Toggle({
    Title = "Criminal ESP",
    Desc = "Highlight players on the Criminal team",
    Value = false,
    Callback = function(Value)
        _G.AuPlatoConfig.CriminalEspEnabled = Value
        if Value then ensureEspLoaded() end
    end
})

EspTab:Toggle({
    Title = "Prisoner ESP",
    Desc = "Highlight players on the Prisoner team",
    Value = false,
    Callback = function(Value)
        _G.AuPlatoConfig.PrisonerEspEnabled = Value
        if Value then ensureEspLoaded() end
    end
})

EspTab:Section({ Title = "Visual Overlays" })

EspTab:Toggle({
    Title = "Show Username",
    Desc = "Display character display name / username above player",
    Value = true,
    Callback = function(Value)
        _G.AuPlatoConfig.ShowUsername = Value
    end
})

EspTab:Toggle({
    Title = "Show Distance",
    Desc = "Display real-time distance in studs below player",
    Value = true,
    Callback = function(Value)
        _G.AuPlatoConfig.ShowDistance = Value
    end
})

EspTab:Toggle({
    Title = "Show Health Bars",
    Desc = "Display health status bar next to target",
    Value = true,
    Callback = function(Value)
        _G.AuPlatoConfig.ShowHealth = Value
    end
})

EspTab:Toggle({
    Title = "Show Tracers / Snaplines",
    Desc = "Draw screen lines from bottom center to target",
    Value = false,
    Callback = function(Value)
        _G.AuPlatoConfig.ShowTracers = Value
    end
})

EspTab:Section({ Title = "Color Customization" })

EspTab:Colorpicker({
    Title = "Police Team Color",
    Default = Color3.fromRGB(0, 150, 255),
    Callback = function(Value)
        _G.AuPlatoConfig.PoliceColor = Value
    end
})

EspTab:Colorpicker({
    Title = "Criminal Team Color",
    Default = Color3.fromRGB(255, 50, 50),
    Callback = function(Value)
        _G.AuPlatoConfig.CriminalColor = Value
    end
})

EspTab:Colorpicker({
    Title = "Prisoner Team Color",
    Default = Color3.fromRGB(255, 170, 0),
    Callback = function(Value)
        _G.AuPlatoConfig.PrisonerColor = Value
    end
})

-- ====================================================================
-- 6. SETTINGS TAB
-- ====================================================================
SettingsTab:Section({ Title = "Server Hopping" })

SettingsTab:Toggle({
    Title = "Enable Server Hop",
    Value = true,
    Callback = function(Value) _G.ServerHopEnabled = Value end
})

print("[AuPlato] ✅ GUI Initialized with ESP Tab!")

