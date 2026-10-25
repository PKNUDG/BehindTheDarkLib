-- ========================================================
-- BEHIND THE DARK : CORE UI LIBRARY (CANDY TD CARTOON THEME)
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
    MovingAurora = true,
    BreathingBorder = true,
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

-- การเคลื่อนไหว Tween สไตล์การ์ตูน
local springBounce = TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local pressSquish = TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local glintTween = TweenInfo.new(0.38, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local rippleTween = TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local toggleSlide = TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

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
    ripple.BackgroundTransparency = 0.4
    ripple.BorderSizePixel = 0
    ripple.ZIndex = 9
    ripple.Parent = btn
    Instance.new("UICorner", ripple).CornerRadius = UDim.new(1, 0)

    local targetSize = math.max(btn.AbsoluteSize.X, btn.AbsoluteSize.Y) * 2.2
    local tw = TweenService:Create(ripple, rippleTween, {
        Size = UDim2.fromOffset(targetSize, targetSize),
        BackgroundTransparency = 1
    })
    tw:Play()
    tw.Completed:Connect(function()
        ripple:Destroy()
    end)
end

function Library.AttachInteractiveEffects(btn: GuiButton, origPos: UDim2?)
    local originalSize = btn.Size
    local basePos = origPos or btn.Position
    local isHovered = false

    btn.ClipsDescendants = true

    -- แสงสะท้อนแว่นการ์ตูน
    local glint = Instance.new("Frame")
    glint.Name = "AnimeGlint"
    glint.Size = UDim2.new(0.28, 0, 2.6, 0)
    glint.Position = UDim2.new(-0.7, 0, -0.8, 0)
    glint.Rotation = 22
    glint.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    glint.BackgroundTransparency = 0.52
    glint.BorderSizePixel = 0
    glint.ZIndex = 8
    glint.Parent = btn
    Instance.new("UICorner", glint).CornerRadius = UDim.new(1, 0)

    local sharpLine = Instance.new("Frame")
    sharpLine.Size = UDim2.new(0.2, 0, 1, 0)
    sharpLine.Position = UDim2.new(1.15, 0, 0, 0)
    sharpLine.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    sharpLine.BackgroundTransparency = 0.3
    sharpLine.BorderSizePixel = 0
    sharpLine.ZIndex = 9
    sharpLine.Parent = glint

    btn.MouseEnter:Connect(function()
        isHovered = true
        TweenService:Create(btn, springBounce, {
            Size = UDim2.new(originalSize.X.Scale, originalSize.X.Offset * 1.028, originalSize.Y.Scale, originalSize.Y.Offset * 1.028),
            Position = UDim2.new(basePos.X.Scale, basePos.X.Offset, basePos.Y.Scale, basePos.Y.Offset - 1.5)
        }):Play()

        if Library.Settings.AnimeGlint then
            glint.Position = UDim2.new(-0.7, 0, -0.8, 0)
            glint.BackgroundTransparency = 0.52
            TweenService:Create(glint, glintTween, {
                Position = UDim2.new(1.5, 0, -0.8, 0),
                BackgroundTransparency = 0.8
            }):Play()
        end
    end)

    btn.MouseLeave:Connect(function()
        isHovered = false
        TweenService:Create(btn, springBounce, { Size = originalSize, Position = basePos }):Play()
    end)

    btn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            spawnClickRipple(btn, input.Position)
            TweenService:Create(btn, pressSquish, {
                Size = UDim2.new(originalSize.X.Scale, originalSize.X.Offset * 0.94, originalSize.Y.Scale, originalSize.Y.Offset * 0.90),
                Position = UDim2.new(basePos.X.Scale, basePos.X.Offset, basePos.Y.Scale, basePos.Y.Offset + 2)
            }):Play()
        end
    end)

    btn.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            local targetSize = isHovered and UDim2.new(originalSize.X.Scale, originalSize.X.Offset * 1.028, originalSize.Y.Scale, originalSize.Y.Offset * 1.028) or originalSize
            local targetPos = isHovered and UDim2.new(basePos.X.Scale, basePos.X.Offset, basePos.Y.Scale, basePos.Y.Offset - 1.5) or basePos
            TweenService:Create(btn, springBounce, { Size = targetSize, Position = targetPos }):Play()
        end
    end)
end

function Library:CreateWindow(config: {Title: string, Name: string, Size: UDim2?, SingleColumn: boolean?, OnUnload: (() -> ())?})
    local self = setmetatable({}, Library)
    local width = config.Size and config.Size.X.Offset or (config.SingleColumn and 340 or 660)
    local height = config.Size and config.Size.Y.Offset or (config.SingleColumn and 230 or 440)

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

    -- จอดำบังหลัง
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

    -- 1. กรอบการ์ดนอกสุด (Outer Shell) โทนม่วง Candy TD
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

    -- เส้นขอบนอกหนา 5px สไตล์การ์ตูน
    local cardStroke = Instance.new("UIStroke", card)
    cardStroke.Thickness = 5
    cardStroke.Color = Color3.fromRGB(48, 14, 76)
    local borderTween = TweenService:Create(cardStroke, TweenInfo.new(2.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Color = Color3.fromRGB(175, 110, 245) })
    if Library.Settings.BreathingBorder then borderTween:Play() end

    -- ลวดลายจุด Polka Dot การ์ตูน (Texture Dots)
    local dotBg = Instance.new("ImageLabel")
    dotBg.Name = "PolkaDots"
    dotBg.Size = UDim2.new(2, 0, 2, 0)
    dotBg.Position = UDim2.fromOffset(0, 0)
    dotBg.BackgroundTransparency = 1
    dotBg.Image = "rbxassetid://6071575925" -- ตารางลายจุดโปร่งแสง
    dotBg.ImageTransparency = 0.94
    dotBg.ScaleType = Enum.ScaleType.Tile
    dotBg.TileSize = UDim2.fromOffset(28, 28)
    dotBg.ZIndex = 2
    dotBg.Parent = card

    -- อนิเมชันเลื่อนลายจุดเบาๆ
    task.spawn(function()
        while card and card.Parent do
            TweenService:Create(dotBg, TweenInfo.new(16, Enum.EasingStyle.Linear), { Position = UDim2.fromOffset(-28, -28) }):Play()
            task.wait(16)
            dotBg.Position = UDim2.fromOffset(0, 0)
        end
    end)

    -- Dynamic Aurora Gradient
    local bgGradient = Instance.new("UIGradient")
    bgGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(148, 105, 215)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(120, 80, 185)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(95, 60, 155))
    })
    bgGradient.Rotation = 45
    bgGradient.Enabled = Library.Settings.MovingAurora
    bgGradient.Parent = card
    local auroraTween = TweenService:Create(bgGradient, TweenInfo.new(12, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1), { Rotation = 405 })
    auroraTween:Play()

    self.MainCard = card

    -- ระบบ Drag หน้าต่าง
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

    -- 2. Title Bar โทนแคปซูลการ์ตูน
    local titlePlate = Instance.new("Frame")
    titlePlate.Size = UDim2.new(1, -28, 0, 44)
    titlePlate.Position = UDim2.fromOffset(14, 12)
    titlePlate.BackgroundColor3 = Color3.fromRGB(85, 45, 140)
    titlePlate.BorderSizePixel = 0
    titlePlate.ZIndex = 4
    titlePlate.Parent = card
    Instance.new("UICorner", titlePlate).CornerRadius = UDim.new(0, 14)
    local tpStroke = Instance.new("UIStroke", titlePlate)
    tpStroke.Thickness = 3
    tpStroke.Color = Color3.fromRGB(48, 14, 76)

    -- ไฮไลต์ขอบบน Title Plate
    local tpGloss = Instance.new("Frame")
    tpGloss.Size = UDim2.new(1, -12, 0.45, 0)
    tpGloss.Position = UDim2.fromOffset(6, 2)
    tpGloss.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    tpGloss.BackgroundTransparency = 0.8
    tpGloss.BorderSizePixel = 0
    tpGloss.ZIndex = 5
    tpGloss.Parent = titlePlate
    Instance.new("UICorner", tpGloss).CornerRadius = UDim.new(1, 0)

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -86, 1, 0)
    titleLabel.Position = UDim2.fromOffset(14, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = config.Title or "BEHIND THE DARK"
    titleLabel.TextColor3 = Color3.fromRGB(255, 235, 110)
    titleLabel.TextSize = 17
    titleLabel.Font = Enum.Font.FredokaOne
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.ZIndex = 6
    titleLabel.Parent = titlePlate
    local titleStroke = Instance.new("UIStroke", titleLabel)
    titleStroke.Thickness = 3.5
    titleStroke.Color = Color3.fromRGB(42, 10, 68)

    -- ปุ่มปิดสีแดง (Close / Unload) สไตล์เยลลี่
    local closeBtnBase = Instance.new("Frame")
    closeBtnBase.Size = UDim2.fromOffset(30, 30)
    closeBtnBase.Position = UDim2.new(1, -36, 0.5, -15)
    closeBtnBase.BackgroundColor3 = Color3.fromRGB(150, 20, 20)
    closeBtnBase.BorderSizePixel = 0
    closeBtnBase.ZIndex = 6
    closeBtnBase.Parent = titlePlate
    Instance.new("UICorner", closeBtnBase).CornerRadius = UDim.new(0, 10)
    local cbStroke = Instance.new("UIStroke", closeBtnBase)
    cbStroke.Thickness = 2
    cbStroke.Color = Color3.fromRGB(48, 14, 76)

    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(1, 0, 1, -3)
    closeBtn.Position = UDim2.fromOffset(0, 0)
    closeBtn.BackgroundColor3 = Color3.fromRGB(235, 60, 60)
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

    -- ปุ่ม Settings สีเหลืองว่างเปล่า (วางติดกับปุ่มปิด)
    local setBtnBase = Instance.new("Frame")
    setBtnBase.Size = UDim2.fromOffset(30, 30)
    setBtnBase.Position = UDim2.new(1, -72, 0.5, -15)
    setBtnBase.BackgroundColor3 = Color3.fromRGB(180, 130, 20)
    setBtnBase.BorderSizePixel = 0
    setBtnBase.ZIndex = 6
    setBtnBase.Parent = titlePlate
    Instance.new("UICorner", setBtnBase).CornerRadius = UDim.new(0, 10)
    local sbStroke = Instance.new("UIStroke", setBtnBase)
    sbStroke.Thickness = 2
    sbStroke.Color = Color3.fromRGB(48, 14, 76)

    local settingsBtn = Instance.new("TextButton")
    settingsBtn.Size = UDim2.new(1, 0, 1, -3)
    settingsBtn.Position = UDim2.fromOffset(0, 0)
    settingsBtn.BackgroundColor3 = Color3.fromRGB(255, 205, 50)
    settingsBtn.Text = ""
    settingsBtn.BorderSizePixel = 0
    settingsBtn.AutoButtonColor = false
    settingsBtn.ZIndex = 7
    settingsBtn.Parent = setBtnBase
    Instance.new("UICorner", settingsBtn).CornerRadius = UDim.new(0, 9)
    Library.AttachInteractiveEffects(settingsBtn)

    -- 3. ถาดรองด้านใน (Inner Recessed Base) โทนสีม่วงเข้มทึบแบบในเกม
    local innerBase = Instance.new("Frame")
    innerBase.Name = "InnerRecessedBase"
    innerBase.Size = UDim2.new(1, -28, 1, -70)
    innerBase.Position = UDim2.fromOffset(14, 62)
    innerBase.BackgroundColor3 = Color3.fromRGB(38, 12, 62)
    innerBase.BorderSizePixel = 0
    innerBase.ZIndex = 3
    innerBase.Parent = card
    Instance.new("UICorner", innerBase).CornerRadius = UDim.new(0, 18)
    local ibStroke = Instance.new("UIStroke", innerBase)
    ibStroke.Thickness = 3
    ibStroke.Color = Color3.fromRGB(30, 8, 48)

    -- ========================================================
    -- หน้าต่างตั้งค่ากราฟิก (Settings Modal)
    -- ========================================================
    local settingsModal = Instance.new("Frame")
    settingsModal.Name = "SettingsModal"
    settingsModal.Size = UDim2.fromOffset(270, 245)
    settingsModal.Position = UDim2.new(0.5, -135, 0.5, -122)
    settingsModal.BackgroundColor3 = Color3.fromRGB(50, 16, 80)
    settingsModal.BorderSizePixel = 0
    settingsModal.ZIndex = 70
    settingsModal.Visible = false
    settingsModal.Parent = card
    Instance.new("UICorner", settingsModal).CornerRadius = UDim.new(0, 18)
    local smStroke = Instance.new("UIStroke", settingsModal)
    smStroke.Thickness = 3.5
    smStroke.Color = Color3.fromRGB(175, 110, 245)

    local smTitle = Instance.new("TextLabel")
    smTitle.Size = UDim2.new(1, -20, 0, 32)
    smTitle.Position = UDim2.fromOffset(10, 8)
    smTitle.BackgroundTransparency = 1
    smTitle.Text = "VISUAL SETTINGS"
    smTitle.TextColor3 = Color3.fromRGB(255, 235, 110)
    smTitle.TextSize = 14
    smTitle.Font = Enum.Font.FredokaOne
    smTitle.ZIndex = 71
    smTitle.Parent = settingsModal

    local function createSettingRow(text: string, yPos: number, settingKey: string, onToggle: ((boolean) -> ())?)
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, -24, 0, 36)
        row.Position = UDim2.fromOffset(12, yPos)
        row.BackgroundColor3 = Color3.fromRGB(32, 10, 52)
        row.BorderSizePixel = 0
        row.ZIndex = 71
        row.Parent = settingsModal
        Instance.new("UICorner", row).CornerRadius = UDim.new(0, 10)

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -64, 1, 0)
        lbl.Position = UDim2.fromOffset(12, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = text
        lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
        lbl.TextSize = 12.5
        lbl.Font = Enum.Font.FredokaOne
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.ZIndex = 72
        lbl.Parent = row

        local switchTrack = Instance.new("TextButton")
        switchTrack.Size = UDim2.fromOffset(44, 22)
        switchTrack.Position = UDim2.new(1, -52, 0.5, -11)
        switchTrack.BackgroundColor3 = Library.Settings[settingKey] and Color3.fromRGB(90, 215, 65) or Color3.fromRGB(95, 95, 105)
        switchTrack.Text = ""
        switchTrack.BorderSizePixel = 0
        switchTrack.AutoButtonColor = false
        switchTrack.ZIndex = 72
        switchTrack.Parent = row
        Instance.new("UICorner", switchTrack).CornerRadius = UDim.new(1, 0)

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
                BackgroundColor3 = active and Color3.fromRGB(90, 215, 65) or Color3.fromRGB(95, 95, 105)
            }):Play()
            TweenService:Create(thumb, toggleSlide, {
                Position = active and UDim2.fromOffset(24, 2) or UDim2.fromOffset(2, 2)
            }):Play()

            if onToggle then onToggle(active) end
        end)
    end

    createSettingRow("Moving Aurora", 45, "MovingAurora", function(val)
        bgGradient.Enabled = val
    end)
    createSettingRow("Breathing Border", 88, "BreathingBorder", function(val)
        if not val then
            borderTween:Pause()
            cardStroke.Color = Color3.fromRGB(48, 14, 76)
        else
            borderTween:Play()
        end
    end)
    createSettingRow("Click Ripple", 131, "ClickRipple")
    createSettingRow("Anime Glint", 174, "AnimeGlint")

    settingsBtn.Activated:Connect(function()
        settingsModal.Visible = not settingsModal.Visible
    end)

    -- Hotkey RightShift
    UserInputService.InputBegan:Connect(function(input, gpe)
        if not gpe and input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == Enum.KeyCode.RightShift then
            card.Visible = not card.Visible
        end
    end)

    -- แบ่งคอลัมน์ภายในถาด innerBase
    if config.SingleColumn then
        local col = Instance.new("Frame")
        col.Size = UDim2.new(1, -20, 1, -16)
        col.Position = UDim2.fromOffset(10, 8)
        col.BackgroundTransparency = 1
        col.ZIndex = 4
        col.Parent = innerBase
        self.CenterColumn = col
    else
        local left = Instance.new("Frame")
        left.Size = UDim2.new(0.5, -14, 1, -16)
        left.Position = UDim2.fromOffset(10, 8)
        left.BackgroundTransparency = 1
        left.ZIndex = 4
        left.Parent = innerBase
        self.LeftColumn = left

        local right = Instance.new("Frame")
        right.Size = UDim2.new(0.5, -14, 1, -16)
        right.Position = UDim2.new(0.5, 4, 0, 8)
        right.BackgroundTransparency = 1
        right.ZIndex = 4
        right.Parent = innerBase
        self.RightColumn = right
    end

    return self
end

function Library:GetColumn(side: string): Frame
    if side == "Left" then return self.LeftColumn
    elseif side == "Right" then return self.RightColumn
    else return self.CenterColumn or self.LeftColumn end
end

-- ========================================================
-- TOGGLE BUTTON สไตล์การ์ตูนเหมือนเกม CANDY TD
-- ========================================================
function Library:CreateToggle(side: string, text: string, yPos: number, colors: {On: Color3, Off: Color3}, default: boolean, callback: (boolean) -> ())
    local parent = self:GetColumn(side)
    local state = default or false

    -- ฐานเงาปุ่ม 3D สีเข้ม
    local base = Instance.new("Frame")
    base.Size = UDim2.new(1, 0, 0, 42)
    base.Position = UDim2.fromOffset(0, yPos)
    base.BackgroundColor3 = Color3.fromRGB(28, 8, 45)
    base.BorderSizePixel = 0
    base.ZIndex = 5
    base.Parent = parent
    Instance.new("UICorner", base).CornerRadius = UDim.new(0, 14)
    local bs = Instance.new("UIStroke", base)
    bs.Thickness = 2.5
    bs.Color = Color3.fromRGB(24, 6, 38)

    -- การ์ดปุ่มด้านบน
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 1, -4)
    btn.Position = UDim2.fromOffset(0, 0)
    btn.BackgroundColor3 = state and (colors.On or Color3.fromRGB(110, 215, 60)) or (colors.Off or Color3.fromRGB(140, 85, 205))
    btn.BorderSizePixel = 0
    btn.AutoButtonColor = false
    btn.Text = ""
    btn.ClipsDescendants = true
    btn.ZIndex = 6
    btn.Parent = base
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 12)

    -- ขอบปุ่มการ์ตูน
    local btnStroke = Instance.new("UIStroke", btn)
    btnStroke.Thickness = 2
    btnStroke.Color = Color3.fromRGB(42, 10, 68)

    -- แถบไฮไลต์สะท้อนแสงด้านบนตัวปุ่ม
    local gloss = Instance.new("Frame")
    gloss.Size = UDim2.new(1, -16, 0.45, 0)
    gloss.Position = UDim2.fromOffset(8, 2)
    gloss.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    gloss.BackgroundTransparency = 0.76
    gloss.BorderSizePixel = 0
    gloss.ZIndex = 7
    gloss.Parent = btn
    Instance.new("UICorner", gloss).CornerRadius = UDim.new(1, 0)

    -- ชื่อฟังก์ชันตัวหนา
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -68, 1, 0)
    label.Position = UDim2.fromOffset(14, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextSize = 13.5
    label.Font = Enum.Font.FredokaOne
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.ZIndex = 8
    label.Text = text
    label.Parent = btn
    local ts = Instance.new("UIStroke", label)
    ts.Thickness = 3
    ts.Color = Color3.fromRGB(38, 8, 62)

    -- รางสวิตช์แคปซูล
    local switchTrack = Instance.new("Frame")
    switchTrack.Size = UDim2.fromOffset(42, 22)
    switchTrack.Position = UDim2.new(1, -50, 0.5, -11)
    switchTrack.BackgroundColor3 = Color3.fromRGB(26, 8, 42)
    switchTrack.BorderSizePixel = 0
    switchTrack.ZIndex = 8
    switchTrack.Parent = btn
    Instance.new("UICorner", switchTrack).CornerRadius = UDim.new(1, 0)
    local stStroke = Instance.new("UIStroke", switchTrack)
    stStroke.Thickness = 1.5
    stStroke.Color = Color3.fromRGB(48, 14, 76)

    -- ลูกกลม Thumb เลื่อนซ้ายขวา
    local thumb = Instance.new("Frame")
    thumb.Size = UDim2.fromOffset(18, 18)
    thumb.Position = state and UDim2.fromOffset(22, 2) or UDim2.fromOffset(2, 2)
    thumb.BackgroundColor3 = Color3.fromRGB(255, 245, 120)
    thumb.BorderSizePixel = 0
    thumb.ZIndex = 9
    thumb.Parent = switchTrack
    Instance.new("UICorner", thumb).CornerRadius = UDim.new(1, 0)

    Library.AttachInteractiveEffects(btn, UDim2.fromOffset(0, 0))

    local function setVisual(val: boolean)
        state = val
        local onCol = colors.On or Color3.fromRGB(110, 215, 60)
        local offCol = colors.Off or Color3.fromRGB(140, 85, 205)
        TweenService:Create(btn, toggleSlide, {
            BackgroundColor3 = state and onCol or offCol
        }):Play()
        TweenService:Create(thumb, toggleSlide, {
            Position = state and UDim2.fromOffset(22, 2) or UDim2.fromOffset(2, 2),
            BackgroundColor3 = state and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(210, 210, 220)
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
-- DROPDOWN สไตล์การ์ตูน
-- ========================================================
function Library:CreateDropdown(side: string, title: string, yPos: number, options: {any}, default: any, zIndexOffset: number, callback: (any) -> ())
    local parent = self:GetColumn(side)
    local selected = default
    local zBase = 15 + (zIndexOffset or 0)

    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, 0, 0, 42)
    card.Position = UDim2.fromOffset(0, yPos)
    card.BackgroundColor3 = Color3.fromRGB(75, 32, 120)
    card.BorderSizePixel = 0
    card.ZIndex = zBase
    card.Parent = parent
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 14)
    local cs = Instance.new("UIStroke", card)
    cs.Thickness = 2.5
    cs.Color = Color3.fromRGB(48, 14, 76)

    local selectBtn = Instance.new("TextButton")
    selectBtn.Size = UDim2.fromScale(1, 1)
    selectBtn.BackgroundTransparency = 1
    selectBtn.Text = string.format("  %s: %s ▾", title, tostring(selected))
    selectBtn.TextColor3 = Color3.fromRGB(255, 235, 110)
    selectBtn.TextSize = 13.5
    selectBtn.Font = Enum.Font.FredokaOne
    selectBtn.TextXAlignment = Enum.TextXAlignment.Left
    selectBtn.ZIndex = zBase + 1
    selectBtn.Parent = card
    local sbs = Instance.new("UIStroke", selectBtn)
    sbs.Thickness = 2.5
    sbs.Color = Color3.fromRGB(38, 8, 62)

    Library.AttachInteractiveEffects(selectBtn)

    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1, 0, 0, 84)
    scroll.Position = UDim2.fromOffset(0, 46)
    scroll.BackgroundColor3 = Color3.fromRGB(45, 15, 75)
    scroll.BorderSizePixel = 0
    scroll.ScrollBarThickness = 4
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scroll.Visible = false
    scroll.ZIndex = zBase + 20
    scroll.Parent = card
    Instance.new("UICorner", scroll).CornerRadius = UDim.new(0, 12)
    local ss = Instance.new("UIStroke", scroll)
    ss.Thickness = 2
    ss.Color = Color3.fromRGB(175, 110, 245)
    local list = Instance.new("UIListLayout", scroll)
    list.Padding = UDim.new(0, 4)

    local function populate()
        for _, ch in ipairs(scroll:GetChildren()) do
            if ch:IsA("TextButton") then ch:Destroy() end
        end
        for _, opt in ipairs(options) do
            local optBtn = Instance.new("TextButton")
            optBtn.Size = UDim2.new(1, -8, 0, 28)
            optBtn.Position = UDim2.fromOffset(4, 0)
            optBtn.BackgroundColor3 = (selected == opt) and Color3.fromRGB(152, 98, 222) or Color3.fromRGB(65, 22, 105)
            optBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            optBtn.TextSize = 12.5
            optBtn.Font = Enum.Font.FredokaOne
            optBtn.Text = "  " .. tostring(opt)
            optBtn.TextXAlignment = Enum.TextXAlignment.Left
            optBtn.BorderSizePixel = 0
            optBtn.ZIndex = zBase + 21
            optBtn.Parent = scroll
            Instance.new("UICorner", optBtn).CornerRadius = UDim.new(0, 8)
            Library.AttachInteractiveEffects(optBtn)

            optBtn.Activated:Connect(function()
                selected = opt
                selectBtn.Text = string.format("  %s: %s ▾", title, tostring(selected))
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
    base.BackgroundColor3 = Color3.fromRGB(25, 65, 30)
    base.BorderSizePixel = 0
    base.ZIndex = 15
    base.Parent = parent
    Instance.new("UICorner", base).CornerRadius = UDim.new(0, 12)
    local bs = Instance.new("UIStroke", base)
    bs.Thickness = 2
    bs.Color = Color3.fromRGB(48, 14, 76)

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 1, -3)
    btn.Position = UDim2.fromOffset(0, 0)
    btn.BackgroundColor3 = Color3.fromRGB(80, 195, 65)
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 12.5
    btn.Font = Enum.Font.FredokaOne
    btn.Text = "[ 3D: ON ]"
    btn.BorderSizePixel = 0
    btn.AutoButtonColor = false
    btn.ZIndex = 16
    btn.Parent = base
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 11)
    local ts = Instance.new("UIStroke", btn)
    ts.Thickness = 2
    ts.Color = Color3.fromRGB(38, 8, 62)

    Library.AttachInteractiveEffects(btn, UDim2.fromOffset(0, 0))

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
            base.BackgroundColor3 = Color3.fromRGB(90, 20, 20)
            btn.BackgroundColor3 = Color3.fromRGB(225, 60, 60)
            btn.Text = "[ 3D: OFF ]"
        else
            pcall(function()
                if cam then
                    cam.CameraType = originalCamType or Enum.CameraType.Custom
                    if originalCamCFrame then cam.CFrame = originalCamCFrame end
                end
            end)
            self.BlackoutFrame.Visible = false
            base.BackgroundColor3 = Color3.fromRGB(25, 65, 30)
            btn.BackgroundColor3 = Color3.fromRGB(80, 195, 65)
            btn.Text = "[ 3D: ON ]"
        end
    end)
end

return Library
