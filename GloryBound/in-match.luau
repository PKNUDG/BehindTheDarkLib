--[[
    GloryBound In-Match Combat Controller v1.2
    Auto-Target, Teleport Behind, Server-Remote Attack & Red AoE Evasion
    Styled with BehindTheDark HUD aesthetics

    Fixes applied:
      - Multi-Wave Targeting: Fully handles corpse cleanup and subfolders (ActiveEnemies.WaveX)
      - Server Damage Hit Registration: Fires ReplicatedStorage.Remotes.Attack with accurate direction unit
      - Red Circle / AoE Detection: Uses engine Spatial Query (GetPartBoundsInRadius) + Keyword & Color matching
      - Safe 3D Dodge: Warps backward & high into the air out of ground AoE danger, returning when safe
      - Keybind [V] Toggle + BehindTheDark draggable HUD
--]]

repeat task.wait() until game:IsLoaded()

local env = (type(getgenv) == "function" and getgenv()) or _G
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera or Workspace:WaitForChild("Camera")

local Controller = { Running = true }
local connections = {}

function Controller.Unload()
    Controller.Running = false
    for _, conn in ipairs(connections) do
        pcall(function() conn:Disconnect() end)
    end
    table.clear(connections)
    if Controller.Gui and Controller.Gui.Parent then
        Controller.Gui:Destroy()
    end
    env.GloryBound_InMatchInstance = nil
    print("[GloryBound In-Match] Unloaded.")
end

-- Clean up any existing in-match instance
if env.GloryBound_InMatchInstance then
    pcall(function()
        if type(env.GloryBound_InMatchInstance.Unload) == "function" then
            env.GloryBound_InMatchInstance.Unload()
        else
            env.GloryBound_InMatchInstance.Running = false
            if env.GloryBound_InMatchInstance.Gui then
                env.GloryBound_InMatchInstance.Gui:Destroy()
            end
        end
    end)
end

env.GloryBound_InMatchInstance = Controller

local oldGui = CoreGui:FindFirstChild("BehindTheDark_InMatchHUD")
    or (LocalPlayer:FindFirstChild("PlayerGui") and LocalPlayer.PlayerGui:FindFirstChild("BehindTheDark_InMatchHUD"))
if oldGui then
    pcall(function() oldGui:Destroy() end)
end

-- ========================================================
-- REMOTES & INPUT EMULATION SERVICES
-- ========================================================
local Remotes = ReplicatedStorage:WaitForChild("Remotes", 15)
local AttackRemote: any = Remotes and Remotes:FindFirstChild("Attack")

local VirtualUser: any = nil
pcall(function() VirtualUser = game:GetService("VirtualUser") end)

local VirtualInputManager: any = nil
pcall(function() VirtualInputManager = game:GetService("VirtualInputManager") end)

local function clickMouse()
    local viewport = Camera and Camera.ViewportSize or Vector2.new(1920, 1080)
    local cx = math.floor(viewport.X / 2)
    local cy = math.floor(viewport.Y / 2)

    local successVim = false
    if VirtualInputManager then
        successVim = pcall(function()
            VirtualInputManager:SendMouseButtonEvent(cx, cy, 0, true, game, 0)
            task.wait(0.03)
            VirtualInputManager:SendMouseButtonEvent(cx, cy, 0, false, game, 0)
        end)
    end

    if not successVim and VirtualUser then
        pcall(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton1(Vector2.new(cx, cy))
        end)
    end
end

-- ========================================================
-- CONFIGURATION & STATES
-- ========================================================
local autoCombat = true
local currentTarget: Model? = nil
local combatStatus = "Idle"
local targetHpText = "—"
local comboCounter = 1

local BEHIND_DISTANCE = 3.2          -- Studs behind target
local SAFE_DODGE_BACK = 28.0         -- Studs to dodge back
local SAFE_DODGE_HEIGHT = 16.0       -- Studs to dodge up into the air
local ATTACK_INTERVAL = 0.12         -- Attack speed
local TELEGRAPH_DETECT_RADIUS = 32.0 -- Detection radius for danger circles

local function connect(signal, fn)
    local conn = signal:Connect(fn)
    table.insert(connections, conn)
    return conn
end

local function getRoot(): BasePart?
    local char = LocalPlayer.Character
    return char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
end

local function safeTeleport(targetCFrame: CFrame)
    local root = getRoot()
    if not root then return end
    root.AssemblyLinearVelocity = Vector3.zero
    root.AssemblyAngularVelocity = Vector3.zero
    root.CFrame = targetCFrame
    task.wait(0.02)
    if root then
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
    end
end

-- ========================================================
-- MULTI-WAVE TARGETING (WORKSPACE.ACTIVEENEMIES)
-- ========================================================
local function getActiveEnemiesFolder(): Instance?
    return Workspace:FindFirstChild("ActiveEnemies")
end

local function getEnemyRoot(enemy: Model): BasePart?
    return enemy:FindFirstChild("HumanoidRootPart") :: BasePart?
        or enemy:FindFirstChild("Torso") :: BasePart?
        or enemy:FindFirstChild("UpperTorso") :: BasePart?
        or enemy.PrimaryPart
        or enemy:FindFirstChildWhichIsA("BasePart")
end

local function isEnemyAlive(enemy: Model): boolean
    if not enemy or not enemy.Parent then return false end

    -- Verify enemy is still in ActiveEnemies hierarchy
    local folder = getActiveEnemiesFolder()
    if not folder or not enemy:IsDescendantOf(folder) then
        return false
    end

    -- Check death attributes common in combat games
    if enemy:GetAttribute("Dead") == true
        or enemy:GetAttribute("IsDead") == true
        or enemy:GetAttribute("Dying") == true
        or enemy:GetAttribute("Defeated") == true then
        return false
    end

    local hpAttr = enemy:GetAttribute("Health") or enemy:GetAttribute("HP")
    if hpAttr ~= nil and tonumber(hpAttr) and tonumber(hpAttr) <= 0 then
        return false
    end

    -- Check Humanoid health and state
    local hum = enemy:FindFirstChildOfClass("Humanoid")
    if hum then
        if hum.Health <= 0 or hum:GetState() == Enum.HumanoidStateType.Dead then
            return false
        end
        return true
    end

    -- If no Humanoid, must have a valid RootPart
    local root = getEnemyRoot(enemy)
    return root ~= nil
end

local function getClosestEnemy(): Model?
    local folder = getActiveEnemiesFolder()
    if not folder then return nil end

    local myRoot = getRoot()
    if not myRoot then return nil end

    local myPos = myRoot.Position
    local closest: Model? = nil
    local minDistance = math.huge

    -- Scan descendants to catch both direct models and wave subfolders (e.g. ActiveEnemies.Wave2)
    for _, desc in ipairs(folder:GetDescendants()) do
        if desc:IsA("Model") and isEnemyAlive(desc) then
            -- Exclude nested sub-models (like hats, weapons, accessories)
            local isSubModel = desc.Parent and desc.Parent:IsA("Model") and desc.Parent ~= folder
            if not isSubModel then
                local enemyRoot = getEnemyRoot(desc)
                if enemyRoot then
                    local dist = (enemyRoot.Position - myPos).Magnitude
                    if dist < minDistance then
                        minDistance = dist
                        closest = desc
                    end
                end
            end
        end
    end

    return closest
end

-- ========================================================
-- RED CIRCLE & AOE DANGER DETECTION
-- ========================================================
local overlapParams = OverlapParams.new()
overlapParams.FilterType = Enum.RaycastFilterType.Exclude

local function isRedOrTelegraphPart(part: BasePart): boolean
    if not part or not part.Parent then return false end
    if LocalPlayer.Character and part:IsDescendantOf(LocalPlayer.Character) then return false end

    local name = string.lower(part.Name)
    local pName = string.lower(part.Parent.Name)

    -- 1. Keyword indicators
    if string.find(name, "hitbox")
        or string.find(name, "telegraph")
        or string.find(name, "warning")
        or string.find(name, "aoe")
        or string.find(name, "indicator")
        or string.find(name, "danger")
        or string.find(name, "zone")
        or string.find(name, "circle")
        or string.find(name, "ring")
        or string.find(name, "radius")
        or string.find(name, "red")
        or string.find(pName, "attack")
        or string.find(pName, "warn")
        or string.find(pName, "indicator")
        or string.find(pName, "telegraph")
        or string.find(pName, "circle") then
        return true
    end

    -- 2. Red color spectrum detection
    local c = part.Color
    local isReddish = (c.R > 0.55 and c.R > c.G * 1.25 and c.R > c.B * 1.25)
        or (c.R > 0.75 and c.G < 0.45)
        or part.BrickColor == BrickColor.new("Really red")
        or part.BrickColor == BrickColor.new("Bright red")
        or part.BrickColor == BrickColor.new("Crimson")
        or part.BrickColor == BrickColor.new("Persimmon")

    if isReddish and part.Transparency < 0.98 then
        return true
    end

    -- 3. Neon or Cylinder ground discs
    if part.Material == Enum.Material.Neon and (c.R > 0.5 or string.find(part.BrickColor.Name, "Red")) then
        return true
    end

    -- 4. Red Highlight or Decal/Texture
    for _, ch in ipairs(part:GetChildren()) do
        if ch:IsA("Highlight") and ch.Enabled then
            local hc = ch.FillColor
            if hc.R > 0.55 and hc.R > hc.G * 1.2 then
                return true
            end
        elseif (ch:IsA("Decal") or ch:IsA("Texture")) and ch.Transparency < 0.9 then
            local tc = ch.Color3
            if tc.R > 0.55 and tc.R > tc.G * 1.2 then
                return true
            end
        end
    end

    return false
end

local function detectNearbyDanger(centerPos: Vector3): boolean
    if LocalPlayer.Character then
        overlapParams.FilterDescendantsInstances = { LocalPlayer.Character }
    end

    -- Spatial query around target position
    local parts = Workspace:GetPartBoundsInRadius(centerPos, TELEGRAPH_DETECT_RADIUS, overlapParams)
    for _, part in ipairs(parts) do
        if isRedOrTelegraphPart(part) then
            return true
        end
    end

    -- Check visual containers in Workspace
    local containers = {
        Workspace:FindFirstChild("Effects"),
        Workspace:FindFirstChild("Visuals"),
        Workspace:FindFirstChild("Debris"),
        Workspace:FindFirstChild("Attacks")
    }
    for _, cont in ipairs(containers) do
        if cont then
            for _, desc in ipairs(cont:GetDescendants()) do
                if desc:IsA("BasePart") and isRedOrTelegraphPart(desc) then
                    if (desc.Position - centerPos).Magnitude <= TELEGRAPH_DETECT_RADIUS then
                        return true
                    end
                end
            end
        end
    end

    return false
end

-- ========================================================
-- ATTACK EXECUTION (SERVER REMOTE + CLIENT MOUSE)
-- ========================================================
local function performAttack(enemyRoot: BasePart)
    local myRoot = getRoot()
    if not myRoot then return end

    local direction = (enemyRoot.Position - myRoot.Position).Unit

    -- 1. Direct Server Remote (Guarantees damage registration!)
    if AttackRemote and AttackRemote:IsA("RemoteEvent") then
        pcall(function()
            comboCounter = (comboCounter % 7) + 1
            AttackRemote:FireServer(7, direction)
            if comboCounter ~= 7 then
                AttackRemote:FireServer(comboCounter, direction)
            end
        end)
    end

    -- 2. Visual click emulation & equipped tool activation
    clickMouse()
    local char = LocalPlayer.Character
    local tool = char and char:FindFirstChildOfClass("Tool")
    if tool then
        pcall(function() tool:Activate() end)
    end
end

-- ========================================================
-- BEHIND THE DARK HUD OVERLAY
-- ========================================================
local gui = Instance.new("ScreenGui")
gui.Name = "BehindTheDark_InMatchHUD"
gui.ResetOnSpawn = false
gui.DisplayOrder = 100000
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local placedInCore = pcall(function() gui.Parent = CoreGui end)
if not placedInCore or not gui.Parent then
    gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end
Controller.Gui = gui

local hudFrame = Instance.new("Frame")
hudFrame.Name = "HUDFrame"
hudFrame.Size = UDim2.fromOffset(260, 115)
hudFrame.Position = UDim2.new(0, 24, 0.5, -57)
hudFrame.BackgroundColor3 = Color3.fromRGB(24, 6, 38)
hudFrame.BorderSizePixel = 0
hudFrame.ZIndex = 10
hudFrame.Parent = gui
Instance.new("UICorner", hudFrame).CornerRadius = UDim.new(0, 16)

local hudStroke = Instance.new("UIStroke")
hudStroke.Thickness = 3
hudStroke.Color = Color3.fromRGB(185, 140, 245)
hudStroke.Parent = hudFrame

local hudInner = Instance.new("Frame")
hudInner.Size = UDim2.new(1, -6, 1, -6)
hudInner.Position = UDim2.fromOffset(3, 3)
hudInner.BackgroundColor3 = Color3.fromRGB(38, 12, 62)
hudInner.BorderSizePixel = 0
hudInner.ZIndex = 11
hudInner.Parent = hudFrame
Instance.new("UICorner", hudInner).CornerRadius = UDim.new(0, 13)

local hudGradient = Instance.new("UIGradient")
hudGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0.00, Color3.fromRGB(168, 122, 232)),
    ColorSequenceKeypoint.new(0.55, Color3.fromRGB(124, 82, 190)),
    ColorSequenceKeypoint.new(1.00, Color3.fromRGB(82, 48, 142))
})
hudGradient.Rotation = 90
hudGradient.Parent = hudInner

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 4)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Parent = hudInner

local hudPadding = Instance.new("UIPadding")
hudPadding.PaddingTop = UDim.new(0, 8)
hudPadding.PaddingBottom = UDim.new(0, 8)
hudPadding.PaddingLeft = UDim.new(0, 12)
hudPadding.PaddingRight = UDim.new(0, 12)
hudPadding.Parent = hudInner

-- Title / Toggle Row
local titleRow = Instance.new("Frame")
titleRow.Size = UDim2.new(1, 0, 0, 22)
titleRow.BackgroundTransparency = 1
titleRow.LayoutOrder = 1
titleRow.ZIndex = 12
titleRow.Parent = hudInner

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -55, 1, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "AUTO COMBAT [V]"
titleLabel.TextColor3 = Color3.fromRGB(255, 230, 120)
titleLabel.Font = Enum.Font.FredokaOne
titleLabel.TextSize = 13
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.ZIndex = 12
titleLabel.Parent = titleRow

local toggleBadge = Instance.new("TextButton")
toggleBadge.Size = UDim2.fromOffset(50, 20)
toggleBadge.Position = UDim2.new(1, -50, 0, 1)
toggleBadge.BackgroundColor3 = Color3.fromRGB(115, 245, 85)
toggleBadge.BorderSizePixel = 0
toggleBadge.Text = "ON"
toggleBadge.TextColor3 = Color3.fromRGB(22, 5, 36)
toggleBadge.Font = Enum.Font.FredokaOne
toggleBadge.TextSize = 11
toggleBadge.ZIndex = 13
toggleBadge.Parent = titleRow
Instance.new("UICorner", toggleBadge).CornerRadius = UDim.new(0, 6)

local function updateToggleVisual()
    toggleBadge.Text = autoCombat and "ON" or "OFF"
    TweenService:Create(toggleBadge, TweenInfo.new(0.18), {
        BackgroundColor3 = autoCombat and Color3.fromRGB(115, 245, 85) or Color3.fromRGB(100, 100, 115),
        TextColor3 = autoCombat and Color3.fromRGB(22, 5, 36) or Color3.fromRGB(220, 220, 230)
    }):Play()
end

toggleBadge.MouseButton1Click:Connect(function()
    autoCombat = not autoCombat
    updateToggleVisual()
end)

-- Target Info Label
local targetLabel = Instance.new("TextLabel")
targetLabel.Size = UDim2.new(1, 0, 0, 20)
targetLabel.BackgroundTransparency = 1
targetLabel.Text = "Target: Searching..."
targetLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
targetLabel.Font = Enum.Font.FredokaOne
targetLabel.TextSize = 12
targetLabel.TextXAlignment = Enum.TextXAlignment.Left
targetLabel.TextTruncate = Enum.TextTruncate.AtEnd
targetLabel.LayoutOrder = 2
targetLabel.ZIndex = 12
targetLabel.Parent = hudInner

-- Health / Status Line
local hpLabel = Instance.new("TextLabel")
hpLabel.Size = UDim2.new(1, 0, 0, 18)
hpLabel.BackgroundTransparency = 1
hpLabel.Text = "HP: —"
hpLabel.TextColor3 = Color3.fromRGB(255, 175, 220)
hpLabel.Font = Enum.Font.FredokaOne
hpLabel.TextSize = 11
hpLabel.TextXAlignment = Enum.TextXAlignment.Left
hpLabel.LayoutOrder = 3
hpLabel.ZIndex = 12
hpLabel.Parent = hudInner

-- Combat Status Banner
local statusBadge = Instance.new("TextLabel")
statusBadge.Size = UDim2.new(1, 0, 0, 22)
statusBadge.BackgroundColor3 = Color3.fromRGB(20, 5, 32)
statusBadge.BorderSizePixel = 0
statusBadge.Text = "Status: Idle"
statusBadge.TextColor3 = Color3.fromRGB(195, 160, 250)
statusBadge.Font = Enum.Font.FredokaOne
statusBadge.TextSize = 11
statusBadge.LayoutOrder = 4
statusBadge.ZIndex = 12
statusBadge.Parent = hudInner
Instance.new("UICorner", statusBadge).CornerRadius = UDim.new(0, 6)

-- Dragging Support
local dragging, dragStart, startPos = false, nil, nil
connect(hudFrame.InputBegan, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = hudFrame.Position
    end
end)

connect(UserInputService.InputChanged, function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        hudFrame.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end
end)

connect(UserInputService.InputEnded, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

-- Keybind [V] with TextBox focus check
connect(UserInputService.InputBegan, function(input, gpe)
    if gpe or UserInputService:GetFocusedTextBox() then return end
    if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == Enum.KeyCode.V then
        autoCombat = not autoCombat
        updateToggleVisual()
    end
end)

-- ========================================================
-- MAIN COMBAT & EVASION LOOP
-- ========================================================
local lastAttackTick = 0

task.spawn(function()
    while Controller.Running and gui.Parent do
        if autoCombat then
            local myRoot = getRoot()
            if not myRoot then
                combatStatus = "Waiting for character..."
                task.wait(0.3)
                continue
            end

            -- Automatically discard dead/invalid targets
            if currentTarget and not isEnemyAlive(currentTarget) then
                currentTarget = nil
            end

            -- Acquire new target if none
            if not currentTarget then
                currentTarget = getClosestEnemy()
                if not currentTarget then
                    combatStatus = "Waiting for next wave..."
                    targetLabel.Text = "Target: None"
                    hpLabel.Text = "HP: —"
                    task.wait(0.2)
                    continue
                end
            end

            local enemyRoot = getEnemyRoot(currentTarget)
            if not enemyRoot then
                currentTarget = nil
                continue
            end

            -- Update target display information
            local hum = currentTarget:FindFirstChildOfClass("Humanoid")
            if hum then
                targetHpText = string.format("%d / %d", math.floor(hum.Health), math.floor(hum.MaxHealth))
            else
                local hpAttr = currentTarget:GetAttribute("Health") or currentTarget:GetAttribute("HP")
                targetHpText = hpAttr and tostring(hpAttr) or "Alive"
            end
            targetLabel.Text = "Target: " .. currentTarget.Name
            hpLabel.Text = "HP: " .. targetHpText

            -- Check for red warning telegraph / AoE hitbox danger
            local dangerDetected = detectNearbyDanger(enemyRoot.Position) or detectNearbyDanger(myRoot.Position)

            if dangerDetected then
                -- DODGE: Warp backward AND high into the air out of ground AoE danger
                combatStatus = "⚡ DODGING RED CIRCLE!"
                statusBadge.TextColor3 = Color3.fromRGB(255, 90, 90)

                local retreatCFrame = enemyRoot.CFrame * CFrame.new(0, SAFE_DODGE_HEIGHT, SAFE_DODGE_BACK)
                safeTeleport(CFrame.lookAt(retreatCFrame.Position, enemyRoot.Position))

                task.wait(0.2)
            else
                combatStatus = "⚔ Attacking from behind"
                statusBadge.TextColor3 = Color3.fromRGB(115, 245, 85)

                -- POSITION: Teleport directly behind the enemy, facing towards its back
                local behindCFrame = enemyRoot.CFrame * CFrame.new(0, 0, BEHIND_DISTANCE)
                local lookAtEnemyCFrame = CFrame.lookAt(behindCFrame.Position, enemyRoot.Position)

                -- Only warp if position drifted
                if (myRoot.Position - behindCFrame.Position).Magnitude > 1.8 then
                    safeTeleport(lookAtEnemyCFrame)
                else
                    myRoot.CFrame = lookAtEnemyCFrame
                end

                -- ATTACK: Fire server remote & mouse simulation
                local now = os.clock()
                if now - lastAttackTick >= ATTACK_INTERVAL then
                    performAttack(enemyRoot)
                    lastAttackTick = now
                end
            end
        else
            combatStatus = "Paused ([V] to resume)"
            statusBadge.TextColor3 = Color3.fromRGB(200, 200, 210)
        end

        task.wait(0.04)
    end
end)

-- UI Status Updater Loop
connect(RunService.Heartbeat, function()
    if not Controller.Running or not gui.Parent then return end
    statusBadge.Text = "Status: " .. combatStatus
end)

-- Character respawn handler
connect(LocalPlayer.CharacterAdded, function()
    task.wait(0.8)
    currentTarget = nil
end)

print("[GloryBound In-Match] v1.2 loaded! Target, Attack Remote & Red AoE Evasion Active.")
