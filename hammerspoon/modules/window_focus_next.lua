--当当前焦点窗口被关闭或被最小化后,让后面的窗口自动成为焦点窗口

local module = {}

--焦点切换函数
function module.focusNextAvailableWindow()
    hs.timer.doAfter(0.2, function()
        --获取所有按叠放顺序排列的窗口
        local visibleWindows = hs.window.orderedWindows()
        --遍历窗口,找到第一个可见的窗口并将其聚焦
        for _, win in ipairs(visibleWindows) do
            if win:isStandard() and not win:isMinimized() then
                win:focus()
                --hs.alert.show("Focus switched to " .. win:application():name())
                return
            end
        end
    end)
end

--监听窗口最小化和关闭事件
function module.start()
    --设置窗口过滤器监听最小化和关闭事件
    local filter = hs.window.filter.new():setDefaultFilter()
    filter:subscribe({
      --窗口最小化事件
        hs.window.filter.windowMinimized,
      --窗口关闭事件
        hs.window.filter.windowDestroyed
    }, function()
        module.focusNextAvailableWindow()
    end)
end

return module
