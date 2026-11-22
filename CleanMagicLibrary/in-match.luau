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
    BookESP = false,      -- Dynamic Series Book & Shelf ESP
    AutoUpgrade = false,  -- อัปเกรดอัตโนมัติ
    PowerUpOrder = table.clone(PURE_POWERUP_DEFAULT),
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

local function sanitizePowerUpOrder(list)
    local allowed = { Extension = true, Haste = true, Owls = true, Reach = true, Levitation = true }
    local result = {}
    local seen = {}
    if type(list) == "table" then
        for _, id in ipairs(list) do
            if allowed[id] and not seen[id] then
                table.insert(result, id)
                seen[id] = true
            end
        end
    end
    for _, id in ipairs(PURE_POWERUP_DEFAULT) do
        if not seen[id] then
            table.insert(result, id)
            seen[id] = true
        end
    end
    return result
end

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
                Config.PowerUpOrder = sanitizePowerUpOrder(Config.PowerUpOrder)
                Config.SpellCheckboxes = Config.SpellCheckboxes or DefaultConfig.SpellCheckboxes
            end
        end
    end
    Config.PowerUpOrder = sanitizePowerUpOrder(Config.PowerUpOrder)
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

-- เก็บหนังสือแบบ Dynamic Fast-Retry (สปีดสูงสุดระดับมิลลิวินาที ไม่ค้างรอ)
local function fastPickUpBook(root: BasePart, book: Instance): boolean
    if not book or not book.Parent or not Network or not Network.pickUp then return false end
    root.CFrame = CFrame.new(book.Position + Vector3.new(0, 1.2, 0))
    sweepNearbyGems(18)

    local startT = os.clock()
    while (os.clock() - startT) < 0.20 and book.Parent and ScriptInstance.Running and _G.CleanMagic_CurrentToken == currentToken do
        local res = Network.pickUp.call(book)
        if res and res.status == "Ok" then
            return true
        elseif res and (res.status == "Full" or res.status == "TooMany") then
            -- หากเซิร์ฟเวอร์แจ้งว่ามือเต็มแล้ว ให้ตัดจบเพื่อไปส่งตู้ทันที
            return false
        end
        task.wait(0.01)
    end
    return false
end

-- --------------------------------------------------------
-- 5. FOCUSED SINGLE-SHELF RUSH (ฟาร์มจบทีละตู้เพื่อ SPELL POINTS)
-- --------------------------------------------------------
local isFarming = false
local currentTargetSeries = nil

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
                    table.insert(candidates, {
                        series = series,
                        needed = needed,
                        placed = placed,
                        available = available
                    })
                end
            end
        end
    end

    if #candidates == 0 then return nil end

    table.sort(candidates, function(a, b)
        return a.needed < b.needed
    end)

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

        -- 1.1 ถ้าในมือยังไม่เต็มความจุ และตู้ยังต้องการหนังสือเพิ่มอีก ให้หาซีรีส์เดิมมาเก็บต่อ
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
                -- หากหยิบไม่สำเร็จ (เซิร์ฟเวอร์เต็ม หรือเล่มถูกแย่ง) ให้ไหลลงไป 1.2 เพื่อไปส่งตู้ทันที
            end
        end

        -- 1.2 วาปไปหน้าตู้และยิงวางต่อเนื่องจนหมดมือ (Ultra-Fast Shelving Pipeline)
        local targetShelf = carriedSeries and findShelfBySeries(carriedSeries)
        if targetShelf then
            root.CFrame = getShelfFrontCFrame(targetShelf)
            sweepNearbyGems(18)

            -- Pre-fire คำสั่งส่งเข้าตู้ทันที
            if Network and Network.shelve then
                pcall(function()
                    Network.shelve.call(targetShelf)
                end)
            end

            local maxShelveAttempts = math.max(30, #carried * 2 + 10)
            local attempts = 0
            while #getCarriedBooks() > 0 and attempts < maxShelveAttempts and ScriptInstance.Running and _G.CleanMagic_CurrentToken == currentToken do
                attempts += 1
                task.wait(0.182)

                local currentCarried = getCarriedBooks()
                if #currentCarried == 0 then break end

                local topBook = currentCarried[1]
                local topSeries = topBook and topBook:GetAttribute("Series") or carriedSeries

                local curShelf = topSeries and findShelfBySeries(topSeries) or targetShelf
                if curShelf then
                    if (root.Position - curShelf.Position).Magnitude > 26 then
                        root.CFrame = getShelfFrontCFrame(curShelf)
                        task.wait(0.08)
                    end

                    local ok, res = pcall(function()
                        return Network.shelve.call(curShelf)
                    end)

                    -- หากส่งผิดตู้เพราะมีหนังสือคละซีรีส์ ให้สลับไปตู้ที่ถูกต้องทันที
                    if ok and type(res) == "table" and res.status == "WrongShelf" and res.series then
                        local correctShelf = findShelfBySeries(res.series)
                        if correctShelf then
                            root.CFrame = getShelfFrontCFrame(correctShelf)
                            task.wait(0.08)
                            pcall(function()
                                Network.shelve.call(correctShelf)
                            end)
                        end
                    end
                end
            end

            if carriedSeries and isShelfCompleted(carriedSeries) then
                print(string.format("[Clean Magic] Shelf %s Completed! 1 Spell Point Earned!", carriedSeries))
                currentTargetSeries = nil
            end
        end
        isFarming = false
        return
    end

    -- [กรณีที่ 2]: หากมือว่าง ให้ล็อคเป้าหมายที่ "ตู้เดิมที่ยังไม่เต็ม" หรือเลือกตู้ที่ใกล้เต็มที่สุด
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

    -- กรณี Fallback: หากไม่มีตู้เป้าหมายที่ค้างอยู่ ให้เก็บหนังสือเล่มใดก็ได้ที่ยังไม่เต็มตู้
    if #looseBooks > 0 then
        local myPos = root.Position
        local bestBook = nil
        local bestDist = math.huge

        for _, b in ipairs(looseBooks) do
            if isBookAvailable(b) then
                local d = (b.Position - myPos).Magnitude
                if d < bestDist then
                    bestDist = d
                    bestBook = b
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

    task.wait(0.1)
    isFarming = false
end

-- ลูปหลักสำหรับ Auto Farm (Books)
task.spawn(function()
    while ScriptInstance.Running and _G.CleanMagic_CurrentToken == currentToken do
        if Config.AutoFarm then
            pcall(processFarmStep)
            task.wait(0.005)
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
                                task.wait(0.08)
                            end
                            if Network and Network.collectGem then
                                pcall(function()
                                    Network.collectGem.call(gem)
                                end)
                            end
                            if not Config.AutoFarm then
                                task.wait(0.05)
                            end
                        end
                    end
                end
            end
            task.wait(0.25)
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
-- 8. AUTO UPGRADES (POWER-UPS PRIORITY & SPELLS BALANCED CHECKBOX)
-- --------------------------------------------------------
task.spawn(function()
    while ScriptInstance.Running and _G.CleanMagic_CurrentToken == currentToken do
        task.wait(0.8)
        if Config.AutoUpgrade and Network and Network.upgrade and UpgradesConfig then
            local upPoints = player:GetAttribute("UpgradePoints") or 0
            local spPoints = player:GetAttribute("SpellPoints") or 0

            -- 1. อัปเกรด Power-ups ตามลำดับ Priority (PowerUpOrder)
            if upPoints > 0 then
                for _, upgradeId in ipairs(Config.PowerUpOrder) do
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
                                task.wait(0.3)
                                break
                            end
                        end
                    end
                end
            end

            -- 2. อัปเกรด Spells แบบ "เฉลี่ยระดับ" (Balanced / Lowest Level First) เฉพาะที่ Checkbox ไว้
            if spPoints > 0 then
                local candidates = {}
                for spellId, isChecked in pairs(Config.SpellCheckboxes) do
                    if isChecked then
                        local info = UpgradesConfig.ById[spellId]
                        if info then
                            local currentLevel = player:GetAttribute(UpgradesConfig.LevelAttributePrefix .. spellId) or 0
                            local maxLevel = info.MaxLevel or 15
                            if currentLevel < maxLevel then
                                table.insert(candidates, {
                                    id = spellId,
                                    level = currentLevel,
                                    name = info.Name
                                })
                            end
                        end
                    end
                end

                table.sort(candidates, function(a, b)
                    return a.level < b.level
                end)

                if #candidates > 0 then
                    local targetSpell = candidates[1]
                    local ok, res = pcall(function()
                        return Network.upgrade.call(targetSpell.id, false)
                    end)
                    if ok and res and res.status == "Ok" then
                        print(string.format("[Clean Magic] Balanced Upgrade Spell: %s (Lv.%d -> Lv.%d)", targetSpell.name, targetSpell.level, targetSpell.level + 1))
                        task.wait(0.3)
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
    OnUnload = function()
        ScriptInstance.Running = false
        Config.AutoFarm = false
        Config.AutoGems = false
        Config.AutoUpgrade = false
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

if Window.RightColumn and Window.RightColumn.Parent and Window.RightColumn.Parent.Parent then
    Window.RightColumn.Parent.Parent.Visible = false
end

local leftCol = Window:GetColumn("Left")

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

local function createDropdownButton(yPos: number, title: string, color: Color3)
    local shadow = Instance.new("Frame")
    shadow.Size = UDim2.new(1, 0, 0, 42)
    shadow.Position = UDim2.fromOffset(0, yPos)
    shadow.BackgroundColor3 = Color3.fromRGB(16, 3, 26)
    shadow.BorderSizePixel = 0
    shadow.ZIndex = 20
    shadow.Parent = leftCol
    Instance.new("UICorner", shadow).CornerRadius = UDim.new(0, 13)

    local rim = Instance.new("Frame")
    rim.Size = UDim2.new(1, 0, 0, 39)
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

local powerUpDropShadow, powerUpDropBtn, powerUpArrow = createDropdownButton(184, "Priority: Power-ups", Color3.fromRGB(75, 215, 140))
local spellDropShadow, spellDropBtn, spellArrow = createDropdownButton(230, "Spells Upgrade (Balanced)", Color3.fromRGB(250, 180, 80))

local targetScreenGui = Window.Gui or CoreGui:FindFirstChild(GUI_NAME)

-- --------------------------------------------------------
-- POPUP A: POWER-UPS PRIORITY POPUP (PURE 5 ITEMS ONLY ▲ / ▼)
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

local renderPowerUpList = nil
renderPowerUpList = function()
    for _, ch in ipairs(scrollPowerUp:GetChildren()) do
        if ch:IsA("Frame") then ch:Destroy() end
    end

    for idx, upgradeId in ipairs(Config.PowerUpOrder) do
        local info = UpgradesConfig and UpgradesConfig.ById[upgradeId]
        local displayName = info and info.Name or upgradeId

        local itemFrame = Instance.new("Frame")
        itemFrame.Size = UDim2.new(1, -6, 0, 34)
        itemFrame.BackgroundColor3 = Color3.fromRGB(24, 62, 42)
        itemFrame.BorderSizePixel = 0
        itemFrame.ZIndex = 854
        itemFrame.Parent = scrollPowerUp
        Instance.new("UICorner", itemFrame).CornerRadius = UDim.new(0, 7)

        local itemStroke = Instance.new("UIStroke")
        itemStroke.Parent = itemFrame
        itemStroke.Thickness = 1.5
        itemStroke.Color = Color3.fromRGB(22, 5, 36)

        local numBadge = Instance.new("TextLabel")
        numBadge.Size = UDim2.fromOffset(24, 34)
        numBadge.Position = UDim2.fromOffset(4, 0)
        numBadge.BackgroundTransparency = 1
        numBadge.Text = string.format("#%d", idx)
        numBadge.TextColor3 = Color3.fromRGB(255, 215, 90)
        numBadge.TextSize = 11.5
        numBadge.Font = Enum.Font.FredokaOne
        numBadge.ZIndex = 855
        numBadge.Parent = itemFrame

        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(1, -84, 1, 0)
        nameLabel.Position = UDim2.fromOffset(30, 0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = displayName
        nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        nameLabel.TextSize = 11.5
        nameLabel.Font = Enum.Font.FredokaOne
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
        nameLabel.ZIndex = 855
        nameLabel.Parent = itemFrame

        if idx > 1 then
            local upBtn = Instance.new("TextButton")
            upBtn.Size = UDim2.fromOffset(22, 22)
            upBtn.Position = UDim2.new(1, -50, 0.5, -11)
            upBtn.BackgroundColor3 = Color3.fromRGB(35, 90, 60)
            upBtn.Text = "▲"
            upBtn.TextColor3 = Color3.fromRGB(255, 225, 95)
            upBtn.TextSize = 11
            upBtn.Font = Enum.Font.FredokaOne
            upBtn.BorderSizePixel = 0
            upBtn.ZIndex = 856
            upBtn.Parent = itemFrame
            Instance.new("UICorner", upBtn).CornerRadius = UDim.new(0, 5)

            upBtn.Activated:Connect(function()
                local temp = Config.PowerUpOrder[idx]
                Config.PowerUpOrder[idx] = Config.PowerUpOrder[idx - 1]
                Config.PowerUpOrder[idx - 1] = temp
                saveConfig()
                renderPowerUpList()
            end)
        end

        if idx < #Config.PowerUpOrder then
            local downBtn = Instance.new("TextButton")
            downBtn.Size = UDim2.fromOffset(22, 22)
            downBtn.Position = UDim2.new(1, -26, 0.5, -11)
            downBtn.BackgroundColor3 = Color3.fromRGB(35, 90, 60)
            downBtn.Text = "▼"
            downBtn.TextColor3 = Color3.fromRGB(255, 225, 95)
            downBtn.TextSize = 11
            downBtn.Font = Enum.Font.FredokaOne
            downBtn.BorderSizePixel = 0
            downBtn.ZIndex = 856
            downBtn.Parent = itemFrame
            Instance.new("UICorner", downBtn).CornerRadius = UDim.new(0, 5)

            downBtn.Activated:Connect(function()
                local temp = Config.PowerUpOrder[idx]
                Config.PowerUpOrder[idx] = Config.PowerUpOrder[idx + 1]
                Config.PowerUpOrder[idx + 1] = temp
                saveConfig()
                renderPowerUpList()
            end)
        end
    end
end

renderPowerUpList()

-- --------------------------------------------------------
-- POPUP B: SPELLS CHECKBOX POPUP (เฉลี่ยอัปเกรด BALANCED)
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
        print(string.format("[Clean Magic] Spell %s Balanced Upgrade: %s", displayName, current and "ON" or "OFF"))
    end

    rowBtn.Activated:Connect(toggleCheck)
end

-- จัดการการเปิด/ปิด Popups สลับกันอย่างอิสระ
local function closeAllPopups()
    powerUpPopup.Visible = false
    spellPopup.Visible = false
    powerUpArrow.Text = "▼"
    spellArrow.Text = "▼"
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

print("[BehindTheDark] Clean the Magic Library (In-Match Hub) Loaded & Restored.")
