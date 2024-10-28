-- resize.lua
-- Contains the main logic for resizing Neovim panes based on focus and configuration settings

local api = vim.api
local config = require("pane_resizer.config")
local utils = require("pane_resizer.utils")

local M = {}

-- Main function to resize only the focused window, enforcing fixed width for NvimTree
function M.resize_focused_pane()
	local current_win = api.nvim_get_current_win()

	-- Skip resizing for floating windows
	if utils.should_exclude_window(current_win) then
		return
	end

	local total_width = api.nvim_get_option("columns")
	local nvimtree_win = nil

	-- Identify NvimTree and filter out floating windows
	for _, win in ipairs(api.nvim_tabpage_list_wins(0)) do
		if utils.is_buffer_name(win, "NvimTree_") then
			nvimtree_win = win
			break
		end
	end

	-- Skip resizing if NvimTree is focused or if there are no other windows
	if current_win == nvimtree_win or #api.nvim_tabpage_list_wins(0) < 2 then
		return
	end

	-- Deduct NvimTree width from the total if it's present
	if nvimtree_win then
		total_width = total_width - config.NVIMTREE_WIDTH
	end

	-- Calculate and set the width for the focused window only
	local focused_width = math.floor(total_width * config.FOCUSED_WIDTH_PERCENTAGE)
	api.nvim_win_set_width(current_win, focused_width)

	-- Enforce fixed width for NvimTree
	if nvimtree_win then
		api.nvim_win_set_width(nvimtree_win, config.NVIMTREE_WIDTH)
	end
end

return M
