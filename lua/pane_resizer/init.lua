-- lua/pane_resizer/init.lua
local api = vim.api

local M = {}

-- Default values for NvimTree width and the focused buffer percentage
M.NVIMTREE_WIDTH = 30 -- You can adjust this value as needed
M.FOCUSED_WIDTH_PERCENTAGE = 0.6 -- Set the focused buffer to 60% of the available width

-- Function to resize the focused pane only, excluding NvimTree and keeping other panes unchanged
function M.resize_focused_pane()
	local current_win = api.nvim_get_current_win()
	local total_width = api.nvim_get_option("columns")
	local windows = api.nvim_tabpage_list_wins(0) -- Get all windows in the current tab
	local non_floating_windows = {}
	local nvimtree_win = nil

	-- Filter out floating windows and identify NvimTree
	for _, win in ipairs(windows) do
		local bufname = api.nvim_buf_get_name(api.nvim_win_get_buf(win))
		local win_config = api.nvim_win_get_config(win)

		-- Identify NvimTree and exclude it from the resizing
		if bufname:match("NvimTree_") then
			nvimtree_win = win
		elseif win_config.relative == "" then -- Non-floating windows
			table.insert(non_floating_windows, win)
		end
	end

	-- If NvimTree is the current window or there are no non-floating windows, skip resizing
	if current_win == nvimtree_win or #non_floating_windows < 2 then
		return
	end

	-- Disable text wrapping to avoid text being squeezed for the current window
	api.nvim_win_set_option(current_win, "wrap", false)

	-- Adjust total width if NvimTree is open (ignore its width for other windows)
	if nvimtree_win then
		total_width = total_width - M.NVIMTREE_WIDTH
	end

	-- Calculate the width for the focused window based on the user-configured percentage
	local focused_width = math.floor(total_width * M.FOCUSED_WIDTH_PERCENTAGE)

	-- Resize the focused window
	api.nvim_win_set_width(current_win, focused_width)
end

-- Setup function to initialize the plugin with customizable options
function M.setup(opts)
	-- Allow users to override default settings
	opts = opts or {}
	M.NVIMTREE_WIDTH = opts.NVIMTREE_WIDTH or M.NVIMTREE_WIDTH
	M.FOCUSED_WIDTH_PERCENTAGE = opts.FOCUSED_WIDTH_PERCENTAGE or M.FOCUSED_WIDTH_PERCENTAGE

	-- Automatically resize the focused pane only, ignoring NvimTree and floating windows
	api.nvim_create_autocmd("WinEnter", {
		group = api.nvim_create_augroup("AutoResizePanes", { clear = true }),
		callback = function()
			-- Check if the focused window is not NvimTree before resizing
			local current_buf = api.nvim_buf_get_name(api.nvim_get_current_buf())
			local is_nvimtree = current_buf:match("NvimTree_")

			-- Only resize if the buffer is not NvimTree
			if not is_nvimtree then
				M.resize_focused_pane()
			end
		end,
	})

	-- Disable text wrapping when a new window is opened
	api.nvim_create_autocmd("BufWinEnter", {
		group = api.nvim_create_augroup("DisableWrapOnOpen", { clear = true }),
		callback = function()
			api.nvim_win_set_option(0, "wrap", false) -- Disable text wrap for the new window
		end,
	})

	-- Set a fixed width for NvimTree once and prevent any resizing after that
	api.nvim_create_autocmd("BufWinEnter", {
		pattern = "NvimTree_*",
		callback = function()
			local nvimtree_win = api.nvim_get_current_win()
			-- Set the NvimTree window to a fixed width
			api.nvim_win_set_width(nvimtree_win, M.NVIMTREE_WIDTH)
		end,
	})

	-- Prevent NvimTree from being resized when switching focus
	api.nvim_create_autocmd("WinLeave", {
		pattern = "*",
		callback = function()
			local current_buf = api.nvim_buf_get_name(api.nvim_get_current_buf())
			if current_buf:match("NvimTree_") then
				-- Reset NvimTree's width to a fixed value when losing focus
				local nvimtree_win = api.nvim_get_current_win()
				api.nvim_win_set_width(nvimtree_win, M.NVIMTREE_WIDTH)
			end
		end,
	})
end

return M
