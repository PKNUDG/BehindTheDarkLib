-- ========================================================
-- BEHIND THE DARK : UNIVERSAL PERSISTENT LOADER
-- ========================================================
local LOADER_URL = "https://raw.githubusercontent.com/PKNUDG/BehindTheDarkLib/main/loader.luau"

-- 1. ฟังก์ชันติดตั้งคิวข้ามแมพแบบปลอดภัย (รอโหลดให้เสร็จก่อนดึงโค้ด)
local function armTeleportQueue()
    local qot = (syn and syn.queue_on_teleport) or queue_on_teleport or (fluxus and fluxus.queue_on_teleport)
    if qot then
        pcall(function()
            local queueScript = [[
                if not game:IsLoaded() then
                    game.Loaded:Wait()
                end
                task.wait(1.5)
                local url = "https://raw.githubusercontent.com/PKNUDG/BehindTheDarkLib/main/loader.luau"
                local s, content = pcall(game.HttpGet, game, url .. "?v=" .. os.time())
                if s and content and content ~= "" and not content:find("404: Not Found") then
                    local chunk, err = loadstring(content)
                    if chunk then
                        task.spawn(chunk)
                    end
                end
            ]]
            qot(queueScript)
        end)
    end
end

-- ดักจับคิวการย้ายแมพ
armTeleportQueue()

local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()
if localPlayer then
    pcall(function()
        localPlayer.OnTeleport:Connect(function()
            armTeleportQueue()
        end)
    end)
end

-- 2. รอโหลดเกมและ PlaceId ให้พร้อม
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

local startWaitPlace = tick()
while (not game.PlaceId or game.PlaceId == 0) and (tick() - startWaitPlace < 5) do
    task.wait(0.1)
end

local placeId = game.PlaceId

-- 3. ฟังก์ชันรันสคริปต์ปลายทาง
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

-- 4. ตรวจสอบ PlaceId เพื่อเลือกรัน (Lobby vs Match)
local LOBBY_PLACE_ID = 111053011787075[cite: 19]

if placeId == LOBBY_PLACE_ID then
    print("[Loader] ตรวจพบห้อง Lobby (PlaceId: " .. tostring(placeId) .. ") กำลังโหลด lobby.luau")
    runRemoteScript("https://raw.githubusercontent.com/PKNUDG/BehindTheDarkLib/main/lobby.luau")[cite: 19]
else
    print("[Loader] ตรวจพบห้อง Match (PlaceId: " .. tostring(placeId) .. ") กำลังโหลด in-match.luau")
    runRemoteScript("https://raw.githubusercontent.com/PKNUDG/BehindTheDarkLib/main/in-match.luau")[cite: 19]
end
