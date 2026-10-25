-- ========================================================
-- BEHIND THE DARK : CORE UI LIBRARY (ANIMATED & SHINY)
-- ========================================================
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")

local Library = {}
Library.__index = Library

local springBounce = TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local pressSquish = TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local glintTween = TweenInfo.new(0.38, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local bgRotateInfo = TweenInfo.new(12, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1)
local borderPulseInfo = TweenInfo.new(2.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)

function Library.AttachInteractiveEffects(btn: GuiButton, origPos: UDim2?)
    local originalSize = btn.Size
    local basePos = origPos or btn.Position
    local isHovered = false

    btn.ClipsDescendants = true

    -- ประกายแสงสะท้อนแว่นอนิเมะ (Anime Glasses Glint)
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

        glint.Position = UDim2.new(-0.7, 0, -0.8, 0)
        glint.BackgroundTransparency = 0.52
        TweenService:Create(glint, glintTween, {
            Position = UDim2.new(1.5, 0, -0.8, 0),
            BackgroundTransparency = 0.8
        }):Play()
    end)

    btn.MouseLeave:Connect(function()
        isHovered = false
        TweenService:Create(btn, springBounce, { Size = originalSize, Position = basePos }):Play()
    end)

    btn.MouseButton1Down:Connect(function()
        TweenService:Create(btn, pressSquish, {
            Size = UDim2.new(originalSize.X.Scale, originalSize.X.Offset * 0.92, originalSize.Y.Scale, originalSize.Y.Offset * 0.88),
            Position = UDim2.new(basePos.X.Scale, basePos.X.Offset, basePos.Y.Scale, basePos.Y.Offset + 2.5)
        }):Play()
    end)

    btn.MouseButton1Up:Connect(function()
        local targetSize = isHovered and UDim2.new(originalSize.X.Scale, originalSize.X.Offset * 1.028, originalSize.Y.Scale, originalSize.Y.Offset * 1.028) or originalSize
        local targetPos = isHovered and UDim2.new(basePos.X.Scale, basePos.X.Offset, basePos.Y.Scale, basePos.Y.Offset - 1.5) or basePos
        TweenService:Create(btn, springBounce, { Size = targetSize, Position = targetPos }):Play()
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

    -- การ์ดหน้าต่างหลัก
    local card = Instance.new("Frame")
    card.Name = "MainCard"
    card.Size = UDim2.fromOffset(width, height)
    card.Position = UDim2.new(0.5, -width / 2, 0.5, -height / 2)
    card.BackgroundColor3 = Color3.fromRGB(120, 85, 175)
    card.BorderSizePixel = 0
    card.Active = true
    card.ZIndex = 2
    card.Parent = screenGui
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 22)

    -- พื้นหลัง Dynamic Moving Aurora Gradient
    local bgGradient = Instance.new("UIGradient")
    bgGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(155, 105, 215)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(85, 45, 130)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(40, 15, 65))
    })
    bgGradient.Rotation = 45
    bgGradient.Parent = card
    TweenService:Create(bgGradient, bgRotateInfo, { Rotation = 405 }):Play()

    -- ขอบเรืองแสงหายใจ (Breathing Stroke)
    local cardStroke = Instance.new("UIStroke", card)
    cardStroke.Thickness = 4.5
    cardStroke.Color = Color3.fromRGB(50, 15, 80)
    TweenService:Create(cardStroke, borderPulseInfo, { Color = Color3.fromRGB(180, 85, 255) }):Play()
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
    titleLabel.Size = UDim2.new(1, -44, 1, 0)
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

    -- ปุ่มปิด Unload
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.fromOffset(28, 28)
    closeBtn.Position = UDim2.new(1, -34, 0.5, -14)
    closeBtn.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
    closeBtn.Text = "✕"
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.TextSize = 15
    closeBtn.Font = Enum.Font.FredokaOne
    closeBtn.BorderSizePixel = 0
    closeBtn.ZIndex = 5
    closeBtn.Parent = titlePlate
    Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 8)
    local cbStroke = Instance.new("UIStroke", closeBtn)
    cbStroke.Thickness = 1.5
    cbStroke.Color = Color3.fromRGB(42, 12, 70)
    Library.AttachInteractiveEffects(closeBtn)

    closeBtn.Activated:Connect(function()
        if config.OnUnload then
            pcall(config.OnUnload)
        end
        screenGui:Destroy()
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
    label.Size = UDim2.new(1, -24, 1, 0)
    label.Position = UDim2.fromOffset(16, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextSize = 14
    label.Font = Enum.Font.FredokaOne
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.ZIndex = 7
    label.Text = text .. (state and " : ON" or " : OFF")
    label.Parent = btn
    local ts = Instance.new("UIStroke", label)
    ts.Thickness = 2.5
    ts.Color = Color3.fromRGB(40, 10, 60)

    Library.AttachInteractiveEffects(btn, UDim2.fromOffset(1, 1))

    local function setVisual(val: boolean)
        state = val
        btn.BackgroundColor3 = state and colors.On or colors.Off
        label.Text = text .. (state and " : ON" or " : OFF")
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
