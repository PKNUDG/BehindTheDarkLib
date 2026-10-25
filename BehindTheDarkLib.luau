-- ========================================================
-- BEHIND THE DARK : CORE UI LIBRARY (ANIMATED & SETTINGS)
-- ========================================================
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")

local Library = {}
Library.__index = Library

-- การตั้งค่าเอฟเฟกต์ภาพ (Global Visual Settings)
Library.Settings = {
    MovingAurora = true,
    BreathingBorder = true,
    ClickRipple = true,
    AnimeGlint = true
}

-- ข้อมูล Tween
local springBounce = TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local pressSquish = TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local glintTween = TweenInfo.new(0.38, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local rippleTween = TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local toggleSlide = TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

-- ฟังก์ชัน Click Ripple Effect สไตล์การ์ตูน
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
    ripple.ZIndex = 7
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

    -- ประกายแสงสะท้อนแว่นอนิเมะ
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
                Size = UDim2.new(originalSize.X.Scale, originalSize.X.Offset * 0.92, originalSize.Y.Scale, originalSize.Y.Offset * 0.88),
                Position = UDim2.new(basePos.X.Scale, basePos.X.Offset, basePos.Y.Scale, basePos.Y.Offset + 2.5)
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

    local blackout = Instance.new("Frame")
    blackout.Name = "BlackoutFrame"
    blackout.Size = UDim2.fromScale(1, 1)
    blackout.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    blackout.BackgroundTransparency = 0.07
    blackout.BorderSizePixel = 0
    blackout.ZIndex = 1
    blackout.Visible = false
    blackout.Parent = screenGui
    self.BlackoutFrame = blackout

    -- การ์ดหลัก
    local card = Instance.new("Frame")
    card.Name = "MainCard"
    card.Size = UDim2.fromOffset(width, height)
    card.Position = UDim2.new(0.5, -width / 2, 0.5, -height / 2)
    card.BackgroundColor3 = Color3.fromRGB(130, 90, 185)
    card.BorderSizePixel = 0
    card.Active = true
    card.ZIndex = 2
    card.Parent = screenGui
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 22)

    -- Dynamic Moving Aurora Gradient
    local bgGradient = Instance.new("UIGradient")
    bgGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(165, 115, 225)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(95, 50, 145)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(45, 15, 75))
    })
    bgGradient.Rotation = 45
    bgGradient.Parent = card

    local auroraTween = TweenService:Create(bgGradient, TweenInfo.new(12, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1), { Rotation = 405 })
    auroraTween:Play()

    -- Breathing Neon Border
    local cardStroke = Instance.new("UIStroke", card)
    cardStroke.Thickness = 4.5
    cardStroke.Color = Color3.fromRGB(50, 15, 80)
    local borderTween = TweenService:Create(cardStroke, TweenInfo.new(2.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Color = Color3.fromRGB(185, 95, 255) })
    borderTween:Play()

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

    -- Title Bar
    local titlePlate = Instance.new("Frame")
    titlePlate.Size = UDim2.new(1, -28, 0, 42)
    titlePlate.Position = UDim2.fromOffset(14, 14)
    titlePlate.BackgroundColor3 = Color3.fromRGB(65, 20, 100)
    titlePlate.BorderSizePixel = 0
    titlePlate.ZIndex = 3
    titlePlate.Parent = card
    Instance.new("UICorner", titlePlate).CornerRadius = UDim.new(0, 12)
    local tpStroke = Instance.new("UIStroke", titlePlate)
    tpStroke.Thickness = 2.5
    tpStroke.Color = Color3.fromRGB(35, 10, 55)

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -80, 1, 0)
    titleLabel.Position = UDim2.fromOffset(12, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = config.Title or "BEHIND THE DARK"
    titleLabel.TextColor3 = Color3.fromRGB(255, 235, 120)
    titleLabel.TextSize = 16
    titleLabel.Font = Enum.Font.FredokaOne
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.ZIndex = 4
    titleLabel.Parent = titlePlate
    local titleStroke = Instance.new("UIStroke", titleLabel)
    titleStroke.Thickness = 3
    titleStroke.Color = Color3.fromRGB(35, 10, 55)

    -- 1. ปุ่มปิดระบบสีแดง (Close/Unload Button)
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.fromOffset(28, 28)
    closeBtn.Position = UDim2.new(1, -34, 0.5, -14)
    closeBtn.BackgroundColor3 = Color3.fromRGB(225, 55, 55)
    closeBtn.Text = ""
    closeBtn.BorderSizePixel = 0
    closeBtn.ZIndex = 5
    closeBtn.Parent = titlePlate
    Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 8)
    local cbStroke = Instance.new("UIStroke", closeBtn)
    cbStroke.Thickness = 1.5
    cbStroke.Color = Color3.fromRGB(42, 12, 70)
    Library.AttachInteractiveEffects(closeBtn)

    closeBtn.Activated:Connect(function()
        if config.OnUnload then pcall(config.OnUnload) end
        screenGui:Destroy()
    end)

    -- 2. ปุ่ม Settings สีเหลืองว่างเปล่า (วางข้างปุ่มปิด)
    local settingsBtn = Instance.new("TextButton")
    settingsBtn.Size = UDim2.fromOffset(28, 28)
    settingsBtn.Position = UDim2.new(1, -68, 0.5, -14)
    settingsBtn.BackgroundColor3 = Color3.fromRGB(245, 195, 45)
    settingsBtn.Text = ""
    settingsBtn.BorderSizePixel = 0
    settingsBtn.ZIndex = 5
    settingsBtn.Parent = titlePlate
    Instance.new("UICorner", settingsBtn).CornerRadius = UDim.new(0, 8)
    local sbStroke = Instance.new("UIStroke", settingsBtn)
    sbStroke.Thickness = 1.5
    sbStroke.Color = Color3.fromRGB(42, 12, 70)
    Library.AttachInteractiveEffects(settingsBtn)

    -- ========================================================
    -- หน้าต่างตั้งค่าภาพ (POPUP SETTINGS MODAL)
    -- ========================================================
    local settingsModal = Instance.new("Frame")
    settingsModal.Name = "SettingsModal"
    settingsModal.Size = UDim2.fromOffset(260, 240)
    settingsModal.Position = UDim2.new(0.5, -130, 0.5, -120)
    settingsModal.BackgroundColor3 = Color3.fromRGB(50, 18, 80)
    settingsModal.BorderSizePixel = 0
    settingsModal.ZIndex = 60
    settingsModal.Visible = false
    settingsModal.Parent = card
    Instance.new("UICorner", settingsModal).CornerRadius = UDim.new(0, 16)
    local smStroke = Instance.new("UIStroke", settingsModal)
    smStroke.Thickness = 3
    smStroke.Color = Color3.fromRGB(160, 75, 235)

    local smTitle = Instance.new("TextLabel")
    smTitle.Size = UDim2.new(1, -20, 0, 32)
    smTitle.Position = UDim2.fromOffset(10, 8)
    smTitle.BackgroundTransparency = 1
    smTitle.Text = "VISUAL SETTINGS"
    smTitle.TextColor3 = Color3.fromRGB(255, 235, 120)
    smTitle.TextSize = 14
    smTitle.Font = Enum.Font.FredokaOne
    smTitle.ZIndex = 61
    smTitle.Parent = settingsModal

    local function createSettingRow(text: string, yPos: number, settingKey: string, onToggle: (boolean) -> ())
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, -24, 0, 34)
        row.Position = UDim2.fromOffset(12, yPos)
        row.BackgroundColor3 = Color3.fromRGB(35, 12, 55)
        row.BorderSizePixel = 0
        row.ZIndex = 61
        row.Parent = settingsModal
        Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -60, 1, 0)
        lbl.Position = UDim2.fromOffset(10, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = text
        lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
        lbl.TextSize = 12
        lbl.Font = Enum.Font.FredokaOne
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.ZIndex = 62
        lbl.Parent = row

        -- Switch Track
        local switchTrack = Instance.new("TextButton")
        switchTrack.Size = UDim2.fromOffset(42, 22)
        switchTrack.Position = UDim2.new(1, -48, 0.5, -11)
        switchTrack.BackgroundColor3 = Library.Settings[settingKey] and Color3.fromRGB(90, 205, 75) or Color3.fromRGB(95, 95, 105)
        switchTrack.Text = ""
        switchTrack.BorderSizePixel = 0
        switchTrack.ZIndex = 62
        switchTrack.Parent = row
        Instance.new("UICorner", switchTrack).CornerRadius = UDim.new(1, 0)

        -- Smooth Switch Thumb
        local thumb = Instance.new("Frame")
        thumb.Size = UDim2.fromOffset(18, 18)
        thumb.Position = Library.Settings[settingKey] and UDim2.fromOffset(22, 2) or UDim2.fromOffset(2, 2)
        thumb.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        thumb.BorderSizePixel = 0
        thumb.ZIndex = 63
        thumb.Parent = switchTrack
        Instance.new("UICorner", thumb).CornerRadius = UDim.new(1, 0)

        switchTrack.Activated:Connect(function()
            Library.Settings[settingKey] = not Library.Settings[settingKey]
            local active = Library.Settings[settingKey]

            TweenService:Create(switchTrack, toggleSlide, {
                BackgroundColor3 = active and Color3.fromRGB(90, 205, 75) or Color3.fromRGB(95, 95, 105)
            }):Play()
            TweenService:Create(thumb, toggleSlide, {
                Position = active and UDim2.fromOffset(22, 2) or UDim2.fromOffset(2, 2)
            }):Play()

            if onToggle then onToggle(active) end
        end)
    end

    createSettingRow("Moving Aurora", 45, "MovingAurora", function(val)
        bgGradient.Enabled = val
    end)
    createSettingRow("Breathing Border", 85, "BreathingBorder", function(val)
        if not val then
            borderTween:Pause()
            cardStroke.Color = Color3.fromRGB(50, 15, 80)
        else
            borderTween:Play()
        end
    end)
    createSettingRow("Click Ripple", 125, "ClickRipple")
    createSettingRow("Anime Glint", 165, "AnimeGlint")

    settingsBtn.Activated:Connect(function()
        settingsModal.Visible = not settingsModal.Visible
    end)

    -- Hotkey RightShift
    UserInputService.InputBegan:Connect(function(input, gpe)
        if not gpe and input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == Enum.KeyCode.RightShift then
            card.Visible = not card.Visible
        end
    end)

    if config.SingleColumn then
        local col = Instance.new("Frame")
        col.Size = UDim2.new(1, -28, 1, -66)
        col.Position = UDim2.fromOffset(14, 62)
        col.BackgroundTransparency = 1
        col.ZIndex = 3
        col.Parent = card
        self.CenterColumn = col
    else
        local left = Instance.new("Frame")
        left.Size = UDim2.new(0.5, -20, 1, -72)
        left.Position = UDim2.fromOffset(14, 66)
        left.BackgroundTransparency = 1
        left.ZIndex = 3
        left.Parent = card
        self.LeftColumn = left

        local right = Instance.new("Frame")
        right.Size = UDim2.new(0.5, -20, 1, -72)
        right.Position = UDim2.new(0.5, 6, 0, 66)
        right.BackgroundTransparency = 1
        right.ZIndex = 3
        right.Parent = card
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
-- SMOOTH TOGGLE SWITCH (สวิตช์ลูกกลมเลื่อน เปิด-ปิด)
-- ========================================================
function Library:CreateToggle(side: string, text: string, yPos: number, colors: {On: Color3, Off: Color3}, default: boolean, callback: (boolean) -> ())
    local parent = self:GetColumn(side)
    local state = default or false

    local base = Instance.new("Frame")
    base.Size = UDim2.new(1, 0, 0, 38)
    base.Position = UDim2.fromOffset(0, yPos)
    base.BackgroundColor3 = Color3.fromRGB(35, 10, 55)
    base.BorderSizePixel = 0
    base.ZIndex = 4
    base.Parent = parent
    Instance.new("UICorner", base).CornerRadius = UDim.new(1, 0)
    local bs = Instance.new("UIStroke", base)
    bs.Thickness = 2.5
    bs.Color = Color3.fromRGB(35, 10, 55)

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -2, 1, -4)
    btn.Position = UDim2.fromOffset(1, 1)
    btn.BackgroundColor3 = state and colors.On or colors.Off
    btn.BorderSizePixel = 0
    btn.AutoButtonColor = false
    btn.Text = ""
    btn.ClipsDescendants = true
    btn.ZIndex = 5
    btn.Parent = base
    Instance.new("UICorner", btn).CornerRadius = UDim.new(1, 0)

    local gloss = Instance.new("Frame")
    gloss.Size = UDim2.new(1, -14, 0.45, 0)
    gloss.Position = UDim2.fromOffset(7, 1)
    gloss.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    gloss.BackgroundTransparency = 0.72
    gloss.BorderSizePixel = 0
    gloss.ZIndex = 6
    gloss.Parent = btn
    Instance.new("UICorner", gloss).CornerRadius = UDim.new(1, 0)

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -66, 1, 0)
    label.Position = UDim2.fromOffset(16, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextSize = 13.5
    label.Font = Enum.Font.FredokaOne
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.ZIndex = 7
    label.Text = text
    label.Parent = btn
    local ts = Instance.new("UIStroke", label)
    ts.Thickness = 2.5
    ts.Color = Color3.fromRGB(40, 10, 60)

    -- Switch Pill Track
    local switchTrack = Instance.new("Frame")
    switchTrack.Size = UDim2.fromOffset(40, 22)
    switchTrack.Position = UDim2.new(1, -48, 0.5, -11)
    switchTrack.BackgroundColor3 = Color3.fromRGB(25, 8, 40)
    switchTrack.BorderSizePixel = 0
    switchTrack.ZIndex = 7
    switchTrack.Parent = btn
    Instance.new("UICorner", switchTrack).CornerRadius = UDim.new(1, 0)

    -- Smooth Slider Thumb
    local thumb = Instance.new("Frame")
    thumb.Size = UDim2.fromOffset(18, 18)
    thumb.Position = state and UDim2.fromOffset(20, 2) or UDim2.fromOffset(2, 2)
    thumb.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    thumb.BorderSizePixel = 0
    thumb.ZIndex = 8
    thumb.Parent = switchTrack
    Instance.new("UICorner", thumb).CornerRadius = UDim.new(1, 0)

    Library.AttachInteractiveEffects(btn, UDim2.fromOffset(1, 1))

    local function setVisual(val: boolean)
        state = val
        TweenService:Create(btn, toggleSlide, {
            BackgroundColor3 = state and colors.On or colors.Off
        }):Play()
        TweenService:Create(thumb, toggleSlide, {
            Position = state and UDim2.fromOffset(20, 2) or UDim2.fromOffset(2, 2)
        }):Play()
    end

    btn.Activated:Connect(function()
        state = not state
        setVisual(state)
        callback(state)
    end)

    return setVisual
end

function Library:CreateDropdown(side: string, title: string, yPos: number, options: {any}, default: any, zIndexOffset: number, callback: (any) -> ())
    local parent = self:GetColumn(side)
    local selected = default
    local zBase = 10 + (zIndexOffset or 0)

    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, 0, 0, 38)
    card.Position = UDim2.fromOffset(0, yPos)
    card.BackgroundColor3 = Color3.fromRGB(60, 20, 85)
    card.BorderSizePixel = 0
    card.ZIndex = zBase
    card.Parent = parent
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 10)
    local cs = Instance.new("UIStroke", card)
    cs.Thickness = 2
    cs.Color = Color3.fromRGB(160, 75, 235)

    local selectBtn = Instance.new("TextButton")
    selectBtn.Size = UDim2.fromScale(1, 1)
    selectBtn.BackgroundTransparency = 1
    selectBtn.Text = string.format("  %s: %s ▾", title, tostring(selected))
    selectBtn.TextColor3 = Color3.fromRGB(255, 235, 120)
    selectBtn.TextSize = 13
    selectBtn.Font = Enum.Font.FredokaOne
    selectBtn.TextXAlignment = Enum.TextXAlignment.Left
    selectBtn.ZIndex = zBase + 1
    selectBtn.Parent = card

    Library.AttachInteractiveEffects(selectBtn)

    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1, 0, 0, 78)
    scroll.Position = UDim2.fromOffset(0, 42)
    scroll.BackgroundColor3 = Color3.fromRGB(35, 12, 55)
    scroll.BorderSizePixel = 0
    scroll.ScrollBarThickness = 4
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scroll.Visible = false
    scroll.ZIndex = zBase + 20
    scroll.Parent = card
    Instance.new("UICorner", scroll).CornerRadius = UDim.new(0, 8)
    local ss = Instance.new("UIStroke", scroll)
    ss.Thickness = 1.5
    ss.Color = Color3.fromRGB(160, 75, 235)
    local list = Instance.new("UIListLayout", scroll)
    list.Padding = UDim.new(0, 3)

    local function populate()
        for _, ch in ipairs(scroll:GetChildren()) do
            if ch:IsA("TextButton") then ch:Destroy() end
        end
        for _, opt in ipairs(options) do
            local optBtn = Instance.new("TextButton")
            optBtn.Size = UDim2.new(1, -6, 0, 26)
            optBtn.Position = UDim2.fromOffset(3, 0)
            optBtn.BackgroundColor3 = (selected == opt) and Color3.fromRGB(160, 75, 235) or Color3.fromRGB(65, 25, 95)
            optBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            optBtn.TextSize = 12
            optBtn.Font = Enum.Font.FredokaOne
            optBtn.Text = "  " .. tostring(opt)
            optBtn.TextXAlignment = Enum.TextXAlignment.Left
            optBtn.BorderSizePixel = 0
            optBtn.ZIndex = zBase + 21
            optBtn.Parent = scroll
            Instance.new("UICorner", optBtn).CornerRadius = UDim.new(0, 6)
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

function Library:Create3DRenderToggle(side: string)
    local parent = self:GetColumn(side or "Right")
    local enabled = true

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 115, 0, 32)
    btn.Position = UDim2.new(1, -115, 1, -34)
    btn.BackgroundColor3 = Color3.fromRGB(55, 140, 65)
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 12
    btn.Font = Enum.Font.FredokaOne
    btn.Text = "[ 3D: ON ]"
    btn.BorderSizePixel = 0
    btn.ZIndex = 15
    btn.Parent = parent
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
    local bs = Instance.new("UIStroke", btn)
    bs.Thickness = 2
    bs.Color = Color3.fromRGB(35, 10, 55)

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
            btn.BackgroundColor3 = Color3.fromRGB(190, 50, 50)
            btn.Text = "[ 3D: OFF ]"
        else
            pcall(function()
                if cam then
                    cam.CameraType = originalCamType or Enum.CameraType.Custom
                    if originalCamCFrame then cam.CFrame = originalCamCFrame end
                end
            end)
            self.BlackoutFrame.Visible = false
            btn.BackgroundColor3 = Color3.fromRGB(55, 140, 65)
            btn.Text = "[ 3D: ON ]"
        end
    end)
end

return Library
