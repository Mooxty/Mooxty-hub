-- Mooxty Hub | Brookhaven RP | English | Mobile Fly Fix
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TeleportService = game:GetService("TeleportService")
local VirtualUser = game:GetService("VirtualUser")

-- State
local States = {
    Fly = false,
    Noclip = false,
    Invisible = false,
    Godmode = false,
    AntiAFK = false,
    ESP = false,
}
local FlySpeed = 80
local SelectedPlayer = nil
local FlyConn, NoclipConn, GodConn, AFKConn
local ESPObjects = {}

local function Notify(Title, Content, Duration)
    Rayfield:Notify({ Title = Title, Content = Content, Duration = Duration or 4 })
end

local function GetCharacter()
    return LocalPlayer.Character
end

local function GetHumanoid()
    local char = GetCharacter()
    return char and char:FindFirstChildOfClass("Humanoid")
end

local function GetHRP()
    local char = GetCharacter()
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function GetPlayerNames()
    local list = {}
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            table.insert(list, plr.Name)
        end
    end
    if #list == 0 then
        table.insert(list, "No other players")
    end
    return list
end

local function GetPlayerByName(name)
    return Players:FindFirstChild(name)
end

-- ===================== FLY (Mobile + PC) =====================
local FlyBV, FlyBG

local function StopFly()
    States.Fly = false
    if FlyConn then
        FlyConn:Disconnect()
        FlyConn = nil
    end
    local hum = GetHumanoid()
    if hum then
        hum.PlatformStand = false
    end
    local hrp = GetHRP()
    if hrp then
        if FlyBV then FlyBV:Destroy() FlyBV = nil end
        if FlyBG then FlyBG:Destroy() FlyBG = nil end
    end
end

local function GetMoveDirection()
    local cam = Workspace.CurrentCamera
    if not cam then return Vector3.zero end

    local hum = GetHumanoid()
    local dir = Vector3.zero

    -- Mobile thumbstick + PC movement (works in most executors)
    if hum then
        local mv = hum:GetMoveVector()
        if mv.Magnitude > 0.1 then
            dir = (cam.CFrame.LookVector * mv.Z) + (cam.CFrame.RightVector * mv.X)
            return dir.Unit
        end
    end

    -- Keyboard fallback
    if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir += cam.CFrame.LookVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir -= cam.CFrame.LookVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir -= cam.CFrame.RightVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir += cam.CFrame.RightVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir += Vector3.yAxis end
    if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then dir -= Vector3.yAxis end

    if dir.Magnitude > 0 then
        return dir.Unit
    end
    return Vector3.zero
end

local function StartFly()
    StopFly()
    local hrp = GetHRP()
    local hum = GetHumanoid()
    if not hrp or not hum then
        Notify("Fly", "Character not loaded. Respawn and try again.", 5)
        return
    end

    States.Fly = true
    hum.PlatformStand = true

    FlyBV = Instance.new("BodyVelocity")
    FlyBV.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    FlyBV.Velocity = Vector3.zero
    FlyBV.Parent = hrp

    FlyBG = Instance.new("BodyGyro")
    FlyBG.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
    FlyBG.P = 10000
    FlyBG.Parent = hrp

    FlyConn = RunService.RenderStepped:Connect(function()
        if not States.Fly then return end
        local root = GetHRP()
        local humanoid = GetHumanoid()
        local camera = Workspace.CurrentCamera
        if not root or not humanoid or not camera then
            StopFly()
            return
        end

        humanoid.PlatformStand = true
        local move = GetMoveDirection()
        FlyBV.Velocity = move * FlySpeed
        FlyBG.CFrame = camera.CFrame
    end)

    Notify("Fly", "Enabled. Move with joystick/WASD. Space = up, Ctrl = down.", 6)
end

-- ===================== NOCLIP =====================
local function StopNoclip()
    States.Noclip = false
    if NoclipConn then
        NoclipConn:Disconnect()
        NoclipConn = nil
    end
end

local function StartNoclip()
    StopNoclip()
    States.Noclip = true
    NoclipConn = RunService.Stepped:Connect(function()
        if not States.Noclip then return end
        local char = GetCharacter()
        if not char then return end
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end)
end

-- ===================== GODMODE =====================
local function StopGodmode()
    States.Godmode = false
    if GodConn then
        GodConn:Disconnect()
        GodConn = nil
    end
end

local function StartGodmode()
    StopGodmode()
    States.Godmode = true
    GodConn = RunService.Heartbeat:Connect(function()
        if not States.Godmode then return end
        local hum = GetHumanoid()
        if hum and hum.Health < hum.MaxHealth then
            hum.Health = hum.MaxHealth
        end
    end)
    Notify("Godmode", "Enabled.", 3)
end

-- ===================== INVISIBLE =====================
local function SetInvisible(on)
    States.Invisible = on
    local char = GetCharacter()
    if not char then return end
    for _, v in ipairs(char:GetDescendants()) do
        if v:IsA("BasePart") and v.Name ~= "HumanoidRootPart" then
            v.Transparency = on and 1 or 0
        elseif v:IsA("Decal") or v:IsA("Texture") then
            v.Transparency = on and 1 or 0
        end
    end
    Notify("Invisible", on and "You are invisible." or "You are visible again.", 4)
end

-- ===================== ESP =====================
local function ClearESP()
    for _, obj in pairs(ESPObjects) do
        if obj and obj.Parent then
            obj:Destroy()
        end
    end
    ESPObjects = {}
end

local function CreateESPForPlayer(plr)
    if plr == LocalPlayer or not plr.Character then return end
    local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
    local hum = plr.Character:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end

    local bill = Instance.new("BillboardGui")
    bill.Name = "MooxtyESP"
    bill.Adornee = hrp
    bill.Size = UDim2.new(0, 120, 0, 40)
    bill.StudsOffset = Vector3.new(0, 3, 0)
    bill.AlwaysOnTop = true
    bill.Parent = hrp

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(0, 255, 127)
    label.TextStrokeTransparency = 0.5
    label.Font = Enum.Font.GothamBold
    label.TextSize = 14
    label.Text = plr.Name
    label.Parent = bill

    ESPObjects[plr] = bill
end

local function RefreshESP()
    ClearESP()
    if not States.ESP then return end
    for _, plr in ipairs(Players:GetPlayers()) do
        CreateESPForPlayer(plr)
    end
end

-- ===================== TROLL / BROOKHAVEN =====================
local function TeleportToPlayer(name)
    local target = GetPlayerByName(name)
    local myHRP = GetHRP()
    if not target or not target.Character or not myHRP then
        Notify("Teleport", "Invalid target.", 3)
        return
    end
    local tHRP = target.Character:FindFirstChild("HumanoidRootPart")
    if tHRP then
        myHRP.CFrame = tHRP.CFrame * CFrame.new(0, 0, 4)
        Notify("Teleport", "Teleported to " .. target.Name, 3)
    end
end

local function BringPlayer(name)
    local target = GetPlayerByName(name)
    local myHRP = GetHRP()
    if not target or not target.Character or not myHRP then
        Notify("Bring", "Invalid target.", 3)
        return
    end
    local tHRP = target.Character:FindFirstChild("HumanoidRootPart")
    if tHRP then
        tHRP.CFrame = myHRP.CFrame * CFrame.new(0, 0, -5)
        Notify("Bring", "Brought " .. target.Name, 3)
    end
end

local function SitOnPlayer(name)
    local target = GetPlayerByName(name)
    local myHRP = GetHRP()
    if not target or not target.Character or not myHRP then
        Notify("Sit", "Invalid target.", 3)
        return
    end
    local tHRP = target.Character:FindFirstChild("HumanoidRootPart")
    if tHRP then
        myHRP.CFrame = tHRP.CFrame * CFrame.new(0, 3, 0)
        Notify("Sit", "Sitting on " .. target.Name, 3)
    end
end

local function FlingPlayer(name)
    local target = GetPlayerByName(name)
    if not target or not target.Character then
        Notify("Fling", "Invalid target.", 3)
        return
    end
    local tHRP = target.Character:FindFirstChild("HumanoidRootPart")
    if tHRP then
        local bv = Instance.new("BodyVelocity")
        bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        bv.Velocity = Vector3.new(math.random(-200, 200), 500, math.random(-200, 200))
        bv.Parent = tHRP
        task.delay(0.4, function()
            if bv and bv.Parent then bv:Destroy() end
        end)
        Notify("Fling", "Flinged " .. target.Name, 3)
    end
end

local function SpectatePlayer(name)
    local target = GetPlayerByName(name)
    local hum = GetHumanoid()
    if not target or not target.Character or not hum then
        Notify("Spectate", "Invalid target.", 3)
        return
    end
    local tHum = target.Character:FindFirstChildOfClass("Humanoid")
    if tHum then
        Workspace.CurrentCamera.CameraSubject = tHum
        Notify("Spectate", "Spectating " .. target.Name .. " (reset camera by respawning)", 5)
    end
end

local function ResetCamera()
    local hum = GetHumanoid()
    if hum then
        Workspace.CurrentCamera.CameraSubject = hum
        Notify("Camera", "Camera reset to you.", 3)
    end
end

-- Respawn safety
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.5)
    if States.Fly then StartFly() end
    if States.Noclip then StartNoclip() end
    if States.Invisible then SetInvisible(true) end
    if States.ESP then RefreshESP() end
end)

Players.PlayerAdded:Connect(function(plr)
    plr.CharacterAdded:Connect(function()
        if States.ESP then
            task.wait(1)
            CreateESPForPlayer(plr)
        end
    end)
end)

Players.PlayerRemoving:Connect(function(plr)
    if ESPObjects[plr] then
        ESPObjects[plr]:Destroy()
        ESPObjects[plr] = nil
    end
end)

-- ===================== RAYFIELD UI =====================
local Window = Rayfield:CreateWindow({
    Name = "Mooxty Hub | Brookhaven RP",
    LoadingTitle = "Mooxty Hub",
    LoadingSubtitle = "English Edition",
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
        Title = "Mooxty Hub Key",
        Subtitle = "Copy Discord below — Key: Mooxty",
        Note = "Discord: discord.gg/9SfemsAnw | Key: Mooxty (case sensitive)",
        FileName = "MooxtyKey",
        SaveKey = true,
        GrabKeyFromSite = false,
        Key = { "Mooxty" }
    }
})

local MainTab = Window:CreateTab("Main", nil)
local PlayerTab = Window:CreateTab("Player", nil)
local VisualTab = Window:CreateTab("Visual", nil)
local TrollTab = Window:CreateTab("Troll", nil)
local BrookhavenTab = Window:CreateTab("Brookhaven", nil)
local MiscTab = Window:CreateTab("Misc", nil)

MainTab:CreateSection("Discord & Info")

MainTab:CreateButton({
    Name = "Copy Discord Link",
    Callback = function()
        if setclipboard then
            setclipboard("discord.gg/9SfemsAnw")
            Notify("Discord", "discord.gg/9SfemsAnw copied!", 4)
        else
            Notify("Discord", "discord.gg/9SfemsAnw (clipboard not supported)", 6)
        end
    end
})

MainTab:CreateLabel("Key: Mooxty | Join Discord for support.")

PlayerTab:CreateSection("Movement")

PlayerTab:CreateToggle({
    Name = "Fly (Mobile + PC)",
    CurrentValue = false,
    Callback = function(v)
        if v then StartFly() else StopFly() end
    end
})

PlayerTab:CreateSlider({
    Name = "Fly Speed",
    Range = { 20, 250 },
    Increment = 5,
    Suffix = "speed",
    CurrentValue = 80,
    Callback = function(v)
        FlySpeed = v
    end
})

PlayerTab:CreateToggle({
    Name = "Noclip",
    CurrentValue = false,
    Callback = function(v)
        if v then StartNoclip() else StopNoclip() end
    end
})

PlayerTab:CreateSlider({
    Name = "Walk Speed",
    Range = { 16, 400 },
    Increment = 1,
    CurrentValue = 16,
    Callback = function(v)
        local hum = GetHumanoid()
        if hum then hum.WalkSpeed = v end
    end
})

PlayerTab:CreateSlider({
    Name = "Jump Power",
    Range = { 50, 500 },
    Increment = 5,
    CurrentValue = 50,
    Callback = function(v)
        local hum = GetHumanoid()
        if hum then hum.JumpPower = v end
    end
})

PlayerTab:CreateToggle({
    Name = "Godmode",
    CurrentValue = false,
    Callback = function(v)
        if v then StartGodmode() else StopGodmode() end
    end
})

VisualTab:CreateSection("ESP")

VisualTab:CreateToggle({
    Name = "Player ESP (Names)",
    CurrentValue = false,
    Callback = function(v)
        States.ESP = v
        if v then RefreshESP() else ClearESP() end
    end
})

TrollTab:CreateSection("Target Player")

local PlayerDropdown = TrollTab:CreateDropdown({
    Name = "Select Player",
    Options = GetPlayerNames(),
    CurrentOption = GetPlayerNames()[1],
    Callback = function(opt)
        SelectedPlayer = opt
    end
})

TrollTab:CreateButton({
    Name = "Refresh Player List",
    Callback = function()
        local opts = GetPlayerNames()
        PlayerDropdown:Refresh(opts)
        SelectedPlayer = opts[1]
        Notify("Players", "List refreshed.", 2)
    end
})

TrollTab:CreateSection("Actions")

TrollTab:CreateToggle({
    Name = "Invisible",
    CurrentValue = false,
    Callback = function(v)
        SetInvisible(v)
    end
})

TrollTab:CreateButton({
    Name = "Teleport To Player",
    Callback = function()
        if SelectedPlayer then TeleportToPlayer(SelectedPlayer) end
    end
})

TrollTab:CreateButton({
    Name = "Bring Player",
    Callback = function()
        if SelectedPlayer then BringPlayer(SelectedPlayer) end
    end
})

TrollTab:CreateButton({
    Name = "Sit On Player",
    Callback = function()
        if SelectedPlayer then SitOnPlayer(SelectedPlayer) end
    end
})

TrollTab:CreateButton({
    Name = "Fling Player",
    Callback = function()
        if SelectedPlayer then FlingPlayer(SelectedPlayer) end
    end
})

TrollTab:CreateButton({
    Name = "Spectate Player",
    Callback = function()
        if SelectedPlayer then SpectatePlayer(SelectedPlayer) end
    end
})

TrollTab:CreateButton({
    Name = "Reset Camera",
    Callback = ResetCamera
})

BrookhavenTab:CreateSection("RP Tools")

BrookhavenTab:CreateButton({
    Name = "Teleport To Spawn",
    Callback = function()
        local hrp = GetHRP()
        if hrp then
            hrp.CFrame = CFrame.new(0, 5, 0)
            Notify("Brookhaven", "Teleported near spawn.", 3)
        end
    end
})

BrookhavenTab:CreateButton({
    Name = "Remove Seat (Unsit)",
    Callback = function()
        local hum = GetHumanoid()
        if hum then
            hum.Sit = false
            hum.Jump = true
            Notify("Brookhaven", "Unsit / jump forced.", 3)
        end
    end
})

BrookhavenTab:CreateButton({
    Name = "Anti-Sit (Toggle sit off)",
    Callback = function()
        local hum = GetHumanoid()
        if hum then
            hum:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
            Notify("Brookhaven", "Seated state disabled.", 4)
        end
    end
})

MiscTab:CreateSection("Utility")

MiscTab:CreateToggle({
    Name = "Anti-AFK",
    CurrentValue = false,
    Callback = function(v)
        States.AntiAFK = v
        if AFKConn then AFKConn:Disconnect() AFKConn = nil end
        if v then
            AFKConn = LocalPlayer.Idled:Connect(function()
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new())
            end)
            Notify("Anti-AFK", "Enabled.", 3)
        end
    end
})

MiscTab:CreateButton({
    Name = "Rejoin Server",
    Callback = function()
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
    end
})

MiscTab:CreateButton({
    Name = "Server Hop (New Server)",
    Callback = function()
        TeleportService:Teleport(game.PlaceId, LocalPlayer)
    end
})

Notify("Mooxty Hub", "Loaded! Key: Mooxty | Fly: use move stick or WASD.", 7)