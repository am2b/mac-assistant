--顺序:ctrl + cmd + p
--随机:ctrl + cmd + shift + p
--退出:esc

local M = {}

-- 配置
M.imageDir = "~/Downloads/收藏的图片"

-- 随机模式:ctrl + cmd + shift + p
M.randomModifiers = { "ctrl", "cmd", "shift" }
M.randomKey = "p"

-- 顺序模式:ctrl + cmd + p
M.sequenceModifiers = { "ctrl", "cmd" }
M.sequenceKey = "p"

-- 到达首尾时是否循环
-- true  = 循环
-- false = 停留在首尾
M.loopAtEnds = true

-- 图片超出屏幕时是否等比例缩小
M.shrinkToFit = true

-- 支持的图片格式
M.imageExtensions = {
    png = true,
    jpg = true,
    jpeg = true,
    gif = true,
    tif = true,
    tiff = true,
    bmp = true,
    heic = true,
    heif = true,
    webp = true,
}

-- 内部状态
M.files = {}

M.currentIndex = nil
M.currentPath = nil

-- 当前激活的浏览模式:random / sequence / nil
M.activeMode = nil

M.image = nil
M.canvas = nil
M.visible = false

-- 启动快捷键
M.randomHotkey = nil
M.sequenceHotkey = nil

-- 导航快捷键
M.previousHotkey = nil
M.nextHotkey = nil
M.spaceHotkey = nil
M.escapeHotkey = nil

-- 快捷键资源管理
function M.deleteHotkey(name)
    local hotkey = M[name]

    if hotkey then
        pcall(function()
            hotkey:delete()
        end)

        M[name] = nil
    end
end

function M.unbindNavigation()
    M.deleteHotkey("previousHotkey")
    M.deleteHotkey("nextHotkey")
    M.deleteHotkey("spaceHotkey")
    M.deleteHotkey("escapeHotkey")
end

function M.bindNavigation()
    M.unbindNavigation()

    local ok, err = pcall(function()
        M.previousHotkey = hs.hotkey.bind(
            {},
            "left",
            function()
                M.previous()
            end
        )

        if not M.previousHotkey then
            error("Left 快捷键注册失败")
        end

        M.nextHotkey = hs.hotkey.bind(
            {},
            "right",
            function()
                M.next()
            end
        )

        if not M.nextHotkey then
            error("Right 快捷键注册失败")
        end

        M.spaceHotkey = hs.hotkey.bind(
            {},
            "space",
            function()
                M.next()
            end
        )

        if not M.spaceHotkey then
            error("Space 快捷键注册失败")
        end

        M.escapeHotkey = hs.hotkey.bind(
            {},
            "escape",
            function()
                M.hide()
            end
        )

        if not M.escapeHotkey then
            error("Esc 快捷键注册失败")
        end
    end)

    if not ok then
        print("[ImageViewer] 导航快捷键注册失败: " .. tostring(err))
        M.unbindNavigation()
        return false
    end

    return true
end

-- 扫描图片目录
function M.getImageFiles()
    local files = {}

    local ok, iter, dir = pcall(hs.fs.dir, M.imageDir)

    if not ok or not iter then
        print("[ImageViewer] 无法访问目录: " .. M.imageDir)
        return files
    end

    local scanOK, scanErr = pcall(function()
        for name in iter, dir do
            if name ~= "." and name ~= ".." then
                local ext = name:match("%.([^%.]+)$")

                if ext and M.imageExtensions[ext:lower()] then
                    local path = M.imageDir .. "/" .. name
                    local attr = hs.fs.attributes(path)

                    if attr and attr.mode == "file" then
                        table.insert(files, path)
                    end
                end
            end
        end
    end)

    if not scanOK then
        print("[ImageViewer] 扫描目录失败: " .. tostring(scanErr))
        return {}
    end

    -- 按文件名排序
    table.sort(files)

    return files
end

-- 随机索引
function M.randomIndex()
    local count = #M.files

    if count == 0 then
        return nil
    end

    return math.random(1, count)
end

-- 创建 canvas
function M.createCanvas(image)
    local c = nil

    local ok, err = pcall(function()
        local screen = hs.screen.primaryScreen()

        if not screen then
            error("找不到主显示器")
        end

        local sf = screen:frame()
        local size = image:size()

        local imageW = size.w
        local imageH = size.h

        if imageW <= 0 or imageH <= 0 then
            error("图片尺寸无效")
        end

        local scale = 1.0

        if M.shrinkToFit then
            scale = math.min(
                1.0,
                sf.w / imageW,
                sf.h / imageH
            )
        end

        local displayW = imageW * scale
        local displayH = imageH * scale

        -- 屏幕居中
        local x = sf.x + (sf.w - displayW) / 2
        local y = sf.y + (sf.h - displayH) / 2

        c = hs.canvas.new {
            x = x,
            y = y,
            w = displayW,
            h = displayH,
        }

        if not c then
            error("Canvas 创建失败")
        end

        c:replaceElements({
            {
                type = "image",
                image = image,
                imageScaling = "scaleToFit",
                frame = {
                    x = 0,
                    y = 0,
                    w = displayW,
                    h = displayH,
                },
            },
        })

        c:level(hs.canvas.windowLevels.floating)

        c:behavior(
            hs.canvas.windowBehaviors.canJoinAllSpaces
        )
    end)

    if not ok then
        if c then
            pcall(function()
                c:delete()
            end)
        end

        print("[ImageViewer] Canvas 创建失败: " .. tostring(err))
        return nil
    end

    return c
end

-- 显示指定索引的图片
function M.showIndex(index)
    local count = #M.files

    if count == 0 or index < 1 or index > count then
        return false
    end

    local path = M.files[index]

    -- 相同图片无需重复加载
    if M.visible
        and M.currentIndex == index
        and M.currentPath == path then
        return true
    end

    -- 加载新图片
    local loadOK, image = pcall(
        hs.image.imageFromPath,
        path
    )

    if not loadOK or not image then
        print("[ImageViewer] 图片加载失败: " .. path)
        return false
    end

    -- 创建新 canvas
    local newCanvas = M.createCanvas(image)

    if not newCanvas then
        image = nil
        return false
    end

    -- 如果原来没有显示图片,先注册导航快捷键
    local newlyBound = false

    if not M.visible then
        if not M.bindNavigation() then
            pcall(function()
                newCanvas:delete()
            end)

            image = nil
            return false
        end

        newlyBound = true
    end

    -- 尝试显示新 canvas
    local showOK, showErr = pcall(function()
        newCanvas:show()
        newCanvas:bringToFront(true)
    end)

    if not showOK then
        pcall(function()
            newCanvas:delete()
        end)

        image = nil

        if newlyBound then
            M.unbindNavigation()
        end

        print("[ImageViewer] 显示失败: " .. tostring(showErr))
        return false
    end

    -- 保存旧资源
    local oldCanvas = M.canvas
    local oldImage = M.image

    -- 接管新资源
    M.canvas = newCanvas
    M.image = image

    M.currentIndex = index
    M.currentPath = path
    M.visible = true

    -- 新画布已经成功显示,现在释放旧资源
    if oldCanvas then
        pcall(function()
            oldCanvas:delete()
        end)
    end

    oldCanvas = nil
    oldImage = nil

    print(string.format(
        "[ImageViewer] [%d/%d] %s",
        index,
        count,
        path
    ))

    return true
end

-- 隐藏 / 关闭图片
function M.hide()
    -- 先释放导航快捷键
    M.unbindNavigation()

    -- 删除 canvas
    if M.canvas then
        pcall(function()
            M.canvas:delete()
        end)

        M.canvas = nil
    end

    -- 释放图片引用
    M.image = nil

    -- 清理状态
    M.visible = false
    M.currentIndex = nil
    M.currentPath = nil
    M.activeMode = nil

    print("[ImageViewer] 图片已关闭")
end

-- 随机模式的上一张 / 下一张
function M.randomNext()
    if not M.visible then
        return
    end

    local index = M.randomIndex()

    if index then
        M.showIndex(index)
    end
end

function M.randomPrevious()
    if not M.visible then
        return
    end

    local index = M.randomIndex()

    if index then
        M.showIndex(index)
    end
end

-- 顺序模式:上一张
function M.sequencePrevious()
    if not M.visible or not M.currentIndex then
        return
    end

    local index = M.currentIndex - 1
    local count = #M.files

    if index < 1 then
        if M.loopAtEnds then
            index = count
        else
            return
        end
    end

    M.showIndex(index)
end

-- 顺序模式:下一张
function M.sequenceNext()
    if not M.visible or not M.currentIndex then
        return
    end

    local index = M.currentIndex + 1
    local count = #M.files

    if index > count then
        if M.loopAtEnds then
            index = 1
        else
            return
        end
    end

    M.showIndex(index)
end

-- 上一张:根据当前模式分派
function M.previous()
    if not M.visible then
        return
    end

    if M.activeMode == "random" then
        M.randomPrevious()
    elseif M.activeMode == "sequence" then
        M.sequencePrevious()
    end
end

-- 下一张:根据当前模式分派
function M.next()
    if not M.visible then
        return
    end

    if M.activeMode == "random" then
        M.randomNext()
    elseif M.activeMode == "sequence" then
        M.sequenceNext()
    end
end

-- 激活指定模式
function M.activateMode(mode)
    if M.visible and M.activeMode == mode then
        return
    end

    -- 重新扫描目录
    local newFiles = M.getImageFiles()

    if #newFiles == 0 then
        print("[ImageViewer] 目录中没有图片")
        return
    end

    -- 暂存原来的文件列表
    local oldFiles = M.files

    M.files = newFiles

    local index

    if mode == "random" then
        index = M.randomIndex()
    elseif mode == "sequence" then
        index = 1
    else
        M.files = oldFiles
        return
    end

    -- 只有成功显示后才切换模式
    if M.showIndex(index) then
        M.activeMode = mode
    else
        -- 加载失败时,恢复原来的列表
        M.files = oldFiles
    end
end

-- 停止并释放所有资源
function M.stop()
    -- 释放启动快捷键
    M.deleteHotkey("randomHotkey")
    M.deleteHotkey("sequenceHotkey")

    -- 释放导航快捷键,canvas,image
    M.hide()

    -- 清空文件列表
    M.files = {}

    print("[ImageViewer] 所有资源已释放")
end

-- 初始化
function M.start()
    M.stop()

    -- 检查目录
    local attr = hs.fs.attributes(M.imageDir)

    if not attr or attr.mode ~= "directory" then
        print("[ImageViewer] 图片目录不存在: " .. M.imageDir)
        return false
    end

    -- 随机模式
    M.randomHotkey = hs.hotkey.bind(
        M.randomModifiers,
        M.randomKey,
        function()
            M.activateMode("random")
        end
    )

    if not M.randomHotkey then
        print("[ImageViewer] 随机快捷键注册失败")
        M.stop()
        return false
    end

    -- 顺序模式
    M.sequenceHotkey = hs.hotkey.bind(
        M.sequenceModifiers,
        M.sequenceKey,
        function()
            M.activateMode("sequence")
        end
    )

    if not M.sequenceHotkey then
        print("[ImageViewer] 顺序快捷键注册失败")
        M.stop()
        return false
    end

    print("[ImageViewer] 已启动")

    return true
end

-- shutdown / reload 清理
local previousShutdownCallback = hs.shutdownCallback

hs.shutdownCallback = function()
    M.stop()

    if type(previousShutdownCallback) == "function" then
        local ok, err = pcall(previousShutdownCallback)

        if not ok then
            print(
                "[ImageViewer] 原 shutdownCallback 执行失败: "
                .. tostring(err)
            )
        end
    end
end

-- 自动启动
M.start()

return M
