--通过检测约定目录下的约定好名字的文件是否存在来激活或关闭"单击鼠标右键来模拟空格键"的功能
--~/.local/share/hammerspoon/right_mouse_button_simulates_space

local module = {}

local envs = require("modules.envs")
local flagFile = envs.home .. "/.local/share/hammerspoon/right_mouse_button_simulates_space"

local eventtap = hs.eventtap.new({ hs.eventtap.event.types.rightMouseDown }, function(event)
    local frontApp = hs.application.frontmostApplication():name()
    if frontApp == "iTerm2" and hs.fs.attributes(flagFile) then
        --hs.alert.show("right clicked")
        hs.eventtap.keyStroke({}, "space")
        return true
    else
        return false
    end
end)

function module.start()
    eventtap:start()
end

return module
