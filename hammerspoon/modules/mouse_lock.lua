--ctrl + cmd + shift + m:锁定/解锁鼠标指针的位置

local module = {}

local isMouseLocked = false
local lockedPosition = nil
local lockTimer = nil

function module.toggleMouseLock()
    if isMouseLocked then
        isMouseLocked = false
        if lockTimer then
            lockTimer:stop()
            lockTimer = nil
        end
        hs.alert.show("解锁鼠标指针的位置")
    else
        lockedPosition = hs.mouse.getAbsolutePosition()
        isMouseLocked = true
        lockTimer = hs.timer.doWhile(
            function() return isMouseLocked end,
            --0.1:每100ms强制重置鼠标位置
            function() hs.mouse.setAbsolutePosition(lockedPosition) end, 0.1
        )
        hs.alert.show("锁定鼠标指针的位置")
    end
end

function module.start()
    hs.hotkey.bind({ "cmd", "shift", "ctrl" }, "m", module.toggleMouseLock)
end

return module
