--cmd + shift + t:在当前访达目录下新建一个文本文件

local M = {}

local function getFinderPath()
    --先检查当前前台应用是否为访达
    local frontApp = hs.application.frontmostApplication()
    if frontApp:bundleID() ~= "com.apple.finder" then
        return nil
    end

    local script = [[
    tell application "Finder"
        if (count of windows) > 0 then
            set currentPath to POSIX path of (target of front window as alias)
        else
            --无窗口时返回空字符串
            set currentPath to ""
        end if
    end tell
    return currentPath
    ]]

    local ok, result = hs.applescript(script)
    return ok and result or nil
end

local function create()
    local path = getFinderPath()
    if path then
        local function completionCallback(exitCode, stdOut, stdErr)
            hs.printf("Task completed with exit code: %s", exitCode or "nil")
            hs.printf("Full stdout:\n%s", stdOut)
            hs.printf("Full stderr:\n%s", stdErr)
        end
        local envs = require("modules.envs")
        local task = hs.task.new("/opt/homebrew/bin/bash", completionCallback,
            {
                "-c",
                "export PATH=/opt/homebrew/bin:$PATH; " ..
                envs.home .. "/repos/bash-tools/text_create_txt_file.sh " .. path
            }
        )
        task:start()
    else
        hs.alert.show("请先聚焦访达窗口")
    end
end

function M.start()
    hs.hotkey.bind({ "cmd", "shift" }, "t", create)
end

return M
