-- Delta Animation ID Capturer
-- Captures unique animation IDs for player: senjmwua
-- Skips duplicate IDs automatically

local player = game.Players["senjmwua"]
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

local capturedAnimations = {}
local animTracker = {}

-- Function to capture animation ID
local function captureAnimationId(animTrack)
    if not animTrack then return end
    
    -- Get animation ID from the track
    local animation = animTrack.Animation
    if not animation then return end
    
    local animationId = animation.AnimationId
    if not animationId or animationId == "" then return end
    
    -- Extract just the ID number if full URL
    local id = animationId:match("rbxassetid://(%d+)") or animationId
    
    -- Check if already captured
    if not capturedAnimations[id] then
        capturedAnimations[id] = {
            id = id,
            fullId = animationId,
            firstCaptured = os.time(),
            track = animTrack
        }
        
        print(string.format("[NEW ANIMATION] ID: %s", id))
        print(string.format("Full URL: %s", animationId))
        print("---")
        
        -- Optional: Log to a table for later use
        table.insert(animTracker, {
            id = id,
            timestamp = os.time(),
            player = player.Name
        })
    end
end

-- Hook into animation played event
humanoid.AnimationPlayed:Connect(function(animTrack)
    captureAnimationId(animTrack)
end)

-- Also check for already playing animations
for _, animTrack in pairs(humanoid.Animator:GetPlayingAnimationTracks()) do
    captureAnimationId(animTrack)
end

-- Monitor new animations being loaded
local function onAnimationAdded(animator, animationTrack)
    task.wait(0.1) -- Small delay to ensure proper loading
    captureAnimationId(animationTrack)
end

humanoid.Animator.AnimationTrackAdded:Connect(onAnimationAdded)

-- Print summary function
function printCapturedAnimations()
    print(string.format("\n=== CAPTURED ANIMATION IDs (%d) ===", #animTracker))
    for i, data in ipairs(animTracker) do
        print(string.format("%d. ID: %s", i, data.id))
    end
    print("====================================\n")
end

-- Auto-save to a file (if in a plugin or script context)
function saveAnimationsToFile()
    if not game:IsStudio() then 
        print("Auto-save only works in Studio")
        return 
    end
    
    local json = game:GetService("HttpService"):JSONEncode(animTracker)
    local file = io.open("captured_animations.json", "w")
    if file then
        file:write(json)
        file:close()
        print("Saved animations to captured_animations.json")
    end
end

-- Print captured IDs every 10 seconds
task.spawn(function()
    while task.wait(10) do
        if #animTracker > 0 then
            print(string.format("Captured %d unique animation IDs so far", #animTracker))
        end
    end
end)

print("Delta Animation ID Capturer initialized for player: " .. player.Name)
print("Listening for animation changes...")

-- Keybind: Press F5 to print all captured IDs
game:GetService("UserInputService").InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.F5 and input.UserInputType == Enum.UserInputType.Keyboard then
        printCapturedAnimations()
    end
end)

-- Auto-save on exit (Studio only)
if game:IsStudio() then
    game:BindToClose(function()
        saveAnimationsToFile()
    end)
end
