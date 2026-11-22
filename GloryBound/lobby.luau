--[[
    GloryBound Auto-Farm Hub (BehindTheDark Edition)
    Open-source auto-training & auto-rebirth for GloryBound
    Styled with the BehindTheDark Design System

    Features:
      - BehindTheDark 3D cartoon UI with anime glints and particle effects
      - Select 1.5x barbells or 1x dumbbells
      - Auto-train at max speed (3 reps/sec, safe teleport + auto-rep)
      - Auto-rebirth when RebirthReady (capped at MAX_REBIRTH = 50)
      - Live strength & status monitor with animated indicators
      - Built-in anti-AFK (VirtualUser + VirtualInputManager fallback)
      - Full lifecycle management & anti-duplicate cleanup
--]]

repeat task.wait() until game:IsLoaded()

local env = (type(getgenv) == "function" and getgenv()) or _G
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local playerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Clean up existing instance
if env.GloryBound_Instance then
    pcall(function()
        env.GloryBound_Instance.Running = false
        if env.GloryBound_Instance.Gui then
            env.GloryBound_Instance.Gui:Destroy()
        end
    end)
end

local Controller = { Running = true }
env.GloryBound_Instance = Controller

-- Clean up legacy GUIs
local oldGuis = { "GloryBoundAutoFarm", "BehindTheDark_GloryBound" }
for _, gName in ipairs(oldGuis) do
    pcall(function()
        local g = CoreGui:FindFirstChild(gName) or playerGui:FindFirstChild(gName)
        if g then g:Destroy() end
    end)
end

-- ========================================================
-- LOAD BEHIND THE DARK UI LIBRARY
-- ========================================================
local libUrl = "https://raw.githubusercontent.com/PKNUDG/BehindTheDarkLib/main/BehindTheDarkLib.luau?v=" .. os.time()
local libRaw: string? = nil
local rf = (type(readfile) == "function" and readfile) or nil

local successLib, res = pcall(function()
    return game:HttpGet(libUrl)
end)

if successLib and res and res ~= "" and not res:find("404: Not Found") then
    libRaw = res
elseif rf then
    pcall(function()
        libRaw = rf("BehindTheDarkLib.luau")
    end)
end

if not libRaw then
    error("[GloryBound] Failed to load BehindTheDarkLib from remote or local storage.")
end

local libChunk, libErr = loadstring(libRaw)
if not libChunk then
    error("[GloryBound] Syntax Error in BehindTheDarkLib: " .. tostring(libErr))
end
local Library = libChunk()

-- ========================================================
-- GAME REMOTES & CONTROLLER STATE
-- ========================================================
local Remotes = ReplicatedStorage:WaitForChild("Remotes", 15)
if not Remotes then
    error("[GloryBound] 'Remotes' folder not found in ReplicatedStorage.")
end

local TrainRepRemote = Remotes:WaitForChild("TrainRep", 15)
local TrainStopRemote = Remotes:WaitForChild("TrainStop", 15)
local RebirthRemote = Remotes:WaitForChild("Rebirth", 15)

if not TrainRepRemote or not TrainStopRemote or not RebirthRemote then
    error("[GloryBound] Required remotes not found in ReplicatedStorage.Remotes.")
end

local ClientState: any = nil
pcall(function()
    local pScripts = LocalPlayer:WaitForChild("PlayerScripts", 10)
    local controllers = pScripts and pScripts:WaitForChild("Controllers", 10)
    local stateMod = controllers and controllers:WaitForChild("ClientState", 10)
    if stateMod and stateMod:IsA("ModuleScript") then
        ClientState = require(stateMod)
    end
end)

local function getState()
    if not ClientState or type(ClientState.get) ~= "function" then return nil end
    local ok, state = pcall(ClientState.get)
    return (ok and state) or nil
end

-- ========================================================
-- CONFIGURATION & RUNTIME STATES
-- ========================================================
local REP_INTERVAL = 0.33
local REBIRTH_STOP_DELAY = 0.3
local MAX_REBIRTH = 50

local autoTrain = false
local autoRebirth = false
local equipmentMode = "1.5x"
local lastRepTime = 0
local isRebirthing = false
local isStartingTraining = false
local statusText = "Idle"

local connections = {}
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
    task.wait(0.1)
    if root then
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
    end
end

-- ========================================================
-- CORE AUTO-FARM LOGIC
-- ========================================================
local function findMachine()
    local lobby = workspace:FindFirstChild("Lobby")
    if not lobby then return nil end
    local gym = lobby:FindFirstChild("Gym")
    if not gym then return nil end
    local barbells = gym:FindFirstChild("Barbells")
    if not barbells then return nil end

    local root = getRoot()
    if not root then return nil end
    local best, bestDist = nil, math.huge

    for _, b in ipairs(barbells:GetChildren()) do
        local boost = b:GetAttribute("Boost")
        local occupant = b:GetAttribute("Occupant")
        local prompt = b:FindFirstChild("TrainPrompt", true)

        local matchesMode
        if equipmentMode == "1.5x" then
            matchesMode = boost and boost >= 1.5
        else
            matchesMode = not boost or boost < 1.5
        end

        local isFree = (occupant == 0 or occupant == nil or occupant == "" or occupant == LocalPlayer.UserId)

        if matchesMode and prompt and isFree then
            local part = b:FindFirstChildWhichIsA("BasePart", true)
            if part then
                local dist = (root.Position - part.Position).Magnitude
                if dist < bestDist then
                    bestDist = dist
                    best = { model = b, prompt = prompt, part = part }
                end
            end
        end
    end

    return best
end

local function triggerPrompt(prompt: ProximityPrompt)
    if typeof(fireproximityprompt) == "function" then
        pcall(fireproximityprompt, prompt)
    else
        pcall(function()
            prompt:InputHoldBegin()
            task.wait(prompt.HoldDuration or 0.1)
            prompt:InputHoldEnd()
        end)
    end
end

local function startTraining()
    if isStartingTraining or not Controller.Running then return false end
    isStartingTraining = true

    local ok, success = pcall(function()
        local machine = findMachine()
        if not machine then
            statusText = "No available " .. equipmentMode .. " machine"
            return false
        end

        local root = getRoot()
        if not root then
            statusText = "Waiting for character..."
            return false
        end

        statusText = "Moving to " .. machine.model.Name .. "..."
        safeTeleport(CFrame.new(machine.part.Position + Vector3.new(0, 3, 0)))
        task.wait(0.5)

        if not Controller.Running then return false end

        triggerPrompt(machine.prompt)
        task.wait(1)

        local training = LocalPlayer:GetAttribute("Training")
        if training and training ~= "" then
            statusText = "Training at " .. machine.model.Name
            return true
        else
            statusText = "Failed to start — retrying"
            return false
        end
    end)

    isStartingTraining = false
    return ok and success
end

local function skipRebirthCutscene()
    local pScripts = LocalPlayer:FindFirstChild("PlayerScripts")
    local controllers = pScripts and pScripts:FindFirstChild("Controllers")
    if not controllers then return end
    local cutscene = controllers:FindFirstChild("RebirthCutscene")
    if not cutscene then return end
    local ok, mod = pcall(require, cutscene)
    if ok and type(mod) == "table" and mod.isPlaying and mod.isPlaying() then
        pcall(mod.stop)
    end
end

local function doRebirth()
    if isRebirthing or not Controller.Running then return end
    isRebirthing = true
    statusText = "Rebirthing..."

    pcall(function()
        local stBefore = getState()
        local beforeRebirth = (stBefore and stBefore.Rebirth) or 0

        local training = LocalPlayer:GetAttribute("Training")
        if training and training ~= "" then
            TrainStopRemote:FireServer()
            task.wait(REBIRTH_STOP_DELAY)
        end

        RebirthRemote:FireServer()
        task.wait(1)
        skipRebirthCutscene()

        local stAfter = getState()
        local afterRebirth = (stAfter and stAfter.Rebirth) or beforeRebirth

        if afterRebirth <= beforeRebirth then
            statusText = "Moving to shrine..."
            local shrine = workspace:FindFirstChild("Lobby")
            if shrine then shrine = shrine:FindFirstChild("Stations") end
            if shrine then shrine = shrine:FindFirstChild("RebirthShrine") end
            if shrine then
                local part = shrine:FindFirstChildWhichIsA("BasePart", true)
                if part then
                    safeTeleport(CFrame.new(part.Position + Vector3.new(0, 3, 0)))
                    task.wait(0.5)
                    RebirthRemote:FireServer()
                    task.wait(1)
                    skipRebirthCutscene()
                end
            end
        end

        local stFinal = getState()
        local finalRebirth = (stFinal and stFinal.Rebirth) or beforeRebirth
        if finalRebirth > beforeRebirth then
            statusText = "Rebirth done — resuming"
        else
            statusText = "Rebirth failed — will retry"
        end
    end)

    task.wait(0.5)
    isRebirthing = false
end

-- ========================================================
-- BEHIND THE DARK GUI SETUP
-- ========================================================
local Window = Library.CreateWindow({
    Title = "GLORY BOUND - AUTO FARM",
    Name = "BehindTheDark_GloryBound",
    Size = UDim2.fromOffset(560, 330),
    OnUnload = function()
        Controller.Running = false
        for _, conn in ipairs(connections) do
            pcall(function() conn:Disconnect() end)
        end
        table.clear(connections)
        env.GloryBound_Instance = nil
        print("[GloryBound] Script unloaded successfully.")
    end
})
Controller.Gui = Window.Gui

-- LEFT COLUMN: Controls
Window:CreateToggle("Left", "Auto Train", 0, {
    On = Color3.fromRGB(115, 245, 85),
    Off = Color3.fromRGB(120, 120, 130)
}, autoTrain, function(v)
    autoTrain = v
    if not v then
        local training = LocalPlayer:GetAttribute("Training")
        if training and training ~= "" then
            TrainStopRemote:FireServer()
        end
        statusText = "Idle"
    end
end)

Window:CreateDropdown("Left", "Equipment", 48, { "1.5x Barbells", "1x Dumbbells" }, "1.5x Barbells", 30, function(selected)
    if selected == "1.5x Barbells" then
        equipmentMode = "1.5x"
    else
        equipmentMode = "1x"
    end

    if autoTrain then
        local training = LocalPlayer:GetAttribute("Training")
        if training and training ~= "" then
            TrainStopRemote:FireServer()
        end
    end
end)

Window:CreateToggle("Left", "Auto Rebirth (Max 50)", 96, {
    On = Color3.fromRGB(245, 185, 45),
    Off = Color3.fromRGB(120, 120, 130)
}, autoRebirth, function(v)
    autoRebirth = v
end)

Window:CreateActionButton("Left", "Unload Script", 144,
    Color3.fromRGB(255, 100, 100),
    Color3.fromRGB(210, 45, 60),
    function()
        if Window.Unload then
            Window.Unload()
        else
            Controller.Running = false
            for _, conn in ipairs(connections) do
                pcall(function() conn:Disconnect() end)
            end
            table.clear(connections)
            if Window.Gui then Window.Gui:Destroy() end
            env.GloryBound_Instance = nil
        end
    end
)

-- RIGHT COLUMN: Live Stats & Status Card
local rightParent = Window:GetColumn("Right")

local statsCard = Instance.new("Frame")
statsCard.Name = "StatsCard"
statsCard.Size = UDim2.new(1, 0, 1, 0)
statsCard.Position = UDim2.fromOffset(0, 0)
statsCard.BackgroundColor3 = Color3.fromRGB(28, 8, 46)
statsCard.BorderSizePixel = 0
statsCard.ZIndex = 5
statsCard.Parent = rightParent
Instance.new("UICorner", statsCard).CornerRadius = UDim.new(0, 14)

local statsStroke = Instance.new("UIStroke")
statsStroke.Parent = statsCard
statsStroke.Thickness = 2.5
statsStroke.Color = Color3.fromRGB(185, 140, 245)

local statsLayout = Instance.new("UIListLayout")
statsLayout.Padding = UDim.new(0, 8)
statsLayout.SortOrder = Enum.SortOrder.LayoutOrder
statsLayout.Parent = statsCard

local cardPadding = Instance.new("UIPadding")
cardPadding.PaddingTop = UDim.new(0, 12)
cardPadding.PaddingBottom = UDim.new(0, 12)
cardPadding.PaddingLeft = UDim.new(0, 14)
cardPadding.PaddingRight = UDim.new(0, 14)
cardPadding.Parent = statsCard

-- Header
local statsHeader = Instance.new("TextLabel")
statsHeader.Size = UDim2.new(1, 0, 0, 22)
statsHeader.BackgroundTransparency = 1
statsHeader.Text = "LIVE MONITOR"
statsHeader.TextColor3 = Color3.fromRGB(255, 220, 100)
statsHeader.Font = Enum.Font.FredokaOne
statsHeader.TextSize = 15
statsHeader.TextXAlignment = Enum.TextXAlignment.Left
statsHeader.LayoutOrder = 1
statsHeader.ZIndex = 6
statsHeader.Parent = statsCard

local headerStroke = Instance.new("UIStroke")
headerStroke.Parent = statsHeader
headerStroke.Thickness = 2
headerStroke.Color = Color3.fromRGB(22, 5, 36)

-- Strength Label & Value
local strTitle = Instance.new("TextLabel")
strTitle.Size = UDim2.new(1, 0, 0, 16)
strTitle.BackgroundTransparency = 1
strTitle.Text = "STRENGTH PROGRESS"
strTitle.TextColor3 = Color3.fromRGB(200, 175, 235)
strTitle.Font = Enum.Font.FredokaOne
strTitle.TextSize = 12
strTitle.TextXAlignment = Enum.TextXAlignment.Left
strTitle.LayoutOrder = 2
strTitle.ZIndex = 6
strTitle.Parent = statsCard

local strDisplay = Instance.new("TextLabel")
strDisplay.Size = UDim2.new(1, 0, 0, 26)
strDisplay.BackgroundColor3 = Color3.fromRGB(18, 4, 30)
strDisplay.BorderSizePixel = 0
strDisplay.Text = "0 / 0"
strDisplay.TextColor3 = Color3.fromRGB(115, 245, 85)
strDisplay.Font = Enum.Font.FredokaOne
strDisplay.TextSize = 14
strDisplay.LayoutOrder = 3
strDisplay.ZIndex = 6
strDisplay.Parent = statsCard
Instance.new("UICorner", strDisplay).CornerRadius = UDim.new(0, 8)

local strDisplayStroke = Instance.new("UIStroke")
strDisplayStroke.Parent = strDisplay
strDisplayStroke.Thickness = 1.5
strDisplayStroke.Color = Color3.fromRGB(124, 82, 190)

-- Rebirth Count Display
local rebTitle = Instance.new("TextLabel")
rebTitle.Size = UDim2.new(1, 0, 0, 16)
rebTitle.BackgroundTransparency = 1
rebTitle.Text = "CURRENT REBIRTH"
rebTitle.TextColor3 = Color3.fromRGB(200, 175, 235)
rebTitle.Font = Enum.Font.FredokaOne
rebTitle.TextSize = 12
rebTitle.TextXAlignment = Enum.TextXAlignment.Left
rebTitle.LayoutOrder = 4
rebTitle.ZIndex = 6
rebTitle.Parent = statsCard

local rebDisplay = Instance.new("TextLabel")
rebDisplay.Size = UDim2.new(1, 0, 0, 26)
rebDisplay.BackgroundColor3 = Color3.fromRGB(18, 4, 30)
rebDisplay.BorderSizePixel = 0
rebDisplay.Text = "0 / 50"
rebDisplay.TextColor3 = Color3.fromRGB(255, 205, 75)
rebDisplay.Font = Enum.Font.FredokaOne
rebDisplay.TextSize = 14
rebDisplay.LayoutOrder = 5
rebDisplay.ZIndex = 6
rebDisplay.Parent = statsCard
Instance.new("UICorner", rebDisplay).CornerRadius = UDim.new(0, 8)

local rebDisplayStroke = Instance.new("UIStroke")
rebDisplayStroke.Parent = rebDisplay
rebDisplayStroke.Thickness = 1.5
rebDisplayStroke.Color = Color3.fromRGB(124, 82, 190)

-- Status Display
local statusTitle = Instance.new("TextLabel")
statusTitle.Size = UDim2.new(1, 0, 0, 16)
statusTitle.BackgroundTransparency = 1
statusTitle.Text = "CURRENT STATUS"
statusTitle.TextColor3 = Color3.fromRGB(200, 175, 235)
statusTitle.Font = Enum.Font.FredokaOne
statusTitle.TextSize = 12
statusTitle.TextXAlignment = Enum.TextXAlignment.Left
statusTitle.LayoutOrder = 6
statusTitle.ZIndex = 6
statusTitle.Parent = statsCard

local statusDisplay = Instance.new("TextLabel")
statusDisplay.Size = UDim2.new(1, 0, 0, 30)
statusDisplay.BackgroundColor3 = Color3.fromRGB(18, 4, 30)
statusDisplay.BorderSizePixel = 0
statusDisplay.Text = "Idle"
statusDisplay.TextColor3 = Color3.fromRGB(240, 230, 255)
statusDisplay.Font = Enum.Font.FredokaOne
statusDisplay.TextSize = 12
statusDisplay.TextWrapped = true
statusDisplay.LayoutOrder = 7
statusDisplay.ZIndex = 6
statusDisplay.Parent = statsCard
Instance.new("UICorner", statusDisplay).CornerRadius = UDim.new(0, 8)

local statusDisplayStroke = Instance.new("UIStroke")
statusDisplayStroke.Parent = statusDisplay
statusDisplayStroke.Thickness = 1.5
statusDisplayStroke.Color = Color3.fromRGB(124, 82, 190)

-- ========================================================
-- BACKGROUND LOOPS & HEARTBEAT
-- ========================================================
connect(RunService.Heartbeat, function()
    if not Controller.Running or not Window.Gui or not Window.Gui.Parent then return end
    local state = getState()
    if state then
        strDisplay.Text = string.format("%d / %d", state.Strength or 0, state.StrengthCap or 0)
        rebDisplay.Text = string.format("%d / %d", state.Rebirth or 0, MAX_REBIRTH)
    end
    statusDisplay.Text = statusText
end)

-- Main auto-farm task
task.spawn(function()
    while Controller.Running and Window.Gui and Window.Gui.Parent do
        if autoTrain and not isRebirthing and not isStartingTraining then
            local state = getState()
            if state then
                local training = LocalPlayer:GetAttribute("Training")
                local zone = LocalPlayer:GetAttribute("Zone")

                if zone == "Arena" then
                    statusText = "In Arena — paused"
                elseif autoRebirth and state.RebirthReady and (state.Rebirth or 0) < MAX_REBIRTH then
                    doRebirth()
                elseif not training or training == "" then
                    local started = startTraining()
                    if not started then
                        task.wait(1)
                    end
                else
                    local now = os.clock()
                    if now - lastRepTime >= REP_INTERVAL then
                        TrainRepRemote:FireServer(1)
                        lastRepTime = now
                    end
                    statusText = "Training..."
                end
            end
        elseif not autoTrain then
            statusText = "Idle"
        end
        task.wait(0.1)
    end
end)

-- Respawn handling
connect(LocalPlayer.CharacterAdded, function()
    if autoTrain and Controller.Running then
        task.wait(1)
        lastRepTime = 0
    end
end)

-- Anti-AFK Simulation
local bbVirtualUser: any = nil
pcall(function() bbVirtualUser = game:GetService("VirtualUser") end)
local vim: any = nil
pcall(function() vim = game:GetService("VirtualInputManager") end)

connect(LocalPlayer.Idled, function()
    if not Controller.Running then return end
    local handled = false
    if bbVirtualUser then
        pcall(function()
            bbVirtualUser:CaptureController()
            bbVirtualUser:ClickButton2(Vector2.new())
            handled = true
        end)
    end
    if not handled and vim then
        pcall(function()
            vim:SendKeyEvent(true, Enum.KeyCode.RightControl, false, game)
            task.wait(0.05)
            vim:SendKeyEvent(false, Enum.KeyCode.RightControl, false, game)
        end)
    end
end)

print("[GloryBound Auto-Farm] Loaded successfully with BehindTheDark Theme! Toggle UI with Right Shift.")
