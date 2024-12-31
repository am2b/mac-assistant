--ctrl + delete:清空废纸篓

local module = {}

-- 绑定ctrl + delete来清空废纸篓
function module.start()
    hs.hotkey.bind({ "ctrl" }, "delete", function()
        --需要在"隐私与安全性"->"自动化"里面开启Hammerspoon对访达的权限
        local result = hs.execute("osascript -e 'tell application \"Finder\" to empty the trash'")
        if result then
            hs.alert.show("回收站已清空")
        else
            hs.alert.show("清空回收站失败")
        end
    end)
end

return module
