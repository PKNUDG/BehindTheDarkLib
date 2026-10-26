-- ========================================================
-- CANDY TD : LOBBY HUB (POWERED BY BEHINDTHEDARKLIB)
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

-- ========================================================
-- ANTI-AFK & RECONNECT
-- ========================================================
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

-- ========================================================
-- STATES
-- ========================================================
local states = {
    AutoSummon = false,
    BannerType = "Standard",
    RollAmount = 10,
    AutoChallenge = false,
    AutoDelete = {
        Rare = false,
        Epic = false,
        Legendary = false
    }
}

-- Remote Action Helpers
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

-- ========================================================
-- ฝั่งซ้าย: AUTO SUMMON & AUTO DELETE SETTINGS
-- ========================================================
Window:CreateToggle("Left", "Auto Summon", 0, { On = Color3.fromRGB(255, 110, 80), Off = Color3.fromRGB(120, 120, 130) }, false, function(v)
    states.AutoSummon = v
    if v then
        syncAllAutoDelete()
    end
end)

Window:CreateDropdown("Left", "Banner", 46, { "Standard", "Event" }, states.BannerType, 20, function(selected)
    states.BannerType = selected
end)

Window:CreateDropdown("Left", "Amount", 92, { 10, 1 }, states.RollAmount, 10, function(selected)
    states.RollAmount = tonumber(selected) or 10
end)

-- Auto Delete Toggles
Window:CreateToggle("Left", "Delete Rare", 144, { On = Color3.fromRGB(80, 160, 240), Off = Color3.fromRGB(120, 120, 130) }, false, function(v)
    states.AutoDelete.Rare = v
    setServerAutoDelete("Rare", v)
end)

Window:CreateToggle("Left", "Delete Epic", 190, { On = Color3.fromRGB(175, 75, 230), Off = Color3.fromRGB(120, 120, 130) }, false, function(v)
    states.AutoDelete.Epic = v
    setServerAutoDelete("Epic", v)
end)

Window:CreateToggle("Left", "Delete Legendary", 236, { On = Color3.fromRGB(245, 185, 45), Off = Color3.fromRGB(120, 120, 130) }, false, function(v)
    states.AutoDelete.Legendary = v
    setServerAutoDelete("Legendary", v)
end)

-- ========================================================
-- ฝั่งขวา: AUTO CHALLENGE & CANDY SHOP INSTANT BUY
-- ========================================================
local rightCol = Window:GetColumn("Right")

-- Toggle สำหรับ Auto Challenge (เพิ่มเข้ามาใหม่)
Window:CreateToggle("Right", "Auto Challenge", 0, { On = Color3.fromRGB(255, 90, 150), Off = Color3.fromRGB(120, 120, 130) }, false, function(v)
    states.AutoChallenge = v
end)

local function createInstantBuyButton(text: string, yPos: number, btnColor: Color3, callback: () -> ())
    local base = Instance.new("Frame")
    base.Size = UDim2.new(1, 0, 0, 38)
    base.Position = UDim2.fromOffset(0, yPos)
    base.BackgroundColor3 = Color3.fromRGB(35, 10, 55)
    base.BorderSizePixel = 0
    base.ZIndex = 4
    base.Parent = rightCol
    Instance.new("UICorner", base).CornerRadius = UDim.new(1, 0)
    local bs = Instance.new("UIStroke", base)
    bs.Thickness = 2.5
    bs.Color = Color3.fromRGB(35, 10, 55)

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -2, 1, -4)
    btn.Position = UDim2.fromOffset(1, 1)
    btn.BackgroundColor3 = btnColor
    btn.BorderSizePixel = 0
    btn.AutoButtonColor = false
    btn.Text = ""
    btn.ClipsDescendants = true
    btn.ZIndex = 5
    btn.Parent = base
    Instance.new("UICorner", btn).CornerRadius = UDim.new(1, 0)

    local gloss = Instance.new("Frame")
    gloss.Size = UDim2.new(1, -14, 0.45, 0)
    gloss.Position = UDim2.fromOffset(7, 1)
    gloss.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    gloss.BackgroundTransparency = 0.72
    gloss.BorderSizePixel = 0
    gloss.ZIndex = 6
    gloss.Parent = btn
    Instance.new("UICorner", gloss).CornerRadius = UDim.new(1, 0)

    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextSize = 14
    label.Font = Enum.Font.FredokaOne
    label.ZIndex = 7
    label.Parent = btn
    local ts = Instance.new("UIStroke", label)
    ts.Thickness = 2.5
    ts.Color = Color3.fromRGB(40, 10, 60)

    Library.AttachInteractiveEffects(btn, UDim2.fromOffset(1, 1))
    btn.Activated:Connect(callback)
end

createInstantBuyButton("Buy Trait Crystal x10", 46, Color3.fromRGB(60, 210, 140), function()
    buyItemFromTeller("crystal", 10)
end)

createInstantBuyButton("Buy Unit of Juice x10", 92, Color3.fromRGB(255, 140, 40), function()
    buyItemFromTeller("statroll", 10)
end)

-- ========================================================
-- AUTO SUMMON LOOP
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
                    pcall(function() summonRemote:InvokeServer(states.RollAmount) end)
                    task.wait(0.8)
                end
            end
        end
    end
end)

-- ========================================================
-- AUTO CHALLENGE LOOP
-- ========================================================
task.spawn(function()
    while Controller.Running do
        task.wait(1.5)
        if states.AutoChallenge then
            pcall(function()
                local hubRemotes = ReplicatedStorage:FindFirstChild("HubRemotes")
                if hubRemotes then
                    -- 1. เปิด Training / Challenge
                    local funnel = hubRemotes:FindFirstChild("Funnel")
                    if funnel and funnel:IsA("RemoteEvent") then
                        funnel:FireServer("open_train")
                        task.wait(0.3)
                    end

                    -- 2. สร้างห้องแมตช์
                    local createMatch = hubRemotes:FindFirstChild("CreateMatch")
                    if createMatch and createMatch:IsA("RemoteFunction") then
                        createMatch:InvokeServer(2, "c996114_1", false)
                        task.wait(0.3)
                    end

                    -- 3. เริ่มเกม/เริ่มชาเลนจ์
                    local startMatch = hubRemotes:FindFirstChild("StartMatch")
                    if startMatch and startMatch:IsA("RemoteFunction") then
                        startMatch:InvokeServer()
                    end
                end
            end)
            task.wait(3)
        end
    end
end)
