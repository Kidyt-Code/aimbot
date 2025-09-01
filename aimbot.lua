--// SERVICES
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

--// SETTINGS
local RADIUS_PIXELS = 100
local FOV_COLOR = Color3.fromRGB(255, 0, 0)
local aimbotEnabled = false

--// GUI
local gui = Instance.new("ScreenGui", LocalPlayer:WaitForChild("PlayerGui"))
gui.Name = "AimbotGUI"
gui.ResetOnSpawn = false

-- Splash "Made by Vex" label
local splashLabel = Instance.new("TextLabel")
splashLabel.Size = UDim2.new(0, 400, 0, 100)
splashLabel.Position = UDim2.new(0.5, -200, 0.5, -50)
splashLabel.BackgroundTransparency = 1
splashLabel.Font = Enum.Font.GothamBlack
splashLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
splashLabel.TextScaled = true
splashLabel.Text = "Made by Vex"
splashLabel.TextStrokeTransparency = 0
splashLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
splashLabel.Parent = gui
splashLabel.TextTransparency = 1

-- Fade in the splash
TweenService:Create(splashLabel, TweenInfo.new(1.2), {TextTransparency = 0}):Play()

-- After fade-in, fade out and then create the main GUI
delay(2, function()
	TweenService:Create(splashLabel, TweenInfo.new(1.2), {TextTransparency = 1}):Play()
	wait(1.2)
	splashLabel:Destroy()

	--// MAIN GUI
	local mainFrame = Instance.new("Frame")
	mainFrame.Size = UDim2.new(0, 220, 0, 100)
	mainFrame.Position = UDim2.new(0.5, -110, 0.5, -50)
	mainFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
	mainFrame.BackgroundTransparency = 1
	mainFrame.BorderSizePixel = 0
	mainFrame.Parent = gui
	mainFrame.Active = true
	mainFrame.Draggable = true

	local uiCorner = Instance.new("UICorner", mainFrame)
	uiCorner.CornerRadius = UDim.new(0, 16)
	local uiStroke = Instance.new("UIStroke", mainFrame)
	uiStroke.Thickness = 2
	uiStroke.Color = Color3.fromRGB(200, 200, 200)
	uiStroke.Transparency = 1

	-- Fade in GUI
	TweenService:Create(mainFrame, TweenInfo.new(1), {BackgroundTransparency = 0.1}):Play()
	TweenService:Create(uiStroke, TweenInfo.new(1), {Transparency = 0.5}):Play()

	-- Toggle button
	local toggleBtn = Instance.new("TextButton")
	toggleBtn.Size = UDim2.new(0, 180, 0, 36)
	toggleBtn.Position = UDim2.new(0.5, -90, 0, 32)
	toggleBtn.Text = "Toggle (G)"
	toggleBtn.Font = Enum.Font.GothamBold
	toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	toggleBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 75)
	toggleBtn.BorderSizePixel = 0
	toggleBtn.Parent = mainFrame

	local toggleCorner = Instance.new("UICorner", toggleBtn)
	toggleCorner.CornerRadius = UDim.new(0, 12)

	-- Hover effect
	toggleBtn.MouseEnter:Connect(function()
		TweenService:Create(toggleBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(90, 90, 100)}):Play()
	end)
	toggleBtn.MouseLeave:Connect(function()
		TweenService:Create(toggleBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(70, 70, 75)}):Play()
	end)

	--// FOV CIRCLE
	local circle = Instance.new("Frame", gui)
	circle.Size = UDim2.fromOffset(RADIUS_PIXELS*2, RADIUS_PIXELS*2)
	circle.AnchorPoint = Vector2.new(0.5, 0.5)
	circle.BackgroundTransparency = 1
	circle.BorderSizePixel = 0
	circle.Visible = false -- hidden by default

	local circleCorner = Instance.new("UICorner", circle)
	circleCorner.CornerRadius = UDim.new(1, 0)

	local circleStroke = Instance.new("UIStroke", circle)
	circleStroke.Thickness = 2
	circleStroke.Color = FOV_COLOR

	--// FUNCTIONS
	local function isVisible(part)
		if not part then return false end
		local origin = Camera.CFrame.Position
		local direction = (part.Position - origin)
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Blacklist
		params.FilterDescendantsInstances = {LocalPlayer.Character}
		local result = workspace:Raycast(origin, direction, params)
		if result then
			return result.Instance:IsDescendantOf(part.Parent)
		end
		return true
	end

	local function getAllCharacters()
		local chars = {}
		for _, plr in ipairs(Players:GetPlayers()) do
			if plr.Character and plr ~= LocalPlayer then
				table.insert(chars, plr.Character)
			end
		end
		for _, obj in ipairs(workspace:GetChildren()) do
			if obj:IsA("Model") and obj:FindFirstChild("Humanoid") and obj:FindFirstChild("HumanoidRootPart") then
				if not Players:GetPlayerFromCharacter(obj) then
					table.insert(chars, obj)
				end
			end
		end
		return chars
	end

	local function getClosestTarget()
		local closest, closestDist = nil, math.huge
		for _, char in ipairs(getAllCharacters()) do
			local hrp = char:FindFirstChild("HumanoidRootPart")
			local humanoid = char:FindFirstChildOfClass("Humanoid")
			if hrp and humanoid and humanoid.Health > 0 then
				local screenPos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
				if onScreen then
					local dist = (Vector2.new(Mouse.X, Mouse.Y) - Vector2.new(screenPos.X, screenPos.Y)).Magnitude
					if dist < RADIUS_PIXELS and dist < closestDist and isVisible(hrp) then
						closest = hrp
						closestDist = dist
					end
				end
			end
		end
		return closest
	end

	--// TOGGLE
	local function updateToggle()
		aimbotEnabled = not aimbotEnabled
		circle.Visible = aimbotEnabled
		toggleBtn.Text = aimbotEnabled and "Enabled (G)" or "Toggle (G)"
	end

	toggleBtn.MouseButton1Click:Connect(updateToggle)

	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		if input.KeyCode == Enum.KeyCode.G then
			updateToggle()
		end
	end)

	--// MAIN LOOP
	RunService.RenderStepped:Connect(function()
		circle.Position = UDim2.fromOffset(Mouse.X, Mouse.Y)
		if aimbotEnabled then
			local target = getClosestTarget()
			if target then
				Camera.CFrame = CFrame.new(Camera.CFrame.Position, target.Position)
			end
		end
	end)
end)
