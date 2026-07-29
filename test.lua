-- POV Checker 70° - Shows for ALL Players (Based on Head)
-- Delta Optimized

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

-- Configuration
local FOV_ANGLE = 70
local VISUAL_DISTANCE = 10

-- Create folder for visuals
local folder = Instance.new("Folder")
folder.Name = "POVVisuals_AllPlayers"
folder.Parent = Workspace

-- Store visuals per player
local playerVisuals = {}

-- Function to create fan visuals for a player
local function createPlayerVisuals()
    local visuals = {
        fanLines = {},
        boundaryLeft = nil,
        boundaryRight = nil,
        arcParts = {},
        centerDot = nil
    }
    
    -- Create fan lines
    for i = 1, 13 do
        local line = Instance.new("Part")
        line.Size = Vector3.new(0.1, 0.05, 1)
        line.Anchored = true
        line.CanCollide = false
        line.Transparency = 0.3 + (i/13) * 0.2
        line.Material = Enum.Material.Neon
        line.BrickColor = BrickColor.new("Bright red")
        line.Parent = folder
        table.insert(visuals.fanLines, line)
    end
    
    -- Create boundaries
    local function createBoundary()
        local part = Instance.new("Part")
        part.Size = Vector3.new(0.15, 0.05, 10)
        part.Anchored = true
        part.CanCollide = false
        part.Transparency = 0.3
        part.Material = Enum.Material.Neon
        part.BrickColor = BrickColor.new("Bright red")
        part.Parent = folder
        return part
    end
    
    visuals.boundaryLeft = createBoundary()
    visuals.boundaryRight = createBoundary()
    
    -- Create arc
    for i = 1, 7 do
        local arc = Instance.new("Part")
        arc.Size = Vector3.new(0.1, 0.05, 0.5)
        arc.Anchored = true
        arc.CanCollide = false
        arc.Transparency = 0.35
        arc.Material = Enum.Material.Neon
        arc.BrickColor = BrickColor.new("Bright red")
        arc.Parent = folder
        table.insert(visuals.arcParts, arc)
    end
    
    -- Center dot
    local dot = Instance.new("Part")
    dot.Size = Vector3.new(0.3, 0.05, 0.3)
    dot.Anchored = true
    dot.CanCollide = false
    dot.Transparency = 0.2
    dot.Material = Enum.Material.Neon
    dot.BrickColor = BrickColor.new("White")
    dot.Shape = Enum.PartType.Ball
    dot.Parent = folder
    visuals.centerDot = dot
    
    return visuals
end

-- Function to update a player's visuals
local function updatePlayerVisuals(player)
    local character = player.Character
    if not character then 
        -- Hide visuals if character doesn't exist
        if playerVisuals[player] then
            for _, line in ipairs(playerVisuals[player].fanLines) do
                line.Transparency = 1
            end
            playerVisuals[player].boundaryLeft.Transparency = 1
            playerVisuals[player].boundaryRight.Transparency = 1
            for _, arc in ipairs(playerVisuals[player].arcParts) do
                arc.Transparency = 1
            end
            playerVisuals[player].centerDot.Transparency = 1
        end
        return 
    end
    
    -- Get head and root
    local head = character:FindFirstChild("Head")
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not head or not rootPart then return end
    
    -- Get visuals for this player, create if doesn't exist
    if not playerVisuals[player] then
        playerVisuals[player] = createPlayerVisuals()
    end
    
    local visuals = playerVisuals[player]
    
    -- Make visuals visible
    for _, line in ipairs(visuals.fanLines) do
        line.Transparency = 0.3 + (i/13) * 0.2
    end
    visuals.boundaryLeft.Transparency = 0.3
    visuals.boundaryRight.Transparency = 0.3
    for _, arc in ipairs(visuals.arcParts) do
        arc.Transparency = 0.35
    end
    visuals.centerDot.Transparency = 0.2
    
    local rootPos = rootPart.Position
    local headCFrame = head.CFrame
    local lookVector = headCFrame.LookVector
    
    -- Ground position
    local groundPos = rootPos - Vector3.new(0, 2, 0)
    
    -- Flat look direction
    local flatLook = Vector3.new(lookVector.X, 0, lookVector.Z).Unit
    if flatLook.Magnitude < 0.001 then return end
    
    local centerAngle = math.atan2(flatLook.X, flatLook.Z)
    local angleOffset = math.rad(FOV_ANGLE/2)
    local distance = VISUAL_DISTANCE
    
    -- Update fan lines
    for i, line in ipairs(visuals.fanLines) do
        local t = (i - 1) / (#visuals.fanLines - 1)
        local angle = centerAngle - angleOffset + (t * angleOffset * 2)
        
        local endPos = groundPos + Vector3.new(
            math.sin(angle) * distance,
            0.05,
            math.cos(angle) * distance
        )
        
        local midPoint = (groundPos + endPos) / 2
        local direction = (endPos - groundPos).Unit
        local length = (endPos - groundPos).Magnitude
        
        line.CFrame = CFrame.lookAt(midPoint, midPoint + direction)
        line.Size = Vector3.new(0.1, 0.05, length)
    end
    
    -- Update boundaries
    local leftAngle = centerAngle - angleOffset
    local rightAngle = centerAngle + angleOffset
    
    local leftEnd = groundPos + Vector3.new(
        math.sin(leftAngle) * distance,
        0.05,
        math.cos(leftAngle) * distance
    )
    local rightEnd = groundPos + Vector3.new(
        math.sin(rightAngle) * distance,
        0.05,
        math.cos(rightAngle) * distance
    )
    
    local leftMid = (groundPos + leftEnd) / 2
    local rightMid = (groundPos + rightEnd) / 2
    
    visuals.boundaryLeft.CFrame = CFrame.lookAt(leftMid, leftMid + (leftEnd - groundPos).Unit)
    visuals.boundaryLeft.Size = Vector3.new(0.15, 0.05, (leftEnd - groundPos).Magnitude)
    
    visuals.boundaryRight.CFrame = CFrame.lookAt(rightMid, rightMid + (rightEnd - groundPos).Unit)
    visuals.boundaryRight.Size = Vector3.new(0.15, 0.05, (rightEnd - groundPos).Magnitude)
    
    -- Update arc
    for i, arc in ipairs(visuals.arcParts) do
        local t = (i - 1) / (#visuals.arcParts - 1)
        local angle = leftAngle + (t * angleOffset * 2)
        
        local arcPos = groundPos + Vector3.new(
            math.sin(angle) * distance,
            0.05,
            math.cos(angle) * distance
        )
        
        arc.CFrame = CFrame.new(arcPos)
        arc.Size = Vector3.new(0.1, 0.05, 0.5)
        
        if i < #visuals.arcParts then
            local nextT = (i) / (#visuals.arcParts - 1)
            local nextAngle = leftAngle + (nextT * angleOffset * 2)
            local nextPos = groundPos + Vector3.new(
                math.sin(nextAngle) * distance,
                0.05,
                math.cos(nextAngle) * distance
            )
            local dir = (nextPos - arcPos).Unit
            if dir.Magnitude > 0 then
                arc.CFrame = CFrame.lookAt(arcPos, arcPos + dir)
            end
        end
    end
    
    -- Update center dot
    local dotPos = groundPos + Vector3.new(flatLook.X * 5, 0.05, flatLook.Z * 5)
    visuals.centerDot.CFrame = CFrame.new(dotPos)
end

-- Update all players
local function updateAllPlayers()
    for _, player in ipairs(Players:GetPlayers()) do
        updatePlayerVisuals(player)
    end
end

-- Connect events
Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        wait(0.1)
        updatePlayerVisuals(player)
    end)
end)

Players.PlayerRemoving:Connect(function(player)
    if playerVisuals[player] then
        -- Remove visuals
        for _, line in ipairs(playerVisuals[player].fanLines) do
            line:Destroy()
        end
        playerVisuals[player].boundaryLeft:Destroy()
        playerVisuals[player].boundaryRight:Destroy()
        for _, arc in ipairs(playerVisuals[player].arcParts) do
            arc:Destroy()
        end
        playerVisuals[player].centerDot:Destroy()
        playerVisuals[player] = nil
    end
end)

-- Main loop
RunService.Heartbeat:Connect(function()
    updateAllPlayers()
end)

print("✅ 70° POV Fan showing for ALL players!")
