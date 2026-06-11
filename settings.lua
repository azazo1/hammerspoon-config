return {
  ctrl_prefix_bracket = {
    timeout_seconds = 0.5,
    switch_delay_seconds = 0.02,
  },
  ime_hotkey = {
    -- 这里保持和你原来的 Karabiner 习惯一致.
    -- Ctrl+[ 命中后, 再发一次 Ctrl+Alt+Shift+F1.
    english = {
      modifiers = { "ctrl", "alt", "shift" },
      key = "f1",
    },
  },
}
