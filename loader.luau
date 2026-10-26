-- ========================================================
-- BEHIND THE DARK : UNIVERSAL PERSISTENT LOADER
-- ========================================================
-- 1. ป้องกันลูปค้างตอนข้ามแมพ
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

-- 2. รอให้ PlaceId ถูกต้อง (ไม่ใช่ 0 หรือ nil)
local startWaitPlace = tick()
while (not game.PlaceId or game.PlaceId == 0) and (tick() - startWaitPlace < 5) do
    task.wait(0.1)
end

local placeId = game.PlaceId
local LOADER_URL = "https://raw.githubusercontent.com/PKNUDG/BehindTheDarkLib/main/loader.luau"

-- 3. ระบบต่ออายุ Auto Execute ข้ามแมพตลอดชีพ (Persistent Teleport Queue)
local function armTeleportQueue()
    local qot = (syn and syn.queue_on_teleport) or queue_on_teleport or (fluxus and fluxus.queue_on_teleport)
    if qot then
        pcall(function()
            qot(string.format('loadstring(game:HttpGet("%s?v=" .. os.time()))()', LOADER_URL))
        end)
    end
end

-- ดักใส่คิวทันทีตั้งแต่เข้าแมพ และดักจับ Event การย้ายแมพทุกครั้ง
armTeleportQueue()

local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()
if localPlayer then
    pcall(function()
        localPlayer.OnTeleport:Connect(function(teleportState)
            armTeleportQueue()
        end)
    end)
end

-- 4. ฟังก์ชันดาวน์โหลดและรันสคริปต์ปลายทาง
local function runRemoteScript(url: string)
    local success, content = pcall(function()
        return game:HttpGet(url .. "?v=" .. os.time())
    end)

    if not success or not content or content == "" or content:find("404: Not Found") then
        warn("[Loader] โหลดไฟล์ไม่สำเร็จ URL ผิดพลาด: " .. url)
        return
    end

    local func, err = loadstring(content)
    if not func then
        warn("[Loader] Syntax Error ในสคริปต์ปลายทาง: " .. tostring(err))
        return
    end

    task.spawn(func)
end

-- 5. ตรวจสอบ PlaceId เพื่อแยกรัน Lobby / Match
local LOBBY_PLACE_ID = 111053011787075[cite: 19]

if placeId == LOBBY_PLACE_ID then
    print("[Loader] ตรวจพบห้อง Lobby (PlaceId: " .. tostring(placeId) .. ") กำลังโหลด lobby.luau")
    runRemoteScript("https://raw.githubusercontent.com/PKNUDG/BehindTheDarkLib/main/lobby.luau")[cite: 19]
else
    print("[Loader] ตรวจพบห้อง Match (PlaceId: " .. tostring(placeId) .. ") กำลังโหลด in-match.luau")
    runRemoteScript("https://raw.githubusercontent.com/PKNUDG/BehindTheDarkLib/main/in-match.luau")[cite: 19]
end
