repeat task.wait() until game:IsLoaded()

local placeId = game.PlaceId

local function runRemoteScript(url: string)
    local success, content = pcall(function()
        return game:HttpGet(url)
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

    func()
end

-- ตรวจสอบ PlaceId เพื่อเลือกรัน (เปลี่ยน PlaceId ของ Lobby ให้ตรงกับเกมของคุณ)
if placeId == 111053011787075 then
    runRemoteScript("https://raw.githubusercontent.com/PKNUDG/BehindTheDarkLib/main/lobby.luau")
else
    runRemoteScript("https://raw.githubusercontent.com/PKNUDG/BehindTheDarkLib/main/in-match.luau")
end
