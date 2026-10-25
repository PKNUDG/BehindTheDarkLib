repeat task.wait() until game:IsLoaded()

local placeId = game.PlaceId

-- ใส่ PlaceId ของเกม Candy TD (เช็คว่าอยู่ล็อบบี้หรือในแมตช์)
-- ถ้า PlaceId ของ Lobby และ Match แยกกัน
if placeId == 1234567890 then -- ใส่ PlaceId ของห้อง Lobby ตรงนี้
    loadstring(game:HttpGet("https://raw.githubusercontent.com/PKNUDG/BehindTheDarkLib/main/lobby.luau"))()
else
    loadstring(game:HttpGet("https://raw.githubusercontent.com/PKNUDG/BehindTheDarkLib/main/in-match.luau"))()
end
