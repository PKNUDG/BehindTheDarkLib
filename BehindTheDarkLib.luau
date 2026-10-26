-- ========================================================
-- BEHIND THE DARK : CORE UI LIBRARY (ENHANCED SETTINGS & DIM)
-- ========================================================
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local SoundService = game:GetService("SoundService")

local Library = {}
Library.__index = Library

local SETTINGS_FILE = "BehindTheDark_Settings.json"

Library.Settings = {
    Animations = true,
    MovingPattern = true,
    ClickRipple = true,
    AnimeGlint = true,
    SoundEffects = true,
    WindowPos = nil,
    SelectedStage = nil
}

local SOUND_CLICK = "rbxassetid://6895079853"
local SOUND_TOGGLE = "rbxassetid://9069609268"

function Library.PlaySound(soundId: string)
    if not Library.Settings.SoundEffects then return end
    task.spawn(function()
        local s = Instance.new("Sound")
        s.SoundId = soundId
        s.Volume = 0.55
        s.Parent = SoundService
        s:Play()
        s.Ended:Wait()
        s:Destroy()
    end)
end

function Library.SaveSettings()
    local wf = (type(writefile) == "function" and writefile) or nil
    if wf then
        pcall(function()
            local encoded = HttpService:JSONEncode(Library.Settings)
            wf(SETTINGS_FILE, encoded)
        end)
    end
end

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

loadSavedSettings()

local springBounce = TweenInfo.new(0.32, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local pressSquish = TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local glintTween = TweenInfo.new(0.38, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local rippleTween = TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local toggleSlide = TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local windowPopOpen = TweenInfo.new(0.38, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local windowSquishClose = TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.In)

function Library.ApplyCartoonScrollbar(scroll: ScrollingFrame)
    scroll.ScrollBarThickness = 6
    scroll.ScrollBarImageColor3 = Color3.fromRGB(182, 130, 248)
    scroll.TopImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"
    scroll.BottomImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"
    scroll.MidImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"
end

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
                if Library.Settings.Animations and Library.Settings.MovingPattern then
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
    if not (Library.Settings.Animations and Library.Settings.ClickRipple) then return end
    
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
        if Library.Settings.Animations then
            TweenService:Create(uiScale, springBounce, { Scale = 1.025 }):Play()
            if Library.Settings.AnimeGlint then
                glint.Position = UDim2.new(-0.7, 0, -0.8, 0)
                glint.BackgroundTransparency = 0.50
                TweenService:Create(glint, glintTween, {
                    Position = UDim2.new(1.5, 0, -0.8, 0),
                    BackgroundTransparency = 0.85
                }):Play()
            end
        end
    end)

    btn.MouseLeave:Connect(function()
        isHovered = false
        if Library.Settings.Animations then
            TweenService:Create(uiScale, springBounce, { Scale = 1 }):Play()
        end
    end)

    btn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            Library.PlaySound(SOUND_CLICK)
            spawnClickRipple(btn, input.Position)
            if Library.Settings.Animations then
                TweenService:Create(uiScale, pressSquish, { Scale = 0.94 }):Play()
            end
        end
    end)

    btn.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if Library.Settings.Animations then
                local targetScale = isHovered and 1.025 or 1
                TweenService:Create(uiScale, springBounce, { Scale = targetScale }):Play()
            end
        end
    end)
end

local wiggleData = {}
function Library.StepWiggle(label: TextLabel)
    if not Library.Settings.Animations then return end
    if not wiggleData[label] then
        wiggleData[label] = {
            BaseSize = label.TextSize,
            Dir = -1,
            TwTilt = nil,
            TwBack = nil
        }
    end
    local data = wiggleData[label]
    data.Dir = -data.Dir

    if data.TwTilt then data.TwTilt:Cancel() end
    if data.TwBack then data.TwBack:Cancel() end

    data.TwTilt = TweenService:Create(label, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Rotation = data.Dir * 14,
        TextSize = data.BaseSize + 3.5
    })
    data.TwTilt:Play()

    task.delay(0.08, function()
        data.TwBack = TweenService:Create(label, TweenInfo.new(0.24, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Rotation = 0,
            TextSize = data.BaseSize
        })
        data.TwBack:Play()
    end)
end

function Library:CreateWindow(config: {Title: string, Name: string, Size: UDim2?, OnUnload: (() -> ())?})
    local self = setmetatable({}, Library)
    local width = config.Size and config.Size.X.Offset or 660
    local height = config.Size and config.Size.Y.Offset or 440

    pcall(function()
        local oldB = CoreGui:FindFirstChild("BehindTheDark_Blackout")
        if oldB then oldB:Destroy() end
        local p = Players.LocalPlayer
        if p and p:FindFirstChild("PlayerGui") then
            local oldPB = p.PlayerGui:FindFirstChild("BehindTheDark_Blackout")
            if oldPB then oldPB:Destroy() end
        end
    end)

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = config.Name or "BehindTheDarkHub"
    screenGui.ResetOnSpawn = false
    screenGui.IgnoreGuiInset = true
    screenGui.DisplayOrder = 999999
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

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

    local defaultPos = UDim2.fromScale(0.5, 0.5)
    if Library.Settings.WindowPos and type(Library.Settings.WindowPos) == "table" then
        defaultPos = UDim2.new(
            Library.Settings.WindowPos.XScale or 0.5,
            Library.Settings.WindowPos.XOffset or 0,
            Library.Settings.WindowPos.YScale or 0.5,
            Library.Settings.WindowPos.YOffset or 0
        )
    end

    local outerBorder = Instance.new("Frame")
    outerBorder.Name = "MainOuterBorder"
    outerBorder.AnchorPoint = Vector2.new(0.5, 0.5)
    outerBorder.Size = UDim2.fromOffset(width, height)
    outerBorder.Position = defaultPos
    outerBorder.BackgroundColor3 = Color3.fromRGB(185, 140, 245)
    outerBorder.BorderSizePixel = 0
    outerBorder.Active = true
    outerBorder.ZIndex = 2
    outerBorder.Parent = screenGui
    Instance.new("UICorner", outerBorder).CornerRadius = UDim.new(0, 26)

    local mainBlackStroke = Instance.new("UIStroke", outerBorder)
    mainBlackStroke.Thickness = 4.5
    mainBlackStroke.Color = Color3.fromRGB(24, 6, 38)

    local windowScale = Instance.new("UIScale")
    windowScale.Scale = 1
    windowScale.Parent = outerBorder
    self.WindowScale = windowScale

    local card = Instance.new("Frame")
    card.Name = "MainCard"
    card.Size = UDim2.new(1, -6, 1, -6)
    card.Position = UDim2.fromOffset(3, 3)
    card.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    card.BorderSizePixel = 0
    card.ClipsDescendants = true
    card.ZIndex = 2
    card.Active = false
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
    self.CardInner = card

    local dragGhost = Instance.new("Frame")
    dragGhost.Name = "GhostDragFrame"
    dragGhost.AnchorPoint = Vector2.new(0.5, 0.5)
    dragGhost.Size = UDim2.fromOffset(width, height)
    dragGhost.BackgroundColor3 = Color3.fromRGB(140, 75, 215)
    dragGhost.BackgroundTransparency = 0.65
    dragGhost.BorderSizePixel = 0
    dragGhost.Visible = false
    dragGhost.ZIndex = 9999
    dragGhost.Parent = screenGui
    Instance.new("UICorner", dragGhost).CornerRadius = UDim.new(0, 26)

    local ghostStroke = Instance.new("UIStroke", dragGhost)
    ghostStroke.Thickness = 3.5
    ghostStroke.Color = Color3.fromRGB(225, 175, 255)

    local ghostGrad = Instance.new("UIGradient")
    ghostGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0.0, Color3.fromRGB(225, 150, 255)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(130, 50, 190)),
        ColorSequenceKeypoint.new(1.0, Color3.fromRGB(225, 150, 255))
    })
    ghostGrad.Rotation = 0
    ghostGrad.Offset = Vector2.new(-1, 0)
    ghostGrad.Parent = dragGhost

    task.spawn(function()
        while dragGhost and dragGhost.Parent do
            if dragGhost.Visible and Library.Settings.Animations then
                ghostGrad.Offset = Vector2.new(-1, 0)
                local twGhost = TweenService:Create(ghostGrad, TweenInfo.new(2.5, Enum.EasingStyle.Linear), {
                    Offset = Vector2.new(1, 0)
                })
                twGhost:Play()
                twGhost.Completed:Wait()
            else
                task.wait(0.3)
            end
        end
    end)

    local isToggling = false
    local function setWindowVisibilityAnimated(show: boolean)
        if isToggling then return end
        isToggling = true

        if show then
            outerBorder.Visible = true
            Library.PlaySound(SOUND_TOGGLE)
            if Library.Settings.Animations then
                windowScale.Scale = 0.05
                local twOpen = TweenService:Create(windowScale, windowPopOpen, { Scale = 1 })
                twOpen:Play()
                twOpen.Completed:Wait()
            else
                windowScale.Scale = 1
            end
        else
            Library.PlaySound(SOUND_TOGGLE)
            if Library.Settings.Animations then
                local twClose = TweenService:Create(windowScale, windowSquishClose, { Scale = 0.05 })
                twClose:Play()
                twClose.Completed:Wait()
            end
            outerBorder.Visible = false
            windowScale.Scale = 1
        end
        isToggling = false
    end

    local isDragging = false
    local dragStartMouse = Vector3.new()
    local dragStartPos = UDim2.new()

    outerBorder.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isDragging = true
            dragStartMouse = input.Position
            dragStartPos = outerBorder.Position
            dragGhost.Position = dragStartPos
            dragGhost.Visible = true
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if isDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStartMouse
            dragGhost.Position = UDim2.new(dragStartPos.X.Scale, dragStartPos.X.Offset + delta.X, dragStartPos.Y.Scale, dragStartPos.Y.Offset + delta.Y)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if isDragging and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
            isDragging = false
            dragGhost.Visible = false
            local finalPos = dragGhost.Position
            TweenService:Create(outerBorder, TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                Position = finalPos
            }):Play()

            Library.Settings.WindowPos = {
                XScale = finalPos.X.Scale,
                XOffset = finalPos.X.Offset,
                YScale = finalPos.Y.Scale,
                YOffset = finalPos.Y.Offset
            }
            Library.SaveSettings()
        end
    end)

    -- Title Bar
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
    titleLabel.Size = UDim2.new(1, -270, 1, 0)
    titleLabel.Position = UDim2.fromOffset(14, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = config.Title or "BEHIND THE DARK"
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.TextSize = 16
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
            if Library.Settings.Animations then
                rainbowGrad.Offset = Vector2.new(-1, 0)
                local tw = TweenService:Create(rainbowGrad, TweenInfo.new(3, Enum.EasingStyle.Linear), {
                    Offset = Vector2.new(1, 0)
                })
                tw:Play()
                tw.Completed:Wait()
            else
                task.wait(0.5)
            end
        end
    end)

    local shortcutHint = Instance.new("TextLabel")
    shortcutHint.Size = UDim2.fromOffset(80, 20)
    shortcutHint.Position = UDim2.new(1, -242, 0.5, -10)
    shortcutHint.BackgroundTransparency = 1
    shortcutHint.Text = "[RightShift]"
    shortcutHint.TextColor3 = Color3.fromRGB(180, 160, 210)
    shortcutHint.TextTransparency = 0.35
    shortcutHint.TextSize = 11
    shortcutHint.Font = Enum.Font.FredokaOne
    shortcutHint.ZIndex = 6
    shortcutHint.Parent = titlePlate

    -- ปุ่มปิดสีแดง (Close)
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
        if self.LockConnection then
            self.LockConnection:Disconnect()
            self.LockConnection = nil
        end
        if config.OnUnload then pcall(config.OnUnload) end
        setWindowVisibilityAnimated(false)
        blackoutGui:Destroy()
        screenGui:Destroy()
    end)

    -- ปุ่ม Settings สีเหลือง
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

    -- ปุ่ม 3D Toggle
    local btn3DRim = Instance.new("Frame")
    btn3DRim.Size = UDim2.fromOffset(74, 30)
    btn3DRim.Position = UDim2.new(1, -152, 0.5, -15)
    btn3DRim.BackgroundColor3 = Color3.fromRGB(190, 255, 145)
    btn3DRim.BorderSizePixel = 0
    btn3DRim.ZIndex = 6
    btn3DRim.Parent = titlePlate
    Instance.new("UICorner", btn3DRim).CornerRadius = UDim.new(0, 10)
    local b3ds = Instance.new("UIStroke", btn3DRim)
    b3ds.Thickness = 2.5
    b3ds.Color = Color3.fromRGB(22, 5, 36)

    local btn3D = Instance.new("TextButton")
    btn3D.Size = UDim2.new(1, -4, 1, -4)
    btn3D.Position = UDim2.fromOffset(2, 2)
    btn3D.BackgroundColor3 = Color3.fromRGB(115, 225, 70)
    btn3D.Text = "3D: ON"
    btn3D.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn3D.TextSize = 12
    btn3D.Font = Enum.Font.FredokaOne
    btn3D.BorderSizePixel = 0
    btn3D.AutoButtonColor = false
    btn3D.ZIndex = 7
    btn3D.Parent = btn3DRim
    Instance.new("UICorner", btn3D).CornerRadius = UDim.new(0, 8)
    local b3dts = Instance.new("UIStroke", btn3D)
    b3dts.Thickness = 2.5
    b3dts.Color = Color3.fromRGB(22, 5, 36)
    Library.AttachInteractiveEffects(btn3D, btn3DRim)

    local is3DActive = true
    local originalCamType = Enum.CameraType.Custom
    local originalCamCFrame = nil

    btn3D.Activated:Connect(function()
        is3DActive = not is3DActive
        Library.PlaySound(SOUND_TOGGLE)
        local cam = workspace.CurrentCamera

        if not is3DActive then
            pcall(function()
                if cam then
                    originalCamType = cam.CameraType
                    originalCamCFrame = cam.CFrame
                    cam.CameraType = Enum.CameraType.Scriptable
                end
            end)
            self.BlackoutFrame.Visible = true

            if self.LockConnection then self.LockConnection:Disconnect() end
            self.LockConnection = RunService.RenderStepped:Connect(function()
                if not is3DActive then
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

            btn3DRim.BackgroundColor3 = Color3.fromRGB(255, 140, 150)
            btn3D.BackgroundColor3 = Color3.fromRGB(235, 65, 75)
            btn3D.Text = "3D: OFF"
        else
            if self.LockConnection then
                self.LockConnection:Disconnect()
                self.LockConnection = nil
            end
            pcall(function()
                if cam then
                    cam.CameraType = originalCamType or Enum.CameraType.Custom
                    if originalCamCFrame then cam.CFrame = originalCamCFrame end
                end
            end)
            self.BlackoutFrame.Visible = false
            btn3DRim.BackgroundColor3 = Color3.fromRGB(190, 255, 145)
            btn3D.BackgroundColor3 = Color3.fromRGB(115, 225, 70)
            btn3D.Text = "3D: ON"
        end
    end)

    -- หน้าหลัก (Main View)
    local mainView = Instance.new("Frame")
    mainView.Name = "MainView"
    mainView.Size = UDim2.new(1, 0, 1, -64)
    mainView.Position = UDim2.fromOffset(0, 64)
    mainView.BackgroundTransparency = 1
    mainView.ZIndex = 3
    mainView.Parent = card
    self.MainView = mainView

    local function createColumnTray(pos: UDim2, size: UDim2)
        local trayRim = Instance.new("Frame")
        trayRim.Size = size
        trayRim.Position = pos
        trayRim.BackgroundColor3 = Color3.fromRGB(98, 52, 148)
        trayRim.BorderSizePixel = 0
        trayRim.ZIndex = 3
        trayRim.Parent = mainView
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

    self.LeftColumn = createColumnTray(UDim2.fromOffset(14, 0), UDim2.new(0.5, -20, 1, -12))
    self.RightColumn = createColumnTray(UDim2.new(0.5, 6, 0, 0), UDim2.new(0.5, -20, 1, -12))
    self.CenterColumn = self.LeftColumn

    -- ========================================================
    -- ม่าน Dim (Dark Backdrop) สำหรับหน้า Setting
    -- ========================================================
    local settingDim = Instance.new("TextButton")
    settingDim.Name = "SettingDimBackdrop"
    settingDim.Size = UDim2.fromScale(1, 1)
    settingDim.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    settingDim.BackgroundTransparency = 0.55
    settingDim.Text = ""
    settingDim.AutoButtonColor = false
    settingDim.BorderSizePixel = 0
    settingDim.ZIndex = 69
    settingDim.Visible = false
    settingDim.Parent = card

    -- หน้าต่าง Visual & Sound Settings Modal (เพิ่มเงาปุ่ม 3 ชั้น)
    local settingsModal = Instance.new("Frame")
    settingsModal.Name = "SettingsModal"
    settingsModal.Size = UDim2.fromOffset(290, 310)
    settingsModal.Position = UDim2.new(0.5, -145, 0.5, -155)
    settingsModal.BackgroundColor3 = Color3.fromRGB(65, 22, 105)
    settingsModal.BorderSizePixel = 0
    settingsModal.ZIndex = 70
    settingsModal.Active = true
    settingsModal.Visible = false
    settingsModal.Parent = card
    Instance.new("UICorner", settingsModal).CornerRadius = UDim.new(0, 20)
    
    local smStroke = Instance.new("UIStroke", settingsModal)
    smStroke.Thickness = 4.5
    smStroke.Color = Color3.fromRGB(22, 5, 36)

    -- ผิวด้านใน Modal
    local smInner = Instance.new("Frame")
    smInner.Size = UDim2.new(1, -6, 1, -6)
    smInner.Position = UDim2.fromOffset(3, 3)
    smInner.BackgroundColor3 = Color3.fromRGB(48, 16, 76)
    smInner.BorderSizePixel = 0
    smInner.ZIndex = 70
    smInner.Parent = settingsModal
    Instance.new("UICorner", smInner).CornerRadius = UDim.new(0, 17)
    applyCartoonSurface(smInner, 70, 17, false)

    local smTitle = Instance.new("TextLabel")
    smTitle.Size = UDim2.new(1, -20, 0, 35)
    smTitle.Position = UDim2.fromOffset(12, 10)
    smTitle.BackgroundTransparency = 1
    smTitle.Text = "VISUAL & SOUND"
    smTitle.TextColor3 = Color3.fromRGB(255, 225, 95)
    smTitle.TextSize = 16
    smTitle.Font = Enum.Font.FredokaOne
    smTitle.ZIndex = 72
    smTitle.Parent = smInner
    local smts = Instance.new("UIStroke", smTitle)
    smts.Thickness = 3
    smts.Color = Color3.fromRGB(22, 5, 36)

    local settingsScroll = Instance.new("ScrollingFrame")
    settingsScroll.Size = UDim2.new(1, -16, 1, -55)
    settingsScroll.Position = UDim2.fromOffset(8, 48)
    settingsScroll.BackgroundTransparency = 1
    settingsScroll.BorderSizePixel = 0
    settingsScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    settingsScroll.ZIndex = 71
    settingsScroll.Parent = smInner
    Library.ApplyCartoonScrollbar(settingsScroll)

    local sLayout = Instance.new("UIListLayout", settingsScroll)
    sLayout.Padding = UDim.new(0, 8)

    -- ฟังก์ชันสร้างแถว Setting พร้อมเงาปุ่ม 3 ชั้น (3D Layered Shadow)
    local function createSettingRow(text: string, settingKey: string, onToggle: ((boolean) -> ())?)
        -- ชั้นที่ 1: เงาดำเข้มด้านล่างสุด
        local rowShadow = Instance.new("Frame")
        rowShadow.Size = UDim2.new(1, -10, 0, 42)
        rowShadow.BackgroundColor3 = Color3.fromRGB(16, 3, 26)
        rowShadow.BorderSizePixel = 0
        rowShadow.ZIndex = 72
        rowShadow.Parent = settingsScroll
        Instance.new("UICorner", rowShadow).CornerRadius = UDim.new(0, 12)

        -- ชั้นที่ 2: ขอบนูนกลาง
        local rowRim = Instance.new("Frame")
        rowRim.Size = UDim2.new(1, 0, 0, 39)
        rowRim.Position = UDim2.fromOffset(0, 0)
        rowRim.BackgroundColor3 = Color3.fromRGB(98, 52, 148)
        rowRim.BorderSizePixel = 0
        rowRim.ZIndex = 73
        rowRim.Parent = rowShadow
        Instance.new("UICorner", rowRim).CornerRadius = UDim.new(0, 12)
        local rs = Instance.new("UIStroke", rowRim)
        rs.Thickness = 2.5
        rs.Color = Color3.fromRGB(22, 5, 36)

        -- ชั้นที่ 3: พื้นผิวปุ่มหลัก
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, -6, 1, -5)
        row.Position = UDim2.fromOffset(3, 2)
        row.BackgroundColor3 = Color3.fromRGB(44, 14, 70)
        row.BorderSizePixel = 0
        row.ZIndex = 74
        row.Parent = rowRim
        Instance.new("UICorner", row.Parent == rowRim and row or row).CornerRadius = UDim.new(0, 10)

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -64, 1, 0)
        lbl.Position = UDim2.fromOffset(12, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = text
        lbl.TextColor3 = Color3.fromRGB(255, 225, 95)
        lbl.TextSize = 13
        lbl.Font = Enum.Font.FredokaOne
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.ZIndex = 75
        lbl.Parent = row
        local ls = Instance.new("UIStroke", lbl)
        ls.Thickness = 2.5
        ls.Color = Color3.fromRGB(22, 5, 36)

        local switchTrack = Instance.new("TextButton")
        switchTrack.Size = UDim2.fromOffset(46, 24)
        switchTrack.Position = UDim2.new(1, -54, 0.5, -12)
        switchTrack.BackgroundColor3 = Library.Settings[settingKey] and Color3.fromRGB(110, 215, 65) or Color3.fromRGB(85, 75, 105)
        switchTrack.Text = ""
        switchTrack.BorderSizePixel = 0
        switchTrack.AutoButtonColor = false
        switchTrack.ZIndex = 75
        switchTrack.Parent = row
        Instance.new("UICorner", switchTrack).CornerRadius = UDim.new(1, 0)
        local sts = Instance.new("UIStroke", switchTrack)
        sts.Thickness = 2
        sts.Color = Color3.fromRGB(22, 5, 36)

        local thumb = Instance.new("Frame")
        thumb.Size = UDim2.fromOffset(20, 20)
        thumb.Position = Library.Settings[settingKey] and UDim2.fromOffset(23, 2) or UDim2.fromOffset(2, 2)
        thumb.BackgroundColor3 = Library.Settings[settingKey] and Color3.fromRGB(115, 245, 85) or Color3.fromRGB(255, 255, 255)
        thumb.BorderSizePixel = 0
        thumb.ZIndex = 76
        thumb.Parent = switchTrack
        Instance.new("UICorner", thumb).CornerRadius = UDim.new(1, 0)

        switchTrack.Activated:Connect(function()
            Library.Settings[settingKey] = not Library.Settings[settingKey]
            local active = Library.Settings[settingKey]
            Library.PlaySound(SOUND_TOGGLE)
            Library.SaveSettings()

            TweenService:Create(switchTrack, toggleSlide, {
                BackgroundColor3 = active and Color3.fromRGB(110, 215, 65) or Color3.fromRGB(85, 75, 105)
            }):Play()
            TweenService:Create(thumb, toggleSlide, {
                Position = active and UDim2.fromOffset(23, 2) or UDim2.fromOffset(2, 2),
                BackgroundColor3 = active and Color3.fromRGB(115, 245, 85) or Color3.fromRGB(255, 255, 255)
            }):Play()

            if onToggle then onToggle(active) end
        end)
    end

    createSettingRow("All Animations", "Animations")
    createSettingRow("Looping Pattern", "MovingPattern")
    createSettingRow("Click Ripple", "ClickRipple")
    createSettingRow("Anime Glint", "AnimeGlint")
    createSettingRow("Sound Effects", "SoundEffects")

    local function toggleSettings()
        local isOpen = not settingsModal.Visible
        settingsModal.Visible = isOpen
        settingDim.Visible = isOpen
        Library.PlaySound(SOUND_CLICK)
    end

    settingsBtn.Activated:Connect(toggleSettings)
    settingDim.Activated:Connect(toggleSettings)

    UserInputService.InputBegan:Connect(function(input, gpe)
        if not gpe and input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == Enum.KeyCode.RightShift then
            setWindowVisibilityAnimated(not outerBorder.Visible)
        end
    end)

    return self
end

function Library:GetColumn(side: string): Frame
    if side == "Left" then return self.LeftColumn
    elseif side == "Right" then return self.RightColumn
    else return self.LeftColumn end
end

function Library:CreatePage(name: string)
    local pageView = Instance.new("Frame")
    pageView.Name = "PageView_" .. name
    pageView.Size = UDim2.new(1, -28, 1, -76)
    pageView.Position = UDim2.fromOffset(14, 64)
    pageView.BackgroundColor3 = Color3.fromRGB(38, 12, 62)
    pageView.BorderSizePixel = 0
    pageView.ZIndex = 5
    pageView.Visible = false
    pageView.Parent = self.CardInner
    Instance.new("UICorner", pageView).CornerRadius = UDim.new(0, 18)

    local stroke = Instance.new("UIStroke", pageView)
    stroke.Thickness = 3.5
    stroke.Color = Color3.fromRGB(22, 5, 36)

    applyCartoonSurface(pageView, 5, 18, false)

    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, -20, 1, -20)
    container.Position = UDim2.fromOffset(10, 10)
    container.BackgroundTransparency = 1
    container.ZIndex = 6
    container.Parent = pageView

    local function showPage()
        self.MainView.Visible = false
        pageView.Visible = true
        Library.PlaySound(SOUND_TOGGLE)
    end

    local function showMain()
        pageView.Visible = false
        self.MainView.Visible = true
        Library.PlaySound(SOUND_TOGGLE)
    end

    return {
        Container = container,
        Show = showPage,
        Hide = showMain
    }
end

function Library:CreateToggle(side: string, text: string, yPos: number, _: {On: Color3, Off: Color3}, default: boolean, callback: (boolean) -> ())
    local parent = self:GetColumn(side)
    local state = default or false

    local btnShadow = Instance.new("Frame")
    btnShadow.Name = "Button3DShadow"
    btnShadow.Size = UDim2.new(1, 0, 0, 44)
    btnShadow.Position = UDim2.fromOffset(0, yPos)
    btnShadow.BackgroundColor3 = Color3.fromRGB(16, 3, 26)
    btnShadow.BorderSizePixel = 0
    btnShadow.ZIndex = 5
    btnShadow.Parent = parent
    Instance.new("UICorner", btnShadow).CornerRadius = UDim.new(0, 14)

    local btnRim = Instance.new("Frame")
    btnRim.Name = "Button3DRim"
    btnRim.Size = UDim2.new(1, 0, 0, 41)
    btnRim.Position = UDim2.fromOffset(0, 0)
    btnRim.BackgroundColor3 = state and Color3.fromRGB(225, 190, 255) or Color3.fromRGB(195, 150, 250)
    btnRim.BorderSizePixel = 0
    btnRim.ZIndex = 6
    btnRim.Parent = btnShadow
    Instance.new("UICorner", btnRim).CornerRadius = UDim.new(0, 14)

    local outerBlack = Instance.new("UIStroke", btnRim)
    outerBlack.Thickness = 3
    outerBlack.Color = Color3.fromRGB(22, 5, 36)

    local onColor = Color3.fromRGB(182, 130, 248)
    local offColor = Color3.fromRGB(154, 102, 224)

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -6, 1, -5)
    btn.Position = UDim2.fromOffset(3, 2)
    btn.BackgroundColor3 = state and onColor or offColor
    btn.BorderSizePixel = 0
    btn.AutoButtonColor = false
    btn.Text = ""
    btn.ClipsDescendants = true
    btn.ZIndex = 7
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
            if Library.Settings.Animations then
                btnGrad.Offset = Vector2.new(-1, 0)
                local tw = TweenService:Create(btnGrad, TweenInfo.new(3.5, Enum.EasingStyle.Linear), {
                    Offset = Vector2.new(1, 0)
                })
                tw:Play()
                tw.Completed:Wait()
            else
                task.wait(0.5)
            end
        end
    end)

    applyCartoonSurface(btn, 7, 11, true)

    local gloss = Instance.new("Frame")
    gloss.Size = UDim2.new(1, -10, 0.42, 0)
    gloss.Position = UDim2.fromOffset(5, 2)
    gloss.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    gloss.BackgroundTransparency = 0.74
    gloss.BorderSizePixel = 0
    gloss.ZIndex = 8
    gloss.Parent = btn
    Instance.new("UICorner", gloss).CornerRadius = UDim.new(0, 9)

    local LIME_COLOR = Color3.fromRGB(180, 255, 75)
    local OFF_COLOR = Color3.fromRGB(175, 175, 185)

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -66, 1, 0)
    label.Position = UDim2.fromOffset(12, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = state and LIME_COLOR or OFF_COLOR
    label.TextSize = 14
    label.Font = Enum.Font.FredokaOne
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.ZIndex = 9
    label.Text = text
    label.Parent = btn
    local ts = Instance.new("UIStroke", label)
    ts.Thickness = 3.2
    ts.Color = Color3.fromRGB(24, 5, 38)

    local limeGrad = Instance.new("UIGradient")
    limeGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0.0, Color3.fromRGB(175, 255, 65)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(245, 255, 215)),
        ColorSequenceKeypoint.new(1.0, Color3.fromRGB(175, 255, 65))
    })
    limeGrad.Offset = Vector2.new(-1, 0)
    limeGrad.Enabled = state
    limeGrad.Parent = label

    task.spawn(function()
        while label and label.Parent do
            if state and Library.Settings.Animations then
                limeGrad.Offset = Vector2.new(-1, 0)
                local twLime = TweenService:Create(limeGrad, TweenInfo.new(2.4, Enum.EasingStyle.Linear), {
                    Offset = Vector2.new(1, 0)
                })
                twLime:Play()
                twLime.Completed:Wait()
            else
                task.wait(0.4)
            end
        end
    end)

    local switchTrack = Instance.new("Frame")
    switchTrack.Size = UDim2.fromOffset(42, 22)
    switchTrack.Position = UDim2.new(1, -48, 0.5, -11)
    switchTrack.BackgroundColor3 = Color3.fromRGB(36, 12, 58)
    switchTrack.BorderSizePixel = 0
    switchTrack.ZIndex = 9
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
    thumb.ZIndex = 10
    thumb.Parent = switchTrack
    Instance.new("UICorner", thumb).CornerRadius = UDim.new(1, 0)

    Library.AttachInteractiveEffects(btn, btnShadow)

    local function setVisual(val: boolean)
        state = val
        limeGrad.Enabled = state
        local labelColor = state and LIME_COLOR or OFF_COLOR
        local thumbColor = state and Color3.fromRGB(115, 245, 85) or Color3.fromRGB(175, 175, 185)

        TweenService:Create(label, toggleSlide, { TextColor3 = labelColor }):Play()
        TweenService:Create(thumb, toggleSlide, {
            Position = state and UDim2.fromOffset(22, 2) or UDim2.fromOffset(2, 2),
            BackgroundColor3 = thumbColor
        }):Play()
    end

    btn.Activated:Connect(function()
        state = not state
        Library.PlaySound(SOUND_TOGGLE)
        setVisual(state)
        callback(state)
    end)

    return setVisual
end

function Library:CreateDropdown(side: string, title: string, yPos: number, options: {any}, default: any, zIndexOffset: number, callback: (any) -> ())
    local parent = self:GetColumn(side)
    local selected = default
    local zBase = 15 + (zIndexOffset or 0)

    local dropShadow = Instance.new("Frame")
    dropShadow.Size = UDim2.new(1, 0, 0, 44)
    dropShadow.Position = UDim2.fromOffset(0, yPos)
    dropShadow.BackgroundColor3 = Color3.fromRGB(16, 3, 26)
    dropShadow.BorderSizePixel = 0
    dropShadow.ZIndex = zBase
    dropShadow.Parent = parent
    Instance.new("UICorner", dropShadow).CornerRadius = UDim.new(0, 14)

    local dropRim = Instance.new("Frame")
    dropRim.Size = UDim2.new(1, 0, 0, 41)
    dropRim.Position = UDim2.fromOffset(0, 0)
    dropRim.BackgroundColor3 = Color3.fromRGB(115, 95, 175)
    dropRim.BorderSizePixel = 0
    dropRim.ZIndex = zBase + 1
    dropRim.Parent = dropShadow
    Instance.new("UICorner", dropRim).CornerRadius = UDim.new(0, 14)
    local cs = Instance.new("UIStroke", dropRim)
    cs.Thickness = 3
    cs.Color = Color3.fromRGB(22, 5, 36)

    local selectBtn = Instance.new("TextButton")
    selectBtn.Size = UDim2.new(1, -6, 1, -5)
    selectBtn.Position = UDim2.fromOffset(3, 2)
    selectBtn.BackgroundColor3 = Color3.fromRGB(48, 20, 82)
    selectBtn.BorderSizePixel = 0
    selectBtn.AutoButtonColor = false
    selectBtn.Text = ""
    selectBtn.ClipsDescendants = true
    selectBtn.ZIndex = zBase + 2
    selectBtn.Parent = dropRim
    Instance.new("UICorner", selectBtn).CornerRadius = UDim.new(0, 11)

    applyCartoonSurface(selectBtn, zBase + 2, 11, false)

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

    Library.AttachInteractiveEffects(selectBtn, dropShadow)

    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1, 0, 0, 88)
    scroll.Position = UDim2.fromOffset(0, 46)
    scroll.BackgroundColor3 = Color3.fromRGB(34, 10, 58)
    scroll.BorderSizePixel = 0
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scroll.Visible = false
    scroll.ZIndex = zBase + 20
    scroll.Parent = dropRim
    Instance.new("UICorner", scroll).CornerRadius = UDim.new(0, 12)
    local ss = Instance.new("UIStroke", scroll)
    ss.Thickness = 3
    ss.Color = Color3.fromRGB(22, 5, 36)
    Library.ApplyCartoonScrollbar(scroll)

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
                Library.PlaySound(SOUND_CLICK)
                selectLabel.Text = string.format("%s: %s", title, tostring(selected))
                scroll.Visible = false
                callback(selected)
            end)
        end
    end

    selectBtn.Activated:Connect(function()
        scroll.Visible = not scroll.Visible
        Library.PlaySound(SOUND_CLICK)
        if scroll.Visible then populate() end
    end)

    return {
        SetOptions = function(newOptions: {any})
            options = newOptions
            if not table.find(options, selected) and #options > 0 then
                selected = options[1]
                selectLabel.Text = string.format("%s: %s", title, tostring(selected))
                callback(selected)
            end
            if scroll.Visible then populate() end
        end
    }
end

return Library
