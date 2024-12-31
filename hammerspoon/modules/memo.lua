--当"备忘录"是焦点的时候,自动绑定ESC->cmd + shift + e:高亮标记被选中的文本

local module = {}

local escBinding = nil
local memoWatcher = nil

function module.start()
    local function bindEsc()
        if escBinding == nil then
            --hs.alert.show("备忘录:绑定ESC -> cmd + shift + e")
            escBinding = hs.hotkey.bind({}, "escape", function()
                -- 高亮标记被选中的文本
                hs.eventtap.keyStroke({ "cmd", "shift" }, "e")
            end)
        end
    end

    local function unbindEsc()
        if escBinding ~= nil then
            --hs.alert.show("备忘录:解绑ESC")
            escBinding:delete()
            escBinding = nil
        end
    end

    --使用hs.window.filter API监控"备忘录"的窗口焦点变化事件,并在窗口聚焦和失焦时分别执行相应的函数
    --创建一个新的窗口过滤器实例memoWatcher,用来监控名字为"备忘录"的应用窗口
    memoWatcher = hs.window.filter.new("备忘录")
    --subscribe方法用于订阅特定的窗口事件,当监控的窗口发生这些事件时会触发指定的回调函数
    memoWatcher:subscribe(hs.window.filter.windowFocused, bindEsc)
    memoWatcher:subscribe(hs.window.filter.windowUnfocused, unbindEsc)
end

return module
