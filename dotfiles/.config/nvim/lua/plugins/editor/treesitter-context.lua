-- Show context of the current function
return {
   "nvim-treesitter/nvim-treesitter-context",
   event = { "BufReadPost", "BufWritePost", "BufNewFile" },
   enabled = true,
   opts = { mode = "cursor", max_lines = 3 },
   keys = {
      {
         "<leader>oc",
         function()
            local Util = require("config.utils")
            local tsc = require("treesitter-context")
            tsc.toggle()
               Util.info("Treesitter Context Toggled", { title = "Option" })
         end,
         desc = "Toggle Context",
      },
   },
}
