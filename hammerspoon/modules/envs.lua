--获取/定义环境变量

local module = {}

module.home = os.getenv("HOME")

module.bash = "/opt/homebrew/bin/bash"

module.icloud = hs.execute("source ~/.zshenv && echo $MAIL_ICLOUD"):gsub("%s+$", "")

return module
