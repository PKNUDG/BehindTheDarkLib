-- ========================================================
-- BEHIND THE DARK : CORE UI LIBRARY (CANDY TD EXACT THEME)
-- ========================================================
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

local Library = {}
Library.__index = Library

local SETTINGS_FILE = "BehindTheDark_Settings.json"

Library.Settings = {
    MovingPattern = true,
    MovingAurora = true,
    ClickRipple = true,
    AnimeGlint = true
}

-- โหลดและบันทึกค่า Settings ลงไฟล์
local function loadSavedSettings()
    local rf = (type(readfile) == "function" and readfile) or nil
    if rf then
        local ok, data = pcall(rf, SETTINGS_FILE)
        if ok and data and data ~= "" then
            local decodedOk, parsed = pcall(HttpService.JSONDecode, HttpService, data)
            if decodedOk and type(parsed) == "table" then
                for k, v in pairs(parsed) do
                    if Library.Settings[k] ~= nil then
                        Library.Settings[k] = v
                    end
                end
            end
        end
    end
end

local function saveCurrentSettings()
    local wf = (type(writefile) == "function" and writefile) or nil
    if wf then
        pcall(function()
            local encoded = HttpService:JSONEncode(Library.Settings)
            wf(SETTINGS_FILE, encoded)
        end)
    end
end

loadSavedSettings()

-- ข้อมูล Tween
local springBounce = TweenInfo.new(0.32, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local pressSquish = TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local glintTween = TweenInfo.new(0.38, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local rippleTween = TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local toggleSlide = TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

-- สร้างเลเยอร์เทคเจอร์หยาบ + ลายจุดเลื่อนเป็นลูปภายในกรอบขนาดเท่าปุ่ม/การ์ด
local function applyCartoonSurface(target: GuiObject, zIndex: number, isButton: boolean)
    -- 1. เทคเจอร์เนื้อหยาบ (Rough Grain Texture)
    local grain = Instance.new("ImageLabel")
    grain.Name = "RoughGrain"
    grain.Size = UDim2.fromScale(1, 1)
    grain.BackgroundTransparency = 1
    grain.Image = "rbxassetid://13062441566" -- เนื้อกระดาษ/การ์ตูนหยาบ
    grain.ImageTransparency = isButton and 0.88 or 0.90
    grain.ScaleType = Enum.ScaleType.Tile
    grain.TileSize = UDim2.fromOffset(90, 90)
    grain.ZIndex = zIndex
    grain.Parent = target
    Instance.new("UICorner", grain).CornerRadius = UDim.new(0, isButton and 12 or 22)

    -- 2. ลวดลายจุด Polka Dots เลื่อนเป็นลูป (เฉพาะขนาดปุ่ม/การ์ดเนื่องจาก ClipsDescendants)
    local dotsHolder = Instance.new("Frame")
    dotsHolder.Name = "DotsClipper"
    dotsHolder.Size = UDim2.fromScale(1, 1)
    dotsHolder.BackgroundTransparency = 1
    dotsHolder.ClipsDescendants = true
    dotsHolder.ZIndex = zIndex
    dotsHolder.Parent = target
    Instance.new("UICorner", dotsHolder).CornerRadius = UDim.new(0, isButton and 12 or 22)

    local dots = Instance.new("ImageLabel")
    dots.Name = "LoopingDots"
    dots.Size = UDim2.new(1, 56, 1, 56)
    dots.Position = UDim2.fromOffset(0, 0)
    dots.BackgroundTransparency = 1
    dots.Image = "rbxassetid://6071575925"
    dots.ImageColor3 = Color3.fromRGB(235, 210, 255)
    dots.ImageTransparency = isButton and 0.87 or 0.91
    dots.ScaleType = Enum.ScaleType.Tile
    dots.TileSize = UDim2.fromOffset(28, 28)
    dots.ZIndex = zIndex
    dots.Parent = dotsHolder

    task.spawn(function()
        local loopDuration = isButton and 4.5 or 7
        while dots and dots.Parent do
            if Library.Settings.MovingPattern then
                dots.Position = UDim2.fromOffset(0, 0)
                local tw = TweenService:Create(dots, TweenInfo.new(loopDuration, Enum.EasingStyle.Linear), {
                    Position = UDim2.fromOffset(-28, -28)
                })
                tw:Play()
                task.wait(loopDuration)
            else
                task.wait(0.5)
            end
        end
    end)
end

-- Click Ripple Effect
local function spawnClickRipple(btn: GuiButton, inputPos: Vector3)
    if not Library.Settings.ClickRipple then return end
    
    local relX = inputPos.X - btn.AbsolutePosition.X
    local relY = inputPos.Y - btn.AbsolutePosition.Y

    local ripple = Instance.new("Frame")
    ripple.Name = "ClickRipple"
    ripple.AnchorPoint = Vector2.new(0.5, 0.5)
    ripple.Position = UDim2.fromOffset(relX, relY)
    ripple.Size = UDim2.fromOffset(0, 0)
    ripple.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    ripple.BackgroundTransparency = 0.45
    ripple.BorderSizePixel = 0
    ripple.ZIndex = btn.ZIndex + 3
    ripple.Parent = btn
    Instance.new("UICorner", ripple).CornerRadius = UDim.new(1, 0)

    local targetSize = math.max(btn.AbsoluteSize.X, btn.AbsoluteSize.Y) * 2.1
    local tw = TweenService:Create(ripple, rippleTween, {
        Size = UDim2.fromOffset(targetSize, targetSize),
        BackgroundTransparency = 1
    })
    tw:Play()
    tw.Completed:Connect(function()
        ripple:Destroy()
    end)
end

-- ระบบย่อ-ขยายปุ่มด้วย UIScale (แก้บั๊กตัวอักษรเลื่อนตกขอบ 100%)
function Library.AttachInteractiveEffects(btn: GuiButton)
    local isHovered = false
    btn.ClipsDescendants = true

    local uiScale = btn:FindFirstChildOfClass("UIScale")
    if not uiScale then
        uiScale = Instance.new("UIScale")
        uiScale.Scale = 1
        uiScale.Parent = btn
    end

    -- แสงสะท้อนแว่นการ์ตูน
    local glint = Instance.new("Frame")
    glint.Name = "AnimeGlint"
    glint.Size = UDim2.new(0.26, 0, 2.6, 0)
    glint.Position = UDim2.new(-0.7, 0, -0.8, 0)
    glint.Rotation = 22
    glint.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    glint.BackgroundTransparency = 0.55
    glint.BorderSizePixel = 0
    glint.ZIndex = btn.ZIndex + 2
    glint.Parent = btn
    Instance.new("UICorner", glint).CornerRadius = UDim.new(1, 0)

    local sharpLine = Instance.new("Frame")
    sharpLine.Size = UDim2.new(0.2, 0, 1, 0)
    sharpLine.Position = UDim2.new(1.15, 0, 0, 0)
    sharpLine.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    sharpLine.BackgroundTransparency = 0.35
    sharpLine.BorderSizePixel = 0
    sharpLine.ZIndex = btn.ZIndex + 2
    sharpLine.Parent = glint

    btn.MouseEnter:Connect(function()
        isHovered = true
        TweenService:Create(uiScale, springBounce, { Scale = 1.025 }):Play()

        if Library.Settings.AnimeGlint then
            glint.Position = UDim2.new(-0.7, 0, -0.8, 0)
            glint.BackgroundTransparency = 0.52
            TweenService:Create(glint, glintTween, {
                Position = UDim2.new(1.5, 0, -0.8, 0),
                BackgroundTransparency = 0.85
            }):Play()
        end
    end)

    btn.MouseLeave:Connect(function()
        isHovered = false
        TweenService:Create(uiScale, springBounce, { Scale = 1 }):Play()
    end)

    btn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            spawnClickRipple(btn, input.Position)
            TweenService:Create(uiScale, pressSquish, { Scale = 0.94 }):Play()
        end
    end)

    btn.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            local targetScale = isHovered and 1.025 or 1
            TweenService:Create(uiScale, springBounce, { Scale = targetScale }):Play()
        end
    end)
end

function Library:CreateWindow(config: {Title: string, Name: string, Size: UDim2?, OnUnload: (() -> ())?})
    local self = setmetatable({}, Library)
    local width = config.Size and config.Size.X.Offset or 660
    local height = config.Size and config.Size.Y.Offset or 440

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = config.Name or "BehindTheDarkHub"
    screenGui.ResetOnSpawn = false
    screenGui.IgnoreGuiInset = true
    screenGui.DisplayOrder = 999

    local success = pcall(function() screenGui.Parent = CoreGui end)
    if not success then
        local p = Players.LocalPlayer
        screenGui.Parent = p and p:FindFirstChild("PlayerGui")
    end
    self.Gui = screenGui

    -- จอดำบังหลังเวลาปิด 3D
    local blackout = Instance.new("Frame")
    blackout.Name = "BlackoutFrame"
    blackout.Size = UDim2.fromScale(1, 1)
    blackout.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    blackout.BackgroundTransparency = 0.08
    blackout.BorderSizePixel = 0
    blackout.ZIndex = 1
    blackout.Visible = false
    blackout.Parent = screenGui
    self.BlackoutFrame = blackout

    -- 1. กรอบหลังสุดของ UI (Outer Shell) สีม่วงลาเวนเดอร์ตามรูป
    local card = Instance.new("Frame")
    card.Name = "MainCard"
    card.Size = UDim2.fromOffset(width, height)
    card.Position = UDim2.new(0.5, -width / 2, 0.5, -height / 2)
    card.BackgroundColor3 = Color3.fromRGB(132, 92, 196)
    card.BorderSizePixel = 0
    card.Active = true
    card.ClipsDescendants = true
    card.ZIndex = 2
    card.Parent = screenGui
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 24)

    -- ขอบหนาสีเข้มคงที่ (ไม่มีการหายใจเรืองแสง)
    local cardStroke = Instance.new("UIStroke", card)
    cardStroke.Thickness = 5
    cardStroke.Color = Color3.fromRGB(36, 10, 58)

    -- ใส่ลวดลายเลื่อนเป็นลูปและเทคเจอร์หยาบให้พื้นหลังสุด
    applyCartoonSurface(card, 2, false)

    -- Dynamic Moving Aurora Gradient
    local bgGradient = Instance.new("UIGradient")
    bgGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(152, 110, 218)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(125, 84, 188)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(102, 65, 162))
    })
    bgGradient.Rotation = 45
    bgGradient.Enabled = Library.Settings.MovingAurora
    bgGradient.Parent = card
    TweenService:Create(bgGradient, TweenInfo.new(14, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1), { Rotation = 405 }):Play()

    self.MainCard = card

    -- ระบบลากหน้าต่าง
    local dragging, dragStart, startPos = false, nil, nil
    card.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = card.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    card.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            if dragging then
                local delta = input.Position - dragStart
                card.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            end
        end
    end)

    -- 2. Title Bar
    local titlePlate = Instance.new("Frame")
    titlePlate.Size = UDim2.new(1, -28, 0, 44)
    titlePlate.Position = UDim2.fromOffset(14, 12)
    titlePlate.BackgroundColor3 = Color3.fromRGB(42, 14, 68)
    titlePlate.BorderSizePixel = 0
    titlePlate.ZIndex = 4
    titlePlate.Parent = card
    Instance.new("UICorner", titlePlate).CornerRadius = UDim.new(0, 14)
    local tpStroke = Instance.new("UIStroke", titlePlate)
    tpStroke.Thickness = 3.5
    tpStroke.Color = Color3.fromRGB(24, 6, 38)

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -86, 1, 0)
    titleLabel.Position = UDim2.fromOffset(14, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = config.Title or "BEHIND THE DARK"
    titleLabel.TextColor3 = Color3.fromRGB(242, 230, 255) -- สีขาวอมม่วงอ่อนตามคำว่า WEARING ในรูป
    titleLabel.TextSize = 17
    titleLabel.Font = Enum.Font.FredokaOne
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.ZIndex = 6
    titleLabel.Parent = titlePlate
    local titleStroke = Instance.new("UIStroke", titleLabel)
    titleStroke.Thickness = 3.5
    titleStroke.Color = Color3.fromRGB(28, 6, 44)

    -- ปุ่มปิดสีแดง (Close / Unload)
    local closeBtnBase = Instance.new("Frame")
    closeBtnBase.Size = UDim2.fromOffset(30, 30)
    closeBtnBase.Position = UDim2.new(1, -36, 0.5, -15)
    closeBtnBase.BackgroundColor3 = Color3.fromRGB(140, 20, 25)
    closeBtnBase.BorderSizePixel = 0
    closeBtnBase.ZIndex = 6
    closeBtnBase.Parent = titlePlate
    Instance.new("UICorner", closeBtnBase).CornerRadius = UDim.new(0, 10)
    local cbStroke = Instance.new("UIStroke", closeBtnBase)
    cbStroke.Thickness = 2.5
    cbStroke.Color = Color3.fromRGB(28, 6, 44)

    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(1, 0, 1, -3)
    closeBtn.BackgroundColor3 = Color3.fromRGB(240, 75, 85)
    closeBtn.Text = "✕"
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.TextSize = 15
    closeBtn.Font = Enum.Font.FredokaOne
    closeBtn.BorderSizePixel = 0
    closeBtn.AutoButtonColor = false
    closeBtn.ZIndex = 7
    closeBtn.Parent = closeBtnBase
    Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 9)
    Library.AttachInteractiveEffects(closeBtn)

    closeBtn.Activated:Connect(function()
        if config.OnUnload then pcall(config.OnUnload) end
        screenGui:Destroy()
    end)

    -- ปุ่ม Settings สีเหลือง (ไม่มีไอคอนหรือตัวอักษร)
    local setBtnBase = Instance.new("Frame")
    setBtnBase.Size = UDim2.fromOffset(30, 30)
    setBtnBase.Position = UDim2.new(1, -72, 0.5, -15)
    setBtnBase.BackgroundColor3 = Color3.fromRGB(175, 120, 15)
    setBtnBase.BorderSizePixel = 0
    setBtnBase.ZIndex = 6
    setBtnBase.Parent = titlePlate
    Instance.new("UICorner", setBtnBase).CornerRadius = UDim.new(0, 10)
    local sbStroke = Instance.new("UIStroke", setBtnBase)
    sbStroke.Thickness = 2.5
    sbStroke.Color = Color3.fromRGB(28, 6, 44)

    local settingsBtn = Instance.new("TextButton")
    settingsBtn.Size = UDim2.new(1, 0, 1, -3)
    settingsBtn.BackgroundColor3 = Color3.fromRGB(255, 205, 55)
    settingsBtn.Text = ""
    settingsBtn.BorderSizePixel = 0
    settingsBtn.AutoButtonColor = false
    settingsBtn.ZIndex = 7
    settingsBtn.Parent = setBtnBase
    Instance.new("UICorner", settingsBtn).CornerRadius = UDim.new(0, 9)
    Library.AttachInteractiveEffects(settingsBtn)

    -- ========================================================
    -- 3. แบ่งเป็น 2 คอลัมน์ซ้าย-ขวา (Dual Dark Purple Trays ตามรูป)
    -- ========================================================
    local function createColumnTray(pos: UDim2, size: UDim2)
        local tray = Instance.new("Frame")
        tray.Size = size
        tray.Position = pos
        tray.BackgroundColor3 = Color3.fromRGB(40, 14, 64) -- สีม่วงดำลึกแบบถาด WEARING ในรูป
        tray.BorderSizePixel = 0
        tray.ZIndex = 3
        tray.Parent = card
        Instance.new("UICorner", tray).CornerRadius = UDim.new(0, 18)
        
        local trayStroke = Instance.new("UIStroke", tray)
        trayStroke.Thickness = 3.5
        trayStroke.Color = Color3.fromRGB(26, 6, 42)

        -- เทคเจอร์เนื้อหยาบในถาดคอลัมน์
        local trayGrain = Instance.new("ImageLabel")
        trayGrain.Size = UDim2.fromScale(1, 1)
        trayGrain.BackgroundTransparency = 1
        trayGrain.Image = "rbxassetid://13062441566"
        trayGrain.ImageTransparency = 0.92
        trayGrain.ScaleType = Enum.ScaleType.Tile
        trayGrain.TileSize = UDim2.fromOffset(80, 80)
        trayGrain.ZIndex = 3
        trayGrain.Parent = tray
        Instance.new("UICorner", trayGrain).CornerRadius = UDim.new(0, 18)

        local container = Instance.new("Frame")
        container.Size = UDim2.new(1, -20, 1, -20)
        container.Position = UDim2.fromOffset(10, 10)
        container.BackgroundTransparency = 1
        container.ZIndex = 4
        container.Parent = tray
        return container
    end

    self.LeftColumn = createColumnTray(UDim2.fromOffset(14, 64), UDim2.new(0.5, -20, 1, -76))
    self.RightColumn = createColumnTray(UDim2.new(0.5, 6, 0, 64), UDim2.new(0.5, -20, 1, -76))
    self.CenterColumn = self.LeftColumn

    -- ========================================================
    -- หน้าต่างตั้งค่ากราฟิก (Settings Modal จำค่าอัตโนมัติ)
    -- ========================================================
    local settingsModal = Instance.new("Frame")
    settingsModal.Name = "SettingsModal"
    settingsModal.Size = UDim2.fromOffset(270, 245)
    settingsModal.Position = UDim2.new(0.5, -135, 0.5, -122)
    settingsModal.BackgroundColor3 = Color3.fromRGB(48, 16, 76)
    settingsModal.BorderSizePixel = 0
    settingsModal.ZIndex = 70
    settingsModal.Visible = false
    settingsModal.Parent = card
    Instance.new("UICorner", settingsModal).CornerRadius = UDim.new(0, 18)
    local smStroke = Instance.new("UIStroke", settingsModal)
    smStroke.Thickness = 4
    smStroke.Color = Color3.fromRGB(26, 6, 42)

    local smTitle = Instance.new("TextLabel")
    smTitle.Size = UDim2.new(1, -20, 0, 32)
    smTitle.Position = UDim2.fromOffset(10, 8)
    smTitle.BackgroundTransparency = 1
    smTitle.Text = "VISUAL SETTINGS"
    smTitle.TextColor3 = Color3.fromRGB(242, 230, 255)
    smTitle.TextSize = 15
    smTitle.Font = Enum.Font.FredokaOne
    smTitle.ZIndex = 71
    smTitle.Parent = settingsModal
    local smts = Instance.new("UIStroke", smTitle)
    smts.Thickness = 3
    smts.Color = Color3.fromRGB(26, 6, 42)

    local function createSettingRow(text: string, yPos: number, settingKey: string, onToggle: ((boolean) -> ())?)
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, -24, 0, 36)
        row.Position = UDim2.fromOffset(12, yPos)
        row.BackgroundColor3 = Color3.fromRGB(34, 10, 56)
        row.BorderSizePixel = 0
        row.ZIndex = 71
        row.Parent = settingsModal
        Instance.new("UICorner", row).CornerRadius = UDim.new(0, 10)
        local rs = Instance.new("UIStroke", row)
        rs.Thickness = 2
        rs.Color = Color3.fromRGB(24, 6, 38)

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -64, 1, 0)
        lbl.Position = UDim2.fromOffset(12, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = text
        lbl.TextColor3 = Color3.fromRGB(242, 230, 255)
        lbl.TextSize = 12.5
        lbl.Font = Enum.Font.FredokaOne
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.ZIndex = 72
        lbl.Parent = row
        local ls = Instance.new("UIStroke", lbl)
        ls.Thickness = 2.5
        ls.Color = Color3.fromRGB(26, 6, 42)

        local switchTrack = Instance.new("TextButton")
        switchTrack.Size = UDim2.fromOffset(44, 22)
        switchTrack.Position = UDim2.new(1, -52, 0.5, -11)
        switchTrack.BackgroundColor3 = Library.Settings[settingKey] and Color3.fromRGB(110, 215, 65) or Color3.fromRGB(85, 75, 105)
        switchTrack.Text = ""
        switchTrack.BorderSizePixel = 0
        switchTrack.AutoButtonColor = false
        switchTrack.ZIndex = 72
        switchTrack.Parent = row
        Instance.new("UICorner", switchTrack).CornerRadius = UDim.new(1, 0)
        local sts = Instance.new("UIStroke", switchTrack)
        sts.Thickness = 2
        sts.Color = Color3.fromRGB(26, 6, 42)

        local thumb = Instance.new("Frame")
        thumb.Size = UDim2.fromOffset(18, 18)
        thumb.Position = Library.Settings[settingKey] and UDim2.fromOffset(24, 2) or UDim2.fromOffset(2, 2)
        thumb.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        thumb.BorderSizePixel = 0
        thumb.ZIndex = 73
        thumb.Parent = switchTrack
        Instance.new("UICorner", thumb).CornerRadius = UDim.new(1, 0)

        switchTrack.Activated:Connect(function()
            Library.Settings[settingKey] = not Library.Settings[settingKey]
            local active = Library.Settings[settingKey]
            saveCurrentSettings()

            TweenService:Create(switchTrack, toggleSlide, {
                BackgroundColor3 = active and Color3.fromRGB(110, 215, 65) or Color3.fromRGB(85, 75, 105)
            }):Play()
            TweenService:Create(thumb, toggleSlide, {
                Position = active and UDim2.fromOffset(24, 2) or UDim2.fromOffset(2, 2)
            }):Play()

            if onToggle then onToggle(active) end
        end)
    end

    createSettingRow("Looping Pattern", 46, "MovingPattern")
    createSettingRow("Moving Aurora", 89, "MovingAurora", function(val)
        bgGradient.Enabled = val
    end)
    createSettingRow("Click Ripple", 132, "ClickRipple")
    createSettingRow("Anime Glint", 175, "AnimeGlint")

    settingsBtn.Activated:Connect(function()
        settingsModal.Visible = not settingsModal.Visible
    end)

    UserInputService.InputBegan:Connect(function(input, gpe)
        if not gpe and input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == Enum.KeyCode.RightShift then
            card.Visible = not card.Visible
        end
    end)

    return self
end

function Library:GetColumn(side: string): Frame
    if side == "Left" then return self.LeftColumn
    elseif side == "Right" then return self.RightColumn
    else return self.LeftColumn end
end

-- ========================================================
-- ปุ่ม TOGGLE สไตล์การ์ดม่วงมีจุดเลื่อน & เทคเจอร์หยาบตามภาพ
-- ========================================================
function Library:CreateToggle(side: string, text: string, yPos: number, colors: {On: Color3, Off: Color3}, default: boolean, callback: (boolean) -> ())
    local parent = self:GetColumn(side)
    local state = default or false

    -- ฐานเงาล่างของปุ่ม
    local base = Instance.new("Frame")
    base.Size = UDim2.new(1, 0, 0, 42)
    base.Position = UDim2.fromOffset(0, yPos)
    base.BackgroundColor3 = Color3.fromRGB(24, 6, 38)
    base.BorderSizePixel = 0
    base.ZIndex = 5
    base.Parent = parent
    Instance.new("UICorner", base).CornerRadius = UDim.new(0, 14)
    local bs = Instance.new("UIStroke", base)
    bs.Thickness = 2.5
    bs.Color = Color3.fromRGB(20, 4, 32)

    -- ตัวปุ่มหลัก (ขนาดเท่าปุ่ม ไม่ล้นหน้าจอ)
    local onColor = colors.On or Color3.fromRGB(162, 105, 235)
    local offColor = Color3.fromRGB(128, 78, 195)

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 1, -4)
    btn.Position = UDim2.fromOffset(0, 0)
    btn.BackgroundColor3 = state and onColor or offColor
    btn.BorderSizePixel = 0
    btn.AutoButtonColor = false
    btn.Text = ""
    btn.ClipsDescendants = true
    btn.ZIndex = 6
    btn.Parent = base
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 12)

    local btnStroke = Instance.new("UIStroke", btn)
    btnStroke.Thickness = 2.5
    btnStroke.Color = Color3.fromRGB(36, 10, 58)

    -- ใส่เทคเจอร์หยาบและลายจุดเลื่อนเป็นลูปเฉพาะในขอบเขตปุ่มนี้
    applyCartoonSurface(btn, 6, true)

    -- แถบสะท้อนแสงโค้งด้านบนเหมือนปุ่มในรูป
    local gloss = Instance.new("Frame")
    gloss.Size = UDim2.new(1, -12, 0.42, 0)
    gloss.Position = UDim2.fromOffset(6, 2)
    gloss.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    gloss.BackgroundTransparency = 0.78
    gloss.BorderSizePixel = 0
    gloss.ZIndex = 7
    gloss.Parent = btn
    Instance.new("UICorner", gloss).CornerRadius = UDim.new(0, 10)

    -- ตัวอักษรสีตามตัวอย่างในรูป (ขาวอมม่วงพาสเทล / ชมพูพีชเมื่อเปิด)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -68, 1, 0)
    label.Position = UDim2.fromOffset(14, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = state and Color3.fromRGB(255, 115, 125) or Color3.fromRGB(242, 230, 255)
    label.TextSize = 14
    label.Font = Enum.Font.FredokaOne
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.ZIndex = 8
    label.Text = text
    label.Parent = btn
    local ts = Instance.new("UIStroke", label)
    ts.Thickness = 3.2
    ts.Color = Color3.fromRGB(32, 6, 48)

    -- รางสวิตช์
    local switchTrack = Instance.new("Frame")
    switchTrack.Size = UDim2.fromOffset(42, 22)
    switchTrack.Position = UDim2.new(1, -50, 0.5, -11)
    switchTrack.BackgroundColor3 = Color3.fromRGB(32, 10, 52)
    switchTrack.BorderSizePixel = 0
    switchTrack.ZIndex = 8
    switchTrack.Parent = btn
    Instance.new("UICorner", switchTrack).CornerRadius = UDim.new(1, 0)
    local stStroke = Instance.new("UIStroke", switchTrack)
    stStroke.Thickness = 2
    stStroke.Color = Color3.fromRGB(24, 6, 38)

    local thumb = Instance.new("Frame")
    thumb.Size = UDim2.fromOffset(18, 18)
    thumb.Position = state and UDim2.fromOffset(22, 2) or UDim2.fromOffset(2, 2)
    thumb.BackgroundColor3 = state and Color3.fromRGB(130, 240, 85) or Color3.fromRGB(215, 195, 240)
    thumb.BorderSizePixel = 0
    thumb.ZIndex = 9
    thumb.Parent = switchTrack
    Instance.new("UICorner", thumb).CornerRadius = UDim.new(1, 0)

    Library.AttachInteractiveEffects(btn)

    local function setVisual(val: boolean)
        state = val
        TweenService:Create(btn, toggleSlide, {
            BackgroundColor3 = state and onColor or offColor
        }):Play()
        TweenService:Create(label, toggleSlide, {
            TextColor3 = state and Color3.fromRGB(255, 115, 125) or Color3.fromRGB(242, 230, 255)
        }):Play()
        TweenService:Create(thumb, toggleSlide, {
            Position = state and UDim2.fromOffset(22, 2) or UDim2.fromOffset(2, 2),
            BackgroundColor3 = state and Color3.fromRGB(130, 240, 85) or Color3.fromRGB(215, 195, 240)
        }):Play()
    end

    btn.Activated:Connect(function()
        state = not state
        setVisual(state)
        callback(state)
    end)

    return setVisual
end

-- ========================================================
-- DROPDOWN สไตล์การ์ตูนพร้อมลายจุดเลื่อนในปุ่ม
-- ========================================================
function Library:CreateDropdown(side: string, title: string, yPos: number, options: {any}, default: any, zIndexOffset: number, callback: (any) -> ())
    local parent = self:GetColumn(side)
    local selected = default
    local zBase = 15 + (zIndexOffset or 0)

    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, 0, 0, 42)
    card.Position = UDim2.fromOffset(0, yPos)
    card.BackgroundColor3 = Color3.fromRGB(24, 6, 38)
    card.BorderSizePixel = 0
    card.ZIndex = zBase
    card.Parent = parent
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 14)
    local cs = Instance.new("UIStroke", card)
    cs.Thickness = 2.5
    cs.Color = Color3.fromRGB(20, 4, 32)

    local selectBtn = Instance.new("TextButton")
    selectBtn.Size = UDim2.new(1, 0, 1, -4)
    selectBtn.BackgroundColor3 = Color3.fromRGB(115, 68, 180)
    selectBtn.BorderSizePixel = 0
    selectBtn.AutoButtonColor = false
    selectBtn.Text = ""
    selectBtn.ClipsDescendants = true
    selectBtn.ZIndex = zBase + 1
    selectBtn.Parent = card
    Instance.new("UICorner", selectBtn).CornerRadius = UDim.new(0, 12)
    local sbs = Instance.new("UIStroke", selectBtn)
    sbs.Thickness = 2.5
    sbs.Color = Color3.fromRGB(36, 10, 58)

    applyCartoonSurface(selectBtn, zBase + 1, true)

    local selectLabel = Instance.new("TextLabel")
    selectLabel.Size = UDim2.new(1, -24, 1, 0)
    selectLabel.Position = UDim2.fromOffset(14, 0)
    selectLabel.BackgroundTransparency = 1
    selectLabel.Text = string.format("%s: %s ▾", title, tostring(selected))
    selectLabel.TextColor3 = Color3.fromRGB(242, 230, 255)
    selectLabel.TextSize = 13.5
    selectLabel.Font = Enum.Font.FredokaOne
    selectLabel.TextXAlignment = Enum.TextXAlignment.Left
    selectLabel.ZIndex = zBase + 3
    selectLabel.Parent = selectBtn
    local sls = Instance.new("UIStroke", selectLabel)
    sls.Thickness = 3
    sls.Color = Color3.fromRGB(32, 6, 48)

    Library.AttachInteractiveEffects(selectBtn)

    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1, 0, 0, 86)
    scroll.Position = UDim2.fromOffset(0, 46)
    scroll.BackgroundColor3 = Color3.fromRGB(38, 12, 62)
    scroll.BorderSizePixel = 0
    scroll.ScrollBarThickness = 4
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scroll.Visible = false
    scroll.ZIndex = zBase + 20
    scroll.Parent = card
    Instance.new("UICorner", scroll).CornerRadius = UDim.new(0, 12)
    local ss = Instance.new("UIStroke", scroll)
    ss.Thickness = 3
    ss.Color = Color3.fromRGB(24, 6, 38)
    local list = Instance.new("UIListLayout", scroll)
    list.Padding = UDim.new(0, 4)

    local function populate()
        for _, ch in ipairs(scroll:GetChildren()) do
            if ch:IsA("TextButton") then ch:Destroy() end
        end
        for _, opt in ipairs(options) do
            local optBtn = Instance.new("TextButton")
            optBtn.Size = UDim2.new(1, -8, 0, 28)
            optBtn.BackgroundColor3 = (selected == opt) and Color3.fromRGB(152, 98, 222) or Color3.fromRGB(75, 32, 120)
            optBtn.Text = ""
            optBtn.AutoButtonColor = false
            optBtn.BorderSizePixel = 0
            optBtn.ZIndex = zBase + 21
            optBtn.Parent = scroll
            Instance.new("UICorner", optBtn).CornerRadius = UDim.new(0, 8)

            local optLbl = Instance.new("TextLabel")
            optLbl.Size = UDim2.new(1, -16, 1, 0)
            optLbl.Position = UDim2.fromOffset(10, 0)
            optLbl.BackgroundTransparency = 1
            optLbl.Text = tostring(opt)
            optLbl.TextColor3 = Color3.fromRGB(242, 230, 255)
            optLbl.TextSize = 12.5
            optLbl.Font = Enum.Font.FredokaOne
            optLbl.TextXAlignment = Enum.TextXAlignment.Left
            optLbl.ZIndex = zBase + 22
            optLbl.Parent = optBtn
            local ols = Instance.new("UIStroke", optLbl)
            ols.Thickness = 2.5
            ols.Color = Color3.fromRGB(28, 6, 44)

            Library.AttachInteractiveEffects(optBtn)

            optBtn.Activated:Connect(function()
                selected = opt
                selectLabel.Text = string.format("%s: %s ▾", title, tostring(selected))
                scroll.Visible = false
                callback(selected)
            end)
        end
    end

    selectBtn.Activated:Connect(function()
        scroll.Visible = not scroll.Visible
        if scroll.Visible then populate() end
    end)
end

-- ========================================================
-- 3D RENDERING TOGGLE BUTTON
-- ========================================================
function Library:Create3DRenderToggle(side: string)
    local parent = self:GetColumn(side or "Right")
    local enabled = true

    local base = Instance.new("Frame")
    base.Size = UDim2.new(0, 118, 0, 36)
    base.Position = UDim2.new(1, -118, 1, -38)
    base.BackgroundColor3 = Color3.fromRGB(24, 6, 38)
    base.BorderSizePixel = 0
    base.ZIndex = 15
    base.Parent = parent
    Instance.new("UICorner", base).CornerRadius = UDim.new(0, 12)
    local bs = Instance.new("UIStroke", base)
    bs.Thickness = 2.5
    bs.Color = Color3.fromRGB(20, 4, 32)

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 1, -3)
    btn.BackgroundColor3 = Color3.fromRGB(95, 205, 65)
    btn.Text = ""
    btn.BorderSizePixel = 0
    btn.AutoButtonColor = false
    btn.ZIndex = 16
    btn.Parent = base
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 10)
    local btnStroke = Instance.new("UIStroke", btn)
    btnStroke.Thickness = 2
    btnStroke.Color = Color3.fromRGB(36, 10, 58)

    applyCartoonSurface(btn, 16, true)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.fromScale(1, 1)
    lbl.BackgroundTransparency = 1
    lbl.Text = "[ 3D: ON ]"
    lbl.TextColor3 = Color3.fromRGB(242, 230, 255)
    lbl.TextSize = 12.5
    lbl.Font = Enum.Font.FredokaOne
    lbl.ZIndex = 18
    lbl.Parent = btn
    local ts = Instance.new("UIStroke", lbl)
    ts.Thickness = 2.8
    ts.Color = Color3.fromRGB(28, 6, 44)

    Library.AttachInteractiveEffects(btn)

    local originalCamType = Enum.CameraType.Custom
    local originalCamCFrame = nil

    btn.Activated:Connect(function()
        enabled = not enabled
        local cam = workspace.CurrentCamera
        if not enabled then
            pcall(function()
                if cam then
                    originalCamType = cam.CameraType
                    originalCamCFrame = cam.CFrame
                    cam.CameraType = Enum.CameraType.Scriptable
                    cam.CFrame = CFrame.new(0, 50000, 0)
                end
            end)
            self.BlackoutFrame.Visible = true
            btn.BackgroundColor3 = Color3.fromRGB(235, 65, 75)
            lbl.Text = "[ 3D: OFF ]"
        else
            pcall(function()
                if cam then
                    cam.CameraType = originalCamType or Enum.CameraType.Custom
                    if originalCamCFrame then cam.CFrame = originalCamCFrame end
                end
            end)
            self.BlackoutFrame.Visible = false
            btn.BackgroundColor3 = Color3.fromRGB(95, 205, 65)
            lbl.Text = "[ 3D: ON ]"
        end
    end)
end

return Library
