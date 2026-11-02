-- 当开启caps lock的时候,打开一个横幅来提示,可以通过鼠标点击来隐藏横幅

local M = {}

M.banner = nil
M.tap = nil
M.screenWatcher = nil
M.manualHidden = false

-- 获取目标显示器
function M.getScreen()
    return hs.screen.primaryScreen()
end

-- 创建横幅
function M.makeBanner()
    -- 先销毁旧画布
    if M.banner then
        M.banner:delete()
        M.banner = nil
    end

    local screen = M.getScreen()
    if not screen then
        return nil
    end

    local f = screen:frame()
    local h = 140

    local c = hs.canvas.new {
        x = f.x,
        y = f.y + 24,
        w = f.w,
        h = h,
    }

    c:replaceElements({
        {
            type = "rectangle",
            action = "fill",
            fillColor = {
                red = 0.85,
                green = 0.10,
                blue = 0.10,
                alpha = 0.94,
            },
            trackMouseDown = true,
            frame = {
                x = 0,
                y = 0,
                w = f.w,
                h = h,
            },
        },
        {
            type = "text",
            text = "CAPS LOCK 已开启",
            textSize = 60,
            textFont = "PingFang SC Semibold",
            textColor = { white = 1 },
            textAlignment = "center",
            trackMouseDown = true,
            frame = {
                x = 0,
                y = 25,
                w = f.w,
                h = 90,
            },
        },
    })

    -- 点击横幅隐藏
    c:mouseCallback(function(_, msg)
        if msg == "mouseDown" then
            M.manualHidden = true

            if M.banner then
                M.banner:hide()
            end
        end
    end)

    M.banner = c
    c:bringToFront(true)

    return c
end

-- 设置 Caps Lock 状态
function M.setCaps(on)
    if not on then
        M.manualHidden = false

        if M.banner then
            M.banner:hide()
        end

        return
    end

    if M.banner and not M.manualHidden then
        M.banner:show()
        M.banner:bringToFront(true)
    end
end

-- 停止并释放所有资源
function M.stop()
    if M.tap then
        M.tap:stop()
        M.tap = nil
    end

    if M.screenWatcher then
        M.screenWatcher:stop()
        M.screenWatcher = nil
    end

    if M.banner then
        M.banner:delete()
        M.banner = nil
    end

    M.manualHidden = false
end

-- 初始化
function M.start()
    -- 确保重复调用 start 不会产生重复资源
    M.stop()

    -- 创建横幅
    M.makeBanner()

    -- Caps Lock 状态监听
    local ALPHA_SHIFT = 1 << 16

    M.tap = hs.eventtap.new(
        { hs.eventtap.event.types.flagsChanged },
        function(e)
            M.setCaps(
                (e:rawFlags() & ALPHA_SHIFT) ~= 0
            )
        end
    )

    M.tap:start()

    -- 显示器变化监听
    M.screenWatcher = hs.screen.watcher.new(function()
        if not M.banner then
            return
        end

        -- 重建横幅,保留 manualHidden 状态
        M.makeBanner()

        -- 同步当前 Caps Lock 状态
        M.setCaps(
            hs.eventtap.checkKeyboardModifiers().capslock or false
        )
    end)

    M.screenWatcher:start()

    -- 初始化同步状态
    M.setCaps(
        hs.eventtap.checkKeyboardModifiers().capslock or false
    )
end

-- 注册退出 / reload 清理回调
local previousShutdownCallback = hs.shutdownCallback

hs.shutdownCallback = function()
    M.stop()

    if type(previousShutdownCallback) == "function" then
        previousShutdownCallback()
    end
end

-- 模块加载自动启动
M.start()

return M
