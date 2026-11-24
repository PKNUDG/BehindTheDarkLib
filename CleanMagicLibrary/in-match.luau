-- ========================================================
-- CLEAN THE MAGIC LIBRARY : ALL-IN-ONE AUTOMATION (IN-MATCH)
-- Auto Books + Auto Gems (Dedicated Toggle) + Auto Upgrades (Dual Priority & Balanced)
-- Robust Single-Instance Controller & Smart Front-Facing Shelving (Room Center Safe Zone)
-- Focused Single-Shelf Rush (จบทีละตู้เพื่อ Spell Points ไวสุด) + True Placed Progress Tracking
-- Ultra-Fast Zero-Delay Shelving & Dynamic PickUp Retry Loop
-- Powered by BehindTheDarkLib & Zap Network Protocol
-- ========================================================
repeat task.wait() until game:IsLoaded()

-- --------------------------------------------------------
-- 0. CLEANUP EVERY OLD SCRIPT INSTANCE & CORRESPONDING GUIS
-- --------------------------------------------------------
local GUI_NAME = "CleanMagic_FullAuto_Hub"
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

local currentToken = tick()
_G.CleanMagic_CurrentToken = currentToken

if _G.CleanMagic_RunningInstance then
    pcall(function()
        _G.CleanMagic_RunningInstance.Running = false
        if _G.CleanMagic_RunningInstance.Cleanup then
            _G.CleanMagic_RunningInstance.Cleanup()
        end
    end)
end

pcall(function()
    for _, g in ipairs(CoreGui:GetChildren()) do
        if g.Name == GUI_NAME or g.Name:find("CleanMagic_") or g.Name:find("PowerUpPopup") or g.Name:find("SpellPopup") then
            g:Destroy()
        end
    end
    local pGui = player:FindFirstChild("PlayerGui")
    if pGui then
        for _, g in ipairs(pGui:GetChildren()) do
            if g.Name == GUI_NAME or g.Name:find("CleanMagic_") or g.Name:find("PowerUpPopup") or g.Name:find("SpellPopup") then
                g:Destroy()
            end
        end
    end
end)

local ScriptInstance = {
    Running = true,
    Token = currentToken
}
_G.CleanMagic_RunningInstance = ScriptInstance

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local HttpService = game:GetService("HttpService")

local character = player.Character or player.CharacterAdded:Wait()
player.CharacterAdded:Connect(function(char)
    character = char
end)

-- --------------------------------------------------------
-- 1. LOAD BEHIND THE DARK UI LIBRARY
-- --------------------------------------------------------
local libUrl = "https://raw.githubusercontent.com/PKNUDG/BehindTheDarkLib/main/BehindTheDarkLib.luau?v=" .. os.time()
local libRaw = game:HttpGet(libUrl)
local libChunk, libErr = loadstring(libRaw)
if not libChunk then
    error("[BehindTheDark] Failed to load library: " .. tostring(libErr))
end
local Library = libChunk()

-- --------------------------------------------------------
-- 2. GAME SERVICES & MODULES
-- --------------------------------------------------------
local Network = nil
local Charm = nil
local LibraryState = nil
local WizardState = nil
local UpgradesConfig = nil
local LooseLib = nil
local ModeLib = nil

pcall(function()
    Network = require(ReplicatedStorage:WaitForChild("Network"))
    Charm = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Charm"))
    LibraryState = require(ReplicatedStorage:WaitForChild("States"):WaitForChild("Library"))
    WizardState = require(ReplicatedStorage:WaitForChild("States"):WaitForChild("Wizard"))
    UpgradesConfig = require(ReplicatedStorage:WaitForChild("_Shared"):WaitForChild("Config"):WaitForChild("Upgrades"))
    LooseLib = require(ReplicatedStorage:WaitForChild("Lib"):WaitForChild("Loose"))
    ModeLib = require(ReplicatedStorage:WaitForChild("Lib"):WaitForChild("Mode"))
end)

-- --------------------------------------------------------
-- 3. SETTINGS & CONFIG PERSISTENCE
-- --------------------------------------------------------
local SETTINGS_FILE = "CleanMagic_Settings.json"

local PURE_POWERUP_DEFAULT = {
    "Extension",   -- เพิ่มความจุหนังสือ (Capacity)
    "Haste",       -- วิ่งเร็วขึ้น (Speed)
    "Owls",        -- นกช่วยเก็บ (Familiars)
    "Reach",       -- ระยะหยิบหนังสือ (Reach)
    "Levitation"   -- กระโดดสูง (Jump)
}

local ALL_SPELL_IDS = {
    "Summon", "March", "Volley", "Stacking", "Cloning",
    "Vortex", "Reveal", "Seek", "Sort", "OwlFlock",
    "ShelfFill", "Sonar", "Teleport", "Portal", "Ending", "Echo"
}

local DefaultConfig = {
    AutoFarm = false,     -- ฟาร์มหนังสือส่งตู้
    AutoGems = false,     -- ฟาร์มเก็บเพชร (แยกปุ่มอิสระ)
    AutoSkill = false,    -- กดใช้สกิลอัตโนมัติ (เฉพาะสกิลที่ติดตั้ง)
    BookESP = false,      -- Dynamic Series Book & Shelf ESP
    AutoUpgrade = false,  -- อัปเกรดอัตโนมัติ
    AutoSkillCheckboxes = {}, -- สกิลในโหลดเอาท์ที่เปิดใช้งาน { [id] = true/false }
    AutoSkillOrder = {},      -- ลำดับการกดสกิล { id1, id2, ... }
    PowerUpCheckboxes = {
        ["Extension"] = true,
        ["Haste"] = true,
        ["Owls"] = true,
        ["Reach"] = true,
        ["Levitation"] = true
    },
    SpellCheckboxes = {
        ["Summon"] = true,
        ["March"] = true,
        ["Volley"] = true,
        ["Stacking"] = false,
        ["Cloning"] = false,
        ["Vortex"] = false,
        ["Reveal"] = false,
        ["Seek"] = false,
        ["Sort"] = false,
        ["OwlFlock"] = false,
        ["ShelfFill"] = false,
        ["Sonar"] = false,
        ["Teleport"] = false,
        ["Portal"] = false,
        ["Ending"] = false,
        ["Echo"] = false
    }
}

local Config = table.clone(DefaultConfig)

local function saveConfig()
    local wf = (type(writefile) == "function" and writefile) or nil
    if wf then
        pcall(function()
            local data = HttpService:JSONEncode(Config)
            wf(SETTINGS_FILE, data)
        end)
    end
end

local function loadConfig()
    local rf = (type(readfile) == "function" and readfile) or nil
    if rf then
        local ok, data = pcall(rf, SETTINGS_FILE)
        if ok and data and data ~= "" then
            local decOk, parsed = pcall(HttpService.JSONDecode, HttpService, data)
            if decOk and type(parsed) == "table" then
                for k, v in pairs(parsed) do
                    Config[k] = v
                end
                Config.AutoSkillCheckboxes = Config.AutoSkillCheckboxes or {}
                Config.AutoSkillOrder = Config.AutoSkillOrder or {}
                Config.PowerUpCheckboxes = Config.PowerUpCheckboxes or DefaultConfig.PowerUpCheckboxes
                Config.SpellCheckboxes = Config.SpellCheckboxes or DefaultConfig.SpellCheckboxes
            end
        end
    end
end

loadConfig()

-- --------------------------------------------------------
-- 4. UTILITIES & REAL GAME STATE READERS
-- --------------------------------------------------------
local function getRootPart(): BasePart?
    local char = player.Character
    if not char then return nil end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if humanoid and humanoid.Health > 0 then
        return humanoid.RootPart or char:FindFirstChild("HumanoidRootPart")
    end
    return char:FindFirstChild("HumanoidRootPart")
end

local function getMaxCapacity(): number
    if Charm and WizardState and WizardState.Resolved then
        local wiz = Charm.peek(WizardState.Resolved)
        if wiz and wiz.Capacity then
            return tonumber(wiz.Capacity) or 1
        end
    end
    return 7
end

local function getTargetCopies(): number
    if ModeLib and typeof(ModeLib.Copies) == "function" then
        local copies = ModeLib.Copies()
        if type(copies) == "number" then return copies end
    end
    return 28
end

local function getCarriedBooks(): {Instance}
    if Charm and LibraryState and LibraryState.Carried then
        local carried = Charm.peek(LibraryState.Carried)
        if type(carried) == "table" then return carried end
    end
    return {}
end

-- อ่านจำนวนหนังสือที่ใส่ในตู้จริงจาก State Placed ของเกม (แม่นยำ 100%)
local function getPlacedForSeries(series: string): number
    if Charm and LibraryState and LibraryState.Placed then
        local placedMap = Charm.peek(LibraryState.Placed)
        if type(placedMap) == "table" and placedMap[series] then
            return tonumber(placedMap[series]) or 0
        end
    end
    return 0
end

local function isShelfCompleted(series: string): boolean
    return getPlacedForSeries(series) >= getTargetCopies()
end

local function isBookAvailable(book: Instance): boolean
    if not book:IsA("BasePart") then return false end
    if book:GetAttribute("Placed") then return false end

    local s = book:GetAttribute("Series")
    if not s or isShelfCompleted(s) then return false end

    if LooseLib and typeof(LooseLib.Is) == "function" then
        if not LooseLib.Is(book) then
            return false
        end
    end

    if book:GetAttribute("Carrier") ~= nil then return false end
    if book:GetAttribute("Owl") ~= nil then return false end
    if book:GetAttribute("WalkEnd") ~= nil then return false end
    if book:GetAttribute("Target") ~= nil then return false end

    return true
end

local function findShelfBySeries(series: string): BasePart?
    for _, shelf in ipairs(CollectionService:GetTagged("Shelf")) do
        if shelf:IsA("BasePart") and shelf:GetAttribute("Series") == series then
            return shelf
        end
    end
    return nil
end

-- พิกัดยืนหน้าตู้ที่ปลอดภัย 100%: คำนวณเวกเตอร์ 8 สตัดมุ่งหน้าเข้าสู่โซนกลางห้อง (ไม่ติดกำแพงหลังตู้ ไม่ตก Void)
local function getShelfFrontCFrame(shelf: BasePart): CFrame
    local secModel = shelf:FindFirstAncestorOfClass("Model")
    if secModel and secModel.Parent and secModel.Parent.Name ~= "Sections" then
        local anc = shelf.Parent
        while anc and anc.Parent and anc.Parent.Name ~= "Sections" do
            anc = anc.Parent
        end
        if anc and anc.Parent and anc.Parent.Name == "Sections" then
            secModel = anc
        end
    end

    local roomCenter = secModel and secModel:GetPivot().Position or Vector3.new(-18, shelf.Position.Y, 0)
    local dirToRoomCenter = (Vector3.new(roomCenter.X, shelf.Position.Y, roomCenter.Z) - shelf.Position)

    local safePos
    if dirToRoomCenter.Magnitude > 0.1 then
        safePos = shelf.Position + dirToRoomCenter.Unit * 8
    else
        safePos = shelf.Position + shelf.CFrame.LookVector * 8
    end

    safePos = Vector3.new(safePos.X, shelf.Position.Y - 0.93, safePos.Z)
    return CFrame.new(safePos, Vector3.new(shelf.Position.X, safePos.Y, shelf.Position.Z))
end

-- เก็บ Gem ละแวกใกล้เคียงแบบ Fast Sweep (ทำงานเมื่อเปิด AutoGems)
local function sweepNearbyGems(maxDist: number?)
    if not Config.AutoGems or not Network or not Network.collectGem then return end
    local root = getRootPart()
    if not root then return end
    local gemsFolder = Workspace:FindFirstChild("Gems")
    if not gemsFolder then return end

    local range = maxDist or 18
    for _, gem in ipairs(gemsFolder:GetChildren()) do
        if gem and gem.Parent and gem:IsA("Model") then
            local dist = (gem:GetPivot().Position - root.Position).Magnitude
            if dist <= range then
                pcall(function()
                    Network.collectGem.call(gem)
                end)
            end
        end
    end
end

-- เก็บหนังสือแบบ Dynamic Fast-Retry (สปีดสูงสุด Hyper-Speed ไม่รอดีเลย์)
local function fastPickUpBook(root: BasePart, book: Instance): boolean
    if not book or not book.Parent or not Network or not Network.pickUp then return false end
    root.CFrame = CFrame.new(book.Position + Vector3.new(0, 1.2, 0))
    sweepNearbyGems(25)

    local startT = os.clock()
    while (os.clock() - startT) < 0.12 and book.Parent and ScriptInstance.Running and _G.CleanMagic_CurrentToken == currentToken do
        local res = Network.pickUp.call(book)
        if res and res.status == "Ok" then
            return true
        elseif res and (res.status == "Full" or res.status == "TooMany") then
            -- หากเซิร์ฟเวอร์แจ้งว่ามือเต็มแล้ว ให้ตัดจบเพื่อไปส่งตู้ทันที
            return false
        end
        task.wait()
    end
    return false
end

-- --------------------------------------------------------
-- 5. FOCUSED SINGLE-SHELF RUSH (ฟาร์มจบทีละตู้ / ทีละห้อง เพื่อ SPELL POINTS ไวสุด)
-- --------------------------------------------------------
local isFarming = false
local currentTargetSeries = nil
local currentTargetRoom = nil

local function getShelfRoom(shelf: BasePart): Instance?
    local secModel = shelf:FindFirstAncestorOfClass("Model")
    if secModel and secModel.Parent and secModel.Parent.Name ~= "Sections" then
        local anc = shelf.Parent
        while anc and anc.Parent and anc.Parent.Name ~= "Sections" do
            anc = anc.Parent
        end
        if anc and anc.Parent and anc.Parent.Name == "Sections" then
            secModel = anc
        end
    end
    return secModel
end

local function getBestTargetSeries(looseBooks: {Instance}): string?
    local targetCopies = getTargetCopies()
    local shelves = CollectionService:GetTagged("Shelf")
    local candidates = {}

    local looseCounts = {}
    for _, b in ipairs(looseBooks) do
        if isBookAvailable(b) then
            local s = b:GetAttribute("Series")
            if s then
                looseCounts[s] = (looseCounts[s] or 0) + 1
            end
        end
    end

    for _, sh in ipairs(shelves) do
        if sh:IsA("BasePart") then
            local series = sh:GetAttribute("Series")
            if series then
                local placed = getPlacedForSeries(series)
                local needed = targetCopies - placed
                local available = looseCounts[series] or 0

                if needed > 0 and available > 0 then
                    local room = getShelfRoom(sh)
                    table.insert(candidates, {
                        series = series,
                        needed = needed,
                        placed = placed,
                        available = available,
                        room = room
                    })
                end
            end
        end
    end

    if #candidates == 0 then return nil end

    -- ลำดับความสำคัญ:
    -- 1. ถ้ามีห้องเป้าหมายเดิมที่ยังไม่เสร็จ ให้เน้นตู้ในห้องเดิมก่อน (เคลียร์ทีละห้อง)
    -- 2. เลือกตู้ที่ใกล้เต็มที่สุด (needed น้อยสุด)
    table.sort(candidates, function(a, b)
        if currentTargetRoom and (a.room == currentTargetRoom) ~= (b.room == currentTargetRoom) then
            return a.room == currentTargetRoom
        end
        return a.needed < b.needed
    end)

    currentTargetRoom = candidates[1].room
    return candidates[1].series
end

local function processFarmStep()
    if isFarming or not Config.AutoFarm or not ScriptInstance.Running or _G.CleanMagic_CurrentToken ~= currentToken then return end
    isFarming = true

    local root = getRootPart()
    if not root then
        isFarming = false
        return
    end

    local carried = getCarriedBooks()
    local maxCapacity = getMaxCapacity()
    local targetCopies = getTargetCopies()
    local booksFolder = Workspace:FindFirstChild("Books")
    local looseBooks = booksFolder and booksFolder:GetChildren() or {}

    -- [กรณีที่ 1]: มีหนังสืออยู่ในมือ
    if #carried > 0 then
        local carriedSeries = carried[1]:GetAttribute("Series")
        local currentShelfPlaced = carriedSeries and getPlacedForSeries(carriedSeries) or 0
        local shelfNeeded = math.max(0, targetCopies - currentShelfPlaced)

        -- 1.1 ถ้าในมือยังไม่เต็มความจุ และตู้ยังต้องการหนังสือเพิ่มอีก ให้หาซีรีส์เดิมมาเก็บต่อ (ห้ามเก็บซีรีส์อื่นปน)
        if #carried < maxCapacity and #carried < shelfNeeded and carriedSeries and not isShelfCompleted(carriedSeries) then
            local sameSeriesBook = nil
            local bestDist = math.huge
            local myPos = root.Position

            for _, b in ipairs(looseBooks) do
                if isBookAvailable(b) and b:GetAttribute("Series") == carriedSeries then
                    local d = (b.Position - myPos).Magnitude
                    if d < bestDist then
                        bestDist = d
                        sameSeriesBook = b
                    end
                end
            end

            if sameSeriesBook then
                local picked = fastPickUpBook(root, sameSeriesBook)
                if picked then
                    isFarming = false
                    return
                end
                -- หากหยิบไม่สำเร็จ ให้ไหลลงไป 1.2 เพื่อไปส่งตู้ทันที
            end
        end

        -- 1.2 วาปไปหน้าตู้และส่งหนังสือเข้าตู้แบบ Synchronous Rapid Zero-Delay (เสร็จไวระดับมิลลิวินาที ไม่ข้ามตู้)
        local targetShelf = carriedSeries and findShelfBySeries(carriedSeries)
        if targetShelf then
            root.CFrame = getShelfFrontCFrame(targetShelf)
            sweepNearbyGems(25)

            local maxShelveAttempts = math.max(25, #carried * 3 + 10)
            local attempts = 0
            while #getCarriedBooks() > 0 and attempts < maxShelveAttempts and ScriptInstance.Running and _G.CleanMagic_CurrentToken == currentToken do
                attempts += 1

                local currentCarried = getCarriedBooks()
                if #currentCarried == 0 then break end

                local topBook = currentCarried[1]
                local topSeries = topBook and topBook:GetAttribute("Series") or carriedSeries
                local curShelf = topSeries and findShelfBySeries(topSeries) or targetShelf

                if curShelf then
                    if (root.Position - curShelf.Position).Magnitude > 26 then
                        root.CFrame = getShelfFrontCFrame(curShelf)
                    end

                    local ok, res = pcall(function()
                        return Network.shelve.call(curShelf)
                    end)

                    -- หากส่งผิดตู้เพราะมีเล่มคละซีรีส์หลุดมา ให้รีบย้ายไปตู้ที่ถูกต้อง
                    if ok and type(res) == "table" and res.status == "WrongShelf" and res.series then
                        local correctShelf = findShelfBySeries(res.series)
                        if correctShelf then
                            root.CFrame = getShelfFrontCFrame(correctShelf)
                            pcall(function()
                                Network.shelve.call(correctShelf)
                            end)
                        end
                    end
                end
                task.wait(0.02)
            end

            if carriedSeries and isShelfCompleted(carriedSeries) then
                print(string.format("[Clean Magic] Shelf %s Completed! 1 Spell Point Earned!", carriedSeries))
                currentTargetSeries = nil
            end
        end
        isFarming = false
        return
    end

    -- [กรณีที่ 2]: หากมือว่าง ให้ล็อคเป้าหมายที่ "ตู้เดิมในห้องเดิมที่ยังไม่เต็ม"
    if not currentTargetSeries or isShelfCompleted(currentTargetSeries) then
        currentTargetSeries = getBestTargetSeries(looseBooks)
    end

    if currentTargetSeries then
        local myPos = root.Position
        local bestBook = nil
        local bestDist = math.huge

        for _, b in ipairs(looseBooks) do
            if isBookAvailable(b) and b:GetAttribute("Series") == currentTargetSeries then
                local d = (b.Position - myPos).Magnitude
                if d < bestDist then
                    bestDist = d
                    bestBook = b
                end
            end
        end

        if bestBook then
            fastPickUpBook(root, bestBook)
            isFarming = false
            return
        else
            currentTargetSeries = getBestTargetSeries(looseBooks)
        end
    end

    -- กรณี Fallback: เลือกเล่มที่ตู้ยังไม่เต็ม และตรงกับห้องปัจจุบันที่สุด
    if #looseBooks > 0 then
        local myPos = root.Position
        local bestBook = nil
        local bestDist = math.huge

        for _, b in ipairs(looseBooks) do
            if isBookAvailable(b) then
                local bSeries = b:GetAttribute("Series")
                if bSeries and not isShelfCompleted(bSeries) then
                    local d = (b.Position - myPos).Magnitude
                    if d < bestDist then
                        bestDist = d
                        bestBook = b
                    end
                end
            end
        end

        if bestBook then
            currentTargetSeries = bestBook:GetAttribute("Series")
            fastPickUpBook(root, bestBook)
            isFarming = false
            return
        end
    end

    task.wait(0.01)
    isFarming = false
end

-- ลูปหลักสำหรับ Auto Farm (Books)
task.spawn(function()
    while ScriptInstance.Running and _G.CleanMagic_CurrentToken == currentToken do
        if Config.AutoFarm then
            pcall(processFarmStep)
            task.wait()
        else
            task.wait(0.2)
        end
    end
end)

-- --------------------------------------------------------
-- 6. DEDICATED AUTO GEMS (ปุ่มเก็บเพชรแยกอิสระ)
-- --------------------------------------------------------
task.spawn(function()
    while ScriptInstance.Running and _G.CleanMagic_CurrentToken == currentToken do
        if Config.AutoGems then
            local gemsFolder = Workspace:FindFirstChild("Gems")
            local gemList = gemsFolder and gemsFolder:GetChildren() or {}

            -- หากไม่ได้เปิด AutoFarm หนังสือ หรือหนังสือในห้องว่างหมดแล้ว ให้เดินสายวาร์ปเก็บ Gem ทั่วแมพ
            if not Config.AutoFarm or #gemList > 0 then
                local root = getRootPart()
                if root and #gemList > 0 then
                    for _, gem in ipairs(gemList) do
                        if not Config.AutoGems or not ScriptInstance.Running or _G.CleanMagic_CurrentToken ~= currentToken then break end
                        if gem and gem.Parent and gem:IsA("Model") then
                            local pivotPos = gem:GetPivot().Position
                            -- ถ้าระยะไกล และไม่ได้กำลังฟาร์มหนังสือ ให้วาร์ปไปเก็บโดยตรง
                            if not Config.AutoFarm then
                                root.CFrame = CFrame.new(pivotPos + Vector3.new(0, 0.8, 0))
                            end
                            if Network and Network.collectGem then
                                pcall(function()
                                    Network.collectGem.call(gem)
                                end)
                            end
                        end
                    end
                end
            end
            task.wait(0.05)
        else
            task.wait(0.5)
        end
    end
end)

-- --------------------------------------------------------
-- 7. DYNAMIC BOOK & SHELF ESP (แสดงเฉพาะซีรีส์ของหนังสือในมือล่าสุด)
-- --------------------------------------------------------
local ESP_FOLDER_NAME = "CleanMagic_DynamicESP"
local espFolder = Workspace:FindFirstChild(ESP_FOLDER_NAME) or Instance.new("Folder")
espFolder.Name = ESP_FOLDER_NAME
espFolder.Parent = Workspace

local function clearESP()
    for _, obj in ipairs(espFolder:GetChildren()) do
        obj:Destroy()
    end
end

local function applyHighlight(target: Instance, nameText: string, color: Color3)
    if not target or not target.Parent then return end

    local hl = Instance.new("Highlight")
    hl.Name = "ESP_Highlight"
    hl.Adornee = target
    hl.FillColor = color
    hl.FillTransparency = 0.55
    hl.OutlineColor = Color3.fromRGB(255, 255, 255)
    hl.OutlineTransparency = 0.1
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Parent = espFolder

    local adornPart = target:IsA("BasePart") and target or (target:IsA("Model") and (target.PrimaryPart or target:FindFirstChildWhichIsA("BasePart")))
    if adornPart then
        local bb = Instance.new("BillboardGui")
        bb.Name = "ESP_Billboard"
        bb.Adornee = adornPart
        bb.Size = UDim2.fromOffset(140, 36)
        bb.StudsOffset = Vector3.new(0, 2.2, 0)
        bb.AlwaysOnTop = true
        bb.Parent = espFolder

        local txt = Instance.new("TextLabel")
        txt.Size = UDim2.fromScale(1, 1)
        txt.BackgroundTransparency = 1
        txt.Font = Enum.Font.FredokaOne
        txt.TextSize = 12
        txt.TextColor3 = color
        txt.TextStrokeTransparency = 0.2
        txt.TextStrokeColor3 = Color3.fromRGB(16, 3, 26)
        txt.Text = nameText
        txt.Parent = bb
    end
end

local lastEspSeries = nil

task.spawn(function()
    while ScriptInstance.Running and _G.CleanMagic_CurrentToken == currentToken do
        task.wait(0.25)
        if not Config.BookESP then
            if lastEspSeries ~= nil then
                clearESP()
                lastEspSeries = nil
            end
        else
            local carried = getCarriedBooks()
            local activeSeries = nil

            if #carried > 0 then
                for i = #carried, 1, -1 do
                    local b = carried[i]
                    if b and b.Parent then
                        local s = b:GetAttribute("Series")
                        if s and s ~= "" then
                            activeSeries = s
                            break
                        end
                    end
                end
            end

            if not activeSeries then
                if lastEspSeries ~= nil then
                    clearESP()
                    lastEspSeries = nil
                end
            else
                -- อัปเดต ESP ใหม่เมื่อถือซีรีส์ หรือมีการขยับรอบ
                clearESP()
                lastEspSeries = activeSeries

                -- 1. แสดง ESP สำหรับหนังสือซีรีส์เดียวกันที่ตกอยู่บนพื้น
                local booksFolder = Workspace:FindFirstChild("Books")
                if booksFolder then
                    for _, book in ipairs(booksFolder:GetChildren()) do
                        if isBookAvailable(book) and book:GetAttribute("Series") == activeSeries then
                            applyHighlight(book, "📖 " .. activeSeries, Color3.fromRGB(80, 255, 140))
                        end
                    end
                end

                -- 2. แสดง ESP ตู้หนังสือ (Shelf) ประจำซีรีส์นั้น
                local shelf = findShelfBySeries(activeSeries)
                if shelf then
                    local placed = getPlacedForSeries(activeSeries)
                    local targetCopies = getTargetCopies()
                    local shelfTitle = string.format("📚 SHELF: %s (%d/%d)", activeSeries, placed, targetCopies)
                    applyHighlight(shelf, shelfTitle, Color3.fromRGB(255, 215, 60))
                end
            end
        end
    end
    clearESP()
end)

-- --------------------------------------------------------
-- 8. AUTO UPGRADES (POWER-UPS & SPELLS SEQUENTIAL CHECKBOX UPGRADE)
-- --------------------------------------------------------
task.spawn(function()
    while ScriptInstance.Running and _G.CleanMagic_CurrentToken == currentToken do
        task.wait(0.05)
        if Config.AutoUpgrade and Network and Network.upgrade and UpgradesConfig then
            local upPoints = player:GetAttribute("UpgradePoints") or 0
            local spPoints = player:GetAttribute("SpellPoints") or 0

            -- 1. อัปเกรด Power-ups จากบนสุดลงล่าง จนเต็ม Max ก่อนค่อยอัพอันต่อไป (เฉพาะที่ Checkbox ไว้)
            if upPoints > 0 then
                for _, upgradeId in ipairs(PURE_POWERUP_DEFAULT) do
                    local isChecked = Config.PowerUpCheckboxes[upgradeId]
                    if isChecked then
                        local info = UpgradesConfig.ById[upgradeId]
                        if info then
                            local currentLevel = player:GetAttribute(UpgradesConfig.LevelAttributePrefix .. upgradeId) or 0
                            local maxLevel = info.MaxLevel or 15

                            if currentLevel < maxLevel then
                                local ok, res = pcall(function()
                                    return Network.upgrade.call(upgradeId, false)
                                end)
                                if ok and res and res.status == "Ok" then
                                    print(string.format("[Clean Magic] Upgraded Power-Up: %s (Lv.%d)", info.Name, currentLevel + 1))
                                    task.wait(0.05)
                                end
                                -- หยุดที่รายการนี้จนกว่าจะอัปเกรดจนเต็ม Max เลเวล
                                break
                            end
                        end
                    end
                end
            end

            -- 2. อัปเกรด Spells จากบนสุดลงล่าง จนเต็ม Max ก่อนค่อยอัพอันต่อไป (เฉพาะที่ Checkbox ไว้)
            if spPoints > 0 then
                for _, spellId in ipairs(ALL_SPELL_IDS) do
                    local isChecked = Config.SpellCheckboxes[spellId]
                    if isChecked then
                        local info = UpgradesConfig.ById[spellId]
                        if info then
                            local currentLevel = player:GetAttribute(UpgradesConfig.LevelAttributePrefix .. spellId) or 0
                            local maxLevel = info.MaxLevel or 15

                            if currentLevel < maxLevel then
                                local ok, res = pcall(function()
                                    return Network.upgrade.call(spellId, false)
                                end)
                                if ok and res and res.status == "Ok" then
                                    print(string.format("[Clean Magic] Upgraded Spell: %s (Lv.%d)", info.Name, currentLevel + 1))
                                    task.wait(0.05)
                                end
                                -- หยุดที่รายการนี้จนกว่าจะอัปเกรดจนเต็ม Max เลเวล
                                break
                            end
                        end
                    end
                end
            end
        end
    end
end)

local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = nil
pcall(function()
    VirtualInputManager = game:GetService("VirtualInputManager")
end)

-- ค้นหาและดึงสกิลที่ติดตั้งอยู่ใน Loadout (Slot 1-6)
local function getEquippedSkills(): {{ id: string, name: string, slot: number, isPassive: boolean, btn: GuiButton? }}
    local result = {}
    local seen = {}

    -- วิธีที่ 1: ตรวจสอบจาก Charm / WizardState
    if Charm and WizardState then
        pcall(function()
            for _, stateKey in ipairs({"Resolved", "Spells", "Loadout", "Equipped", "Skills"}) do
                local s = WizardState[stateKey]
                if s then
                    local data = Charm.peek(s)
                    if type(data) == "table" then
                        local list = data.Spells or data.Equipped or data.Skills or data.Loadout or data
                        if type(list) == "table" then
                            local slotIdx = 1
                            for k, v in pairs(list) do
                                local sId = (type(v) == "string" and v) or (type(v) == "table" and (v.Id or v.Name or v.SpellId)) or (type(k) == "string" and k)
                                if sId and not seen[sId] then
                                    local info = UpgradesConfig and UpgradesConfig.ById[sId]
                                    if info or table.find(ALL_SPELL_IDS, sId) then
                                        seen[sId] = true
                                        local isPass = (info and (info.Type == "Passive" or info.IsPassive)) or false
                                        table.insert(result, {
                                            id = sId,
                                            name = info and info.Name or sId,
                                            slot = tonumber(k) or slotIdx,
                                            isPassive = isPass,
                                            btn = nil
                                        })
                                        slotIdx += 1
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end)
    end

    -- วิธีที่ 2: ตรวจจับจาก PlayerGui (ตรวจดูปุ่มสกิลบนจอจริง)
    local pGui = player:FindFirstChild("PlayerGui")
    if pGui then
        pcall(function()
            for _, g in ipairs(pGui:GetDescendants()) do
                if g:IsA("GuiButton") and g.Visible and g.Parent and g.Parent.Visible then
                    local gName = g.Name
                    for _, sId in ipairs(ALL_SPELL_IDS) do
                        if (gName:lower():find(sId:lower()) or (g:FindFirstChild("TextLabel") and g.TextLabel.Text:lower():find(sId:lower()))) and not seen[sId] then
                            seen[sId] = true
                            local info = UpgradesConfig and UpgradesConfig.ById[sId]
                            local isPass = (info and (info.Type == "Passive" or info.IsPassive)) or false
                            table.insert(result, {
                                id = sId,
                                name = info and info.Name or sId,
                                slot = #result + 1,
                                isPassive = isPass,
                                btn = g
                            })
                        end
                    end
                end
            end
        end)
    end

    return result
end

-- กดปุ่มคีย์บอร์ดจำลองสำหรับใช้สกิล (รองรับทั้ง VirtualInputManager, Mouse Aim Raycast และ Remote)
local function triggerSkillSlot(slot: number, spellId: string?, targetShelf: BasePart?)
    -- 1. พยายามยิงผ่าน Remote ตรงๆ ก่อนหากมี Remote เกี่ยวกับสกิล
    if Network and spellId then
        pcall(function()
            for _, fnName in ipairs({"castSpell", "useSpell", "activateSpell", "spell", "cast", "useCharm"}) do
                if Network[fnName] and typeof(Network[fnName].call) == "function" then
                    if targetShelf then
                        Network[fnName].call(spellId, targetShelf)
                        Network[fnName].call(targetShelf)
                        Network[fnName].call(targetShelf.Position)
                    else
                        Network[fnName].call(spellId)
                    end
                    return
                end
            end
        end)
    end

    -- 2. เล็ง Camera และหันเมาส์เข้าสู่กึ่งกลางตู้ เพื่อให้เกมตรวจจับ Cursor อยู่บนตู้
    local camera = Workspace.CurrentCamera
    if camera and targetShelf then
        pcall(function()
            local targetPos = targetShelf.Position + Vector3.new(0, 1.5, 0)
            local root = getRootPart()
            if root then
                root.CFrame = CFrame.new(root.Position, Vector3.new(targetPos.X, root.Position.Y, targetPos.Z))
            end
            camera.CFrame = CFrame.new(camera.CFrame.Position, targetPos)
            
            -- จำลองตำแหน่งเมาส์ตรงกลางหน้าจอที่เล็งตู้
            if VirtualInputManager then
                local viewport = camera.ViewportSize
                local midX = viewport.X / 2
                local midY = viewport.Y / 2
                VirtualInputManager:SendMouseMoveEvent(midX, midY, game)
            end
        end)
    end

    -- 3. จำลองการกดปุ่มตัวเลข 1-6 (หรือคลิกปุ่มบนหน้าจอ)
    local keyCodes = {
        [1] = Enum.KeyCode.One,
        [2] = Enum.KeyCode.Two,
        [3] = Enum.KeyCode.Three,
        [4] = Enum.KeyCode.Four,
        [5] = Enum.KeyCode.Five,
        [6] = Enum.KeyCode.Six
    }
    local kc = keyCodes[slot]
    if kc and VirtualInputManager then
        pcall(function()
            VirtualInputManager:SendKeyEvent(true, kc, false, game)
            task.wait(0.03)
            VirtualInputManager:SendKeyEvent(false, kc, false, game)
        end)
    end

    -- 4. หากเป็นสกิลที่ต้องคลิกเป้าหมาย (เช่น Shelf Fill Charm) ให้ส่ง Mouse Click ยืนยันที่ตู้ด้วย
    if targetShelf and VirtualInputManager and camera then
        pcall(function()
            task.wait(0.04)
            local viewport = camera.ViewportSize
            local midX = viewport.X / 2
            local midY = viewport.Y / 2
            VirtualInputManager:SendMouseButtonEvent(midX, midY, 0, true, game, 1)
            task.wait(0.03)
            VirtualInputManager:SendMouseButtonEvent(midX, midY, 0, false, game, 1)
        end)
    end
end

-- หาตู้ที่ยังว่าง หรือมีหนังสือน้อยที่สุดเพื่อเล็งใช้ Shelf Fill Charm
local function getLowestShelf(): BasePart?
    local shelves = CollectionService:GetTagged("Shelf")
    local bestShelf = nil
    local minPlaced = math.huge
    local targetCopies = getTargetCopies()

    for _, sh in ipairs(shelves) do
        if sh:IsA("BasePart") then
            local series = sh:GetAttribute("Series")
            if series then
                local placed = getPlacedForSeries(series)
                if placed < targetCopies and placed < minPlaced then
                    minPlaced = placed
                    bestShelf = sh
                end
            end
        end
    end
    return bestShelf
end

-- --------------------------------------------------------
-- 9. AUTO SKILL ACTIVE THREAD
-- --------------------------------------------------------
task.spawn(function()
    while ScriptInstance.Running and _G.CleanMagic_CurrentToken == currentToken do
        task.wait(0.2)
        if Config.AutoSkill then
            -- ทำงานเมื่อไม่อยู่ในจังหวะถือหนังสือไปส่งตู้ (ป้องกันการวาร์ปขัดจังหวะการส่งหนังสือ)
            local carried = getCarriedBooks()
            if #carried == 0 then
                local equipped = getEquippedSkills()
                local orderMap = {}
                for idx, id in ipairs(Config.AutoSkillOrder or {}) do
                    orderMap[id] = idx
                end

                -- เรียงตามลำดับที่จัดไว้ใน AutoSkillOrder
                table.sort(equipped, function(a, b)
                    local rankA = orderMap[a.id] or 999
                    local rankB = orderMap[b.id] or 999
                    return rankA < rankB
                end)

                for _, sk in ipairs(equipped) do
                    if not Config.AutoSkill or not ScriptInstance.Running or _G.CleanMagic_CurrentToken ~= currentToken then break end
                    -- ข้ามสกิลที่เป็น Passive หรือไม่ได้ Checkbox ไว้
                    local isChecked = Config.AutoSkillCheckboxes[sk.id]
                    if isChecked and not sk.isPassive then
                        if sk.id == "ShelfFill" then
                            -- กรณีสกิล Shelf Fill Charm: ต้องเล็งไปที่ตู้ว่าง/หนังสือน้อยที่สุด
                            local targetShelf = getLowestShelf()
                            if targetShelf then
                                local root = getRootPart()
                                local oldCF = root and root.CFrame
                                if root then
                                    -- วาร์ปไปหน้าตู้เป้าหมายเพื่อเล็งยิงสกิล
                                    root.CFrame = getShelfFrontCFrame(targetShelf)
                                    task.wait(0.04)
                                end

                                triggerSkillSlot(sk.slot, sk.id, targetShelf)
                                task.wait(0.05)

                                -- วาร์ปกลับตำแหน่งเดิมทันที
                                if oldCF and root and Config.AutoFarm then
                                    root.CFrame = oldCF
                                end
                                task.wait(0.15)
                            end
                        else
                            -- สกิลทั่วไป: กดใช้ได้ทันที
                            triggerSkillSlot(sk.slot, sk.id, nil)
                            task.wait(0.08)
                        end
                    end
                end
            end
        end
    end
end)

-- --------------------------------------------------------
-- 8. CREATE UI WINDOW WITH BEHIND THE DARK LIB
-- --------------------------------------------------------
local Window = Library:CreateWindow({
    Title = "CLEAN THE MAGIC",
    Name = GUI_NAME,
    Size = UDim2.fromOffset(660, 440),
    OnUnload = function()
        ScriptInstance.Running = false
        Config.AutoFarm = false
        Config.AutoGems = false
        Config.AutoUpgrade = false
        Config.AutoSkill = false
        saveConfig()
        local root = getRootPart()
        if root then root.Anchored = false end
    end
})

ScriptInstance.Cleanup = function()
    pcall(function()
        if Window.Gui then Window.Gui:Destroy() end
    end)
    local root = getRootPart()
    if root then root.Anchored = false end
end

local leftCol = Window:GetColumn("Left")
local rightCol = Window:GetColumn("Right")

-- --------------------------------------------------------
-- คอลัมน์ซ้าย: TOGGLES & AUTOMATION CONTROLS
-- --------------------------------------------------------
-- 1. Main Toggle: Auto Books
Window:CreateToggle("Left", "Auto Farm (Books)", 0, {
    On = Color3.fromRGB(0, 230, 150),
    Off = Color3.fromRGB(120, 120, 130)
}, Config.AutoFarm, function(enabled)
    Config.AutoFarm = enabled
    saveConfig()
    local root = getRootPart()
    if not enabled and not Config.AutoGems and root then
        root.Anchored = false
    end
    print("[Clean Magic] Auto Books Farm:", enabled and "ON" or "OFF")
end)

-- 2. Toggle: Auto Gems (แยกปุ่มอิสระ)
Window:CreateToggle("Left", "Auto Collect Gems", 46, {
    On = Color3.fromRGB(80, 200, 255),
    Off = Color3.fromRGB(120, 120, 130)
}, Config.AutoGems, function(enabled)
    Config.AutoGems = enabled
    saveConfig()
    print("[Clean Magic] Auto Collect Gems:", enabled and "ON" or "OFF")
end)

-- 3. Toggle: Dynamic Book ESP (ถือเล่มไหนขึ้นเฉพาะซีรีส์นั้น)
Window:CreateToggle("Left", "Dynamic Book & Shelf ESP", 92, {
    On = Color3.fromRGB(150, 100, 255),
    Off = Color3.fromRGB(120, 120, 130)
}, Config.BookESP, function(enabled)
    Config.BookESP = enabled
    saveConfig()
    if not enabled then
        local ef = Workspace:FindFirstChild("CleanMagic_DynamicESP")
        if ef then ef:ClearAllChildren() end
    end
    print("[Clean Magic] Dynamic Book ESP:", enabled and "ON" or "OFF")
end)

-- 4. Toggle: Auto Upgrade Master
Window:CreateToggle("Left", "Auto Upgrade (Points)", 138, {
    On = Color3.fromRGB(255, 170, 40),
    Off = Color3.fromRGB(120, 120, 130)
}, Config.AutoUpgrade, function(enabled)
    Config.AutoUpgrade = enabled
    saveConfig()
    print("[Clean Magic] Auto Upgrade Master:", enabled and "ON" or "OFF")
end)

-- 5. Toggle: Auto Skill (Cast Equipped Skills)
Window:CreateToggle("Left", "Auto Use Skills (Equipped)", 184, {
    On = Color3.fromRGB(240, 90, 140),
    Off = Color3.fromRGB(120, 120, 130)
}, Config.AutoSkill, function(enabled)
    Config.AutoSkill = enabled
    saveConfig()
    print("[Clean Magic] Auto Use Skills:", enabled and "ON" or "OFF")
end)

-- --------------------------------------------------------
-- คอลัมน์ขวา: POPUP MENUS & CONFIGURATION DROPDOWNS
-- --------------------------------------------------------
local function createDropdownButton(parentCol, yPos: number, title: string, color: Color3)
    local shadow = Instance.new("Frame")
    shadow.Size = UDim2.new(1, 0, 0, 44)
    shadow.Position = UDim2.fromOffset(0, yPos)
    shadow.BackgroundColor3 = Color3.fromRGB(16, 3, 26)
    shadow.BorderSizePixel = 0
    shadow.ZIndex = 20
    shadow.Parent = parentCol
    Instance.new("UICorner", shadow).CornerRadius = UDim.new(0, 13)

    local rim = Instance.new("Frame")
    rim.Size = UDim2.new(1, 0, 0, 41)
    rim.Position = UDim2.fromOffset(0, 0)
    rim.BackgroundColor3 = color
    rim.BorderSizePixel = 0
    rim.ZIndex = 21
    rim.Parent = shadow
    Instance.new("UICorner", rim).CornerRadius = UDim.new(0, 13)
    local s = Instance.new("UIStroke")
    s.Parent = rim
    s.Thickness = 2.8
    s.Color = Color3.fromRGB(22, 5, 36)

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -6, 1, -5)
    btn.Position = UDim2.fromOffset(3, 2)
    btn.BackgroundColor3 = Color3.fromRGB(154, 102, 224)
    btn.BorderSizePixel = 0
    btn.AutoButtonColor = false
    btn.Text = ""
    btn.ClipsDescendants = true
    btn.ZIndex = 22
    btn.Parent = rim
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 10)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -50, 1, 0)
    lbl.Position = UDim2.fromOffset(12, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = title
    lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
    lbl.TextSize = 13
    lbl.Font = Enum.Font.FredokaOne
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.ZIndex = 23
    lbl.Parent = btn
    local ls = Instance.new("UIStroke")
    ls.Parent = lbl
    ls.Thickness = 2.4
    ls.Color = Color3.fromRGB(22, 5, 36)

    local arrow = Instance.new("TextLabel")
    arrow.Size = UDim2.fromOffset(26, 24)
    arrow.Position = UDim2.new(1, -34, 0.5, -12)
    arrow.BackgroundTransparency = 1
    arrow.Text = "▼"
    arrow.TextColor3 = Color3.fromRGB(255, 225, 95)
    arrow.TextSize = 11
    arrow.Font = Enum.Font.FredokaOne
    arrow.ZIndex = 23
    arrow.Parent = btn

    return shadow, btn, arrow
end

local powerUpDropShadow, powerUpDropBtn, powerUpArrow = createDropdownButton(rightCol, 0, "Power-ups (Sequential)", Color3.fromRGB(75, 215, 140))
local spellDropShadow, spellDropBtn, spellArrow = createDropdownButton(rightCol, 52, "Spells (Sequential)", Color3.fromRGB(250, 180, 80))
local autoSkillDropShadow, autoSkillDropBtn, autoSkillArrow = createDropdownButton(rightCol, 104, "Equipped Skills (Order)", Color3.fromRGB(240, 90, 140))

local targetScreenGui = Window.Gui or CoreGui:FindFirstChild(GUI_NAME)

-- --------------------------------------------------------
-- POPUP A: POWER-UPS CHECKBOX POPUP (UPGRADE POINTS - TOP DOWN FIRST)
-- --------------------------------------------------------
local powerUpPopup = Instance.new("Frame")
powerUpPopup.Name = "PowerUpPopupDropdown"
powerUpPopup.Size = UDim2.new(0, 240, 0, 220)
powerUpPopup.BackgroundColor3 = Color3.fromRGB(16, 3, 26)
powerUpPopup.BorderSizePixel = 0
powerUpPopup.Visible = false
powerUpPopup.ZIndex = 850
powerUpPopup.Parent = targetScreenGui
Instance.new("UICorner", powerUpPopup).CornerRadius = UDim.new(0, 14)

local popRimA = Instance.new("Frame")
popRimA.Size = UDim2.new(1, 0, 1, -3)
popRimA.BackgroundColor3 = Color3.fromRGB(45, 140, 85)
popRimA.BorderSizePixel = 0
popRimA.ZIndex = 851
popRimA.Parent = powerUpPopup
Instance.new("UICorner", popRimA).CornerRadius = UDim.new(0, 14)
local prsA = Instance.new("UIStroke")
prsA.Parent = popRimA
prsA.Thickness = 3
prsA.Color = Color3.fromRGB(22, 5, 36)

local popInnerA = Instance.new("Frame")
popInnerA.Size = UDim2.new(1, -6, 1, -6)
popInnerA.Position = UDim2.fromOffset(3, 3)
popInnerA.BackgroundColor3 = Color3.fromRGB(16, 42, 28)
popInnerA.BorderSizePixel = 0
popInnerA.ZIndex = 852
popInnerA.Parent = popRimA
Instance.new("UICorner", popInnerA).CornerRadius = UDim.new(0, 11)

local scrollPowerUp = Instance.new("ScrollingFrame")
scrollPowerUp.Size = UDim2.new(1, -8, 1, -12)
scrollPowerUp.Position = UDim2.fromOffset(4, 6)
scrollPowerUp.BackgroundTransparency = 1
scrollPowerUp.BorderSizePixel = 0
scrollPowerUp.AutomaticCanvasSize = Enum.AutomaticSize.Y
scrollPowerUp.ScrollBarThickness = 5
scrollPowerUp.ZIndex = 853
scrollPowerUp.Parent = popInnerA

local layoutA = Instance.new("UIListLayout")
layoutA.Parent = scrollPowerUp
layoutA.Padding = UDim.new(0, 4)
layoutA.SortOrder = Enum.SortOrder.LayoutOrder

for _, upgradeId in ipairs(PURE_POWERUP_DEFAULT) do
    local info = UpgradesConfig and UpgradesConfig.ById[upgradeId]
    local displayName = info and info.Name or upgradeId

    local rowBtn = Instance.new("TextButton")
    rowBtn.Name = "PowerUpRow_" .. upgradeId
    rowBtn.Size = UDim2.new(1, -8, 0, 34)
    rowBtn.BackgroundColor3 = Color3.fromRGB(24, 62, 42)
    rowBtn.BorderSizePixel = 0
    rowBtn.AutoButtonColor = false
    rowBtn.Text = ""
    rowBtn.ZIndex = 854
    rowBtn.Parent = scrollPowerUp
    Instance.new("UICorner", rowBtn).CornerRadius = UDim.new(0, 7)

    local rowStroke = Instance.new("UIStroke")
    rowStroke.Parent = rowBtn
    rowStroke.Thickness = 1.5
    rowStroke.Color = Color3.fromRGB(22, 5, 36)

    local isChecked = Config.PowerUpCheckboxes[upgradeId] ~= false

    local boxFrame = Instance.new("Frame")
    boxFrame.Size = UDim2.fromOffset(18, 18)
    boxFrame.Position = UDim2.new(0, 8, 0.5, -9)
    boxFrame.BackgroundColor3 = isChecked and Color3.fromRGB(75, 215, 140) or Color3.fromRGB(16, 42, 28)
    boxFrame.BorderSizePixel = 0
    boxFrame.ZIndex = 855
    boxFrame.Parent = rowBtn
    Instance.new("UICorner", boxFrame).CornerRadius = UDim.new(0, 5)

    local boxStroke = Instance.new("UIStroke")
    boxStroke.Parent = boxFrame
    boxStroke.Thickness = 1.3
    boxStroke.Color = Color3.fromRGB(22, 5, 36)

    local checkMark = Instance.new("TextLabel")
    checkMark.Size = UDim2.fromScale(1, 1)
    checkMark.BackgroundTransparency = 1
    checkMark.Text = isChecked and "✓" or ""
    checkMark.TextColor3 = Color3.fromRGB(16, 3, 26)
    checkMark.TextSize = 12
    checkMark.Font = Enum.Font.FredokaOne
    checkMark.ZIndex = 856
    checkMark.Parent = boxFrame

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, -34, 1, 0)
    nameLabel.Position = UDim2.fromOffset(32, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = displayName
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.TextSize = 11.5
    nameLabel.Font = Enum.Font.FredokaOne
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
    nameLabel.ZIndex = 855
    nameLabel.Parent = rowBtn

    local function toggleCheck()
        local current = not (Config.PowerUpCheckboxes[upgradeId] ~= false)
        Config.PowerUpCheckboxes[upgradeId] = current
        boxFrame.BackgroundColor3 = current and Color3.fromRGB(75, 215, 140) or Color3.fromRGB(16, 42, 28)
        checkMark.Text = current and "✓" or ""
        saveConfig()
        print(string.format("[Clean Magic] Power-Up %s Sequential Upgrade: %s", displayName, current and "ON" or "OFF"))
    end

    rowBtn.Activated:Connect(toggleCheck)
end

-- --------------------------------------------------------
-- POPUP B: SPELLS CHECKBOX POPUP (SPELL POINTS - TOP DOWN FIRST)
-- --------------------------------------------------------
local spellPopup = Instance.new("Frame")
spellPopup.Name = "SpellPopupDropdown"
spellPopup.Size = UDim2.new(0, 240, 0, 290)
spellPopup.BackgroundColor3 = Color3.fromRGB(16, 3, 26)
spellPopup.BorderSizePixel = 0
spellPopup.Visible = false
spellPopup.ZIndex = 850
spellPopup.Parent = targetScreenGui
Instance.new("UICorner", spellPopup).CornerRadius = UDim.new(0, 14)

local popRimB = Instance.new("Frame")
popRimB.Size = UDim2.new(1, 0, 1, -3)
popRimB.BackgroundColor3 = Color3.fromRGB(150, 95, 45)
popRimB.BorderSizePixel = 0
popRimB.ZIndex = 851
popRimB.Parent = spellPopup
Instance.new("UICorner", popRimB).CornerRadius = UDim.new(0, 14)
local prsB = Instance.new("UIStroke")
prsB.Parent = popRimB
prsB.Thickness = 3
prsB.Color = Color3.fromRGB(22, 5, 36)

local popInnerB = Instance.new("Frame")
popInnerB.Size = UDim2.new(1, -6, 1, -6)
popInnerB.Position = UDim2.fromOffset(3, 3)
popInnerB.BackgroundColor3 = Color3.fromRGB(44, 24, 16)
popInnerB.BorderSizePixel = 0
popInnerB.ZIndex = 852
popInnerB.Parent = popRimB
Instance.new("UICorner", popInnerB).CornerRadius = UDim.new(0, 11)

local scrollSpells = Instance.new("ScrollingFrame")
scrollSpells.Size = UDim2.new(1, -8, 1, -12)
scrollSpells.Position = UDim2.fromOffset(4, 6)
scrollSpells.BackgroundTransparency = 1
scrollSpells.BorderSizePixel = 0
scrollSpells.AutomaticCanvasSize = Enum.AutomaticSize.Y
scrollSpells.ScrollBarThickness = 5
scrollSpells.ZIndex = 853
scrollSpells.Parent = popInnerB

local layoutB = Instance.new("UIListLayout")
layoutB.Parent = scrollSpells
layoutB.Padding = UDim.new(0, 4)
layoutB.SortOrder = Enum.SortOrder.LayoutOrder

for _, spellId in ipairs(ALL_SPELL_IDS) do
    local info = UpgradesConfig and UpgradesConfig.ById[spellId]
    local displayName = info and info.Name or spellId

    local rowBtn = Instance.new("TextButton")
    rowBtn.Name = "SpellRow_" .. spellId
    rowBtn.Size = UDim2.new(1, -8, 0, 34)
    rowBtn.BackgroundColor3 = Color3.fromRGB(64, 32, 22)
    rowBtn.BorderSizePixel = 0
    rowBtn.AutoButtonColor = false
    rowBtn.Text = ""
    rowBtn.ZIndex = 854
    rowBtn.Parent = scrollSpells
    Instance.new("UICorner", rowBtn).CornerRadius = UDim.new(0, 7)

    local rowStroke = Instance.new("UIStroke")
    rowStroke.Parent = rowBtn
    rowStroke.Thickness = 1.5
    rowStroke.Color = Color3.fromRGB(22, 5, 36)

    local isChecked = Config.SpellCheckboxes[spellId] or false
    local boxFrame = Instance.new("Frame")
    boxFrame.Size = UDim2.fromOffset(18, 18)
    boxFrame.Position = UDim2.new(0, 8, 0.5, -9)
    boxFrame.BackgroundColor3 = isChecked and Color3.fromRGB(255, 175, 50) or Color3.fromRGB(36, 16, 10)
    boxFrame.BorderSizePixel = 0
    boxFrame.ZIndex = 855
    boxFrame.Parent = rowBtn
    Instance.new("UICorner", boxFrame).CornerRadius = UDim.new(0, 5)

    local boxStroke = Instance.new("UIStroke")
    boxStroke.Parent = boxFrame
    boxStroke.Thickness = 1.3
    boxStroke.Color = Color3.fromRGB(22, 5, 36)

    local checkMark = Instance.new("TextLabel")
    checkMark.Size = UDim2.fromScale(1, 1)
    checkMark.BackgroundTransparency = 1
    checkMark.Text = isChecked and "✓" or ""
    checkMark.TextColor3 = Color3.fromRGB(16, 3, 26)
    checkMark.TextSize = 12
    checkMark.Font = Enum.Font.FredokaOne
    checkMark.ZIndex = 856
    checkMark.Parent = boxFrame

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, -34, 1, 0)
    nameLabel.Position = UDim2.fromOffset(32, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = displayName
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.TextSize = 11.5
    nameLabel.Font = Enum.Font.FredokaOne
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
    nameLabel.ZIndex = 855
    nameLabel.Parent = rowBtn

    local function toggleCheck()
        local current = not (Config.SpellCheckboxes[spellId] or false)
        Config.SpellCheckboxes[spellId] = current
        boxFrame.BackgroundColor3 = current and Color3.fromRGB(255, 175, 50) or Color3.fromRGB(36, 16, 10)
        checkMark.Text = current and "✓" or ""
        saveConfig()
        print(string.format("[Clean Magic] Spell %s Sequential Upgrade: %s", displayName, current and "ON" or "OFF"))
    end

    rowBtn.Activated:Connect(toggleCheck)
end

-- --------------------------------------------------------
-- POPUP C: EQUIPPED AUTO SKILLS POPUP (CHECKBOX + ARROW REORDER ▲/▼ + REFRESH)
-- --------------------------------------------------------
local autoSkillPopup = Instance.new("Frame")
autoSkillPopup.Name = "AutoSkillPopupDropdown"
autoSkillPopup.Size = UDim2.new(0, 240, 0, 270)
autoSkillPopup.BackgroundColor3 = Color3.fromRGB(16, 3, 26)
autoSkillPopup.BorderSizePixel = 0
autoSkillPopup.Visible = false
autoSkillPopup.ZIndex = 850
autoSkillPopup.Parent = targetScreenGui
Instance.new("UICorner", autoSkillPopup).CornerRadius = UDim.new(0, 14)

local popRimC = Instance.new("Frame")
popRimC.Size = UDim2.new(1, 0, 1, -3)
popRimC.BackgroundColor3 = Color3.fromRGB(160, 50, 95)
popRimC.BorderSizePixel = 0
popRimC.ZIndex = 851
popRimC.Parent = autoSkillPopup
Instance.new("UICorner", popRimC).CornerRadius = UDim.new(0, 14)
local prsC = Instance.new("UIStroke")
prsC.Parent = popRimC
prsC.Thickness = 3
prsC.Color = Color3.fromRGB(22, 5, 36)

local popInnerC = Instance.new("Frame")
popInnerC.Size = UDim2.new(1, -6, 1, -6)
popInnerC.Position = UDim2.fromOffset(3, 3)
popInnerC.BackgroundColor3 = Color3.fromRGB(48, 16, 28)
popInnerC.BorderSizePixel = 0
popInnerC.ZIndex = 852
popInnerC.Parent = popRimC
Instance.new("UICorner", popInnerC).CornerRadius = UDim.new(0, 11)

-- ปุ่ม Refresh เพื่อตรวจจับสกิลที่ใส่มาใหม่
local refreshBtn = Instance.new("TextButton")
refreshBtn.Size = UDim2.new(1, -12, 0, 26)
refreshBtn.Position = UDim2.fromOffset(6, 6)
refreshBtn.BackgroundColor3 = Color3.fromRGB(180, 55, 105)
refreshBtn.Text = "🔄 Refresh Equipped Skills"
refreshBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
refreshBtn.TextSize = 11.5
refreshBtn.Font = Enum.Font.FredokaOne
refreshBtn.BorderSizePixel = 0
refreshBtn.ZIndex = 854
refreshBtn.Parent = popInnerC
Instance.new("UICorner", refreshBtn).CornerRadius = UDim.new(0, 6)
local rfStroke = Instance.new("UIStroke")
rfStroke.Parent = refreshBtn
rfStroke.Thickness = 1.3
rfStroke.Color = Color3.fromRGB(22, 5, 36)

local scrollAutoSkill = Instance.new("ScrollingFrame")
scrollAutoSkill.Size = UDim2.new(1, -8, 1, -44)
scrollAutoSkill.Position = UDim2.fromOffset(4, 38)
scrollAutoSkill.BackgroundTransparency = 1
scrollAutoSkill.BorderSizePixel = 0
scrollAutoSkill.AutomaticCanvasSize = Enum.AutomaticSize.Y
scrollAutoSkill.ScrollBarThickness = 5
scrollAutoSkill.ZIndex = 853
scrollAutoSkill.Parent = popInnerC

local layoutC = Instance.new("UIListLayout")
layoutC.Parent = scrollAutoSkill
layoutC.Padding = UDim.new(0, 4)
layoutC.SortOrder = Enum.SortOrder.LayoutOrder

local renderSkillList = nil
renderSkillList = function()
    for _, ch in ipairs(scrollAutoSkill:GetChildren()) do
        if ch:IsA("Frame") or ch:IsA("TextLabel") then ch:Destroy() end
    end

    local equipped = getEquippedSkills()

    -- ตรวจสอบและลงทะเบียนสกิลใหม่เข้าสู่ Config
    for _, sk in ipairs(equipped) do
        if Config.AutoSkillCheckboxes[sk.id] == nil then
            Config.AutoSkillCheckboxes[sk.id] = not sk.isPassive
        end
        if not table.find(Config.AutoSkillOrder, sk.id) then
            table.insert(Config.AutoSkillOrder, sk.id)
        end
    end

    local orderMap = {}
    for idx, id in ipairs(Config.AutoSkillOrder) do
        orderMap[id] = idx
    end

    table.sort(equipped, function(a, b)
        local rankA = orderMap[a.id] or 999
        local rankB = orderMap[b.id] or 999
        return rankA < rankB
    end)

    if #equipped == 0 then
        local emptyLbl = Instance.new("TextLabel")
        emptyLbl.Size = UDim2.new(1, -8, 0, 40)
        emptyLbl.Position = UDim2.fromOffset(4, 10)
        emptyLbl.BackgroundTransparency = 1
        emptyLbl.Text = "No skills equipped in match!\n(Click Refresh when in game)"
        emptyLbl.TextColor3 = Color3.fromRGB(255, 180, 200)
        emptyLbl.TextSize = 11
        emptyLbl.Font = Enum.Font.FredokaOne
        emptyLbl.ZIndex = 855
        emptyLbl.Parent = scrollAutoSkill
        return
    end

    for idx, sk in ipairs(equipped) do
        local itemFrame = Instance.new("Frame")
        itemFrame.Size = UDim2.new(1, -6, 0, 36)
        itemFrame.BackgroundColor3 = Color3.fromRGB(68, 22, 38)
        itemFrame.BorderSizePixel = 0
        itemFrame.ZIndex = 854
        itemFrame.Parent = scrollAutoSkill
        Instance.new("UICorner", itemFrame).CornerRadius = UDim.new(0, 7)

        local itemStroke = Instance.new("UIStroke")
        itemStroke.Parent = itemFrame
        itemStroke.Thickness = 1.3
        itemStroke.Color = Color3.fromRGB(22, 5, 36)

        local isChecked = Config.AutoSkillCheckboxes[sk.id] or false

        -- Checkbox
        local boxBtn = Instance.new("TextButton")
        boxBtn.Size = UDim2.fromOffset(18, 18)
        boxBtn.Position = UDim2.new(0, 6, 0.5, -9)
        boxBtn.BackgroundColor3 = isChecked and Color3.fromRGB(240, 90, 140) or Color3.fromRGB(36, 12, 20)
        boxBtn.Text = isChecked and "✓" or ""
        boxBtn.TextColor3 = Color3.fromRGB(16, 3, 26)
        boxBtn.TextSize = 12
        boxBtn.Font = Enum.Font.FredokaOne
        boxBtn.BorderSizePixel = 0
        boxBtn.ZIndex = 856
        boxBtn.Parent = itemFrame
        Instance.new("UICorner", boxBtn).CornerRadius = UDim.new(0, 5)

        local boxStroke = Instance.new("UIStroke")
        boxStroke.Parent = boxBtn
        boxStroke.Thickness = 1.2
        boxStroke.Color = Color3.fromRGB(22, 5, 36)

        boxBtn.Activated:Connect(function()
            local cur = not (Config.AutoSkillCheckboxes[sk.id] or false)
            Config.AutoSkillCheckboxes[sk.id] = cur
            boxBtn.BackgroundColor3 = cur and Color3.fromRGB(240, 90, 140) or Color3.fromRGB(36, 12, 20)
            boxBtn.Text = cur and "✓" or ""
            saveConfig()
        end)

        -- Skill Tag: Active / Passive
        local tagText = sk.isPassive and "[PASSIVE]" or string.format("[Slot %d]", sk.slot)
        local tagColor = sk.isPassive and Color3.fromRGB(180, 180, 190) or Color3.fromRGB(255, 215, 90)

        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(1, -78, 1, 0)
        nameLabel.Position = UDim2.fromOffset(28, 0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = string.format("%s %s", sk.name, tagText)
        nameLabel.TextColor3 = tagColor
        nameLabel.TextSize = 10.5
        nameLabel.Font = Enum.Font.FredokaOne
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
        nameLabel.ZIndex = 855
        nameLabel.Parent = itemFrame

        -- Arrow Up ▲
        if idx > 1 then
            local upBtn = Instance.new("TextButton")
            upBtn.Size = UDim2.fromOffset(20, 20)
            upBtn.Position = UDim2.new(1, -46, 0.5, -10)
            upBtn.BackgroundColor3 = Color3.fromRGB(90, 30, 50)
            upBtn.Text = "▲"
            upBtn.TextColor3 = Color3.fromRGB(255, 225, 95)
            upBtn.TextSize = 10
            upBtn.Font = Enum.Font.FredokaOne
            upBtn.BorderSizePixel = 0
            upBtn.ZIndex = 856
            upBtn.Parent = itemFrame
            Instance.new("UICorner", upBtn).CornerRadius = UDim.new(0, 4)

            upBtn.Activated:Connect(function()
                local prevId = equipped[idx - 1].id
                local curId = sk.id
                local pIdx = table.find(Config.AutoSkillOrder, prevId)
                local cIdx = table.find(Config.AutoSkillOrder, curId)
                if pIdx and cIdx then
                    Config.AutoSkillOrder[cIdx] = prevId
                    Config.AutoSkillOrder[pIdx] = curId
                    saveConfig()
                    renderSkillList()
                end
            end)
        end

        -- Arrow Down ▼
        if idx < #equipped then
            local downBtn = Instance.new("TextButton")
            downBtn.Size = UDim2.fromOffset(20, 20)
            downBtn.Position = UDim2.new(1, -22, 0.5, -10)
            downBtn.BackgroundColor3 = Color3.fromRGB(90, 30, 50)
            downBtn.Text = "▼"
            downBtn.TextColor3 = Color3.fromRGB(255, 225, 95)
            downBtn.TextSize = 10
            downBtn.Font = Enum.Font.FredokaOne
            downBtn.BorderSizePixel = 0
            downBtn.ZIndex = 856
            downBtn.Parent = itemFrame
            Instance.new("UICorner", downBtn).CornerRadius = UDim.new(0, 4)

            downBtn.Activated:Connect(function()
                local nextId = equipped[idx + 1].id
                local curId = sk.id
                local nIdx = table.find(Config.AutoSkillOrder, nextId)
                local cIdx = table.find(Config.AutoSkillOrder, curId)
                if nIdx and cIdx then
                    Config.AutoSkillOrder[cIdx] = nextId
                    Config.AutoSkillOrder[nIdx] = curId
                    saveConfig()
                    renderSkillList()
                end
            end)
        end
    end
end

refreshBtn.Activated:Connect(function()
    renderSkillList()
end)

renderSkillList()

-- จัดการการเปิด/ปิด Popups สลับกันอย่างอิสระ
local function closeAllPopups()
    powerUpPopup.Visible = false
    spellPopup.Visible = false
    autoSkillPopup.Visible = false
    powerUpArrow.Text = "▼"
    spellArrow.Text = "▼"
    autoSkillArrow.Text = "▼"
end

powerUpDropBtn.Activated:Connect(function()
    local isOpening = not powerUpPopup.Visible
    closeAllPopups()
    if isOpening then
        powerUpPopup.Visible = true
        powerUpArrow.Text = "▲"
        local pos = powerUpDropShadow.AbsolutePosition
        local size = powerUpDropShadow.AbsoluteSize
        powerUpPopup.Position = UDim2.fromOffset(pos.X, pos.Y + size.Y + 4)
    end
end)

spellDropBtn.Activated:Connect(function()
    local isOpening = not spellPopup.Visible
    closeAllPopups()
    if isOpening then
        spellPopup.Visible = true
        spellArrow.Text = "▲"
        local pos = spellDropShadow.AbsolutePosition
        local size = spellDropShadow.AbsoluteSize
        spellPopup.Position = UDim2.fromOffset(pos.X, pos.Y + size.Y + 4)
    end
end)

autoSkillDropBtn.Activated:Connect(function()
    local isOpening = not autoSkillPopup.Visible
    closeAllPopups()
    if isOpening then
        renderSkillList()
        autoSkillPopup.Visible = true
        autoSkillArrow.Text = "▲"
        local pos = autoSkillDropShadow.AbsolutePosition
        local size = autoSkillDropShadow.AbsoluteSize
        autoSkillPopup.Position = UDim2.fromOffset(pos.X, pos.Y + size.Y + 4)
    end
end)

print("[BehindTheDark] Clean the Magic Library (In-Match Hub) Loaded & Restored.")
