-- ========================================================
-- CANDY TD : IN-MATCH CONTROLLER (WITH 3D RENDERING TOGGLE)
-- ========================================================
repeat task.wait() until game:IsLoaded()

local env = (type(getgenv) == "function" and getgenv()) or _G
local queueOnTeleport = (env and env.queue_on_teleport) 
    or (rawget(env, "syn") and env.syn.queue_on_teleport)
    or (rawget(env, "fluxus") and env.fluxus.queue_on_teleport)

if queueOnTeleport then
    pcall(function()
        queueOnTeleport([[
            repeat task.wait() until game:IsLoaded()
            if not _G.CandyTD_InMatchInstance then
                loadstring(game:HttpGet("https://raw.githubusercontent.com/PKNUDG/BehindTheDarkLib/main/in-match.luau"))()
            end
        ]])
    end)
end

local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local GuiService = game:GetService("GuiService")
local TeleportService = game:GetService("TeleportService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
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
pcall(function()
    GuiService:SetGameplayPausedNotificationEnabled(false)
end)

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
-- EXTREME POTATO BOOST FPS ENGINE (MAX PERFORMANCE)
-- ========================================================
local cachedPartMaterials = {}
local cachedPartColors = {}
local cachedTextures = {}
local cachedDecals = {}
local cachedEmitters = {}
local cachedLights = {}
local cachedMeshTextures = {}
local cachedLighting = {
    GlobalShadows = Lighting.GlobalShadows,
    FogEnd = Lighting.FogEnd,
    Brightness = Lighting.Brightness,
    OutdoorAmbient = Lighting.OutdoorAmbient
}

local function applyUltraBoostFPS(enable: boolean)
    if enable then
        pcall(function()
            settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
        end)

        pcall(function()
            Lighting.GlobalShadows = false
            Lighting.FogEnd = 9e9
            Lighting.Brightness = 1
            Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
        end)

        for _, effect in ipairs(Lighting:GetChildren()) do
            if effect:IsA("PostEffect") or effect:IsA("Atmosphere") or effect:IsA("Sky") or effect:IsA("Clouds") then
                if cachedEmitters[effect] == nil then cachedEmitters[effect] = effect.Parent end
                effect.Parent = nil
            end
        end

        for _, obj in ipairs(workspace:GetDescendants()) do
            pcall(function()
                if obj:IsA("MeshPart") then
                    if not cachedMeshTextures[obj] then
                        cachedMeshTextures[obj] = obj.TextureID
                    end
                    obj.TextureID = ""
                    obj.RenderFidelity = Enum.RenderFidelity.Performance
                end

                if obj:IsA("SpecialMesh") then
                    if not cachedMeshTextures[obj] then
                        cachedMeshTextures[obj] = obj.TextureId
                    end
                    obj.TextureId = ""
                end

                if obj:IsA("BasePart") then
                    if not cachedPartMaterials[obj] then
                        cachedPartMaterials[obj] = obj.Material
                        cachedPartColors[obj] = obj.Color
                    end
                    obj.Material = Enum.Material.SmoothPlastic
                    obj.Color = Color3.fromRGB(125, 125, 125)
                    obj.CastShadow = false
                elseif obj:IsA("Texture") then
                    if not cachedTextures[obj] then cachedTextures[obj] = obj.Texture end
                    obj.Texture = ""
                elseif obj:IsA("Decal") then
                    if not cachedDecals[obj] then cachedDecals[obj] = obj.Transparency end
                    obj.Transparency = 1
                elseif obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") or obj:IsA("Smoke") or obj:IsA("Fire") or obj:IsA("Sparkles") or obj:IsA("Highlight") then
                    if not cachedEmitters[obj] then cachedEmitters[obj] = obj.Enabled end
                    obj.Enabled = false
                elseif obj:IsA("PointLight") or obj:IsA("SpotLight") or obj:IsA("SurfaceLight") then
                    if not cachedLights[obj] then cachedLights[obj] = obj.Enabled end
                    obj.Enabled = false
                end
            end)
        end
    else
        pcall(function()
            settings().Rendering.QualityLevel = Enum.QualityLevel.Automatic
            Lighting.GlobalShadows = cachedLighting.GlobalShadows
            Lighting.FogEnd = cachedLighting.FogEnd
            Lighting.Brightness = cachedLighting.Brightness
            Lighting.OutdoorAmbient = cachedLighting.OutdoorAmbient
        end)

        for effect, parent in pairs(cachedEmitters) do
            pcall(function()
                if typeof(parent) == "Instance" then effect.Parent = parent end
            end)
        end
        for obj, mat in pairs(cachedPartMaterials) do
            pcall(function()
                if obj and obj.Parent then
                    obj.Material = mat
                    obj.Color = cachedPartColors[obj]
                end
            end)
        end
        for obj, tex in pairs(cachedMeshTextures) do
            pcall(function()
                if obj and obj.Parent then
                    if obj:IsA("MeshPart") then obj.TextureID = tex end
                    if obj:IsA("SpecialMesh") then obj.TextureId = tex end
                end
            end)
        end
        for obj, tex in pairs(cachedTextures) do
            pcall(function()
                if obj and obj.Parent then obj.Texture = tex end
            end)
        end
        for obj, trans in pairs(cachedDecals) do
            pcall(function()
                if obj and obj.Parent then obj.Transparency = trans end
            end)
        end
        for obj, en in pairs(cachedEmitters) do
            pcall(function()
                if typeof(en) == "boolean" and obj and obj.Parent then obj.Enabled = en end
            end)
        end
        for obj, en in pairs(cachedLights) do
            pcall(function()
                if typeof(en) == "boolean" and obj and obj.Parent then obj.Enabled = en end
            end)
        end
    end
end

-- ดึงอินสแตนซ์หลัก
local candyTD = playerGui:WaitForChild("CandyTD", 30)
local candyTDStorage = ReplicatedStorage:WaitForChild("CandyTD", 30)
local matchNet: any = nil
pcall(function()
    local module = candyTDStorage:WaitForChild("MatchNet", 10)
    if module and module:IsA("ModuleScript") then
        local reqFunc = require :: any
        matchNet = reqFunc(module)
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

-- Action Helpers
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

-- Interactive Effects
local tweenInfoFast = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local function attachInteractiveEffects(btn: GuiButton, _: any, originalPos: UDim2?)
    local originalSize = btn.Size
    local origPos = originalPos or btn.Position
    local isHovered = false

    btn.MouseEnter:Connect(function()
        isHovered = true
        TweenService:Create(btn, tweenInfoFast, {
            Size = UDim2.new(originalSize.X.Scale, originalSize.X.Offset * 1.025, originalSize.Y.Scale, originalSize.Y.Offset * 1.025),
            Position = UDim2.new(origPos.X.Scale, origPos.X.Offset, origPos.Y.Scale, origPos.Y.Offset - 1)
        }):Play()
    end)

    btn.MouseLeave:Connect(function()
        isHovered = false
        TweenService:Create(btn, tweenInfoFast, { Size = originalSize, Position = origPos }):Play()
    end)

    btn.MouseButton1Down:Connect(function()
        TweenService:Create(btn, tweenInfoFast, {
            Size = UDim2.new(originalSize.X.Scale, originalSize.X.Offset * 0.96, originalSize.Y.Scale, originalSize.Y.Offset * 0.96),
            Position = UDim2.new(origPos.X.Scale, origPos.X.Offset, origPos.Y.Scale, origPos.Y.Offset + 1.5)
        }):Play()
    end)

    btn.MouseButton1Up:Connect(function()
        local targetSize = isHovered and UDim2.new(originalSize.X.Scale, originalSize.X.Offset * 1.025, originalSize.Y.Scale, originalSize.Y.Offset * 1.025) or originalSize
        local targetPos = isHovered and UDim2.new(origPos.X.Scale, origPos.X.Offset, origPos.Y.Scale, origPos.Y.Offset - 1) or origPos
        TweenService:Create(btn, tweenInfoFast, { Size = targetSize, Position = targetPos }):Play()
    end)
end

-- ========================================================
-- EXPANDED WIDE LAYOUT GUI (660 x 440)
-- ========================================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CandyTD_BehindTheDarkHub"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true -- ดัน UI ให้คลุมเต็มจอทะลุขอบ Topbar ด้านบน
Controller.Gui = screenGui

local successParent = pcall(function() screenGui.Parent = CoreGui end)
if not successParent then screenGui.Parent = playerGui end

-- ========================================================
-- BLACKOUT CURTAIN (ม่านจอดำเวลาปิด 3D)
-- ========================================================
local blackoutFrame = Instance.new("Frame")
blackoutFrame.Name = "BlackoutFrame"
blackoutFrame.Size = UDim2.fromScale(1, 1)
blackoutFrame.Position = UDim2.fromScale(0, 0)
blackoutFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
blackoutFrame.BorderSizePixel = 0
blackoutFrame.ZIndex = 0 -- อยู่หลังสุด ไม่บัง UI หลัก
blackoutFrame.Visible = false
blackoutFrame.Active = false
blackoutFrame.Parent = screenGui

local mainCard = Instance.new("Frame")
mainCard.Name = "MainCard"
mainCard.Size = UDim2.fromOffset(660, 440)
mainCard.Position = UDim2.new(0.5, -330, 0.5, -220)
mainCard.BackgroundColor3 = Color3.fromRGB(152, 114, 203)
mainCard.BorderSizePixel = 0
mainCard.Active = true
mainCard.Parent = screenGui
Instance.new("UICorner", mainCard).CornerRadius = UDim.new(0, 22)
local mainStroke = Instance.new("UIStroke", mainCard)
mainStroke.Thickness = 5
mainStroke.Color = Color3.fromRGB(42, 12, 70)

-- Drag Window
local dragging, dragStart, startPos = false, nil, nil
mainCard.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = mainCard.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)
mainCard.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        if dragging then
            local delta = input.Position - dragStart
            mainCard.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end
end)

-- Title Bar
local titlePlate = Instance.new("Frame")
titlePlate.Size = UDim2.new(1, -28, 0, 42)
titlePlate.Position = UDim2.fromOffset(14, 14)
titlePlate.BackgroundColor3 = Color3.fromRGB(75, 30, 115)
titlePlate.BorderSizePixel = 0
titlePlate.ZIndex = 2
titlePlate.Parent = mainCard
Instance.new("UICorner", titlePlate).CornerRadius = UDim.new(0, 12)
local tpStroke = Instance.new("UIStroke", titlePlate)
tpStroke.Thickness = 2.5
tpStroke.Color = Color3.fromRGB(42, 12, 70)

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.fromScale(1, 1)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "BEHIND THE DARK"
titleLabel.TextColor3 = Color3.fromRGB(255, 235, 120)
titleLabel.TextSize = 17
titleLabel.Font = Enum.Font.FredokaOne
titleLabel.ZIndex = 3
titleLabel.Parent = titlePlate
local titleStroke = Instance.new("UIStroke", titleLabel)
titleStroke.Thickness = 3
titleStroke.Color = Color3.fromRGB(35, 10, 55)

-- Hotkey Hide/Show
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and input.UserInputType == Enum.UserInputType.Keyboard then
        if input.KeyCode == Enum.KeyCode.RightShift then
            mainCard.Visible = not mainCard.Visible
        end
    end
end)

-- 2 Columns (Left / Right)
local leftColumn = Instance.new("Frame")
leftColumn.Size = UDim2.new(0.5, -20, 1, -72)
leftColumn.Position = UDim2.fromOffset(14, 66)
leftColumn.BackgroundTransparency = 1
leftColumn.Parent = mainCard

local rightColumn = Instance.new("Frame")
rightColumn.Size = UDim2.new(0.5, -20, 1, -72)
rightColumn.Position = UDim2.new(0.5, 6, 0, 66)
rightColumn.BackgroundTransparency = 1
rightColumn.Parent = mainCard

-- ========================================================
-- PRESETS & DROPDOWN ENGINE (AUTO PLACE WITH INF BUG MILK)
-- ========================================================
local StagePresets = {
    ["Raid Halloween"] = {
        { unit = "AlienJake", x = -23.374317169189453, z = -29.752378463745117 },
        { unit = "AlienJake", x = -21.034372329711914, z = -30.95560073852539 },
        { unit = "Lemongrab3", x = -18.13538932800293, z = -24.010784149169922 },
        { unit = "Lemongrab3", x = -15.872089385986328, z = -24.980955123901367 },
        { unit = "CandyElemental", x = -12.905556678771973, z = -26.32013702392578 },
        { unit = "CandyElemental", x = -10.390554428100586, z = -28.499164581298828 },
        { unit = "HunsonDemon", x = -10.000167846679688, z = -30.825727462768555, useAbility = true }
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
    Render3DEnabled = true, -- ตัวแปรสถานะเปิด/ปิดการ Render 3D
    CurrentStage = "Inf Bug Milk",
    TargetRounds = 10,
    CurrentRounds = 0
}

local visualUpdaters: {[string]: (boolean) -> ()} = {}

local function createSolidCandyButton(parentObj: Frame, text: string, yPos: number, colorPreset: {On: Color3, Off: Color3}, callback: () -> ())
    local btnBase = Instance.new("Frame")
    btnBase.Size = UDim2.new(1, 0, 0, 38)
    btnBase.Position = UDim2.fromOffset(0, yPos)
    btnBase.BackgroundColor3 = Color3.fromRGB(35, 10, 55)
    btnBase.BorderSizePixel = 0
    btnBase.ZIndex = 2
    btnBase.Parent = parentObj
    Instance.new("UICorner", btnBase).CornerRadius = UDim.new(1, 0)
    local bs = Instance.new("UIStroke", btnBase)
    bs.Thickness = 2.5
    bs.Color = Color3.fromRGB(35, 10, 55)

    local btnTop = Instance.new("TextButton")
    btnTop.Size = UDim2.new(1, -2, 1, -4)
    btnTop.Position = UDim2.fromOffset(1, 1)
    btnTop.BackgroundColor3 = colorPreset.Off
    btnTop.BorderSizePixel = 0
    btnTop.AutoButtonColor = false
    btnTop.Text = ""
    btnTop.ClipsDescendants = true
    btnTop.ZIndex = 3
    btnTop.Parent = btnBase
    Instance.new("UICorner", btnTop).CornerRadius = UDim.new(1, 0)

    local gloss = Instance.new("Frame")
    gloss.Size = UDim2.new(1, -14, 0.45, 0)
    gloss.Position = UDim2.fromOffset(7, 1)
    gloss.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    gloss.BackgroundTransparency = 0.72
    gloss.BorderSizePixel = 0
    gloss.ZIndex = 4
    gloss.Parent = btnTop
    Instance.new("UICorner", gloss).CornerRadius = UDim.new(1, 0)

    local btnText = Instance.new("TextLabel")
    btnText.Size = UDim2.new(1, -24, 1, 0)
    btnText.Position = UDim2.fromOffset(16, 0)
    btnText.BackgroundTransparency = 1
    btnText.TextColor3 = Color3.fromRGB(255, 255, 255)
    btnText.TextSize = 14
    btnText.Font = Enum.Font.FredokaOne
    btnText.TextXAlignment = Enum.TextXAlignment.Left
    btnText.ZIndex = 5
    btnText.Text = text .. " : OFF"
    btnText.Parent = btnTop
    local ts = Instance.new("UIStroke", btnText)
    ts.Thickness = 2.5
    ts.Color = Color3.fromRGB(40, 10, 60)

    attachInteractiveEffects(btnTop, btnTop.BackgroundColor3, UDim2.fromOffset(1, 1))

    local function setVisual(active: boolean)
        if active then
            btnTop.BackgroundColor3 = colorPreset.On
            btnText.Text = text .. " : ON"
        else
            btnTop.BackgroundColor3 = colorPreset.Off
            btnText.Text = text .. " : OFF"
        end
    end

    btnTop.Activated:Connect(callback)
    return setVisual
end

-- ========================================================
-- ฝั่งซ้าย: END-MATCH & AGAIN ENGINE
-- ========================================================
local function updateEndChoiceVisuals()
    if visualUpdaters["NEXT"] then visualUpdaters["NEXT"](states.EndChoice == "NEXT") end
    if visualUpdaters["AGAIN"] then visualUpdaters["AGAIN"](states.EndChoice == "AGAIN") end
    if visualUpdaters["HOME"] then visualUpdaters["HOME"](states.EndChoice == "HOME") end
end

local function setEndChoice(choice: string)
    if states.EndChoice == choice then
        states.EndChoice = "NONE"
    else
        states.EndChoice = choice
    end
    updateEndChoiceVisuals()
end

visualUpdaters["NEXT"] = createSolidCandyButton(leftColumn, "Auto Next", 0, { On = Color3.fromRGB(235, 65, 135), Off = Color3.fromRGB(120, 120, 130) }, function() setEndChoice("NEXT") end)
visualUpdaters["AGAIN"] = createSolidCandyButton(leftColumn, "Auto Again", 46, { On = Color3.fromRGB(240, 150, 40), Off = Color3.fromRGB(120, 120, 130) }, function() setEndChoice("AGAIN") end)
visualUpdaters["HOME"] = createSolidCandyButton(leftColumn, "Auto Home", 92, { On = Color3.fromRGB(60, 180, 245), Off = Color3.fromRGB(120, 120, 130) }, function() setEndChoice("HOME") end)

-- สั่งอัปเดตสีตาม states.EndChoice ทันที
updateEndChoiceVisuals()

local againHomeToggleUpdater = nil
againHomeToggleUpdater = createSolidCandyButton(leftColumn, "Again Count Limit", 144, { On = Color3.fromRGB(255, 140, 40), Off = Color3.fromRGB(120, 120, 130) }, function()
    states.AgainBeforeHomeActive = not states.AgainBeforeHomeActive
    if againHomeToggleUpdater then againHomeToggleUpdater(states.AgainBeforeHomeActive) end
end)

local configBox = Instance.new("Frame")
configBox.Size = UDim2.new(1, 0, 0, 38)
configBox.Position = UDim2.fromOffset(0, 190)
configBox.BackgroundColor3 = Color3.fromRGB(80, 35, 120)
configBox.BorderSizePixel = 0
configBox.Parent = leftColumn
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
cfgLabel.Parent = configBox

local roundCountLabel = Instance.new("TextLabel")
roundCountLabel.Size = UDim2.fromOffset(30, 26)
roundCountLabel.Position = UDim2.new(1, -66, 0.5, -13)
roundCountLabel.BackgroundColor3 = Color3.fromRGB(45, 15, 75)
roundCountLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
roundCountLabel.TextSize = 13
roundCountLabel.Font = Enum.Font.FredokaOne
roundCountLabel.Text = tostring(states.TargetRounds)
roundCountLabel.Parent = configBox
Instance.new("UICorner", roundCountLabel).CornerRadius = UDim.new(0, 6)

local btnMinus = Instance.new("TextButton")
btnMinus.Size = UDim2.fromOffset(24, 26)
btnMinus.Position = UDim2.new(1, -96, 0.5, -13)
btnMinus.BackgroundColor3 = Color3.fromRGB(240, 70, 70)
btnMinus.Text = "-"
btnMinus.TextColor3 = Color3.fromRGB(255, 255, 255)
btnMinus.TextSize = 16
btnMinus.Font = Enum.Font.FredokaOne
btnMinus.BorderSizePixel = 0
btnMinus.Parent = configBox
Instance.new("UICorner", btnMinus).CornerRadius = UDim.new(0, 6)

local btnPlus = Instance.new("TextButton")
btnPlus.Size = UDim2.fromOffset(24, 26)
btnPlus.Position = UDim2.new(1, -30, 0.5, -13)
btnPlus.BackgroundColor3 = Color3.fromRGB(115, 220, 75)
btnPlus.Text = "+"
btnPlus.TextColor3 = Color3.fromRGB(255, 255, 255)
btnPlus.TextSize = 16
btnPlus.Font = Enum.Font.FredokaOne
btnPlus.BorderSizePixel = 0
btnPlus.Parent = configBox
Instance.new("UICorner", btnPlus).CornerRadius = UDim.new(0, 6)

local roundStatusBox = Instance.new("Frame")
roundStatusBox.Size = UDim2.new(1, 0, 0, 52)
roundStatusBox.Position = UDim2.fromOffset(0, 236)
roundStatusBox.BackgroundColor3 = Color3.fromRGB(45, 18, 72)
roundStatusBox.BorderSizePixel = 0
roundStatusBox.Parent = leftColumn
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
roundStatus.Parent = roundStatusBox

btnMinus.Activated:Connect(function()
    if states.TargetRounds > 1 then
        states.TargetRounds = states.TargetRounds - 1
        roundCountLabel.Text = tostring(states.TargetRounds)
        roundStatus.Text = string.format("Round %d/%d", states.CurrentRounds, states.TargetRounds)
    end
end)

btnPlus.Activated:Connect(function()
    states.TargetRounds = states.TargetRounds + 1
    roundCountLabel.Text = tostring(states.TargetRounds)
    roundStatus.Text = string.format("Round %d/%d", states.CurrentRounds, states.TargetRounds)
end)

-- ตรวจสอบบรรทัดนี้: เรียก updateEndChoiceVisuals() เท่านั้น ห้ามเรียก setEndChoice(states.EndChoice)
updateEndChoiceVisuals()

-- ========================================================
-- ฝั่งขวา: BATTLE ENGINE & DROPDOWN AUTO PLACE & 3D TOGGLE
-- ========================================================
local upgradeVisualUpdater = nil
upgradeVisualUpdater = createSolidCandyButton(rightColumn, "Auto Upgrade All", 0, { On = Color3.fromRGB(90, 195, 60), Off = Color3.fromRGB(120, 120, 130) }, function()
    states.AutoUpgrade = not states.AutoUpgrade
    if upgradeVisualUpdater then upgradeVisualUpdater(states.AutoUpgrade) end
end)
upgradeVisualUpdater(states.AutoUpgrade)

local autoSkipVisualUpdater = nil
autoSkipVisualUpdater = createSolidCandyButton(rightColumn, "Auto Skip Wave", 46, { On = Color3.fromRGB(160, 75, 235), Off = Color3.fromRGB(120, 120, 130) }, function()
    states.AutoSkipWave = not states.AutoSkipWave
    if autoSkipVisualUpdater then autoSkipVisualUpdater(states.AutoSkipWave) end
end)
autoSkipVisualUpdater(states.AutoSkipWave)

local boostFpsVisualUpdater = nil
boostFpsVisualUpdater = createSolidCandyButton(rightColumn, "Boost FPS", 92, { On = Color3.fromRGB(50, 205, 150), Off = Color3.fromRGB(120, 120, 130) }, function()
    states.BoostFPS = not states.BoostFPS
    applyUltraBoostFPS(states.BoostFPS)
    if boostFpsVisualUpdater then boostFpsVisualUpdater(states.BoostFPS) end
end)
boostFpsVisualUpdater(states.BoostFPS)

-- สวิตช์เปิด/ปิด Auto Place
local autoPlaceVisualUpdater = nil
autoPlaceVisualUpdater = createSolidCandyButton(rightColumn, "Auto Place", 144, { On = Color3.fromRGB(255, 110, 80), Off = Color3.fromRGB(120, 120, 130) }, function()
    states.AutoPlace = not states.AutoPlace
    if autoPlaceVisualUpdater then autoPlaceVisualUpdater(states.AutoPlace) end
end)
autoPlaceVisualUpdater(states.AutoPlace)

-- Dropdown เลือกด่านสำหรับ Auto Place
local dropdownCard = Instance.new("Frame")
dropdownCard.Size = UDim2.new(1, 0, 0, 38)
dropdownCard.Position = UDim2.fromOffset(0, 190)
dropdownCard.BackgroundColor3 = Color3.fromRGB(60, 20, 85)
dropdownCard.BorderSizePixel = 0
dropdownCard.ZIndex = 10
dropdownCard.Parent = rightColumn
Instance.new("UICorner", dropdownCard).CornerRadius = UDim.new(0, 10)
local dcs = Instance.new("UIStroke", dropdownCard)
dcs.Thickness = 2
dcs.Color = Color3.fromRGB(160, 75, 235)

local stageSelectBtn = Instance.new("TextButton")
stageSelectBtn.Size = UDim2.fromScale(1, 1)
stageSelectBtn.BackgroundTransparency = 1
stageSelectBtn.Text = " Stage: " .. states.CurrentStage .. " ▾"
stageSelectBtn.TextColor3 = Color3.fromRGB(255, 235, 120)
stageSelectBtn.TextSize = 13
stageSelectBtn.Font = Enum.Font.FredokaOne
stageSelectBtn.TextXAlignment = Enum.TextXAlignment.Left
stageSelectBtn.ZIndex = 11
stageSelectBtn.Parent = dropdownCard

local stageDropdownScroll = Instance.new("ScrollingFrame")
stageDropdownScroll.Size = UDim2.new(1, 0, 0, 98)
stageDropdownScroll.Position = UDim2.fromOffset(0, 42)
stageDropdownScroll.BackgroundColor3 = Color3.fromRGB(35, 12, 55)
stageDropdownScroll.BorderSizePixel = 0
stageDropdownScroll.ScrollBarThickness = 5
stageDropdownScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
stageDropdownScroll.Visible = false
stageDropdownScroll.ZIndex = 50
stageDropdownScroll.Parent = dropdownCard
Instance.new("UICorner", stageDropdownScroll).CornerRadius = UDim.new(0, 8)
local sdsStroke = Instance.new("UIStroke", stageDropdownScroll)
sdsStroke.Thickness = 1.5
sdsStroke.Color = Color3.fromRGB(160, 75, 235)
local sdsList = Instance.new("UIListLayout", stageDropdownScroll)
sdsList.Padding = UDim.new(0, 2)

stageSelectBtn.Activated:Connect(function()
    stageDropdownScroll.Visible = not stageDropdownScroll.Visible
    if stageDropdownScroll.Visible then
        for _, ch in ipairs(stageDropdownScroll:GetChildren()) do
            if ch:IsA("TextButton") then ch:Destroy() end
        end
        for stageName, _ in pairs(StagePresets) do
            local sBtn = Instance.new("TextButton")
            sBtn.Size = UDim2.new(1, -8, 0, 28)
            sBtn.BackgroundColor3 = (states.CurrentStage == stageName) and Color3.fromRGB(160, 75, 235) or Color3.fromRGB(65, 25, 95)
            sBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            sBtn.TextSize = 12
            sBtn.Font = Enum.Font.FredokaOne
            sBtn.Text = " " .. stageName
            sBtn.TextXAlignment = Enum.TextXAlignment.Left
            sBtn.BorderSizePixel = 0
            sBtn.ZIndex = 51
            sBtn.Parent = stageDropdownScroll
            Instance.new("UICorner", sBtn).CornerRadius = UDim.new(0, 6)

            sBtn.Activated:Connect(function()
                states.CurrentStage = stageName
                stageSelectBtn.Text = " Stage: " .. states.CurrentStage .. " ▾"
                stageDropdownScroll.Visible = false
            end)
        end
    end
end)

-- ========================================================
-- [NEW] ปุ่มเล็กเปิด/ปิด 3D RENDERING (มุมขวาล่างสุด)
-- ========================================================
local render3dBtn = Instance.new("TextButton")
render3dBtn.Size = UDim2.new(0, 115, 0, 32)
render3dBtn.Position = UDim2.new(1, -115, 1, -34) -- ล็อคตำแหน่งมุมขวาล่างสุด
render3dBtn.BackgroundColor3 = states.Render3DEnabled and Color3.fromRGB(55, 140, 65) or Color3.fromRGB(190, 50, 50)
render3dBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
render3dBtn.TextSize = 12
render3dBtn.Font = Enum.Font.FredokaOne
render3dBtn.Text = states.Render3DEnabled and "[ 3D: ON ]" or "[ 3D: OFF ]"
render3dBtn.BorderSizePixel = 0
render3dBtn.ZIndex = 15
render3dBtn.Parent = rightColumn
Instance.new("UICorner", render3dBtn).CornerRadius = UDim.new(0, 8)
local r3dStroke = Instance.new("UIStroke", render3dBtn)
r3dStroke.Thickness = 2
r3dStroke.Color = Color3.fromRGB(35, 10, 55)

attachInteractiveEffects(render3dBtn, render3dBtn.BackgroundColor3)

render3dBtn.Activated:Connect(function()
    states.Render3DEnabled = not states.Render3DEnabled
    pcall(function()
        RunService:Set3dRenderingEnabled(states.Render3DEnabled)
    end)
    
    -- ควบคุมม่านจอดำ
    blackoutFrame.Visible = not states.Render3DEnabled
    
    render3dBtn.BackgroundColor3 = states.Render3DEnabled and Color3.fromRGB(55, 140, 65) or Color3.fromRGB(190, 50, 50)
    render3dBtn.Text = states.Render3DEnabled and "[ 3D: ON ]" or "[ 3D: OFF ]"
end)

-- ========================================================
-- AUTO PLACE EXECUTION ENGINE
-- ========================================================
local hasPlacedThisMatch = false

local function runAutoPlaceSequence()
    local matchRemotes = ReplicatedStorage:FindFirstChild("MatchRemotes")
    local actRemote = matchRemotes and matchRemotes:FindFirstChild("Act")
    if not (actRemote and actRemote:IsA("RemoteFunction")) then return end

    local currentQueue = StagePresets[states.CurrentStage]
    if not currentQueue or #currentQueue == 0 then return end

    print("[AutoPlace] เริ่มกระบวนการวางตัวในด่าน: " .. states.CurrentStage)

    for _, item in ipairs(currentQueue) do
        local ok, result = pcall(function()
            return actRemote:InvokeServer("place", item.unit, item.x, item.z)
        end)
        
        local targetId = nil
        if ok then
            if type(result) == "table" and result.id then
                targetId = result.id
            elseif type(result) == "number" then
                targetId = result
            end
        end

        -- ตรวจสอบการใช้สกิล Ability
        if ok and item.useAbility and targetId then
            task.wait(0.3)
            pcall(function()
                actRemote:InvokeServer("ability", targetId)
            end)
        end

        -- ตรวจสอบการปรับเป้าหมาย Targeting (เช่น strongest)
        if ok and item.setTarget and targetId then
            task.wait(0.3)
            pcall(function()
                actRemote:InvokeServer("target", targetId, item.setTarget)
            end)
        end

        task.wait(0.35)
    end

    task.wait(0.5)
    print("[AutoPlace] วางครบเรียบร้อย! สั่งเริ่มเกม (Start)...")
    pcall(function()
        actRemote:InvokeServer("start")
    end)
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
                if txt:find("START WAVE 1") or txt:find("WAVE 1") then
                    isPreMatch = true
                end
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
-- MATCH END CONTROLLER (REPLAY & BUG MILK SEQUENCE)
-- ========================================================
local function runEndMatchSequence(choice: string)
    task.spawn(function()
        local matchRemotes = ReplicatedStorage:FindFirstChild("MatchRemotes")
        local overlay = candyTD:FindFirstChild("Overlay")

        local function findClickableBtn(parentObj: Instance?): GuiButton?
            if not parentObj then return nil end
            if parentObj:IsA("GuiButton") then return parentObj end
            return parentObj:FindFirstChildWhichIsA("GuiButton", true)
        end

        local nextBtn = overlay and findClickableBtn(overlay:FindFirstChild("Next", true))
        local againBtn = overlay and findClickableBtn(overlay:FindFirstChild("PlayAgain", true))

        if choice == "NEXT" then
            if nextBtn and nextBtn.Visible then triggerInternalButton(nextBtn) end
            requestMatchAction("next")
        elseif choice == "AGAIN" then
            if againBtn and againBtn.Visible then triggerInternalButton(againBtn) end
            requestMatchAction("again")
        end

        task.wait(0.4)

        if matchRemotes then
            local replayRemote = matchRemotes:FindFirstChild("Replay")
            if replayRemote and replayRemote:IsA("RemoteFunction") then
                pcall(function() replayRemote:InvokeServer("info") end)
                task.wait(0.3)
                pcall(function() replayRemote:InvokeServer("pay") end)
            end
        end

        task.wait(0.2)
        pcall(function()
            for _, desc in ipairs(candyTD:GetDescendants()) do
                if desc:IsA("GuiButton") and desc.Visible then
                    local t = (desc:IsA("TextButton") and desc.Text:upper()) or ""
                    for _, l in ipairs(desc:GetDescendants()) do
                        if l:IsA("TextLabel") and l.Visible then t = t .. " " .. l.Text:upper() end
                    end
                    if t:find("YES") or t:find("POUR") or desc.Name:upper():find("YES") then
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

                local function findClickableBtn(parentObj: Instance?): GuiButton?
                    if not parentObj then return nil end
                    if parentObj:IsA("GuiButton") then return parentObj end
                    return parentObj:FindFirstChildWhichIsA("GuiButton", true)
                end

                local homeBtn = findClickableBtn(overlay:FindFirstChild("ReturnToHub", true))

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
                            
                            if homeBtn then triggerInternalButton(homeBtn) end
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
                    if homeBtn then triggerInternalButton(homeBtn) end
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

-- ========================================================
-- AUTO UPGRADE & AUTO SKIP WAVE LOOPS
-- ========================================================
task.spawn(function()
    while Controller.Running do
        task.wait(0.2)
        if states.AutoUpgrade then
            local overlay = candyTD:FindFirstChild("Overlay")
            local isOverlayOpen = overlay and overlay.Visible

            local isPreMatch = false
            local startWaveBtn = candyTD:FindFirstChild("StartWave")
            if startWaveBtn and startWaveBtn.Visible then
                local txtLabel = startWaveBtn:FindFirstChildWhichIsA("TextLabel", true)
                if txtLabel and txtLabel.Text:find("START WAVE 1") then isPreMatch = true end
            end

            if not isPreMatch and not isOverlayOpen then
                local upgradeAllBtn: GuiButton? = nil
                local isFullyMaxed = false

                for _, desc in ipairs(candyTD:GetDescendants()) do
                    if desc:IsA("GuiButton") and desc.Visible then
                        local n = desc.Name:lower()
                        local txt = ""
                        for _, l in ipairs(desc:GetDescendants()) do
                            if l:IsA("TextLabel") then txt = txt .. " " .. l.Text:lower() end
                        end
                        if desc:IsA("TextButton") then txt = txt .. " " .. desc.Text:lower() end

                        if n:find("upgradeall") or txt:find("upgrade all") then
                            if txt:find("max") or n:find("max") then isFullyMaxed = true else upgradeAllBtn = desc end
                            break
                        end
                    end
                end

                if upgradeAllBtn and not isFullyMaxed then
                    triggerInternalButton(upgradeAllBtn)
                end
            end
        end
    end
end)

task.spawn(function()
    while Controller.Running do
        task.wait(0.15)
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
