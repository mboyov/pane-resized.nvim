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

return M
