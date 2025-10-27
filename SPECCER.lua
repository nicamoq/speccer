-- LocalScript (StarterPlayer -> StarterPlayerScripts)
-- Compact square spectate UI with default camera, pastel health ring, white text, remembers last spectated player, title tooltip, animated health, clipboard flash
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local localPlayer = Players.LocalPlayer
local camera = workspace.CurrentCamera
local UIS = UserInputService

-- Config
local TOGGLE_KEY = Enum.KeyCode.V
local PREV_KEY = Enum.KeyCode.Left
local NEXT_KEY = Enum.KeyCode.Right
local TELEPORT_KEY = Enum.KeyCode.B
local TELEPORT_MOD = Enum.KeyCode.LeftControl
local SHOW_UI_BUTTONS = true
local TITLE_TOOLTIP = "V - Start Speccing | B - Copy @username | Ctrl + B - TP to player | Made by Sro"

-- Tween config
local CAMERA_TWEEN_TIME = 0.4

-- State
local targets, idx, lastTarget, spectating, closed = {}, 0, nil, false, false

-- UI
task.wait(1)
local playerGui = localPlayer:WaitForChild("PlayerGui",10)
if playerGui:FindFirstChild("SpectateUI") then playerGui.SpectateUI:Destroy() end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SpectateUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local window = Instance.new("Frame")
window.Size = UDim2.new(0,150,0,180)
window.Position = UDim2.new(0.4,0,0.05,0)
window.BackgroundColor3 = Color3.fromRGB(25,25,25)
window.BackgroundTransparency = 0.1
window.BorderSizePixel = 0
window.Active = true
window.Draggable = true
window.Visible = true
window.Parent = screenGui

-- Title
local titleBar = Instance.new("Frame",window)
titleBar.Size = UDim2.new(1,0,0,25)
titleBar.BackgroundColor3 = Color3.fromRGB(35,35,35)
titleBar.BorderSizePixel = 0

local titleText = Instance.new("TextLabel",titleBar)
titleText.Size = UDim2.new(1,-80,1,0)
titleText.Position = UDim2.new(0,5,0,0)
titleText.BackgroundTransparency = 1
titleText.TextColor3 = Color3.new(1,1,1)
titleText.Font = Enum.Font.BuilderSansMedium
titleText.TextXAlignment = Enum.TextXAlignment.Left
titleText.Text = "SPECCER"

-- Tooltip
local tooltip = Instance.new("TextLabel",titleBar)
tooltip.Size = UDim2.new(0,200,0,50)
tooltip.Position = UDim2.new(0,0,0,-50)
tooltip.BackgroundColor3 = Color3.fromRGB(50,50,50)
tooltip.BackgroundTransparency = 0.2
tooltip.TextColor3 = Color3.new(1,1,1)
tooltip.Font = Enum.Font.SourceSans
tooltip.TextSize = 14
tooltip.TextWrapped = true
tooltip.Text = TITLE_TOOLTIP
tooltip.Visible = false
tooltip.ZIndex = 5

titleText.MouseEnter:Connect(function() tooltip.Visible = true end)
titleText.MouseLeave:Connect(function() tooltip.Visible = false end)

local closeBtn = Instance.new("TextButton",titleBar)
closeBtn.Size = UDim2.new(0,22,1,0)
closeBtn.Position = UDim2.new(1,-25,0,0)
closeBtn.BackgroundTransparency = 1
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.fromRGB(255,100,100)
closeBtn.Font = Enum.Font.BuilderSansMedium
closeBtn.TextScaled = true

local teleportBtn = Instance.new("TextButton",titleBar)
teleportBtn.Size = UDim2.new(0,22,1,0)
teleportBtn.Position = UDim2.new(1,-50,0,0)
teleportBtn.BackgroundTransparency = 1
teleportBtn.Text = "TP"
teleportBtn.TextColor3 = Color3.fromRGB(100,255,100)
teleportBtn.Font = Enum.Font.BuilderSansMedium
teleportBtn.TextScaled = true

-- Content
local content = Instance.new("Frame",window)
content.Size = UDim2.new(1,-10,1,-30)
content.Position = UDim2.new(0,5,0,25)
content.BackgroundTransparency = 1

local headshot = Instance.new("ImageLabel",content)
headshot.Size = UDim2.new(0,50,0,50)
headshot.Position = UDim2.new(0.5,0,0.3,0)
headshot.AnchorPoint = Vector2.new(0.5,0.5)
headshot.BackgroundTransparency = 1

local nickname = Instance.new("TextLabel",content)
nickname.Size = UDim2.new(0.9,0,0,20)
nickname.Position = UDim2.new(0.5,0,0.55,0)
nickname.AnchorPoint = Vector2.new(0.5,0.5)
nickname.BackgroundTransparency = 1
nickname.TextColor3 = Color3.new(1,1,1)
nickname.Font = Enum.Font.BuilderSansMedium
nickname.TextScaled = true
nickname.Text = ""

local username = Instance.new("TextLabel",content)
username.Size = UDim2.new(0.9,0,0,15)
username.Position = UDim2.new(0.5,0,0.7,0)
username.AnchorPoint = Vector2.new(0.5,0.5)
username.BackgroundTransparency = 1
username.TextColor3 = Color3.fromRGB(200,200,200)
username.Font = Enum.Font.SourceSans
username.TextScaled = true
username.Text = ""

-- Health border
local stroke = Instance.new("UIStroke", headshot)
stroke.Color = Color3.fromRGB(152,251,152)
stroke.Thickness = 2
stroke.Transparency = 0

-- Arrows
local prevBtn, nextBtn
if SHOW_UI_BUTTONS then
	prevBtn = Instance.new("TextButton",content)
	prevBtn.Size = UDim2.new(0.5,-5,0,25)
	prevBtn.Position = UDim2.new(0,0,0.85,0)
	prevBtn.Text = "<"
	prevBtn.TextColor3 = Color3.new(1,1,1)
	prevBtn.BackgroundTransparency = 0.2
	prevBtn.TextScaled = true

	nextBtn = Instance.new("TextButton",content)
	nextBtn.Size = UDim2.new(0.5,-5,0,25)
	nextBtn.Position = UDim2.new(0.5,5,0.85,0)
	nextBtn.Text = ">"
	nextBtn.TextColor3 = Color3.new(1,1,1)
	nextBtn.BackgroundTransparency = 0.2
	nextBtn.TextScaled = true
end

-- ===== FUNCTIONS =====
local function rebuildTargets()
	local prevName = lastTarget and lastTarget.Name or nil
	targets = {}
	for _,p in ipairs(Players:GetPlayers()) do
		if p~=localPlayer and p.Character and p.Character:FindFirstChildWhichIsA("Humanoid") then
			table.insert(targets,p)
		end
	end
	idx = 0
	if prevName then
		for i,p in ipairs(targets) do
			if p.Name==prevName then idx=i break end
		end
	end
	if #targets==0 then idx=0 elseif idx<1 or idx>#targets then idx=1 end
end

local function updateUI()
	if not spectating or idx==0 or #targets==0 then
		local thumb = Players:GetUserThumbnailAsync(localPlayer.UserId,Enum.ThumbnailType.HeadShot,Enum.ThumbnailSize.Size48x48)
		headshot.Image = thumb
		nickname.Text = "It's still you"
		username.Text = "@"..localPlayer.Name
		stroke.Color = Color3.fromRGB(152,251,152)
		stroke.Transparency = 0
	else
		local t = targets[idx]
		nickname.Text = t.DisplayName
		username.Text = "@"..t.Name
		local thumb = Players:GetUserThumbnailAsync(t.UserId,Enum.ThumbnailType.HeadShot,Enum.ThumbnailSize.Size48x48)
		headshot.Image = thumb
		local hum = t.Character and t.Character:FindFirstChildWhichIsA("Humanoid")
		if hum then
			stroke.Transparency = 1 - (hum.Health/hum.MaxHealth)
		end
	end
end

-- Smooth transition using TweenService
local function transitionCameraToPlayer(p)
	if not p or not p.Character then return end
	local hrp = p.Character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	local startCFrame = camera.CFrame
	local targetCFrame = CFrame.new(hrp.Position + Vector3.new(0,5,10), hrp.Position)
	local tween = TweenService:Create(camera,TweenInfo.new(CAMERA_TWEEN_TIME,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{CFrame = targetCFrame})
	tween:Play()
	tween.Completed:Wait()
	camera.CameraSubject = p.Character:FindFirstChildWhichIsA("Humanoid")
end

local function setCameraToTarget(p)
	if not p then return end
	lastTarget = p
	transitionCameraToPlayer(p)
end

local function enterSpectate()
	rebuildTargets()
	if #targets==0 then spectating=true updateUI() return end
	spectating=true
	if lastTarget then
		for i,p in ipairs(targets) do
			if p==lastTarget then idx=i break end
		end
	end
	if idx<1 or idx>#targets then idx=1 end
	setCameraToTarget(targets[idx])
	updateUI()
end

local function clearSpectate()
	spectating=false
	idx=0
	if localPlayer.Character and localPlayer.Character:FindFirstChildWhichIsA("Humanoid") then
		camera.CameraSubject = localPlayer.Character:FindFirstChildWhichIsA("Humanoid")
	end
	updateUI()
end

local function cycle(step)
	if #targets==0 then clearSpectate() return end
	idx+=step
	if idx<1 then idx=#targets end
	if idx>#targets then idx=1 end
	setCameraToTarget(targets[idx])
	updateUI()
end

-- Animate health border
task.spawn(function()
	while task.wait(0.03) do
		if spectating and idx>0 and #targets>0 then
			local t = targets[idx]
			if t and t.Character then
				local hum = t.Character:FindFirstChildWhichIsA("Humanoid")
				if hum then
					local healthPerc = hum.Health/hum.MaxHealth
					stroke.Transparency = stroke.Transparency + (1 - healthPerc - stroke.Transparency) * 0.2
				end
			end
		end
	end
end)

-- ===== INPUT =====
UIS.InputBegan:Connect(function(input,processed)
	if processed or closed then return end
	if input.UserInputType==Enum.UserInputType.Keyboard then
		if input.KeyCode==TOGGLE_KEY then
			if spectating then clearSpectate() else enterSpectate() end
		elseif input.KeyCode==PREV_KEY and spectating then cycle(-1)
		elseif input.KeyCode==NEXT_KEY and spectating then cycle(1)
		elseif input.KeyCode==TELEPORT_KEY and UIS:IsKeyDown(TELEPORT_MOD) and spectating then
			local t = targets[idx]
			if t and t.Character and t.Character:FindFirstChild("HumanoidRootPart") then
				local hrp = t.Character.HumanoidRootPart
				if localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart") then
					localPlayer.Character.HumanoidRootPart.CFrame = hrp.CFrame + Vector3.new(2,0,2)
				end
			end
		elseif input.KeyCode==TELEPORT_KEY and spectating then
			local t = targets[idx]
			if t then
				setclipboard("@"..t.Name)
				username.TextTransparency = 0
				task.spawn(function()
					for i=1,10 do
						username.TextTransparency = i*0.1
						task.wait(0.03)
					end
					username.TextTransparency = 0
				end)
			end
		end
	end
end)

-- ===== BUTTONS =====
closeBtn.MouseButton1Click:Connect(function()
	closed=true
	clearSpectate()
	window.Visible=false
end)

teleportBtn.MouseButton1Click:Connect(function()
	local t = targets[idx]
	if t and t.Character and t.Character:FindFirstChild("HumanoidRootPart") then
		local hrp = t.Character.HumanoidRootPart
		if localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart") then
			localPlayer.Character.HumanoidRootPart.CFrame = hrp.CFrame + Vector3.new(2,0,2)
		end
	end
end)

if SHOW_UI_BUTTONS then
	prevBtn.MouseButton1Click:Connect(function() if spectating then cycle(-1) end end)
	nextBtn.MouseButton1Click:Connect(function() if spectating then cycle(1) end end)
end

-- ===== PLAYER JOIN/LEAVE =====
Players.PlayerAdded:Connect(function(p)
	p.CharacterAdded:Connect(function()
		rebuildTargets()
		updateUI()
	end)
	rebuildTargets()
	updateUI()
end)

Players.PlayerRemoving:Connect(function(p)
	rebuildTargets()
	if idx~=0 and targets[idx]==p then
		if #targets>0 then idx=math.clamp(idx,1,#targets) setCameraToTarget(targets[idx]) end
	end
	updateUI()
end)

-- ===== AUTO-CAMERA ON RESPAWN =====
local function monitorCurrentTarget(target)
	if not target then return end
	target.CharacterAdded:Connect(function(char)
		if spectating and targets[idx] == target then
			task.wait(0.05)
			local hum = char:FindFirstChildWhichIsA("Humanoid")
			if hum then
				camera.CameraSubject = hum
				updateUI()
			end
		end
	end)
end

for _,p in ipairs(Players:GetPlayers()) do
	monitorCurrentTarget(p)
end
Players.PlayerAdded:Connect(function(p)
	monitorCurrentTarget(p)
end)

-- ===== INITIAL =====
rebuildTargets()
updateUI()
