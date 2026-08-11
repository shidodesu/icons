-- Auto-Parry with GUI (tweak hold duration, start delay, radius)
-- Paste into Delta Executor

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer

-- Default settings (will be overridden by GUI)
local settings = {
    Radius = 7,
    HoldMs = 100,
    DelayMs = 50,
    Enabled = true,
}

-- ─── Your attack animation IDs ──────────────────────
local ATTACK_ANIMS = {
    ["rbxassetid://137980914350618"] = true,
    ["rbxassetid://100408082509740"] = true,
    ["rbxassetid://94803478352691"] = true,
    ["rbxassetid://78695517680318"] = true,
    ["rbxassetid://132022052139564"] = true,
}

-- ─── GUI Creation ──────────────────────────────────
local function createGUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "ParryGUI"
    screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

    -- Main Frame
    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 220, 0, 200)
    mainFrame.Position = UDim2.new(0.5, -110, 0.5, -100)
    mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    mainFrame.BackgroundTransparency = 0.1
    mainFrame.BorderSizePixel = 1
    mainFrame.BorderColor3 = Color3.fromRGB(255, 255, 255)
    mainFrame.Active = true
    mainFrame.Draggable = false  -- we'll implement custom drag
    mainFrame.Parent = screenGui

    -- Drag bar
    local dragBar = Instance.new("Frame")
    dragBar.Size = UDim2.new(1, 0, 0, 25)
    dragBar.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
    dragBar.BorderSizePixel = 0
    dragBar.Parent = mainFrame
    dragBar.ZIndex = 2

    local dragText = Instance.new("TextLabel")
    dragText.Size = UDim2.new(1, 0, 1, 0)
    dragText.BackgroundTransparency = 1
    dragText.Text = "⚙️ Parry Settings"
    dragText.TextColor3 = Color3.fromRGB(255, 255, 255)
    dragText.TextSize = 14
    dragText.Font = Enum.Font.GothamBold
    dragText.TextXAlignment = Enum.TextXAlignment.Center
    dragText.Parent = dragBar

    -- Enable toggle
    local enableBtn = Instance.new("TextButton")
    enableBtn.Size = UDim2.new(0, 60, 0, 22)
    enableBtn.Position = UDim2.new(0.7, 0, 0.05, 0)
    enableBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
    enableBtn.Text = "ON"
    enableBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    enableBtn.TextSize = 12
    enableBtn.Font = Enum.Font.GothamBold
    enableBtn.Parent = mainFrame
    enableBtn.ZIndex = 2

    -- Helper function to create labeled slider
    local function createSlider(parent, labelText, minVal, maxVal, defaultVal, yPos)
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(0.5, -5, 0, 20)
        label.Position = UDim2.new(0.05, 0, yPos, 0)
        label.BackgroundTransparency = 1
        label.Text = labelText
        label.TextColor3 = Color3.fromRGB(220, 220, 220)
        label.TextSize = 12
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Font = Enum.Font.Gotham
        label.Parent = parent

        local valueBox = Instance.new("TextBox")
        valueBox.Size = UDim2.new(0.3, 0, 0, 20)
        valueBox.Position = UDim2.new(0.6, 0, yPos, 0)
        valueBox.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
        valueBox.TextColor3 = Color3.fromRGB(255, 255, 255)
        valueBox.Text = tostring(defaultVal)
        valueBox.TextSize = 12
        valueBox.Font = Enum.Font.Gotham
        valueBox.ClearTextOnFocus = false
        valueBox.Parent = parent

        return label, valueBox
    end

    -- Radius slider
    local _, radiusBox = createSlider(mainFrame, "Radius (studs)", 3, 15, settings.Radius, 0.25)
    radiusBox:GetPropertyChangedSignal("Text"):Connect(function()
        local val = tonumber(radiusBox.Text)
        if val then settings.Radius = math.clamp(val, 3, 15) end
        radiusBox.Text = tostring(settings.Radius)
    end)

    -- Hold Duration slider (ms)
    local _, holdBox = createSlider(mainFrame, "Hold (ms)", 20, 500, settings.HoldMs, 0.45)
    holdBox:GetPropertyChangedSignal("Text"):Connect(function()
        local val = tonumber(holdBox.Text)
        if val then settings.HoldMs = math.clamp(val, 20, 500) end
        holdBox.Text = tostring(settings.HoldMs)
    end)

    -- Delay before press (ms)
    local _, delayBox = createSlider(mainFrame, "Start Delay (ms)", 0, 300, settings.DelayMs, 0.65)
    delayBox:GetPropertyChangedSignal("Text"):Connect(function()
        local val = tonumber(delayBox.Text)
        if val then settings.DelayMs = math.clamp(val, 0, 300) end
        delayBox.Text = tostring(settings.DelayMs)
    end)

    -- Toggle button logic
    enableBtn.MouseButton1Click:Connect(function()
        settings.Enabled = not settings.Enabled
        enableBtn.Text = settings.Enabled and "ON" or "OFF"
        enableBtn.BackgroundColor3 = settings.Enabled and Color3.fromRGB(0, 200, 0) or Color3.fromRGB(200, 0, 0)
    end)

    -- Drag logic for the frame
    local dragging = false
    local dragOffset = Vector2.new()

    dragBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragOffset = Vector2.new(input.Position.X - mainFrame.AbsolutePosition.X, input.Position.Y - mainFrame.AbsolutePosition.Y)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local newPos = input.Position - dragOffset
            mainFrame.Position = UDim2.new(0, newPos.X, 0, newPos.Y)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    return screenGui
end

-- ─── Create the GUI ──────────────────────────────
local gui = createGUI()

-- ─── Core functions ──────────────────────────────

local function getHRP(player)
    local char = player.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function isFacing(attackerHRP, victimHRP)
    local toVictim = (victimHRP.Position - attackerHRP.Position).Unit
    local dot = attackerHRP.CFrame.LookVector:Dot(toVictim)
    return math.acos(math.clamp(dot, -1, 1)) <= math.rad(60)
end

-- Hold using touch (with move event)
local function holdBlockButton(holdMs)
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    if not playerGui then return end
    local touchGui = playerGui:FindFirstChild("TouchGui")
    if not touchGui then return end
    local controls = touchGui:FindFirstChild("TouchControlFrame")
    if not controls then return end
    local jumpButton = controls:FindFirstChild("JumpButton")
    if not jumpButton then return end
    local blockButton = jumpButton:FindFirstChild("BlockButton")
    if not blockButton then return end

    local pos = blockButton.AbsolutePosition
    local size = blockButton.AbsoluteSize
    local inset = GuiService:GetGuiInset()
    local x = pos.X + size.X / 2 + inset.X
    local y = pos.Y + size.Y / 2 + inset.Y

    local touchId = math.random(10000, 99999)

    pcall(VirtualInputManager.SendTouchEvent, VirtualInputManager, touchId, 0, x, y)
    task.wait(holdMs * 0.001)  -- convert ms to seconds
    pcall(VirtualInputManager.SendTouchEvent, VirtualInputManager, touchId, 2, x, y)
end

-- ─── Detection loop ──────────────────────────────

local parriedThisFrame = {}
local playerAnimators = {}

RunService.PreSimulation:Connect(function()
    if not settings.Enabled then return end

    local myChar = LocalPlayer.Character
    local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myHRP then return end

    parriedThisFrame = {}

    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end

        local attackerHRP = getHRP(player)
        if not attackerHRP then continue end

        local dist = (attackerHRP.Position - myHRP.Position).Magnitude
        if dist > settings.Radius then continue end

        if not isFacing(attackerHRP, myHRP) then continue end

        -- Get animator
        local animator = playerAnimators[player]
        if not animator or not animator.Parent then
            local char = player.Character
            if not char then continue end
            local hum = char:FindFirstChildOfClass("Humanoid")
            if not hum then continue end
            animator = hum:FindFirstChildOfClass("Animator")
            if not animator then continue end
            playerAnimators[player] = animator
        end

        local tracks = animator:GetPlayingAnimationTracks()
        local hasAttack = false
        for _, track in ipairs(tracks) do
            local id = track.Animation and track.Animation.AnimationId or ""
            if ATTACK_ANIMS[id] then
                hasAttack = true
                break
            end
        end

        if hasAttack and not parriedThisFrame[player] then
            parriedThisFrame[player] = true
            -- Apply start delay
            task.spawn(function()
                if settings.DelayMs > 0 then
                    task.wait(settings.DelayMs * 0.001)
                end
                holdBlockButton(settings.HoldMs)
            end)
        end
    end
end)

print("✅ Auto-Parry GUI loaded – tweak settings in the on-screen menu")
