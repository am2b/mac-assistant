--通过检测约定目录下的约定好名字的文件是否存在来激活或关闭:
--开关文件的名字:
--~/.local/share/hammerspoon/browse_pictures
--在目录中选中一个图片文件,按下空格键开始预览:
--left/right:copy当前正在预览的图片到配置文件所指定的目录
--也可以仅在目录中选中一个任意文件,然后按下left/right来copy,前提是存在开关文件
--配置文件:
--~/.config/hammerspoon-modules/browse_pictures
--注意:
--1:当修改了配置文件后,需要重新reload一下Hammerspoon的配置文件
--2:如果没有成功从配置文件中解析出destDir,那么使用默认的~/tmp作为copy的目标目录

local module = {}

local envs = require("modules.envs")
local flagFile = envs.home .. "/.local/share/hammerspoon/browse_pictures"
local configFilePath = envs.home .. "/.config/hammerspoon-modules/browse_pictures"
local config = nil
local targetDir = nil

--按键
local stateLeft, stateRight = nil, nil
local isBound = false

--窗口过滤器
local windowFilter = nil

--展开~
local function expandUser(path)
    if type(path) ~= "string" then return path end
    local home = os.getenv("HOME") or "~"
    return path:gsub("^~", home)
end

--解析配置文件
local function parseConfigFile()
    local err = nil
    config, err = hs.json.read(configFilePath)
    if not config then
        hs.alert.show("browse_pictures:读取配置文件失败:" .. tostring(err))
        config = {}
    end
end

local function createDirectoryIfNeeded(dirPath)
    --检查目录是否存在
    local attr = hs.fs.attributes(dirPath)
    if attr and attr.mode == "directory" then
        --目录已存在
        return true
    elseif attr then
        --存在但不是目录(是文件)
        return false, "路径存在但不是目录"
    end

    local success, err = hs.fs.mkdir(dirPath)
    if not success then
        return false, "创建目录失败:" .. (err or "未知错误")
    end

    return true
end

--从一个路径中抽取出文件名
local function getFilenameFromPath(path)
    return path:match("^.+/(.+)$")
end

--检查文件是否存在
local function fileExists()
    return hs.fs.attributes(flagFile) ~= nil
end

--获取访达中选中的那个文件
local function getSelectedFile()
    local script = [[
        tell application "Finder"
            try
                --获取选中的第一个文件,如果未选中任何文件会报错
                set selectedItem to (item 1 of (get selection)) as alias
                set thePath to POSIX path of selectedItem
                return thePath
            on error
                return ""
            end try
        end tell
    ]]
    local ok, result = hs.osascript.applescript(script)
    if not ok or result == "" then
        --未选中文件或者发生错误,都返回nil
        hs.alert.show("获取选中文件失败或未选中任何文件")
        return nil
    end

    return result
end

local function copyToTarget(path)
    --检查目标目录下是否存在同名的文件
    local pictureName = getFilenameFromPath(path)
    local destPictureName = targetDir .. "/" .. pictureName
    if fileExists(destPictureName) then
        hs.alert.show("目标目录下存在同名文件:" .. pictureName)
        return
    end

    if path then
        os.execute(string.format('cp "%s" "%s/"', path, targetDir))
    end
end

local function bindKeys()
    if isBound then return end

    stateLeft = hs.hotkey.bind({}, "left", function()
        local f = getSelectedFile()
        copyToTarget(f)
    end)

    stateRight = hs.hotkey.bind({}, "right", function()
        local f = getSelectedFile()
        copyToTarget(f)
    end)

    isBound = true
end

--当删除~/.local/share/hammerspoon/browse_pictures,然后访达再次是焦点窗口的时候,会调用该函数
--也可以通过监控~/.local/share/hammerspoon目录来调用该函数,但是考虑到访达是一个经常会被切换到的app,所以就省略了对目录的监控逻辑
local function unbindKeys()
    if not isBound then return end

    if stateLeft then
        stateLeft:delete()
        stateLeft = nil
    end
    if stateRight then
        stateRight:delete()
        stateRight = nil
    end

    isBound = false
end

--根据flagFile是否存在来绑定/解绑按键
local function refreshBindings()
    if fileExists() then
        bindKeys()
    else
        unbindKeys()
    end
end

--当访达是焦点窗口的时候,回调该函数
local function finderActivatedCallback(win)
    --从窗口对象拿application
    local app = win:application()
    if not app then
        hs.alert.show("browse_pictures:没有从窗口对象获取到应用对象")
        return
    end

    if app:bundleID() == "com.apple.finder" then
        refreshBindings()
    end
end

function module.start()
    --解析配置文件
    parseConfigFile()
    targetDir = expandUser(config.destDir or "~/tmp")
    createDirectoryIfNeeded(targetDir)

    if windowFilter then
        windowFilter:unsubscribeAll()
        windowFilter = nil
    end

    --定义一个window filter,只监听访达,注意:new里面要写中文"访达"
    windowFilter = hs.window.filter.new("访达")
    --当Finder窗口被激活(获得焦点)时触发
    --win:触发事件的窗口对象(hs.window)
    --appName:应用名称(比如"Finder")
    --event:事件类型(比如"windowFocused")
    windowFilter:subscribe(hs.window.filter.windowFocused, function(win, appName, event)
        --在这里调用自己的函数
        finderActivatedCallback(win)
    end)
end

return module
