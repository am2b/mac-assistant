--检测到ctrl + option + cmd + h后,开启/关闭对"全局变量:GLOBAL_FLAG"的检测

local M = {}

local isEnable = false

function M.enable()
    isEnable = true

    hs.alert.show("enable")
    hs.alert.show(GLOBAL_FLAG)
end

function M.disable()
    isEnable = false

    hs.alert.show("disable")
    GLOBAL_FLAG = "init"
end

function M.switch()
    if isEnable then
        M.disable()
    else
        M.enable()
    end
end

function M.start()
    local keys = require("modules.keys")
    hs.hotkey.bind(keys.coc, "h", M.switch)
end

return M
