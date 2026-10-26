-- ========================================================
-- CANDY TD : IN-MATCH CONTROLLER (SUB-PAGE & CUSTOM STAGE)
-- ========================================================
repeat task.wait() until game:IsLoaded()

local env = (type(getgenv) == "function" and getgenv()) or _G
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GuiService = game:GetService("GuiService")
local TeleportService = game:GetService("TeleportService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local Lighting = game:GetService("Lighting")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

if _G.CandyTD_InMatchInstance then
    pcall(function()
        _G.CandyTD_InMatchInstance.Running = false
        if _G.CandyTD_InMatchInstance.Gui then
            _G.CandyTD_InMatchInstance.Gui:Destroy()
        end
    end)
end

local Controller = { Running = true }
_G.CandyTD_InMatchInstance = Controller

local oldGuis = { "CandyTD_BehindTheDarkHub", "CandyTD_UniversalHub" }
for _, gName in ipairs(oldGuis) do
    pcall(function()
        local g = CoreGui:FindFirstChild(gName) or playerGui:FindFirstChild(gName)
        if g then g:Destroy() end
    end)
end

-- ========================================================
-- ANTI-GAMEPLAYPAUSED & RECONNECT & ANTI-AFK
-- ========================================================
pcall(function() GuiService:SetGameplayPausedNotificationEnabled(false) end)

task.spawn(function()
    while Controller.Running do
        task.wait(0.5)
        pcall(function()
            local robloxGui = CoreGui:FindFirstChild("RobloxGui")
            if robloxGui then
                local pauseNotif = robloxGui:FindFirstChild("GameplayPausedNotification")
                if pauseNotif and pauseNotif.Visible then pauseNotif.Visible = false end
            end
            local candyTDGui = playerGui:FindFirstChild("CandyTD")
            if candyTDGui then
                local pauseFrame = candyTDGui:FindFirstChild("Pause", true) or candyTDGui:FindFirstChild("GameplayPaused", true)
                if pauseFrame and pauseFrame.Visible then pauseFrame.Visible = false end
            end
        end)
    end
end)

GuiService.ErrorMessageChanged:Connect(function(errorMessage)
    if Controller.Running and errorMessage and errorMessage ~= "" then
        task.wait(2)
        pcall(function() TeleportService:Teleport(game.PlaceId, player) end)
    end
end)

local bbVirtualUser = nil
pcall(function() bbVirtualUser = game:GetService("VirtualUser") end)
player.Idled:Connect(function()
    if Controller.Running then
        pcall(function()
            if bbVirtualUser then
                bbVirtualUser:CaptureController()
                bbVirtualUser:ClickButton2(Vector2.new())
            else
                VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
                task.wait(0.05)
                VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
            end
        end)
    end
end)

-- ========================================================
-- POTATO BOOST FPS ENGINE
-- ========================================================
local function applyUltraBoostFPS(enable: boolean)
    if enable then
        pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level01 end)
        pcall(function()
            Lighting.GlobalShadows = false
            Lighting.FogEnd = 9e9
            Lighting.Brightness = 1
            Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
        end)
        for _, obj in ipairs(workspace:GetDescendants()) do
            pcall(function()
                if obj:IsA("BasePart") then
                    obj.Material = Enum.Material.SmoothPlastic
                    obj.CastShadow = false
                elseif obj:IsA("Texture") or obj:IsA("Decal") then
                    obj.Transparency = 1
                elseif obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Highlight") then
                    obj.Enabled = false
                end
            end)
        end
    else
        pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Automatic end)
    end
end

local candyTD = playerGui:WaitForChild("CandyTD", 30)
local candyTDStorage = ReplicatedStorage:WaitForChild("CandyTD", 30)
local matchNet: any = nil
pcall(function()
    local module = candyTDStorage:WaitForChild("MatchNet", 10)
    if module and module:IsA("ModuleScript") then
        matchNet = (require :: any)(module)
    end
end)

task.spawn(function()
    local banner = candyTD:WaitForChild("Banner", 15)
    if banner then
        local textLabel = banner:FindFirstChildWhichIsA("TextLabel", true)
        local function checkBannerText()
            if textLabel and banner.Visible then
                local txt = (textLabel.Text or ""):upper()
                if txt:find("NOT ENOUGH MONEY") or txt:find("FULLY UPGRADED") or txt:find("ANOTHER UPGRADE") then
                    banner.Visible = false
                    banner.Position = UDim2.new(2, 0, 2, 0)
                end
            end
        end
        banner:GetPropertyChangedSignal("Visible"):Connect(checkBannerText)
        if textLabel then textLabel:GetPropertyChangedSignal("Text"):Connect(checkBannerText) end
    end
end)

local function triggerInternalButton(btn: Instance?)
    if not btn then return false end
    pcall(function()
        local firesig = (rawget(env, "firesignal") or firesignal) :: any
        if firesig then
            if btn:IsA("GuiButton") then
                firesig(btn.Activated)
                firesig(btn.MouseButton1Click)
            end
            for _, ch in ipairs(btn:GetChildren()) do
                if ch:IsA("GuiButton") then
                    firesig(ch.Activated)
                    firesig(ch.MouseButton1Click)
                end
            end
        end
    end)
    return true
end

local function requestMatchAction(action: string, ...)
    local ok, res = false, nil
    if matchNet and matchNet.request then
        ok, res = pcall(matchNet.request, action, ...)
    end
    if not ok then
        local matchRemotes = ReplicatedStorage:FindFirstChild("MatchRemotes")
        if matchRemotes then
            local req = matchRemotes:FindFirstChild("Request") or matchRemotes:FindFirstChild(action)
            if req then
                if req:IsA("RemoteFunction") then
                    pcall(req.InvokeServer, req, action, ...)
                elseif req:IsA("RemoteEvent") then
                    pcall(req.FireServer, req, action, ...)
                end
            end
        end
    end
    return res
end

-- ========================================================
-- PRESET & FILE SYSTEM (CANDYTD_PRESETS.JSON)
-- ========================================================
local PRESET_FILE = "CandyTD_Presets.json"

local DefaultStagePresets = {
    ["Raid Halloween"] = {
        { unit = "AlienJake", x = -23.374317169189453, z = -29.752378463745117 },
        { unit = "AlienJake", x = -21.034372329711914, z = -30.95560073852539 },
        { unit = "Lemongrab3", x = -18.13538932800293, z = -24.010784149169922 },
        { unit = "Lemongrab3", x = -15.872089385986328, z = -24.980955123901367 },
        { unit = "CandyElemental", x = -12.905556678771973, z = -26.32013702392578 },
        { unit = "CandyElemental", x = -10.390554428100586, z = -28.499164581298828 },
        { unit = "HunsonDemon", x = -10.000167846679688, z = -30.825727462768555 }
    },
    ["Inf Bug Milk"] = {
        { unit = "AlienJake", x = -12.826902389526367, z = -31.56324577331543 },
        { unit = "AlienJake", x = -14.521763801574707, z = -29.90790367126465 },
        { unit = "CandyElemental", x = -17.214988708496094, z = -28.374713897705078 },
        { unit = "CandyElemental", x = -15.965791702270508, z = -31.911561965942383 },
        { unit = "Lemongrab3", x = -9.518001556396484, z = -24.649188995361328 },
        { unit = "Lemongrab3", x = -10.839069366455078, z = -22.71699333190918 },
        { unit = "HunsonDemon", x = -7.739049434661865, z = -26.240154266357422, setTarget = "strongest" },
        { unit = "VampireKingCloud", x = -6.147939205169678, z = -28.48414421081543, setTarget = "strongest" },
        { unit = "PrismRainicorn", x = -19.20961570739746, z = -27.122318267822266, setTarget = "strongest" },
        { unit = "PrismRainicorn", x = -18.643310546875, z = -30.057519912719727, setTarget = "strongest" }
    }
}

local StagePresets = {}

local function savePresetsToFile()
    local wf = (type(writefile) == "function" and writefile) or nil
    if wf then
        pcall(function()
            local encoded = HttpService:JSONEncode(StagePresets)
            wf(PRESET_FILE, encoded)
        end)
    end
end

local function loadPresetsFromFile()
    local rf = (type(readfile) == "function" and readfile) or nil
    local loaded = false
    if rf then
        local ok, data = pcall(rf, PRESET_FILE)
        if ok and data and data ~= "" then
            local decodedOk, parsed = pcall(HttpService.JSONDecode, HttpService, data)
            if decodedOk and type(parsed) == "table" then
                StagePresets = parsed
                loaded = true
            end
        end
    end
    if not loaded then
        StagePresets = DefaultStagePresets
        savePresetsToFile()
    else
        for k, v in pairs(DefaultStagePresets) do
            if StagePresets[k] == nil then
                StagePresets[k] = v
            end
        end
    end
end

loadPresetsFromFile()

local function getStageNames(): {string}
    local names = {}
    for stageName, _ in pairs(StagePresets) do
        table.insert(names, stageName)
    end
    table.sort(names)
    return names
end

local states = {
    EndChoice = "AGAIN",
    AutoUpgrade = true,
    AgainBeforeHomeActive = false,
    AutoSkipWave = true,
    BoostFPS = false,
    AutoPlace = false,
    RecordMode = false,
    CurrentStage = "Inf Bug Milk",
    RecordStageName = "My New Stage",
    TargetRounds = 10,
    CurrentRounds = 0
}

local onUnitRecorded: (() -> ())? = nil

-- ========================================================
-- IN-GAME RECORDER HOOK (ปลอดภัย ไม่ทำเกมหลุด)
-- ========================================================
local function hookPlacementRecorder()
    local hookMeta = (type(hookmetamethod) == "function" and hookmetamethod) or nil
    if hookMeta then
        local oldNamecall
        oldNamecall = hookMeta(game, "__namecall", function(self, ...)
            local method = getnamecallmethod()
            local args = { ... }
            if states.RecordMode and (method == "InvokeServer" or method == "FireServer") and (tostring(self.Name) == "Act" or tostring(self.Name) == "Request") then
                local targetStage = (states.RecordStageName and states.RecordStageName ~= "") and states.RecordStageName or states.CurrentStage
                if args[1] == "place" and args[2] and args[3] and args[4] then
                    StagePresets[targetStage] = StagePresets[targetStage] or {}
                    local currentQueue = StagePresets[targetStage]
                    table.insert(currentQueue, {
                        unit = tostring(args[2]),
                        x = tonumber(args[3]),
                        z = tonumber(args[4])
                    })
                    savePresetsToFile()
                    print(string.format("[Recorder] บันทึกลำดับที่ %d: %s (X: %.2f, Z: %.2f) ในด่าน '%s'", #currentQueue, tostring(args[2]), tonumber(args[3]), tonumber(args[4]), targetStage))
                    if onUnitRecorded then onUnitRecorded() end
                elseif args[1] == "target" and args[3] then
                    local currentQueue = StagePresets[targetStage]
                    if currentQueue and #currentQueue > 0 then
                        currentQueue[#currentQueue].setTarget = tostring(args[3])
                        savePresetsToFile()
                        print(string.format("[Recorder] บันทึก Target ลำดับที่ %d: %s ในด่าน '%s'", #currentQueue, tostring(args[3]), targetStage))
                    end
                end
            end
            if setnamecallmethod then
                setnamecallmethod(method)
            end
            return oldNamecall(self, ...)
        end)
    end
end
pcall(hookPlacementRecorder)

-- ========================================================
-- โหลดและใช้งาน BEHINDTHEDARKLIB
-- ========================================================
local libUrl = "https://raw.githubusercontent.com/PKNUDG/BehindTheDarkLib/main/BehindTheDarkLib.luau?v=" .. os.time()
local libRaw = game:HttpGet(libUrl)
local libChunk, libErr = loadstring(libRaw)
if not libChunk then
    error("[BehindTheDark] โหลด Library ไม่สำเร็จ: " .. tostring(libErr))
end
local Library = libChunk()

local Window = Library:CreateWindow({
    Title = "BEHIND THE DARK",
    Name = "CandyTD_BehindTheDarkHub",
    OnUnload = function()
        Controller.Running = false
        pcall(function()
            local cam = workspace.CurrentCamera
            if cam then
                cam.CameraType = Enum.CameraType.Custom
            end
        end)
        _G.CandyTD_InMatchInstance = nil
    end
})
Controller.Gui = Window.Gui

local visualUpdaters = {}

local function updateEndChoiceVisuals()
    if visualUpdaters["NEXT"] then visualUpdaters["NEXT"](states.EndChoice == "NEXT") end
    if visualUpdaters["AGAIN"] then visualUpdaters["AGAIN"](states.EndChoice == "AGAIN") end
    if visualUpdaters["HOME"] then visualUpdaters["HOME"](states.EndChoice == "HOME") end
end

local function setEndChoice(choice: string)
    states.EndChoice = (states.EndChoice == choice) and "NONE" or choice
    updateEndChoiceVisuals()
end

visualUpdaters["NEXT"] = Window:CreateToggle("Left", "Auto Next", 0, { On = Color3.fromRGB(235, 65, 135), Off = Color3.fromRGB(120, 120, 130) }, false, function() setEndChoice("NEXT") end)
visualUpdaters["AGAIN"] = Window:CreateToggle("Left", "Auto Again", 46, { On = Color3.fromRGB(240, 150, 40), Off = Color3.fromRGB(120, 120, 130) }, true, function() setEndChoice("AGAIN") end)
visualUpdaters["HOME"] = Window:CreateToggle("Left", "Auto Home", 92, { On = Color3.fromRGB(60, 180, 245), Off = Color3.fromRGB(120, 120, 130) }, false, function() setEndChoice("HOME") end)
updateEndChoiceVisuals()

local againLimitUpdater = nil
againLimitUpdater = Window:CreateToggle("Left", "Again Count Limit", 144, { On = Color3.fromRGB(255, 140, 40), Off = Color3.fromRGB(120, 120, 130) }, false, function(v)
    states.AgainBeforeHomeActive = v
end)

-- Target Rounds 3D
local leftCol = Window:GetColumn("Left")

local configBoxShadow = Instance.new("Frame")
configBoxShadow.Size = UDim2.new(1, 0, 0, 44)
configBoxShadow.Position = UDim2.fromOffset(0, 190)
configBoxShadow.BackgroundColor3 = Color3.fromRGB(16, 3, 26)
configBoxShadow.BorderSizePixel = 0
configBoxShadow.ZIndex = 4
configBoxShadow.Parent = leftCol
Instance.new("UICorner", configBoxShadow).CornerRadius = UDim.new(0, 14)

local configBox = Instance.new("Frame")
configBox.Size = UDim2.new(1, 0, 0, 41)
configBox.Position = UDim2.fromOffset(0, 0)
configBox.BackgroundColor3 = Color3.fromRGB(65, 22, 105)
configBox.BorderSizePixel = 0
configBox.ZIndex = 5
configBox.Parent = configBoxShadow
Instance.new("UICorner", configBox).CornerRadius = UDim.new(0, 14)
local cbs = Instance.new("UIStroke", configBox)
cbs.Thickness = 2.5
cbs.Color = Color3.fromRGB(22, 5, 36)

local cfgLabel = Instance.new("TextLabel")
cfgLabel.Size = UDim2.new(1, -115, 1, 0)
cfgLabel.Position = UDim2.fromOffset(12, 0)
cfgLabel.BackgroundTransparency = 1
cfgLabel.Text = "Target Rounds"
cfgLabel.TextColor3 = Color3.fromRGB(255, 225, 95)
cfgLabel.TextSize = 13.5
cfgLabel.Font = Enum.Font.FredokaOne
cfgLabel.TextXAlignment = Enum.TextXAlignment.Left
cfgLabel.ZIndex = 6
cfgLabel.Parent = configBox
local cgls = Instance.new("UIStroke", cfgLabel)
cgls.Thickness = 2.5
cgls.Color = Color3.fromRGB(22, 5, 36)

local roundCountBadge = Instance.new("Frame")
roundCountBadge.Size = UDim2.fromOffset(30, 28)
roundCountBadge.Position = UDim2.new(1, -66, 0.5, -14)
roundCountBadge.BackgroundColor3 = Color3.fromRGB(36, 10, 58)
roundCountBadge.BorderSizePixel = 0
roundCountBadge.ZIndex = 6
roundCountBadge.Parent = configBox
Instance.new("UICorner", roundCountBadge).CornerRadius = UDim.new(0, 8)
local rcbs = Instance.new("UIStroke", roundCountBadge)
rcbs.Thickness = 2
rcbs.Color = Color3.fromRGB(22, 5, 36)

local roundCountLabel = Instance.new("TextLabel")
roundCountLabel.Size = UDim2.fromScale(1, 1)
roundCountLabel.BackgroundTransparency = 1
roundCountLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
roundCountLabel.TextSize = 14
roundCountLabel.Font = Enum.Font.FredokaOne
roundCountLabel.Text = tostring(states.TargetRounds)
roundCountLabel.ZIndex = 7
roundCountLabel.Parent = roundCountBadge

local roundStatusShadow = Instance.new("Frame")
roundStatusShadow.Size = UDim2.new(1, 0, 0, 54)
roundStatusShadow.Position = UDim2.fromOffset(0, 244)
roundStatusShadow.BackgroundColor3 = Color3.fromRGB(16, 3, 26)
roundStatusShadow.BorderSizePixel = 0
roundStatusShadow.ZIndex = 4
roundStatusShadow.Parent = leftCol
Instance.new("UICorner", roundStatusShadow).CornerRadius = UDim.new(0, 16)

local roundStatusBox = Instance.new("Frame")
roundStatusBox.Size = UDim2.new(1, 0, 0, 50)
roundStatusBox.Position = UDim2.fromOffset(0, 0)
roundStatusBox.BackgroundColor3 = Color3.fromRGB(42, 14, 68)
roundStatusBox.BorderSizePixel = 0
roundStatusBox.ZIndex = 5
roundStatusBox.Parent = roundStatusShadow
Instance.new("UICorner", roundStatusBox).CornerRadius = UDim.new(0, 16)
local rsbs = Instance.new("UIStroke", roundStatusBox)
rsbs.Thickness = 3
rsbs.Color = Color3.fromRGB(22, 5, 36)

local roundStatus = Instance.new("TextLabel")
roundStatus.Size = UDim2.fromScale(1, 1)
roundStatus.BackgroundTransparency = 1
roundStatus.Text = string.format("Round %d/%d", states.CurrentRounds, states.TargetRounds)
roundStatus.TextColor3 = Color3.fromRGB(255, 225, 95)
roundStatus.TextSize = 17
roundStatus.Font = Enum.Font.FredokaOne
roundStatus.ZIndex = 6
roundStatus.Parent = roundStatusBox
local rsts = Instance.new("UIStroke", roundStatus)
rsts.Thickness = 3
rsts.Color = Color3.fromRGB(22, 5, 36)

local function create3DActionButton(xPos: number, rimColor: Color3, btnColor: Color3)
    local shadow = Instance.new("Frame")
    shadow.Size = UDim2.fromOffset(26, 28)
    shadow.Position = UDim2.new(1, xPos, 0.5, -14)
    shadow.BackgroundColor3 = Color3.fromRGB(16, 3, 26)
    shadow.BorderSizePixel = 0
    shadow.ZIndex = 6
    shadow.Parent = configBox
    Instance.new("UICorner", shadow).CornerRadius = UDim.new(0, 8)

    local rim = Instance.new("Frame")
    rim.Size = UDim2.new(1, 0, 0, 25)
    rim.Position = UDim2.fromOffset(0, 0)
    rim.BackgroundColor3 = rimColor
    rim.BorderSizePixel = 0
    rim.ZIndex = 7
    rim.Parent = shadow
    Instance.new("UICorner", rim).CornerRadius = UDim.new(0, 8)
    local rs = Instance.new("UIStroke", rim)
    rs.Thickness = 2
    rs.Color = Color3.fromRGB(22, 5, 36)

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -4, 1, -4)
    btn.Position = UDim2.fromOffset(2, 2)
    btn.BackgroundColor3 = btnColor
    btn.Text = ""
    btn.BorderSizePixel = 0
    btn.AutoButtonColor = false
    btn.ZIndex = 8
    btn.Parent = rim
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

    local bts = Instance.new("UIStroke", btn)
    bts.Thickness = 2
    bts.Color = Color3.fromRGB(22, 5, 36)

    Library.AttachInteractiveEffects(btn, shadow)
    return btn
end

local btnMinus = create3DActionButton(-98, Color3.fromRGB(255, 140, 150), Color3.fromRGB(235, 65, 75))
btnMinus.Activated:Connect(function()
    if states.TargetRounds > 1 then
        states.TargetRounds = states.TargetRounds - 1
        roundCountLabel.Text = tostring(states.TargetRounds)
        roundStatus.Text = string.format("Round %d/%d", states.CurrentRounds, states.TargetRounds)
        Library.StepWiggle(roundStatus)
    end
end)

local btnPlus = create3DActionButton(-32, Color3.fromRGB(190, 255, 145), Color3.fromRGB(115, 225, 70))
btnPlus.Activated:Connect(function()
    states.TargetRounds = states.TargetRounds + 1
    roundCountLabel.Text = tostring(states.TargetRounds)
    roundStatus.Text = string.format("Round %d/%d", states.CurrentRounds, states.TargetRounds)
    Library.StepWiggle(roundStatus)
end)

-- ========================================================
-- ควบคุมฝั่งขวา (CONTROLS & STAGE SELECTION)
-- ========================================================
local rightCol = Window:GetColumn("Right")

Window:CreateToggle("Right", "Auto Upgrade All", 0, { On = Color3.fromRGB(90, 195, 60), Off = Color3.fromRGB(120, 120, 130) }, true, function(v)
    states.AutoUpgrade = v
end)

Window:CreateToggle("Right", "Auto Skip Wave", 46, { On = Color3.fromRGB(160, 75, 235), Off = Color3.fromRGB(120, 120, 130) }, true, function(v)
    states.AutoSkipWave = v
end)

Window:CreateToggle("Right", "Boost FPS", 92, { On = Color3.fromRGB(50, 205, 150), Off = Color3.fromRGB(120, 120, 130) }, false, function(v)
    states.BoostFPS = v
    applyUltraBoostFPS(v)
end)

Window:CreateToggle("Right", "Auto Place", 144, { On = Color3.fromRGB(255, 110, 80), Off = Color3.fromRGB(120, 120, 130) }, false, function(v)
    states.AutoPlace = v
end)

local stageDropdown = Window:CreateDropdown("Right", "Stage", 190, getStageNames(), states.CurrentStage, 10, function(selected)
    states.CurrentStage = selected
    states.RecordStageName = selected
end)

-- ========================================================
-- หน้าต่างใหม่ RECORD MODE (SUB-PAGE MODAL)
-- ========================================================
local RecordPage = Window:CreateSubPage({
    Title = "RECORD & PRESET SETUP",
    Size = UDim2.fromOffset(480, 310)
})

-- 1. ช่องกรอกชื่อด่าน (TextBox ไม่ทับด่านเดิม)
local nameBoxShadow = Instance.new("Frame")
nameBoxShadow.Size = UDim2.new(1, 0, 0, 42)
nameBoxShadow.Position = UDim2.fromOffset(0, 0)
nameBoxShadow.BackgroundColor3 = Color3.fromRGB(16, 3, 26)
nameBoxShadow.BorderSizePixel = 0
nameBoxShadow.ZIndex = 84
nameBoxShadow.Parent = RecordPage.Content
Instance.new("UICorner", nameBoxShadow).CornerRadius = UDim.new(0, 12)

local nameBoxRim = Instance.new("Frame")
nameBoxRim.Size = UDim2.new(1, 0, 0, 39)
nameBoxRim.Position = UDim2.fromOffset(0, 0)
nameBoxRim.BackgroundColor3 = Color3.fromRGB(115, 95, 175)
nameBoxRim.BorderSizePixel = 0
nameBoxRim.ZIndex = 85
nameBoxRim.Parent = nameBoxShadow
Instance.new("UICorner", nameBoxRim).CornerRadius = UDim.new(0, 12)
local nbs = Instance.new("UIStroke", nameBoxRim)
nbs.Thickness = 2.5
nbs.Color = Color3.fromRGB(22, 5, 36)

local stageInput = Instance.new("TextBox")
stageInput.Size = UDim2.new(1, -8, 1, -6)
stageInput.Position = UDim2.fromOffset(4, 3)
stageInput.BackgroundColor3 = Color3.fromRGB(36, 12, 58)
stageInput.BorderSizePixel = 0
stageInput.Text = states.RecordStageName
stageInput.PlaceholderText = "Type new stage name here..."
stageInput.PlaceholderColor3 = Color3.fromRGB(160, 145, 185)
stageInput.TextColor3 = Color3.fromRGB(255, 235, 110)
stageInput.TextSize = 13.5
stageInput.Font = Enum.Font.FredokaOne
stageInput.ClearTextOnFocus = false
stageInput.ZIndex = 86
stageInput.Parent = nameBoxRim
Instance.new("UICorner", stageInput).CornerRadius = UDim.new(0, 10)

-- 2. แถบแสดงสถานะยูนิตที่บันทึก
local recordStatusLabel = Instance.new("TextLabel")
recordStatusLabel.Size = UDim2.new(1, 0, 0, 34)
recordStatusLabel.Position = UDim2.fromOffset(0, 52)
recordStatusLabel.BackgroundColor3 = Color3.fromRGB(30, 8, 48)
recordStatusLabel.BorderSizePixel = 0
recordStatusLabel.Text = string.format("Target: '%s' | Recorded: %d units", states.RecordStageName, #(StagePresets[states.RecordStageName] or {}))
recordStatusLabel.TextColor3 = Color3.fromRGB(242, 230, 255)
recordStatusLabel.TextSize = 13
recordStatusLabel.Font = Enum.Font.FredokaOne
recordStatusLabel.ZIndex = 84
recordStatusLabel.Parent = RecordPage.Content
Instance.new("UICorner", recordStatusLabel).CornerRadius = UDim.new(0, 10)
local rsls = Instance.new("UIStroke", recordStatusLabel)
rsls.Thickness = 2
rsls.Color = Color3.fromRGB(22, 5, 36)

onUnitRecorded = function()
    local tName = (stageInput.Text ~= "") and stageInput.Text or states.RecordStageName
    local count = #(StagePresets[tName] or {})
    recordStatusLabel.Text = string.format("Target: '%s' | Recorded: %d units", tName, count)
end

stageInput:GetPropertyChangedSignal("Text"):Connect(function()
    states.RecordStageName = stageInput.Text
    onUnitRecorded()
end)

-- 3. ปุ่มสลับ Record ON/OFF ในหน้า Sub-Page
local recordBtnShadow = Instance.new("Frame")
recordBtnShadow.Size = UDim2.new(1, 0, 0, 44)
recordBtnShadow.Position = UDim2.fromOffset(0, 96)
recordBtnShadow.BackgroundColor3 = Color3.fromRGB(16, 3, 26)
recordBtnShadow.BorderSizePixel = 0
recordBtnShadow.ZIndex = 84
recordBtnShadow.Parent = RecordPage.Content
Instance.new("UICorner", recordBtnShadow).CornerRadius = UDim.new(0, 14)

local recordBtnRim = Instance.new("Frame")
recordBtnRim.Size = UDim2.new(1, 0, 0, 41)
recordBtnRim.Position = UDim2.fromOffset(0, 0)
recordBtnRim.BackgroundColor3 = Color3.fromRGB(195, 150, 250)
recordBtnRim.BorderSizePixel = 0
recordBtnRim.ZIndex = 85
recordBtnRim.Parent = recordBtnShadow
Instance.new("UICorner", recordBtnRim).CornerRadius = UDim.new(0, 14)
local rbs = Instance.new("UIStroke", recordBtnRim)
rbs.Thickness = 3
rbs.Color = Color3.fromRGB(22, 5, 36)

local recordBtn = Instance.new("TextButton")
recordBtn.Size = UDim2.new(1, -6, 1, -5)
recordBtn.Position = UDim2.fromOffset(3, 2)
recordBtn.BackgroundColor3 = Color3.fromRGB(154, 102, 224)
recordBtn.BorderSizePixel = 0
recordBtn.AutoButtonColor = false
recordBtn.Text = "START RECORDING (OFF)"
recordBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
recordBtn.TextSize = 14
recordBtn.Font = Enum.Font.FredokaOne
recordBtn.ZIndex = 86
recordBtn.Parent = recordBtnRim
Instance.new("UICorner", recordBtn).CornerRadius = UDim.new(0, 11)
local rts = Instance.new("UIStroke", recordBtn)
rts.Thickness = 2.5
rts.Color = Color3.fromRGB(22, 5, 36)
Library.AttachInteractiveEffects(recordBtn, recordBtnShadow)

recordBtn.Activated:Connect(function()
    states.RecordMode = not states.RecordMode
    local cleanName = stageInput.Text:gsub("^%s*(.-)%s*$", "%1")
    if cleanName == "" then cleanName = "Custom Stage" end
    states.RecordStageName = cleanName
    stageInput.Text = cleanName

    Library.PlaySound("rbxassetid://9069609268")
    if states.RecordMode then
        StagePresets[cleanName] = StagePresets[cleanName] or {}
        recordBtn.BackgroundColor3 = Color3.fromRGB(235, 65, 75)
        recordBtn.Text = "RECORDING NOW... (CLICK TO STOP)"
        recordBtnRim.BackgroundColor3 = Color3.fromRGB(255, 140, 150)
    else
        recordBtn.BackgroundColor3 = Color3.fromRGB(154, 102, 224)
        recordBtn.Text = "START RECORDING (OFF)"
        recordBtnRim.BackgroundColor3 = Color3.fromRGB(195, 150, 250)
        savePresetsToFile()
        stageDropdown.SetOptions(getStageNames())
    end
    onUnitRecorded()
end)

-- 4. ปุ่มล้างข้อมูลเฉพาะด่านนี้ (Clear Stage Data)
local clearBtnShadow = Instance.new("Frame")
clearBtnShadow.Size = UDim2.new(1, 0, 0, 40)
clearBtnShadow.Position = UDim2.fromOffset(0, 150)
clearBtnShadow.BackgroundColor3 = Color3.fromRGB(16, 3, 26)
clearBtnShadow.BorderSizePixel = 0
clearBtnShadow.ZIndex = 84
clearBtnShadow.Parent = RecordPage.Content
Instance.new("UICorner", clearBtnShadow).CornerRadius = UDim.new(0, 12)

local clearBtn = Instance.new("TextButton")
clearBtn.Size = UDim2.new(1, 0, 1, -3)
clearBtn.Position = UDim2.fromOffset(0, 0)
clearBtn.BackgroundColor3 = Color3.fromRGB(190, 50, 60)
clearBtn.BorderSizePixel = 0
clearBtn.Text = "CLEAR CURRENT STAGE DATA"
clearBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
clearBtn.TextSize = 13
clearBtn.Font = Enum.Font.FredokaOne
clearBtn.ZIndex = 86
clearBtn.Parent = clearBtnShadow
Instance.new("UICorner", clearBtn).CornerRadius = UDim.new(0, 10)
local cs = Instance.new("UIStroke", clearBtn)
cs.Thickness = 2.5
cs.Color = Color3.fromRGB(22, 5, 36)
Library.AttachInteractiveEffects(clearBtn, clearBtnShadow)

clearBtn.Activated:Connect(function()
    local cleanName = stageInput.Text:gsub("^%s*(.-)%s*$", "%1")
    if cleanName ~= "" then
        StagePresets[cleanName] = {}
        savePresetsToFile()
        Library.PlaySound("rbxassetid://6895079853")
        onUnitRecorded()
    end
end)

-- ========================================================
-- ปุ่มบนหน้าหลักสำหรับเปิดหน้า RECORD MODE (3D Button)
-- ========================================================
local function createNavButton(text: string, yPos: number, rimColor: Color3, btnColor: Color3, callback: () -> ())
    local shadow = Instance.new("Frame")
    shadow.Size = UDim2.new(1, 0, 0, 42)
    shadow.Position = UDim2.fromOffset(0, yPos)
    shadow.BackgroundColor3 = Color3.fromRGB(16, 3, 26)
    shadow.BorderSizePixel = 0
    shadow.ZIndex = 14
    shadow.Parent = rightCol
    Instance.new("UICorner", shadow).CornerRadius = UDim.new(0, 14)

    local rim = Instance.new("Frame")
    rim.Size = UDim2.new(1, 0, 0, 39)
    rim.Position = UDim2.fromOffset(0, 0)
    rim.BackgroundColor3 = rimColor
    rim.BorderSizePixel = 0
    rim.ZIndex = 15
    rim.Parent = shadow
    Instance.new("UICorner", rim).CornerRadius = UDim.new(0, 14)
    local rs = Instance.new("UIStroke", rim)
    rs.Thickness = 2.5
    rs.Color = Color3.fromRGB(22, 5, 36)

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -6, 1, -5)
    btn.Position = UDim2.fromOffset(3, 2)
    btn.BackgroundColor3 = btnColor
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 13.5
    btn.Font = Enum.Font.FredokaOne
    btn.BorderSizePixel = 0
    btn.AutoButtonColor = false
    btn.ZIndex = 16
    btn.Parent = rim
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 11)
    local bts = Instance.new("UIStroke", btn)
    bts.Thickness = 2.5
    bts.Color = Color3.fromRGB(22, 5, 36)

    Library.AttachInteractiveEffects(btn, shadow)
    btn.Activated:Connect(callback)
end

-- 1. ปุ่มเปิดหน้า Record Mode Setup
createNavButton("Setup Record & Presets ⚙", 236, Color3.fromRGB(255, 145, 160), Color3.fromRGB(235, 65, 85), function()
    stageInput.Text = states.CurrentStage
    states.RecordStageName = states.CurrentStage
    onUnitRecorded()
    RecordPage.Open()
end)

-- 2. ปุ่ม Reload Presets
createNavButton("Reload Presets ↺", 282, Color3.fromRGB(255, 220, 110), Color3.fromRGB(240, 160, 45), function()
    loadPresetsFromFile()
    stageDropdown.SetOptions(getStageNames())
    Library.PlaySound("rbxassetid://6895079853")
    print(string.format("[PresetManager] โหลดค่าพรีเซ็ตจาก %s สำเร็จ!", PRESET_FILE))
end)

Window:Create3DRenderToggle("Right")

-- ========================================================
-- GAMEPLAY LOGIC LOOPS
-- ========================================================
local hasPlacedThisMatch = false
local function runAutoPlaceSequence()
    local matchRemotes = ReplicatedStorage:FindFirstChild("MatchRemotes")
    local actRemote = matchRemotes and matchRemotes:FindFirstChild("Act")
    if not (actRemote and actRemote:IsA("RemoteFunction")) then return end

    local currentQueue = StagePresets[states.CurrentStage]
    if not currentQueue or #currentQueue == 0 then
        print(string.format("[AutoPlace] ไม่พบรายการยูนิตในด่าน '%s' กรุณาเปิด Record Mode หรือแก้ไขใน %s", states.CurrentStage, PRESET_FILE))
        return
    end

    print(string.format("[AutoPlace] เริ่มวางยูนิต %d ตัวในด่าน: %s", #currentQueue, states.CurrentStage))
    for idx, item in ipairs(currentQueue) do
        local ok, result = pcall(function()
            return actRemote:InvokeServer("place", item.unit, item.x, item.z)
        end)
        local targetId = nil
        if ok then
            if type(result) == "table" and result.id then targetId = result.id
            elseif type(result) == "number" then targetId = result end
        end
        if ok and item.setTarget and targetId then
            task.wait(0.25)
            pcall(function() actRemote:InvokeServer("target", targetId, item.setTarget) end)
        end
        task.wait(0.35)
    end
    task.wait(0.5)
    print("[AutoPlace] วางยูนิตครบแล้ว สั่งเริ่มแมตช์...")
    pcall(function() actRemote:InvokeServer("start") end)
end

task.spawn(function()
    while Controller.Running do
        task.wait(0.5)
        if states.AutoPlace then
            local overlay = candyTD:FindFirstChild("Overlay")
            local isOverlayOpen = overlay and overlay.Visible
            local isPreMatch = false
            local startWaveBtn = candyTD:FindFirstChild("StartWave")
            if startWaveBtn and startWaveBtn.Visible then
                local txtLabel = startWaveBtn:FindFirstChildWhichIsA("TextLabel", true)
                local txt = (txtLabel and txtLabel.Text:upper()) or (startWaveBtn:IsA("TextButton") and startWaveBtn.Text:upper()) or ""
                if txt:find("START WAVE 1") or txt:find("WAVE 1") then isPreMatch = true end
            end
            if isPreMatch and not isOverlayOpen and not hasPlacedThisMatch then
                hasPlacedThisMatch = true
                runAutoPlaceSequence()
            elseif not isPreMatch then
                hasPlacedThisMatch = false
            end
        end
    end
end)

local function runEndMatchSequence(choice: string)
    task.spawn(function()
        local matchRemotes = ReplicatedStorage:FindFirstChild("MatchRemotes")
        if not matchRemotes then return end

        local actRemote = matchRemotes:FindFirstChild("Act")
        local replayRemote = matchRemotes:FindFirstChild("Replay")

        local hasNextButton = false
        pcall(function()
            for _, desc in ipairs(candyTD:GetDescendants()) do
                if desc:IsA("GuiButton") and desc.Visible then
                    local t = (desc:IsA("TextButton") and desc.Text:upper()) or ""
                    for _, l in ipairs(desc:GetDescendants()) do
                        if l:IsA("TextLabel") and l.Visible then t = t .. " " .. l.Text:upper() end
                    end
                    if t:find("NEXT") or desc.Name:upper():find("NEXT") then
                        hasNextButton = true
                        triggerInternalButton(desc)
                    end
                end
            end
        end)

        if hasNextButton or choice == "NEXT" then
            if actRemote and actRemote:IsA("RemoteFunction") then
                pcall(function() actRemote:InvokeServer("next") end)
            end
        end

        if choice == "AGAIN" and not hasNextButton then
            if replayRemote and replayRemote:IsA("RemoteFunction") then
                pcall(function() replayRemote:InvokeServer("info") end)
                task.wait(0.4)
                pcall(function() replayRemote:InvokeServer("pay") end)
            end

            if actRemote and actRemote:IsA("RemoteFunction") then
                pcall(function() actRemote:InvokeServer("again") end)
            end
        end

        task.wait(0.35)
        pcall(function()
            for _, desc in ipairs(candyTD:GetDescendants()) do
                if desc:IsA("GuiButton") and desc.Visible then
                    local t = (desc:IsA("TextButton") and desc.Text:upper()) or ""
                    for _, l in ipairs(desc:GetDescendants()) do
                        if l:IsA("TextLabel") and l.Visible then t = t .. " " .. l.Text:upper() end
                    end
                    if t:find("YES") or t:find("POUR") or t:find("REPLAY") or desc.Name:upper():find("YES") then
                        triggerInternalButton(desc)
                    end
                end
            end
        end)
    end)
end

local matchHandled = false
task.spawn(function()
    while Controller.Running do
        task.wait(0.35)
        local overlay = candyTD:FindFirstChild("Overlay")
        local isGameOver = overlay and overlay.Visible

        if not isGameOver then
            matchHandled = false
        else
            if not matchHandled and states.EndChoice ~= "NONE" then
                matchHandled = true
                task.wait(0.6)
                if states.EndChoice == "NEXT" or states.EndChoice == "AGAIN" then
                    if states.AgainBeforeHomeActive then
                        states.CurrentRounds = states.CurrentRounds + 1
                        roundCountLabel.Text = tostring(states.TargetRounds)
                        roundStatus.Text = string.format("Round %d/%d", states.CurrentRounds, states.TargetRounds)
                        if states.CurrentRounds >= states.TargetRounds then
                            states.CurrentRounds = 0
                            roundCountLabel.Text = tostring(states.TargetRounds)
                            roundStatus.Text = string.format("Round %d/%d", states.CurrentRounds, states.TargetRounds)
                            setEndChoice("HOME")
                            pcall(function()
                                local mRemotes = ReplicatedStorage:FindFirstChild("MatchRemotes")
                                local retRemote = mRemotes and mRemotes:FindFirstChild("ReturnToHub")
                                if retRemote then retRemote:FireServer() end
                            end)
                        else
                            runEndMatchSequence(states.EndChoice)
                        end
                    else
                        runEndMatchSequence(states.EndChoice)
                    end
                elseif states.EndChoice == "HOME" then
                    pcall(function()
                        local matchRemotes = ReplicatedStorage:FindFirstChild("MatchRemotes")
                        local retRemote = matchRemotes and matchRemotes:FindFirstChild("ReturnToHub")
                        if retRemote then retRemote:FireServer() end
                    end)
                end
            end
        end
    end
end)

task.spawn(function()
    while Controller.Running do
        task.wait(0.8)
        if states.AutoUpgrade then
            local overlay = candyTD:FindFirstChild("Overlay")
            local isOverlayOpen = overlay and overlay.Visible
            local isPreMatch = false
            local startWaveBtn = candyTD:FindFirstChild("StartWave")
            if startWaveBtn and startWaveBtn.Visible then
                local txtLabel = startWaveBtn:FindFirstChildWhichIsA("TextLabel", true)
                local txt = (txtLabel and txtLabel.Text:upper()) or (startWaveBtn:IsA("TextButton") and startWaveBtn.Text:upper()) or ""
                if txt:find("START WAVE 1") or (txt:find("WAVE 1") and not txt:find("WAVE 10") and not txt:find("WAVE 11") and not txt:find("WAVE 12")) then
                    isPreMatch = true
                end
            end
            if not isPreMatch and not isOverlayOpen then
                local matchRemotes = ReplicatedStorage:FindFirstChild("MatchRemotes")
                local actRemote = matchRemotes and matchRemotes:FindFirstChild("Act")
                if actRemote and actRemote:IsA("RemoteFunction") then
                    pcall(function() actRemote:InvokeServer("upgradeall") end)
                end
            end
        end
    end
end)

task.spawn(function()
    while Controller.Running do
        task.wait(0.3)
        if states.AutoSkipWave then
            local overlay = candyTD:FindFirstChild("Overlay")
            local isOverlayOpen = overlay and overlay.Visible
            if not isOverlayOpen then
                local skipBtn: GuiButton? = nil
                local isWaveOne = false
                local startWaveObj = candyTD:FindFirstChild("StartWave")
                if startWaveObj and startWaveObj.Visible then
                    local txtLabel = startWaveObj:FindFirstChildWhichIsA("TextLabel", true)
                    local txt = txtLabel and txtLabel.Text:upper() or ""
                    if txt:find("WAVE 1") and not txt:find("WAVE 10") and not txt:find("WAVE 11") and not txt:find("WAVE 12") then
                        isWaveOne = true
                    else
                        skipBtn = startWaveObj:IsA("GuiButton") and startWaveObj or startWaveObj:FindFirstChildWhichIsA("GuiButton", true)
                    end
                end
                if not skipBtn and not isWaveOne then
                    for _, desc in ipairs(candyTD:GetDescendants()) do
                        if desc:IsA("GuiButton") and desc.Visible then
                            local n = desc.Name:lower()
                            local t = (desc:IsA("TextButton") and desc.Text:lower()) or ""
                            for _, l in ipairs(desc:GetDescendants()) do
                                if l:IsA("TextLabel") then t = t .. " " .. l.Text:lower() end
                            end
                            if n:find("skip") or t:find("skip") or t:find("call wave") then
                                skipBtn = desc
                                break
                            end
                        end
                    end
                end
                if skipBtn and not isWaveOne then
                    triggerInternalButton(skipBtn)
                    requestMatchAction("skip")
                    requestMatchAction("startWave")
                    task.wait(0.5)
                end
            end
        end
    end
end)
