--刷新chatGPT的网页

local module = {}

-- 按键序列:全选->剪切->刷新网页
function module.reAsk()
    -- 执行 cmd + a (全选)
    hs.eventtap.keyStroke({ "cmd" }, "a")

    -- 等待 0.5 秒再执行下一个命令
    hs.timer.doAfter(0.5, function()
        -- 执行 cmd + x (剪切)
        hs.eventtap.keyStroke({ "cmd" }, "x")

        -- 再等待 0.5 秒
        hs.timer.doAfter(0.5, function()
            -- 执行 cmd + r (刷新网页)
            hs.eventtap.keyStroke({ "cmd" }, "r")
        end)
    end)
end

function module.start()
    local keys = require("modules.keys")
    hs.hotkey.bind(keys.coc, ";", module.reAsk)
end

return module
