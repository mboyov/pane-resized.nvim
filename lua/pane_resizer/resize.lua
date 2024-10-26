-- resize.lua
-- Contains the main logic for resizing Neovim panes based on focus and configuration settings

local api = vim.api
local config = require("pane_resizer.config")
local utils = require("pane_resizer.utils")

local M = {}

-- Resizes the focused window, distributing remaining space among non-focused windows
function M.resize_focused_pane()
	local current_win = api.nvim_get_current_win()
	local windows = api.nvim_tabpage_list_wins(0)
	local non_floating_windows = {}
	local fixed_windows = {}
	local nvimtree_win

	-- Identify NvimTree and windows with fixed widths, exclude floating windows
	for _, win in ipairs(windows) do
		local win_config = api.nvim_win_get_config(win)
		-- Skip floating windows by checking if 'relative' is empty
		if win_config.relative == "" then
			if utils.is_buffer_name(win, "NvimTree_") then
				nvimtree_win = win
			else
				-- Check if the window matches any fixed window pattern
				local is_fixed = false
				for _, fixed in ipairs(config.fixed_windows) do
					if utils.is_buffer_name(win, fixed.pattern) then
						table.insert(fixed_windows, { win = win, width_percentage = fixed.width_percentage })
						is_fixed = true
						break
					end
				end
				-- If not fixed, consider it as a regular window
				if not is_fixed then
					table.insert(non_floating_windows, win)
				end
				-- Disable wrap for non-floating windows
				utils.disable_wrap(win)
			end
		end
	end

	-- Skip resizing if in NvimTree or if only one non-floating window is present
	if nvimtree_win and (current_win == nvimtree_win or #non_floating_windows < 2) then
		return
	end

	-- Calculate available width, subtracting space for NvimTree and fixed-width windows
	local adjusted_width = api.nvim_get_option("columns") - (nvimtree_win and config.NVIMTREE_WIDTH or 0)
	for _, fixed in ipairs(fixed_windows) do
		local fixed_width = math.floor(adjusted_width * fixed.width_percentage + 0.5) -- round to nearest integer
		api.nvim_win_set_width(fixed.win, fixed_width)
		adjusted_width = adjusted_width - fixed_width
	end

	-- Calculate focused window width
	local focused_width = math.floor(adjusted_width * config.FOCUSED_WIDTH_PERCENTAGE + 0.5) -- round to nearest integer
	api.nvim_win_set_width(current_win, focused_width)

	-- Distribute remaining width equally among non-focused windows
	local remaining_width = adjusted_width - focused_width
	local non_focused_width = math.floor((remaining_width / (#non_floating_windows - 1)) + 0.5) -- round to nearest integer
	for _, win in ipairs(non_floating_windows) do
		if win ~= current_win then
			api.nvim_win_set_width(win, non_focused_width)
		end
	end

	-- Ensure NvimTree retains its fixed width if present
	if nvimtree_win then
		api.nvim_win_set_width(nvimtree_win, config.NVIMTREE_WIDTH)
	end
end

return M
