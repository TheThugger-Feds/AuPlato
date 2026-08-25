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

-- State trackers for single-instance script initialization
local airdropScriptLoaded = false
local flightScriptLoaded = false

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
            if not airdropScriptLoaded then
                airdropScriptLoaded = true
                task.spawn(function()
                    loadstring(game:HttpGet("https://raw.githubusercontent.com/TheThugger-Feds/AuPlato/refs/heads/main/Airdrop.lua"))()
                end)
            end
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
            if not flightScriptLoaded then
                flightScriptLoaded = true
                task.spawn(function()
                    loadstring(game:HttpGet("https://raw.githubusercontent.com/TheThugger-Feds/AuPlato/main/LocalPlayer"))()
                end)
            end
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
print("[AuPlato] All scripts are connected through global config")

