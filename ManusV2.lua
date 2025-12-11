-- LIWA Victim Panel — راكان مود 💚
-- استهداف ضحية + تحكم + سبام + حماية + تايتل مخصص + نسخ 1-20

-----------------[ الخدمات الأساسية ]-----------------

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer

-----------------[ نظام الإشعارات البسيط ]-----------------

local NotificationGui = Instance.new("ScreenGui")
NotificationGui.Name = "LIWA_Notifications"
NotificationGui.ResetOnSpawn = false
NotificationGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
NotificationGui.Parent = CoreGui

local activeNotifications = {}

local function showNotification(message)
    local notification = Instance.new("Frame")
    notification.Size = UDim2.new(0, 320, 0, 60)
    notification.Position = UDim2.new(1, -330, 0, 15 + (#activeNotifications * 70))
    notification.BackgroundColor3 = Color3.new(0, 0, 0)
    notification.BorderSizePixel = 2
    notification.BorderColor3 = Color3.new(1, 1, 1)

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = notification

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -10, 1, -10)
    label.Position = UDim2.new(0, 5, 0, 5)
    label.BackgroundTransparency = 1
    label.Text = message
    label.TextColor3 = Color3.new(1, 1, 1)
    label.TextWrapped = true
    label.Font = Enum.Font.GothamBold
    label.TextSize = 14
    label.Parent = notification

    notification.Parent = NotificationGui
    table.insert(activeNotifications, notification)

    notification.Position = UDim2.new(1, 400, 0, notification.Position.Y.Offset)
    TweenService:Create(notification, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Position = UDim2.new(1, -330, 0, notification.Position.Y.Offset)
    }):Play()

    task.delay(4, function()
        if notification.Parent then
            TweenService:Create(notification, TweenInfo.new(0.3), {
                Position = UDim2.new(1, 400, 0, notification.Position.Y.Offset)
            }):Play()
            task.wait(0.35)
            notification:Destroy()

            local index = table.find(activeNotifications, notification)
            if index then
                table.remove(activeNotifications, index)
            end

            for i, notif in ipairs(activeNotifications) do
                notif.Position = UDim2.new(1, -330, 0, 15 + ((i - 1) * 70))
            end
        end
    end)
end

-----------------[ وظائف مساعدة ]-----------------

local function findPlayerByPartialName(partialName)
    if not partialName or partialName == "" then return nil end
    partialName = partialName:lower()
    local exact

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr.Name:lower() == partialName or plr.DisplayName:lower() == partialName then
            exact = plr
            break
        end
    end
    if exact then return exact end

    local matches = {}
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr.Name:lower():sub(1, #partialName) == partialName
            or plr.DisplayName:lower():sub(1, #partialName) == partialName then
            table.insert(matches, plr)
        end
    end
    if #matches == 1 then
        return matches[1]
    end
    return nil
end

local function getAccountAgeFromPlayer(plr)
    if not plr then return 0,0,0 end
    local days = plr.AccountAge or 0
    local years = math.floor(days/365)
    local months = math.floor((days%365)/30)
    local rem = days%30
    return years, months, rem
end

local function getVictimTools(plr)
    local tools = {}
    if not plr then return tools end

    local backpack = plr:FindFirstChildOfClass("Backpack")
    if backpack then
        for _, tool in ipairs(backpack:GetChildren()) do
            if tool:IsA("Tool") then
                table.insert(tools, tool.Name)
            end
        end
    end
    if plr.Character then
        for _, tool in ipairs(plr.Character:GetChildren()) do
            if tool:IsA("Tool") then
                table.insert(tools, tool.Name)
            end
        end
    end
    return tools
end

-----------------[ متغيرات عامة ]-----------------

local currentVictimName = nil
local originalCameraSubject = workspace.CurrentCamera.CameraSubject
local isSpectating = false

local bangActive = false
local bangConnection
local bangTargetPlayer

local bangFrontActive = false
local bangFrontConnection
local bangFrontTargetPlayer

local headSucking = false
local headSuckTargetPlayer
local headSuckAnimTrack

local skidFlingActive = false
local skidFlingConnection
local IsFlinging = false

local SIMPLE_OFFSET = Vector3.new(0,0.5,0)

local autoButtonsActive = {}
local autoButtonsThreads = {}

local autoSpamActive = {}
local autoSpamThreads = {}

local antiCopyActive = false
local antiCopyThread
local antiCopyNoModActive = false
local antiCopyNoModThread

local autoTitleActive = false
local autoTitleThread
local defaultTitleText = "اًلًجًرًاًرًهً اًلًعًفًوًيًهً"

local protectedUsernames = {
    "Ghgdtuhvdddd",
    "2liiliil",
    "fzd_200",
    "1il5f",
    "1il5i",
    "sj3zx"
}

-----------------[ أوامر HD Admin ; ]-----------------

local function normalizeCommandString(cmd)
    cmd = cmd:gsub("^%.", ";")
    cmd = cmd:gsub(" %.", " ;")
    return cmd
end

local function executeCommand(command)
    local HDAdminHDClient = ReplicatedStorage:FindFirstChild("HDAdminHDClient")
    if not HDAdminHDClient then return end
    local Signals = HDAdminHDClient:FindFirstChild("Signals")
    if not Signals then return end
    local RequestCommandSilent = Signals:FindFirstChild("RequestCommandSilent")
    if not RequestCommandSilent then return end

    local finalCommand = normalizeCommandString(command)
    pcall(function()
        RequestCommandSilent:InvokeServer(finalCommand)
    end)
end

local function requireVictim()
    if not currentVictimName then
        showNotification("❌ لم يتم تحديد ضحية")
        return nil
    end
    local victim = findPlayerByPartialName(currentVictimName)
    if not victim then
        showNotification("❌ الضحية غير موجودة في السيرفر")
        return nil
    end
    return victim
end

local function executeVictimCommand(cmd)
    local victim = requireVictim()
    if not victim then return end
    executeCommand(cmd.." "..victim.Name.." ")
end

local function executeFly(speed)
    local victim = requireVictim()
    if not victim then return end
    executeCommand(";fly "..victim.Name.." "..tostring(speed).." ")
end

local function executeSpeed(speed)
    local victim = requireVictim()
    if not victim then return end
    executeCommand(";speed "..victim.Name.." "..tostring(speed).." ")
end

local function executeSize(size)
    local victim = requireVictim()
    if not victim then return end
    executeCommand(";size "..victim.Name.." "..tostring(size).." ")
end

local function executeCharSkin(char)
    local victim = requireVictim()
    if not victim then return end
    executeCommand(";char "..victim.Name.." "..char.." ")
end

local function executeColor(color)
    local victim = requireVictim()
    if not victim then return end
    executeCommand(";colour "..victim.Name.." "..color.." ")
end

local function executeWhite()
    local victim = requireVictim()
    if not victim then return end
    executeCommand(";color "..victim.Name.." White ")
end

local function executeStopAll()
    local victim = requireVictim()
    if not victim then return end
    local n = victim.Name
    executeCommand(";unwormify "..n.." ;undog "..n.." ;unneon "..n.." ;unchar "..n.." ")
end

local function executeSuspendVictim()
    local victim = requireVictim()
    if not victim then return end
    executeCommand(";speed "..victim.Name.." 01. ")
end

local function executeUnsuspendVictim()
    local victim = requireVictim()
    if not victim then return end
    executeCommand(";speed "..victim.Name.." ")
end

local function executeSuspendFly()
    local victim = requireVictim()
    if not victim then return end
    executeCommand(";fly "..victim.Name.." 10. ")
end

local function executeUnsuspendFly()
    local victim = requireVictim()
    if not victim then return end
    executeCommand(";fly "..victim.Name.." ")
end

local function executeSuspendF()
    local victim = requireVictim()
    if not victim then return end
    local n = victim.Name
    executeCommand(";speed "..n.." 01. ;jp "..n.." ")
end

local function executeUnsuspendF()
    local victim = requireVictim()
    if not victim then return end
    local n = victim.Name
    executeCommand(";speed "..n.."  ;unjp "..n.." ")
end

local function executeSuspendJump()
    local victim = requireVictim()
    if not victim then return end
    executeCommand(";jp "..victim.Name.." ")
end

local function executeUnsuspendJump()
    local victim = requireVictim()
    if not victim then return end
    executeCommand(";unjp "..victim.Name.." ")
end

local function executeFlyInAir()
    local victim = requireVictim()
    if not victim then return end
    local n = victim.Name
    executeCommand(";jp "..n.." 999999999999999999 ;jump "..n.." ")
end

local function executePhase()
    executeVictimCommand(";phase")
end

local function executePlane()
    executeVictimCommand(";plane")
end

local function executeFreakify()
    executeVictimCommand(";freakify")
end

-----------------[ أزرار تلقائية عامة ]-----------------

local buttonInstances = {}
local ScrollFrame
local TitlesFrame

local function toggleAutoButton(buttonType, func, interval)
    if autoButtonsActive[buttonType] then
        autoButtonsActive[buttonType] = false
        autoButtonsThreads[buttonType] = nil
        if buttonInstances[buttonType] then
            buttonInstances[buttonType].Text = (buttonInstances[buttonType].Text:gsub(" ✅",""))
            buttonInstances[buttonType].BackgroundColor3 = Color3.new(0,0,0)
        end
    else
        autoButtonsActive[buttonType] = true
        if buttonInstances[buttonType] then
            buttonInstances[buttonType].Text = buttonInstances[buttonType].Text.." ✅"
            buttonInstances[buttonType].BackgroundColor3 = Color3.new(0,0.5,0)
        end
        autoButtonsThreads[buttonType] = coroutine.wrap(function()
            while autoButtonsActive[buttonType] do
                func()
                task.wait(interval)
            end
        end)()
    end
end

-----------------[ مشاهدة / انتقال ]-----------------

local function toggleSpectate()
    local victim = requireVictim()
    if not victim then return end

    if not isSpectating then
        if victim.Character and victim.Character:FindFirstChild("Humanoid") then
            originalCameraSubject = workspace.CurrentCamera.CameraSubject
            workspace.CurrentCamera.CameraSubject = victim.Character.Humanoid
            isSpectating = true
            if buttonInstances["spectate"] then
                buttonInstances["spectate"].Text = "إلغاء المشاهدة"
            end
        end
    else
        workspace.CurrentCamera.CameraSubject = originalCameraSubject
        isSpectating = false
        if buttonInstances["spectate"] then
            buttonInstances["spectate"].Text = "مشاهدة"
        end
    end
end

local function teleportToPlayer()
    local victim = requireVictim()
    if not victim then return end
    if victim.Character and victim.Character:FindFirstChild("HumanoidRootPart")
    and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
        player.Character.HumanoidRootPart.CFrame =
            victim.Character.HumanoidRootPart.CFrame + Vector3.new(0,3,0)
    end
end

-----------------[ Bang / BangFront / HeadSuck ]-----------------

local function playBangAnimation()
    local char = player.Character
    if not char then return nil end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return nil end

    for _, t in ipairs(hum:GetPlayingAnimationTracks()) do
        t:Stop()
    end

    local anim = Instance.new("Animation")
    anim.AnimationId = "rbxassetid://10714068222"
    local track = hum:LoadAnimation(anim)
    track.Looped = true
    track:Play()
    pcall(function() track:AdjustSpeed(2000) end)
    return track
end

local function startBang()
    local victim = requireVictim()
    if not victim or not victim.Character then return end

    bangActive = true
    bangTargetPlayer = victim
    local animTrack = playBangAnimation()
    if bangConnection then bangConnection:Disconnect() end

    bangConnection = RunService.Heartbeat:Connect(function()
        if bangActive and bangTargetPlayer and bangTargetPlayer.Character and player.Character then
            local tHRP = bangTargetPlayer.Character:FindFirstChild("HumanoidRootPart")
            local pHRP = player.Character:FindFirstChild("HumanoidRootPart")
            if tHRP and pHRP then
                local dist = 1
                pHRP.CFrame = CFrame.new(
                    tHRP.Position + (tHRP.CFrame.LookVector * -dist),
                    tHRP.Position
                )
            end
            if not animTrack or not animTrack.IsPlaying then
                animTrack = playBangAnimation()
            end
        end
    end)

    if buttonInstances["bang"] then
        buttonInstances["bang"].Text = "بانق ✅"
        buttonInstances["bang"].BackgroundColor3 = Color3.new(0,0.5,0)
    end
end

local function stopBang()
    bangActive = false
    bangTargetPlayer = nil
    if bangConnection then
        bangConnection:Disconnect()
        bangConnection = nil
    end
    if player.Character then
        local hum = player.Character:FindFirstChildOfClass("Humanoid")
        if hum then
            for _, t in ipairs(hum:GetPlayingAnimationTracks()) do
                t:Stop()
            end
        end
    end
    if buttonInstances["bang"] then
        buttonInstances["bang"].Text = "بانق"
        buttonInstances["bang"].BackgroundColor3 = Color3.new(0,0,0)
    end
end

local function toggleBang()
    if bangActive then stopBang() else startBang() end
end

local function startBangFront()
    local victim = requireVictim()
    if not victim or not victim.Character then return end

    bangFrontActive = true
    bangFrontTargetPlayer = victim
    local animTrack = playBangAnimation()
    if bangFrontConnection then bangFrontConnection:Disconnect() end

    bangFrontConnection = RunService.Heartbeat:Connect(function()
        if bangFrontActive and bangFrontTargetPlayer and bangFrontTargetPlayer.Character and player.Character then
            local tHRP = bangFrontTargetPlayer.Character:FindFirstChild("HumanoidRootPart")
            local pHRP = player.Character:FindFirstChild("HumanoidRootPart")
            if tHRP and pHRP then
                local forward = tHRP.CFrame.LookVector
                local newPos = tHRP.Position + (forward * 1)
                pHRP.CFrame = CFrame.new(newPos, tHRP.Position)
            end
            if not animTrack or not animTrack.IsPlaying then
                animTrack = playBangAnimation()
            end
        end
    end)

    if buttonInstances["bangFront"] then
        buttonInstances["bangFront"].Text = "بانق من الامام ✅"
        buttonInstances["bangFront"].BackgroundColor3 = Color3.new(0,0.5,0)
    end
end

local function stopBangFront()
    bangFrontActive = false
    bangFrontTargetPlayer = nil
    if bangFrontConnection then
        bangFrontConnection:Disconnect()
        bangFrontConnection = nil
    end
    if player.Character then
        local hum = player.Character:FindFirstChildOfClass("Humanoid")
        if hum then
            for _, t in ipairs(hum:GetPlayingAnimationTracks()) do
                t:Stop()
            end
        end
    end
    if buttonInstances["bangFront"] then
        buttonInstances["bangFront"].Text = "بانق من الامام"
        buttonInstances["bangFront"].BackgroundColor3 = Color3.new(0,0,0)
    end
end

local function toggleBangFront()
    if bangFrontActive then stopBangFront() else startBangFront() end
end

-- Head Suck
local function updateHeadSuck()
    while headSucking do
        local char = player.Character
        local victim = headSuckTargetPlayer
        if char and victim and victim.Character then
            local hrp = char:FindFirstChild("HumanoidRootPart")
            local head = victim.Character:FindFirstChild("Head")
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hrp and head and hum then
                hum.Sit = true
                if not headSuckAnimTrack then
                    local anim = Instance.new("Animation")
                    anim.AnimationId = "rbxassetid://2506281703"
                    headSuckAnimTrack = hum:LoadAnimation(anim)
                    headSuckAnimTrack.Looped = true
                    headSuckAnimTrack:Play()
                    headSuckAnimTrack:AdjustSpeed(1.5)
                end
                local dir = head.CFrame.LookVector
                local pos = head.Position + dir * 1.5
                hrp.CFrame = CFrame.new(pos, head.Position)
                hrp.Velocity = Vector3.new(0,2,0)
            end
        end
        RunService.Heartbeat:Wait()
    end

    if player.Character then
        local hum = player.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.Sit = false end
    end
    if headSuckAnimTrack then
        headSuckAnimTrack:Stop()
        headSuckAnimTrack = nil
    end
end

local function startHeadSuck(victim)
    headSuckTargetPlayer = victim
    headSucking = true
    task.spawn(updateHeadSuck)
    if buttonInstances["headSuck"] then
        buttonInstances["headSuck"].Text = "بانق بالراس ✅"
        buttonInstances["headSuck"].BackgroundColor3 = Color3.new(0,0.5,0)
    end
end

local function stopHeadSuck()
    headSucking = false
    headSuckTargetPlayer = nil
    if buttonInstances["headSuck"] then
        buttonInstances["headSuck"].Text = "بانق بالراس"
        buttonInstances["headSuck"].BackgroundColor3 = Color3.new(0,0,0)
    end
end

local function toggleHeadSuck()
    if headSucking then
        stopHeadSuck()
    else
        local victim = requireVictim()
        if victim then startHeadSuck(victim) end
    end
end

-----------------[ Skid Fling بسيط ]-----------------

local function SkidFling(targetPlayer)
    if not targetPlayer or IsFlinging then return end
    IsFlinging = true

    local char = player.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local root = hum and hum.RootPart
    if not (char and hum and root) then
        IsFlinging = false
        return
    end

    local tChar = targetPlayer.Character
    if not tChar then IsFlinging = false return end
    local tRoot = tChar:FindFirstChild("HumanoidRootPart")
        or tChar:FindFirstChild("Torso")
        or tChar:FindFirstChild("UpperTorso")
    if not tRoot then IsFlinging = false return end

    local oldPos = root.CFrame

    local bv = Instance.new("BodyVelocity")
    bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    bv.Velocity = Vector3.new(9e8,9e8,9e8)
    bv.Parent = root

    local angle = 0
    skidFlingConnection = RunService.Heartbeat:Connect(function()
        if not skidFlingActive or not targetPlayer.Character or hum.Health <= 0 then
            return
        end
        angle = angle + 10
        root.CFrame = (tRoot.CFrame * CFrame.Angles(0, math.rad(angle), 0)) * CFrame.new(0,0,5)
        root.Velocity = Vector3.new(9e7,9e7,9e7)
        root.RotVelocity = Vector3.new(9e7,9e7,9e7)
    end)

    task.delay(2, function()
        if bv then bv:Destroy() end
        if skidFlingConnection then
            skidFlingConnection:Disconnect()
            skidFlingConnection = nil
        end
        if char and hum and root then
            root.CFrame = oldPos * CFrame.new(SIMPLE_OFFSET)
            root.Velocity = Vector3.new()
            root.RotVelocity = Vector3.new()
        end
        IsFlinging = false
    end)
end

local function toggleSkidFling()
    if skidFlingActive then
        skidFlingActive = false
        if skidFlingConnection then
            skidFlingConnection:Disconnect()
            skidFlingConnection = nil
        end
        if buttonInstances["skidFling"] then
            buttonInstances["skidFling"].Text = "بانق تشويش"
            buttonInstances["skidFling"].BackgroundColor3 = Color3.new(0,0,0)
        end
    else
        local victim = requireVictim()
        if not victim then return end
        skidFlingActive = true
        if buttonInstances["skidFling"] then
            buttonInstances["skidFling"].Text = "بانق تشويش ✅"
            buttonInstances["skidFling"].BackgroundColor3 = Color3.new(0,0.5,0)
        end
        SkidFling(victim)
    end
end

-----------------[ سبام ]-----------------

local function sendSpam1()
    local Events = ReplicatedStorage:FindFirstChild("Events")
    if not Events then return end
    local SendMessage = Events:FindFirstChild("SendMessage")
    if not SendMessage then return end
    pcall(function()
        SendMessage:FireServer(string.rep("?", 200))
    end)
end

local function sendSpam2()
    local Events = ReplicatedStorage:FindFirstChild("Events")
    if not Events then return end
    local SendMessage = Events:FindFirstChild("SendMessage")
    if not SendMessage then return end
    pcall(function()
        SendMessage:FireServer(string.rep("F", 200))
    end)
end

local function sendSpam3()
    executeCommand(".re .hr")
end

local function sendSpam4()
    local Events = ReplicatedStorage:FindFirstChild("Events")
    if not Events then return end
    local SendMessage = Events:FindFirstChild("SendMessage")
    if not SendMessage then return end
    pcall(function()
        SendMessage:FireServer("سبام عربي مطوّل 😂😂😂😂😂")
    end)
end

local function sendSpam5()
    local Events = ReplicatedStorage:FindFirstChild("Events")
    if not Events then return end
    local SendMessage = Events:FindFirstChild("SendMessage")
    if not SendMessage then return end
    pcall(function()
        SendMessage:FireServer("هههههههههههههههههههههههههههههههههههههههههههههههههههههههههههههههههههههه")
    end)
end

local function toggleAutoSpam(spamType, func)
    if autoSpamActive[spamType] then
        autoSpamActive[spamType] = false
        autoSpamThreads[spamType] = nil
        if buttonInstances[spamType] then
            buttonInstances[spamType].Text = (buttonInstances[spamType].Text:gsub(" ✅",""))
            buttonInstances[spamType].BackgroundColor3 = Color3.new(0,0,0)
        end
    else
        autoSpamActive[spamType] = true
        if buttonInstances[spamType] then
            buttonInstances[spamType].Text = buttonInstances[spamType].Text.." ✅"
            buttonInstances[spamType].BackgroundColor3 = Color3.new(0,0.5,0)
        end
        autoSpamThreads[spamType] = coroutine.wrap(function()
            while autoSpamActive[spamType] do
                func()
                task.wait(0.03)
            end
        end)()
    end
end

-----------------[ حماية (مضاد نسخ) ]-----------------

local function toggleAntiCopy()
    antiCopyActive = not antiCopyActive
    if antiCopyActive then
        if buttonInstances["antiCopy"] then
            buttonInstances["antiCopy"].Text = "مضاد نسخ ✅"
            buttonInstances["antiCopy"].BackgroundColor3 = Color3.new(0,0.5,0)
        end
        antiCopyThread = coroutine.wrap(function()
            while antiCopyActive do
                executeCommand(";unwormify me  ;undog me  ;unneon me  ;unchar me ")
                task.wait(5)
            end
        end)()
    else
        antiCopyThread = nil
        if buttonInstances["antiCopy"] then
            buttonInstances["antiCopy"].Text = "مضاد نسخ"
            buttonInstances["antiCopy"].BackgroundColor3 = Color3.new(0,0,0)
        end
    end
end

local function toggleAntiCopyNoMod()
    antiCopyNoModActive = not antiCopyNoModActive
    if antiCopyNoModActive then
        if buttonInstances["antiCopyNoMod"] then
            buttonInstances["antiCopyNoMod"].Text = "مضاد نسخ بدون Mod ✅"
            buttonInstances["antiCopyNoMod"].BackgroundColor3 = Color3.new(0,0.5,0)
        end
        antiCopyNoModThread = coroutine.wrap(function()
            while antiCopyNoModActive do
                executeCommand(";char me ")
                task.wait(2)
            end
        end)()
    else
        antiCopyNoModThread = nil
        if buttonInstances["antiCopyNoMod"] then
            buttonInstances["antiCopyNoMod"].Text = "مضاد نسخ بدون Mod"
            buttonInstances["antiCopyNoMod"].BackgroundColor3 = Color3.new(0,0,0)
        end
    end
end

-----------------[ واجهة المستخدم ]-----------------

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "LIWA_VictimPanel"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = CoreGui

local ToggleButton = Instance.new("TextButton")
ToggleButton.Name = "ToggleButton"
ToggleButton.Size = UDim2.new(0, 40, 0, 40)
ToggleButton.Position = UDim2.new(0, 20, 0, 20)
ToggleButton.BackgroundColor3 = Color3.new(0, 0, 0)
ToggleButton.BorderSizePixel = 2
ToggleButton.BorderColor3 = Color3.new(1,1,1)
ToggleButton.TextColor3 = Color3.new(1,1,1)
ToggleButton.Text = "W"
ToggleButton.TextSize = 18
ToggleButton.Font = Enum.Font.GothamBlack
ToggleButton.Parent = ScreenGui

local tCorner = Instance.new("UICorner")
tCorner.CornerRadius = UDim.new(1,0)
tCorner.Parent = ToggleButton

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 420, 0, 500)
MainFrame.Position = UDim2.new(0.5, -210, 0.5, -250)
MainFrame.BackgroundColor3 = Color3.new(0,0,0)
MainFrame.BorderSizePixel = 3
MainFrame.BorderColor3 = Color3.new(1,1,1)
MainFrame.Visible = false
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0,12)
mainCorner.Parent = MainFrame

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1,0,0,50)
TitleLabel.Position = UDim2.new(0,0,0,0)
TitleLabel.BackgroundColor3 = Color3.new(0.1,0.1,0.1)
TitleLabel.BorderSizePixel = 3
TitleLabel.BorderColor3 = Color3.new(1,1,1)
TitleLabel.TextColor3 = Color3.new(1,1,1)
TitleLabel.Text = "~ LIWA Victim Panel ~"
TitleLabel.Font = Enum.Font.GothamBlack
TitleLabel.TextSize = 20
TitleLabel.Parent = MainFrame

local tlCorner = Instance.new("UICorner")
tlCorner.CornerRadius = UDim.new(0,8)
tlCorner.Parent = TitleLabel

-- محتوى اليسار
local ContentFrame = Instance.new("Frame")
ContentFrame.Size = UDim2.new(1, -140, 1, -60)
ContentFrame.Position = UDim2.new(0,10,0,55)
ContentFrame.BackgroundTransparency = 1
ContentFrame.Parent = MainFrame

-- قائمة الأقسام على اليمين
local CategoriesFrame = Instance.new("Frame")
CategoriesFrame.Size = UDim2.new(0, 120, 1, -60)
CategoriesFrame.Position = UDim2.new(1, -130, 0, 55)
CategoriesFrame.BackgroundColor3 = Color3.new(0.08,0.08,0.08)
CategoriesFrame.BorderSizePixel = 2
CategoriesFrame.BorderColor3 = Color3.new(1,1,1)
CategoriesFrame.Parent = MainFrame

local catCorner = Instance.new("UICorner")
catCorner.CornerRadius = UDim.new(0,8)
catCorner.Parent = CategoriesFrame

local catLayout = Instance.new("UIListLayout")
catLayout.Padding = UDim.new(0,2) -- تم تصغير البادينق عشان كل الأقسام تدخل
catLayout.FillDirection = Enum.FillDirection.Vertical
catLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
catLayout.SortOrder = Enum.SortOrder.LayoutOrder
catLayout.Parent = CategoriesFrame

local buttonCategory = {}
local categoryButtons = {}
local currentCategory = "control"

-- الأقسام
local categories = {
    {id="control",    label="التحكم"},
    {id="help",       label="المساعدة"},
    {id="bang",       label="البانق"},
    {id="trolling",   label="التخريب"},
    {id="copy",       label="النسخ"},
    {id="skins",      label="السكنات"},
    {id="colors",     label="الألوان"},
    {id="emotes",     label="الرقص"},
    {id="effects",    label="المؤثرات"},
    {id="clothes",    label="الملابس"},
    {id="protection", label="الحماية"},
    {id="spam",       label="السبام"},
    {id="titles",     label="التايتل"},
}

local explicitCategoryOverrides = {
    -- مساعدة (سبيد/فلاي)
    fly60   = "help",
    fly120  = "help",
    fly220  = "help",
    unfly   = "help",
    speed60 = "help",
    speed120= "help",
    speed220= "help",

    -- سبام
    spam1      = "spam",
    autoSpam1  = "spam",
    spam2      = "spam",
    autoSpam2  = "spam",
    spam3      = "spam",
    autoSpam3  = "spam",
    spam4      = "spam",
    autoSpam4  = "spam",
    spam5      = "spam",
    autoSpam5  = "spam",

    -- حماية
    antiCopy      = "protection",
    antiCopyNoMod = "protection",

    -- تحكم
    spectate = "control",
    teleport = "control",
    reset    = "control",
    to       = "control",
    view     = "control",
    unview   = "control",
}

local function defaultCategoryForOrder(order)
    if order <= 6 then return "control" end
    if order <= 8 then return "bang" end
    if order <= 36 then return "trolling" end
    if order <= 52 then return "skins" end
    if order <= 56 then return "clothes" end
    if order <= 67 then return "colors" end
    if order <= 72 then return "emotes" end
    if order <= 90 then return "effects" end
    if order <= 126 then return "copy" end
    return "trolling"
end

local function updateCategoryButtons()
    for id, btn in pairs(categoryButtons) do
        if id == currentCategory then
            btn.BackgroundColor3 = Color3.new(0,0.5,0)
        else
            btn.BackgroundColor3 = Color3.new(0.08,0.08,0.08)
        end
    end
end

local function updateButtonsVisibility()
    local titlesMode = (currentCategory == "titles")
    if ScrollFrame then ScrollFrame.Visible = not titlesMode end
    if TitlesFrame then TitlesFrame.Visible = titlesMode end

    for typeName, btn in pairs(buttonInstances) do
        local cat = buttonCategory[typeName] or "control"
        btn.Visible = (not titlesMode) and (cat == currentCategory)
    end
end

local function createCategoryButtons()
    for i, cat in ipairs(categories) do
        local btn = Instance.new("TextButton")
        btn.Name = cat.id
        btn.Size = UDim2.new(1, -10, 0, 24) -- تصغير ارتفاع زر القسم
        btn.BackgroundColor3 = Color3.new(0.08,0.08,0.08)
        btn.BorderSizePixel = 2
        btn.BorderColor3 = Color3.new(1,1,1)
        btn.TextColor3 = Color3.new(1,1,1)
        btn.Text = cat.label
        btn.TextSize = 12
        btn.Font = Enum.Font.GothamBlack
        btn.LayoutOrder = i

        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0,6)
        c.Parent = btn

        btn.Parent = CategoriesFrame

        btn.MouseButton1Click:Connect(function()
            currentCategory = cat.id
            updateCategoryButtons()
            updateButtonsVisibility()
        end)

        categoryButtons[cat.id] = btn
    end
    updateCategoryButtons()
end

-----------------[ معلومات الضحية ]-----------------

local VictimInfo = Instance.new("Frame")
VictimInfo.Size = UDim2.new(1,0,0,150)
VictimInfo.Position = UDim2.new(0,0,0,0)
VictimInfo.BackgroundColor3 = Color3.new(0.1,0.1,0.1)
VictimInfo.BorderSizePixel = 3
VictimInfo.BorderColor3 = Color3.new(1,1,1)
VictimInfo.Parent = ContentFrame

local viCorner = Instance.new("UICorner")
viCorner.CornerRadius = UDim.new(0,8)
viCorner.Parent = VictimInfo

local VictimAvatar = Instance.new("ImageLabel")
VictimAvatar.Size = UDim2.new(0,80,0,80)
VictimAvatar.Position = UDim2.new(0,10,0,10)
VictimAvatar.BackgroundColor3 = Color3.new(1,1,1)
VictimAvatar.BorderSizePixel = 2
VictimAvatar.BorderColor3 = Color3.new(1,1,1)
VictimAvatar.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
VictimAvatar.Parent = VictimInfo

local vaCorner = Instance.new("UICorner")
vaCorner.CornerRadius = UDim.new(0,6)
vaCorner.Parent = VictimAvatar

local VictimNameLabel = Instance.new("TextLabel")
VictimNameLabel.Size = UDim2.new(0,350,0,25)
VictimNameLabel.Position = UDim2.new(0,100,0,10)
VictimNameLabel.BackgroundTransparency = 1
VictimNameLabel.TextColor3 = Color3.new(1,1,1)
VictimNameLabel.Font = Enum.Font.GothamBlack
VictimNameLabel.TextSize = 16
VictimNameLabel.TextXAlignment = Enum.TextXAlignment.Left
VictimNameLabel.Text = "لا يوجد ضحية محددة"
VictimNameLabel.Parent = VictimInfo

local VictimInfoText = Instance.new("TextLabel")
VictimInfoText.Size = UDim2.new(0,350,0,100)
VictimInfoText.Position = UDim2.new(0,100,0,35)
VictimInfoText.BackgroundTransparency = 1
VictimInfoText.TextColor3 = Color3.new(1,1,1)
VictimInfoText.Font = Enum.Font.GothamBold
VictimInfoText.TextSize = 12
VictimInfoText.TextXAlignment = Enum.TextXAlignment.Left
VictimInfoText.TextYAlignment = Enum.TextYAlignment.Top
VictimInfoText.TextWrapped = true
VictimInfoText.Text = "اللقب: -\nعمر الحساب: -\nID: -\nالأدوات: -"
VictimInfoText.Parent = VictimInfo

local InputFrame = Instance.new("Frame")
InputFrame.Size = UDim2.new(1,0,0,40)
InputFrame.Position = UDim2.new(0,0,0,160)
InputFrame.BackgroundTransparency = 1
InputFrame.Parent = ContentFrame

local VictimInput = Instance.new("TextBox")
VictimInput.Size = UDim2.new(0.7,0,1,0)
VictimInput.Position = UDim2.new(0,0,0,0)
VictimInput.BackgroundColor3 = Color3.new(0.1,0.1,0.1)
VictimInput.BorderSizePixel = 3
VictimInput.BorderColor3 = Color3.new(1,1,1)
VictimInput.TextColor3 = Color3.new(1,1,1)
VictimInput.PlaceholderText = "أدخل اسم المستخدم (حرفين على الأقل)"
VictimInput.PlaceholderColor3 = Color3.new(0.7,0.7,0.7)
VictimInput.Text = ""
VictimInput.Font = Enum.Font.GothamBold
VictimInput.TextSize = 14
VictimInput.Parent = InputFrame

local viCorner2 = Instance.new("UICorner")
viCorner2.CornerRadius = UDim.new(0,6)
viCorner2.Parent = VictimInput

local SetVictimButton = Instance.new("TextButton")
SetVictimButton.Size = UDim2.new(0.28,0,1,0)
SetVictimButton.Position = UDim2.new(0.72,0,0,0)
SetVictimButton.BackgroundColor3 = Color3.new(0,0,0)
SetVictimButton.BorderSizePixel = 3
SetVictimButton.BorderColor3 = Color3.new(1,1,1)
SetVictimButton.TextColor3 = Color3.new(1,1,1)
SetVictimButton.Text = "تحديد الضحية"
SetVictimButton.Font = Enum.Font.GothamBlack
SetVictimButton.TextSize = 14
SetVictimButton.Parent = InputFrame

local svCorner = Instance.new("UICorner")
svCorner.CornerRadius = UDim.new(0,6)
svCorner.Parent = SetVictimButton

-- سكروول للأزرار
ScrollFrame = Instance.new("ScrollingFrame")
ScrollFrame.Size = UDim2.new(1,0,1,-210)
ScrollFrame.Position = UDim2.new(0,0,0,210)
ScrollFrame.BackgroundColor3 = Color3.new(0.1,0.1,0.1)
ScrollFrame.BorderSizePixel = 3
ScrollFrame.BorderColor3 = Color3.new(1,1,1)
ScrollFrame.ScrollBarThickness = 8
ScrollFrame.ScrollingDirection = Enum.ScrollingDirection.Y
ScrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
ScrollFrame.CanvasSize = UDim2.new(0,0,0,0)
ScrollFrame.Parent = ContentFrame

local sfCorner = Instance.new("UICorner")
sfCorner.CornerRadius = UDim.new(0,8)
sfCorner.Parent = ScrollFrame

local ButtonGrid = Instance.new("UIGridLayout")
ButtonGrid.CellPadding = UDim2.new(0,5,0,5)
ButtonGrid.CellSize = UDim2.new(0,110,0,35)
ButtonGrid.HorizontalAlignment = Enum.HorizontalAlignment.Center
ButtonGrid.SortOrder = Enum.SortOrder.LayoutOrder
ButtonGrid.Parent = ScrollFrame

-- قسم التايتل
TitlesFrame = Instance.new("Frame")
TitlesFrame.Size = ScrollFrame.Size
TitlesFrame.Position = ScrollFrame.Position
TitlesFrame.BackgroundColor3 = Color3.new(0.1,0.1,0.1)
TitlesFrame.BorderSizePixel = 3
TitlesFrame.BorderColor3 = Color3.new(1,1,1)
TitlesFrame.Visible = false
TitlesFrame.Parent = ContentFrame

local tfCorner = Instance.new("UICorner")
tfCorner.CornerRadius = UDim.new(0,8)
tfCorner.Parent = TitlesFrame

local TitleInput = Instance.new("TextBox")
TitleInput.Size = UDim2.new(0.9,0,0,40)
TitleInput.Position = UDim2.new(0.05,0,0,20)
TitleInput.BackgroundColor3 = Color3.new(0.1,0.1,0.1)
TitleInput.BorderSizePixel = 3
TitleInput.BorderColor3 = Color3.new(1,1,1)
TitleInput.TextColor3 = Color3.new(1,1,1)
TitleInput.PlaceholderText = "اكتب التايتل هنا..."
TitleInput.PlaceholderColor3 = Color3.new(0.7,0.7,0.7)
TitleInput.Text = ""
TitleInput.Font = Enum.Font.GothamBold
TitleInput.TextSize = 14
TitleInput.ClearTextOnFocus = false
TitleInput.Parent = TitlesFrame

local tiCorner = Instance.new("UICorner")
tiCorner.CornerRadius = UDim.new(0,6)
tiCorner.Parent = TitleInput

local ApplyTitleButton = Instance.new("TextButton")
ApplyTitleButton.Size = UDim2.new(0.4,0,0,35)
ApplyTitleButton.Position = UDim2.new(0.05,0,0,80)
ApplyTitleButton.BackgroundColor3 = Color3.new(0,0,0)
ApplyTitleButton.BorderSizePixel = 3
ApplyTitleButton.BorderColor3 = Color3.new(1,1,1)
ApplyTitleButton.TextColor3 = Color3.new(1,1,1)
ApplyTitleButton.Text = "تطبيق"
ApplyTitleButton.Font = Enum.Font.GothamBlack
ApplyTitleButton.TextSize = 14
ApplyTitleButton.Parent = TitlesFrame

local atCorner = Instance.new("UICorner")
atCorner.CornerRadius = UDim.new(0,6)
atCorner.Parent = ApplyTitleButton

local AutoTitleButton = Instance.new("TextButton")
AutoTitleButton.Size = UDim2.new(0.4,0,0,35)
AutoTitleButton.Position = UDim2.new(0.55,0,0,80)
AutoTitleButton.BackgroundColor3 = Color3.new(0,0,0)
AutoTitleButton.BorderSizePixel = 3
AutoTitleButton.BorderColor3 = Color3.new(1,1,1)
AutoTitleButton.TextColor3 = Color3.new(1,1,1)
AutoTitleButton.Text = "تلقائي"
AutoTitleButton.Font = Enum.Font.GothamBlack
AutoTitleButton.TextSize = 14
AutoTitleButton.Parent = TitlesFrame

local auCorner = Instance.new("UICorner")
auCorner.CornerRadius = UDim.new(0,6)
auCorner.Parent = AutoTitleButton

local TitleInfo = Instance.new("TextLabel")
TitleInfo.Size = UDim2.new(0.9,0,0,60)
TitleInfo.Position = UDim2.new(0.05,0,0,130)
TitleInfo.BackgroundTransparency = 1
TitleInfo.TextColor3 = Color3.new(1,1,1)
TitleInfo.Font = Enum.Font.GothamBold
TitleInfo.TextSize = 12
TitleInfo.TextWrapped = true
TitleInfo.Text = "💡 يطبق التايتل على الضحية الحالية باستخدام ;titlepk.\nلو تركت الخانة فاضية يستخدم التايتل اللي تكتبه هنا."
TitleInfo.Parent = TitlesFrame

local function applyTitleOnce()
    local victim = requireVictim()
    if not victim then return end
    local txt = TitleInput.Text
    if txt == "" then
        txt = defaultTitleText
    end
    executeCommand(";titlepk "..victim.Name.." "..txt)
    showNotification("✅ تم تطبيق التايتل على "..victim.Name)
end

local function toggleAutoTitle()
    autoTitleActive = not autoTitleActive
    if autoTitleActive then
        AutoTitleButton.Text = "تلقائي ✅"
        AutoTitleButton.BackgroundColor3 = Color3.new(0,0.5,0)
        autoTitleThread = coroutine.wrap(function()
            while autoTitleActive do
                local victim = requireVictim()
                if victim then
                    local txt = TitleInput.Text
                    if txt == "" then txt = defaultTitleText end
                    executeCommand(";titlepk "..victim.Name.." "..txt)
                end
                task.wait(3)
            end
        end)()
    else
        AutoTitleButton.Text = "تلقائي"
        AutoTitleButton.BackgroundColor3 = Color3.new(0,0,0)
        autoTitleThread = nil
    end
end

ApplyTitleButton.MouseButton1Click:Connect(applyTitleOnce)
AutoTitleButton.MouseButton1Click:Connect(toggleAutoTitle)

-----------------[ إنشاء أزرار الضحية ]-----------------

local function createButton(name, layoutOrder)
    local btn = Instance.new("TextButton")
    btn.Name = name
    btn.Size = UDim2.new(0,110,0,35)
    btn.BackgroundColor3 = Color3.new(0,0,0)
    btn.BorderSizePixel = 3
    btn.BorderColor3 = Color3.new(1,1,1)
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Text = name
    btn.Font = Enum.Font.GothamBlack
    btn.TextSize = 11
    btn.LayoutOrder = layoutOrder

    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0,6)
    c.Parent = btn

    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.15,Enum.EasingStyle.Quad,Enum.EasingDirection.Out), {
            BackgroundColor3 = Color3.new(0.2,0.2,0.2),
            Size = UDim2.new(0,115,0,38)
        }):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.15,Enum.EasingStyle.Quad,Enum.EasingDirection.Out), {
            BackgroundColor3 = Color3.new(0,0,0),
            Size = UDim2.new(0,110,0,35)
        }):Play()
    end)

    btn.Parent = ScrollFrame
    return btn
end

-- ترتيب الأزرار + الأقسام
local victimButtons = {
    {name="مشاهدة",type="spectate",order=1},
    {name="انتقال",type="teleport",order=2},
    {name="اعاده تعيين",type="reset",order=3},
    {name="to",type="to",order=4},
    {name="view",type="view",order=5},
    {name="unview",type="unview",order=6},

    {name="بانق",type="bang",order=7},
    {name="بانق من الامام",type="bangFront",order=8},
    {name="بانق بالراس",type="headSuck",order=9},
    {name="بانق تشويش",type="skidFling",order=10},

    {name="اعاده تعيين تلقائي",type="autoReset",order=11},
    {name="ايقاف الجميع",type="stopAll",order=12},
    {name="ايقاف الجميع تلقائي",type="autoStopAll",order=13},
    {name="معوق",type="cripple",order=14},
    {name="معوق تلقائي",type="autoCripple",order=15},

    {name="تطيير في الجو",type="flyInAir",order=16},
    {name="تطيير في الجو تلقائي",type="autoFlyInAir",order=17},
    {name="تعليق F",type="suspendF",order=18},
    {name="فك تعليق F",type="unsuspendF",order=19},
    {name="تعليق F تلقائي",type="autoSuspendF",order=20},

    {name="تعليق القفز",type="suspendJump",order=21},
    {name="فك تعليق القفز",type="unsuspendJump",order=22},
    {name="قفز تلقائي",type="autoJump",order=23},
    {name="تعليق الضحيه",type="suspendVictim",order=24},
    {name="فك تعليق الضحيه",type="unsuspendVictim",order=25},
    {name="تعليق الطيران",type="suspendFly",order=26},
    {name="فك تعليق الطيران",type="unsuspendFly",order=27},

    {name="طيران 60",type="fly60",order=28},
    {name="طيران 120",type="fly120",order=29},
    {name="طيران 220",type="fly220",order=30},
    {name="ايقاف الطيران",type="unfly",order=31},
    {name="سرعه 60",type="speed60",order=32},
    {name="سرعه 120",type="speed120",order=33},
    {name="سرعه 220",type="speed220",order=34},

    {name="كلب",type="dog",order=35},
    {name="كلب تلقائي",type="autoDog",order=36},
    {name="دوده",type="worm",order=37},
    {name="منور",type="neon",order=38},
    {name="ذهب",type="gold",order=39},
    {name="شفاف",type="glass",order=40},
    {name="اخفاء",type="ref",order=41},

    {name="حجم طبيعي",type="size1",order=42},
    {name="حجم متوسط",type="size2",order=43},
    {name="حجم كبير",type="size3",order=44},

    {name="سكن تخريب",type="charCrazy",order=45},
    {name="سكن Miri",type="charMiri",order=46},
    {name="char",type="char",order=47},
    {name="unchar",type="unchar",order=48},

    {name="تفصيخ تيشرت",type="shirt",order=49},
    {name="تفصيخ كامل",type="pants",order=50},
    {name="فك الهيدلست",type="head",order=51},

    {name="اسود",type="black",order=52},
    {name="ابيض",type="white",order=53},
    {name="وردي",type="pink",order=54},
    {name="بنفسجي",type="purple",order=55},
    {name="ازرق",type="blue",order=56},
    {name="اصفر",type="yellow",order=57},
    {name="احمر",type="red",order=58},
    {name="اخضر",type="green",order=59},
    {name="ايقاف اللون",type="uncolour",order=60},

    {name="رقصه 1",type="fryDance",order=61},
    {name="رقصه 2",type="takethel",order=62},
    {name="فار يرقص",type="ratDance",order=63},
    {name="جلوس 2",type="cuteSit",order=64},
    {name="ميت",type="fakeDeath",order=65},

    {name="دب",type="fat",order=66},
    {name="نحيف",type="thin",order=67},
    {name="مربع",type="hide",order=68},
    {name="معضل",type="buffify",order=69},
    {name="دبابه حربيه",type="tank",order=70},
    {name="هليكوبتر",type="helicopter",order=71},
    {name="طياره",type="plane",order=72},
    {name="سياره",type="car",order=73},
    {name="صندوق",type="box",order=74},

    {name="عشوائي",type="emote",order=75},
    {name="ارتجاج",type="phase",order=76},
    {name="دخان",type="smoke",order=77},
    {name="ايقاف الدخان",type="unsmoke",order=78},
    {name="نار",type="fire",order=79},
    {name="ايقاف النار",type="unfire",order=80},
    {name="اختفاء",type="shine",order=81},
    {name="شبح",type="ghost",order=82},

    {name="اورا تلقائي",type="autoAura",order=83},

    -- نسخ 1-20
    {name="نسخ 1",type="copy1",order=90},
    {name="نسخ 2",type="copy2",order=91},
    {name="نسخ 3",type="copy3",order=92},
    {name="نسخ 4",type="copy4",order=93},
    {name="نسخ 5",type="copy5",order=94},
    {name="نسخ 6",type="copy6",order=95},
    {name="نسخ 7",type="copy7",order=96},
    {name="نسخ 8",type="copy8",order=97},
    {name="نسخ 9",type="copy9",order=98},
    {name="نسخ 10",type="copy10",order=99},
    {name="نسخ 11",type="copy11",order=100},
    {name="نسخ 12",type="copy12",order=101},
    {name="نسخ 13",type="copy13",order=102},
    {name="نسخ 14",type="copy14",order=103},
    {name="نسخ 15",type="copy15",order=104},
    {name="نسخ 16",type="copy16",order=105},
    {name="نسخ 17",type="copy17",order=106},
    {name="نسخ 18",type="copy18",order=107},
    {name="نسخ 19",type="copy19",order=108},
    {name="نسخ 20",type="copy20",order=109},

    {name="نسخ تلقائي 1",type="autoCopy1",order=110},
    {name="نسخ تلقائي 2",type="autoCopy2",order=111},
    {name="نسخ تلقائي 3",type="autoCopy3",order=112},
    {name="نسخ تلقائي 4",type="autoCopy4",order=113},
    {name="نسخ تلقائي 5",type="autoCopy5",order=114},
    {name="نسخ تلقائي 6",type="autoCopy6",order=115},

    {name="اخفاء 1",type="hideCombo1",order=116},
    {name="اخفاء 2",type="hideCombo2",order=117},
    {name="كومبو تلقائي",type="autoHideCombo",order=118},

    -- سبام
    {name="سبام 1",type="spam1",order=120},
    {name="سبام تلقائي 1",type="autoSpam1",order=121},
    {name="سبام 2",type="spam2",order=122},
    {name="سبام تلقائي 2",type="autoSpam2",order=123},
    {name="سبام 3",type="spam3",order=124},
    {name="سبام تلقائي 3",type="autoSpam3",order=125},
    {name="سبام 4",type="spam4",order=126},
    {name="سبام تلقائي 4",type="autoSpam4",order=127},
    {name="سبام 5",type="spam5",order=128},
    {name="سبام تلقائي 5",type="autoSpam5",order=129},

    -- حماية
    {name="مضاد نسخ",type="antiCopy",order=130},
    {name="مضاد نسخ بدون Mod",type="antiCopyNoMod",order=131},
}

for _, info in ipairs(victimButtons) do
    local btn = createButton(info.name, info.order)
    buttonInstances[info.type] = btn
    local cat = explicitCategoryOverrides[info.type] or defaultCategoryForOrder(info.order)
    buttonCategory[info.type] = cat
end

createCategoryButtons()
updateButtonsVisibility()

-----------------[ تحديث معلومات الضحية ]-----------------

local function updateVictimInfo(victim)
    if victim then
        currentVictimName = victim.Name
        VictimNameLabel.Text = "الضحية: "..victim.Name

        pcall(function()
            VictimAvatar.Image = "https://www.roblox.com/headshot-thumbnail/image?userId="..
                victim.UserId.."&width=150&height=150&format=png"
        end)

        local y,m,d = getAccountAgeFromPlayer(victim)
        local tools = getVictimTools(victim)
        local toolsText = (#tools>0 and table.concat(tools,", ") or "لا يوجد أدوات")

        VictimInfoText.Text =
            "اللقب: "..victim.DisplayName..
            "\nعمر الحساب: "..y.." سنة, "..m.." شهر, "..d.." يوم"..
            "\nID: "..victim.UserId..
            "\nالأدوات: "..toolsText

        showNotification("✅ تم تحديد الضحية: "..victim.Name)
    else
        currentVictimName = nil
        VictimNameLabel.Text = "لا يوجد ضحية محددة"
        VictimAvatar.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
        VictimInfoText.Text = "اللقب: -\nعمر الحساب: -\nID: -\nالأدوات: -"
    end
end

SetVictimButton.MouseButton1Click:Connect(function()
    local username = VictimInput.Text
    if username == "" then
        showNotification("❌ أدخل اسم المستخدم")
        return
    end
    if #username < 2 then
        showNotification("❌ أدخل حرفين على الأقل")
        return
    end

    for _, protectedName in ipairs(protectedUsernames) do
        if username:lower() == protectedName:lower() then
            showNotification("❌ هذا المستخدم محمي")
            return
        end
    end

    local victim = findPlayerByPartialName(username)
    if not victim then
        showNotification("❌ لم يتم العثور على "..username)
        return
    end

    for _, protectedName in ipairs(protectedUsernames) do
        if victim.Name:lower() == protectedName:lower() then
            showNotification("❌ هذا المستخدم محمي")
            return
        end
    end

    updateVictimInfo(victim)
    VictimInput.Text = ""
end)

-----------------[ أداة استهداف بالنقر على اللاعبين ]-----------------

local targetingEnabled = false
local mouse = player:GetMouse()

local TargetButton = Instance.new("TextButton")
TargetButton.Name = "ClickTargetButton"
TargetButton.Size = UDim2.new(0, 40, 0, 40)
TargetButton.AnchorPoint = Vector2.new(1,1)
TargetButton.Position = UDim2.new(1, -20, 1, -20) -- يمين تحت مع مارجن 20
TargetButton.BackgroundColor3 = Color3.new(0,0,0)
TargetButton.BorderSizePixel = 2
TargetButton.BorderColor3 = Color3.new(1,1,1)
TargetButton.TextColor3 = Color3.new(1,1,1)
TargetButton.Text = "☝🏻"
TargetButton.TextSize = 24
TargetButton.Font = Enum.Font.GothamBlack
TargetButton.Parent = ScreenGui

local tbCorner = Instance.new("UICorner")
tbCorner.CornerRadius = UDim.new(1,0)
tbCorner.Parent = TargetButton

local function updateTargetButtonVisual()
    if targetingEnabled then
        TargetButton.BackgroundColor3 = Color3.new(0,0.5,0)
    else
        TargetButton.BackgroundColor3 = Color3.new(0,0,0)
    end
end

TargetButton.MouseButton1Click:Connect(function()
    targetingEnabled = not targetingEnabled
    updateTargetButtonVisual()
    if targetingEnabled then
        showNotification("🎯 وضع الاستهداف شغال - اضغط على اللاعب")
    else
        showNotification("⛔ تم إيقاف الاستهداف")
    end
end)

local function getPlayerFromPart(part)
    if not part then return nil end
    local model = part:FindFirstAncestorOfClass("Model")
    if not model then return nil end
    return Players:GetPlayerFromCharacter(model)
end

mouse.Button1Down:Connect(function()
    if not targetingEnabled then return end
    local target = mouse.Target
    local plr = getPlayerFromPart(target)
    if not plr then return end

    -- حماية المستخدمين المحميين
    for _, protectedName in ipairs(protectedUsernames) do
        if plr.Name:lower() == protectedName:lower() then
            showNotification("❌ هذا المستخدم محمي")
            return
        end
    end

    updateVictimInfo(plr)
    targetingEnabled = false
    updateTargetButtonVisual()
    showNotification("🎯 تم استهداف: "..plr.Name)
end)

-----------------[ ربط الأزرار بالوظائف ]-----------------

-- تحكم
buttonInstances["spectate"].MouseButton1Click:Connect(toggleSpectate)
buttonInstances["teleport"].MouseButton1Click:Connect(teleportToPlayer)
buttonInstances["reset"].MouseButton1Click:Connect(function()
    executeVictimCommand(";re")
end)
buttonInstances["to"].MouseButton1Click:Connect(function()
    executeVictimCommand(";to")
end)
buttonInstances["view"].MouseButton1Click:Connect(function()
    executeVictimCommand(";view")
end)
buttonInstances["unview"].MouseButton1Click:Connect(function()
    executeVictimCommand(";unview")
end)

-- بانق
buttonInstances["bang"].MouseButton1Click:Connect(toggleBang)
buttonInstances["bangFront"].MouseButton1Click:Connect(toggleBangFront)
buttonInstances["headSuck"].MouseButton1Click:Connect(toggleHeadSuck)
buttonInstances["skidFling"].MouseButton1Click:Connect(toggleSkidFling)

-- أوتو Reset / StopAll / Cripple
buttonInstances["autoReset"].MouseButton1Click:Connect(function()
    toggleAutoButton("autoReset", function()
        executeVictimCommand(";re")
    end, 2)
end)

buttonInstances["stopAll"].MouseButton1Click:Connect(executeStopAll)
buttonInstances["autoStopAll"].MouseButton1Click:Connect(function()
    toggleAutoButton("autoStopAll", executeStopAll, 4)
end)

buttonInstances["cripple"].MouseButton1Click:Connect(function()
    executeVictimCommand(";sit")
end)
buttonInstances["autoCripple"].MouseButton1Click:Connect(function()
    toggleAutoButton("autoCripple", function()
        executeVictimCommand(";sit")
    end, 2)
end)

-- تعليق / طيران / سبيد
buttonInstances["flyInAir"].MouseButton1Click:Connect(executeFlyInAir)
buttonInstances["autoFlyInAir"].MouseButton1Click:Connect(function()
    toggleAutoButton("autoFlyInAir", executeFlyInAir, 3)
end)

buttonInstances["suspendF"].MouseButton1Click:Connect(executeSuspendF)
buttonInstances["unsuspendF"].MouseButton1Click:Connect(executeUnsuspendF)
buttonInstances["autoSuspendF"].MouseButton1Click:Connect(function()
    toggleAutoButton("autoSuspendF", executeSuspendF, 2)
end)

buttonInstances["suspendJump"].MouseButton1Click:Connect(executeSuspendJump)
buttonInstances["unsuspendJump"].MouseButton1Click:Connect(executeUnsuspendJump)
buttonInstances["autoJump"].MouseButton1Click:Connect(function()
    toggleAutoButton("autoJump", function()
        executeVictimCommand(";jump")
    end, 2)
end)

buttonInstances["suspendVictim"].MouseButton1Click:Connect(executeSuspendVictim)
buttonInstances["unsuspendVictim"].MouseButton1Click:Connect(executeUnsuspendVictim)

buttonInstances["suspendFly"].MouseButton1Click:Connect(executeSuspendFly)
buttonInstances["unsuspendFly"].MouseButton1Click:Connect(executeUnsuspendFly)

buttonInstances["fly60"].MouseButton1Click:Connect(function() executeFly(60) end)
buttonInstances["fly120"].MouseButton1Click:Connect(function() executeFly(120) end)
buttonInstances["fly220"].MouseButton1Click:Connect(function() executeFly(220) end)
buttonInstances["unfly"].MouseButton1Click:Connect(function()
    executeVictimCommand(";unfly")
end)

buttonInstances["speed60"].MouseButton1Click:Connect(function() executeSpeed(60) end)
buttonInstances["speed120"].MouseButton1Click:Connect(function() executeSpeed(120) end)
buttonInstances["speed220"].MouseButton1Click:Connect(function() executeSpeed(220) end)

-- أشكال / سكنات / أحجام
buttonInstances["dog"].MouseButton1Click:Connect(function()
    executeVictimCommand(";dog")
end)
buttonInstances["autoDog"].MouseButton1Click:Connect(function()
    toggleAutoButton("autoDog", function()
        executeVictimCommand(";dog")
    end, 2)
end)

buttonInstances["worm"].MouseButton1Click:Connect(function()
    executeVictimCommand(";worm")
end)
buttonInstances["neon"].MouseButton1Click:Connect(function()
    executeVictimCommand(";neon")
end)
buttonInstances["gold"].MouseButton1Click:Connect(function()
    executeVictimCommand(";gold")
end)
buttonInstances["glass"].MouseButton1Click:Connect(function()
    executeVictimCommand(";glass")
end)
buttonInstances["ref"].MouseButton1Click:Connect(function()
    executeVictimCommand(";ref")
end)

buttonInstances["size1"].MouseButton1Click:Connect(function() executeSize(1) end)
buttonInstances["size2"].MouseButton1Click:Connect(function() executeSize(2) end)
buttonInstances["size3"].MouseButton1Click:Connect(function() executeSize(3) end)

buttonInstances["charCrazy"].MouseButton1Click:Connect(function()
    executeCharSkin("crazydalejrd")
end)
buttonInstances["charMiri"].MouseButton1Click:Connect(function()
    executeCharSkin("miri")
end)
buttonInstances["char"].MouseButton1Click:Connect(function()
    local victim = requireVictim()
    if not victim then return end
    executeCommand(";char "..victim.Name.." ")
end)
buttonInstances["unchar"].MouseButton1Click:Connect(function()
    local victim = requireVictim()
    if not victim then return end
    executeCommand(";unchar "..victim.Name.." ")
end)

buttonInstances["shirt"].MouseButton1Click:Connect(function()
    executeVictimCommand(";shirt")
end)
buttonInstances["pants"].MouseButton1Click:Connect(function()
    executeVictimCommand(";pants")
end)
buttonInstances["head"].MouseButton1Click:Connect(function()
    executeVictimCommand(";head")
end)

-- ألوان
buttonInstances["black"].MouseButton1Click:Connect(function() executeColor("Black") end)
buttonInstances["white"].MouseButton1Click:Connect(executeWhite)
buttonInstances["pink"].MouseButton1Click:Connect(function() executeColor("Pink") end)
buttonInstances["purple"].MouseButton1Click:Connect(function() executeColor("Purple") end)
buttonInstances["blue"].MouseButton1Click:Connect(function() executeColor("Blue") end)
buttonInstances["yellow"].MouseButton1Click:Connect(function() executeColor("Yellow") end)
buttonInstances["red"].MouseButton1Click:Connect(function() executeColor("Red") end)
buttonInstances["green"].MouseButton1Click:Connect(function() executeColor("Green") end)
buttonInstances["uncolour"].MouseButton1Click:Connect(function()
    executeVictimCommand(";uncolour")
end)

-- رقص و إيموت
buttonInstances["fryDance"].MouseButton1Click:Connect(function()
    executeVictimCommand(";fryDance")
end)
buttonInstances["takethel"].MouseButton1Click:Connect(function()
    executeVictimCommand(";takethel")
end)
buttonInstances["ratDance"].MouseButton1Click:Connect(function()
    executeVictimCommand(";ratDance")
end)
buttonInstances["cuteSit"].MouseButton1Click:Connect(function()
    executeVictimCommand(";cuteSit")
end)
buttonInstances["fakeDeath"].MouseButton1Click:Connect(function()
    executeVictimCommand(";fakeDeath")
end)

buttonInstances["fat"].MouseButton1Click:Connect(function()
    executeVictimCommand(";fat")
end)
buttonInstances["thin"].MouseButton1Click:Connect(function()
    executeVictimCommand(";thin")
end)
buttonInstances["hide"].MouseButton1Click:Connect(function()
    executeVictimCommand(";hide")
end)
buttonInstances["buffify"].MouseButton1Click:Connect(function()
    executeVictimCommand(";buffify")
end)
buttonInstances["tank"].MouseButton1Click:Connect(function()
    executeVictimCommand(";tank")
end)
buttonInstances["helicopter"].MouseButton1Click:Connect(function()
    executeVictimCommand(";helicopter")
end)
buttonInstances["plane"].MouseButton1Click:Connect(executePlane)
buttonInstances["car"].MouseButton1Click:Connect(function()
    executeVictimCommand(";car")
end)
buttonInstances["box"].MouseButton1Click:Connect(function()
    executeVictimCommand(";Box")
end)
buttonInstances["emote"].MouseButton1Click:Connect(function()
    executeVictimCommand(";emote")
end)
buttonInstances["phase"].MouseButton1Click:Connect(executePhase)

buttonInstances["smoke"].MouseButton1Click:Connect(function()
    executeVictimCommand(";smoke")
end)
buttonInstances["unsmoke"].MouseButton1Click:Connect(function()
    executeVictimCommand(";unsmoke")
end)
buttonInstances["fire"].MouseButton1Click:Connect(function()
    executeVictimCommand(";fire")
end)
buttonInstances["unfire"].MouseButton1Click:Connect(function()
    executeVictimCommand(";unfire")
end)
buttonInstances["shine"].MouseButton1Click:Connect(function()
    executeVictimCommand(";shine")
end)
buttonInstances["ghost"].MouseButton1Click:Connect(function()
    executeVictimCommand(";ghost")
end)

-- اورا تلقائي
if buttonInstances["autoAura"] then
    buttonInstances["autoAura"].MouseButton1Click:Connect(function()
        toggleAutoButton("autoAura", function()
            executeVictimCommand(";aura")
        end, 2)
    end)
end

-----------------[ نسخ + تايتل مدموج (1-20) ]-----------------

local copyTitleText = "اًلًجًرًاًرًهً اًلًعًفًوًيًهً"

local copyPatterns = {
    function(n,t) return ";dog "..n.." ;size "..n.." 3 ;neon "..n.." ;colour "..n.." Pink ;titlepk "..n.." "..t end, -- 1
    function(n,t) return ";worm "..n.." ;size "..n.." 3 ;neon "..n.." ;colour "..n.." Black ;titlepk "..n.." "..t end, -- 2
    function(n,t) return ";emote "..n.." ;size "..n.." 2 ;neon "..n.." ;colour "..n.." White ;titlepk "..n.." "..t end, -- 3
    function(n,t) return ";fat "..n.." ;neon "..n.." ;colour "..n.." Red ;fire "..n.." ;titlepk "..n.." "..t end, -- 4
    function(n,t) return ";thin "..n.." ;neon "..n.." ;colour "..n.." Blue ;smoke "..n.." ;titlepk "..n.." "..t end, -- 5
    function(n,t) return ";buffify "..n.." ;gold "..n.." ;colour "..n.." Yellow ;titlepk "..n.." "..t end, -- 6
    function(n,t) return ";dog "..n.." ;worm "..n.." ;neon "..n.." ;colour "..n.." Purple ;titlepk "..n.." "..t end, -- 7
    function(n,t) return ";hide "..n.." ;glass "..n.." ;shine "..n.." ;ghost "..n.." ;titlepk "..n.." "..t end, -- 8
    function(n,t) return ";tank "..n.." ;neon "..n.." ;colour "..n.." Green ;titlepk "..n.." "..t end, -- 9
    function(n,t) return ";car "..n.." ;neon "..n.." ;colour "..n.." Orange ;titlepk "..n.." "..t end, -- 10
    function(n,t) return ";plane "..n.." ;neon "..n.." ;colour "..n.." Blue ;titlepk "..n.." "..t end, -- 11
    function(n,t) return ";helicopter "..n.." ;neon "..n.." ;colour "..n.." Pink ;titlepk "..n.." "..t end, -- 12
    function(n,t) return ";phase "..n.." ;smoke "..n.." ;ghost "..n.." ;titlepk "..n.." "..t end, -- 13
    function(n,t) return ";fire "..n.." ;smoke "..n.." ;neon "..n.." ;colour "..n.." Red ;titlepk "..n.." "..t end, -- 14
    function(n,t) return ";fryDance "..n.." ;size "..n.." 2 ;neon "..n.." ;colour "..n.." Pink ;titlepk "..n.." "..t end, -- 15
    function(n,t) return ";takethel "..n.." ;size "..n.." 3 ;neon "..n.." ;colour "..n.." Purple ;titlepk "..n.." "..t end, -- 16
    function(n,t) return ";ratDance "..n.." ;fat "..n.." ;neon "..n.." ;colour "..n.." Yellow ;titlepk "..n.." "..t end, -- 17
    function(n,t) return ";cuteSit "..n.." ;size "..n.." 1 ;neon "..n.." ;colour "..n.." White ;titlepk "..n.." "..t end, -- 18
    function(n,t) return ";fakeDeath "..n.." ;ghost "..n.." ;shine "..n.." ;colour "..n.." Black ;titlepk "..n.." "..t end, -- 19
    function(n,t) return ";freakify "..n.." ;neon "..n.." ;colour "..n.." Pink ;titlepk "..n.." "..t end, -- 20
}

local function doCopyIndex(index)
    local victim = requireVictim()
    if not victim then return end
    local n = victim.Name
    local t = copyTitleText
    local pattern = copyPatterns[index]
    if pattern then
        executeCommand(pattern(n, t))
    end
end

-- أزرار النسخ 1-20
for i = 1, 20 do
    local btnName = "copy"..i
    if buttonInstances[btnName] then
        buttonInstances[btnName].MouseButton1Click:Connect(function()
            doCopyIndex(i)
        end)
    end
end

-- نسخ تلقائي 1-6 (تكرار نفس الأنماط)
buttonInstances["autoCopy1"].MouseButton1Click:Connect(function()
    toggleAutoButton("autoCopy1", function() doCopyIndex(1) end, 2)
end)
buttonInstances["autoCopy2"].MouseButton1Click:Connect(function()
    toggleAutoButton("autoCopy2", function() doCopyIndex(2) end, 2)
end)
buttonInstances["autoCopy3"].MouseButton1Click:Connect(function()
    toggleAutoButton("autoCopy3", function() doCopyIndex(3) end, 2)
end)
buttonInstances["autoCopy4"].MouseButton1Click:Connect(function()
    toggleAutoButton("autoCopy4", function() doCopyIndex(4) end, 2)
end)
buttonInstances["autoCopy5"].MouseButton1Click:Connect(function()
    toggleAutoButton("autoCopy5", function() doCopyIndex(5) end, 2)
end)
buttonInstances["autoCopy6"].MouseButton1Click:Connect(function()
    toggleAutoButton("autoCopy6", function() doCopyIndex(6) end, 2)
end)

-----------------[ كومبو اخفاء (سكن تخريب + شفاف + ref + حجم 3) ]-----------------

local function doHideComboSingle()
    local victim = requireVictim()
    if not victim then return end
    local n = victim.Name
    -- كل الأوامر في رسالة واحدة
    executeCommand(";char "..n.." crazydalejrd ;glass "..n.." ;ref "..n.." ;size "..n.." 3")
end

local function doHideComboMulti()
    local victim = requireVictim()
    if not victim then return end
    -- كل أمر لوحده
    executeCharSkin("crazydalejrd")
    executeVictimCommand(";glass")
    executeVictimCommand(";ref")
    executeSize(3)
end

if buttonInstances["hideCombo1"] then
    buttonInstances["hideCombo1"].MouseButton1Click:Connect(doHideComboSingle)
end

if buttonInstances["hideCombo2"] then
    buttonInstances["hideCombo2"].MouseButton1Click:Connect(doHideComboMulti)
end

if buttonInstances["autoHideCombo"] then
    buttonInstances["autoHideCombo"].MouseButton1Click:Connect(function()
        toggleAutoButton("autoHideCombo", doHideComboMulti, 2)
    end)
end

-- سبام
buttonInstances["spam1"].MouseButton1Click:Connect(sendSpam1)
buttonInstances["spam2"].MouseButton1Click:Connect(sendSpam2)
buttonInstances["spam3"].MouseButton1Click:Connect(sendSpam3)
buttonInstances["spam4"].MouseButton1Click:Connect(sendSpam4)
buttonInstances["spam5"].MouseButton1Click:Connect(sendSpam5)

buttonInstances["autoSpam1"].MouseButton1Click:Connect(function()
    toggleAutoSpam("autoSpam1", sendSpam1)
end)
buttonInstances["autoSpam2"].MouseButton1Click:Connect(function()
    toggleAutoSpam("autoSpam2", sendSpam2)
end)
buttonInstances["autoSpam3"].MouseButton1Click:Connect(function()
    toggleAutoSpam("autoSpam3", sendSpam3)
end)
buttonInstances["autoSpam4"].MouseButton1Click:Connect(function()
    toggleAutoSpam("autoSpam4", sendSpam4)
end)
buttonInstances["autoSpam5"].MouseButton1Click:Connect(function()
    toggleAutoSpam("autoSpam5", sendSpam5)
end)

-- حماية
buttonInstances["antiCopy"].MouseButton1Click:Connect(toggleAntiCopy)
buttonInstances["antiCopyNoMod"].MouseButton1Click:Connect(toggleAntiCopyNoMod)

-----------------[ زر فتح / إغلاق ]-----------------

ToggleButton.MouseButton1Click:Connect(function()
    local visible = not MainFrame.Visible
    MainFrame.Visible = visible
    if visible then
        MainFrame.Size = UDim2.new(0,0,0,0)
        MainFrame.Position = UDim2.new(0.5,0,0.5,0)
        TweenService:Create(MainFrame, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Size = UDim2.new(0,420,0,500),
            Position = UDim2.new(0.5,-210,0.5,-250)
        }):Play()
    end
end)

-----------------[ تنبيهات دخول/خروج الضحية ]-----------------

Players.PlayerRemoving:Connect(function(leavingPlayer)
    if currentVictimName and leavingPlayer.Name == currentVictimName then
        showNotification("🛑 الضحية "..leavingPlayer.Name.." خرجت من السيرفر")
    end
end)

Players.PlayerAdded:Connect(function(joiningPlayer)
    if currentVictimName and joiningPlayer.Name == currentVictimName then
        showNotification("✅ الضحية "..joiningPlayer.Name.." رجعت للسيرفر")
    end
end)

-----------------[ جاهز ]-----------------

showNotification("hello rakan")
