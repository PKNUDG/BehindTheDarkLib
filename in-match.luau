-- ========================================================
-- CANDY TD : IN-MATCH CONTROLLER (ORDER FIXED & AUTO PLACE)
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
local MarketplaceService = game:GetService("MarketplaceService")

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
    },
    -- 7 Main Stages (Candy TD Core Worlds)
    ["CANDY KINGDOM"] = {},
    ["ICE KINGDOM"] = {},
    ["FIRE KINGDOM"] = {},
    ["MO FACTORY"] = {},
    ["CASTLE LEMONGRAB"] = {},
    ["NIGHTOSPHERE"] = {},
    ["CRYSTAL DIMENSION"] = {}
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

local libUrl = "https://raw.githubusercontent.com/PKNUDG/BehindTheDarkLib/main/BehindTheDarkLib.luau?v=" .. os.time()
local libRaw = game:HttpGet(libUrl)
local libChunk, libErr = loadstring(libRaw)
if not libChunk then
    error("[BehindTheDark] โหลด Library ไม่สำเร็จ: " .. tostring(libErr))
end
local Library = libChunk()

local savedCfg = Library.Settings.Configs or {}

local states = {
    EndChoice = savedCfg.EndChoice or "AGAIN",
    AutoUpgrade = (savedCfg.AutoUpgrade ~= nil) and savedCfg.AutoUpgrade or true,
    AgainBeforeHomeActive = (savedCfg.AgainBeforeHomeActive ~= nil) and savedCfg.AgainBeforeHomeActive or false,
    AutoSkipWave = (savedCfg.AutoSkipWave ~= nil) and savedCfg.AutoSkipWave or true,
    BoostFPS = (savedCfg.BoostFPS ~= nil) and savedCfg.BoostFPS or false,
    AutoPlace = false, -- เริ่มต้นเป็น OFF เสมอ เพื่อป้องกันการวางยูนิตมั่วก่อนตรวจเจอด่านจริง
    RecordMode = false,
    CurrentStage = savedCfg.CurrentStage or Library.Settings.SelectedStage or "Inf Bug Milk",
    RecordStageName = savedCfg.CurrentStage or Library.Settings.SelectedStage or "Inf Bug Milk",
    TargetRounds = savedCfg.TargetRounds or 10,
    CurrentRounds = 0
}

local function saveConfigState()
    Library.Settings.Configs = {
        EndChoice = states.EndChoice,
        AutoUpgrade = states.AutoUpgrade,
        AgainBeforeHomeActive = states.AgainBeforeHomeActive,
        AutoSkipWave = states.AutoSkipWave,
        BoostFPS = states.BoostFPS,
        AutoPlace = states.AutoPlace,
        TargetRounds = states.TargetRounds,
        CurrentStage = states.CurrentStage
    }
    Library.Settings.SelectedStage = states.CurrentStage
    Library.SaveSettings()
end

local currentPlaceId = tostring(game.PlaceId)
while not currentPlaceId or currentPlaceId == "0" do
    task.wait(0.2)
    currentPlaceId = tostring(game.PlaceId)
end

local currentMapName = "Custom Match"
pcall(function()
    local info = MarketplaceService:GetProductInfo(game.PlaceId)
    if info and info.Name then
        currentMapName = info.Name
    end
end)

local function findMatchingPresetName(query: string?): string?
    if not query or query == "" then return nil end
    local cleanQuery = query:lower():gsub("[%p%s]", "")

    -- ตรวจสอบชื่อตรงตัวกับ StagePresets
    for presetName, _ in pairs(StagePresets) do
        local cleanPreset = presetName:lower():gsub("[%p%s]", "")
        if cleanPreset == cleanQuery or cleanPreset:find(cleanQuery, 1, true) or cleanQuery:find(cleanPreset, 1, true) then
            return presetName
        end
    end

    -- จับคู่ Act, World, หรือ Keyword พิเศษ เข้าสู่ 7 Main Stages
    local stageKeywords = {
        -- ICE KINGDOM
        ["ice"] = "ICE KINGDOM",
        ["frost"] = "ICE KINGDOM",
        ["penguin"] = "ICE KINGDOM",
        ["fudge"] = "ICE KINGDOM",
        ["goliad"] = "ICE KINGDOM",
        ["snow"] = "ICE KINGDOM",

        -- CANDY KINGDOM
        ["candy"] = "CANDY KINGDOM",
        ["gumdrop"] = "CANDY KINGDOM",
        ["peppermint"] = "CANDY KINGDOM",
        ["parade"] = "CANDY KINGDOM",
        ["gauntlet"] = "CANDY KINGDOM",
        ["gumball"] = "CANDY KINGDOM",

        -- FIRE KINGDOM
        ["fire"] = "FIRE KINGDOM",
        ["flame"] = "FIRE KINGDOM",
        ["lava"] = "FIRE KINGDOM",
        ["inferno"] = "FIRE KINGDOM",

        -- MO FACTORY
        ["mo factory"] = "MO FACTORY",
        ["factory"] = "MO FACTORY",
        ["bmo"] = "MO FACTORY",
        ["robot"] = "MO FACTORY",

        -- CASTLE LEMONGRAB
        ["lemongrab"] = "CASTLE LEMONGRAB",
        ["lemon"] = "CASTLE LEMONGRAB",
        ["castle lemon"] = "CASTLE LEMONGRAB",

        -- NIGHTOSPHERE
        ["nightosphere"] = "NIGHTOSPHERE",
        ["demon"] = "NIGHTOSPHERE",
        ["hunson"] = "NIGHTOSPHERE",

        -- CRYSTAL DIMENSION
        ["crystal"] = "CRYSTAL DIMENSION",
        ["dimension"] = "CRYSTAL DIMENSION",

        -- Special Raids / Events
        ["halloween"] = "Raid Halloween",
        ["bug milk"] = "Inf Bug Milk"
    }

    local lowerQuery = query:lower()
    for kw, targetName in pairs(stageKeywords) do
        if lowerQuery:find(kw, 1, true) and StagePresets[targetName] then
            return targetName
        end
    end
    return nil
end

-- ฟังก์ชันอัปเดตสเตจและ UI อัตโนมัติเมื่อตรวจพบด่าน
local stageDropdown: any = nil
local autoPlaceToggleUpdater: any = nil

local function applyDetectedStage(targetStage: string, sourceDesc: string)
    if not targetStage or not StagePresets[targetStage] then return end
    if states.CurrentStage == targetStage and states.RecordStageName == targetStage then
        return
    end

    print(string.format("[AutoStage] >> สลับไปยังด่าน: '%s' (ตรวจพบจาก: %s)", targetStage, sourceDesc))
    states.CurrentStage = targetStage
    states.RecordStageName = targetStage
    Library.Settings.SelectedStage = targetStage
    Library.Settings.Configs = Library.Settings.Configs or {}
    Library.Settings.Configs.CurrentStage = targetStage

    -- บันทึกแมปกับ PlaceId ไว้ด้วย
    Library.Settings.PlaceIdStageMap = Library.Settings.PlaceIdStageMap or {}
    Library.Settings.PlaceIdStageMap[currentPlaceId] = targetStage
    Library.SaveSettings()

    -- อัปเดต UI Dropdown
    if stageDropdown and stageDropdown.Set then
        stageDropdown.Set(targetStage)
    end

    -- หากมี Preset ยูนิตในด่านนี้อยู่แล้ว และยังไม่ได้เปิด Auto Place ให้เปิดอัตโนมัติ
    local presetUnits = StagePresets[targetStage]
    if presetUnits and #presetUnits > 0 then
        if not states.AutoPlace then
            states.AutoPlace = true
            if autoPlaceToggleUpdater then
                autoPlaceToggleUpdater(true)
            end
            print(string.format("[AutoStage] พรีเซ็ตด่าน '%s' มีข้อมูลยูนิต %d ตัว -> เปิด Auto Place อัตโนมัติ", targetStage, #presetUnits))
        end
    else
        print(string.format("[AutoStage] ด่าน '%s' ยังเป็นพรีเซ็ตว่าง (พร้อมสำหรับการ Record)", targetStage))
    end
end

-- ตรวจสอบรอบแรกทันที
local initCandidate = _G.CandyTD_SelectedStage or Library.Settings.SelectedStage
local initMatched = findMatchingPresetName(initCandidate)
if initMatched then
    states.CurrentStage = initMatched
    states.RecordStageName = initMatched
    local pUnits = StagePresets[initMatched]
    if pUnits and #pUnits > 0 then
        states.AutoPlace = true
    end
end

-- ลูปสแกนตรวจจับด่านแบบต่อเนื่อง (Continuous Scanner)
task.spawn(function()
    local detected = false
    while Controller.Running and not detected do
        task.wait(0.75)

        -- 1. ตรวจสอบค่าจาก Genv / Library.Settings
        local fromLobby = _G.CandyTD_SelectedStage or Library.Settings.SelectedStage
        local m1 = findMatchingPresetName(fromLobby)
        if m1 then
            applyDetectedStage(m1, "Lobby Handshake")
            detected = true
            break
        end

        -- 2. ตรวจสอบ ReplicatedStorage / MatchRemotes / CandyTD
        local matchFolder = ReplicatedStorage:FindFirstChild("CandyTD") or ReplicatedStorage:FindFirstChild("Match")
        if matchFolder then
            for _, child in ipairs(matchFolder:GetDescendants()) do
                if child:IsA("StringValue") and child.Value ~= "" then
                    local m = findMatchingPresetName(child.Value)
                    if m then
                        applyDetectedStage(m, "ReplicatedStorage." .. child.Name)
                        detected = true
                        break
                    end
                end
            end
        end
        if detected then break end

        -- 3. ตรวจสอบข้อความบน UI (PlayerGui ทั้งหมด รวมถึง CandyTD HUD)
        for _, gui in ipairs(playerGui:GetChildren()) do
            if gui:IsA("ScreenGui") and gui.Enabled then
                for _, desc in ipairs(gui:GetDescendants()) do
                    if desc:IsA("TextLabel") and desc.Visible and desc.Text ~= "" and desc.TextSize >= 12 then
                        local m = findMatchingPresetName(desc.Text)
                        if m then
                            applyDetectedStage(m, "UI (" .. desc.Name .. ": " .. desc.Text .. ")")
                            detected = true
                            break
                        end
                    end
                end
                if detected then break end
            end
        end
        if detected then break end

        -- 4. ตรวจสอบจาก Workspace Models / Map
        local mapFolder = workspace:FindFirstChild("Map") or workspace:FindFirstChild("Stage") or workspace:FindFirstChild("Arena")
        if mapFolder then
            local m = findMatchingPresetName(mapFolder.Name)
            if m then
                applyDetectedStage(m, "Workspace.Map (" .. mapFolder.Name .. ")")
                detected = true
                break
            else
                for _, ch in ipairs(mapFolder:GetChildren()) do
                    local chM = findMatchingPresetName(ch.Name)
                    if chM then
                        applyDetectedStage(chM, "Workspace.Map." .. ch.Name)
                        detected = true
                        break
                    end
                end
            end
        end
        if detected then break end
    end
end)

local refreshRecordUI: (() -> ())? = nil
local lastRecordTick = 0

local function handleRecordInput(...)
    if not states.RecordMode then return end
    local rawArgs = { ... }
    if #rawArgs == 0 then return end

    local isPlace = false
    local isTarget = false
    local unitName = nil
    local posX, posZ = nil, nil
    local targetMode = nil

    for _, arg in ipairs(rawArgs) do
        local str = tostring(arg):lower()
        if str == "place" then
            isPlace = true
        elseif str == "target" then
            isTarget = true
        elseif typeof(arg) == "Vector3" then
            posX, posZ = arg.X, arg.Z
        elseif typeof(arg) == "CFrame" then
            posX, posZ = arg.Position.X, arg.Position.Z
        elseif type(arg) == "table" then
            if arg.unit or arg.name or arg.Name or arg.Unit then
                unitName = tostring(arg.unit or arg.name or arg.Name or arg.Unit)
            end
            if arg.x or arg.X then posX = tonumber(arg.x or arg.X) end
            if arg.z or arg.Z then posZ = tonumber(arg.z or arg.Z) end
            if tostring(arg.action or arg.Action):lower() == "place" then isPlace = true end
            if tostring(arg.action or arg.Action):lower() == "target" then isTarget = true end
        end
    end

    if not isPlace and not isTarget then
        if type(rawArgs[1]) == "string" and rawArgs[1]:lower() == "place" then
            isPlace = true
            unitName = tostring(rawArgs[2])
            posX = tonumber(rawArgs[3])
            posZ = tonumber(rawArgs[4])
        elseif type(rawArgs[1]) == "string" and rawArgs[1]:lower() == "target" then
            isTarget = true
            targetMode = tostring(rawArgs[3] or rawArgs[2])
        end
    end

    if isPlace then
        if not unitName then
            for _, arg in ipairs(rawArgs) do
                if type(arg) == "string" and arg:lower() ~= "place" and not tonumber(arg) then
                    unitName = arg
                    break
                end
            end
        end

        if not posX or not posZ then
            local nums = {}
            for _, arg in ipairs(rawArgs) do
                if type(arg) == "number" then
                    table.insert(nums, arg)
                end
            end
            if #nums >= 2 then
                posX, posZ = nums[1], nums[2]
            end
        end

        if unitName and posX and posZ then
            local targetStage = (states.RecordStageName and states.RecordStageName ~= "") and states.RecordStageName or states.CurrentStage
            StagePresets[targetStage] = StagePresets[targetStage] or {}
            local currentQueue = StagePresets[targetStage]

            if tick() - lastRecordTick < 0.15 then
                local last = currentQueue[#currentQueue]
                if last and last.unit == unitName and math.abs((last.x or 0) - posX) < 0.05 and math.abs((last.z or 0) - posZ) < 0.05 then
                    return
                end
            end
            lastRecordTick = tick()

            table.insert(currentQueue, {
                unit = unitName,
                x = posX,
                z = posZ
            })

            task.spawn(function()
                savePresetsToFile()
                if refreshRecordUI then refreshRecordUI() end
            end)
            print(string.format("[Recorder] บันทึกสำเร็จ: #%d %s (X: %.1f, Z: %.1f) ในด่าน '%s'", #currentQueue, unitName, posX, posZ, targetStage))
        end

    elseif isTarget then
        for _, arg in ipairs(rawArgs) do
            if type(arg) == "string" and arg:lower() ~= "target" then
                targetMode = arg
            end
        end
        if targetMode then
            local targetStage = (states.RecordStageName and states.RecordStageName ~= "") and states.RecordStageName or states.CurrentStage
            local currentQueue = StagePresets[targetStage]
            if currentQueue and #currentQueue > 0 then
                currentQueue[#currentQueue].setTarget = targetMode
                task.spawn(function()
                    savePresetsToFile()
                    if refreshRecordUI then refreshRecordUI() end
                end)
                print(string.format("[Recorder] บันทึก Target สำเร็จ: #%d %s -> %s", #currentQueue, currentQueue[#currentQueue].unit, targetMode))
            end
        end
    end
end

_G.CandyTD_ActiveRecordHandler = handleRecordInput

local function installPlacementHook()
    if matchNet and type(matchNet.request) == "function" then
        local oldReq = matchNet.request
        matchNet.request = function(...)
            local args = { ... }
            task.spawn(function()
                if _G.CandyTD_ActiveRecordHandler then
                    _G.CandyTD_ActiveRecordHandler(unpack(args))
                end
            end)
            return oldReq(...)
        end
    end

    local matchRemotes = ReplicatedStorage:FindFirstChild("MatchRemotes")
    local actRemote = matchRemotes and matchRemotes:FindFirstChild("Act")
    if actRemote and typeof(hookfunction) == "function" then
        local oldInvoke
        oldInvoke = hookfunction(actRemote.InvokeServer, function(self, ...)
            local args = { ... }
            task.spawn(function()
                if _G.CandyTD_ActiveRecordHandler then
                    _G.CandyTD_ActiveRecordHandler(unpack(args))
                end
            end)
            return oldInvoke(self, ...)
        end)
    end
end
pcall(installPlacementHook)

-- ========================================================
-- WINDOW & UI LAYOUT
-- ========================================================
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

if Window.RightColumn and Window.RightColumn.Parent and Window.RightColumn.Parent.Parent then
    Window.RightColumn.Parent.Parent.Visible = false
end

-- ฝั่งซ้าย
local visualUpdaters = {}
local function updateEndChoiceVisuals()
    if visualUpdaters["NEXT"] then visualUpdaters["NEXT"](states.EndChoice == "NEXT") end
    if visualUpdaters["AGAIN"] then visualUpdaters["AGAIN"](states.EndChoice == "AGAIN") end
    if visualUpdaters["HOME"] then visualUpdaters["HOME"](states.EndChoice == "HOME") end
end

local function setEndChoice(choice: string)
    states.EndChoice = (states.EndChoice == choice) and "NONE" or choice
    updateEndChoiceVisuals()
    saveConfigState()
end

visualUpdaters["NEXT"] = Window:CreateToggle("Left", "Auto Next", 0, { On = Color3.fromRGB(235, 65, 135), Off = Color3.fromRGB(120, 120, 130) }, states.EndChoice == "NEXT", function() setEndChoice("NEXT") end)
visualUpdaters["AGAIN"] = Window:CreateToggle("Left", "Auto Again", 46, { On = Color3.fromRGB(240, 150, 40), Off = Color3.fromRGB(120, 120, 130) }, states.EndChoice == "AGAIN", function() setEndChoice("AGAIN") end)
visualUpdaters["HOME"] = Window:CreateToggle("Left", "Auto Home", 92, { On = Color3.fromRGB(60, 180, 245), Off = Color3.fromRGB(120, 120, 130) }, states.EndChoice == "HOME", function() setEndChoice("HOME") end)
updateEndChoiceVisuals()

Window:CreateToggle("Left", "Again Count Limit", 144, { On = Color3.fromRGB(255, 140, 40), Off = Color3.fromRGB(120, 120, 130) }, states.AgainBeforeHomeActive, function(v)
    states.AgainBeforeHomeActive = v
    saveConfigState()
end)

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
local cbs = Instance.new("UIStroke")
cbs.Parent = configBox
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
local cgls = Instance.new("UIStroke")
cgls.Parent = cfgLabel
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
local rcbs = Instance.new("UIStroke")
rcbs.Parent = roundCountBadge
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
local rsbs = Instance.new("UIStroke")
rsbs.Parent = roundStatusBox
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
local rsts = Instance.new("UIStroke")
rsts.Parent = roundStatus
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
    local rs = Instance.new("UIStroke")
    rs.Parent = rim
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

    local bts = Instance.new("UIStroke")
    bts.Parent = btn
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
        saveConfigState()
    end
end)

local btnPlus = create3DActionButton(-32, Color3.fromRGB(190, 255, 145), Color3.fromRGB(115, 225, 70))
btnPlus.Activated:Connect(function()
    states.TargetRounds = states.TargetRounds + 1
    roundCountLabel.Text = tostring(states.TargetRounds)
    roundStatus.Text = string.format("Round %d/%d", states.CurrentRounds, states.TargetRounds)
    Library.StepWiggle(roundStatus)
    saveConfigState()
end)

-- ========================================================
-- ฝั่งขวา: สร้าง SUBTRAY ก่อน
-- ========================================================
local topSubTray = Window:CreateSubTray(UDim2.new(0.5, 6, 0, 0), UDim2.new(0.5, -20, 0, 154))
Window:CreateToggle(topSubTray, "Auto Upgrade All", 0, { On = Color3.fromRGB(90, 195, 60), Off = Color3.fromRGB(120, 120, 130) }, states.AutoUpgrade, function(v)
    states.AutoUpgrade = v
    saveConfigState()
end)

Window:CreateToggle(topSubTray, "Auto Skip Wave", 46, { On = Color3.fromRGB(160, 75, 235), Off = Color3.fromRGB(120, 120, 130) }, states.AutoSkipWave, function(v)
    states.AutoSkipWave = v
    saveConfigState()
end)

Window:CreateToggle(topSubTray, "Boost FPS", 92, { On = Color3.fromRGB(50, 205, 150), Off = Color3.fromRGB(120, 120, 130) }, states.BoostFPS, function(v)
    states.BoostFPS = v
    saveConfigState()
    applyUltraBoostFPS(v)
end)

local bottomSubTray = Window:CreateSubTray(UDim2.new(0.5, 6, 0, 162), UDim2.new(0.5, -20, 1, -174))

-- สร้าง Toggle Auto Place
autoPlaceToggleUpdater = Window:CreateToggle(bottomSubTray, "Auto Place", 0, { On = Color3.fromRGB(255, 110, 80), Off = Color3.fromRGB(120, 120, 130) }, states.AutoPlace, function(v)
    states.AutoPlace = v
    saveConfigState()
end)

if autoPlaceToggleUpdater then
    autoPlaceToggleUpdater(states.AutoPlace)
end

stageDropdown = Window:CreateDropdown(bottomSubTray, "Stage", 46, getStageNames(), states.CurrentStage, 10, function(selected)
    states.CurrentStage = selected
    states.RecordStageName = selected
    Library.Settings.SelectedStage = selected
    Library.Settings.PlaceIdStageMap = Library.Settings.PlaceIdStageMap or {}
    Library.Settings.PlaceIdStageMap[currentPlaceId] = selected
    Library.SaveSettings()
end)

local function createBottomActionButton(text: string, yPos: number, rimColor: Color3, btnColor: Color3, callback: () -> ())
    local shadow = Instance.new("Frame")
    shadow.Size = UDim2.new(1, 0, 0, 42)
    shadow.Position = UDim2.fromOffset(0, yPos)
    shadow.BackgroundColor3 = Color3.fromRGB(16, 3, 26)
    shadow.BorderSizePixel = 0
    shadow.ZIndex = 8
    shadow.Parent = bottomSubTray
    Instance.new("UICorner", shadow).CornerRadius = UDim.new(0, 14)

    local rim = Instance.new("Frame")
    rim.Size = UDim2.new(1, 0, 0, 39)
    rim.Position = UDim2.fromOffset(0, 0)
    rim.BackgroundColor3 = rimColor
    rim.BorderSizePixel = 0
    rim.ZIndex = 9
    rim.Parent = shadow
    Instance.new("UICorner", rim).CornerRadius = UDim.new(0, 14)
    local rs = Instance.new("UIStroke")
    rs.Parent = rim
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
    btn.ZIndex = 10
    btn.Parent = rim
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 11)
    local bts = Instance.new("UIStroke")
    bts.Parent = btn
    bts.Thickness = 2.5
    bts.Color = Color3.fromRGB(22, 5, 36)

    Library.AttachInteractiveEffects(btn, shadow)
    btn.Activated:Connect(callback)
end

-- ========================================================
-- RECORD PAGE
-- ========================================================
local RecordPage = Window:CreatePage("RecordView")

local recHeader = Instance.new("Frame")
recHeader.Size = UDim2.new(1, 0, 0, 36)
recHeader.Position = UDim2.fromOffset(0, 0)
recHeader.BackgroundTransparency = 1
recHeader.ZIndex = 6
recHeader.Parent = RecordPage.Container

local backBtnShadow = Instance.new("Frame")
backBtnShadow.Size = UDim2.fromOffset(95, 34)
backBtnShadow.Position = UDim2.fromOffset(0, 0)
backBtnShadow.BackgroundColor3 = Color3.fromRGB(16, 3, 26)
backBtnShadow.BorderSizePixel = 0
backBtnShadow.ZIndex = 6
backBtnShadow.Parent = recHeader
Instance.new("UICorner", backBtnShadow).CornerRadius = UDim.new(0, 10)

local backBtn = Instance.new("TextButton")
backBtn.Size = UDim2.new(1, 0, 1, -3)
backBtn.Position = UDim2.fromOffset(0, 0)
backBtn.BackgroundColor3 = Color3.fromRGB(235, 65, 75)
backBtn.Text = "BACK"
backBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
backBtn.TextSize = 13
backBtn.Font = Enum.Font.FredokaOne
backBtn.BorderSizePixel = 0
backBtn.AutoButtonColor = false
backBtn.ZIndex = 7
backBtn.Parent = backBtnShadow
Instance.new("UICorner", backBtn).CornerRadius = UDim.new(0, 9)
local bbs = Instance.new("UIStroke")
bbs.Parent = backBtn
bbs.Thickness = 2
bbs.Color = Color3.fromRGB(22, 5, 36)
Library.AttachInteractiveEffects(backBtn, backBtnShadow)

backBtn.Activated:Connect(function()
    RecordPage.Hide()
end)

local mapInfoBadge = Instance.new("Frame")
mapInfoBadge.Size = UDim2.new(1, -105, 1, 0)
mapInfoBadge.Position = UDim2.fromOffset(105, 0)
mapInfoBadge.BackgroundColor3 = Color3.fromRGB(48, 16, 76)
mapInfoBadge.BorderSizePixel = 0
mapInfoBadge.ZIndex = 6
mapInfoBadge.Parent = recHeader
Instance.new("UICorner", mapInfoBadge).CornerRadius = UDim.new(0, 10)
local mibs = Instance.new("UIStroke")
mibs.Parent = mapInfoBadge
mibs.Thickness = 2
mibs.Color = Color3.fromRGB(22, 5, 36)

local mapInfoLabel = Instance.new("TextLabel")
mapInfoLabel.Size = UDim2.fromScale(1, 1)
mapInfoLabel.BackgroundTransparency = 1
mapInfoLabel.Text = string.format("Map: %s  |  PlaceId: %s", currentMapName, currentPlaceId)
mapInfoLabel.TextColor3 = Color3.fromRGB(255, 225, 95)
mapInfoLabel.TextSize = 11.5
mapInfoLabel.Font = Enum.Font.FredokaOne
mapInfoLabel.ZIndex = 7
mapInfoLabel.Parent = mapInfoBadge

local inputShadow = Instance.new("Frame")
inputShadow.Size = UDim2.new(0.58, -6, 0, 38)
inputShadow.Position = UDim2.fromOffset(0, 44)
inputShadow.BackgroundColor3 = Color3.fromRGB(16, 3, 26)
inputShadow.BorderSizePixel = 0
inputShadow.ZIndex = 6
inputShadow.Parent = RecordPage.Container
Instance.new("UICorner", inputShadow).CornerRadius = UDim.new(0, 10)

local stageInput = Instance.new("TextBox")
stageInput.Size = UDim2.new(1, 0, 1, -3)
stageInput.Position = UDim2.fromOffset(0, 0)
stageInput.BackgroundColor3 = Color3.fromRGB(50, 18, 80)
stageInput.BorderSizePixel = 0
stageInput.Text = states.RecordStageName
stageInput.PlaceholderText = "Type custom stage name..."
stageInput.PlaceholderColor3 = Color3.fromRGB(170, 155, 195)
stageInput.TextColor3 = Color3.fromRGB(255, 235, 110)
stageInput.TextSize = 13
stageInput.Font = Enum.Font.FredokaOne
stageInput.ClearTextOnFocus = false
stageInput.ZIndex = 7
stageInput.Parent = inputShadow
Instance.new("UICorner", stageInput).CornerRadius = UDim.new(0, 9)
local sis = Instance.new("UIStroke")
sis.Parent = stageInput
sis.Thickness = 2
sis.Color = Color3.fromRGB(22, 5, 36)

local recToggleShadow = Instance.new("Frame")
recToggleShadow.Size = UDim2.new(0.42, 0, 0, 38)
recToggleShadow.Position = UDim2.new(0.58, 6, 0, 44)
recToggleShadow.BackgroundColor3 = Color3.fromRGB(16, 3, 26)
recToggleShadow.BorderSizePixel = 0
recToggleShadow.ZIndex = 6
recToggleShadow.Parent = RecordPage.Container
Instance.new("UICorner", recToggleShadow).CornerRadius = UDim.new(0, 10)

local recToggleBtn = Instance.new("TextButton")
recToggleBtn.Size = UDim2.new(1, 0, 1, -3)
recToggleBtn.Position = UDim2.fromOffset(0, 0)
recToggleBtn.BackgroundColor3 = Color3.fromRGB(154, 102, 224)
recToggleBtn.Text = "START RECORD"
recToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
recToggleBtn.TextSize = 12.5
recToggleBtn.Font = Enum.Font.FredokaOne
recToggleBtn.BorderSizePixel = 0
recToggleBtn.AutoButtonColor = false
recToggleBtn.ZIndex = 7
recToggleBtn.Parent = recToggleShadow
Instance.new("UICorner", recToggleBtn).CornerRadius = UDim.new(0, 9)
local rts2 = Instance.new("UIStroke")
rts2.Parent = recToggleBtn
rts2.Thickness = 2
rts2.Color = Color3.fromRGB(22, 5, 36)
Library.AttachInteractiveEffects(recToggleBtn, recToggleShadow)

local listShadow = Instance.new("Frame")
listShadow.Size = UDim2.new(1, 0, 1, -132)
listShadow.Position = UDim2.fromOffset(0, 88)
listShadow.BackgroundColor3 = Color3.fromRGB(16, 3, 26)
listShadow.BorderSizePixel = 0
listShadow.ZIndex = 6
listShadow.Parent = RecordPage.Container
Instance.new("UICorner", listShadow).CornerRadius = UDim.new(0, 12)

local unitScroll = Instance.new("ScrollingFrame")
unitScroll.Size = UDim2.new(1, 0, 1, -3)
unitScroll.Position = UDim2.fromOffset(0, 0)
unitScroll.BackgroundColor3 = Color3.fromRGB(30, 8, 48)
unitScroll.BorderSizePixel = 0
unitScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
unitScroll.ZIndex = 7
unitScroll.Parent = listShadow
Instance.new("UICorner", unitScroll).CornerRadius = UDim.new(0, 11)
local uss = Instance.new("UIStroke")
uss.Parent = unitScroll
uss.Thickness = 2
uss.Color = Color3.fromRGB(22, 5, 36)
Library.ApplyCartoonScrollbar(unitScroll)

local uListLayout = Instance.new("UIListLayout")
uListLayout.Parent = unitScroll
uListLayout.Padding = UDim.new(0, 4)
local uListPad = Instance.new("UIPadding")
uListPad.Parent = unitScroll
uListPad.PaddingTop = UDim.new(0, 6)
uListPad.PaddingLeft = UDim.new(0, 6)
uListPad.PaddingRight = UDim.new(0, 6)
uListPad.PaddingBottom = UDim.new(0, 6)

local function swapUnits(stageName: string, idx1: number, idx2: number)
    local q = StagePresets[stageName]
    if q and q[idx1] and q[idx2] then
        local temp = q[idx1]
        q[idx1] = q[idx2]
        q[idx2] = temp
        savePresetsToFile()
        Library.PlaySound("rbxassetid://6895079853")
        if refreshRecordUI then refreshRecordUI() end
    end
end

refreshRecordUI = function()
    local cName = stageInput.Text:gsub("^%s*(.-)%s*$", "%1")
    if cName == "" then cName = states.CurrentStage end

    for _, ch in ipairs(unitScroll:GetChildren()) do
        if ch:IsA("Frame") or ch:IsA("TextLabel") then ch:Destroy() end
    end

    local q = StagePresets[cName] or {}
    if #q == 0 then
        local emptyLbl = Instance.new("TextLabel")
        emptyLbl.Size = UDim2.new(1, 0, 0, 60)
        emptyLbl.BackgroundTransparency = 1
        emptyLbl.Text = string.format("No units recorded for '%s' yet.\nTurn ON Record Mode and place units in match!", cName)
        emptyLbl.TextColor3 = Color3.fromRGB(180, 170, 205)
        emptyLbl.TextSize = 13
        emptyLbl.Font = Enum.Font.FredokaOne
        emptyLbl.ZIndex = 8
        emptyLbl.Parent = unitScroll
    else
        for i, u in ipairs(q) do
            local card = Instance.new("Frame")
            card.Size = UDim2.new(1, -6, 0, 32)
            card.BackgroundColor3 = Color3.fromRGB(48, 16, 76)
            card.BorderSizePixel = 0
            card.ZIndex = 8
            card.Parent = unitScroll
            Instance.new("UICorner", card).CornerRadius = UDim.new(0, 8)
            local cs = Instance.new("UIStroke")
            cs.Parent = card
            cs.Thickness = 1.5
            cs.Color = Color3.fromRGB(22, 5, 36)

            local txt = Instance.new("TextLabel")
            txt.Size = UDim2.new(1, -68, 1, 0)
            txt.Position = UDim2.fromOffset(8, 0)
            txt.BackgroundTransparency = 1
            txt.Text = string.format("#%d  %s  |  (X: %.1f, Z: %.1f)  |  Target: %s", i, u.unit, u.x or 0, u.z or 0, u.setTarget or "first")
            txt.TextColor3 = Color3.fromRGB(255, 235, 120)
            txt.TextSize = 12
            txt.Font = Enum.Font.FredokaOne
            txt.TextXAlignment = Enum.TextXAlignment.Left
            txt.ZIndex = 9
            txt.Parent = card

            local btnUp = Instance.new("TextButton")
            btnUp.Size = UDim2.fromOffset(26, 24)
            btnUp.Position = UDim2.new(1, -58, 0.5, -12)
            btnUp.BackgroundColor3 = (i > 1) and Color3.fromRGB(80, 180, 245) or Color3.fromRGB(60, 45, 80)
            btnUp.Text = "UP"
            btnUp.TextColor3 = Color3.fromRGB(255, 255, 255)
            btnUp.TextSize = 11
            btnUp.Font = Enum.Font.FredokaOne
            btnUp.BorderSizePixel = 0
            btnUp.AutoButtonColor = false
            btnUp.ZIndex = 10
            btnUp.Parent = card
            Instance.new("UICorner", btnUp).CornerRadius = UDim.new(0, 6)
            if i > 1 then
                Library.AttachInteractiveEffects(btnUp)
                btnUp.Activated:Connect(function() swapUnits(cName, i, i - 1) end)
            end

            local btnDown = Instance.new("TextButton")
            btnDown.Size = UDim2.fromOffset(26, 24)
            btnDown.Position = UDim2.new(1, -28, 0.5, -12)
            btnDown.BackgroundColor3 = (i < #q) and Color3.fromRGB(240, 150, 40) or Color3.fromRGB(60, 45, 80)
            btnDown.Text = "DN"
            btnDown.TextColor3 = Color3.fromRGB(255, 255, 255)
            btnDown.TextSize = 11
            btnDown.Font = Enum.Font.FredokaOne
            btnDown.BorderSizePixel = 0
            btnDown.AutoButtonColor = false
            btnDown.ZIndex = 10
            btnDown.Parent = card
            Instance.new("UICorner", btnDown).CornerRadius = UDim.new(0, 6)
            if i < #q then
                Library.AttachInteractiveEffects(btnDown)
                btnDown.Activated:Connect(function() swapUnits(cName, i, i + 1) end)
            end
        end
    end
end

stageInput.FocusLost:Connect(function()
    local clean = stageInput.Text:gsub("^%s*(.-)%s*$", "%1")
    if clean ~= "" then
        states.RecordStageName = clean
        refreshRecordUI()
    end
end)

recToggleBtn.Activated:Connect(function()
    states.RecordMode = not states.RecordMode
    local clean = stageInput.Text:gsub("^%s*(.-)%s*$", "%1")
    if clean == "" then clean = states.CurrentStage end
    states.RecordStageName = clean
    stageInput.Text = clean

    Library.PlaySound("rbxassetid://9069609268")
    if states.RecordMode then
        if states.AutoPlace and autoPlaceToggleUpdater then autoPlaceToggleUpdater(false) end
        recToggleBtn.BackgroundColor3 = Color3.fromRGB(235, 65, 75)
        recToggleBtn.Text = "RECORDING (STOP)"
    else
        recToggleBtn.BackgroundColor3 = Color3.fromRGB(154, 102, 224)
        recToggleBtn.Text = "START RECORD"
        savePresetsToFile()
        states.CurrentStage = clean
        Library.Settings.SelectedStage = clean
        Library.Settings.PlaceIdStageMap = Library.Settings.PlaceIdStageMap or {}
        Library.Settings.PlaceIdStageMap[currentPlaceId] = clean
        Library.SaveSettings()
        stageDropdown.SetOptions(getStageNames())
    end
    refreshRecordUI()
end)

local bottomBar = Instance.new("Frame")
bottomBar.Size = UDim2.new(1, 0, 0, 36)
bottomBar.Position = UDim2.new(0, 0, 1, -36)
bottomBar.BackgroundTransparency = 1
bottomBar.ZIndex = 6
bottomBar.Parent = RecordPage.Container

-- ปุ่ม 1: UNDO LAST
local undoShadow = Instance.new("Frame")
undoShadow.Size = UDim2.new(0.31, -3, 1, 0)
undoShadow.Position = UDim2.fromOffset(0, 0)
undoShadow.BackgroundColor3 = Color3.fromRGB(16, 3, 26)
undoShadow.BorderSizePixel = 0
undoShadow.ZIndex = 6
undoShadow.Parent = bottomBar
Instance.new("UICorner", undoShadow).CornerRadius = UDim.new(0, 10)

local undoBtn = Instance.new("TextButton")
undoBtn.Size = UDim2.new(1, 0, 1, -3)
undoBtn.Position = UDim2.fromOffset(0, 0)
undoBtn.BackgroundColor3 = Color3.fromRGB(215, 115, 45)
undoBtn.Text = "UNDO"
undoBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
undoBtn.TextSize = 11.5
undoBtn.Font = Enum.Font.FredokaOne
undoBtn.BorderSizePixel = 0
undoBtn.AutoButtonColor = false
undoBtn.ZIndex = 7
undoBtn.Parent = undoShadow
Instance.new("UICorner", undoBtn).CornerRadius = UDim.new(0, 9)
local ubs = Instance.new("UIStroke")
ubs.Parent = undoBtn
ubs.Thickness = 2
ubs.Color = Color3.fromRGB(22, 5, 36)
Library.AttachInteractiveEffects(undoBtn, undoShadow)

undoBtn.Activated:Connect(function()
    local clean = stageInput.Text:gsub("^%s*(.-)%s*$", "%1")
    if clean ~= "" and StagePresets[clean] and #StagePresets[clean] > 0 then
        table.remove(StagePresets[clean], #StagePresets[clean])
        savePresetsToFile()
        Library.PlaySound("rbxassetid://6895079853")
        refreshRecordUI()
    end
end)

-- ปุ่ม 2: CLEAR ALL (ล้างยูนิตในด่านนี้)
local clearShadow = Instance.new("Frame")
clearShadow.Size = UDim2.new(0.34, -4, 1, 0)
clearShadow.Position = UDim2.new(0.31, 3, 0, 0)
clearShadow.BackgroundColor3 = Color3.fromRGB(16, 3, 26)
clearShadow.BorderSizePixel = 0
clearShadow.ZIndex = 6
clearShadow.Parent = bottomBar
Instance.new("UICorner", clearShadow).CornerRadius = UDim.new(0, 10)

local clearBtn = Instance.new("TextButton")
clearBtn.Size = UDim2.new(1, 0, 1, -3)
clearBtn.Position = UDim2.fromOffset(0, 0)
clearBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 60)
clearBtn.Text = "CLEAR ALL"
clearBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
clearBtn.TextSize = 11.5
clearBtn.Font = Enum.Font.FredokaOne
clearBtn.BorderSizePixel = 0
clearBtn.AutoButtonColor = false
clearBtn.ZIndex = 7
clearBtn.Parent = clearShadow
Instance.new("UICorner", clearBtn).CornerRadius = UDim.new(0, 9)
local cs = Instance.new("UIStroke")
cs.Parent = clearBtn
cs.Thickness = 2
cs.Color = Color3.fromRGB(22, 5, 36)
Library.AttachInteractiveEffects(clearBtn, clearShadow)

clearBtn.Activated:Connect(function()
    local clean = stageInput.Text:gsub("^%s*(.-)%s*$", "%1")
    if clean ~= "" then
        StagePresets[clean] = {}
        savePresetsToFile()
        Library.PlaySound("rbxassetid://6895079853")
        refreshRecordUI()
    end
end)

-- ปุ่ม 3: DELETE PRESET (ลบทั้งพรีเซ็ตด่านออกจากระบบ)
local delPresetShadow = Instance.new("Frame")
delPresetShadow.Size = UDim2.new(0.35, -3, 1, 0)
delPresetShadow.Position = UDim2.new(0.65, 3, 0, 0)
delPresetShadow.BackgroundColor3 = Color3.fromRGB(16, 3, 26)
delPresetShadow.BorderSizePixel = 0
delPresetShadow.ZIndex = 6
delPresetShadow.Parent = bottomBar
Instance.new("UICorner", delPresetShadow).CornerRadius = UDim.new(0, 10)

local delPresetBtn = Instance.new("TextButton")
delPresetBtn.Size = UDim2.new(1, 0, 1, -3)
delPresetBtn.Position = UDim2.fromOffset(0, 0)
delPresetBtn.BackgroundColor3 = Color3.fromRGB(135, 25, 45)
delPresetBtn.Text = "DELETE PRESET"
delPresetBtn.TextColor3 = Color3.fromRGB(255, 215, 225)
delPresetBtn.TextSize = 10.5
delPresetBtn.Font = Enum.Font.FredokaOne
delPresetBtn.BorderSizePixel = 0
delPresetBtn.AutoButtonColor = false
delPresetBtn.ZIndex = 7
delPresetBtn.Parent = delPresetShadow
Instance.new("UICorner", delPresetBtn).CornerRadius = UDim.new(0, 9)
local dps = Instance.new("UIStroke")
dps.Parent = delPresetBtn
dps.Thickness = 2
dps.Color = Color3.fromRGB(22, 5, 36)
Library.AttachInteractiveEffects(delPresetBtn, delPresetShadow)

delPresetBtn.Activated:Connect(function()
    local clean = stageInput.Text:gsub("^%s*(.-)%s*$", "%1")
    if clean ~= "" and StagePresets[clean] ~= nil then
        StagePresets[clean] = nil
        savePresetsToFile()
        Library.PlaySound("rbxassetid://6895079853")
        print(string.format("[PresetManager] ลบพรีเซ็ตด่าน '%s' ออกจากระบบเรียบร้อย", clean))

        local names = getStageNames()
        if stageDropdown and stageDropdown.SetOptions then
            stageDropdown.SetOptions(names)
        end

        local fallbackStage = names[1] or "CANDY KINGDOM"
        states.CurrentStage = fallbackStage
        states.RecordStageName = fallbackStage
        stageInput.Text = fallbackStage
        if stageDropdown and stageDropdown.Set then
            stageDropdown.Set(fallbackStage)
        end
        refreshRecordUI()
    end
end)

createBottomActionButton("Setup Record & Presets", 92, Color3.fromRGB(255, 145, 160), Color3.fromRGB(235, 65, 85), function()
    stageInput.Text = states.CurrentStage
    states.RecordStageName = states.CurrentStage
    refreshRecordUI()
    RecordPage.Show()
end)

createBottomActionButton("Reload Presets", 136, Color3.fromRGB(255, 220, 110), Color3.fromRGB(240, 160, 45), function()
    loadPresetsFromFile()
    stageDropdown.SetOptions(getStageNames())
    Library.PlaySound("rbxassetid://6895079853")
    print("[PresetManager] โหลดค่าพรีเซ็ตสำเร็จ!")
end)

-- ========================================================
-- GAMEPLAY LOGIC LOOPS (AUTO PLACE & UPGRADE & SKIP)
-- ========================================================
local hasPlacedThisMatch = false
local function runAutoPlaceSequence()
    local matchRemotes = ReplicatedStorage:FindFirstChild("MatchRemotes")
    local actRemote = matchRemotes and matchRemotes:FindFirstChild("Act")
    if not (actRemote and actRemote:IsA("RemoteFunction")) then return end

    local currentQueue = StagePresets[states.CurrentStage]
    if not currentQueue or #currentQueue == 0 then
        print(string.format("[AutoPlace] ไม่พบรายการยูนิตในด่าน '%s'", states.CurrentStage))
        return
    end

    print(string.format("[AutoPlace] เริ่มวางยูนิต %d ตัวในด่าน: %s", #currentQueue, states.CurrentStage))
    for _, item in ipairs(currentQueue) do
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

-- ========================================================
-- STABLE AUTO END-MATCH LOGIC (OVERLAY DETECTION + REMOTE)
-- ========================================================
local function checkIsMatchEnded()
    local overlay = candyTD:FindFirstChild("Overlay")
    if overlay and overlay.Visible then return true end

    for _, desc in ipairs(candyTD:GetDescendants()) do
        if desc:IsA("GuiObject") and desc.Visible then
            local n = desc.Name:lower()
            if n == "victory" or n == "defeat" or n == "gameover" or n == "rewards" or n == "endgame" then
                return true
            end
        end
    end
    return false
end

local matchHandled = false
task.spawn(function()
    while Controller.Running do
        task.wait(0.5)
        pcall(function()
            local isGameOver = checkIsMatchEnded()

            if not isGameOver then
                matchHandled = false
            else
                if not matchHandled and states.EndChoice ~= "NONE" then
                    matchHandled = true
                    task.wait(1.2)

                    local matchRemotes = ReplicatedStorage:FindFirstChild("MatchRemotes")
                    local actRemote = matchRemotes and matchRemotes:FindFirstChild("Act")

                    if states.EndChoice == "NEXT" then
                        if actRemote and actRemote:IsA("RemoteFunction") then
                            print("[AutoNext] สั่ง Remote: Act -> 'next'")
                            actRemote:InvokeServer("next")
                        end
                        for _, d in ipairs(candyTD:GetDescendants()) do
                            if d:IsA("GuiButton") and d.Visible and (d.Name:lower():find("next") or (d:IsA("TextButton") and d.Text:lower():find("next"))) then
                                triggerInternalButton(d)
                            end
                        end

                    elseif states.EndChoice == "AGAIN" then
                        if actRemote and actRemote:IsA("RemoteFunction") then
                            print("[AutoAgain] สั่ง Remote: Act -> 'again'")
                            actRemote:InvokeServer("again")
                        end

                    elseif states.EndChoice == "HOME" then
                        print("[AutoHome] ส่งคำสั่งกลับ HOME/ReturnToHub...")
                        local retRemote = matchRemotes and matchRemotes:FindFirstChild("ReturnToHub")
                        if retRemote then
                            if retRemote:IsA("RemoteEvent") then
                                retRemote:FireServer()
                            elseif retRemote:IsA("RemoteFunction") then
                                retRemote:InvokeServer()
                            end
                        end
                        for _, d in ipairs(candyTD:GetDescendants()) do
                            if d:IsA("GuiButton") and d.Visible then
                                local n = d.Name:lower()
                                local txt = (d:IsA("TextButton") and d.Text:lower()) or ""
                                if n:find("home") or n:find("lobby") or txt:find("home") or txt:find("lobby") then
                                    triggerInternalButton(d)
                                end
                            end
                        end
                    end
                end
            end
        end)
    end
end)

task.spawn(function()
    while Controller.Running do
        task.wait(0.8)
        if states.AutoUpgrade then
            local isPreMatch = false
            local startWaveBtn = candyTD:FindFirstChild("StartWave")
            if startWaveBtn and startWaveBtn.Visible then
                local txtLabel = startWaveBtn:FindFirstChildWhichIsA("TextLabel", true)
                local txt = (txtLabel and txtLabel.Text:upper()) or (startWaveBtn:IsA("TextButton") and startWaveBtn.Text:upper()) or ""
                if txt:find("START WAVE 1") or (txt:find("WAVE 1") and not txt:find("WAVE 10") and not txt:find("WAVE 11") and not txt:find("WAVE 12")) then
                    isPreMatch = true
                end
            end
            if not isPreMatch and not checkIsMatchEnded() then
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
            if not checkIsMatchEnded() then
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
