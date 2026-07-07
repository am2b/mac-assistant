--启动App

local module = {}

--function module.kacha()
--    local envs = require("modules.envs")
--    hs.application.launchOrFocus(envs.home .. "/applescripts/apps/kacha.app")
--end

function module.start()
    --hs.hotkey.bind({ "cmd", "shift" }, "0", module.kacha)
end

return module
