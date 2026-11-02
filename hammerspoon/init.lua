--enable IPC
hs.ipc.cliInstall()

local self = require("modules.self")
self.start()

local keyboard_battery = require("modules.keyboard_battery")
keyboard_battery.start()

local input_switch = require("modules.input_switch")
input_switch.start()

local window_expand = require("modules.window_expand")
window_expand.start()

local window_move = require("modules.window_move")
window_move.start()

local clipboard_stack = require("modules.clipboard_stack")
clipboard_stack.start()

local memo = require("modules.memo")
memo.start()

local mouse_lock = require("modules.mouse_lock")
mouse_lock.start()

local create_txt = require("modules.create_txt_file")
create_txt.start()

local hotkeys = require("modules.hotkeys")
hotkeys.start()

require("modules.caps_lock")

require("modules.image_viewer")

--require("modules.clipboard_history")

--local send_clipboard_to_telegram = require("modules.send_clipboard_to_telegram")
--send_clipboard_to_telegram.start()

--local one_key_move = require("modules.one_key_move")
--one_key_move.start()

--local launch = require("modules.launch")
--launch.start()

--local right_mouse_button_simulates_right = require("modules.right_mouse_button_simulates_right")
--right_mouse_button_simulates_right.start()

--local right_mouse_button_simulates_space = require("modules.right_mouse_button_simulates_space")
--right_mouse_button_simulates_space.start()

--local browse_pictures = require("modules.browse_pictures")
--browse_pictures.start()
