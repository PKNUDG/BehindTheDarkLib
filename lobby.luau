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
-- STATES
-- ========================================================
local states = {
    AutoSummon = false,
    BannerType = "Standard",
    RollAmount = 10,
    AutoDelete = {
        Rare = false,
        Epic = false,
        Legendary = false
    },
    AutoBuyCrystal = false,
    BuyCrystalAmount = 10
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
    Name = "CandyTD_BehindTheDarkLobby"
})
Controller.Gui = Window.Gui

-- ========================================================
-- ฝั่งซ้าย: AUTO SUMMON & AUTO DELETE SETTINGS
-- ========================================================
Window:CreateToggle("Left", "Auto Summon", 0, { On = Color3.fromRGB(255, 110, 80), Off = Color3.fromRGB(120, 120, 130) }, false, function(v)
    states.AutoSummon = v
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
-- ฝั่งขวา: CANDY SHOP (TRAIT CRYSTAL) & ACTIONS
-- ========================================================
Window:CreateToggle("Right", "Auto Buy Crystal", 0, { On = Color3.fromRGB(60, 210, 140), Off = Color3.fromRGB(120, 120, 130) }, false, function(v)
    states.AutoBuyCrystal = v
end)

Window:CreateDropdown("Right", "Crystal Amount", 46, { 10, 1 }, states.BuyCrystalAmount, 20, function(selected)
    states.BuyCrystalAmount = tonumber(selected) or 10
end)

-- ปุ่มคลิกซื้อทันที (Manual Buy Button)
local rightCol = Window:GetColumn("Right")
local buyOnceBase = Instance.new("Frame")
buyOnceBase.Size = UDim2.new(1, 0, 0, 38)
buyOnceBase.Position = UDim2.fromOffset(0, 96)
buyOnceBase.BackgroundColor3 = Color3.fromRGB(35, 10, 55)
buyOnceBase.BorderSizePixel = 0
buyOnceBase.ZIndex = 4
buyOnceBase.Parent = rightCol
Instance.new("UICorner", buyOnceBase).CornerRadius = UDim.new(1, 0)

local buyOnceBtn = Instance.new("TextButton")
buyOnceBtn.Size = UDim2.new(1, -2, 1, -4)
buyOnceBtn.Position = UDim2.fromOffset(1, 1)
buyOnceBtn.BackgroundColor3 = Color3.fromRGB(160, 75, 235)
buyOnceBtn.BorderSizePixel = 0
buyOnceBtn.AutoButtonColor = false
buyOnceBtn.Text = ""
buyOnceBtn.ClipsDescendants = true
buyOnceBtn.ZIndex = 5
buyOnceBtn.Parent = buyOnceBase
Instance.new("UICorner", buyOnceBtn).CornerRadius = UDim.new(1, 0)

local buyOnceLabel = Instance.new("TextLabel")
buyOnceLabel.Size = UDim2.fromScale(1, 1)
buyOnceLabel.BackgroundTransparency = 1
buyOnceLabel.Text = "Buy Trait Crystal (Once)"
buyOnceLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
buyOnceLabel.TextSize = 14
buyOnceLabel.Font = Enum.Font.FredokaOne
buyOnceLabel.ZIndex = 6
buyOnceLabel.Parent = buyOnceBtn
local bols = Instance.new("UIStroke", buyOnceLabel)
bols.Thickness = 2.5
bols.Color = Color3.fromRGB(40, 10, 60)

Library.AttachInteractiveEffects(buyOnceBtn, UDim2.fromOffset(1, 1))

buyOnceBtn.Activated:Connect(function()
    local tellerRemotes = ReplicatedStorage:FindFirstChild("TellerRemotes")
    local buyRemote = tellerRemotes and tellerRemotes:FindFirstChild("Buy")
    if buyRemote and buyRemote:IsA("RemoteFunction") then
        pcall(function()
            buyRemote:InvokeServer("crystal", states.BuyCrystalAmount)
        end)
    end
end)

-- ========================================================
-- BACKGROUND EXECUTION LOOPS
-- ========================================================
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

-- Auto Buy Crystal Loop
task.spawn(function()
    while Controller.Running do
        task.wait(1)
        if states.AutoBuyCrystal then
            local tellerRemotes = ReplicatedStorage:FindFirstChild("TellerRemotes")
            local buyRemote = tellerRemotes and tellerRemotes:FindFirstChild("Buy")
            if buyRemote and buyRemote:IsA("RemoteFunction") then
                pcall(function()
                    buyRemote:InvokeServer("crystal", states.BuyCrystalAmount)
                end)
                task.wait(1.5)
            end
        end
    end
end)
