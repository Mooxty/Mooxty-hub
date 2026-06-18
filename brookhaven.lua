-- Mooxty Hub | Brookhaven RP
loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "Mooxty Hub | Brookhaven RP",
    LoadingTitle = "Mooxty Hub",
    LoadingSubtitle = "by Grok",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "MooxtyHub",
        FileName = "Brookhaven"
    },
    Discord = {
        Enabled = true,
        Invite = "9SfemsAnw",
        RememberJoins = true
    },
    KeySystem = true,
    KeySettings = {
        Title = "Mooxty Key System",
        Subtitle = "Join Discord for Key",
        Note = "Key is case sensitive!",
        FileName = "MooxtyKey",
        SaveKey = true,
        GrabKeyFromSite = false,
        Key = {"Mooxty"}
    }
})

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local flying = false
local noclipping = false
local flySpeed = 60

local function startFly()
    if flying then return end
    flying = true
    local root = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local bv = Instance.new("BodyVelocity")
    local bg = Instance.new("BodyGyro")
    bv.MaxForce = Vector3.new(9e4, 9e4, 9e4)
    bg.MaxTorque = Vector3.new(9e4, 9e4, 9e4)
    bg.P = 12500
    bv.Parent = root
    bg.Parent = root

    spawn(function()
        while flying and root.Parent do
            local cam = Workspace.CurrentCamera
            local move = Vector3.new()
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then move += cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then move -= cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then move -= cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then move += cam.CFrame.RightVector end

            bv.Velocity = move.Magnitude > 0 and move.Unit * flySpeed or Vector3.new()
            bg.CFrame = cam.CFrame
            task.wait()
        end
    end)
end

local function stopFly()
    flying = false
    local root = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if root then
        for _, v in pairs(root:GetChildren()) do
            if v:IsA("BodyVelocity") or v:IsA("BodyGyro") then v:Destroy() end
        end
    end
end

local function noclipLoop()
    while noclipping do
        for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide then
                part.CanCollide = false
            end
        end
        task.wait()
    end
end

local MainTab = Window:CreateTab("🏠 Main", nil)
local PlayerTab = Window:CreateTab("👤 Player", nil)
local VisualTab = Window:CreateTab("👁️ Visual", nil)
local TrollTab = Window:CreateTab("😈 Troll", nil)
local MiscTab = Window:CreateTab("⚙️ Misc", nil)

MainTab:CreateButton({
    Name = "📋 Copy Discord",
    Callback = function()
        setclipboard("discord.gg/9SfemsAnw")
        Rayfield:Notify({Title = "Copied!", Content = "Discord link copied!", Duration = 3})
    end
})

PlayerTab:CreateSection("Movement")

PlayerTab:CreateToggle({
    Name = "✈️ Fly",
    CurrentValue = false,
    Callback = function(Value)
        if Value then startFly() else stopFly() end
    end,
})

PlayerTab:CreateToggle({
    Name = "🚶 Noclip",
    CurrentValue = false,
    Callback = function(Value)
        noclipping = Value
        if Value then spawn(noclipLoop) end
    end,
})

PlayerTab:CreateSlider({
    Name = "🏃 WalkSpeed",
    Range = {16, 300},
    Increment = 1,
    CurrentValue = 16,
    Callback = function(Value)
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
        if hum then hum.WalkSpeed = Value end
    end,
})

PlayerTab:CreateSlider({
    Name = "🦘 JumpPower",
    Range = {50, 500},
    Increment = 10,
    CurrentValue = 50,
    Callback = function(Value)
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
        if hum then hum.JumpPower = Value end
    end,
})

PlayerTab:CreateButton({
    Name = "🛡️ Godmode",
    Callback = function()
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
        if hum then
            hum.MaxHealth = math.huge
            hum.Health = math.huge
        end
        Rayfield:Notify({Title = "Godmode", Content = "Activated!", Duration = 4})
    end
})

VisualTab:CreateToggle({
    Name = "👥 Player ESP",
    CurrentValue = false,
    Callback = function(Value)
        Rayfield:Notify({Title = "ESP", Content = Value and "Enabled" or "Disabled", Duration = 3})
    end,
})

MiscTab:CreateButton({
    Name = "🔄 Rejoin Server",
    Callback = function()
        game:GetService("TeleportService"):Teleport(game.PlaceId, LocalPlayer)
    end,
})

Rayfield:Notify({
    Title = "Mooxty Hub Loaded!",
    Content = "Enjoy Brookhaven RP!",
    Duration = 6
})
