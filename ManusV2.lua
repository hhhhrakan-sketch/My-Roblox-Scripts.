-- LIWA Prompt (Right side, aim, dual boxes, title split, view + unview buttons + inline player info)

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")
local UIS = game:GetService("UserInputService")

local LP = Players.LocalPlayer
local PlayerGui = LP:WaitForChild("PlayerGui")
local Mouse = LP:GetMouse()

-- ========== شات ==========
local function sendChat(msg: string)
	msg = tostring(msg or ""):gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")
	if msg == "" then return end
	pcall(function()
		if TextChatService and TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
			local ch = TextChatService.TextChannels and TextChatService.TextChannels.RBXGeneral
			if ch then ch:SendAsync(msg) end
		end
	end)
	local events = RS:FindFirstChild("DefaultChatSystemChatEvents")
	if events then
		local say = events:FindFirstChild("SayMessageRequest")
		if say and say:IsA("RemoteEvent") then
			say:FireServer(msg, "All")
		end
	end
end

-- ========== مساعدات ==========
local function normTarget(t: string): string
	t = tostring(t or ""):gsub("%s+", "")
	return (t:sub(1,3)):lower()
end

local function splitFirstWord(s: string)
	local sp = s:find("%s")
	if sp then return s:sub(1, sp-1), s:sub(sp+1) else return s, "" end
end

local function quoteIfNeeded(text: string): string
	local t = (text or ""):gsub("^%s+",""):gsub("%s+$","")
	if t == "" then return "" end
	if t:match('^".*"$') then return t end
	return '"'..t..'"'
end

-- يحول سلسلة أوامر مثل ";size 3 ;neon ;paint pink ;titlepk {p} نص"
-- إلى سلسلة فيها حقن الهدف/استبدال {p}، وعلاج titlepk.
local function processAuto(raw: string, first3: string): string
	if not raw or raw == "" then return "" end
	raw = raw:gsub("\r\n"," "):gsub("\n"," "):gsub("\t"," ")
	raw = raw:gsub("%s+"," "):gsub("^%s+",""):gsub("%s+$","")
	if raw == "" then return "" end
	if not raw:find(";") then raw = ";"..raw end

	local out = {}
	local esc = first3:gsub("(%W)","%%%1")

	for seg in raw:gmatch(";[^;]+") do
		local body = seg:sub(2):gsub("^%s+",""):gsub("%s+$","")
		if body ~= "" then
			local cmd, rest = splitFirstWord(body)
			local lc = (cmd or ""):lower()

			-- 1) استبدال {p}
			if rest:find("{p}") then
				rest = rest:gsub("{p}", first3)
			else
				-- 2) حقن الهدف بعد اسم الأمر إن لم يكن أول كلمة
				if not rest:match("^%s*"..esc.."(%s+.*|$)") then
					rest = (rest == "" and first3) or (first3.." "..rest)
				end
			end

			-- 3) title/titlep/titlepk: اقتباس النص بعد الهدف
			if lc == "titlepk" or lc == "titlep" or lc == "title" then
				local pWord, tail = splitFirstWord(rest)
				if pWord and pWord:lower() ~= first3 then
					tail = (pWord and (pWord.." "..(tail or "")) or (tail or ""))
					pWord = first3
				end
				if tail ~= "" then
					rest = pWord.." "..quoteIfNeeded(tail)
				else
					rest = pWord
				end
			end

			table.insert(out, ";"..cmd.." "..rest)
		end
	end
	return table.concat(out, " ")
end

-- ========== UI أساسيات ==========
local function addCorner(instance, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or 6)
	c.Parent = instance
end

local function addStroke(instance, thickness, color)
	local s = Instance.new("UIStroke")
	s.Thickness = thickness or 1
	s.Color = color or Color3.fromRGB(0,0,0)
	s.Transparency = 0.3
	s.Parent = instance
end

local gui = Instance.new("ScreenGui")
gui.Name = "LIWAPrompt"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.Parent = PlayerGui

-- زر إظهار/إخفاء (تحت يسار)
local toggle = Instance.new("TextButton")
toggle.Name = "Toggle"
toggle.Size = UDim2.fromOffset(58, 26)
toggle.Position = UDim2.new(0, 12, 1, -40)
toggle.AnchorPoint = Vector2.new(0, 1)
toggle.Text = "LIWA"
toggle.BackgroundColor3 = Color3.fromRGB(35,45,65)
toggle.TextColor3 = Color3.fromRGB(240,240,240)
toggle.Font = Enum.Font.GothamBold
toggle.TextSize = 12
toggle.Parent = gui
addCorner(toggle, 6)
addStroke(toggle, 1.2, Color3.fromRGB(0,0,0))

-- الإطار الرئيسي (يمين فوق)
local main = Instance.new("Frame")
main.Name = "Main"
main.Size = UDim2.fromOffset(360, 300)
main.Position = UDim2.new(1, -372, 0, 12)
main.AnchorPoint = Vector2.new(1, 0)
main.BackgroundColor3 = Color3.fromRGB(24,28,40)
main.BorderSizePixel = 0
main.Parent = gui
addCorner(main, 8)
addStroke(main, 1.5, Color3.fromRGB(0,0,0))

local header = Instance.new("TextLabel")
header.Size = UDim2.new(1,0,0,26)
header.BackgroundColor3 = Color3.fromRGB(30,36,54)
header.TextColor3 = Color3.fromRGB(250,250,250)
header.Font = Enum.Font.GothamBold
header.TextSize = 14
header.Text = "LIWA Prompt"
header.Parent = main
addCorner(header, 8)

-- سحب النافذة من الهيدر
local dragging = false
local dragStart
local startPos

header.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos = main.Position
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
			end
		end)
	end
end)

UIS.InputChanged:Connect(function(input)
	if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		local delta = input.Position - dragStart
		main.Position = UDim2.new(
			startPos.X.Scale,
			startPos.X.Offset + delta.X,
			startPos.Y.Scale,
			startPos.Y.Offset + delta.Y
		)
	end
end)

-- الهدف
local targetBox = Instance.new("TextBox")
targetBox.Size = UDim2.new(0, 120, 0, 28)
targetBox.Position = UDim2.new(0, 10, 0, 34)
targetBox.PlaceholderText = "أول 3 حروف (mis)"
targetBox.BackgroundColor3 = Color3.fromRGB(34,40,60)
targetBox.TextColor3 = Color3.fromRGB(240,240,240)
targetBox.ClearTextOnFocus = false
targetBox.Font = Enum.Font.Gotham
targetBox.TextSize = 13
targetBox.Parent = main
addCorner(targetBox, 6)
addStroke(targetBox, 1, Color3.fromRGB(0,0,0))

-- زر العين (VIEW)
local viewBtn = Instance.new("TextButton")
viewBtn.Name = "ViewButton"
viewBtn.Size = UDim2.fromOffset(32, 28)
viewBtn.Position = UDim2.new(0, 140, 0, 34)
viewBtn.BackgroundColor3 = Color3.fromRGB(45,52,78)
viewBtn.TextColor3 = Color3.fromRGB(255,255,255)
viewBtn.Font = Enum.Font.GothamBold
viewBtn.TextSize = 16
viewBtn.Text = "👁"
viewBtn.Parent = main
addCorner(viewBtn, 6)
addStroke(viewBtn, 1, Color3.fromRGB(0,0,0))

-- زر العين + X (UNVIEW)
local unviewBtn = Instance.new("TextButton")
unviewBtn.Name = "UnviewButton"
unviewBtn.Size = UDim2.fromOffset(32, 28)
unviewBtn.Position = UDim2.new(0, 140, 0, 66) -- تحت زر الفيو
unviewBtn.BackgroundColor3 = Color3.fromRGB(90, 45, 60)
unviewBtn.TextColor3 = Color3.fromRGB(255,255,255)
unviewBtn.Font = Enum.Font.GothamBold
unviewBtn.TextSize = 14
unviewBtn.Text = "👁✕"
unviewBtn.Parent = main
addCorner(unviewBtn, 6)
addStroke(unviewBtn, 1, Color3.fromRGB(0,0,0))

local viewState = false        -- هل حالياً عامل view؟
local viewTarget: string? = nil

local function updateViewVisual()
	if viewState then
		viewBtn.BackgroundColor3 = Color3.fromRGB(60,140,90)
		viewBtn.Text = "👁‍🗨"
	else
		viewBtn.BackgroundColor3 = Color3.fromRGB(45,52,78)
		viewBtn.Text = "👁"
	end
end

-- ========== كرت معلومات اللاعب (مضمن في الواجهة) ==========
local infoInline = Instance.new("Frame")
infoInline.Name = "TargetInfoInline"
infoInline.Position = UDim2.new(0, 182, 0, 34)        -- جنب زر العين
infoInline.Size = UDim2.new(1, -192, 0, 28)
infoInline.BackgroundTransparency = 1
infoInline.Parent = main

local avatarInline = Instance.new("ImageLabel")
avatarInline.Size = UDim2.fromOffset(24, 24)
avatarInline.Position = UDim2.new(0, 0, 0.5, -12)
avatarInline.BackgroundColor3 = Color3.fromRGB(30,30,40)
avatarInline.BorderSizePixel = 0
avatarInline.Parent = infoInline
addCorner(avatarInline, 999)

local infoText = Instance.new("TextLabel")
infoText.Size = UDim2.new(1, -30, 1, 0)
infoText.Position = UDim2.new(0, 30, 0, 0)
infoText.BackgroundTransparency = 1
infoText.Font = Enum.Font.Gotham
infoText.TextSize = 11
infoText.TextXAlignment = Enum.TextXAlignment.Left
infoText.TextYAlignment = Enum.TextYAlignment.Center
infoText.TextWrapped = true
infoText.TextColor3 = Color3.fromRGB(210, 210, 230)
infoText.Text = "لا يوجد هدف محدد"
infoText.Parent = infoInline

local currentTargetPlayer: Player? = nil

local function showPlayerInfo(plr: Player)
	currentTargetPlayer = plr

	local displayName = (plr.DisplayName ~= "" and plr.DisplayName) or plr.Name
	infoText.Text = string.format("%s\n@%s | ID:%d", displayName, plr.Name, plr.UserId)

	local success, thumb = pcall(function()
		return Players:GetUserThumbnailAsync(plr.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
	end)
	if success then
		avatarInline.Image = thumb
	else
		avatarInline.Image = ""
	end
end

Players.PlayerRemoving:Connect(function(plr)
	if currentTargetPlayer == plr then
		currentTargetPlayer = nil
		avatarInline.Image = ""
		infoText.Text = "اللاعب خرج من السيرفر"
	end
end)

-- ====== صندوق الأوامر 1 ======
local autoLbl1 = Instance.new("TextLabel")
autoLbl1.Size = UDim2.new(1, -20, 0, 16)
autoLbl1.Position = UDim2.new(0, 10, 0, 66)
autoLbl1.BackgroundTransparency = 1
autoLbl1.TextColor3 = Color3.fromRGB(200,210,255)
autoLbl1.TextXAlignment = Enum.TextXAlignment.Left
autoLbl1.Font = Enum.Font.GothamSemibold
autoLbl1.TextSize = 12
autoLbl1.Text = "أوامر 1 (تلقائي مع استهداف):"
autoLbl1.Parent = main

local autoBox1 = Instance.new("TextBox")
autoBox1.Size = UDim2.new(1, -20, 0, 52)
autoBox1.Position = UDim2.new(0, 10, 0, 84)
autoBox1.MultiLine = true
autoBox1.TextWrapped = true
autoBox1.TextXAlignment = Enum.TextXAlignment.Left
autoBox1.TextYAlignment = Enum.TextYAlignment.Top
autoBox1.BackgroundColor3 = Color3.fromRGB(34,40,60)
autoBox1.TextColor3 = Color3.fromRGB(240,240,240)
autoBox1.ClearTextOnFocus = false
autoBox1.Font = Enum.Font.Code
autoBox1.TextSize = 12
autoBox1.Text = ";paint pink ;titlepk اًلًجًرًاًرًهً اًلًعًفًوًيًهً"
autoBox1.Parent = main
addCorner(autoBox1, 6)
addStroke(autoBox1, 1, Color3.fromRGB(0,0,0))

local autoSend1 = Instance.new("TextButton")
autoSend1.Size = UDim2.new(0, 94, 0, 26)
autoSend1.Position = UDim2.new(1, -104, 0, 140)
autoSend1.Text = "إرسال 1"
autoSend1.BackgroundColor3 = Color3.fromRGB(60,90,160)
autoSend1.TextColor3 = Color3.fromRGB(255,255,255)
autoSend1.Font = Enum.Font.GothamBold
autoSend1.TextSize = 13
autoSend1.Parent = main
addCorner(autoSend1, 6)
addStroke(autoSend1, 1, Color3.fromRGB(0,0,0))

-- ====== زر "إرسال الكل" ======
local sendAll = Instance.new("TextButton")
sendAll.Size = UDim2.new(0, 110, 0, 26)
sendAll.Position = UDim2.new(0.5, -55, 0, 212)
sendAll.Text = "إرسال الكل"
sendAll.BackgroundColor3 = Color3.fromRGB(90, 90, 110)
sendAll.TextColor3 = Color3.fromRGB(255,255,255)
sendAll.Font = Enum.Font.GothamBold
sendAll.TextSize = 13
sendAll.Parent = main
addCorner(sendAll, 6)
addStroke(sendAll, 1, Color3.fromRGB(0,0,0))

-- ====== صندوق الأوامر 2 ======
local autoLbl2 = Instance.new("TextLabel")
autoLbl2.Size = UDim2.new(1, -20, 0, 16)
autoLbl2.Position = UDim2.new(0, 10, 0, 170)
autoLbl2.BackgroundTransparency = 1
autoLbl2.TextColor3 = Color3.fromRGB(200,210,255)
autoLbl2.TextXAlignment = Enum.TextXAlignment.Left
autoLbl2.Font = Enum.Font.GothamSemibold
autoLbl2.TextSize = 12
autoLbl2.Text = "أوامر 2 (تلقائي مع استهداف):"
autoLbl2.Parent = main

local autoBox2 = Instance.new("TextBox")
autoBox2.Size = UDim2.new(1, -20, 0, 52)
autoBox2.Position = UDim2.new(0, 10, 0, 188)
autoBox2.MultiLine = true
autoBox2.TextWrapped = true
autoBox2.TextXAlignment = Enum.TextXAlignment.Left
autoBox2.TextYAlignment = Enum.TextYAlignment.Top
autoBox2.BackgroundColor3 = Color3.fromRGB(34,40,60)
autoBox2.TextColor3 = Color3.fromRGB(240,240,240)
autoBox2.ClearTextOnFocus = false
autoBox2.Font = Enum.Font.Code
autoBox2.TextSize = 12
autoBox2.Text = ";chibify ;aura ;neon ;height 0 ;color ;hotdance 3"
autoBox2.Parent = main
addCorner(autoBox2, 6)
addStroke(autoBox2, 1, Color3.fromRGB(0,0,0))

local autoSend2 = Instance.new("TextButton")
autoSend2.Size = UDim2.new(0, 94, 0, 26)
autoSend2.Position = UDim2.new(1, -104, 0, 244)
autoSend2.Text = "إرسال 2"
autoSend2.BackgroundColor3 = Color3.fromRGB(80,120,90)
autoSend2.TextColor3 = Color3.fromRGB(255,255,255)
autoSend2.Font = Enum.Font.GothamBold
autoSend2.TextSize = 13
autoSend2.Parent = main
addCorner(autoSend2, 6)
addStroke(autoSend2, 1, Color3.fromRGB(0,0,0))

-- تحذير
local warnLbl = Instance.new("TextLabel")
warnLbl.Size = UDim2.new(1, -20, 0, 18)
warnLbl.Position = UDim2.new(0, 10, 1, -20)
warnLbl.BackgroundTransparency = 1
warnLbl.TextColor3 = Color3.fromRGB(255,200,120)
warnLbl.Font = Enum.Font.Gotham
warnLbl.TextSize = 11
warnLbl.Text = ""
warnLbl.TextWrapped = true
warnLbl.Parent = main

-- إظهار/إخفاء
local visible = true
toggle.MouseButton1Click:Connect(function()
	visible = not visible
	main.Visible = visible
end)

-- ========== زر الاستهداف (ثابت تحت يمين) ==========
local aimBtn = Instance.new("TextButton")
aimBtn.Name = "AimButton"
aimBtn.Size = UDim2.fromOffset(90, 34)
aimBtn.Position = UDim2.new(1, -102, 1, -46)
aimBtn.AnchorPoint = Vector2.new(1, 1)
aimBtn.Text = "استهداف"
aimBtn.BackgroundColor3 = Color3.fromRGB(35,35,35)
aimBtn.TextColor3 = Color3.fromRGB(240,240,240)
aimBtn.AutoButtonColor = true
aimBtn.Font = Enum.Font.GothamBold
aimBtn.TextSize = 13
aimBtn.Parent = gui
addCorner(aimBtn, 8)
addStroke(aimBtn, 1.2, Color3.fromRGB(0,0,0))

local aimHint = Instance.new("TextLabel")
aimHint.Size = UDim2.fromOffset(140, 22)
aimHint.Position = UDim2.new(0.5, -70, 1, -130)
aimHint.AnchorPoint = Vector2.new(0.5, 1)
aimHint.BackgroundColor3 = Color3.fromRGB(0,0,0)
aimHint.BackgroundTransparency = 0.35
aimHint.TextColor3 = Color3.fromRGB(255,255,255)
aimHint.Font = Enum.Font.GothamBold
aimHint.TextSize = 12
aimHint.Text = ""
aimHint.TextScaled = false
aimHint.Visible = false
aimHint.Parent = gui
addCorner(aimHint, 6)

-- ========== استهداف بالضغط ==========
local selecting = false
local clickConn: RBXScriptConnection? = nil

local function stopSelecting(msg)
	selecting = false
	aimHint.Visible = false
	if clickConn then clickConn:Disconnect() clickConn = nil end
	if msg then warnLbl.Text = msg end
end

local function findPlayerFromTarget(inst: Instance)
	if not inst then return nil end
	local node = inst
	for _ = 1, 8 do
		if not node then break end
		if node:IsA("Model") and node:FindFirstChildOfClass("Humanoid") then
			return Players:GetPlayerFromCharacter(node)
		end
		node = node.Parent
	end
	return nil
end

aimBtn.MouseButton1Click:Connect(function()
	if selecting then
		stopSelecting()
		return
	end
	selecting = true
	aimHint.Text = "اختر لاعب"
	aimHint.Visible = true
	warnLbl.Text = ""
	clickConn = Mouse.Button1Down:Connect(function()
		local plr = findPlayerFromTarget(Mouse.Target)
		if plr then
			targetBox.Text = normTarget(plr.Name)
			showPlayerInfo(plr)
			stopSelecting("✅ تم التقاط الهدف: "..targetBox.Text)
		else
			stopSelecting("⚠ اضغط على لاعب.")
		end
	end)
end)

-- لو كتب أول 3 حروف وضغط Enter
targetBox.FocusLost:Connect(function(enterPressed)
	if not enterPressed then return end
	local t = normTarget(targetBox.Text)
	if t == "" then return end
	for _,plr in ipairs(Players:GetPlayers()) do
		if plr.Name:sub(1, #t):lower() == t then
			showPlayerInfo(plr)
			warnLbl.Text = "✅ تم تعيين الهدف: "..t
			return
		end
	end
	avatarInline.Image = ""
	infoText.Text = "⚠ ما لقيت لاعب بهالحروف."
end)

-- إذا تغيّر الهدف، وفينا view شغال، نسوي unview تلقائي
targetBox:GetPropertyChangedSignal("Text"):Connect(function()
	local t = normTarget(targetBox.Text)
	if (t == "" or t ~= viewTarget) and viewState and viewTarget then
		sendChat("/e ;unview "..viewTarget)
		viewState = false
		viewTarget = nil
		updateViewVisual()
	end
end)

-- ========== إرسال الأوامر (مع فصل أوامر الـ title) ==========

local function buildProcessedFromBox(box: TextBox)
	local target = normTarget(targetBox.Text)
	if target == "" then
		return nil, "⚠ اكتب أول 3 حروف من الهدف."
	end

	local processed = processAuto(box.Text, target)
	if processed == "" then
		return nil, "⚠ لا يوجد أوامر."
	end

	return processed, nil
end

local function sendProcessedWithTitleSplit(processed: string)
	if not processed or processed == "" then return end

	local normalSegs = {}
	local titleSegs = {}

	for seg in processed:gmatch(";[^;]+") do
		local body = seg:sub(2):gsub("^%s+",""):gsub("%s+$","")
		if body ~= "" then
			local cmd, rest = splitFirstWord(body)
			local lc = (cmd or ""):lower()

			if lc == "title" or lc == "titlep" or lc == "titlepk" then
				table.insert(titleSegs, ";"..body)
			else
				table.insert(normalSegs, ";"..body)
			end
		end
	end

	local function sendGroup(segs)
		if #segs == 0 then return end
		local msg = "/e "..table.concat(segs, " ")
		if #msg > 200 then
			warnLbl.Text = ("⚠ طول الرسالة %d (حد ~200) - قلل الأوامر أو قلل نص التايتل."):format(#msg)
		end
		sendChat(msg)
	end

	-- أولاً الأوامر العادية
	sendGroup(normalSegs)

	-- ثم أوامر التايتل لوحدها
	if #titleSegs > 0 then
		task.wait(0.2)
		sendGroup(titleSegs)
	end
end

local function doSendFromBox(box: TextBox)
	warnLbl.Text = ""
	local processed, err = buildProcessedFromBox(box)
	if not processed then
		warnLbl.Text = err or "⚠ خطأ غير معروف."
		return
	end

	sendProcessedWithTitleSplit(processed)
end

autoSend1.MouseButton1Click:Connect(function()
	doSendFromBox(autoBox1)
end)

autoSend2.MouseButton1Click:Connect(function()
	doSendFromBox(autoBox2)
end)

sendAll.MouseButton1Click:Connect(function()
	warnLbl.Text = ""

	local processed2, err2 = buildProcessedFromBox(autoBox2)
	if not processed2 then
		warnLbl.Text = err2 or "⚠ لا يوجد أوامر في 2."
		return
	end
	sendProcessedWithTitleSplit(processed2)

	task.wait(0.25)

	local processed1, err1 = buildProcessedFromBox(autoBox1)
	if processed1 then
		sendProcessedWithTitleSplit(processed1)
	end
end)

-- ========== زر VIEW ==========
viewBtn.MouseButton1Click:Connect(function()
	local target = normTarget(targetBox.Text)
	if target == "" then
		warnLbl.Text = "⚠ حدد هدف أولاً (أول 3 حروف)."
		return
	end

	-- لو فيه هدف قديم مختلف عليه view نفكه عنه أول
	if viewState and viewTarget and viewTarget ~= target then
		sendChat("/e ;unview "..viewTarget)
	end

	sendChat("/e ;view "..target)
	viewState = true
	viewTarget = target
	updateViewVisual()
	warnLbl.Text = "👁 تم view على: "..target
end)

-- ========== زر UNVIEW ==========
unviewBtn.MouseButton1Click:Connect(function()
	-- لو فيه هدف محفوظ من قبل نستخدمه، غير كذا نستخدم اللي مكتوب
	local target = viewTarget or normTarget(targetBox.Text)

	if not target or target == "" then
		warnLbl.Text = "⚠ ما فيه هدف لفك الـ view."
		return
	end

	sendChat("/e ;unview "..target)
	viewState = false
	viewTarget = nil
	updateViewVisual()
	warnLbl.Text = "🚫 تم unview عن: "..target
end)

updateViewVisual()
