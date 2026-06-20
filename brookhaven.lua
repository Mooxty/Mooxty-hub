local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "Mooxty Hub",
    LoadingTitle = "Mooxty Hub",
    LoadingSubtitle = "by efeyi_calcam",
    ConfigurationSaving = { Enabled = false },
    Discord = {
        Enabled = true,
        Invite = "9SfemsAnw",
        RememberJoins = true,
    },
    KeySystem = true,
    KeySettings = {
        Title = "Mooxty Hub",
        Subtitle = "by efeyi_calcam",
        Note = "Get your key from Discord.",
        FileName = "MooxtyHubKey",
        SaveKey = false,
        GrabKeyFromSite = false,
        Key = { "MooxtyOnTop" },
    },
})

local Universal = Window:CreateTab("Universal", 4483362458)
Universal:CreateSection("Movement")

local DISCORD = "discord.gg/9SfemsAnw"

--[[
    FLY KODUNU BURAYA YAZ (aşağıdaki CreateToggle içinde):
    - Value == true  → Fly AÇ
    - Value == false → Fly KAPAT
]]

Universal:CreateToggle({
    Name = "Fly",
    CurrentValue = false,
    Flag = "MooxtyFly",
    Callback = function(Value)
        if Value then
            -- ========== FLY ON — local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")

local flying = false
local speed = 50
local flyForce = Instance.new("BodyVelocity")
flyForce.Name = "FlyVelocity"
flyForce.MaxForce = Vector3.new(0, 0, 0)

-- Toggle Flying
local function toggleFly()
	flying = not flying
	if flying then
		flyForce.Parent = rootPart
		flyForce.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
		humanoid.PlatformStand = true
	else
		flyForce.Parent = nil
		flyForce.MaxForce = Vector3.new(0, 0, 0)
		humanoid.PlatformStand = false
	end
end

-- Input detection for Spacebar
UserInputService.InputBegan:Connect(function(input, isProcessed)
	if isProcessed then return end
	if input.KeyCode == Enum.KeyCode.Space then
		toggleFly()
	end
end)

-- Continuously update fly direction
game:GetService("RunService").RenderStepped:Connect(function()
	if flying then
		local camera = Workspace.CurrentCamera
		local moveDirection = Vector3.new()
		
		-- Check movement keys (WASD)
		if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDirection += camera.LookVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDirection -= camera.LookVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDirection -= camera.RightVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDirection += camera.RightVector end
		
		-- Normalize and apply speed
		if moveDirection.Magnitude > 0 then
			moveDirection = moveDirection.Unit * speed
		end
		flyForce.Velocity = moveDirection
	end
end)
 ==========
            
        else
            -- ========== FLY OFF — kodunu buraya yaz ==========
            
        end
    end,
})

Universal:CreateButton({
    Name = "Copy Discord",
    Callback = function()
        if setclipboard then
            setclipboard(DISCORD)
            Rayfield:Notify({ Title = "Discord", Content = "Copied!", Duration = 4 })
        else
            Rayfield:Notify({ Title = "Discord", Content = DISCORD, Duration = 6 })
        end
    end,
})

if setclipboard then
    setclipboard(DISCORD)
end

Rayfield:Notify({
    Title = "Mooxty Hub",
    Content = "by efeyi_calcam | Discord copied",
    Duration = 5,
})