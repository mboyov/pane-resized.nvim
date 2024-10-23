local api = vim.api

local M = {}

-- Default values for NvimTree width and the focused buffer percentage
M.NVIMTREE_WIDTH = 30 -- Width of NvimTree
M.FOCUSED_WIDTH_PERCENTAGE = 0.6 -- Focused window will take 60% of available width
local previous_win = nil -- Track the previous window

-- Helper to check if a window has a specific characteristic
local function is_window_type(win, pattern)
	if not api.nvim_win_is_valid(win) then
		return false
	end
	local valid, bufname = pcall(api.nvim_buf_get_name, api.nvim_win_get_buf(win))
	return valid and bufname:match(pattern)
end

-- Wrapper around is_window_type to identify specific window types
local function is_nvimtree(win)
	return is_window_type(win, "NvimTree_")
end
local function is_special_sidebar(win)
	return is_window_type(win, "Trouble")
end
local function is_floating(win)
	return api.nvim_win_is_valid(win) and api.nvim_win_get_config(win).relative ~= ""
end

-- Lock NvimTree's width permanently
local function lock_nvimtree_width()
	for _, win in ipairs(api.nvim_tabpage_list_wins(0)) do
		if is_nvimtree(win) then
			api.nvim_win_set_width(win, M.NVIMTREE_WIDTH)
		end
	end
end

-- Disable text wrapping for all valid windows
local function disable_wrap_for_all_windows()
	for _, win in ipairs(api.nvim_tabpage_list_wins(0)) do
		if api.nvim_win_is_valid(win) and not is_floating(win) and not is_nvimtree(win) then
			api.nvim_win_set_option(win, "wrap", false)
		end
	end
end

-- Generalized function to resize windows, excluding NvimTree
local function resize_all_windows(focused_win, non_floating_windows, total_width)
	local focused_width = math.floor(total_width * M.FOCUSED_WIDTH_PERCENTAGE)
	local remaining_width = total_width - focused_width
	local other_windows_width = math.floor(remaining_width / (#non_floating_windows - 1))

	-- Resize the focused window and the others
	api.nvim_win_set_width(focused_win, focused_width)
	for _, win in ipairs(non_floating_windows) do
		if win ~= focused_win then
			api.nvim_win_set_width(win, other_windows_width)
		end
	end
end

-- Function to handle special transitions (e.g., Trouble <-> Split 3)
local function handle_special_transitions(non_floating_windows, focused_win, total_width)
	if previous_win and is_special_sidebar(previous_win) and not is_special_sidebar(focused_win) then
		resize_all_windows(focused_win, non_floating_windows, total_width)
		lock_nvimtree_width()
		return true
	end
	return false
end

-- Core function to resize the focused window dynamically
local function resize_focused_pane()
	local current_win = api.nvim_get_current_win()
	local total_width = api.nvim_get_option("columns")
	local windows = api.nvim_tabpage_list_wins(0)
	local non_floating_windows = {}
	local nvimtree_open = false

	-- Identify non-floating windows and NvimTree
	for _, win in ipairs(windows) do
		if is_nvimtree(win) then
			nvimtree_open = true
		elseif not is_floating(win) then
			table.insert(non_floating_windows, win)
		end
	end

	-- Skip resizing if NvimTree is focused or there are fewer than 2 windows
	if #non_floating_windows < 2 then
		return
	end
	api.nvim_win_set_option(current_win, "wrap", false)

	-- Adjust total width if NvimTree is open
	if nvimtree_open then
		total_width = total_width - M.NVIMTREE_WIDTH
	end

	-- Handle special transitions (e.g., Trouble -> Split 3)
	if handle_special_transitions(non_floating_windows, current_win, total_width) then
		return
	end

	-- Resize all windows, respecting focus
	resize_all_windows(current_win, non_floating_windows, total_width)
	lock_nvimtree_width()
	previous_win = current_win
end

-- Setup function for initializing the plugin
function M.setup(opts)
	opts = opts or {}
	M.NVIMTREE_WIDTH = opts.NVIMTREE_WIDTH or M.NVIMTREE_WIDTH
	M.FOCUSED_WIDTH_PERCENTAGE = opts.FOCUSED_WIDTH_PERCENTAGE or M.FOCUSED_WIDTH_PERCENTAGE

	local group_id = api.nvim_create_augroup("PaneResizerGroup", { clear = true })

	-- Autocommand to resize the focused pane dynamically
	api.nvim_create_autocmd({ "WinEnter", "BufWinEnter" }, {
		group = group_id,
		callback = function()
			if not is_nvimtree(api.nvim_get_current_win()) then
				resize_focused_pane()
			else
				lock_nvimtree_width()
			end
		end,
	})

	-- Lock NvimTree's width when leaving focus
	api.nvim_create_autocmd("WinLeave", {
		group = group_id,
		callback = lock_nvimtree_width,
	})

	-- Disable wrap for all windows on opening
	api.nvim_create_autocmd("BufWinEnter", {
		group = group_id,
		callback = disable_wrap_for_all_windows,
	})
end

return M
