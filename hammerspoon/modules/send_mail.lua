--通过命令行/bash脚本/客户端来发送邮件

local module = {}

function module.sendByCommandLine(recipient, subject, body)
    local function completionCallback(exitCode, stdOut, stdErr)
        hs.printf("Task completed with exit code: %s", exitCode or "nil")
        hs.printf("Full stdout:\n%s", stdOut)
        hs.printf("Full stderr:\n%s", stdErr)
    end

    -- 定义邮件内容部分
    local toLine = string.format("To: %s\n", recipient)
    local subjectLine = string.format("Subject: %s\n", subject)
    local bodyContent = string.format("\n%s\n", body)
    -- 拼接完整的邮件内容
    local mailContent = toLine .. subjectLine .. bodyContent
    -- 使用 printf 将邮件内容通过管道传给 msmtp
    local command = string.format("printf '%s' | /opt/homebrew/bin/msmtp \"%s\"", mailContent, recipient)

    local task = hs.task.new("/opt/homebrew/bin/bash", completionCallback, { "-c", command })

    task:setEnvironment({
        LANG = "en_US.UTF-8",
        LC_CTYPE = "UTF-8",
        LC_ALL = "en_US.UTF-8"
    })

    task:start()
end

function module.sendByBashScript(recipient, subject, body)
    local function completionCallback(exitCode, stdOut, stdErr)
        hs.printf("Task completed with exit code: %s", exitCode or "nil")
        hs.printf("Full stdout:\n%s", stdOut)
        hs.printf("Full stderr:\n%s", stdErr)
    end

    local envs = require("modules.envs")
    local task = hs.task.new("/opt/homebrew/bin/bash", completionCallback,
        {
            "-c",
            "export PATH=/opt/homebrew/bin:$PATH; " .. envs.home .. "/repos/bash-tools/send_mail.sh '" ..
            subject .. "' '" .. body .. "' '" .. recipient .. "'"
        }
    )

    task:setEnvironment({
        LANG = "en_US.UTF-8",
        LC_CTYPE = "UTF-8",
        LC_ALL = "en_US.UTF-8"
    })

    task:start()
end

function module.sendByClient(recipient, subject, body)
    local applescript = string.format([[
        tell application "Microsoft Outlook"
            set newMessage to make new outgoing message with properties {subject:"%s", content:"%s"}
            tell newMessage
                make new to recipient at end of to recipients with properties {email address:{address:"%s"}}
                send
            end tell
        end tell
    ]], subject, body, recipient)

    hs.osascript.applescript(applescript)
end

return module
