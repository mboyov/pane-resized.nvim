-- utils.lua
-- Utility functions for Pane Resizer to improve code reusability and readability

local api = vim.api

local M = {}

-- Checks if a window's buffer name matches a given pattern
-- @param win - the window ID
-- @param name - the pattern to match (e.g., "NvimTree_")
-- @return boolean - true if the buffer name matches the pattern
function M.is_buffer_name(win, name)
	local bufname = api.nvim_buf_get_name(api.nvim_win_get_buf(win))
	return bufname:match(name) ~= nil
end

-- Disables text wrapping for a given window
-- @param win - the window ID
function M.disable_wrap(win)
	api.nvim_win_set_option(win, "wrap", false)
end

-- Determines if a window should be excluded from resizing (e.g., floating or special windows)
-- @param win - the window ID
-- @return boolean - true if the window should be excluded
function M.should_exclude_window(win)
	local win_config = api.nvim_win_get_config(win)
	local bufname = api.nvim_buf_get_name(api.nvim_win_get_buf(win))
	return win_config.relative ~= "" or bufname:match("TelescopePrompt")
end

return M
