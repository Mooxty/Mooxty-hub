--[[ Mooxty Hub | Brookhaven RP | Custom GUI | English ]]

local DISCORD = "discord.gg/9SfemsAnw"
local KEY_URL = "https://raw.githubusercontent.com/Mooxty/Mooxty-hub/main/key.txt"

local Players = game:GetService("Players")
local LP = Players.LocalPlayer
local UIS = game:GetService("UserInputService")
local RS = game:GetService("RunService")
local WS = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local TPS = game:GetService("TeleportService")
local VU = game:GetService("VirtualUser")

local PG = LP:WaitForChild("PlayerGui")

-- Saved defaults (for OFF restore)
local DefaultWalk = 16
local DefaultJump = 50

local State = {
    Fly = false,
    Noclip = false,
    SpeedOn = false,
    JumpOn = false,
    God = false,
    Invis = false,
    ESP = false,
    AntiAFK = false,
    InfJump = false,
    Fullbright = false,
    ClickTP = false,
}
local SpeedValue = 100
local JumpValue = 120
local FlySpeed = 2.5
local FlyUp, FlyDown = false, false
local TargetName = nil
local Conns = {}
local ESPMap = {}
local ControlModule

pcall(function()
    local pm = LP:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule")
    ControlModule = require(pm):WaitForChild("ControlModule") and require(pm).ControlModule
    if not ControlModule then
        ControlModule = require(pm).ControlModule
    end
end)

local function GetGuiParent()
    if gethui then
        local g = Instance.new("ScreenGui")
        g.Name = "MooxtyHub"
        g.ResetOnSpawn = false
        g.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        g.Parent = gethui()
        return g
    end
    if syn and syn.protect_gui then
        local g = Instance.new("ScreenGui")
        g.Name = "MooxtyHub"
        g.ResetOnSpawn = false
        syn.protect_gui(g)
        g.Parent = game:GetService("CoreGui")
        return g
    end
    local g = Instance.new("ScreenGui")
    g.Name = "MooxtyHub"
    g.ResetOnSpawn = false
    g.Parent = PG
    return g
end

local Screen = GetGuiParent()
local UIScale = Instance.new("UIScale", Screen)
UIScale.Scale = UIS.TouchEnabled and 0.85 or 1

local function Notify(t, m, d)
    d = d or 4
    local f = Instance.new("Frame", Screen)
    f.Size = UDim2.new(0, 260, 0, 64)
    f.Position = UDim2.new(1, -270, 0, 10)
    f.BackgroundColor3 = Color3.fromRGB(22, 22, 32)
    Instance.new("UICorner", f).CornerRadius = UDim.new(0, 8)
    local a = Instance.new("TextLabel", f)
    a.Size = UDim2.new(1, -8, 0, 20)
    a.Position = UDim2.new(0, 4, 0, 4)
    a.BackgroundTransparency = 1
    a.Font = Enum.Font.GothamBold
    a.TextSize = 13
    a.TextColor3 = Color3.fromRGB(100, 180, 255)
    a.TextXAlignment = Enum.TextXAlignment.Left
    a.Text = t
    local b = Instance.new("TextLabel", f)
    b.Size = UDim2.new(1, -8, 0, 36)
    b.Position = UDim2.new(0, 4, 0, 24)
    b.BackgroundTransparency = 1
    b.Font = Enum.Font.Gotham
    b.TextSize = 11
    b.TextWrapped = true
    b.TextColor3 = Color3.new(1, 1, 1)
    b.TextXAlignment = Enum.TextXAlignment.Left
    b.Text = m
    task.delay(d, function() if f.Parent then f:Destroy() end end)
end

local function Char() return LP.Character end
local function Hum()
    local c = Char()
    return c and c:FindFirstChildOfClass("Humanoid")
end
local function HRP()
    local c = Char()
    return c and c:FindFirstChild("HumanoidRootPart")
end

local function Clip(s)
    if setclipboard then setclipboard(s) Notify("Copied", s, 3)
    else Notify("Discord", s, 5) end
end

local function FetchValidKey()
    local ok, res = pcall(function()
        return game:HttpGet(KEY_URL)
    end)
    if ok and res then
        return res:gsub("%s+", "")
    end
    return nil
end

local function SaveSession()
    if writefile and makefolder then
        pcall(makefolder, "MooxtyHub")
        writefile("MooxtyHub/session", "1")
    end
end

local function HasSession()
    return isfile and isfile("MooxtyHub/session")
end

-- Capture defaults when character loads
local function CacheDefaults()
    local h = Hum()
    if h then
        DefaultWalk = h.WalkSpeed
        DefaultJump = h.JumpPower > 0 and h.JumpPower or h.JumpHeight or 50
    end
end

LP.CharacterAdded:Connect(function()
    task.wait(0.5)
    CacheDefaults()
    if State.SpeedOn then local h = Hum() if h then h.WalkSpeed = SpeedValue end end
    if State.JumpOn then local h = Hum() if h then h.JumpPower = JumpValue end end
    if State.Fly then StartFly() end
    if State.Noclip then StartNoclip() end
    if State.Invis then SetInvisible(true) end
    if State.ESP then RefreshESP() end
    if State.God then StartGod() end
end)

if LP.Character then CacheDefaults() end

-- ========= MOVEMENT =========
local function GetMoveVector2D()
    if ControlModule and ControlModule.GetMoveVector then
        local v = ControlModule:GetMoveVector()
        return Vector3.new(v.X, 0, v.Z)
    end
    local h = Hum()
    if h and h.MoveDirection.Magnitude > 0.01 then
        return h.MoveDirection
    end
    local cam = WS.CurrentCamera
    if not cam then return Vector3.zero end
    local d = Vector3.zero
    if UIS:IsKeyDown(Enum.KeyCode.W) then d += cam.CFrame.LookVector end
    if UIS:IsKeyDown(Enum.KeyCode.S) then d -= cam.CFrame.LookVector end
    if UIS:IsKeyDown(Enum.KeyCode.A) then d -= cam.CFrame.RightVector end
    if UIS:IsKeyDown(Enum.KeyCode.D) then d += cam.CFrame.RightVector end
    if d.Magnitude > 0 then return d.Unit end
    return Vector3.zero
end

function StopFly()
    State.Fly = false
    if Conns.Fly then Conns.Fly:Disconnect() Conns.Fly = nil end
    local h = Hum()
    if h then h.PlatformStand = false end
end

function StartFly()
    StopFly()
    if not HRP() then Notify("Fly", "Character not ready.", 4) return end
    State.Fly = true
    local h = Hum()
    if h then h.PlatformStand = true end
    Conns.Fly = RS.RenderStepped:Connect(function(dt)
        if not State.Fly then return end
        local hrp = HRP()
        local hum = Hum()
        local cam = WS.CurrentCamera
        if not hrp or not hum or not cam then return end
        hum.PlatformStand = true
        local move = GetMoveVector2D()
        local spd = FlySpeed * 60 * dt
        if move.Magnitude > 0 then
            hrp.CFrame = hrp.CFrame + (move * spd)
        end
        if FlyUp or UIS:IsKeyDown(Enum.KeyCode.Space) then
            hrp.CFrame = hrp.CFrame + Vector3.new(0, spd, 0)
        end
        if FlyDown or UIS:IsKeyDown(Enum.KeyCode.LeftControl) then
            hrp.CFrame = hrp.CFrame - Vector3.new(0, spd, 0)
        end
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero
    end)
    Notify("Fly", "ON — use move stick / WASD. UP/DOWN buttons on mobile.", 5)
end

function StopNoclip()
    State.Noclip = false
    if Conns.Noclip then Conns.Noclip:Disconnect() Conns.Noclip = nil end
end

function StartNoclip()
    StopNoclip()
    State.Noclip = true
    Conns.Noclip = RS.Stepped:Connect(function()
        if not State.Noclip then return end
        local c = Char()
        if not c then return end
        for _, p in ipairs(c:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide = false end
        end
    end)
end

function ApplySpeed(on)
    State.SpeedOn = on
    local h = Hum()
    if not h then return end
    if on then h.WalkSpeed = SpeedValue
    else h.WalkSpeed = DefaultWalk end
end

function ApplyJump(on)
    State.JumpOn = on
    local h = Hum()
    if not h then return end
    if on then h.JumpPower = JumpValue
    else h.JumpPower = DefaultJump end
end

function StopGod()
    State.God = false
    if Conns.God then Conns.God:Disconnect() Conns.God = nil end
end

function StartGod()
    StopGod()
    State.God = true
    Conns.God = RS.Heartbeat:Connect(function()
        if not State.God then return end
        local h = Hum()
        if h and h.Health < h.MaxHealth then h.Health = h.MaxHealth end
    end)
end

function SetInvisible(on)
    State.Invis = on
    local c = Char()
    if not c then return end
    for _, d in ipairs(c:GetDescendants()) do
        if d:IsA("BasePart") and d.Name ~= "HumanoidRootPart" then
            d.Transparency = on and 1 or 0
            d.LocalTransparencyModifier = on and 1 or 0
        elseif d:IsA("Decal") then
            d.Transparency = on and 1 or 0
        end
    end
end

function ClearESP()
    for _, g in pairs(ESPMap) do if g and g.Parent then g:Destroy() end end
    ESPMap = {}
end

function AddESP(plr)
    if plr == LP or not plr.Character then return end
    local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local bill = Instance.new("BillboardGui")
    bill.Size = UDim2.new(0, 90, 0, 28)
    bill.Adornee = hrp
    bill.StudsOffset = Vector3.new(0, 2.5, 0)
    bill.AlwaysOnTop = true
    bill.Parent = hrp
    local tl = Instance.new("TextLabel", bill)
    tl.Size = UDim2.new(1, 0, 1, 0)
    tl.BackgroundTransparency = 1
    tl.Text = plr.Name
    tl.Font = Enum.Font.GothamBold
    tl.TextSize = 12
    tl.TextColor3 = Color3.fromRGB(80, 255, 160)
    tl.TextStrokeTransparency = 0.4
    ESPMap[plr] = bill
end

function RefreshESP()
    ClearESP()
    if not State.ESP then return end
    for _, p in ipairs(Players:GetPlayers()) do AddESP(p) end
end

local function PlayerNames()
    local t = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP then table.insert(t, p.Name) end
    end
    if #t == 0 then table.insert(t, "Nobody") end
    return t
end

-- ========= GUI HELPERS =========
local function Corner(p, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 6)
    c.Parent = p
end

local Toggles = {}

local function MakeScroll(parent)
    local sc = Instance.new("ScrollingFrame", parent)
    sc.Size = UDim2.new(1, -8, 1, -8)
    sc.Position = UDim2.new(0, 4, 0, 4)
    sc.BackgroundTransparency = 1
    sc.ScrollBarThickness = 3
    sc.CanvasSize = UDim2.new(0, 0, 0, 0)
    sc.AutomaticCanvasSize = Enum.AutomaticSize.Y
    local lay = Instance.new("UIListLayout", sc)
    lay.Padding = UDim.new(0, 6)
    lay.SortOrder = Enum.SortOrder.LayoutOrder
    Instance.new("UIPadding", sc).PaddingTop = UDim.new(0, 4)
    return sc
end

local function Btn(parent, text, h, cb)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, -12, 0, h or 34)
    b.BackgroundColor3 = Color3.fromRGB(48, 48, 62)
    b.Text = text
    b.Font = Enum.Font.GothamSemibold
    b.TextSize = 13
    b.TextColor3 = Color3.new(1, 1, 1)
    b.Parent = parent
    Corner(b)
    b.MouseButton1Click:Connect(cb)
    return b
end

local function Toggle(parent, id, text, onCb)
    local on = false
    local b = Btn(parent, text .. " [OFF]", 36, function()
        on = not on
        b.Text = text .. (on and " [ON]" or " [OFF]")
        b.BackgroundColor3 = on and Color3.fromRGB(45, 110, 70) or Color3.fromRGB(48, 48, 62)
        onCb(on)
    end)
    Toggles[id] = function(v)
        on = v
        b.Text = text .. (on and " [ON]" or " [OFF]")
        b.BackgroundColor3 = on and Color3.fromRGB(45, 110, 70) or Color3.fromRGB(48, 48, 62)
        onCb(on)
    end
    return b
end

local function Slider(parent, label, min, max, start, step, cb)
    local val = start
    local fr = Instance.new("Frame", parent)
    fr.Size = UDim2.new(1, -12, 0, 44)
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
    minus.Size = UDim2.new(0, 36, 0, 24)
    minus.Position = UDim2.new(0, 0, 0, 20)
    minus.Text = "-"
    minus.Font = Enum.Font.GothamBold
    minus.TextSize = 16
    minus.BackgroundColor3 = Color3.fromRGB(55, 55, 70)
    Corner(minus)
    local plus = Instance.new("TextButton", fr)
    plus.Size = UDim2.new(0, 36, 0, 24)
    plus.Position = UDim2.new(0, 42, 0, 20)
    plus.Text = "+"
    plus.Font = Enum.Font.GothamBold
    plus.TextSize = 16
    plus.BackgroundColor3 = Color3.fromRGB(55, 55, 70)
    Corner(plus)
    minus.MouseButton1Click:Connect(function()
        val = math.clamp(val - step, min, max)
        lbl.Text = label .. ": " .. val
        cb(val)
    end)
    plus.MouseButton1Click:Connect(function()
        val = math.clamp(val + step, min, max)
        lbl.Text = label .. ": " .. val
        cb(val)
    end)
end

-- ========= LOGIN (no key shown) =========
local Login = Instance.new("Frame", Screen)
Login.Size = UDim2.new(0, 300, 0, 200)
Login.Position = UDim2.new(0.5, -150, 0.5, -100)
Login.BackgroundColor3 = Color3.fromRGB(18, 18, 28)
Corner(Login, 10)

local LTitle = Instance.new("TextLabel", Login)
LTitle.Size = UDim2.new(1, 0, 0, 36)
LTitle.BackgroundTransparency = 1
LTitle.Text = "Mooxty Hub"
LTitle.Font = Enum.Font.GothamBold
LTitle.TextSize = 20
LTitle.TextColor3 = Color3.fromRGB(120, 190, 255)

local LInfo = Instance.new("TextLabel", Login)
LInfo.Size = UDim2.new(1, -20, 0, 50)
LInfo.Position = UDim2.new(0, 10, 0, 38)
LInfo.BackgroundTransparency = 1
LInfo.Text = "Get your access key from our Discord server."
LInfo.Font = Enum.Font.Gotham
LInfo.TextSize = 12
LInfo.TextWrapped = true
LInfo.TextColor3 = Color3.fromRGB(210, 210, 210)

Btn(Login, "Copy Discord Invite", 36, function() Clip(DISCORD) end).Position = UDim2.new(0, 10, 0, 92)
Login:FindFirstChildWhichIsA("TextButton", true) -- fix position
local copyBtn = Login:GetChildren()
for _, ch in ipairs(Login:GetChildren()) do
    if ch:IsA("TextButton") and ch.Text:find("Discord") then
        ch.Position = UDim2.new(0, 10, 0, 92)
        ch.Size = UDim2.new(1, -20, 0, 36)
    end
end

local KeyBox = Instance.new("TextBox", Login)
KeyBox.Size = UDim2.new(1, -20, 0, 32)
KeyBox.Position = UDim2.new(0, 10, 0, 134)
KeyBox.BackgroundColor3 = Color3.fromRGB(32, 32, 45)
KeyBox.PlaceholderText = "Access key from Discord..."
KeyBox.Text = ""
KeyBox.Font = Enum.Font.Gotham
KeyBox.TextSize = 13
KeyBox.TextColor3 = Color3.new(1, 1, 1)
Corner(KeyBox)

local Submit = Instance.new("TextButton", Login)
Submit.Size = UDim2.new(1, -20, 0, 32)
Submit.Position = UDim2.new(0, 10, 0, 168)
Submit.BackgroundColor3 = Color3.fromRGB(50, 130, 75)
Submit.Text = "Continue"
Submit.Font = Enum.Font.GothamBold
Submit.TextSize = 14
Submit.TextColor3 = Color3.new(1, 1, 1)
Corner(Submit)

-- ========= MAIN HUB =========
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
TopFill.Size = UDim2.new(1, 0, 0, 14)
TopFill.Position = UDim2.new(0, 0, 1, -14)
TopFill.BackgroundColor3 = Top.BackgroundColor3
TopFill.BorderSizePixel = 0

local Title = Instance.new("TextLabel", Top)
Title.Size = UDim2.new(1, -50, 1, 0)
Title.Position = UDim2.new(0, 10, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "Mooxty Hub | Brookhaven"
Title.Font = Enum.Font.GothamBold
Title.TextSize = 14
Title.TextColor3 = Color3.new(1, 1, 1)
Title.TextXAlignment = Enum.TextXAlignment.Left

local Close = Instance.new("TextButton", Top)
Close.Size = UDim2.new(0, 32, 0, 26)
Close.Position = UDim2.new(1, -38, 0, 7)
Close.Text = "X"
Close.Font = Enum.Font.GothamBold
Close.BackgroundColor3 = Color3.fromRGB(170, 55, 55)
Close.TextColor3 = Color3.new(1, 1, 1)
Corner(Close)
Close.MouseButton1Click:Connect(function() Hub.Visible = false end)

-- Drag
local drag, start, orig
Top.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
        drag = true
        start = i.Position
        orig = Hub.Position
    end
end)
Top.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then drag = false end
end)
UIS.InputChanged:Connect(function(i)
    if drag and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
        local d = i.Position - start
        Hub.Position = UDim2.new(orig.X.Scale, orig.X.Offset + d.X, orig.Y.Scale, orig.Y.Offset + d.Y)
    end
end)

local TabRow = Instance.new("Frame", Hub)
TabRow.Size = UDim2.new(1, -10, 0, 30)
TabRow.Position = UDim2.new(0, 5, 0, 44)
TabRow.BackgroundTransparency = 1
local TabLay = Instance.new("UIListLayout", TabRow)
TabLay.FillDirection = Enum.FillDirection.Horizontal
TabLay.Padding = UDim.new(0, 4)

local Body = Instance.new("Frame", Hub)
Body.Size = UDim2.new(1, -10, 1, -82)
Body.Position = UDim2.new(0, 5, 0, 78)
Body.BackgroundColor3 = Color3.fromRGB(24, 24, 36)
Corner(Body)

local Pages = {}
local function NewPage(name)
    local p = Instance.new("Frame", Body)
    p.Name = name
    p.Size = UDim2.new(1, 0, 1, 0)
    p.BackgroundTransparency = 1
    p.Visible = false
    local sc = MakeScroll(p)
    Pages[name] = sc
    local tab = Instance.new("TextButton", TabRow)
    tab.Size = UDim2.new(0, 54, 1, 0)
    tab.Text = name
    tab.Font = Enum.Font.GothamSemibold
    tab.TextSize = 11
    tab.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
    tab.TextColor3 = Color3.new(1, 1, 1)
    Corner(tab, 4)
    tab.MouseButton1Click:Connect(function()
        for n, pg in pairs(Pages) do
            pg.Parent.Visible = (n == name)
        end
    end)
    return sc
end

local PMain = NewPage("Main")
local PPlayer = NewPage("Player")
local PVisual = NewPage("Visual")
local PTroll = NewPage("Troll")
local PBH = NewPage("BH")
local PMisc = NewPage("Misc")
Pages["Main"].Parent.Visible = true

-- Mobile fly pad
local FlyPad = Instance.new("Frame", Screen)
FlyPad.Size = UDim2.new(0, 110, 0, 90)
FlyPad.Position = UDim2.new(0, 8, 1, -98)
FlyPad.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
FlyPad.BackgroundTransparency = 0.4
FlyPad.Visible = UIS.TouchEnabled
Corner(FlyPad)
local function HoldBtn(btn, up)
    btn.MouseButton1Down:Connect(function() if up then FlyUp = true else FlyDown = true end end)
    btn.MouseButton1Up:Connect(function() if up then FlyUp = false else FlyDown = false end end)
    btn.MouseLeave:Connect(function() if up then FlyUp = false else FlyDown = false end end)
end
local upB = Instance.new("TextButton", FlyPad)
upB.Size = UDim2.new(0.9, 0, 0.42, 0)
upB.Position = UDim2.new(0.05, 0, 0.05, 0)
upB.Text = "UP"
upB.Font = Enum.Font.GothamBold
upB.BackgroundColor3 = Color3.fromRGB(50, 90, 140)
HoldBtn(upB, true)
local dnB = Instance.new("TextButton", FlyPad)
dnB.Size = UDim2.new(0.9, 0, 0.42, 0)
dnB.Position = UDim2.new(0.05, 0, 0.52, 0)
dnB.Text = "DOWN"
dnB.Font = Enum.Font.GothamBold
dnB.BackgroundColor3 = Color3.fromRGB(50, 90, 140)
HoldBtn(dnB, false)

-- MAIN
Btn(PMain, "Copy Discord", 34, function() Clip(DISCORD) end)
Btn(PMain, "Toggle Menu (RightShift)", 34, function() Hub.Visible = not Hub.Visible end)

-- PLAYER
Toggle(PPlayer, "fly", "Fly", function(v) if v then StartFly() else StopFly() end end)
Slider(PPlayer, "Fly Speed", 1, 8, 3, 0.5, function(v) FlySpeed = v end)
Toggle(PPlayer, "noclip", "Noclip", function(v) if v then StartNoclip() else StopNoclip() end end)
Toggle(PPlayer, "speed", "Speed Hack", function(v) ApplySpeed(v) end)
Slider(PPlayer, "Speed", 20, 500, SpeedValue, 10, function(v)
    SpeedValue = v
    if State.SpeedOn then local h = Hum() if h then h.WalkSpeed = v end end
end)
Toggle(PPlayer, "jump", "Jump Hack", function(v) ApplyJump(v) end)
Slider(PPlayer, "Jump", 30, 600, JumpValue, 10, function(v)
    JumpValue = v
    if State.JumpOn then local h = Hum() if h then h.JumpPower = v end end
end)
Toggle(PPlayer, "god", "Godmode", function(v) if v then StartGod() else StopGod() end end)
Toggle(PPlayer, "infjump", "Infinite Jump", function(v)
    State.InfJump = v
    if Conns.InfJump then Conns.InfJump:Disconnect() end
    if v then
        Conns.InfJump = UIS.JumpRequest:Connect(function()
            local h = Hum()
            if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
        end)
    end
end)

-- VISUAL
Toggle(PVisual, "esp", "Player ESP", function(v)
    State.ESP = v
    if v then RefreshESP() else ClearESP() end
end)
Toggle(PVisual, "invis", "Invisible", function(v) SetInvisible(v) end)
Toggle(PVisual, "bright", "Fullbright", function(v)
    State.Fullbright = v
    if v then
        Lighting.Brightness = 2
        Lighting.FogEnd = 1e5
        Lighting.GlobalShadows = false
    else
        Lighting.Brightness = 1
        Lighting.FogEnd = 10000
        Lighting.GlobalShadows = true
    end
end)

-- TROLL (no bring / fling)
TargetName = PlayerNames()[1]
local Tlbl = Instance.new("TextLabel", PTroll)
Tlbl.Size = UDim2.new(1, -12, 0, 20)
Tlbl.BackgroundTransparency = 1
Tlbl.Font = Enum.Font.Gotham
Tlbl.TextSize = 12
Tlbl.TextColor3 = Color3.new(1, 1, 1)
Tlbl.TextXAlignment = Enum.TextXAlignment.Left
Tlbl.Text = "Target: " .. TargetName

Btn(PTroll, "Next Target", 32, function()
    local list = PlayerNames()
    local i = table.find(list, TargetName) or 1
    i = i % #list + 1
    TargetName = list[i]
    Tlbl.Text = "Target: " .. TargetName
end)

Btn(PTroll, "Teleport To Target", 34, function()
    local p = Players:FindFirstChild(TargetName)
    local me = HRP()
    if p and p.Character and me then
        local t = p.Character:FindFirstChild("HumanoidRootPart")
        if t then me.CFrame = t.CFrame * CFrame.new(0, 0, 4) end
    end
end)

Btn(PTroll, "Sit On Target", 34, function()
    local p = Players:FindFirstChild(TargetName)
    local me = HRP()
    if p and p.Character and me then
        local t = p.Character:FindFirstChild("Head") or p.Character:FindFirstChild("HumanoidRootPart")
        if t then me.CFrame = t.CFrame * CFrame.new(0, 2.2, 0) end
    end
end)

Btn(PTroll, "Spectate Target", 34, function()
    local p = Players:FindFirstChild(TargetName)
    if p and p.Character then
        local th = p.Character:FindFirstChildOfClass("Humanoid")
        if th then WS.CurrentCamera.CameraSubject = th end
    end
end)

Btn(PTroll, "Reset Camera", 32, function()
    local h = Hum()
    if h then WS.CurrentCamera.CameraSubject = h end
end)

-- BROOKHAVEN
Btn(PBH, "TP Spawn", 32, function()
    local r = HRP()
    if r then r.CFrame = CFrame.new(0, 5, 0) end
end)
Btn(PBH, "Force Unsit", 32, function()
    local h = Hum()
    if h then h.Sit = false h.Jump = true end
end)
Btn(PBH, "Disable Sit State", 32, function()
    local h = Hum()
    if h then h:SetStateEnabled(Enum.HumanoidStateType.Seated, false) end
end)
Btn(PBH, "Reset Character", 32, function()
    local h = Hum()
    if h then h.Health = 0 end
end)

-- MISC
Toggle(PMisc, "afk", "Anti-AFK", function(v)
    State.AntiAFK = v
    if Conns.AFK then Conns.AFK:Disconnect() end
    if v then
        Conns.AFK = LP.Idled:Connect(function()
            VU:CaptureController()
            VU:ClickButton2(Vector2.new())
        end)
    end
end)
Btn(PMisc, "Rejoin", 32, function()
    TPS:TeleportToPlaceInstance(game.PlaceId, game.JobId, LP)
end)
Btn(PMisc, "Server Hop", 32, function()
    TPS:Teleport(game.PlaceId, LP)
end)

local function OpenHub()
    Login.Visible = false
    Hub.Visible = true
    Notify("Mooxty Hub", "Loaded successfully.", 5)
end

Submit.MouseButton1Click:Connect(function()
    local valid = FetchValidKey()
    local entered = KeyBox.Text:gsub("%s+", "")
    if valid and entered == valid then
        SaveSession()
        OpenHub()
    else
        Notify("Access", "Invalid key. Join Discord and copy the key from there.", 5)
    end
end)

if HasSession() then
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