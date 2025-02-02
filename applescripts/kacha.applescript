-- 截图,然后不仅存储到硬盘上,同时也存储到剪贴板上

set timestamp to do shell script "date +%Y%m%d%H%M%S"
set screenshotFolder to (path to downloads folder as text) & "screenshot:"
set screenshotFolderPOSIX to POSIX path of screenshotFolder

-- 检查目录是否存在，如果不存在则创建目录
do shell script "if [ ! -d " & quoted form of screenshotFolderPOSIX & " ]; then mkdir -p " & quoted form of screenshotFolderPOSIX & "; fi"

set filename to screenshotFolder & "screenshot_" & timestamp & ".png"

-- 使用 screencapture 命令截图并保存到文件
do shell script "screencapture -i " & quoted form of POSIX path of filename

-- 等待文件写入完成
delay 0.5

-- 检查文件是否存在，如果存在则将内容复制到剪贴板
try
	do shell script "if [ -f " & quoted form of POSIX path of filename & " ]; then osascript -e 'set the clipboard to (read (POSIX file \"" & POSIX path of filename & "\") as «class PNGf»)' ; fi"
on error
	display dialog "Screenshot was canceled or an error occurred." buttons {"OK"} default button "OK"
end try
