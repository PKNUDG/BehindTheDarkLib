-- ========================================================
-- CANDY TD : LOBBY HUB (CLEAN AUTO SUMMON CONTROLLER)
-- ========================================================
repeat task.wait() until game:IsLoaded()

local env = (type(getgenv) == "function" and getgenv()) or _G
local queueOnTeleport = (env and env.queue_on_teleport) 
    or (rawget(env, "syn") and env.syn.queue_on_teleport)
    or (rawget(env, "fluxus") and env.fluxus.queue_on_teleport)

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

-- ลบ Instance เก่า
if _G.CandyTD_LobbyInstance then
    pcall(function()
        _G.CandyTD_LobbyInstance.Running = false
        if _G.CandyTD_LobbyInstance.Gui then
            _G.CandyTD_LobbyInstance.Gui:Destroy()
        end
    end)
end

local Controller = { Running = true }
_G.CandyTD_LobbyInstance = Controller

local oldGuis = { "CandyTD_BehindTheDarkLobby", "CandyTD_LobbyHub" }
for _, gName in ipairs(oldGuis) do
    pcall(function()
        local g = CoreGui:FindFirstChild(gName) or playerGui:FindFirstChild(gName)
        if g then g:Destroy() end
    end)
end

-- ========================================================
-- ANTI-AFK & RECONNECT
-- ========================================================
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
-- UI CREATION (WIDE LAYOUT 660 x 440)
-- ========================================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CandyTD_BehindTheDarkLobby"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.DisplayOrder = 999 -- ดันเลเยอร์ขึ้นเหนือ UI ตัวเกม
Controller.Gui = screenGui

local successParent = pcall(function() screenGui.Parent = CoreGui end)
if not successParent then screenGui.Parent = playerGui end

-- Blackout Frame (มืดสนิท บัง UI เกมให้เห็นจางๆ)
local blackoutFrame = Instance.new("Frame")
blackoutFrame.Name = "BlackoutFrame"
blackoutFrame.Size = UDim2.fromScale(1, 1)
blackoutFrame.Position = UDim2.fromScale(0, 0)
blackoutFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
blackoutFrame.BackgroundTransparency = 0.07 -- เห็น UI เกมจางๆ
blackoutFrame.BorderSizePixel = 0
blackoutFrame.ZIndex = 1 -- อยู่เหนือ UI เกม แต่อยู่ใต้หน้าต่างสคริปต์
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
mainCard.ZIndex = 2 -- ให้หน้าต่างหลักอยู่เหนือม่านดำ
mainCard.Parent = screenGui

-- Dragging
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

-- Hotkey Hide/Show (RightShift)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and input.UserInputType == Enum.UserInputType.Keyboard then
        if input.KeyCode == Enum.KeyCode.RightShift then
            mainCard.Visible = not mainCard.Visible
        end
    end
end)

-- 2 คอลัมน์
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
-- INTERACTIVE BUTTON ENGINE
-- ========================================================
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
-- STATES & SUMMON CONFIG
-- ========================================================
local states = {
    AutoSummon = false,
    BannerType = "Standard", -- "Standard" หรือ "Event"
    RollAmount = 10,        -- 1 หรือ 10
    Render3DEnabled = true,
    TotalSummons = 0
}

-- ========================================================
-- LEFT COLUMN: BANNER CONTROLLER & DROPDOWNS
-- ========================================================
-- 1. ปุ่มเปิด/ปิด Auto Summon
local autoSummonUpdater = nil
autoSummonUpdater = createSolidCandyButton(leftColumn, "Auto Summon", 0, { On = Color3.fromRGB(255, 110, 80), Off = Color3.fromRGB(120, 120, 130) }, function()
    states.AutoSummon = not states.AutoSummon
    if autoSummonUpdater then autoSummonUpdater(states.AutoSummon) end
end)
autoSummonUpdater(states.AutoSummon)

-- 2. Dropdown เลือกตู้ (Banner Type)
local bannerCard = Instance.new("Frame")
bannerCard.Size = UDim2.new(1, 0, 0, 38)
bannerCard.Position = UDim2.fromOffset(0, 46)
bannerCard.BackgroundColor3 = Color3.fromRGB(60, 20, 85)
bannerCard.BorderSizePixel = 0
bannerCard.ZIndex = 20
bannerCard.Parent = leftColumn
Instance.new("UICorner", bannerCard).CornerRadius = UDim.new(0, 10)
local bcs = Instance.new("UIStroke", bannerCard)
bcs.Thickness = 2
bcs.Color = Color3.fromRGB(160, 75, 235)

local bannerSelectBtn = Instance.new("TextButton")
bannerSelectBtn.Size = UDim2.fromScale(1, 1)
bannerSelectBtn.BackgroundTransparency = 1
bannerSelectBtn.Text = "  Banner: " .. states.BannerType .. " ▾"
bannerSelectBtn.TextColor3 = Color3.fromRGB(255, 235, 120)
bannerSelectBtn.TextSize = 13
bannerSelectBtn.Font = Enum.Font.FredokaOne
bannerSelectBtn.TextXAlignment = Enum.TextXAlignment.Left
bannerSelectBtn.ZIndex = 21
bannerSelectBtn.Parent = bannerCard

local bannerDropdownScroll = Instance.new("Frame")
bannerDropdownScroll.Size = UDim2.new(1, 0, 0, 68)
bannerDropdownScroll.Position = UDim2.fromOffset(0, 42)
bannerDropdownScroll.BackgroundColor3 = Color3.fromRGB(35, 12, 55)
bannerDropdownScroll.BorderSizePixel = 0
bannerDropdownScroll.Visible = false
bannerDropdownScroll.ZIndex = 50
bannerDropdownScroll.Parent = bannerCard
Instance.new("UICorner", bannerDropdownScroll).CornerRadius = UDim.new(0, 8)
local bdsStroke = Instance.new("UIStroke", bannerDropdownScroll)
bdsStroke.Thickness = 1.5
bdsStroke.Color = Color3.fromRGB(160, 75, 235)
local bdsList = Instance.new("UIListLayout", bannerDropdownScroll)
bdsList.Padding = UDim.new(0, 4)

local function populateBannerOptions()
    for _, ch in ipairs(bannerDropdownScroll:GetChildren()) do
        if ch:IsA("TextButton") then ch:Destroy() end
    end
    for _, bType in ipairs({ "Standard", "Event" }) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, -8, 0, 28)
        btn.Position = UDim2.fromOffset(4, 0)
        btn.BackgroundColor3 = (states.BannerType == bType) and Color3.fromRGB(160, 75, 235) or Color3.fromRGB(65, 25, 95)
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.TextSize = 12
        btn.Font = Enum.Font.FredokaOne
        btn.Text = "  " .. bType .. " Banner"
        btn.TextXAlignment = Enum.TextXAlignment.Left
        btn.BorderSizePixel = 0
        btn.ZIndex = 51
        btn.Parent = bannerDropdownScroll
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

        btn.Activated:Connect(function()
            states.BannerType = bType
            bannerSelectBtn.Text = "  Banner: " .. states.BannerType .. " ▾"
            bannerDropdownScroll.Visible = false
        end)
    end
end

bannerSelectBtn.Activated:Connect(function()
    bannerDropdownScroll.Visible = not bannerDropdownScroll.Visible
    if bannerDropdownScroll.Visible then populateBannerOptions() end
end)

-- 3. Dropdown เลือกจำนวนครั้ง (Roll Amount)
local rollCard = Instance.new("Frame")
rollCard.Size = UDim2.new(1, 0, 0, 38)
rollCard.Position = UDim2.fromOffset(0, 92)
rollCard.BackgroundColor3 = Color3.fromRGB(60, 20, 85)
rollCard.BorderSizePixel = 0
rollCard.ZIndex = 15
rollCard.Parent = leftColumn
Instance.new("UICorner", rollCard).CornerRadius = UDim.new(0, 10)
local rcs = Instance.new("UIStroke", rollCard)
rcs.Thickness = 2
rcs.Color = Color3.fromRGB(160, 75, 235)

local rollSelectBtn = Instance.new("TextButton")
rollSelectBtn.Size = UDim2.fromScale(1, 1)
rollSelectBtn.BackgroundTransparency = 1
rollSelectBtn.Text = "  Amount: " .. states.RollAmount .. " Rolls ▾"
rollSelectBtn.TextColor3 = Color3.fromRGB(255, 235, 120)
rollSelectBtn.TextSize = 13
rollSelectBtn.Font = Enum.Font.FredokaOne
rollSelectBtn.TextXAlignment = Enum.TextXAlignment.Left
rollSelectBtn.ZIndex = 16
rollSelectBtn.Parent = rollCard

local rollDropdownScroll = Instance.new("Frame")
rollDropdownScroll.Size = UDim2.new(1, 0, 0, 68)
rollDropdownScroll.Position = UDim2.fromOffset(0, 42)
rollDropdownScroll.BackgroundColor3 = Color3.fromRGB(35, 12, 55)
rollDropdownScroll.BorderSizePixel = 0
rollDropdownScroll.Visible = false
rollDropdownScroll.ZIndex = 50
rollDropdownScroll.Parent = rollCard
Instance.new("UICorner", rollDropdownScroll).CornerRadius = UDim.new(0, 8)
local rdsStroke = Instance.new("UIStroke", rollDropdownScroll)
rdsStroke.Thickness = 1.5
rdsStroke.Color = Color3.fromRGB(160, 75, 235)
local rdsList = Instance.new("UIListLayout", rollDropdownScroll)
rdsList.Padding = UDim.new(0, 4)

local function populateRollOptions()
    for _, ch in ipairs(rollDropdownScroll:GetChildren()) do
        if ch:IsA("TextButton") then ch:Destroy() end
    end
    for _, amt in ipairs({ 10, 1 }) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, -8, 0, 28)
        btn.Position = UDim2.fromOffset(4, 0)
        btn.BackgroundColor3 = (states.RollAmount == amt) and Color3.fromRGB(160, 75, 235) or Color3.fromRGB(65, 25, 95)
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.TextSize = 12
        btn.Font = Enum.Font.FredokaOne
        btn.Text = "  " .. amt .. " Rolls"
        btn.TextXAlignment = Enum.TextXAlignment.Left
        btn.BorderSizePixel = 0
        btn.ZIndex = 51
        btn.Parent = rollDropdownScroll
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

        btn.Activated:Connect(function()
            states.RollAmount = amt
            rollSelectBtn.Text = "  Amount: " .. states.RollAmount .. " Rolls ▾"
            rollDropdownScroll.Visible = false
        end)
    end
end

rollSelectBtn.Activated:Connect(function()
    rollDropdownScroll.Visible = not rollDropdownScroll.Visible
    if rollDropdownScroll.Visible then populateRollOptions() end
end)

-- 4. Stat Counter Display
local counterBox = Instance.new("Frame")
counterBox.Size = UDim2.new(1, 0, 0, 52)
counterBox.Position = UDim2.fromOffset(0, 144)
counterBox.BackgroundColor3 = Color3.fromRGB(45, 18, 72)
counterBox.BorderSizePixel = 0
counterBox.Parent = leftColumn
Instance.new("UICorner", counterBox).CornerRadius = UDim.new(0, 12)
local cbs = Instance.new("UIStroke", counterBox)
cbs.Thickness = 2.5
cbs.Color = Color3.fromRGB(75, 30, 115)

local counterLabel = Instance.new("TextLabel")
counterLabel.Size = UDim2.fromScale(1, 1)
counterLabel.BackgroundTransparency = 1
counterLabel.Text = "Total Summoned: 0"
counterLabel.TextColor3 = Color3.fromRGB(255, 225, 80)
counterLabel.TextSize = 16
counterLabel.Font = Enum.Font.FredokaOne
counterLabel.Parent = counterBox

-- ========================================================
-- RIGHT COLUMN: STATUS & 3D RENDERING
-- ========================================================
local statusBox = Instance.new("Frame")
statusBox.Size = UDim2.new(1, 0, 0, 136)
statusBox.Position = UDim2.fromOffset(0, 0)
statusBox.BackgroundColor3 = Color3.fromRGB(45, 18, 72)
statusBox.BorderSizePixel = 0
statusBox.Parent = rightColumn
Instance.new("UICorner", statusBox).CornerRadius = UDim.new(0, 12)
local sbs = Instance.new("UIStroke", statusBox)
sbs.Thickness = 2.5
sbs.Color = Color3.fromRGB(75, 30, 115)

local statusTitle = Instance.new("TextLabel")
statusTitle.Size = UDim2.new(1, -20, 0, 30)
statusTitle.Position = UDim2.fromOffset(10, 8)
statusTitle.BackgroundTransparency = 1
statusTitle.Text = "LOBBY STATUS"
statusTitle.TextColor3 = Color3.fromRGB(255, 235, 120)
statusTitle.TextSize = 14
statusTitle.Font = Enum.Font.FredokaOne
statusTitle.TextXAlignment = Enum.TextXAlignment.Left
statusTitle.Parent = statusBox

local statusLog = Instance.new("TextLabel")
statusLog.Size = UDim2.new(1, -20, 0, 85)
statusLog.Position = UDim2.fromOffset(10, 40)
statusLog.BackgroundTransparency = 1
statusLog.Text = "System Ready\nWaiting for Auto Summon..."
statusLog.TextColor3 = Color3.fromRGB(215, 215, 225)
statusLog.TextSize = 13
statusLog.Font = Enum.Font.FredokaOne
statusLog.TextXAlignment = Enum.TextXAlignment.Left
statusLog.TextYAlignment = Enum.TextYAlignment.Top
statusLog.TextWrapped = true
statusLog.Parent = statusBox

-- 3D Rendering Toggle Button (มุมขวาล่าง)
local render3dBtn = Instance.new("TextButton")
render3dBtn.Size = UDim2.new(0, 115, 0, 32)
render3dBtn.Position = UDim2.new(1, -115, 1, -34)
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

local originalCameraType = Enum.CameraType.Custom
local originalCameraCFrame = nil

render3dBtn.Activated:Connect(function()
    states.Render3DEnabled = not states.Render3DEnabled
    local cam = workspace.CurrentCamera

    if not states.Render3DEnabled then
        pcall(function()
            if cam then
                originalCameraType = cam.CameraType
                originalCameraCFrame = cam.CFrame
                cam.CameraType = Enum.CameraType.Scriptable
                cam.CFrame = CFrame.new(0, 50000, 0)
            end
        end)
        blackoutFrame.Visible = true
        render3dBtn.BackgroundColor3 = Color3.fromRGB(190, 50, 50)
        render3dBtn.Text = "[ 3D: OFF ]"
    else
        pcall(function()
            if cam then
                cam.CameraType = originalCameraType or Enum.CameraType.Custom
                if originalCameraCFrame then
                    cam.CFrame = originalCameraCFrame
                end
            end
        end)
        blackoutFrame.Visible = false
        render3dBtn.BackgroundColor3 = Color3.fromRGB(55, 140, 65)
        render3dBtn.Text = "[ 3D: ON ]"
    end
end)

-- ========================================================
-- AUTO SUMMON EXECUTION LOOP
-- ========================================================
task.spawn(function()
    while Controller.Running do
        task.wait(0.5)

        if states.AutoSummon then
            local hubRemotes = ReplicatedStorage:FindFirstChild("HubRemotes")
            if hubRemotes then
                local remoteName = (states.BannerType == "Event") and "SummonEvent" or "Summon"
                local summonRemote = hubRemotes:FindFirstChild(remoteName)

                if summonRemote and summonRemote:IsA("RemoteFunction") then
                    statusLog.Text = string.format("Summoning [%s Banner] x%d...", states.BannerType, states.RollAmount)
                    
                    local success, result = pcall(function()
                        return summonRemote:InvokeServer(states.RollAmount)
                    end)

                    if success then
                        states.TotalSummons = states.TotalSummons + states.RollAmount
                        counterLabel.Text = "Total Summoned: " .. states.TotalSummons
                        statusLog.Text = string.format("Success: Rolled x%d!\nWaiting for next summon...", states.RollAmount)
                    else
                        statusLog.Text = "Summon Failed: " .. tostring(result)
                    end

                    -- หน่วงเวลา 0.8 วินาที เพื่อไม่ให้เซิร์ฟเวอร์ติด Rate Limit
                    task.wait(0.8)
                else
                    statusLog.Text = "Remote not found: " .. remoteName
                end
            end
        end
    end
end)
