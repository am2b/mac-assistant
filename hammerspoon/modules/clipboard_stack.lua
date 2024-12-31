--cmd + shift + p:启动/关闭剪贴板堆栈模式
--hyper + v:粘贴剪贴板内容并退出剪贴板堆栈模式

local module = {}

local isStackModeEnabled = false
local currentHotkey = nil
local clipboardTimer = nil
local clipboardStack = ""
--这个值需要大于0.2
local delay = 0.5
local counter = 0

function module.paste()
    if isStackModeEnabled then
        if clipboardStack ~= "" then
            if clipboardTimer then clipboardTimer:stop() end

            -- 移除最后一行末尾的换行符
            clipboardStack = clipboardStack:gsub("(\n?)$", "")
            hs.pasteboard.setContents(clipboardStack)

            hs.timer.doAfter(delay, function()
                hs.eventtap.keyStroke({ "cmd" }, "v")
                hs.alert.show("共计粘贴:\n" .. counter .. "项")

                hs.timer.doAfter(delay, function()
                    isStackModeEnabled = false
                    clipboardStack = ""
                    hs.pasteboard.clearContents()
                    if currentHotkey then
                        currentHotkey:delete()
                    end
                    hs.alert.show("剪贴板堆栈模式已退出")
                end)
            end)
        end
    end
end

function module.enableStackMode()
    isStackModeEnabled = true
    clipboardStack = ""
    hs.pasteboard.clearContents()
    counter = 0

    hs.alert.show("剪贴板堆栈模式已启动")

    -- 开始监控剪贴板
    clipboardTimer = hs.timer.doEvery(0.5, function()
        local currentClipboard = hs.pasteboard.getContents()
        if currentClipboard ~= nil then
            clipboardStack = clipboardStack .. currentClipboard .. "\n"
            hs.pasteboard.clearContents()

            -- 限制显示的内容为前3行
            local showContent = ""
            local lines = {}
            for line in currentClipboard:gmatch("[^\r\n]+") do
                table.insert(lines, line)
                if #lines == 3 then break end
            end
            showContent = table.concat(lines, "\n")

            counter = counter + 1
            hs.alert.show(counter .. ":\n已添加到堆栈:\n" .. showContent)
        end
    end)

    local keys = require("modules.keys")
    currentHotkey = hs.hotkey.bind(keys.hyper, "v", module.paste)
end

--每次粘贴完了之后就会退出stack mode,所以这个函数实际上仅用于在粘贴前放弃粘贴而退出
function module.disableStackMode()
    -- 停止监控并恢复原始剪贴板内容
    isStackModeEnabled = false
    if currentHotkey then
        currentHotkey:delete()
    end
    if clipboardTimer then clipboardTimer:stop() end
    clipboardStack = ""
    hs.pasteboard.clearContents()
    hs.alert.show("剪贴板堆栈模式已退出")
end

function module.toggleStackMode()
    if isStackModeEnabled then
        module.disableStackMode()
    else
        module.enableStackMode()
    end
end

function module.start()
    hs.hotkey.bind({ "cmd", "shift" }, "p", module.toggleStackMode)
end

return module
