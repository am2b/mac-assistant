--绑定同一个ctrl + option + cmd + hotkey到多个apps,然后在不同的app下执行不同的脚本

local module = {}

local hotkeys = {
    ["1"] = "1",
    ["2"] = "2",
    ["3"] = "3",
    --["a"] = "a",
    --["b"] = "b",
}

local function getFrontAppName()
    local frontApp = hs.application.frontmostApplication()
    local name = frontApp:name()
    --转小写并将空格替换为下划线
    name = string.lower(name):gsub("%s", "_")
    return name
end

local function resolve_symlink(path)
    local handle = io.popen("realpath " .. string.format("%q", path))
    local result = handle:read("*a")
    handle:close()
    return result:gsub("\n$", "")
end

local function copyImage()
    local envs = require("modules.envs")
    local dir = resolve_symlink(envs.home .. "/.local/share/mail-helper/images")

    local files = {}
    for file in hs.fs.dir(dir) do
        local fullpath = dir .. "/" .. file
        if hs.fs.attributes(fullpath, "mode") == "file" then
            table.insert(files, fullpath)
        end
    end

    if #files == 0 then
        hs.alert.show("No images found!")
        return
    end

    -- 随机选择一个图片
    math.randomseed(os.time())
    local index = math.random(1, #files)
    local chosen_file = files[index]

    --hs.alert.show(chosen_file)

    local task = hs.task.new(envs.home .. "/.local/bin/go-tools/copy_image", function(exitCode, stdOut, stdErr)
        if exitCode == 0 then
            hs.alert.show("图片复制成功")

            -- 删除该文件
            os.remove(chosen_file)
        else
            hs.alert.show("复制失败:" .. stdErr)
        end
    end, { chosen_file })

    if not task:start() then
        hs.alert.show("无法启动copy_image命令")
    end
end

local function hotKeySpecial(appName, key)
    if key == "3" then
        if appName == "microsoft_outlook" or appName == "mailmaster" or appName == "mail" then
            copyImage()
            return true
        end
    end

    return false
end

local function hotKey(key)
    local appName = getFrontAppName()

    local ret = hotKeySpecial(appName, key)
    if ret == true then
        return
    end

    local envs = require("modules.envs")
    local task = hs.task.new("/opt/homebrew/bin/bash", nil,
        {
            "-c",
            "export PATH=/opt/homebrew/bin:$PATH; " ..
            envs.home .. "/.config/hotkeys/hotkeys.sh " .. appName .. " " .. key
        })
    task:start()
end

function module.start()
    local keys = require("modules.keys")
    for k, v in pairs(hotkeys) do
        --hs.hotkey.bind(keys.coc, "1", function() hotKey("1") end)
        hs.hotkey.bind(keys.coc, k, function() hotKey(v) end)
    end
end

return module
