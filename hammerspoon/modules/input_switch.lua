--根据不同的App自动切换输入法

local module = {}

module.englishInputSource = "com.apple.keylayout.ABC"
module.chineseInputSource = "com.apple.inputmethod.SCIM.Shuangpin"

--英文:
module.iterm2 = "iTerm2"
--中文:
module.chatgpt = "ChatGPT"
module.memo = "备忘录"
module.wechat = "微信"
module.chrome = "Google Chrome"
module.safari = "Safari浏览器"
module.firefox = "Firefox"

module.debugMode = false

function module.debugAlert(message) if module.debugMode then hs.alert.show(message) end end

-- 获取当前输入法
function module.currentInputSource()
    return hs.keycodes.currentSourceID()
end

-- 切换到指定的输入法
function module.changeInputToEnglish()
    local currentSource = module.currentInputSource()
    if currentSource ~= module.englishInputSource then
        hs.keycodes.currentSourceID(module.englishInputSource)
        module.debugAlert("Switched to English input")
    end
end

function module.changeInputToChinese()
    local currentSource = module.currentInputSource()
    if currentSource ~= module.chineseInputSource then
        hs.keycodes.currentSourceID(module.chineseInputSource)
        module.debugAlert("Switched to Chinese input")
    end
end

--英语:
-- iterm2
module.englishWatcher = hs.application.watcher.new(function(name, event, app)
    if (event == hs.application.watcher.activated) then
        if name == module.iterm2 then
            module.changeInputToEnglish()
        end
    end
end)

--中文:
module.chineseWatcher = hs.application.watcher.new(function(name, event, app)
    if (event == hs.application.watcher.activated) then
        if name == module.chatgpt or name == module.memo or name == module.wechat
            or name == module.chrome or name == module.safari or name == module.firefox then
            module.changeInputToChinese()
        end
    end
end)

function module.start()
    module.englishWatcher:start()
    --module.chineseWatcher:start()
end

return module
