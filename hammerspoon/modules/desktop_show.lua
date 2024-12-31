--ctrl + option + cmd + d:显示桌面

local module = {}

function module.hide()
    --隐藏其它App
    hs.eventtap.keyStroke({ "cmd", "option" }, "h")

    --隐藏焦点App
    local frontApp = hs.application.frontmostApplication()
    if frontApp then
        local windows = frontApp:allWindows()
        for _, window in ipairs(windows) do
            window:minimize()
        end
    end

    --隐藏访达App
    local finder = hs.application.get("访达")
    if finder then
        local windows = finder:allWindows()
        for _, window in ipairs(windows) do
            window:minimize()
        end
    end
end

function module.start()
    local keys = require("modules.keys")
    hs.hotkey.bind(keys.coc, "d", module.hide)
end

return module
