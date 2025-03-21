local unanchoredParts = {}
local player = game.Players.LocalPlayer
local mouse = player:GetMouse()
local gravityStrength = 1000
local spinSpeed = 10
local repulsionStrength = 500
local lastClickTime = 0
local doubleClickThreshold = 0.3
local gravityActive = false
local gravityTarget = nil
local maxParts = 50 -- Limit the number of parts affected.

local function findUnanchoredParts()
    unanchoredParts = {}
    local count = 0
    for _, part in pairs(workspace:GetDescendants()) do
        if part:IsA("BasePart") and not part.Anchored then
            local parent = part.Parent
            local isPlayerPart = false
            while parent do
                if parent:IsA("Model") and parent:FindFirstChild("Humanoid") then
                    isPlayerPart = true
                    break
                end
                parent = parent.Parent
            end
            if not isPlayerPart then
                table.insert(unanchoredParts, part)
                count = count +1
                if count >= maxParts then break end
            end
        end
    end
end

local function applyGravity(position)
    if not position then return end
    for i, part in ipairs(unanchoredParts) do
        local gravityDirection = (position - part.Position).Unit
        local gravityForce = gravityDirection * gravityStrength
        local repulsionForce = Vector3.new(0, 0, 0)

        -- Optimized repulsion calculation
        for j = i + 1, #unanchoredParts do
            local otherPart = unanchoredParts[j]
            local distance = (part.Position - otherPart.Position).Magnitude
            if distance < 5 then
                local repulsionDirection = (part.Position - otherPart.Position).Unit
                local force = repulsionDirection * (repulsionStrength / (distance + 0.1))
                repulsionForce = repulsionForce + force
                local otherRepulsion = force * -1;
                if otherPart:FindFirstChild("BodyVelocity") then otherPart.BodyVelocity.Velocity = otherPart.BodyVelocity.Velocity + otherRepulsion else local otherBodyVelocity = Instance.new("BodyVelocity") otherBodyVelocity.Velocity = otherRepulsion otherBodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge) otherBodyVelocity.Parent = otherPart end
            end
        end

        local combinedForce = gravityForce + repulsionForce

        if part:FindFirstChild("BodyVelocity") then
            part.BodyVelocity.Velocity = combinedForce
        else
            local bodyVelocity = Instance.new("BodyVelocity")
            bodyVelocity.Velocity = combinedForce
            bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
            bodyVelocity.Parent = part
        end

        if part:FindFirstChild("AngularVelocity") then
            part.AngularVelocity.AngularVelocity = Vector3.new(0, spinSpeed, 0)
        else
            local angularVelocity = Instance.new("AngularVelocity")
            angularVelocity.AngularVelocity = Vector3.new(0, spinSpeed, 0)
            angularVelocity.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
            angularVelocity.Parent = part
        end
    end
end

local function onMouseClick(mouse)
    local currentTime = tick()
    if currentTime - lastClickTime < doubleClickThreshold then
        findUnanchoredParts()
        gravityActive = true
        gravityTarget = mouse.Hit.p
        for _, part in ipairs(unanchoredParts) do
            part.CanCollide = false
            part.CollisionGroup = "NoCollideAll"
        end
        game:GetService("CollisionGroupService"):CreateCollisionGroup("NoCollideAll")
        game:GetService("CollisionGroupService"):CollisionGroupSetCollidable("NoCollideAll", "NoCollideAll", false)
        for _, otherPlayer in pairs(game.Players:GetPlayers()) do
            if otherPlayer ~= player then
                game:GetService("CollisionGroupService"):CollisionGroupSetCollidable("NoCollideAll", otherPlayer.Character and otherPlayer.Character.CollisionGroup or "Default", true)
            end
        end
    end
    lastClickTime = currentTime
end

mouse.Button1Down:Connect(function()
    onMouseClick(mouse)
end)

game:GetService("RunService").Heartbeat:Connect(function()
    if gravityActive and gravityTarget then
        applyGravity(gravityTarget)
    end
end)
