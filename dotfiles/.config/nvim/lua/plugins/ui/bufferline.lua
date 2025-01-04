-- This is what powers LazyVim's fancy-looking
-- tabs, which include filetype icons and close buttons.
return {
	"akinsho/bufferline.nvim",
	event = "VeryLazy",
   dependencies = {
      { 'echasnovski/mini.bufremove', version = false, opts = {} },
   },
	keys = {
		{ "<leader>bp", "<Cmd>BufferLineTogglePin<CR>", desc = "Toggle pin" },
		{ "<leader>bP", "<Cmd>BufferLineGroupClose ungrouped<CR>", desc = "Delete non-pinned buffers" },
		{ "<leader>bO", "<Cmd>BufferLineCloseOthers<CR>", desc = "Delete other buffers" },
		{ "<leader>bR", "<Cmd>BufferLineCloseRight<CR>", desc = "Delete buffers to the right" },
		{ "<leader>bL", "<Cmd>BufferLineCloseLeft<CR>", desc = "Delete buffers to the left" },
		{ ";", "<cmd>BufferLineCyclePrev<cr>", desc = "Prev buffer" },
		{ "'", "<cmd>BufferLineCycleNext<cr>", desc = "Next buffer" },
		{ "[b", "<cmd>BufferLineCyclePrev<cr>", desc = "Prev buffer" },
		{ "]b", "<cmd>BufferLineCycleNext<cr>", desc = "Next buffer" },
		{ "<leader>b>", "<cmd>BufferLineMoveNext<cr>", desc = "Move buffer right" },
		{ "<leader>b<", "<cmd>BufferLineMovePrev<cr>", desc = "Move buffer left" },
		{ "<C->>", "<cmd>BufferLineMoveNext<cr>", desc = "Move buffer right" },
		{ "<C-lt>", "<cmd>BufferLineMovePrev<cr>", desc = "Move buffer left" },
	},
	opts = {
		options = {
        -- stylua: ignore
        close_command = function(n) require("mini.bufremove").delete(n, false) end,
        -- stylua: ignore
        right_mouse_command = function(n) require("mini.bufremove").delete(n, false) end,
        -- BUG: this diagnostic line is causing an issue
		  -- diagnostics = "nvim_lsp",
			always_show_bufferline = false,
			offsets = {
				{
					filetype = "neo-tree",
					text = "Neo-tree",
					highlight = "Directory",
					text_align = "left",
				},
			},
		},
	},
   -- TODO: figure out if this is necessary
	-- config = function(_, opts)
	-- 	require("bufferline").setup(opts)
	-- 	-- Fix bufferline when restoring a session
	-- 	vim.api.nvim_create_autocmd("BufAdd", {
	-- 		callback = function()
	-- 			vim.schedule(function()
	-- 				pcall(nvim_bufferline)
	-- 			end)
	-- 		end,
	-- 	})
	-- end,
}
