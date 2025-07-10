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
                hs.eventtap.keyStroke({"cmd"}, "v", 0)
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
