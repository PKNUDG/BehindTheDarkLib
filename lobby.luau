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
-- โหลดและใช้งาน BEHINDTHEDARKLIB
-- ========================================================
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
    AutoChallenge = (savedCfg.AutoChallenge ~= nil) and savedCfg.AutoChallenge or false,
    AutoDelete = {
        Rare = (savedCfg.AutoDelete and savedCfg.AutoDelete.Rare ~= nil) and savedCfg.AutoDelete.Rare or false,
        Epic = (savedCfg.AutoDelete and savedCfg.AutoDelete.Epic ~= nil) and savedCfg.AutoDelete.Epic or false,
        Legendary = (savedCfg.AutoDelete and savedCfg.AutoDelete.Legendary ~= nil) and savedCfg.AutoDelete.Legendary or false
    }
}

local function saveConfigState()
    Library.Settings.Configs = {
        AutoSummon = states.AutoSummon,
        BannerType = states.BannerType,
        RollAmount = states.RollAmount,
        AutoChallenge = states.AutoChallenge,
        AutoDelete = states.AutoDelete
    }
    Library.SaveSettings()
end

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

-- ซ่อนกล่องพื้นหลังรวมเดิมของฝั่งขวาเพื่อไม่ให้เกิดการซ้อนทับ
if Window.RightColumn and Window.RightColumn.Parent and Window.RightColumn.Parent.Parent then
    Window.RightColumn.Parent.Parent.Visible = false
end

-- ========================================================
-- ฝั่งซ้าย: AUTO SUMMON & AUTO DELETE SETTINGS
-- ========================================================
Window:CreateToggle("Left", "Auto Summon", 0, { On = Color3.fromRGB(255, 110, 80), Off = Color3.fromRGB(120, 120, 130) }, states.AutoSummon, function(v)
    states.AutoSummon = v
    saveConfigState()
    if v then
        syncAllAutoDelete()
    end
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

-- ========================================================
-- ฝั่งขวา: กล่องเดี่ยวแยกอิสระ (CHALLENGE & CANDY SHOP TRAY)
-- ========================================================
local rightSubTray = Window:CreateSubTray(UDim2.new(0.5, 6, 0, 0), UDim2.new(0.5, -20, 0, 154))

-- 1. ปุ่ม Auto Challenge 3D Toggle
Window:CreateToggle(rightSubTray, "Auto Challenge", 0, { On = Color3.fromRGB(255, 90, 150), Off = Color3.fromRGB(120, 120, 130) }, states.AutoChallenge, function(v)
    states.AutoChallenge = v
    saveConfigState()
end)

-- 2. ฟังก์ชันสร้างปุ่มซื้อของด่วนแบบ 3D มาตรฐาน
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
    btn.ZIndex = 7
    btn.Parent = rim
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 11)
    local bts = Instance.new("UIStroke", btn)
    bts.Thickness = 2.5
    bts.Color = Color3.fromRGB(22, 5, 36)

    Library.AttachInteractiveEffects(btn, shadow)
    btn.Activated:Connect(callback)
end

createShopActionButton(rightSubTray, "Buy Trait Crystal x10", 46, Color3.fromRGB(140, 240, 180), Color3.fromRGB(60, 210, 140), function()
    buyItemFromTeller("crystal", 10)
end)

createShopActionButton(rightSubTray, "Buy Unit of Juice x10", 92, Color3.fromRGB(255, 185, 110), Color3.fromRGB(255, 140, 40), function()
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
