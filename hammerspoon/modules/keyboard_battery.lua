--监控Magic Keyboard的电量,当电量低于25%的时候,自动发送邮件

local module = {}

local warningPower = 25
-- 每3小时最多检查一次
local limitTime = 3600 * 3
-- 上次调用的时间戳
local lastCheckTime = 0

-- 获取键盘电量的函数
local function getKeyboardBatteryLevel()
    --ioreg是macOS的I/ORegistry工具,可以列出系统硬件信息
    ---c AppleDeviceManagementHIDEventService选项用于过滤出属于AppleDeviceManagementHIDEventService类的设备,该类通常包含蓝牙外设(例如Magic Keyboard)的信息
    ---r 选项显示设备树的根节点
    ---l 选项以详细格式显示每个设备的属性信息
    ---A 20 会显示匹配行之后的20行内容,以确保我们能获取该设备的其他属性,例如电量信息
    local shellCommand =
    [[ioreg -c AppleDeviceManagementHIDEventService -r -l | grep -i '"Product" = "Magic Keyboard"' -A 20 | grep -i '"BatteryPercent" =' | awk '{print $3}']]
    local batteryLevel = hs.execute(shellCommand)
    return tonumber(batteryLevel)
end

-- 检查电量并发送通知的函数
function module.checkKeyboardBattery()
    local currentTime = os.time()
    if (currentTime - lastCheckTime) < limitTime then
        --hs.notify.new({ title = "频繁检查 Magic Keyboard 电量", informativeText = "每" .. (limitTime / 3600) .. "小时只能检查一次" }):send()
        return
    end
    -- 更新调用时间
    lastCheckTime = currentTime

    local batteryLevel = getKeyboardBatteryLevel()
    if batteryLevel and batteryLevel < warningPower then
        local env = require("modules.envs")
        local recipient = env.icloud
        local subject = "Magic Keyboard 低电量警告"
        local body = "Magic Keyboard 的电量已经低于" .. warningPower .. "%了"

        --发送桌面通知
        hs.notify.new({
            title = subject,
            informativeText = body
        }):send()

        --发送邮件
        local send_mail = require("modules.send_mail")
        send_mail.sendByClient(recipient, subject, body)
    end
end

-- 启动模块
function module.start()
    -- 唤醒的时候检查一次
    module.wakeupWatcher = hs.caffeinate.watcher.new(function(eventType)
        if eventType == hs.caffeinate.watcher.systemDidWake then
            module.checkKeyboardBattery()
        end
    end)
    module.wakeupWatcher:start()

    -- 每隔5小时检查一次
    -- module.batteryTimer在这里是有用的,因为它确保了定时器对象在模块中始终存在,没有这个引用的话,定时器可能会在创建后被垃圾回收机制清理掉
    -- 在lua中,当一个对象没有任何引用时,垃圾回收机制会自动清除它,如果我们没有在模块中保存hs.timer.doEvery返回的定时器对象,定时器可能会因为没有引用而被清除
    module.batteryTimer = hs.timer.doEvery(3600 * 5, module.checkKeyboardBattery)

    -- 重启mac的时候,或重新reload配置文件的时候检查一次
    module.checkKeyboardBattery()
end

return module
