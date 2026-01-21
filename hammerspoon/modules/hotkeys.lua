--绑定同一个ctrl + option + cmd + hotkey到多个apps,然后在不同的app下执行不同的脚本

local module = {}

local hotkeys = {
    ["1"] = "1",
    ["2"] = "2",
    ["3"] = "3",
    --["a"] = "a",
    --["b"] = "b",
}

local function getFrontAppName()
    local frontApp = hs.application.frontmostApplication()
    local name = frontApp:name()
    --转小写并将空格替换为下划线
    name = string.lower(name):gsub("%s", "_")
    return name
end

local function hotKey(key)
    local appName = getFrontAppName()

    local envs = require("modules.envs")
    local task = hs.task.new("/opt/homebrew/bin/bash",
        function(exitCode, stdOut, stdErr)
            if exitCode == 0 then
                --hs.alert.show("脚本执行成功")
                --去除字符串首尾的空白字符
                --(.-):捕获一个尽可能短的子串(非贪婪匹配)
                local message = stdOut:gsub("^%s*(.-)%s*$", "%1")
                --hs.alert.show(result)
                if message == "cmd v" then
                    hs.eventtap.keyStroke({ "cmd" }, "v", 0)
                elseif message == "cmd v+enter" then
                    hs.eventtap.keyStroke({ "cmd" }, "v", 0)
                    hs.timer.doAfter(0.2, function()
                        hs.eventtap.keyStroke({}, "return", 0)
                    end)
                end
            else
                hs.alert.show("发生了错误")
            end
        end,
        {
            "-c",
            "export PATH=/opt/homebrew/bin:$PATH; " ..
            envs.home .. "/.config/hotkeys/hotkeys.sh " .. appName .. " " .. key
        })
    task:start()
end

function module.start()
    local keys = require("modules.keys")
    for k, v in pairs(hotkeys) do
        --hs.hotkey.bind(keys.coc, "1", function() hotKey("1") end)
        hs.hotkey.bind(keys.coc, k, function() hotKey(v) end)
    end
end

return module

--邮件助手的流程:
--mac-assistant/hammerspoon/modules/hotkeys.lua:响应ctrl+option+command+1/2/3按键后执行bash脚本:~/.config/hotkeys/hotkeys.sh
--该bash脚本根据传进来的app名字和按键进行路由调用:
--~/.config/hotkeys/sets/里面的可执行文件
--这些可执行文件:
--1:一个bash脚本,该脚本调用:~/.local/bin/python-tools/mail-helper copy-address来从~/.config/mail-helper/helper.toml里面拷贝地址
--2:一个bash脚本,该脚本调用:~/.local/bin/python-tools/mail-helper copy-lines来从~/.config/mail-helper/helper.toml里面找到书籍资源的地址,然后拷贝固定的行数
--3:这些1,2的bash脚本,以及3的go编译后的可执行文件,又会在最后给mac-assistant/hammerspoon/modules/hotkeys.lua发送一个消息,hotkeys.lua在收到消息后就会再模拟一个cmd+v的按键来把剪贴板上面的内容进行粘贴
