-- init.lua
-- Entry point for the Pane Resizer plugin, setting up user configuration and auto commands

local api = vim.api
local config = require("pane_resizer.config")
local resize = require("pane_resizer.resize")
local utils = require("pane_resizer.utils")

local M = {}

-- Setup function to initialize the plugin with customizable options
function M.setup(opts)
	opts = opts or {}
	config.NVIMTREE_WIDTH = opts.NVIMTREE_WIDTH or config.NVIMTREE_WIDTH
	config.FOCUSED_WIDTH_PERCENTAGE = opts.FOCUSED_WIDTH_PERCENTAGE or config.FOCUSED_WIDTH_PERCENTAGE

	api.nvim_create_autocmd("WinEnter", {
		group = api.nvim_create_augroup("AutoResizePanes", { clear = true }),
		callback = function()
			local current_buf = api.nvim_buf_get_name(api.nvim_get_current_buf())
			if not current_buf:match("NvimTree_") then
				resize.resize_focused_pane()
			end
		end,
	})

	api.nvim_create_autocmd("BufWinEnter", {
		group = api.nvim_create_augroup("DisableWrapOnOpen", { clear = true }),
		callback = function()
			utils.disable_wrap(0)
		end,
	})

	api.nvim_create_autocmd("BufWinEnter", {
		pattern = "NvimTree_*",
		callback = function()
			local nvimtree_win = api.nvim_get_current_win()
			api.nvim_win_set_width(nvimtree_win, config.NVIMTREE_WIDTH)
		end,
	})

	api.nvim_create_autocmd("WinLeave", {
		pattern = "*",
		callback = function()
			local current_buf = api.nvim_buf_get_name(api.nvim_get_current_buf())
			if current_buf:match("NvimTree_") then
				local nvimtree_win = api.nvim_get_current_win()
				api.nvim_win_set_width(nvimtree_win, config.NVIMTREE_WIDTH)
			end
		end,
	})
end

return M
