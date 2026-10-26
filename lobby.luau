-- ========================================================
-- CANDY TD : LOBBY HUB (FULL AUTO FIRST WIN & CHALLENGE)
-- ========================================================
repeat task.wait() until game:IsLoaded()

local env = (type(getgenv) == "function" and getgenv()) or _G
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GuiService = game:GetService("GuiService")
local TeleportService = game:GetService("TeleportService")
local VirtualInputManager = game:GetService("VirtualInputManager")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

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

local connError = GuiService.ErrorMessageChanged:Connect(function(errorMessage)
    if Controller.Running and errorMessage and errorMessage ~= "" then
        task.wait(2)
        pcall(function() TeleportService:Teleport(game.PlaceId, player) end)
    end
end)

local bbVirtualUser = nil
pcall(function() bbVirtualUser = game:GetService("VirtualUser") end)
local connIdle = player.Idled:Connect(function()
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

local libUrl = "https://raw.githubusercontent.com/PKNUDG/BehindTheDarkLib/main/BehindTheDarkLib.luau?v=" .. os.time()
local libRaw = game:HttpGet(libUrl)
local libChunk, libErr = loadstring(libRaw)
if not libChunk then
    error("[BehindTheDark] โหลด Library ไม่สำเร็จ: " .. tostring(libErr))
end
local Library = libChunk()

local savedCfg = Library.Settings.Configs or {}

local states = {
    AutoSummon = (savedCfg.AutoSummon ~= nil) and savedCfg.AutoSummon or false,
    BannerType = savedCfg.BannerType or "Standard",
    RollAmount = savedCfg.RollAmount or 10,
    AutoChallenge = (Library.Settings.AutoChallenge ~= nil) and Library.Settings.AutoChallenge or false,
    AutoDelete = {
        Rare = (savedCfg.AutoDelete and savedCfg.AutoDelete.Rare ~= nil) and savedCfg.AutoDelete.Rare or false,
        Epic = (savedCfg.AutoDelete and savedCfg.AutoDelete.Epic ~= nil) and savedCfg.AutoDelete.Epic or false,
        Legendary = (savedCfg.AutoDelete and savedCfg.AutoDelete.Legendary ~= nil) and savedCfg.AutoDelete.Legendary or false
    }
}

local function saveConfigState()
    Library.Settings.AutoChallenge = states.AutoChallenge
    Library.Settings.Configs = {
        AutoSummon = states.AutoSummon,
        BannerType = states.BannerType,
        RollAmount = states.RollAmount,
        AutoDelete = states.AutoDelete
    }
    Library.SaveSettings()
end

local function setServerAutoDelete(rarity: string, enable: boolean)
    local hubRemotes = ReplicatedStorage:FindFirstChild("HubRemotes")
    local setRemote = hubRemotes and hubRemotes:FindFirstChild("SetAutoDelete")
    if setRemote and setRemote:IsA("RemoteFunction") then
        pcall(function()
            setRemote:InvokeServer({ [rarity] = enable })
        end)
    end
end

local function syncAllAutoDelete()
    for rarity, isDel in pairs(states.AutoDelete) do
        if isDel then
            setServerAutoDelete(rarity, true)
            task.wait(0.1)
        end
    end
end

local function buyItemFromTeller(itemId: string, amount: number)
    local tellerRemotes = ReplicatedStorage:FindFirstChild("TellerRemotes")
    local buyRemote = tellerRemotes and tellerRemotes:FindFirstChild("Buy")
    if buyRemote and buyRemote:IsA("RemoteFunction") then
        pcall(function()
            buyRemote:InvokeServer(itemId, amount)
        end)
    end
end

local Window = Library:CreateWindow({
    Title = "BEHIND THE DARK - LOBBY",
    Name = "CandyTD_BehindTheDarkLobby",
    OnUnload = function()
        Controller.Running = false
        if connError then connError:Disconnect() end
        if connIdle then connIdle:Disconnect() end
        _G.CandyTD_LobbyInstance = nil
    end
})
Controller.Gui = Window.Gui

pcall(function()
    local rightRim = Window.RightColumn.Parent.Parent
    if rightRim then rightRim:Destroy() end
end)

-- ฝั่งซ้าย
Window:CreateToggle("Left", "Auto Summon", 0, { On = Color3.fromRGB(255, 110, 80), Off = Color3.fromRGB(120, 120, 130) }, states.AutoSummon, function(v)
    states.AutoSummon = v
    saveConfigState()
    if v then syncAllAutoDelete() end
end)

Window:CreateDropdown("Left", "Banner", 46, { "Standard", "Event" }, states.BannerType, 20, function(selected)
    states.BannerType = selected
    saveConfigState()
end)

Window:CreateDropdown("Left", "Amount", 92, { 10, 1 }, states.RollAmount, 10, function(selected)
    states.RollAmount = tonumber(selected) or 10
    saveConfigState()
end)

Window:CreateToggle("Left", "Delete Rare", 144, { On = Color3.fromRGB(80, 160, 240), Off = Color3.fromRGB(120, 120, 130) }, states.AutoDelete.Rare, function(v)
    states.AutoDelete.Rare = v
    saveConfigState()
    setServerAutoDelete("Rare", v)
end)

Window:CreateToggle("Left", "Delete Epic", 190, { On = Color3.fromRGB(175, 75, 230), Off = Color3.fromRGB(120, 120, 130) }, states.AutoDelete.Epic, function(v)
    states.AutoDelete.Epic = v
    saveConfigState()
    setServerAutoDelete("Epic", v)
end)

Window:CreateToggle("Left", "Delete Legendary", 236, { On = Color3.fromRGB(245, 185, 45), Off = Color3.fromRGB(120, 120, 130) }, states.AutoDelete.Legendary, function(v)
    states.AutoDelete.Legendary = v
    saveConfigState()
    setServerAutoDelete("Legendary", v)
end)

-- ฝั่งขวา (2 กล่องแยก)
local challengeSubTray = Window:CreateSubTray(UDim2.new(0.5, 6, 0, 0), UDim2.new(0.5, -20, 0, 68))

local challengeToggleUpdater = nil
challengeToggleUpdater = Window:CreateToggle(challengeSubTray, "Auto Challenge", 0, { On = Color3.fromRGB(255, 90, 150), Off = Color3.fromRGB(120, 120, 130) }, states.AutoChallenge, function(v)
    states.AutoChallenge = v
    saveConfigState()
end)

-- ตรวจสอบการเปลี่ยนค่าจาก Setting Modal
task.spawn(function()
    while Controller.Running do
        task.wait(0.5)
        if Library.Settings.AutoChallenge ~= states.AutoChallenge then
            states.AutoChallenge = Library.Settings.AutoChallenge
            if challengeToggleUpdater then challengeToggleUpdater(states.AutoChallenge) end
        end
    end
end)

local shopSubTray = Window:CreateSubTray(UDim2.new(0.5, 6, 0, 76), UDim2.new(0.5, -20, 1, -88))

local function createShopActionButton(parentTarget: Instance, text: string, yPos: number, rimColor: Color3, btnColor: Color3, callback: () -> ())
    local shadow = Instance.new("Frame")
    shadow.Size = UDim2.new(1, 0, 0, 44)
    shadow.Position = UDim2.fromOffset(0, yPos)
    shadow.BackgroundColor3 = Color3.fromRGB(16, 3, 26)
    shadow.BorderSizePixel = 0
    shadow.ZIndex = 5
    shadow.Parent = parentTarget
    Instance.new("UICorner", shadow).CornerRadius = UDim.new(0, 14)

    local rim = Instance.new("Frame")
    rim.Size = UDim2.new(1, 0, 0, 41)
    rim.Position = UDim2.fromOffset(0, 0)
    rim.BackgroundColor3 = rimColor
    rim.BorderSizePixel = 0
    rim.ZIndex = 6
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
    btn.ZIndex = 7
    btn.Parent = rim
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 11)
    local bts = Instance.new("UIStroke")
    bts.Parent = btn
    bts.Thickness = 2.5
    bts.Color = Color3.fromRGB(22, 5, 36)

    Library.AttachInteractiveEffects(btn, shadow)
    btn.Activated:Connect(callback)
end

createShopActionButton(shopSubTray, "Buy Trait Crystal x10", 0, Color3.fromRGB(140, 240, 180), Color3.fromRGB(60, 210, 140), function()
    buyItemFromTeller("crystal", 10)
end)

createShopActionButton(shopSubTray, "Buy Unit of Juice x10", 46, Color3.fromRGB(255, 185, 110), Color3.fromRGB(255, 140, 40), function()
    buyItemFromTeller("statroll", 10)
end)

-- Auto Summon Loop
task.spawn(function()
    while Controller.Running do
        task.wait(0.5)
        if states.AutoSummon then
            local hubRemotes = ReplicatedStorage:FindFirstChild("HubRemotes")
            if hubRemotes then
                local remoteName = (states.BannerType == "Event") and "SummonEvent" or "Summon"
                local summonRemote = hubRemotes:FindFirstChild(remoteName)
                if summonRemote and summonRemote:IsA("RemoteFunction") then
                    pcall(function() summonRemote:InvokeServer(states.RollAmount) end)
                    task.wait(0.8)
                end
            end
        end
    end
end)

-- ========================================================
-- AUTO CHALLENGE (TELEPORT TO SPOT, OVERLAY SCAN & EXACT FIRST WIN)
-- ========================================================
local function teleportToChallengeSpot()
    local char = player.Character or player.CharacterAdded:Wait()
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    -- ค้นหาแท่น Challenge หรือ ป้าย TAKE A CHALLENGE ใน workspace
    local targetCFrame = nil
    local promptFound = nil

    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("ProximityPrompt") then
            local actText = (obj.ActionText or ""):upper()
            local objText = (obj.ObjectText or ""):upper()
            if actText:find("CHALLENGE") or objText:find("TRAIN") or objText:find("CHALLENGE") then
                promptFound = obj
                local part = obj.Parent
                if part and part:IsA("BasePart") then
                    targetCFrame = part.CFrame + Vector3.new(0, 3, 0)
                    break
                end
            end
        end
    end

    if not targetCFrame then
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("TextLabel") and obj.Text:upper():find("TAKE A CHALLENGE") then
                local bb = obj:FindFirstAncestorWhichIsA("BillboardGui")
                if bb and bb.Adornee and bb.Adornee:IsA("BasePart") then
                    targetCFrame = bb.Adornee.CFrame + Vector3.new(0, 3, 0)
                    break
                elseif bb and bb.Parent and bb.Parent:IsA("BasePart") then
                    targetCFrame = bb.Parent.CFrame + Vector3.new(0, 3, 0)
                    break
                end
            end
        end
    end

    if targetCFrame then
        local dist = (hrp.Position - targetCFrame.Position).Magnitude
        if dist > 12 then
            hrp.CFrame = targetCFrame
            task.wait(0.4)
        end
    end

    -- Trigger ProximityPrompt ถ้ามี
    if promptFound then
        pcall(function()
            local fireprompt = (rawget(env, "fireproximityprompt") or fireproximityprompt) :: any
            if fireprompt then
                fireprompt(promptFound)
            end
        end)
    end
end

local function triggerButton(btn: GuiButton)
    pcall(function()
        local firesig = (rawget(env, "firesignal") or firesignal) :: any
        if firesig then
            firesig(btn.Activated)
            firesig(btn.MouseButton1Click)
            firesig(btn.MouseButton1Down)
            firesig(btn.MouseButton1Up)
        else
            local absPos = btn.AbsolutePosition
            local absSize = btn.AbsoluteSize
            local clickX = absPos.X + (absSize.X / 2)
            local clickY = absPos.Y + (absSize.Y / 2) + 36
            VirtualInputManager:SendMouseButtonEvent(clickX, clickY, 0, true, game, 1)
            task.wait(0.05)
            VirtualInputManager:SendMouseButtonEvent(clickX, clickY, 0, false, game, 1)
        end
    end)
end

local function findTrainFrame()
    local searchContainers = { playerGui, CoreGui }
    for _, container in ipairs(searchContainers) do
        for _, desc in ipairs(container:GetDescendants()) do
            -- ข้ามพวกป้ายแจ้งเตือนหน้ารถไฟ (HubPrompts / BillboardGui)
            if desc:IsA("TextLabel") and not desc:FindFirstAncestor("HubPrompts") and not desc:FindFirstAncestorWhichIsA("BillboardGui") then
                local txt = desc.Text:upper()
                if txt:find("DUNGEON TRAIN") or txt:find("NEW CARS IN") then
                    local frame = desc:FindFirstAncestorWhichIsA("Frame") or desc.Parent
                    if frame then
                        -- ไต่ขึ้นไปหาหน้าต่างหลักที่เป็น Modal จริงๆ (ขนาดใหญ่)
                        local topModal = frame
                        while topModal.Parent and (topModal.Parent:IsA("Frame") or topModal.Parent:IsA("ScreenGui")) do
                            if topModal.Parent:IsA("ScreenGui") then break end
                            topModal = topModal.Parent
                        end
                        return topModal, container
                    end
                end
            end
        end
    end
    return nil, nil
end

local function findAndPlayFirstWinCar()
    print("[AutoChallenge] เริ่มขั้นตอนค้นหาด่าน First Win...")

    -- 1. วาร์ปเข้าใกล้แท่น Challenge
    teleportToChallengeSpot()

    -- 2. ยิง Remote Funnel เพื่อเปิดหน้าต่าง Train เสมอ
    pcall(function()
        local hubRemotes = ReplicatedStorage:FindFirstChild("HubRemotes")
        local funnel = hubRemotes and hubRemotes:FindFirstChild("Funnel")
        if funnel and funnel:IsA("RemoteEvent") then
            funnel:FireServer("open_train")
        end
    end)
    task.wait(1.5)

    -- ตรวจสอบว่าหน้าต่าง DUNGEON TRAIN ปรากฏขึ้นมาหรือไม่
    local trainFrame, activeGui = findTrainFrame()
    if not trainFrame then
        print("[AutoChallenge] ไม่พบหน้าต่าง DUNGEON TRAIN บนหน้าจอ (กำลังเปิดอีกครั้ง...)")
        return false
    end

    print("[AutoChallenge] ตรวจพบหน้าต่างหลักใน:", trainFrame:GetFullName())

    -- 3. สแกนหาตู้รถไฟที่มีป้าย FIRST WIN
    local targetPlayButton = nil
    local hasAnyFirstWin = false

    -- ค้นหาป้าย FIRST WIN ภายในหน้าต่างหลัก
    for _, desc in ipairs(trainFrame:GetDescendants()) do
        if desc:IsA("TextLabel") and desc.Text:upper():find("FIRST WIN") then
            hasAnyFirstWin = true
            print("[AutoChallenge] ตรวจพบป้ายรางวัล:", desc.Text, "ที่", desc:GetFullName())

            -- ค้นหาการ์ดตู้รถไฟใบนี้ที่มีปุ่ม PLAY
            local carCard = desc.Parent
            local playBtn = nil

            while carCard and carCard ~= trainFrame and carCard ~= activeGui do
                for _, btn in ipairs(carCard:GetDescendants()) do
                    if btn:IsA("TextButton") or btn:IsA("ImageButton") then
                        local btnText = (btn:IsA("TextButton") and btn.Text:upper()) or ""
                        for _, t in ipairs(btn:GetDescendants()) do
                            if t:IsA("TextLabel") then
                                btnText = btnText .. " " .. t.Text:upper()
                            end
                        end
                        if btnText:find("PLAY") then
                            playBtn = btn
                            break
                        end
                    end
                end
                if playBtn then break end
                carCard = carCard.Parent
            end

            if playBtn then
                targetPlayButton = playBtn
                print("[AutoChallenge] เจอปุ่ม PLAY ของตู้ First Win นี้แล้ว:", playBtn:GetFullName())
                break
            end
        end
    end

    -- หากสแกนทั่วทั้งหน้าต่างแล้วยังไม่เจอปุ่ม PLAY จากป้าย FIRST WIN ให้ fallback หาปุ่ม PLAY ตรงๆ
    if not targetPlayButton then
        for _, btn in ipairs(trainFrame:GetDescendants()) do
            if btn:IsA("TextButton") or btn:IsA("ImageButton") then
                local bText = (btn:IsA("TextButton") and btn.Text:upper()) or ""
                for _, t in ipairs(btn:GetDescendants()) do
                    if t:IsA("TextLabel") then
                        bText = bText .. " " .. t.Text:upper()
                    end
                end
                if bText:find("PLAY") then
                    -- เช็คว่าในโซนการ์ดใบนี้มีป้าย FIRST WIN หรือไม่
                    local pCard = btn.Parent
                    local isFirstWinZone = false
                    while pCard and pCard ~= trainFrame do
                        for _, lbl in ipairs(pCard:GetDescendants()) do
                            if lbl:IsA("TextLabel") and lbl.Text:upper():find("FIRST WIN") then
                                isFirstWinZone = true
                                break
                            end
                        end
                        if isFirstWinZone then break end
                        pCard = pCard.Parent
                    end

                    if isFirstWinZone then
                        targetPlayButton = btn
                        hasAnyFirstWin = true
                        print("[AutoChallenge] เจอปุ่ม PLAY โดยการจับคู่การ์ด:", btn:GetFullName())
                        break
                    end
                end
            end
        end
    end

    -- หากสแกนแล้วไม่พบ FIRST WIN เลย
    if not hasAnyFirstWin then
        local countdownText = ""
        for _, l in ipairs(trainFrame:GetDescendants()) do
            if l:IsA("TextLabel") and l.Text:upper():find("NEW CARS IN") then
                countdownText = l.Text
                break
            end
        end
        print("[AutoChallenge] รับของ First Win ครบหมดทุกตู้แล้ว! " .. countdownText)
        return false
    end

    -- 4. สั่งเริ่มเกมโดยการกดปุ่ม PLAY ที่ถูกต้อง
    if targetPlayButton then
        print("[AutoChallenge] กำลังกดปุ่ม PLAY เพื่อเข้าห้อง...")
        triggerButton(targetPlayButton)
        task.wait(1.5)

        -- ตรวจสอบและยิง StartMatch หรือ Remote เข้าเกม
        pcall(function()
            local hubRemotes = ReplicatedStorage:FindFirstChild("HubRemotes")
            local startMatch = hubRemotes and hubRemotes:FindFirstChild("StartMatch")
            if startMatch and startMatch:IsA("RemoteFunction") then
                startMatch:InvokeServer()
            end
        end)

        -- เช็คปุ่ม START หรือ START MATCH บน UI ถ้ามี
        if activeGui then
            for _, btn in ipairs(activeGui:GetDescendants()) do
                if (btn:IsA("TextButton") or btn:IsA("ImageButton")) and btn.Visible then
                    local bText = (btn:IsA("TextButton") and btn.Text:upper()) or ""
                    for _, t in ipairs(btn:GetDescendants()) do
                        if t:IsA("TextLabel") and t.Visible then
                            bText = bText .. " " .. t.Text:upper()
                        end
                    end
                    if bText:find("START") and not bText:find("RESTART") then
                        print("[AutoChallenge] กำลังกดปุ่มยืนยัน START:", btn:GetFullName())
                        triggerButton(btn)
                        break
                    end
                end
            end
        end

        return true
    end

    return false
end

task.spawn(function()
    while Controller.Running do
        task.wait(2)
        if states.AutoChallenge then
            findAndPlayFirstWinCar()
            task.wait(4)
        end
    end
end)
