--cmd + shift + r:启动/关闭剪贴板历史记录
--cmd + shift + v:打开剪贴板历史记录的面板

local clipboardHistory = {}

--获取当前剪贴板内容的"修改计数",每当剪贴板内容发生变化时,hs.pasteboard.changeCount()的值会自动增加
--用preChangeCount变量来记录上一次检查剪贴板时的计数,并在定时器中将其与当前计数进行比较,以判断剪贴板是否发生了新的更改
local preChangeCount = hs.pasteboard.changeCount()
local text_show_length = 100
local history = {}
local historyNum = 10
local recording = false

-- 检查内容是否已在历史记录中
local function isDuplicate(content)
    for _, item in ipairs(history) do
        if item.content == content then
            return true
        end
    end
    return false
end

-- 添加新内容到历史记录
local function addToHistory()
    --返回当前剪贴板中内容的类型列表
    local contentTypes = hs.pasteboard.contentTypes()
    for _, uti in ipairs(contentTypes) do
        if uti == "public.utf8-plain-text" then
            --获取剪贴板中的纯文本内容
            local text = hs.pasteboard.readString()
            if text and not isDuplicate(text) then
                --添加到history表的开头
                --string.gsub(text, "[\r\n]+", " ")将文本中的换行符替换为空格
                --text:无换行符的文本
                --content:原始的文本
                if #text > text_show_length then
                    -- 截断并添加省略号
                    text = string.sub(text, 1, text_show_length) .. "..."
                end
                table.insert(history, 1, { text = string.gsub(text, "[\r\n]+", " "), content = text })
                if #history > historyNum then
                    table.remove(history, #history)
                end
                hs.alert.show("已添加到剪贴板的历史记录:" .. history[1].text)
            end
            break
        end
    end
end

-- 启动剪贴板监控
function clipboardHistory.start()
    if not recording then
        hs.pasteboard.clearContents()
        clipboardHistory.watcher = hs.timer.doEvery(0.5, function()
            local changeCount = hs.pasteboard.changeCount()
            if preChangeCount ~= changeCount then
                addToHistory()
                preChangeCount = changeCount
            end
        end)

        -- 绑定cmd+shift+v快捷键显示历史记录
        hs.hotkey.bind({ "cmd", "shift" }, "v", clipboardHistory.showHistory)
        recording = true
        hs.alert.show("启动剪贴板历史记录")
    end
end

-- 停止剪贴板监控
function clipboardHistory.stop()
    if recording and clipboardHistory.watcher then
        clipboardHistory.watcher:stop()
        clipboardHistory.watcher = nil
        -- 清空历史记录
        history = {}
        -- 解除cmd+shift+v快捷键绑定
        hs.hotkey.deleteAll({ "cmd", "shift" }, "v")
        recording = false
        hs.pasteboard.clearContents()
        hs.alert.show("关闭剪贴板历史记录")
    end
end

-- 显示历史记录选择菜单
function clipboardHistory.showHistory()
    --创建一个新的选择器(chooser),并接受一个回调函数作为参数,当用户从历史记录中选择一个选项时,这个回调函数会被调用
    --choice是用户选择的项
    local chooser = hs.chooser.new(function(choice)
        if choice then
            hs.pasteboard.setContents(choice.content)
            --hs.alert.show("Pasted:" .. choice.text)
        else
            --按下了esc
            return
        end
    end)

    --准备选择项
    --遍历history表中的每一项,构造一个新表包含text和content字段,并将其插入到choices表中
    --text是简化显示的文本,而content是完整的剪贴板内容
    local choices = {}
    for _, item in ipairs(history) do
        table.insert(choices, { text = item.text, content = item.content })
    end
    --设置选择项并显示
    --chooser:choices(choices)将构建好的choices列表设置为选择器的内容
    chooser:choices(choices)
    --chooser:show()显示选择器,让用户能够看到历史记录并做出选择
    --在屏幕上显示一个浮动的选择器界面（包含一个可滚动的列表，用户可以通过键盘或鼠标选择条目），允许用户从剪贴板历史记录中选择项目
    chooser:show()
end

function clipboardHistory.toggleRecording()
    if recording then
        clipboardHistory.stop()
    else
        clipboardHistory.start()
    end
end

hs.hotkey.bind({ "cmd", "shift" }, "r", clipboardHistory.toggleRecording)

return clipboardHistory
