--ctro + option + cmd + r:重新载入Hammerspoon的配置文件

local module = {}

function module.start()
    local keys = require("modules.keys")
    -- 使用ctrl + option + cmd + r快捷键来重新加载hammerspoon配置
    hs.hotkey.bind(keys.coc, "r", hs.reload)
    hs.alert.show("Hammerspoon已重新加载配置文件")
end

return module
