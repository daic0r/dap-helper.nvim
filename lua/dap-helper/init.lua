function reload()
   package.loaded["dap-helper"] = nil
   require("dap-helper").setup()
end

local internals = require("dap-helper.internals")

local M = {}

local daic0r_dap_helper = vim.api.nvim_create_augroup("DAIC0R_DAP_HELPER", {
   clear = true
})

function M.setup()
   vim.api.nvim_create_user_command("DapHelperSetLaunchArgs", function(_arg)
      local entry = internals.load_from_json_file("args")
      local opts = { prompt = "Enter launch arguments: " }
      -- Check if file exists and data could be loaded
      -- If not, create default entry for this directory
      -- TODO: Always use base directory of current project, not cwd
      -- If entry exists and has args, use them as default for the prompt
      -- concatening them with spaces
      if #entry > 0 then
         opts.default = table.concat(entry, " ")
      end
      -- Ask use to input arguments
      local new_args = vim.fn.input(opts)
      -- Now do the reverse of the above, and split the input into an array
      local arg_array = {}
      for arg in string.gmatch(new_args, "%S+") do
         table.insert(arg_array, arg)
      end
      -- If the entry does not exist, or the arguments have changed, save the
      -- new arguments
      if not entry or not internals.compare_args(arg_array, entry) then
         if not internals.update_json_file("args", arg_array) then
            print("Saving failed")
         end
      end
   end, {})

   vim.api.nvim_create_autocmd("BufWritePost", {
      pattern = {"*.h", ".c", ".cpp", "*.rs" },
      callback = function(opts)
         internals.save_breakpoints()
         internals.save_watches()
      end,
      group = daic0r_dap_helper
   })
   vim.api.nvim_create_autocmd("BufReadPost", {
      pattern = {"*.h", ".c", ".cpp", "*.rs" },
      callback = function(opts)
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
