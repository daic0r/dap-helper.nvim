--function reload()
--   package.loaded["dap-helper"] = nil
--   require("dap-helper").setup()
--end

local internals = require("dap-helper.internals")

local M = {}

local daic0r_dap_helper = vim.api.nvim_create_augroup("DAIC0R_DAP_HELPER", {
   clear = true
})

function M.setup()
   vim.api.nvim_create_user_command("DapHelperSetLaunchArgs", function(_arg)
      local entry = internals.load_from_json_file("args")
      local opts = { prompt = "Launch arguments: " }
      -- Check if file exists and data could be loaded
      -- If not, create default entry for this directory
      -- TODO: Always use base directory of current project, not cwd
      -- If entry exists and has args, use them as default for the prompt
      -- concatening them with spaces
      if #entry > 0 then
         opts.default = table.concat(entry, " ")
      end
      -- Ask use to input arguments
      vim.ui.input(opts, function(new_args)
         if not new_args then
            return
         end
         -- Now do the reverse of the above, and split the input into an array
         local arg_array = {}
         for arg in string.gmatch(new_args, "%S+") do
            table.insert(arg_array, arg)
         end
         -- If the entry does not exist, or the arguments have changed, save the
         -- new arguments
         if not entry or not internals.compare_args(arg_array, entry) then
            if not internals.update_json_file("args", arg_array) then
               vim.notify("Saving failed", vim.log.levels.WARN)
            end
         end
      end)
   end, {})

   vim.api.nvim_create_autocmd("BufUnload", {
      pattern = "*",
      callback = function(opts)
         local filename = vim.api.nvim_buf_get_name(opts.buf)
         if #filename == 0 or not vim.fn.filereadable(filename) then
            return
         end
         internals.save_watches()
         if vim.api.nvim_buf_get_option(opts.buf, "modified") then
            return
         end
         -- Only save breakpoints if buffer is unmodified to make sure we save no
         -- breakpoints that reference non-existing lines
         internals.save_breakpoints()
      end,
      group = daic0r_dap_helper
   })
   vim.api.nvim_create_autocmd("BufReadPost", { 
      pattern = "*",
      callback = function(opts)
         local filename = vim.api.nvim_buf_get_name(opts.buf)
         if #filename == 0 or not vim.fn.filereadable(filename) then
            return
         end
         internals.load_breakpoints()
         internals.load_watches()
      end,
      group = daic0r_dap_helper
   })

end

function M.get_launch_args()
   return internals.load_from_json_file("args")
end

function M.set_launch_args()
   require("dap").configurations[vim.bo.filetype][1].args = M.get_launch_args()
end

return M
