--// SERVICES
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

--// SETTINGS
local RADIUS_PIXELS = 150 -- FOV circle
local FOV_COLOR = Color3.fromRGB(255, 0, 0)
local aimbotEnabled = false
local PREDICTION_TIME = 1 -- default 1 second

--// GUI
local gui = Instance.new("ScreenGui", LocalPlayer:WaitForChild("PlayerGui"))
gui.Name = "AimbotGUI"
gui.ResetOnSpawn = false

-- FUNCTION to create 3D text
local function Create3DText(text, parent, position, size, mainColor, depthColor, depthOffset)
    depthOffset = depthOffset or 4
    local labels = {}
    for i = 1, depthOffset do
        local depthLabel = Instance.new("TextLabel")
        depthLabel.Size = size
        depthLabel.Position = position + UDim2.new(0, i, 0, i)
        depthLabel.BackgroundTransparency = 1
        depthLabel.Font = Enum.Font.GothamBlack
        depthLabel.Text = text
        depthLabel.TextColor3 = depthColor
        depthLabel.TextScaled = true
        depthLabel.TextStrokeTransparency = 0
        depthLabel.Parent = parent
        depthLabel.TextTransparency = 1
        table.insert(labels, depthLabel)
    end
    local mainLabel = Instance.new("TextLabel")
    mainLabel.Size = size
    mainLabel.Position = position
    mainLabel.BackgroundTransparency = 1
    mainLabel.Font = Enum.Font.GothamBlack
    mainLabel.Text = text
    mainLabel.TextColor3 = mainColor
    mainLabel.TextScaled = true
    mainLabel.TextStrokeTransparency = 0
    mainLabel.Parent = parent
    mainLabel.TextTransparency = 1
    table.insert(labels, mainLabel)

    for _, lbl in pairs(labels) do
        TweenService:Create(lbl, TweenInfo.new(1.5), {TextTransparency = 0}):Play()
    end
end

-- Splash
Create3DText(
    "Made by Vex",
    gui,
    UDim2.new(0.5, -200, 0.5, -50),
    UDim2.new(0, 400, 0, 100),
    Color3.fromRGB(255, 255, 255),
    Color3.fromRGB(0, 0, 0),
    4
)

delay(3, function()
    for _, obj in ipairs(gui:GetChildren()) do
        if obj:IsA("TextLabel") then
            TweenService:Create(obj, TweenInfo.new(1.2), {TextTransparency = 1}):Play()
        end
    end

    wait(1.2)

    -- MAIN GUI
    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 240, 0, 140)
    mainFrame.Position = UDim2.new(0.5, -120, 0.5, -70)
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

    TweenService:Create(mainFrame, TweenInfo.new(1), {BackgroundTransparency = 0.1}):Play()
    TweenService:Create(uiStroke, TweenInfo.new(1), {Transparency = 0.5}):Play()

    -- Toggle button
    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Size = UDim2.new(0, 180, 0, 36)
    toggleBtn.Position = UDim2.new(0.5, -90, 0, 20)
    toggleBtn.Text = "Toggle (G)"
    toggleBtn.Font = Enum.Font.GothamBold
    toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggleBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 75)
    toggleBtn.BorderSizePixel = 0
    toggleBtn.Parent = mainFrame

    local toggleCorner = Instance.new("UICorner", toggleBtn)
    toggleCorner.CornerRadius = UDim.new(0, 12)

    toggleBtn.MouseEnter:Connect(function()
        TweenService:Create(toggleBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(90, 90, 100)}):Play()
    end)
    toggleBtn.MouseLeave:Connect(function()
        TweenService:Create(toggleBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(70, 70, 75)}):Play()
    end)

    -- Prediction input
    local predBox = Instance.new("TextBox")
    predBox.Size = UDim2.new(0, 180, 0, 30)
    predBox.Position = UDim2.new(0.5, -90, 0, 70)
    predBox.Text = tostring(PREDICTION_TIME)
    predBox.PlaceholderText = "Prediction (s)"
    predBox.Font = Enum.Font.Gotham
    predBox.TextColor3 = Color3.fromRGB(255,255,255)
    predBox.BackgroundColor3 = Color3.fromRGB(70,70,75)
    predBox.BorderSizePixel = 0
    predBox.TextScaled = true
    predBox.ClearTextOnFocus = false
    predBox.Parent = mainFrame
    local predCorner = Instance.new("UICorner", predBox)
    predCorner.CornerRadius = UDim.new(0, 12)

    predBox.FocusLost:Connect(function(enterPressed)
        local num = tonumber(predBox.Text)
        if num and num > 0 and num <= 5 then -- clamp between 0 and 5 seconds
            PREDICTION_TIME = num
        else
            predBox.Text = tostring(PREDICTION_TIME)
        end
    end)

    -- FOV circle
    local circle = Instance.new("Frame", gui)
    circle.Size = UDim2.fromOffset(RADIUS_PIXELS*2, RADIUS_PIXELS*2)
    circle.AnchorPoint = Vector2.new(0.5, 0.5)
    circle.BackgroundTransparency = 1
    circle.BorderSizePixel = 0
    circle.Visible = false

    local circleCorner = Instance.new("UICorner", circle)
    circleCorner.CornerRadius = UDim.new(1, 0)
    local circleStroke = Instance.new("UIStroke", circle)
    circleStroke.Thickness = 2
    circleStroke.Color = FOV_COLOR

    -- FUNCTIONS
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
            if obj:IsA("Model") and obj:FindFirstChild("Humanoid") and obj:FindFirstChild("Head") then
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
            local head = char:FindFirstChild("Head")
            local humanoid = char:FindFirstChildOfClass("Humanoid")
            if head and humanoid and humanoid.Health > 0 then
                local screenPos, onScreen = Camera:WorldToViewportPoint(head.Position)
                if onScreen then
                    local dist = (Vector2.new(Mouse.X, Mouse.Y) - Vector2.new(screenPos.X, screenPos.Y)).Magnitude
                    if dist < RADIUS_PIXELS and dist < closestDist and isVisible(head) then
                        closest = head
                        closestDist = dist
                    end
                end
            end
        end
        return closest
    end

    -- TOGGLE
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

    -- MAIN LOOP
    RunService.RenderStepped:Connect(function()
        circle.Position = UDim2.fromOffset(Mouse.X, Mouse.Y)
        if aimbotEnabled then
            local target = getClosestTarget()
            if target then
                local velocity = target.AssemblyLinearVelocity or Vector3.new(0,0,0)
                local predictedPos = target.Position + velocity * PREDICTION_TIME
                Camera.CFrame = CFrame.new(Camera.CFrame.Position, predictedPos)
            end
        end
    end)
end)


