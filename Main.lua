-- Fetch and initialize WindUI
local WindUI = loadstring(game:HttpGet("https://tree-hub.vercel.app/api/UI/WindUI"))()

-- Create the Main Window
local Window = WindUI:CreateWindow({
    Title = "AuPlatoHub",
    Icon = "rbxassetid://4483345998",
    Author = "AuPlato",
    Folder = "AuPlatoHubConfig",
    Size = UDim2.fromOffset(580, 460),
    Transparent = true,
    Theme = "Dark"
})

-- Create Requested Tabs
local AutoFarmTab = Window:Tab({ Title = "Auto Farm", Icon = "coins" })
local AirdropTab  = Window:Tab({ Title = "Airdrop Farm", Icon = "box" })
local ArrestTab   = Window:Tab({ Title = "Auto Arrest", Icon = "shield-alert" })
local PlayerTab   = Window:Tab({ Title = "Local Player", Icon = "user" })

-- ====================================================================
-- 1. AUTO FARM TAB
-- ====================================================================
AutoFarmTab:Section({ Title = "Automated Farming" })

AutoFarmTab:Toggle({
    Title = "Auto Farm",
    Desc = "Slide to activate or disable cash auto farm",
    Value = false,
    Callback = function(Value)
        _G.AutoFarmEnabled = Value
        if Value then
            -- Insert Auto Farm loop here
        end
    end
})

-- ====================================================================
-- 2. AIRDROP FARM TAB
-- ====================================================================
AirdropTab:Section({ Title = "Airdrop Collection" })

AirdropTab:Toggle({
    Title = "Auto Collect Airdrops",
    Desc = "Slide to activate or disable crate collection",
    Value = false,
    Callback = function(Value)
        _G.AirdropFarmEnabled = Value
        if Value then
            -- Insert Airdrop detection loop here
        end
    end
})

-- ====================================================================
-- 3. AUTO ARREST TAB
-- ====================================================================
ArrestTab:Section({ Title = "Cop Mechanics" })

ArrestTab:Toggle({
    Title = "Auto Arrest",
    Desc = "Slide to activate or disable automatic criminal arrest",
    Value = false,
    Callback = function(Value)
        _G.AutoArrestEnabled = Value
        if Value then
            -- Insert arrest target loop here
        end
    end
})

-- ====================================================================
-- 4. LOCAL PLAYER TAB
-- ====================================================================
PlayerTab:Section({ Title = "Character Attributes" })

PlayerTab:Slider({
    Title = "WalkSpeed",
    Step = 1,
    Value = { Min = 16, Max = 150, Default = 16 },
    Callback = function(Value)
        local LocalPlayer = game.Players.LocalPlayer
        if LocalPlayer and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.WalkSpeed = Value
        end
    end
})

PlayerTab:Slider({
    Title = "JumpPower",
    Step = 1,
    Value = { Min = 50, Max = 200, Default = 50 },
    Callback = function(Value)
        local LocalPlayer = game.Players.LocalPlayer
        if LocalPlayer and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") me
            LocalPlayer.Character.Humanoid.UseJumpPower = true
            LocalPlayer.Character.Humanoid.JumpPower = Value
        end
    end
})

