-- =================================================================
-- |         السكربت الشيطاني المحدّث (نسخة Manus V2)               |
-- =================================================================

-- تحميل مكتبة الواجهة الرسومية
local library = loadstring(game:HttpGet("https://raw.githubusercontent.com/wally-rblx/LinoriaLib/main/Library.lua" ))()

-- إنشاء نافذة جديدة
local window = library:CreateWindow({
    Title = "Manus's Psychological Warfare",
    Center = true,
    AutoShow = true,
})

-- إضافة قسم "الحرب النفسية"
local psychoTab = window:AddTab("الحرب النفسية")
local targetSection = psychoTab:AddLeftGroupbox("التحكم بالهدف")

-- صندوق إدخال اسم اللاعب
local targetPlayerName = targetSection:AddTextbox("اسم الضحية", {
    Default = "",
    TextDisappear = true,
})

-- وظيفة إرسال الأوامر إلى الشات
local function runCommand(command)
    game:GetService("ReplicatedStorage").DefaultChatSystemChatEvents.SayMessageRequest:FireServer(command, "All")
end

-- متغير لتفعيل/إيقاف الوظائف المستمرة
local isLooping = {}

-- =================================================================
-- |                     الأزرار الشيطانية الجديدة                   |
-- =================================================================

-- 1. زر "جحيم الجاذبية"
targetSection:AddButton("تفعيل/إيقاف جحيم الجاذبية", function()
    local playerName = targetPlayerName.Value
    if not playerName or playerName == "" then
        library:Notify("اختر ضحية أولاً!", 3)
        return
    end

    isLooping[playerName .. "_gravity"] = not isLooping[playerName .. "_gravity"]

    if isLooping[playerName .. "_gravity"] then
        library:Notify("تم تفعيل جحيم الجاذبية على " .. playerName, 5)
        task.spawn(function()
            while isLooping[playerName .. "_gravity"] do
                runCommand(";jumpHeight " .. playerName .. " 150") -- قفزة عالية جدًا
                wait(2)
                if not isLooping[playerName .. "_gravity"] then break end
                runCommand(";heavyJump " .. playerName) -- هبوط ثقيل جدًا
                wait(2)
            end
        end)
    else
        library:Notify("تم إيقاف جحيم الجاذبية عن " .. playerName, 5)
        runCommand(";jumpHeight " .. playerName .. " 50") -- إعادة القفز للوضع الطبيعي
    end
end)

-- 2. زر "الظل المزعج"
targetSection:AddButton("تفعيل/إيقاف الظل المزعج", function()
    local playerName = targetPlayerName.Value
    if not playerName or playerName == "" then
        library:Notify("اختر ضحية أولاً!", 3)
        return
    end

    isLooping[playerName .. "_shadow"] = not isLooping[playerName .. "_shadow"]

    if isLooping[playerName .. "_shadow"] then
        library:Notify(playerName .. " أصبح ظلك الآن", 5)
        runCommand(";char " .. playerName .. " me") -- جعله نسخة منك
        runCommand(";follow " .. playerName .. " me") -- جعله يتبعك
        task.spawn(function()
            while isLooping[playerName .. "_shadow"] do
                runCommand(";title " .. playerName .. " 'أنا مجرد ظل'")
                wait(2)
            end
        end)
    else
        library:Notify("تم تحرير " .. playerName .. " من كونه ظلك", 5)
        runCommand(";unfollow " .. playerName) -- (نفترض وجود أمر ;unfollow)
        runCommand(";char " .. playerName .. " " .. playerName) -- إعادته لشكله
        runCommand(";title " .. playerName .. " ''") -- إزالة العنوان
    end
end)

-- 3. زر "حرب الإشعارات"
targetSection:AddButton("تفعيل/إيقاف حرب الإشعارات", function()
    local playerName = targetPlayerName.Value
    if not playerName or playerName == "" then
        library:Notify("اختر ضحية أولاً!", 3)
        return
    end

    isLooping[playerName .. "_notifs"] = not isLooping[playerName .. "_notifs"]

    if isLooping[playerName .. "_notifs"] then
        library:Notify("بدء قصف " .. playerName .. " بالإشعارات!", 5)
        task.spawn(function()
            local messages = {"!!!", "HACKED", "LOOK BEHIND YOU", "...", "ERROR 404"}
            local colors = {";hr ", ";ho ", ";hy ", ";hg ", ";hb "}
            while isLooping[playerName .. "_notifs"] do
                local randomMsg = messages[math.random(#messages)]
                local randomColorCmd = colors[math.random(#colors)]
                runCommand(randomColorCmd .. "'" .. randomMsg .. "'") -- إرسال رسالة ملونة للجميع
                runCommand(";title" .. "r " .. playerName .. " '" .. randomMsg .. "'") -- إرسال عنوان أحمر للاعب
                wait(0.5)
            end
        end)
    else
        library:Notify("تم إيقاف حرب الإشعارات.", 5)
    end
end)
