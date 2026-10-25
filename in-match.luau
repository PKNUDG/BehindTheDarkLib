-- ========================================================
-- CANDY TD : IN-MATCH CONTROLLER (POWERED BY BEHINDTHEDARKLIB)
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

-- ปิด Mute Banners
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
-- PRESETS & STATES
-- ========================================================
local StagePresets = {
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

local states = {
    EndChoice = "AGAIN",
    AutoUpgrade = true,
    AgainBeforeHomeActive = false,
    AutoSkipWave = true,
    BoostFPS = false,
    AutoPlace = false,
    CurrentStage = "Inf Bug Milk",
    TargetRounds = 10,
    CurrentRounds = 0
}

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
    Name = "CandyTD_BehindTheDarkHub"
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

-- กล่อง Target Rounds
local leftCol = Window:GetColumn("Left")
local configBox = Instance.new("Frame")
configBox.Size = UDim2.new(1, 0, 0, 38)
configBox.Position = UDim2.fromOffset(0, 190)
configBox.BackgroundColor3 = Color3.fromRGB(80, 35, 120)
configBox.BorderSizePixel = 0
configBox.ZIndex = 4
configBox.Parent = leftCol
Instance.new("UICorner", configBox).CornerRadius = UDim.new(0, 10)
local cbs = Instance.new("UIStroke", configBox)
cbs.Thickness = 2
cbs.Color = Color3.fromRGB(42, 12, 70)

local cfgLabel = Instance.new("TextLabel")
cfgLabel.Size = UDim2.new(1, -100, 1, 0)
cfgLabel.Position = UDim2.fromOffset(12, 0)
cfgLabel.BackgroundTransparency = 1
cfgLabel.Text = "Target Rounds"
cfgLabel.TextColor3 = Color3.fromRGB(255, 235, 120)
cfgLabel.TextSize = 13
cfgLabel.Font = Enum.Font.FredokaOne
cfgLabel.TextXAlignment = Enum.TextXAlignment.Left
cfgLabel.ZIndex = 5
cfgLabel.Parent = configBox

local roundCountLabel = Instance.new("TextLabel")
roundCountLabel.Size = UDim2.fromOffset(30, 26)
roundCountLabel.Position = UDim2.new(1, -66, 0.5, -13)
roundCountLabel.BackgroundColor3 = Color3.fromRGB(45, 15, 75)
roundCountLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
roundCountLabel.TextSize = 13
roundCountLabel.Font = Enum.Font.FredokaOne
roundCountLabel.Text = tostring(states.TargetRounds)
roundCountLabel.ZIndex = 5
roundCountLabel.Parent = configBox
Instance.new("UICorner", roundCountLabel).CornerRadius = UDim.new(0, 6)

local roundStatusBox = Instance.new("Frame")
roundStatusBox.Size = UDim2.new(1, 0, 0, 52)
roundStatusBox.Position = UDim2.fromOffset(0, 236)
roundStatusBox.BackgroundColor3 = Color3.fromRGB(45, 18, 72)
roundStatusBox.BorderSizePixel = 0
roundStatusBox.ZIndex = 4
roundStatusBox.Parent = leftCol
Instance.new("UICorner", roundStatusBox).CornerRadius = UDim.new(0, 12)
local rsbs = Instance.new("UIStroke", roundStatusBox)
rsbs.Thickness = 2.5
rsbs.Color = Color3.fromRGB(75, 30, 115)

local roundStatus = Instance.new("TextLabel")
roundStatus.Size = UDim2.fromScale(1, 1)
roundStatus.BackgroundTransparency = 1
roundStatus.Text = "Round " .. states.CurrentRounds .. "/" .. states.TargetRounds
roundStatus.TextColor3 = Color3.fromRGB(255, 225, 80)
roundStatus.TextSize = 17
roundStatus.Font = Enum.Font.FredokaOne
roundStatus.ZIndex = 5
roundStatus.Parent = roundStatusBox

local btnMinus = Instance.new("TextButton")
btnMinus.Size = UDim2.fromOffset(24, 26)
btnMinus.Position = UDim2.new(1, -96, 0.5, -13)
btnMinus.BackgroundColor3 = Color3.fromRGB(240, 70, 70)
btnMinus.Text = "-"
btnMinus.TextColor3 = Color3.fromRGB(255, 255, 255)
btnMinus.TextSize = 16
btnMinus.Font = Enum.Font.FredokaOne
btnMinus.BorderSizePixel = 0
btnMinus.ZIndex = 5
btnMinus.Parent = configBox
Instance.new("UICorner", btnMinus).CornerRadius = UDim.new(0, 6)
Library.AttachInteractiveEffects(btnMinus)

btnMinus.Activated:Connect(function()
    if states.TargetRounds > 1 then
        states.TargetRounds = states.TargetRounds - 1
        roundCountLabel.Text = tostring(states.TargetRounds)
        roundStatus.Text = string.format("Round %d/%d", states.CurrentRounds, states.TargetRounds)
    end
end)

local btnPlus = Instance.new("TextButton")
btnPlus.Size = UDim2.fromOffset(24, 26)
btnPlus.Position = UDim2.new(1, -30, 0.5, -13)
btnPlus.BackgroundColor3 = Color3.fromRGB(115, 220, 75)
btnPlus.Text = "+"
btnPlus.TextColor3 = Color3.fromRGB(255, 255, 255)
btnPlus.TextSize = 16
btnPlus.Font = Enum.Font.FredokaOne
btnPlus.BorderSizePixel = 0
btnPlus.ZIndex = 5
btnPlus.Parent = configBox
Instance.new("UICorner", btnPlus).CornerRadius = UDim.new(0, 6)
Library.AttachInteractiveEffects(btnPlus)

btnPlus.Activated:Connect(function()
    states.TargetRounds = states.TargetRounds + 1
    roundCountLabel.Text = tostring(states.TargetRounds)
    roundStatus.Text = string.format("Round %d/%d", states.CurrentRounds, states.TargetRounds)
end)

-- ควบคุมฝั่งขวา
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

Window:CreateDropdown("Right", "Stage", 190, { "Inf Bug Milk", "Raid Halloween" }, states.CurrentStage, 10, function(selected)
    states.CurrentStage = selected
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
    if not currentQueue or #currentQueue == 0 then return end

    print("[AutoPlace] เริ่มวางยูนิตในด่าน: " .. states.CurrentStage)
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

local function runEndMatchSequence(choice: string)
    task.spawn(function()
        local matchRemotes = ReplicatedStorage:FindFirstChild("MatchRemotes")
        if not matchRemotes then return end

        local actRemote = matchRemotes:FindFirstChild("Act")
        local replayRemote = matchRemotes:FindFirstChild("Replay")

        -- 1. ตรวจสอบปุ่ม Next สำหรับ Raid Halloween (ชั้น 1 และ 2)
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

        -- หากเป็นชั้น 1 หรือ 2 ใน Raid ให้ส่งคำสั่ง Next ขึ้นชั้นถัดไปก่อน
        if hasNextButton or choice == "NEXT" then
            if actRemote and actRemote:IsA("RemoteFunction") then
                pcall(function() actRemote:InvokeServer("next") end)
            end
        end

        -- 2. กรณีเลือกเล่นซ้ำ (AGAIN) หรือจ่ายเงินเล่นต่อใน Raid (ชั้น 3 / Game Over)
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

        -- 3. ตรวจสอบกดยืนยันปุ่ม Popup เช่น YES / OK / REPLAY บนหน้าจอ
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
