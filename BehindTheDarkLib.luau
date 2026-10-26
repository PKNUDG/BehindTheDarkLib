-- ========================================================
-- BEHIND THE DARK : CORE UI LIBRARY (RAINBOW & CANDY THEME)
-- ========================================================
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local Library = {}
Library.__index = Library

local SETTINGS_FILE = "BehindTheDark_Settings.json"

Library.Settings = {
    MovingPattern = true,
    ClickRipple = true,
    AnimeGlint = true
}

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

local springBounce = TweenInfo.new(0.32, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local pressSquish = TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local glintTween = TweenInfo.new(0.38, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local rippleTween = TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local toggleSlide = TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

local function applyCartoonSurface(target: GuiObject, zIndex: number, cornerRad: number, withMovingDots: boolean)
    local grain = Instance.new("ImageLabel")
    grain.Name = "RoughGrain"
    grain.Size = UDim2.fromScale(1, 1)
    grain.BackgroundTransparency = 1
    grain.Image = "rbxassetid://13062441566"
    grain.ImageTransparency = 0.89
    grain.ScaleType = Enum.ScaleType.Tile
    grain.TileSize = UDim2.fromOffset(85, 85)
    grain.ZIndex = zIndex
    grain.Parent = target
    Instance.new("UICorner", grain).CornerRadius = UDim.new(0, cornerRad)

    if withMovingDots then
        local dotsHolder = Instance.new("Frame")
        dotsHolder.Name = "DotsClipper"
        dotsHolder.Size = UDim2.fromScale(1, 1)
        dotsHolder.BackgroundTransparency = 1
        dotsHolder.ClipsDescendants = true
        dotsHolder.ZIndex = zIndex
        dotsHolder.Parent = target
        Instance.new("UICorner", dotsHolder).CornerRadius = UDim.new(0, cornerRad)

        local dots = Instance.new("ImageLabel")
        dots.Name = "LoopingDots"
        dots.Size = UDim2.new(1, 56, 1, 56)
        dots.Position = UDim2.fromOffset(0, 0)
        dots.BackgroundTransparency = 1
        dots.Image = "rbxassetid://6071575925"
        dots.ImageColor3 = Color3.fromRGB(245, 230, 255)
        dots.ImageTransparency = 0.86
        dots.ScaleType = Enum.ScaleType.Tile
        dots.TileSize = UDim2.fromOffset(28, 28)
        dots.ZIndex = zIndex
        dots.Parent = dotsHolder

        task.spawn(function()
            local loopDuration = 5.5
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
end

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
    ripple.ZIndex = btn.ZIndex + 4
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

function Library.AttachInteractiveEffects(btn: GuiButton, scaleTarget: any)
    local isHovered = false
    btn.ClipsDescendants = true

    local targetObj: Instance = (typeof(scaleTarget) == "Instance") and scaleTarget or btn
    local uiScale = targetObj:FindFirstChildOfClass("UIScale")
    if not uiScale then
        uiScale = Instance.new("UIScale")
        uiScale.Scale = 1
        uiScale.Parent = targetObj
    end

    local glint = Instance.new("Frame")
    glint.Name = "AnimeGlint"
    glint.Size = UDim2.new(0.26, 0, 2.6, 0)
    glint.Position = UDim2.new(-0.7, 0, -0.8, 0)
    glint.Rotation = 22
    glint.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    glint.BackgroundTransparency = 0.52
    glint.BorderSizePixel = 0
    glint.ZIndex = btn.ZIndex + 3
    glint.Parent = btn
    Instance.new("UICorner", glint).CornerRadius = UDim.new(1, 0)

    local sharpLine = Instance.new("Frame")
    sharpLine.Size = UDim2.new(0.2, 0, 1, 0)
    sharpLine.Position = UDim2.new(1.15, 0, 0, 0)
    sharpLine.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    sharpLine.BackgroundTransparency = 0.35
    sharpLine.BorderSizePixel = 0
    sharpLine.ZIndex = btn.ZIndex + 3
    sharpLine.Parent = glint

    btn.MouseEnter:Connect(function()
        isHovered = true
        TweenService:Create(uiScale, springBounce, { Scale = 1.025 }):Play()

        if Library.Settings.AnimeGlint then
            glint.Position = UDim2.new(-0.7, 0, -0.8, 0)
            glint.BackgroundTransparency = 0.50
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

function Library.BounceWiggleText(label: TextLabel)
    task.spawn(function()
        local origRot = label.Rotation
        local twExpand = TweenService:Create(label, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            TextSize = 17,
            Rotation = -10
        })
        twExpand:Play()
        twExpand.Completed:Wait()

        local twSway = TweenService:Create(label, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {
            Rotation = 10
        })
        twSway:Play()
        twSway.Completed:Wait()

        local twReset = TweenService:Create(label, TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            TextSize = 13,
            Rotation = origRot
        })
        twReset:Play()
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
    screenGui.DisplayOrder = 999999

    local success = pcall(function() screenGui.Parent = CoreGui end)
    if not success then
        local p = Players.LocalPlayer
        screenGui.Parent = p and p:FindFirstChild("PlayerGui")
    end
    self.Gui = screenGui

    local blackoutGui = Instance.new("ScreenGui")
    blackoutGui.Name = "BehindTheDark_Blackout"
    blackoutGui.ResetOnSpawn = false
    blackoutGui.IgnoreGuiInset = true
    blackoutGui.DisplayOrder = 999998
    pcall(function() blackoutGui.Parent = CoreGui end)
    if not blackoutGui.Parent then
        local p = Players.LocalPlayer
        blackoutGui.Parent = p and p:FindFirstChild("PlayerGui")
    end

    local blackout = Instance.new("Frame")
    blackout.Name = "BlackoutFrame"
    blackout.Size = UDim2.fromScale(1, 1)
    blackout.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    blackout.BackgroundTransparency = 0.05
    blackout.BorderSizePixel = 0
    blackout.ZIndex = 1
    blackout.Visible = false
    blackout.Parent = blackoutGui
    self.BlackoutFrame = blackout

    local outerBorder = Instance.new("Frame")
    outerBorder.Name = "MainOuterBorder"
    outerBorder.Size = UDim2.fromOffset(width, height)
    outerBorder.Position = UDim2.new(0.5, -width / 2, 0.5, -height / 2)
    outerBorder.BackgroundColor3 = Color3.fromRGB(185, 140, 245)
    outerBorder.BorderSizePixel = 0
    outerBorder.Active = true
    outerBorder.ZIndex = 2
    outerBorder.Parent = screenGui
    Instance.new("UICorner", outerBorder).CornerRadius = UDim.new(0, 26)

    local mainBlackStroke = Instance.new("UIStroke", outerBorder)
    mainBlackStroke.Thickness = 4.5
    mainBlackStroke.Color = Color3.fromRGB(24, 6, 38)

    local card = Instance.new("Frame")
    card.Name = "MainCard"
    card.Size = UDim2.new(1, -6, 1, -6)
    card.Position = UDim2.fromOffset(3, 3)
    card.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    card.BorderSizePixel = 0
    card.ClipsDescendants = true
    card.ZIndex = 2
    card.Parent = outerBorder
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 23)

    local bgGradient = Instance.new("UIGradient")
    bgGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(168, 122, 232)),
        ColorSequenceKeypoint.new(0.55, Color3.fromRGB(124, 82, 190)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(82, 48, 142))
    })
    bgGradient.Rotation = 90
    bgGradient.Parent = card

    applyCartoonSurface(card, 2, 23, true)

    self.MainCard = outerBorder

    local dragging, dragStart, startPos = false, nil, nil
    outerBorder.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = outerBorder.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    outerBorder.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            if dragging then
                local delta = input.Position - dragStart
                outerBorder.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            end
        end
    end)

    local titleRim = Instance.new("Frame")
    titleRim.Size = UDim2.new(1, -28, 0, 44)
    titleRim.Position = UDim2.fromOffset(14, 12)
    titleRim.BackgroundColor3 = Color3.fromRGB(98, 52, 148)
    titleRim.BorderSizePixel = 0
    titleRim.ZIndex = 4
    titleRim.Parent = card
    Instance.new("UICorner", titleRim).CornerRadius = UDim.new(0, 15)
    local tpStroke = Instance.new("UIStroke", titleRim)
    tpStroke.Thickness = 3
    tpStroke.Color = Color3.fromRGB(22, 5, 36)

    local titlePlate = Instance.new("Frame")
    titlePlate.Size = UDim2.new(1, -4, 1, -4)
    titlePlate.Position = UDim2.fromOffset(2, 2)
    titlePlate.BackgroundColor3 = Color3.fromRGB(40, 14, 66)
    titlePlate.BorderSizePixel = 0
    titlePlate.ZIndex = 4
    titlePlate.Parent = titleRim
    Instance.new("UICorner", titlePlate).CornerRadius = UDim.new(0, 13)

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -86, 1, 0)
    titleLabel.Position = UDim2.fromOffset(14, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = config.Title or "BEHIND THE DARK"
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.TextSize = 17
    titleLabel.Font = Enum.Font.FredokaOne
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.ZIndex = 6
    titleLabel.Parent = titlePlate

    local rainbowGrad = Instance.new("UIGradient")
    rainbowGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 75, 75)),
        ColorSequenceKeypoint.new(0.20, Color3.fromRGB(255, 185, 50)),
        ColorSequenceKeypoint.new(0.40, Color3.fromRGB(255, 245, 80)),
        ColorSequenceKeypoint.new(0.60, Color3.fromRGB(80, 240, 125)),
        ColorSequenceKeypoint.new(0.80, Color3.fromRGB(80, 205, 255)),
        ColorSequenceKeypoint.new(1.00, Color3.fromRGB(215, 95, 255))
    })
    rainbowGrad.Parent = titleLabel

    local titleStroke = Instance.new("UIStroke", titleLabel)
    titleStroke.Thickness = 3.5
    titleStroke.Color = Color3.fromRGB(22, 5, 36)

    task.spawn(function()
        while titleLabel and titleLabel.Parent do
            rainbowGrad.Offset = Vector2.new(-1, 0)
            local tw = TweenService:Create(rainbowGrad, TweenInfo.new(3, Enum.EasingStyle.Linear), {
                Offset = Vector2.new(1, 0)
            })
            tw:Play()
            tw.Completed:Wait()
        end
    end)

    local closeBtnRim = Instance.new("Frame")
    closeBtnRim.Size = UDim2.fromOffset(30, 30)
    closeBtnRim.Position = UDim2.new(1, -36, 0.5, -15)
    closeBtnRim.BackgroundColor3 = Color3.fromRGB(255, 130, 140)
    closeBtnRim.BorderSizePixel = 0
    closeBtnRim.ZIndex = 6
    closeBtnRim.Parent = titlePlate
    Instance.new("UICorner", closeBtnRim).CornerRadius = UDim.new(0, 10)
    local cbStroke = Instance.new("UIStroke", closeBtnRim)
    cbStroke.Thickness = 2.5
    cbStroke.Color = Color3.fromRGB(22, 5, 36)

    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(1, -4, 1, -4)
    closeBtn.Position = UDim2.fromOffset(2, 2)
    closeBtn.BackgroundColor3 = Color3.fromRGB(235, 65, 75)
    closeBtn.Text = "✕"
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.TextSize = 14
    closeBtn.Font = Enum.Font.FredokaOne
    closeBtn.BorderSizePixel = 0
    closeBtn.AutoButtonColor = false
    closeBtn.ZIndex = 7
    closeBtn.Parent = closeBtnRim
    Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 8)
    Library.AttachInteractiveEffects(closeBtn, closeBtnRim)

    closeBtn.Activated:Connect(function()
        if config.OnUnload then pcall(config.OnUnload) end
        blackoutGui:Destroy()
        screenGui:Destroy()
    end)

    local setBtnRim = Instance.new("Frame")
    setBtnRim.Size = UDim2.fromOffset(30, 30)
    setBtnRim.Position = UDim2.new(1, -72, 0.5, -15)
    setBtnRim.BackgroundColor3 = Color3.fromRGB(255, 235, 130)
    setBtnRim.BorderSizePixel = 0
    setBtnRim.ZIndex = 6
    setBtnRim.Parent = titlePlate
    Instance.new("UICorner", setBtnRim).CornerRadius = UDim.new(0, 10)
    local sbStroke = Instance.new("UIStroke", setBtnRim)
    sbStroke.Thickness = 2.5
    sbStroke.Color = Color3.fromRGB(22, 5, 36)

    local settingsBtn = Instance.new("TextButton")
    settingsBtn.Size = UDim2.new(1, -4, 1, -4)
    settingsBtn.Position = UDim2.fromOffset(2, 2)
    settingsBtn.BackgroundColor3 = Color3.fromRGB(250, 195, 45)
    settingsBtn.Text = ""
    settingsBtn.BorderSizePixel = 0
    settingsBtn.AutoButtonColor = false
    settingsBtn.ZIndex = 7
    settingsBtn.Parent = setBtnRim
    Instance.new("UICorner", settingsBtn).CornerRadius = UDim.new(0, 8)
    Library.AttachInteractiveEffects(settingsBtn, setBtnRim)

    local function createColumnTray(pos: UDim2, size: UDim2)
        local trayRim = Instance.new("Frame")
        trayRim.Size = size
        trayRim.Position = pos
        trayRim.BackgroundColor3 = Color3.fromRGB(98, 52, 148)
        trayRim.BorderSizePixel = 0
        trayRim.ZIndex = 3
        trayRim.Parent = card
        Instance.new("UICorner", trayRim).CornerRadius = UDim.new(0, 20)
        
        local trayOuterBlack = Instance.new("UIStroke", trayRim)
        trayOuterBlack.Thickness = 3.5
        trayOuterBlack.Color = Color3.fromRGB(22, 5, 36)

        local trayInner = Instance.new("Frame")
        trayInner.Size = UDim2.new(1, -6, 1, -6)
        trayInner.Position = UDim2.fromOffset(3, 3)
        trayInner.BackgroundColor3 = Color3.fromRGB(38, 12, 62)
        trayInner.BorderSizePixel = 0
        trayInner.ZIndex = 3
        trayInner.Parent = trayRim
        Instance.new("UICorner", trayInner).CornerRadius = UDim.new(0, 17)

        applyCartoonSurface(trayInner, 3, 17, false)

        local container = Instance.new("Frame")
        container.Size = UDim2.new(1, -20, 1, -20)
        container.Position = UDim2.fromOffset(10, 10)
        container.BackgroundTransparency = 1
        container.ZIndex = 4
        container.Parent = trayInner
        return container
    end

    self.LeftColumn = createColumnTray(UDim2.fromOffset(14, 64), UDim2.new(0.5, -20, 1, -76))
    self.RightColumn = createColumnTray(UDim2.new(0.5, 6, 0, 64), UDim2.new(0.5, -20, 1, -76))
    self.CenterColumn = self.LeftColumn

    local settingsModal = Instance.new("Frame")
    settingsModal.Name = "SettingsModal"
    settingsModal.Size = UDim2.fromOffset(270, 205)
    settingsModal.Position = UDim2.new(0.5, -135, 0.5, -102)
    settingsModal.BackgroundColor3 = Color3.fromRGB(48, 16, 76)
    settingsModal.BorderSizePixel = 0
    settingsModal.ZIndex = 70
    settingsModal.Visible = false
    settingsModal.Parent = card
    Instance.new("UICorner", settingsModal).CornerRadius = UDim.new(0, 18)
    local smStroke = Instance.new("UIStroke", settingsModal)
    smStroke.Thickness = 4
    smStroke.Color = Color3.fromRGB(22, 5, 36)

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
    smts.Color = Color3.fromRGB(22, 5, 36)

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
        rs.Color = Color3.fromRGB(22, 5, 36)

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
        ls.Color = Color3.fromRGB(22, 5, 36)

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
        sts.Color = Color3.fromRGB(22, 5, 36)

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
    createSettingRow("Click Ripple", 89, "ClickRipple")
    createSettingRow("Anime Glint", 132, "AnimeGlint")

    settingsBtn.Activated:Connect(function()
        settingsModal.Visible = not settingsModal.Visible
    end)

    UserInputService.InputBegan:Connect(function(input, gpe)
        if not gpe and input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == Enum.KeyCode.RightShift then
            outerBorder.Visible = not outerBorder.Visible
        end
    end)

    return self
end

function Library:GetColumn(side: string): Frame
    if side == "Left" then return self.LeftColumn
    elseif side == "Right" then return self.RightColumn
    else return self.LeftColumn end
end

function Library:CreateToggle(side: string, text: string, yPos: number, _: {On: Color3, Off: Color3}, default: boolean, callback: (boolean) -> ())
    local parent = self:GetColumn(side)
    local state = default or false

    local btnRim = Instance.new("Frame")
    btnRim.Size = UDim2.new(1, 0, 0, 42)
    btnRim.Position = UDim2.fromOffset(0, yPos)
    btnRim.BackgroundColor3 = Color3.fromRGB(195, 150, 250)
    btnRim.BorderSizePixel = 0
    btnRim.ZIndex = 5
    btnRim.Parent = parent
    Instance.new("UICorner", btnRim).CornerRadius = UDim.new(0, 14)

    local outerBlack = Instance.new("UIStroke", btnRim)
    outerBlack.Thickness = 3
    outerBlack.Color = Color3.fromRGB(22, 5, 36)

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -6, 1, -6)
    btn.Position = UDim2.fromOffset(3, 3)
    btn.BackgroundColor3 = Color3.fromRGB(165, 110, 235)
    btn.BorderSizePixel = 0
    btn.AutoButtonColor = false
    btn.Text = ""
    btn.ClipsDescendants = true
    btn.ZIndex = 6
    btn.Parent = btnRim
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 11)

    local btnGrad = Instance.new("UIGradient")
    btnGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0.0, Color3.fromRGB(188, 138, 255)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(135, 82, 210)),
        ColorSequenceKeypoint.new(1.0, Color3.fromRGB(188, 138, 255))
    })
    btnGrad.Rotation = 0
    btnGrad.Offset = Vector2.new(-1, 0)
    btnGrad.Parent = btn

    task.spawn(function()
        while btn and btn.Parent do
            btnGrad.Offset = Vector2.new(-1, 0)
            local tw = TweenService:Create(btnGrad, TweenInfo.new(3.5, Enum.EasingStyle.Linear), {
                Offset = Vector2.new(1, 0)
            })
            tw:Play()
            tw.Completed:Wait()
        end
    end)

    applyCartoonSurface(btn, 6, 11, true)

    local gloss = Instance.new("Frame")
    gloss.Size = UDim2.new(1, -10, 0.42, 0)
    gloss.Position = UDim2.fromOffset(5, 2)
    gloss.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    gloss.BackgroundTransparency = 0.74
    gloss.BorderSizePixel = 0
    gloss.ZIndex = 7
    gloss.Parent = btn
    Instance.new("UICorner", gloss).CornerRadius = UDim.new(0, 9)

    local ON_COLOR = Color3.fromRGB(115, 245, 85)
    local OFF_COLOR = Color3.fromRGB(175, 175, 185)

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -66, 1, 0)
    label.Position = UDim2.fromOffset(12, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = state and ON_COLOR or OFF_COLOR
    label.TextSize = 14
    label.Font = Enum.Font.FredokaOne
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.ZIndex = 8
    label.Text = text
    label.Parent = btn
    local ts = Instance.new("UIStroke", label)
    ts.Thickness = 3.2
    ts.Color = Color3.fromRGB(24, 5, 38)

    local switchTrack = Instance.new("Frame")
    switchTrack.Size = UDim2.fromOffset(42, 22)
    switchTrack.Position = UDim2.new(1, -48, 0.5, -11)
    switchTrack.BackgroundColor3 = Color3.fromRGB(36, 12, 58)
    switchTrack.BorderSizePixel = 0
    switchTrack.ZIndex = 8
    switchTrack.Parent = btn
    Instance.new("UICorner", switchTrack).CornerRadius = UDim.new(1, 0)
    local stStroke = Instance.new("UIStroke", switchTrack)
    stStroke.Thickness = 2.2
    stStroke.Color = Color3.fromRGB(22, 5, 36)

    local thumb = Instance.new("Frame")
    thumb.Size = UDim2.fromOffset(18, 18)
    thumb.Position = state and UDim2.fromOffset(22, 2) or UDim2.fromOffset(2, 2)
    thumb.BackgroundColor3 = state and Color3.fromRGB(115, 245, 85) or Color3.fromRGB(175, 175, 185)
    thumb.BorderSizePixel = 0
    thumb.ZIndex = 9
    thumb.Parent = switchTrack
    Instance.new("UICorner", thumb).CornerRadius = UDim.new(1, 0)

    Library.AttachInteractiveEffects(btn, btnRim)

    local function setVisual(val: boolean)
        state = val
        TweenService:Create(label, toggleSlide, {
            TextColor3 = state and ON_COLOR or OFF_COLOR
        }):Play()
        TweenService:Create(thumb, toggleSlide, {
            Position = state and UDim2.fromOffset(22, 2) or UDim2.fromOffset(2, 2),
            BackgroundColor3 = state and ON_COLOR or OFF_COLOR
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
    local zBase = 15 + (zIndexOffset or 0)

    local dropRim = Instance.new("Frame")
    dropRim.Size = UDim2.new(1, 0, 0, 42)
    dropRim.Position = UDim2.fromOffset(0, yPos)
    dropRim.BackgroundColor3 = Color3.fromRGB(115, 95, 175)
    dropRim.BorderSizePixel = 0
    dropRim.ZIndex = zBase
    dropRim.Parent = parent
    Instance.new("UICorner", dropRim).CornerRadius = UDim.new(0, 14)
    local cs = Instance.new("UIStroke", dropRim)
    cs.Thickness = 3
    cs.Color = Color3.fromRGB(22, 5, 36)

    local selectBtn = Instance.new("TextButton")
    selectBtn.Size = UDim2.new(1, -6, 1, -6)
    selectBtn.Position = UDim2.fromOffset(3, 3)
    selectBtn.BackgroundColor3 = Color3.fromRGB(48, 20, 82)
    selectBtn.BorderSizePixel = 0
    selectBtn.AutoButtonColor = false
    selectBtn.Text = ""
    selectBtn.ClipsDescendants = true
    selectBtn.ZIndex = zBase + 1
    selectBtn.Parent = dropRim
    Instance.new("UICorner", selectBtn).CornerRadius = UDim.new(0, 11)

    applyCartoonSurface(selectBtn, zBase + 1, 11, false)

    local selectLabel = Instance.new("TextLabel")
    selectLabel.Size = UDim2.new(1, -40, 1, 0)
    selectLabel.Position = UDim2.fromOffset(12, 0)
    selectLabel.BackgroundTransparency = 1
    selectLabel.Text = string.format("%s: %s", title, tostring(selected))
    selectLabel.TextColor3 = Color3.fromRGB(255, 225, 95)
    selectLabel.TextSize = 13.5
    selectLabel.Font = Enum.Font.FredokaOne
    selectLabel.TextXAlignment = Enum.TextXAlignment.Left
    selectLabel.ZIndex = zBase + 3
    selectLabel.Parent = selectBtn
    local sls = Instance.new("UIStroke", selectLabel)
    sls.Thickness = 3
    sls.Color = Color3.fromRGB(22, 5, 36)

    local arrowBadge = Instance.new("Frame")
    arrowBadge.Size = UDim2.fromOffset(24, 24)
    arrowBadge.Position = UDim2.new(1, -30, 0.5, -12)
    arrowBadge.BackgroundColor3 = Color3.fromRGB(32, 10, 56)
    arrowBadge.BorderSizePixel = 0
    arrowBadge.ZIndex = zBase + 3
    arrowBadge.Parent = selectBtn
    Instance.new("UICorner", arrowBadge).CornerRadius = UDim.new(0, 7)

    local arrowLbl = Instance.new("TextLabel")
    arrowLbl.Size = UDim2.fromScale(1, 1)
    arrowLbl.BackgroundTransparency = 1
    arrowLbl.Text = "▾"
    arrowLbl.TextColor3 = Color3.fromRGB(255, 225, 95)
    arrowLbl.TextSize = 14
    arrowLbl.Font = Enum.Font.FredokaOne
    arrowLbl.ZIndex = zBase + 4
    arrowLbl.Parent = arrowBadge

    Library.AttachInteractiveEffects(selectBtn, dropRim)

    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1, 0, 0, 88)
    scroll.Position = UDim2.fromOffset(0, 46)
    scroll.BackgroundColor3 = Color3.fromRGB(34, 10, 58)
    scroll.BorderSizePixel = 0
    scroll.ScrollBarThickness = 4
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scroll.Visible = false
    scroll.ZIndex = zBase + 20
    scroll.Parent = dropRim
    Instance.new("UICorner", scroll).CornerRadius = UDim.new(0, 12)
    local ss = Instance.new("UIStroke", scroll)
    ss.Thickness = 3
    ss.Color = Color3.fromRGB(22, 5, 36)
    local list = Instance.new("UIListLayout", scroll)
    list.Padding = UDim.new(0, 4)

    local function populate()
        for _, ch in ipairs(scroll:GetChildren()) do
            if ch:IsA("TextButton") then ch:Destroy() end
        end
        for _, opt in ipairs(options) do
            local optBtn = Instance.new("TextButton")
            optBtn.Size = UDim2.new(1, -8, 0, 28)
            optBtn.BackgroundColor3 = (selected == opt) and Color3.fromRGB(115, 70, 185) or Color3.fromRGB(52, 20, 88)
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
            optLbl.TextColor3 = (selected == opt) and Color3.fromRGB(255, 225, 95) or Color3.fromRGB(242, 230, 255)
            optLbl.TextSize = 12.5
            optLbl.Font = Enum.Font.FredokaOne
            optLbl.TextXAlignment = Enum.TextXAlignment.Left
            optLbl.ZIndex = zBase + 22
            optLbl.Parent = optBtn
            local ols = Instance.new("UIStroke", optLbl)
            ols.Thickness = 2.5
            ols.Color = Color3.fromRGB(22, 5, 36)

            Library.AttachInteractiveEffects(optBtn)

            optBtn.Activated:Connect(function()
                selected = opt
                selectLabel.Text = string.format("%s: %s", title, tostring(selected))
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

    local btnRim = Instance.new("Frame")
    btnRim.Size = UDim2.new(0, 118, 0, 36)
    btnRim.Position = UDim2.new(1, -118, 1, -38)
    btnRim.BackgroundColor3 = Color3.fromRGB(190, 255, 145)
    btnRim.BorderSizePixel = 0
    btnRim.ZIndex = 15
    btnRim.Parent = parent
    Instance.new("UICorner", btnRim).CornerRadius = UDim.new(0, 12)
    local bs = Instance.new("UIStroke", btnRim)
    bs.Thickness = 3
    bs.Color = Color3.fromRGB(22, 5, 36)

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -6, 1, -6)
    btn.Position = UDim2.fromOffset(3, 3)
    btn.BackgroundColor3 = Color3.fromRGB(115, 225, 70)
    btn.Text = ""
    btn.BorderSizePixel = 0
    btn.AutoButtonColor = false
    btn.ZIndex = 16
    btn.Parent = btnRim
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 9)

    applyCartoonSurface(btn, 16, 9, false)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.fromScale(1, 1)
    lbl.BackgroundTransparency = 1
    lbl.Text = "[ 3D: ON ]"
    lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
    lbl.TextSize = 12.5
    lbl.Font = Enum.Font.FredokaOne
    lbl.ZIndex = 18
    lbl.Parent = btn
    local ts = Instance.new("UIStroke", lbl)
    ts.Thickness = 2.8
    ts.Color = Color3.fromRGB(22, 5, 36)

    Library.AttachInteractiveEffects(btn, btnRim)

    local originalCamType = Enum.CameraType.Custom
    local originalCamCFrame = nil
    local lockConnection: RBXScriptConnection? = nil

    btn.Activated:Connect(function()
        enabled = not enabled
        local cam = workspace.CurrentCamera

        if not enabled then
            pcall(function()
                if cam then
                    originalCamType = cam.CameraType
                    originalCamCFrame = cam.CFrame
                    cam.CameraType = Enum.CameraType.Scriptable
                end
            end)
            self.BlackoutFrame.Visible = true

            if lockConnection then lockConnection:Disconnect() end
            lockConnection = RunService.RenderStepped:Connect(function()
                if not enabled then
                    local c = workspace.CurrentCamera
                    if c then
                        c.CameraType = Enum.CameraType.Scriptable
                        c.CFrame = CFrame.new(0, 50000, 0)
                    end
                    if self.BlackoutFrame and not self.BlackoutFrame.Visible then
                        self.BlackoutFrame.Visible = true
                    end
                end
            end)

            btnRim.BackgroundColor3 = Color3.fromRGB(255, 150, 160)
            btn.BackgroundColor3 = Color3.fromRGB(235, 65, 75)
            lbl.Text = "[ 3D: OFF ]"
        else
            if lockConnection then
                lockConnection:Disconnect()
                lockConnection = nil
            end
            pcall(function()
                if cam then
                    cam.CameraType = originalCamType or Enum.CameraType.Custom
                    if originalCamCFrame then cam.CFrame = originalCamCFrame end
                end
            end)
            self.BlackoutFrame.Visible = false
            btnRim.BackgroundColor3 = Color3.fromRGB(190, 255, 145)
            btn.BackgroundColor3 = Color3.fromRGB(115, 225, 70)
            lbl.Text = "[ 3D: ON ]"
        end
    end)
end

return Library
