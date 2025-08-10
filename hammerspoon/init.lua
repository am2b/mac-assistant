--enable IPC
hs.ipc.cliInstall()

local keyboard_battery = require("modules.keyboard_battery")
keyboard_battery.start()

local input_switch = require("modules.input_switch")
input_switch.start()

local window_expand = require("modules.window_expand")
window_expand.start()

local window_move = require("modules.window_move")
window_move.start()

local window_focus_next = require("modules.window_focus_next")
window_focus_next.start()

local desktop_show = require("modules.desktop_show")
desktop_show.start()

local clipboard_stack = require("modules.clipboard_stack")
clipboard_stack.start()

require("modules.clipboard_history")

local send_clipboard_to_telegram = require("modules.send_clipboard_to_telegram")
send_clipboard_to_telegram.start()

local finder_trash = require("modules.finder")
finder_trash.start()

local one_key_move = require("modules.one_key_move")
one_key_move.start()

local launch = require("modules.launch")
launch.start()

local memo = require("modules.memo")
memo.start()

local mouse_lock = require("modules.mouse_lock")
mouse_lock.start()

local chatgpt = require("modules.chatgpt")
chatgpt.start()

local create_txt = require("modules.create_txt_file")
create_txt.start()

local hotkeys = require("modules.hotkeys")
hotkeys.start()

local right_mouse_button_simulates_space = require("modules.right_mouse_button_simulates_space")
right_mouse_button_simulates_space.start()

local self = require("modules.self")
self.start()
