--ctrl + option + cmd + left:移动当前的焦点窗口到左半屏
--ctrl + option + cmd + right:移动当前的焦点窗口到右半屏

local module = {}

function module.moveToLeftHalf()
    local win = hs.window.focusedWindow()
    if win then
        local screen = win:screen()
        local frame = screen:frame()
        local winFrame = win:frame()

        local newFrame = frame
        newFrame.w = frame.w / 2

        if winFrame.w < frame.w / 2 then
            newFrame.w = winFrame.w
        end

        win:setFrame(newFrame)
    else
        hs.alert.show("No focused window found!")
    end
end

function module.moveToRightHalf()
    local win = hs.window.focusedWindow()
    if win then
        local screen = win:screen()
        local frame = screen:frame()
        local winFrame = win:frame()

        local newFrame = winFrame

        if winFrame.w < frame.w / 2 then
            -- 如果窗口宽度小于屏幕一半，则右边紧贴屏幕
            newFrame.x = frame.x + frame.w - winFrame.w
        else
            -- 否则将窗口移动到右半屏
            newFrame.x = frame.x + frame.w / 2
        end

        newFrame.y = frame.y
        newFrame.h = frame.h
        win:setFrame(newFrame)
    else
        hs.alert.show("No focused window found!")
    end
end

function module.start()
    local keys = require("modules.keys")
    -- 使用 Ctrl + Option + Cmd + Left/right 快捷键来放置窗口
    hs.hotkey.bind(keys.coc, "left", module.moveToLeftHalf)
    hs.hotkey.bind(keys.coc, "right", module.moveToRightHalf)
end

return module
