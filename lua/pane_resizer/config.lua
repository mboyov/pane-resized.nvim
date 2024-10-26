-- config.lua
-- Default configuration settings for Pane Resizer

local M = {}

-- Fixed width for NvimTree sidebar
M.NVIMTREE_WIDTH = 30
-- Percentage of available width assigned to the focused window
M.FOCUSED_WIDTH_PERCENTAGE = 0.6
-- Configurable list of windows with fixed widths
-- Each entry specifies a buffer name pattern and the width percentage to apply
M.fixed_windows = {
	{ pattern = "Trouble", width_percentage = 0.4 },
	-- Additional plugins can be added here
}

return M
