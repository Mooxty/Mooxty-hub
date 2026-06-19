--[[ Mooxty Hub | Brookhaven | Custom GUI | IY Fly | Key: Discord only ]]

local VALID_KEY = "Mooxty"
local DISCORD = "discord.gg/9SfemsAnw"

local Players = game:GetService("Players")
local LP = Players.LocalPlayer
local UIS = game:GetService("UserInputService")
local RS = game:GetService("RunService")
local WS = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local TPS = game:GetService("TeleportService")
local VU = game:GetService("VirtualUser")

local PG = LP:WaitForChild("PlayerGui")

local DefaultWalk, DefaultJump = 16, 50
local SpeedVal, JumpVal, IYFlySpeed = 100, 120, 50
local TargetName = "Nobody"

local State = {
    Fly = false, Noclip = false, Speed = false, Jump = false,
    God = false, Invis = false, ESP = false, AntiAFK = false, InfJump = false, Fullbright = false,
}
local Conns, ESPMap = {}, {}
local IYFlying, IYControl = false, {F=0,B=0,L=0,R=0,Q=0,E=0}
local IYBV, IYBG, IYInputB, IYInputE, IYThread

local function ParentGui()
    if gethui then
        local g = Instance.new("ScreenGui")
        g.Name, g.ResetOnSpawn, g.ZIndexBehavior = "MooxtyHub", false, Enum.ZIndexBehavior.Sibling
        g.Parent = gethui()
        return g
    end
    if syn and syn.protect_gui then
        local g = Instance.new("ScreenGui")
        g.Name, g.ResetOnSpawn = "MooxtyHub", false
        syn.protect_gui(g)
        g.Parent = game:GetService("CoreGui")
        return g
    end
    local g = Instance.new("ScreenGui")
    g.Name, g.ResetOnSpawn = "MooxtyHub", false
    g.Parent = PG
    return g
end

local Screen = ParentGui()
Instance.new("UIScale", Screen).Scale = UIS.TouchEnabled and 0.88 or 1

local function Notify(t, m, d)
    local f = Instance.new("Frame", Screen)
    f.Size = UDim2.new(0, 260, 0, 60)
    f.Position = UDim2.new(1, -270, 0, 8)
    f.BackgroundColor3 = Color3.fromRGB(22, 22, 32)
    Instance.new("UICorner", f).CornerRadius = UDim.new(0, 8)
    local l1 = Instance.new("TextLabel", f)
    l1.Size = UDim2.new(1, -8, 0, 18)
    l1.Position = UDim2.new(0, 4, 0, 4)
    l1.BackgroundTransparency = 1
    l1.Font = Enum.Font.GothamBold
    l1.TextSize = 13
    l1.TextColor3 = Color3.fromRGB(110, 180, 255)
    l1.TextXAlignment = Enum.TextXAlignment.Left
    l1.Text = t
    local l2 = Instance.new("TextLabel", f)
    l2.Size = UDim2.new(1, -8, 0, 34)
    l2.Position = UDim2.new(0, 4, 0, 22)
    l2.BackgroundTransparency = 1
    l2.Font = Enum.Font.Gotham
    l2.TextSize = 11
    l2.TextWrapped = true
    l2.TextColor3 = Color3.new(1, 1, 1)
    l2.TextXAlignment = Enum.TextXAlignment.Left
    l2.Text = m
    task.delay(d or 4, function() if f.Parent then f:Destroy() end end)
end

local function Hum() local c = LP.Character return c and c:FindFirstChildOfClass("Humanoid") end
local function HRP() local c = LP.Character return c and c:FindFirstChild("HumanoidRootPart") end
local function Root(c) c = c or LP.Character return c and (c:FindFirstChild("HumanoidRootPart") or c:FindFirstChildWhichIsA("BasePart")) end

local function Clip(s)
    if setclipboard then setclipboard(s) Notify("Copied", s, 3) else Notify("Discord", s, 5) end
end

local function CacheDefaults()
    local h = Hum()
    if h then
        DefaultWalk = h.WalkSpeed
        DefaultJump = (h.JumpPower and h.JumpPower > 0) and h.JumpPower or 50
    end
end

local function GetControls()
    local ok, ctrl = pcall(function()
        return require(LP.PlayerScripts:WaitForChild("PlayerModule")):GetControls()
    end)
    return ok and ctrl or nil
end

-- ========= Infinite Yield style FLY (EdgeIY pattern) =========
local function IYStopFly()
    IYFlying = false
    if IYInputB then IYInputB:Disconnect() IYInputB = nil end
    if IYInputE then IYInputE:Disconnect() IYInputE = nil end
    local r = Root()
    if r then
        for _, ch in ipairs(r:GetChildren()) do
            if ch.Name == "MooxtyIYFlyBV" or ch.Name == "MooxtyIYFlyBG" then ch:Destroy() end
        end
    end
    local h = Hum()
    if h then h.PlatformStand = false end
    IYControl = {F=0,B=0,L=0,R=0,Q=0,E=0}
end

local function IYStartFly()
    IYStopFly()
    local T = Root()
    local hum = Hum()
    if not T or not hum then
        Notify("Fly", "Wait for character to load.", 4)
        return false
    end

    IYFlying = true
    State.Fly = true

    IYBG = Instance.new("BodyGyro")
    IYBG.Name = "MooxtyIYFlyBG"
    IYBG.P = 9e4
    IYBG.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
    IYBG.CFrame = T.CFrame
    IYBG.Parent = T

    IYBV = Instance.new("BodyVelocity")
    IYBV.Name = "MooxtyIYFlyBV"
    IYBV.Velocity = Vector3.zero
    IYBV.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    IYBV.Parent = T

    local Controls = GetControls()

    IYInputB = UIS.InputBegan:Connect(function(input, processed)
        if processed then return end
        local k = input.KeyCode
        if k == Enum.KeyCode.W then IYControl.F = 1
        elseif k == Enum.KeyCode.S then IYControl.B = 1
        elseif k == Enum.KeyCode.A then IYControl.L = 1
        elseif k == Enum.KeyCode.D then IYControl.R = 1
        elseif k == Enum.KeyCode.Q or k == Enum.KeyCode.Space then IYControl.Q = 1
        elseif k == Enum.KeyCode.E or k == Enum.KeyCode.LeftControl then IYControl.E = 1
        end
    end)

    IYInputE = UIS.InputEnded:Connect(function(input)
        local k = input.KeyCode
        if k == Enum.KeyCode.W then IYControl.F = 0
        elseif k == Enum.KeyCode.S then IYControl.B = 0
        elseif k == Enum.KeyCode.A then IYControl.L = 0
        elseif k == Enum.KeyCode.D then IYControl.R = 0
        elseif k == Enum.KeyCode.Q or k == Enum.KeyCode.Space then IYControl.Q = 0
        elseif k == Enum.KeyCode.E or k == Enum.KeyCode.LeftControl then IYControl.E = 0
        end
    end)

    task.spawn(function()
        while IYFlying and T.Parent do
            hum = Hum()
            if not hum then break end
            hum.PlatformStand = true
            local cam = WS.CurrentCamera
            if not cam then task.wait() continue end

            -- Mobile: IY uses move vector
            if Controls and Controls.GetMoveVector then
                local mv = Controls:GetMoveVector()
                if mv.Magnitude > 0.05 then
                    IYControl.F = math.clamp(-mv.Z, 0, 1)
                    IYControl.B = math.clamp(mv.Z, 0, 1)
                    IYControl.L = math.clamp(-mv.X, 0, 1)
                    IYControl.R = math.clamp(mv.X, 0, 1)
                elseif not UIS.KeyboardEnabled then
                    IYControl.F, IYControl.B, IYControl.L, IYControl.R = 0, 0, 0, 0
                end
            end

            local C = IYControl
            if C.L + C.R ~= 0 or C.F + C.B ~= 0 or C.Q + C.E ~= 0 then
                IYBV.Velocity = (
                    (cam.CFrame.LookVector * (C.F - C.B)) +
                    (cam.CFrame.RightVector * (C.R - C.L)) +
                    Vector3.new(0, (C.Q - C.E) * 0.5, 0)
                ) * IYFlySpeed
                IYBG.CFrame = cam.CFrame
            else
                IYBV.Velocity = Vector3.zero
                IYBG.CFrame = cam.CFrame
            end
            task.wait()
        end
        IYStopFly()
        State.Fly = false
    end)

    Notify("Fly", "ON (IY) — Stick/WASD. Space up, E down (PC).", 5)
    return true
end

-- ========= Other features =========
local function SetSpeed(on)
    State.Speed = on
    local h = Hum()
    if not h then return end
    h.WalkSpeed = on and SpeedVal or DefaultWalk
end

local function SetJump(on)
    State.Jump = on
    local h = Hum()
    if not h then return end
    h.JumpPower = on and JumpVal or DefaultJump
end

local function StopNoclip()
    State.Noclip = false
    if Conns.Noclip then Conns.Noclip:Disconnect() Conns.Noclip = nil end
end

local function StartNoclip()
    StopNoclip()
    State.Noclip = true
    Conns.Noclip = RS.Stepped:Connect(function()
        if not State.Noclip then return end
        local c = LP.Character
        if not c then return end
        for _, p in ipairs(c:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide = false end
        end
    end)
end

local function StopGod()
    State.God = false
    if Conns.God then Conns.God:Disconnect() Conns.God = nil end
end

local function StartGod()
    StopGod()
    State.God = true
    Conns.God = RS.Heartbeat:Connect(function()
        if not State.God then return end
        local h = Hum()
        if h and h.Health < h.MaxHealth then h.Health = h.MaxHealth end
    end)
end

local function SetInvis(on)
    State.Invis = on
    local c = LP.Character
    if not c then return end
    for _, d in ipairs(c:GetDescendants()) do
        if d:IsA("BasePart") and d.Name ~= "HumanoidRootPart" then
            d.Transparency = on and 1 or 0
        elseif d:IsA("Decal") then d.Transparency = on and 1 or 0 end
    end
end

local function ClearESP()
    for _, g in pairs(ESPMap) do if g and g.Parent then g:Destroy() end end
    ESPMap = {}
end

local function AddESP(plr)
    if plr == LP or not plr.Character then return end
    local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local b = Instance.new("BillboardGui", hrp)
    b.Size = UDim2.new(0, 90, 0, 26)
    b.Adornee = hrp
    b.StudsOffset = Vector3.new(0, 2.5, 0)
    b.AlwaysOnTop = true
    local t = Instance.new("TextLabel", b)
    t.Size = UDim2.new(1, 0, 1, 0)
    t.BackgroundTransparency = 1
    t.Text = plr.Name
    t.Font = Enum.Font.GothamBold
    t.TextSize = 12
    t.TextColor3 = Color3.fromRGB(80, 255, 160)
    t.TextStrokeTransparency = 0.4
    ESPMap[plr] = b
end

local function RefreshESP()
    ClearESP()
    if not State.ESP then return end
    for _, p in ipairs(Players:GetPlayers()) do AddESP(p) end
end

local function PlayerList()
    local t = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP then table.insert(t, p.Name) end
    end
    if #t == 0 then table.insert(t, "Nobody") end
    return t
end

LP.CharacterAdded:Connect(function()
    task.wait(0.6)
    CacheDefaults()
    if State.Speed then SetSpeed(true) end
    if State.Jump then SetJump(true) end
    if State.Fly then IYStartFly() end
    if State.Noclip then StartNoclip() end
    if State.God then StartGod() end
    if State.Invis then SetInvis(true) end
    if State.ESP then RefreshESP() end
end)
if LP.Character then CacheDefaults() end

-- ========= GUI =========
local function Corner(p, r)
    Instance.new("UICorner", p).CornerRadius = UDim.new(0, r or 6)
end

local function Scroll(parent)
    local s = Instance.new("ScrollingFrame", parent)
    s.Size = UDim2.new(1, -8, 1, -8)
    s.Position = UDim2.new(0, 4, 0, 4)
    s.BackgroundTransparency = 1
    s.ScrollBarThickness = 3
    s.AutomaticCanvasSize = Enum.AutomaticSize.Y
    s.CanvasSize = UDim2.new()
    Instance.new("UIListLayout", s).Padding = UDim.new(0, 6)
    return s
end

local function Btn(parent, text, cb)
    local b = Instance.new("TextButton", parent)
    b.Size = UDim2.new(1, -12, 0, 34)
    b.BackgroundColor3 = Color3.fromRGB(48, 48, 62)
    b.Font = Enum.Font.GothamSemibold
    b.TextSize = 13
    b.TextColor3 = Color3.new(1, 1, 1)
    b.Text = text
    Corner(b)
    b.MouseButton1Click:Connect(cb)
    return b
end

local function Toggle(parent, label, getSt, setSt, onFn, offFn)
    local b = Btn(parent, label .. " [OFF]", function()
        local on = not getSt()
        setSt(on)
        b.Text = label .. (on and " [ON]" or " [OFF]")
        b.BackgroundColor3 = on and Color3.fromRGB(45, 110, 70) or Color3.fromRGB(48, 48, 62)
        if on then onFn() else offFn() end
    end)
    return b
end

local function Slider(parent, label, min, max, start, step, onChange)
    local val = start
    local fr = Instance.new("Frame", parent)
    fr.Size = UDim2.new(1, -12, 0, 42)
    fr.BackgroundTransparency = 1
    local lbl = Instance.new("TextLabel", fr)
    lbl.Size = UDim2.new(1, 0, 0, 18)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 12
    lbl.TextColor3 = Color3.new(1, 1, 1)
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Text = label .. ": " .. val
    local minus = Instance.new("TextButton", fr)
    minus.Size = UDim2.new(0, 34, 0, 22)
    minus.Position = UDim2.new(0, 0, 0, 20)
    minus.Text = "-"
    minus.Font = Enum.Font.GothamBold
    minus.BackgroundColor3 = Color3.fromRGB(55, 55, 70)
    Corner(minus)
    local plus = Instance.new("TextButton", fr)
    plus.Size = UDim2.new(0, 34, 0, 22)
    plus.Position = UDim2.new(0, 40, 0, 20)
    plus.Text = "+"
    plus.Font = Enum.Font.GothamBold
    plus.BackgroundColor3 = Color3.fromRGB(55, 55, 70)
    Corner(plus)
    local function upd()
        lbl.Text = label .. ": " .. val
        onChange(val)
    end
    minus.MouseButton1Click:Connect(function() val = math.clamp(val - step, min, max) upd() end)
    plus.MouseButton1Click:Connect(function() val = math.clamp(val + step, min, max) upd() end)
end

-- Login (NO key text on screen)
local Login = Instance.new("Frame", Screen)
Login.Size = UDim2.new(0, 300, 0, 190)
Login.Position = UDim2.new(0.5, -150, 0.5, -95)
Login.BackgroundColor3 = Color3.fromRGB(18, 18, 28)
Corner(Login, 10)

local LT = Instance.new("TextLabel", Login)
LT.Size = UDim2.new(1, 0, 0, 34)
LT.BackgroundTransparency = 1
LT.Text = "Mooxty Hub"
LT.Font = Enum.Font.GothamBold
LT.TextSize = 20
LT.TextColor3 = Color3.fromRGB(120, 190, 255)

local LI = Instance.new("TextLabel", Login)
LI.Size = UDim2.new(1, -20, 0, 44)
LI.Position = UDim2.new(0, 10, 0, 36)
LI.BackgroundTransparency = 1
LI.Text = "Join our Discord and get the access key there."
LI.Font = Enum.Font.Gotham
LI.TextSize = 12
LI.TextWrapped = true
LI.TextColor3 = Color3.fromRGB(210, 210, 210)

local CopyD = Instance.new("TextButton", Login)
CopyD.Size = UDim2.new(1, -20, 0, 34)
CopyD.Position = UDim2.new(0, 10, 0, 84)
CopyD.BackgroundColor3 = Color3.fromRGB(65, 85, 200)
CopyD.Text = "Copy Discord Invite"
CopyD.Font = Enum.Font.GothamSemibold
CopyD.TextSize = 13
CopyD.TextColor3 = Color3.new(1, 1, 1)
Corner(CopyD)
CopyD.MouseButton1Click:Connect(function() Clip(DISCORD) end)

local KeyBox = Instance.new("TextBox", Login)
KeyBox.Size = UDim2.new(1, -20, 0, 32)
KeyBox.Position = UDim2.new(0, 10, 0, 124)
KeyBox.BackgroundColor3 = Color3.fromRGB(32, 32, 45)
KeyBox.PlaceholderText = "Paste key from Discord..."
KeyBox.Text = ""
KeyBox.Font = Enum.Font.Gotham
KeyBox.TextSize = 13
KeyBox.TextColor3 = Color3.new(1, 1, 1)
Corner(KeyBox)

local Go = Instance.new("TextButton", Login)
Go.Size = UDim2.new(1, -20, 0, 32)
Go.Position = UDim2.new(0, 10, 0, 158)
Go.BackgroundColor3 = Color3.fromRGB(50, 130, 75)
Go.Text = "Continue"
Go.Font = Enum.Font.GothamBold
Go.TextSize = 14
Go.TextColor3 = Color3.new(1, 1, 1)
Corner(Go)

-- Hub
local Hub = Instance.new("Frame", Screen)
Hub.Size = UDim2.new(0, 360, 0, 400)
Hub.Position = UDim2.new(0.5, -180, 0.5, -200)
Hub.BackgroundColor3 = Color3.fromRGB(16, 16, 26)
Hub.Visible = false
Corner(Hub, 10)

local Top = Instance.new("Frame", Hub)
Top.Size = UDim2.new(1, 0, 0, 40)
Top.BackgroundColor3 = Color3.fromRGB(28, 28, 42)
Corner(Top, 10)
local TopFill = Instance.new("Frame", Top)
TopFill.Size = UDim2.new(1, 0, 0, 12)
TopFill.Position = UDim2.new(0, 0, 1, -12)
TopFill.BackgroundColor3 = Top.BackgroundColor3
TopFill.BorderSizePixel = 0

local Title = Instance.new("TextLabel", Top)
Title.Size = UDim2.new(1, -44, 1, 0)
Title.Position = UDim2.new(0, 10, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "Mooxty Hub | Brookhaven"
Title.Font = Enum.Font.GothamBold
Title.TextSize = 14
Title.TextColor3 = Color3.new(1, 1, 1)
Title.TextXAlignment = Enum.TextXAlignment.Left

local X = Instance.new("TextButton", Top)
X.Size = UDim2.new(0, 32, 0, 26)
X.Position = UDim2.new(1, -38, 0, 7)
X.Text = "X"
X.Font = Enum.Font.GothamBold
X.BackgroundColor3 = Color3.fromRGB(170, 55, 55)
X.TextColor3 = Color3.new(1, 1, 1)
Corner(X)
X.MouseButton1Click:Connect(function() Hub.Visible = false end)

local drag, st, op
Top.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
        drag, st, op = true, i.Position, Hub.Position
    end
end)
Top.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then drag = false end
end)
UIS.InputChanged:Connect(function(i)
    if drag and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
        local d = i.Position - st
        Hub.Position = UDim2.new(op.X.Scale, op.X.Offset + d.X, op.Y.Scale, op.Y.Offset + d.Y)
    end
end)

local TabBar = Instance.new("Frame", Hub)
TabBar.Size = UDim2.new(1, -10, 0, 28)
TabBar.Position = UDim2.new(0, 5, 0, 44)
TabBar.BackgroundTransparency = 1
Instance.new("UIListLayout", TabBar).FillDirection = Enum.FillDirection.Horizontal

local Body = Instance.new("Frame", Hub)
Body.Size = UDim2.new(1, -10, 1, -80)
Body.Position = UDim2.new(0, 5, 0, 76)
Body.BackgroundColor3 = Color3.fromRGB(24, 24, 36)
Corner(Body)

local Pages = {}
local function Tab(name)
    local page = Instance.new("Frame", Body)
    page.Size = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.Visible = false
    local sc = Scroll(page)
    Pages[name] = page
    local tbtn = Instance.new("TextButton", TabBar)
    tbtn.Size = UDim2.new(0, 52, 1, 0)
    tbtn.Text = name
    tbtn.Font = Enum.Font.GothamSemibold
    tbtn.TextSize = 11
    tbtn.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
    tbtn.TextColor3 = Color3.new(1, 1, 1)
    Corner(tbtn, 4)
    tbtn.MouseButton1Click:Connect(function()
        for n, p in pairs(Pages) do p.Visible = (n == name) end
    end)
    return sc
end

local P1, P2, P3, P4, P5, P6 = Tab("Main"), Tab("Player"), Tab("Visual"), Tab("Troll"), Tab("BH"), Tab("Misc")
Pages["Main"].Visible = true

Btn(P1, "Copy Discord", function() Clip(DISCORD) end)
Btn(P1, "Toggle Menu (RightShift)", function() Hub.Visible = not Hub.Visible end)

Toggle(P2, "Fly (Infinite Yield)", function() return State.Fly end, function(v) State.Fly = v end,
    function() IYStartFly() end,
    function() IYStopFly() State.Fly = false end)

Slider(P2, "Fly Speed", 20, 200, IYFlySpeed, 5, function(v)
    IYFlySpeed = v
end)

Toggle(P2, "Noclip", function() return State.Noclip end, function(v) State.Noclip = v end, StartNoclip, StopNoclip)

Toggle(P2, "Speed Hack", function() return State.Speed end, function(v) State.Speed = v end,
    function() SetSpeed(true) end, function() SetSpeed(false) end)

Slider(P2, "Speed Value", 20, 500, SpeedVal, 10, function(v)
    SpeedVal = v
    if State.Speed then SetSpeed(true) end
end)

Toggle(P2, "Jump Hack", function() return State.Jump end, function(v) State.Jump = v end,
    function() SetJump(true) end, function() SetJump(false) end)

Slider(P2, "Jump Value", 30, 600, JumpVal, 10, function(v)
    JumpVal = v
    if State.Jump then SetJump(true) end
end)

Toggle(P2, "Godmode", function() return State.God end, function(v) State.God = v end, StartGod, StopGod)

Toggle(P2, "Infinite Jump", function() return State.InfJump end, function(v) State.InfJump = v end,
    function()
        if Conns.InfJump then Conns.InfJump:Disconnect() end
        Conns.InfJump = UIS.JumpRequest:Connect(function()
            local h = Hum()
            if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
        end)
    end,
    function()
        if Conns.InfJump then Conns.InfJump:Disconnect() Conns.InfJump = nil end
    end)

Toggle(P3, "Player ESP", function() return State.ESP end, function(v) State.ESP = v end,
    function() RefreshESP() end, function() ClearESP() end)

Toggle(P3, "Invisible", function() return State.Invis end, function(v) State.Invis = v end,
    function() SetInvis(true) end, function() SetInvis(false) end)

Toggle(P3, "Fullbright", function() return State.Fullbright end, function(v) State.Fullbright = v end,
    function()
        Lighting.Brightness = 2
        Lighting.FogEnd = 1e5
        Lighting.GlobalShadows = false
    end,
    function()
        Lighting.Brightness = 1
        Lighting.FogEnd = 10000
        Lighting.GlobalShadows = true
    end)

TargetName = PlayerList()[1]
local Tlbl = Instance.new("TextLabel", P4)
Tlbl.Size = UDim2.new(1, -12, 0, 18)
Tlbl.BackgroundTransparency = 1
Tlbl.Font = Enum.Font.Gotham
Tlbl.TextSize = 12
Tlbl.TextColor3 = Color3.new(1, 1, 1)
Tlbl.TextXAlignment = Enum.TextXAlignment.Left
Tlbl.Text = "Target: " .. TargetName

Btn(P4, "Next Target", function()
    local l = PlayerList()
    local i = table.find(l, TargetName) or 1
    TargetName = l[i % #l + 1]
    Tlbl.Text = "Target: " .. TargetName
end)

Btn(P4, "Teleport To Target", function()
    local p = Players:FindFirstChild(TargetName)
    local me = HRP()
    if p and p.Character and me then
        local t = p.Character:FindFirstChild("HumanoidRootPart")
        if t then me.CFrame = t.CFrame * CFrame.new(0, 0, 4) end
    end
end)

Btn(P4, "Sit On Target", function()
    local p = Players:FindFirstChild(TargetName)
    local me = HRP()
    if p and p.Character and me then
        local t = p.Character:FindFirstChild("Head") or p.Character:FindFirstChild("HumanoidRootPart")
        if t then me.CFrame = t.CFrame * CFrame.new(0, 2.2, 0) end
    end
end)

Btn(P4, "Spectate Target", function()
    local p = Players:FindFirstChild(TargetName)
    if p and p.Character then
        local th = p.Character:FindFirstChildOfClass("Humanoid")
        if th then WS.CurrentCamera.CameraSubject = th end
    end
end)

Btn(P4, "Reset Camera", function()
    local h = Hum()
    if h then WS.CurrentCamera.CameraSubject = h end
end)

Btn(P5, "TP Spawn", function()
    local r = HRP()
    if r then r.CFrame = CFrame.new(0, 5, 0) end
end)
Btn(P5, "Force Unsit", function()
    local h = Hum()
    if h then h.Sit = false h.Jump = true end
end)
Btn(P5, "Disable Sit", function()
    local h = Hum()
    if h then h:SetStateEnabled(Enum.HumanoidStateType.Seated, false) end
end)
Btn(P5, "Reset Character", function()
    local h = Hum()
    if h then h.Health = 0 end
end)

Toggle(P6, "Anti-AFK", function() return State.AntiAFK end, function(v) State.AntiAFK = v end,
    function()
        if Conns.AFK then Conns.AFK:Disconnect() end
        Conns.AFK = LP.Idled:Connect(function()
            VU:CaptureController()
            VU:ClickButton2(Vector2.new())
        end)
    end,
    function()
        if Conns.AFK then Conns.AFK:Disconnect() Conns.AFK = nil end
    end)

Btn(P6, "Rejoin", function() TPS:TeleportToPlaceInstance(game.PlaceId, game.JobId, LP) end)
Btn(P6, "Server Hop", function() TPS:Teleport(game.PlaceId, LP) end)

local function OpenHub()
    Login.Visible = false
    Hub.Visible = true
    Notify("Mooxty Hub", "Welcome!", 4)
end

local function SaveKey()
    if writefile and makefolder then
        pcall(makefolder, "MooxtyHub")
        writefile("MooxtyHub/ok", "1")
    end
end

local function HasKey()
    return isfile and isfile("MooxtyHub/ok")
end

Go.MouseButton1Click:Connect(function()
    local entered = KeyBox.Text:gsub("%s+", "")
    if entered == VALID_KEY then
        SaveKey()
        OpenHub()
    else
        Notify("Access Denied", "Wrong key. Copy Discord and get the key there.", 5)
    end
end)

if HasKey() then
    Login.Visible = false
    OpenHub()
else
    Login.Visible = true
end

UIS.InputBegan:Connect(function(i, gp)
    if gp then return end
    if i.KeyCode == Enum.KeyCode.RightShift and not Login.Visible then
        Hub.Visible = not Hub.Visible
    end
end)

Players.PlayerAdded:Connect(function(plr)
    plr.CharacterAdded:Connect(function()
        task.wait(1)
        if State.ESP then AddESP(plr) end
    end)
end)
Players.PlayerRemoving:Connect(function(plr)
    if ESPMap[plr] then ESPMap[plr]:Destroy() ESPMap[plr] = nil end
end)