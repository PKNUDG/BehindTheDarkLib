-- ========================================================
-- BEHIND THE DARK : SIMPLE LOADER (NO TELEPORT QUEUE)
-- ========================================================
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

-- รอให้ PlaceId ถูกต้อง
local startWaitPlace = tick()
while (not game.PlaceId or game.PlaceId == 0) and (tick() - startWaitPlace < 5) do
    task.wait(0.1)
end

local placeId = game.PlaceId

-- ฟังก์ชันดาวน์โหลดและรันสคริปต์
local function runRemoteScript(url: string)
    local success, content = pcall(function()
        return game:HttpGet(url .. "?v=" .. os.time())
    end)

    if not success or not content or content == "" or content:find("404: Not Found") then
        warn("[Loader] โหลดไฟล์ไม่สำเร็จ: " .. url)
        return
    end

    local func, err = loadstring(content)
    if not func then
        warn("[Loader] Syntax Error ในสคริปต์: " .. tostring(err))
        return
    end

    task.spawn(func)
end

-- แยกรันระหว่าง Lobby และ In-Match
local LOBBY_PLACE_ID = 111053011787075

if placeId == LOBBY_PLACE_ID then
    print("[Loader] กำลังโหลด lobby.luau")
    runRemoteScript("https://raw.githubusercontent.com/PKNUDG/BehindTheDarkLib/main/lobby.luau")
else
    print("[Loader] กำลังโหลด in-match.luau")
    runRemoteScript("https://raw.githubusercontent.com/PKNUDG/BehindTheDarkLib/main/in-match.luau")
end
