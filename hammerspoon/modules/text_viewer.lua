-- ctrl + cmd + shift + t:随机显示一个给定目录下的文本文件

local M = {}

-- 配置区域
-- 文本文件所在目录(只扫描当前目录,不递归)
M.textDir = os.getenv("HOME") .. "/Downloads/texts"

-- 启动快捷键:ctrl + cmd + shift + t
M.hotkeyModifiers = { "ctrl", "cmd", "shift" }
M.hotkeyKey = "t"

-- 字体设置
M.fontName = "Hack Nerd Font Mono"
M.fontSize = 20

-- 窗口边距
M.padding = 28

-- 窗口最小宽度
M.minWidth = 480

-- 最大窗口宽度比例
M.maxWidthRatio = 0.90

-- 最大窗口高度比例
-- 1.0 = 屏幕可用高度的 100%
M.maxHeightRatio = 1.0

-- 文件扩展名
M.extensions = {
    txt = true,
    text = true,
    md = true,
    markdown = true,
    log = true,
}

-- 窗口背景
M.backgroundColor = {
    red = 0.10,
    green = 0.11,
    blue = 0.14,
    alpha = 0.97,
}

-- 文本颜色
M.textColor = {
    red = 0.93,
    green = 0.94,
    blue = 0.96,
    alpha = 1.0,
}

-- 边框颜色
M.borderColor = {
    red = 0.35,
    green = 0.38,
    blue = 0.43,
    alpha = 0.8,
}

-- 内部状态
M.openHotkey = nil

M.spaceHotkey = nil
M.upHotkey = nil
M.downHotkey = nil
M.escapeHotkey = nil
M.nextHotkey = nil

M.scrollTap = nil

M.canvas = nil

M.lines = {}
M.currentPath = nil
M.lastPath = nil

-- 滚动位置:已经向上滚过多少个视觉行
M.scrollRows = 0

-- 全部文本经过软换行后的视觉行数
M.totalVisualRows = 0

-- 当前窗口可显示的视觉行数
M.visibleRows = 0

-- 每个视觉行的高度
M.lineHeight = 0

-- 文本区域宽度
M.contentWidth = 0

-- 文本完整高度
M.contentHeight = 0

-- 删除热键
local function deleteHotkey(name)
    if M[name] then
        pcall(function()
            M[name]:delete()
        end)

        M[name] = nil
    end
end

-- 注销查看器临时热键和事件监听
function M.unbindViewerControls()
    deleteHotkey("spaceHotkey")
    deleteHotkey("upHotkey")
    deleteHotkey("downHotkey")
    deleteHotkey("escapeHotkey")
    deleteHotkey("nextHotkey")

    if M.scrollTap then
        pcall(function()
            M.scrollTap:stop()
        end)

        M.scrollTap = nil
    end
end

-- 关闭并释放资源
function M.close()
    local wasOpen = M.canvas ~= nil

    M.unbindViewerControls()

    if M.canvas then
        pcall(function()
            M.canvas:delete()
        end)

        M.canvas = nil
    end

    M.lines = {}
    M.currentPath = nil

    M.scrollRows = 0
    M.totalVisualRows = 0
    M.visibleRows = 0
    M.lineHeight = 0
    M.contentWidth = 0
    M.contentHeight = 0

    if wasOpen then
        print("[TextViewer] 文本窗口已关闭")
        print("[TextViewer] 所有资源已释放")
    end
end

-- 扫描文本目录
function M.getTextFiles()
    local iterator, dirHandle = hs.fs.dir(M.textDir)

    if not iterator then
        print(
            "[TextViewer] 无法读取目录"
        )

        return {}
    end

    local files = {}

    for name in iterator, dirHandle do
        if name ~= "." and name ~= ".." then
            local ext = name:match("%.([^%.]+)$")

            if ext and M.extensions[ext:lower()] then
                local path = M.textDir .. "/" .. name

                local attr = hs.fs.attributes(path)

                if attr and attr.mode == "file" then
                    table.insert(files, path)
                end
            end
        end
    end

    table.sort(files)

    return files
end

-- 读取文本文件
local function readTextFile(path)
    local file, err = io.open(path, "rb")

    if not file then
        return nil, err
    end

    local content = file:read("*a")

    file:close()

    if not content then
        return nil, "读取文件失败"
    end

    -- 排除明显的二进制文件
    if content:find("%z") then
        return nil, "文件包含二进制数据"
    end

    -- 移除 UTF-8 BOM
    content = content:gsub("^\239\187\191", "")

    return content
end

-- 拆分原始物理行
local function splitLines(content)
    -- 统一换行符
    content = content:gsub("\r\n", "\n")
    content = content:gsub("\r", "\n")

    local lines = {}

    if content == "" then
        return { "" }
    end

    local start = 1

    while true do
        local pos = content:find("\n", start, true)

        if not pos then
            table.insert(lines, content:sub(start))
            break
        end

        table.insert(lines, content:sub(start, pos - 1))

        start = pos + 1

        -- 不额外制造文件末尾的空行
        if start > #content then
            break
        end
    end

    return lines
end

-- 测量文本和计算布局
function M.measureLayout(lines)
    local screen = hs.screen.mainScreen()

    if not screen then
        return nil, "无法获取主显示器"
    end

    local screenFrame = screen:frame()

    -- 临时 Canvas 用于测量字体尺寸
    local measureCanvas = hs.canvas.new({
        x = screenFrame.x,
        y = screenFrame.y,
        w = screenFrame.w,
        h = screenFrame.h,
    })

    if not measureCanvas then
        return nil, "创建测量 Canvas 失败"
    end

    measureCanvas[1] = {
        type = "text",

        frame = {
            x = 0,
            y = 0,
            w = screenFrame.w,
            h = screenFrame.h,
        },

        text = "",
        textFont = M.fontName,
        textSize = M.fontSize,

        textLineBreak = "charWrap",
    }

    -- 测量单行高度
    local oneLine = measureCanvas:minimumTextSize(
        1,
        "Mg"
    )

    local twoLines = measureCanvas:minimumTextSize(
        1,
        "Mg\nMg"
    )

    local lineHeight = twoLines.h - oneLine.h

    if lineHeight <= 0 then
        lineHeight = M.fontSize * 1.2
    end

    -- 测量每一条原始物理行的宽度
    local maxLineWidth = 0
    local lineWidths = {}

    for index, line in ipairs(lines) do
        local measured = measureCanvas:minimumTextSize(
            1,
            line == "" and " " or line
        )

        local width = measured.w or 0

        lineWidths[index] = width

        if width > maxLineWidth then
            maxLineWidth = width
        end
    end

    measureCanvas:delete()

    -- 计算窗口宽度
    local maxWidth = screenFrame.w * M.maxWidthRatio

    local minWidth = math.min(
        M.minWidth,
        maxWidth
    )

    local width = math.min(
        maxWidth,
        math.max(
            minWidth,
            maxLineWidth + M.padding * 2
        )
    )

    local contentWidth = math.max(
        1,
        width - M.padding * 2
    )

    -- 计算软换行后的视觉行数
    -- 每一条物理行根据显示宽度计算视觉行数
    local totalVisualRows = 0

    for _, lineWidth in ipairs(lineWidths) do
        local rows = math.max(
            1,
            math.ceil(lineWidth / contentWidth)
        )

        totalVisualRows = totalVisualRows + rows
    end

    -- 最大窗口高度
    local maxHeight = screenFrame.h * M.maxHeightRatio

    local maxVisibleRows = math.max(
        1,
        math.floor(
            (maxHeight - M.padding * 2) / lineHeight
        )
    )

    local visibleRows = math.min(
        totalVisualRows,
        maxVisibleRows
    )

    -- 实际窗口高度
    local height = math.min(
        maxHeight,
        visibleRows * lineHeight + M.padding * 2
    )

    -- 居中
    local x = screenFrame.x
        + (screenFrame.w - width) / 2

    local y = screenFrame.y
        + (screenFrame.h - height) / 2

    -- 完整文本高度
    local contentHeight =
        totalVisualRows * lineHeight + lineHeight

    return {
        x = x,
        y = y,

        width = width,
        height = height,

        contentWidth = contentWidth,
        contentHeight = contentHeight,

        lineHeight = lineHeight,

        totalVisualRows = totalVisualRows,
        visibleRows = visibleRows,
    }
end

-- 更新文本位置,实现滚动
function M.updateTextPosition()
    if not M.canvas then
        return
    end

    local y = M.padding
        - M.scrollRows * M.lineHeight

    M.canvas:elementAttribute(
        2,
        "frame",
        {
            x = M.padding,
            y = y,
            w = M.contentWidth,
            h = M.contentHeight,
        }
    )
end

-- 正数:向下滚动
-- 负数:向上滚动
function M.scrollBy(rows)
    if not M.canvas then
        return
    end

    local maxScroll = math.max(
        0,
        M.totalVisualRows - M.visibleRows
    )

    M.scrollRows = math.max(
        0,
        math.min(
            maxScroll,
            M.scrollRows + rows
        )
    )

    M.updateTextPosition()
end

-- 逐行滚动
function M.scrollDown()
    M.scrollBy(1)
end

function M.scrollUp()
    M.scrollBy(-1)
end

-- 向下翻页:当前屏最后一行保留为下一屏第一行
function M.scrollPageDown()
    local step = math.max(1, M.visibleRows + 1)
    M.scrollBy(step)
end

-- 鼠标滚轮事件
-- 只在鼠标位于文本窗口内时处理
function M.startScrollTap()
    local ok, tap = pcall(
        hs.eventtap.new,
        {
            hs.eventtap.event.types.scrollWheel
        },
        function(event)
            if not M.canvas then
                return false
            end

            local mouse = hs.mouse.absolutePosition()
            local frame = M.canvas:frame()

            local inside =
                mouse.x >= frame.x
                and mouse.x <= frame.x + frame.w
                and mouse.y >= frame.y
                and mouse.y <= frame.y + frame.h

            if not inside then
                return false
            end

            local delta = event:getProperty(
                hs.eventtap.event.properties.scrollWheelEventDeltaAxis1
            )

            if delta == 0 then
                delta = event:getProperty(
                    hs.eventtap.event.properties.scrollWheelEventFixedPtDeltaAxis1
                )
            end

            if delta > 0 then
                M.scrollUp()
            elseif delta < 0 then
                M.scrollDown()
            end

            -- 不把窗口内的滚轮事件传给后面的应用
            return true
        end
    )

    if not ok or not tap then
        return false
    end

    local started, err = pcall(function()
        tap:start()
    end)

    if not started then
        pcall(function()
            tap:stop()
        end)

        print(
            "[TextViewer] 鼠标滚轮监听启动失败: "
            .. tostring(err)
        )

        return false
    end

    M.scrollTap = tap

    return true
end

-- 注册查看器临时热键
function M.bindViewerControls()
    if M.spaceHotkey then
        return true
    end

    local created = {}

    local function cleanup()
        for _, hotkey in pairs(created) do
            pcall(function()
                hotkey:delete()
            end)
        end
    end

    local function bind(field, key, callback)
        local ok, hotkey = pcall(
            hs.hotkey.bind,
            {},
            key,
            callback
        )

        if not ok or not hotkey then
            cleanup()
            return false
        end

        created[field] = hotkey
        return true
    end

    -- 空格:向下翻一屏,与上一屏重叠一行
    if not bind("spaceHotkey", "space", function()
            M.scrollPageDown()
        end) then
        return false
    end

    -- 上方向键:向上滚动
    if not bind("upHotkey", "up", function()
            M.scrollUp()
        end) then
        return false
    end

    -- 下方向键:向下滚动
    if not bind("downHotkey", "down", function()
            M.scrollDown()
        end) then
        return false
    end

    -- Esc:关闭
    if not bind("escapeHotkey", "escape", function()
            M.close()
        end) then
        return false
    end

    -- 右方向键:随机选择下一份文本
    if not bind("nextHotkey", "right", function()
            M.showRandom()
        end) then
        return false
    end

    -- 全部注册成功后再接管资源
    M.spaceHotkey = created.spaceHotkey
    M.upHotkey = created.upHotkey
    M.downHotkey = created.downHotkey
    M.escapeHotkey = created.escapeHotkey
    M.nextHotkey = created.nextHotkey

    -- 注册鼠标滚轮监听
    if not M.startScrollTap() then
        M.unbindViewerControls()
        return false
    end

    return true
end

-- 创建 Canvas
function M.createCanvas(lines)
    local layout, err = M.measureLayout(lines)

    if not layout then
        return nil, err
    end

    local canvas = hs.canvas.new({
        x = layout.x,
        y = layout.y,
        w = layout.width,
        h = layout.height,
    })

    if not canvas then
        return nil, "创建 Canvas 失败"
    end

    -- 背景
    canvas[1] = {
        type = "rectangle",

        frame = {
            x = 0,
            y = 0,
            w = layout.width,
            h = layout.height,
        },

        roundedRectRadii = {
            xRadius = 12,
            yRadius = 12,
        },

        fillColor = M.backgroundColor,
        strokeColor = M.borderColor,
        strokeWidth = 1,

        -- 背景也接收鼠标点击
        trackMouseDown = true,
    }

    -- 文本
    canvas[2] = {
        type = "text",

        frame = {
            x = M.padding,
            y = M.padding,
            w = layout.contentWidth,
            h = layout.contentHeight,
        },

        text = table.concat(lines, "\n"),

        textFont = M.fontName,
        textSize = M.fontSize,
        textColor = M.textColor,

        textAlignment = "left",

        -- 类似 nvim 的软换行
        textLineBreak = "charWrap",
    }

    -- 鼠标点击关闭
    canvas:mouseCallback(function(_, message)
        if message == "mouseDown" then
            M.close()
        end
    end)

    canvas:clickActivating(false)

    -- Canvas 窗口层级
    canvas:level("floating")

    return canvas, nil, layout
end

-- 显示文本
function M.showText(path, content)
    local lines = splitLines(content)

    local newCanvas, err, layout =
        M.createCanvas(lines)

    if not newCanvas then
        print("[TextViewer] " .. tostring(err))
        return false
    end

    -- 注册临时热键
    local newlyBound = false

    if not M.spaceHotkey then
        if not M.bindViewerControls() then
            newCanvas:delete()

            print("[TextViewer] 查看器快捷键注册失败")
            return false
        end

        newlyBound = true
    end

    -- 显示新 Canvas
    local ok, showErr = pcall(function()
        newCanvas:show()
    end)

    if not ok then
        newCanvas:delete()

        if newlyBound then
            M.unbindViewerControls()
        end

        print(
            "[TextViewer] 显示失败: "
            .. tostring(showErr)
        )

        return false
    end

    -- 接管新资源
    local oldCanvas = M.canvas

    M.canvas = newCanvas

    M.lines = lines

    M.currentPath = path
    M.lastPath = path

    M.scrollRows = 0

    M.totalVisualRows = layout.totalVisualRows
    M.visibleRows = layout.visibleRows

    M.lineHeight = layout.lineHeight
    M.contentWidth = layout.contentWidth
    M.contentHeight = layout.contentHeight

    -- 删除旧 Canvas
    if oldCanvas then
        pcall(function()
            oldCanvas:delete()
        end)
    end

    -- 输出日志
    print("[TextViewer] 文件: " .. path)
    print("[TextViewer] 原始物理行数: " .. #lines)
    print("[TextViewer] 软换行视觉行数: " .. M.totalVisualRows)
    print("[TextViewer] 当前可见视觉行数: " .. M.visibleRows)
    print("[TextViewer] 方向键 / 鼠标滚轮: 每次 1 个视觉行")
    print("[TextViewer] Space: 向下翻页,保留 1 行重叠")

    return true
end

-- 随机选择文本文件
function M.showRandom()
    local files = M.getTextFiles()

    if #files == 0 then
        print("[TextViewer] 目录中没有可用的文本文件")
        return false
    end

    -- 尽量避免连续抽到同一份文件
    local candidates = {}

    if #files > 1 then
        for _, path in ipairs(files) do
            if path ~= M.currentPath and path ~= M.lastPath then
                table.insert(candidates, path)
            end
        end
    end

    if #candidates == 0 then
        candidates = files
    end

    -- 随机起点,依次尝试其他文件
    local startIndex = math.random(#candidates)

    for offset = 0, #candidates - 1 do
        local index = (
            (startIndex + offset - 1) % #candidates
        ) + 1

        local path = candidates[index]

        local content, err = readTextFile(path)

        if content then
            if M.showText(path, content) then
                return true
            end
        else
            print(
                "[TextViewer] 跳过文件: "
                .. path
                .. ",原因: "
                .. tostring(err)
            )
        end
    end

    print("[TextViewer] 没有找到可读取的文本文件")

    return false
end

-- 启动
function M.start()
    M.stop()

    local attr = hs.fs.attributes(M.textDir)

    if not attr or attr.mode ~= "directory" then
        print(
            "[TextViewer] 文本目录不存在: "
            .. M.textDir
        )

        return false
    end

    local ok, hotkey = pcall(
        hs.hotkey.bind,
        M.hotkeyModifiers,
        M.hotkeyKey,
        function()
            M.showRandom()
        end
    )

    if not ok or not hotkey then
        print("[TextViewer] 启动快捷键注册失败")
        M.stop()
        return false
    end

    M.openHotkey = hotkey

    print("[TextViewer] 已启动")
    print("[TextViewer] 文本目录: " .. M.textDir)
    print("[TextViewer] 启动快捷键: Ctrl + Cmd + Alt + T")
    print("[TextViewer] 滚动: Space / Up / Down / 鼠标滚轮")
    print("[TextViewer] 下一份文本: Right")
    print("[TextViewer] 关闭: Esc / 鼠标点击")
    print("[TextViewer] 方向键 / 鼠标滚轮: 每次 1 个视觉行")
    print("[TextViewer] Space: 向下翻页,保留 1 行重叠")

    return true
end

-- 停止
function M.stop()
    M.close()

    deleteHotkey("openHotkey")

    print("[TextViewer] 已停止")
end

-- 模块入口
M.start()

return M
