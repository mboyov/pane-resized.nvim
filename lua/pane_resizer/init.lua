-- init.lua
-- Entry point for the Pane Resizer plugin, setting up user configuration and auto commands

local config = require("pane_resizer.config")
local resize = require("pane_resizer.resize")
local utils = require("pane_resizer.utils")

local M = {}

-- Sets up the Pane Resizer plugin with user-defined or default options
-- @param opts - optional table containing configuration overrides
function M.setup(opts)
	opts = opts or {}
	config.NVIMTREE_WIDTH = opts.NVIMTREE_WIDTH or config.NVIMTREE_WIDTH
	config.FOCUSED_WIDTH_PERCENTAGE = opts.FOCUSED_WIDTH_PERCENTAGE or config.FOCUSED_WIDTH_PERCENTAGE
	config.fixed_windows = opts.fixed_windows or config.fixed_windows

	-- Auto command: Resize panes when entering a new window
	vim.api.nvim_create_autocmd("WinEnter", {
		group = vim.api.nvim_create_augroup("AutoResizePanes", { clear = true }),
		callback = function()
			local current_buf = vim.api.nvim_buf_get_name(vim.api.nvim_get_current_buf())
			if not current_buf:match("NvimTree_") then
				resize.resize_focused_pane()
			end
		end,
	})

	-- Auto command: Enforce fixed NvimTree width when Neovim's window layout changes
	vim.api.nvim_create_autocmd("VimResized", {
		group = vim.api.nvim_create_augroup("EnforceNvimTreeWidth", { clear = true }),
		callback = function()
			for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
				if utils.is_buffer_name(win, "NvimTree_") then
					vim.api.nvim_win_set_width(win, config.NVIMTREE_WIDTH)
				end
			end
		end,
	})

	-- Auto command: Disable text wrap for all newly created windows
	vim.api.nvim_create_autocmd("WinNew", {
		pattern = "*",
		callback = function()
			utils.disable_wrap(0)
		end,
	})
end

return M
