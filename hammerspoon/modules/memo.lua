--当"备忘录"是焦点的时候,自动绑定ESC->cmd + shift + e:高亮标记被选中的文本

local module = {}

local escTap = nil
local memoWatcher = nil

local function bindEscEvent()
    if escTap == nil then
        escTap = hs.eventtap.new({ hs.eventtap.event.types.keyDown }, function(event)
            if hs.window.focusedWindow():application():name() ~= "备忘录" then return false end
            if event:getKeyCode() == hs.keycodes.map["escape"] then
                --高亮标记被选中的文本
                hs.eventtap.keyStroke({ "cmd", "shift" }, "e")
                return true
            end
            return false
        end)
        escTap:start()
        hs.printf("ESC 热键已绑定")
    end
end

local function unbindEscEvent()
    if escTap then
        escTap:stop()
        escTap = nil
        hs.printf("ESC 热键已解绑")
    end
end

function module.start()
    --使用hs.window.filter API监控"备忘录"的窗口焦点变化事件,并在窗口聚焦和失焦时分别执行相应的函数
    --创建一个新的窗口过滤器实例memoWatcher,用来监控名字为"备忘录"的应用窗口
    memoWatcher = hs.window.filter.new("备忘录")
    --subscribe方法用于订阅特定的窗口事件,当监控的窗口发生这些事件时会触发指定的回调函数
    memoWatcher:subscribe(hs.window.filter.windowFocused, function()
        --延迟一点确保窗口稳定
        hs.timer.doAfter(0.2, bindEscEvent)
    end)
    memoWatcher:subscribe(hs.window.filter.windowUnfocused, unbindEscEvent)
end

function module.stop()
    if memoWatcher then
        memoWatcher:unsubscribeAll()
        memoWatcher = nil
    end
    unbindEscEvent()
end

return module
