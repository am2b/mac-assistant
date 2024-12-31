--ctrl + option + cmd + m:最大化当前的焦点窗口

local module = {}

--扩展窗口:左右到屏幕边缘,上下紧贴状态栏和程序坞
function module.expand()
    local win = hs.window.focusedWindow()
    if win then
        local screen = win:screen()
        local frame = screen:frame()

        -- 设置窗口的新位置和大小
        local newFrame = {
            x = frame.x,
            y = frame.y,
            w = frame.w,
            h = frame.h,
        }

        win:setFrame(newFrame)
    end
end

function module.start()
    local keys = require("modules.keys")
    hs.hotkey.bind(keys.coc, "m", module.expand)
end

return module
