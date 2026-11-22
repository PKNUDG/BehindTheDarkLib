-- ========================================================
-- BEHIND THE DARK : UNIVERSAL AUTO-DETECT LOADER v2
-- รัน loadstring(game:HttpGet("https://raw.githubusercontent.com/PKNUDG/BehindTheDarkLib/main/loader.luau?v=" .. os.time()))()
-- ตรวจแมพอัตโนมัติ — ไม่ต้องรันไฟล์ตรงๆ
-- ========================================================

-- รอเกมโหลดให้เสร็จก่อน
if not game:IsLoaded() then
    local loaded = false
    local conn
    conn = game.Loaded:Connect(function()
        loaded = true
        if conn then conn:Disconnect() end
    end)
    local startT = tick()
    while not loaded and not game:IsLoaded() and (tick() - startT < 10) do
        task.wait(0.2)
    end
end

-- รอ PlaceId ถูกต้อง
local startWaitPlace = tick()
while (not game.PlaceId or game.PlaceId == 0) and (tick() - startWaitPlace < 5) do
    task.wait(0.1)
end

local BASE_URL = "https://raw.githubusercontent.com/PKNUDG/BehindTheDarkLib/main/"

-- ดึงสคริปต์จาก GitHub แล้วรัน
local function runRemoteScript(path: string)
    local url = BASE_URL .. path .. "?v=" .. os.time()
    local ok, content = pcall(function() return game:HttpGet(url) end)
    if not ok or not content or content == "" or content:find("404: Not Found") then
        warn("[Loader] โหลดไม่สำเร็จ: " .. url)
        return false
    end
    local func, err = loadstring(content)
    if not func then
        warn("[Loader] Syntax Error: " .. tostring(err))
        return false
    end
    task.spawn(func)
    return true
end

-- ตรวจสอบว่า ReplicatedStorage มีโฟลเดอร์/วัตถุที่ระบุหรือไม่
local RS = game:GetService("ReplicatedStorage")
local function hasRS(name: string): boolean
    return RS:FindFirstChild(name) ~= nil
end

local function hasRSDeep(name: string, childName: string): boolean
    local parent = RS:FindFirstChild(name)
    return parent ~= nil and parent:FindFirstChild(childName) ~= nil
end

-- ============================================================
-- ตาราง GAME MAP REGISTRY
-- แต่ละ entry มี:
--   detect   : function() -> boolean  (ตรวจว่าอยู่ในเกมนี้ไหม)
--   script   : path บน GitHub (ไม่ต้องใส่ BASE_URL)
-- ============================================================
local GAME_REGISTRY: {{
    name: string,
    detect: () -> boolean,
    script: string,
}} = {
    -- ─── Candy TD : Lobby ────────────────────────────────────────
    {
        name   = "Candy TD (Lobby)",
        detect = function()
            return game.PlaceId == 111053011787075
        end,
        script = "CandyTD/lobby.luau",
    },
    -- ─── Candy TD : In-Match (PlaceId ≠ Lobby แต่มี CandyTD) ─────
    {
        name   = "Candy TD (In-Match)",
        detect = function()
            return hasRS("CandyTD")
        end,
        script = "CandyTD/in-match.luau",
    },
    -- ─── GloryBound (ตรวจ TrainRep remote ที่ไม่ซ้ำกับเกมอื่น) ───
    {
        name   = "GloryBound",
        detect = function()
            local remotes = RS:FindFirstChild("Remotes")
            if not remotes then return false end
            return remotes:FindFirstChild("TrainRep") ~= nil
                or remotes:FindFirstChild("Rebirth") ~= nil
        end,
        script = "GloryBound/lobby.luau",
    },
    -- ─── Clean the Magic Library : In-Match ─────────────────────
    {
        name   = "Clean the Magic Library (In-Match)",
        detect = function()
            return hasRS("Network")
                and hasRSDeep("States", "Library")
                and hasRSDeep("States", "Wizard")
        end,
        script = "CleanMagicLibrary/in-match.luau",
    },
    -- ─── Clean the Magic Library : Lobby (fallback) ─────────────
    {
        name   = "Clean the Magic Library (Lobby)",
        detect = function()
            -- lobby มี Packages แต่ยังไม่มี Network หรือ States/Wizard
            return hasRS("Packages") and not hasRS("Network")
        end,
        script = "CleanMagicLibrary/lobby.luau",
    },
}

-- ============================================================
-- ตรวจแมพ — รอ RS พร้อมสูงสุด 15 วินาที แล้วลอง detect ทุก entry
-- ============================================================
print("[Loader] 🔍 กำลังตรวจสอบแมพ... PlaceId =", game.PlaceId)

local detected = false
local retryTimeout = 15
local retryStart = tick()

repeat
    for _, entry in ipairs(GAME_REGISTRY) do
        local ok, result = pcall(entry.detect)
        if ok and result then
            print("[Loader] ✅ ตรวจพบแมพ:", entry.name, "→ โหลด", entry.script)
            runRemoteScript(entry.script)
            detected = true
            break
        end
    end
    if not detected then task.wait(0.5) end
until detected or (tick() - retryStart > retryTimeout)

if not detected then
    warn("[Loader] ⚠️ ไม่สามารถระบุแมพได้ภายใน", retryTimeout, "วินาที — PlaceId:", game.PlaceId)
    warn("[Loader] ReplicatedStorage children:")
    for _, child in ipairs(RS:GetChildren()) do
        warn("  •", child.Name, "(", child.ClassName, ")")
    end
end
