-- resize.lua
-- Contains the main logic for resizing Neovim panes based on focus and configuration settings

local api = vim.api
local config = require("pane_resizer.config")
local utils = require("pane_resizer.utils")

local M = {}

-- Converts any float to an integer by rounding to the nearest whole number
-- @param width - the width to round
-- @return integer - rounded integer width
local function round_to_integer(width)
	return math.floor(width + 0.5)
end

-- Collects and categorizes all windows based on type and configuration
-- @return nvimtree_win, fixed_windows, non_floating_windows - categorized windows
local function categorize_windows()
	local windows = api.nvim_tabpage_list_wins(0)
	local non_floating_windows = {}
	local fixed_windows = {}
	local nvimtree_win = nil

	for _, win in ipairs(windows) do
		-- Exclude floating and special windows like Telescope
		if utils.should_exclude_window(win) then
			goto continue -- Skip to the next iteration for excluded windows
		end

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
			utils.disable_wrap(win)
		end

		::continue::
	end
	return nvimtree_win, fixed_windows, non_floating_windows
end

-- Calculates and sets widths for the NvimTree, fixed, and other windows
function M.resize_focused_pane()
	local current_win = api.nvim_get_current_win()
	local nvimtree_win, fixed_windows, non_floating_windows = categorize_windows()

	-- Skip resizing if NvimTree is focused or only one window is non-floating
	if nvimtree_win and (current_win == nvimtree_win or #non_floating_windows < 2) then
		return
	end

	local total_width = api.nvim_get_option("columns")
	local adjusted_width = total_width - (nvimtree_win and config.NVIMTREE_WIDTH or 0)

	-- Set widths for fixed windows and adjust remaining width
	for _, fixed in ipairs(fixed_windows) do
		local fixed_width = round_to_integer(adjusted_width * fixed.width_percentage)
		api.nvim_win_set_width(fixed.win, fixed_width)
		adjusted_width = adjusted_width - fixed_width
	end

	-- Set focused window width and calculate remaining width for others
	local focused_width = round_to_integer(adjusted_width * config.FOCUSED_WIDTH_PERCENTAGE)
	api.nvim_win_set_width(current_win, focused_width)
	local remaining_width = adjusted_width - focused_width

	-- Distribute remaining width equally among non-focused windows, ensuring integer widths
	if #non_floating_windows > 1 then
		local non_focused_width = round_to_integer(remaining_width / (#non_floating_windows - 1))
		for _, win in ipairs(non_floating_windows) do
			if win ~= current_win then
				api.nvim_win_set_width(win, non_focused_width)
			end
		end
	end

	-- Enforce fixed width for NvimTree, if present
	if nvimtree_win then
		api.nvim_win_set_width(nvimtree_win, config.NVIMTREE_WIDTH)
	end
end

return M
