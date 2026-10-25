-- ดึง Library ผ่าน Loadstring (หรือ require)
local Library = loadstring(game:HttpGet("ลิงก์_GITHUB_ของ_LIBRARY_คุณ"))()

-- 1. สร้างหน้าต่างหลัก
local Window = Library:CreateWindow({
    Title = "BEHIND THE DARK",
    Name = "BehindTheDark_Match"
})

-- 2. สร้างปุ่มสลับสถานะฝั่งซ้าย (Auto Again, Next, Home)
local autoNext = Window:CreateToggle("Left", "Auto Next", 0, { On = Color3.fromRGB(235, 65, 135), Off = Color3.fromRGB(120, 120, 130) }, false, function(val)
    states.EndChoice = val and "NEXT" or "NONE"
end)

local autoAgain = Window:CreateToggle("Left", "Auto Again", 46, { On = Color3.fromRGB(240, 150, 40), Off = Color3.fromRGB(120, 120, 130) }, true, function(val)
    states.EndChoice = val and "AGAIN" or "NONE"
end)

-- 3. สร้างปุ่มระบบต่อสู้และ Dropdown ฝั่งขวา
local autoUpgrade = Window:CreateToggle("Right", "Auto Upgrade All", 0, { On = Color3.fromRGB(90, 195, 60), Off = Color3.fromRGB(120, 120, 130) }, true, function(val)
    states.AutoUpgrade = val
end)

local stageDropdown = Window:CreateDropdown("Right", "Stage", 190, { "Inf Bug Milk", "Raid Halloween" }, "Inf Bug Milk", 10, function(selected)
    states.CurrentStage = selected
end)

-- 4. เรียกปุ่ม 3D Blackout Curtain ที่มุมขวาล่าง
Window:Create3DRenderToggle()
