--cmd + shift + 1:启动/关闭一键移动模式
--hyper + m:移动访达中被选中的文件到某个指定的目录

local module = {}

local isMoveEnable = false
local currentHotkey = nil
local oneKeyMoveMenubar = nil

function module.getDestPath()
    local configFile = os.getenv("HOME") .. "/.one_key_move"
    local file, err = io.open(configFile, "r")
    if not file then
        hs.alert.show("无法读取配置文件:" .. err)
        return nil
    end

    local destPath = file:read("*line")
    file:close()

    if not destPath or destPath == "" then
        hs.alert.show("配置文件中没有有效的目标目录")
        return nil
    end

    local attributes = hs.fs.attributes(destPath)
    if not attributes or attributes.mode ~= "directory" then
        hs.alert.show("配置文件中的路径" .. destPath .. "无效")
        return nil
    end

    return destPath
end

function module.isFinderFocused()
    local frontApp = hs.application.frontmostApplication()
    return frontApp:name() == "访达"
end

function module.hasSelected()
    local script = [[
    tell application "Finder"
        if selection as alias list is {} then
            return "none"
        else
            return "selected"
        end if
    end tell
    ]]

    local ok, result = hs.osascript.applescript(script)
    if not ok or result == "none" then
        return false
    end
    return true
end

function module.move(destPath)
    if not module.isFinderFocused() then
        hs.alert.show("当前的焦点窗口不是访达")
        return
    end

    if not module.hasSelected() then
        hs.alert.show("没有选中任何文件或目录")
        return
    end

    --获取访达选中的文件
    local script = [[
    tell application "Finder"
        set selectedItems to selection as alias list
        set paths to {}
        repeat with anItem in selectedItems
            set end of paths to POSIX path of anItem
        end repeat
        return paths
    end tell
    ]]
    local ok, result = hs.osascript.applescript(script)
    if not ok then
        hs.alert.show("获取选中文件失败:" .. result)
        return
    end

    --遍历选中的文件并移动到目标文件夹
    for _, filePath in ipairs(result) do
        local command = string.format('mv "%s" "%s/"', filePath, destPath)
        os.execute(command)
    end
    hs.alert.show("已移动选中的文件到目标目录")
end

function module.enableMove()
    hs.alert.show("一键移动模式已启动")

    isMoveEnable = true

    local destPath = module.getDestPath()
    if not destPath then
        return
    end

    local keys = require("modules.keys")
    currentHotkey = hs.hotkey.bind(keys.hyper, "m", function() module.move(destPath) end)

    if not oneKeyMoveMenubar then
        --创建状态栏对象
        oneKeyMoveMenubar = hs.menubar.new()
        oneKeyMoveMenubar:setTitle("OKM")
    end

    return true
end

function module.disableMove()
    isMoveEnable = false

    if currentHotkey then
        currentHotkey:delete()
    end

    if oneKeyMoveMenubar then
        oneKeyMoveMenubar:delete()
        oneKeyMoveMenubar = nil
    end

    hs.alert.show("一键移动模式已退出")
end

function module.toggleMove()
    if isMoveEnable then
        module.disableMove()
    else
        local ret = module.enableMove()
        if not ret then
            module.disableMove()
        end
    end
end

--该函数只会在Hammerspoon启动时执行一次,而不会在每次切换模式时执行
function module.start()
    hs.hotkey.bind({ "cmd", "shift" }, "1", module.toggleMove)
end

return module
