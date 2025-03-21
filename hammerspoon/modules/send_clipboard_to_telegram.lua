--ctrl + option + cmd + t:启动/关闭发送选中的文本至电报模式
--space:发送选中的文本至电报的某个chat

local module = {}

local isSendEnable = false
local currentHotkey = nil
local oneKeySendMenubar = nil

--获取要发送至的用户的名称
function module.getChatName()
    --注意:从HOME里面读取出来的路径后面没有/
    local configFile = os.getenv("HOME") .. "/.config/hammerspoon-modules/send_clipboard_to_telegram"
    local file, err = io.open(configFile, "r")
    if not file then
        hs.alert.show("无法读取配置文件:" .. err)
        return nil
    end

    local name = file:read("*line")
    file:close()

    if not name or name == "" then
        hs.alert.show("配置文件中没有有效的聊天对象名字")
        return nil
    end

    return name
end

function module.sendByBashScript(name)
    --auto copy
    --注意:不能在bash脚本里面通过osascript来模拟cmd+c,因为bash脚本是通过hammerspoon来调用的
    hs.eventtap.keyStroke({"cmd"}, "c")

    local function completionCallback(exitCode, stdOut, stdErr)
        hs.printf("Task completed with exit code: %s", exitCode or "nil")
        hs.printf("Full stdout:\n%s", stdOut)
        hs.printf("Full stderr:\n%s", stdErr)
    end

    local envs = require("modules.envs")
    local task = hs.task.new("/opt/homebrew/bin/bash", completionCallback,
        {
            "-c",
            "export PATH=/opt/homebrew/bin:$PATH; " ..
            envs.home .. "/repos/bash-tools/send_clipboard_to_telegram.sh " .. name
        }
    )

    task:setEnvironment({
        LANG = "en_US.UTF-8",
        LC_CTYPE = "UTF-8",
        LC_ALL = "en_US.UTF-8"
    })

    task:start()
end

function module.enableSend()
    hs.alert.show("发送至电报模式已启动")

    isSendEnable = true

    local name = module.getChatName()
    if not name then
        return
    end

    --就使用一个单独的空格键
    currentHotkey = hs.hotkey.bind({}, "space", function() module.sendByBashScript(name) end)

    if not oneKeySendMenubar then
        --创建状态栏对象
        oneKeySendMenubar = hs.menubar.new()
        oneKeySendMenubar:setTitle("SCT")
    end

    return true
end

function module.disableSend()
    isSendEnable = false

    if currentHotkey then
        currentHotkey:delete()
    end

    if oneKeySendMenubar then
        oneKeySendMenubar:delete()
        oneKeySendMenubar = nil
    end

    hs.alert.show("发送至电报模式已退出")
end

function module.toggleSend()
    if isSendEnable then
        module.disableSend()
    else
        local ret = module.enableSend()
        if not ret then
            module.disableSend()
        end
    end
end

--该函数只会在Hammerspoon启动时执行一次,而不会在每次切换模式时执行
function module.start()
    local keys = require("modules.keys")
    hs.hotkey.bind(keys.coc, "t", module.toggleSend)
end

return module
